//+------------------------------------------------------------------+
//| CanvasPanel.mqh                                                   |
//| Fase 2 — CFusionCanvasPanel: mesma fronteira que CFusionPanel,    |
//| composta em cima do renderizador da Fase 1 em vez de herdar dela. |
//|                                                                   |
//| O EA nao sabe qual painel esta do outro lado dos 10 pontos de     |
//| contato (secao 5 do plano); so precisa que esta classe responda   |
//| aos 8 metodos com as mesmas assinaturas de CFusionPanel.          |
//|                                                                   |
//| Etapa 2c: alem de exibir, o painel agora RESPONDE. Ele e o unico  |
//| lado desta dupla que alcanca o disco e os registros do terminal,  |
//| e por isso e ele quem reconfere cada intencao no instante da      |
//| acao — o renderizador decide o que OFERECER, este decide o que    |
//| ACONTECE.                                                         |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_PANEL_MQH__
#define __FUSION_CANVAS_PANEL_MQH__

#include "../../Core/Types.mqh"
//--- A lista de perfis vem do DISCO, nao de SEASettings, e por isso e o painel
//--- que a busca — mesmo desenho da 1.058, que tem um CSettingsStore dentro do
//--- proprio painel. O renderizador continua sem tocar em Persistence: ele
//--- recebe a lista pronta, pelo mesmo caminho por onde recebe o snapshot.
#include "../../Persistence/SettingsStore.mqh"
//--- Registros de concorrencia. O renderizador tambem os consulta, para
//--- desenhar; aqui eles sao consultados de novo, no instante do clique — e e
//--- essa segunda consulta que vale, porque a primeira e de ate um segundo
//--- atras (ver a divida registrada para a 2c no plano).
#include "../../Core/InstanceRegistry.mqh"
#include "../../Core/ActiveProfileRegistry.mqh"
#include "CanvasRenderer.mqh"

class CFusionCanvasPanel
  {
private:
   CFusionCanvasRenderer m_renderer;
   SUIPanelSnapshot      m_snapshot;
   bool                  m_created;
   CSettingsStore        m_store;
   //--- Ultimo perfil ativo visto. Serve de gatilho de releitura: quando o EA
   //--- troca de perfil, a lista em disco quase sempre mudou junto (carga,
   //--- gravacao, exclusao). Reler a cada Update seria uma varredura de disco
   //--- ate 5x por segundo, com um parse de arquivo por perfil.
   string                m_lastActiveProfile;
   //--- Grafico deste painel. Guardado, e nao lido por ChartID(): os registros
   //--- de concorrencia comparam por identificador, e um EA anexado a um
   //--- subgrafico responderia outro numero — o painel passaria a se ver como
   //--- "outro grafico" e recusaria as proprias acoes.
   long                  m_chartId;

   //+---------------------------------------------------------------+
   //| Gravacao esperando resposta.                                   |
   //|                                                                |
   //| O EA nao devolve "deu certo" — ele CHAMA LoadSettings quando   |
   //| deu, e simplesmente volta quando nao deu. Sem lembrar que      |
   //| pedimos, o painel nao teria como distinguir a recarga que e    |
   //| resposta ao nosso SALVAR da recarga que veio de outro motivo:  |
   //| a primeira merece "perfil salvo", a segunda o aviso de que o   |
   //| que estava sendo digitado se perdeu. Anunciar perda depois de  |
   //| uma gravacao bem-sucedida seria assustar sem causa.            |
   //|                                                                |
   //| A leitura e segura porque a sequencia e sincrona: o EA trata o |
   //| comando e, no mesmo passo, chama LoadSettings (sucesso) ou     |
   //| apenas retorna (recusa). Nenhum Update se intromete no meio —  |
   //| conferido em EAApplicationCommands: o caminho de SAVE_PROFILE  |
   //| so toca o painel em ReloadPanelSettingsIfVisible.              |
   //+---------------------------------------------------------------+
   int                   m_echoKind;     // 0 nenhum, 1 salvar, 2 criar, 3 restaurar
   string                m_echoProfile;
   //+---------------------------------------------------------------+
   //| Contexto anterior a uma TRANSACAO de criacao.                  |
   //|                                                                |
   //| Guardado porque a criacao APLICA antes de gravar: falhando o   |
   //| disco, a sessao fica rodando a configuracao de um perfil que   |
   //| nao existe, e o unico desfazer confiavel e este — o arquivo do |
   //| perfil ativo pode ser exatamente o que sumiu.                  |
   //|                                                                |
   //| ⚠ Fotografado UMA VEZ por transacao, na primeira tentativa, e  |
   //| liberado so no sucesso ou no abandono confirmado. Recapturar a |
   //| cada tentativa era um defeito grave e silencioso: na segunda,  |
   //| o snapshot ja carrega a configuracao da PRIMEIRA — o desfazer  |
   //| "restaurava" exatamente o que deveria descartar, e ainda       |
   //| anunciava que o perfil anterior tinha voltado.                 |
   //|                                                                |
   //| Guarda tambem a DIVIDA DE PERSISTENCIA que existia antes. Criar|
   //| perfil e permitido com uma gravacao ja pendente, e o rollback  |
   //| apagava essa divida junto: o arquivo do perfil ativo seguia    |
   //| desatualizado e o painel parava de avisar.                     |
   //+---------------------------------------------------------------+
   SEASettings           m_preCreateSettings;
   bool                  m_hasPreCreate;
   string                m_preCreateStale;
   //--- Perfil cujo arquivo ficou para tras numa gravacao que falhou. Guardado
   //--- pelo NOME, e nao so como sinalizador, para o aviso poder dizer o que se
   //--- perdeu quando o usuario troca de perfil por cima dele.
   string                m_staleProfile;

   void              ClearEcho(void) { m_echoKind=0; m_echoProfile=""; }

   //+---------------------------------------------------------------+
   //| A gravacao aconteceu mesmo? Pergunta ao DISCO.                 |
   //|                                                                |
   //| ⚠ Chamar LoadSettings NAO significa que gravou. O EA aplica e  |
   //| grava em passos separados, e o retorno de SaveProfile so       |
   //| governa a troca do nome ativo:                                 |
   //|                                                                |
   //|   if(!ApplySettings(...)) return;                              |
   //|   if(m_settingsStore.SaveProfile(...)) m_activeProfileName=...; |
   //|   ReloadPanelSettingsIfVisible();   // <- roda de todo jeito    |
   //|                                                                |
   //| Ou seja: disco cheio, arquivo somente-leitura, pasta sem        |
   //| permissao — a configuracao passa a valer NESTA SESSAO e o       |
   //| painel era avisado do mesmo jeito. Anunciar "PERFIL SALVO" ali  |
   //| e a pior mentira que este painel pode contar: o usuario fecha o |
   //| terminal confiando que gravou.                                  |
   //|                                                                |
   //| Nao existe canal para o EA dizer "falhou" sem mexer no comando, |
   //| que e codigo de producao compartilhado com o painel 1.058.      |
   //| Entao conferimos o RESULTADO em vez de confiar no aviso — e a   |
   //| licao 4 da secao 8 do plano ("conferir o binario deployado      |
   //| antes de interpretar um teste") aplicada ao proprio painel.     |
   //|                                                                |
   //| Custa uma leitura de disco por clique em SALVAR. Nao e por      |
   //| quadro: so acontece no eco de um comando que o usuario pediu.   |
   //+---------------------------------------------------------------+
   //--- A gravacao pedida chegou ao disco? Separada do anuncio porque a
   //--- resposta e precisa ANTES de recarregar a tela: e ela que decide se o
   //--- formulario de criacao fica aberto.
   bool              SaveLandedOnDisk(const SEASettings &applied)
     {
      SEASettings onDisk;
      //--- Compara contra o que o EA APLICOU, nao contra o rascunho que
      //--- enviamos: o EA normaliza (ResolveOperationalTimeframes) antes de
      //--- gravar, e o arquivo carrega a forma normalizada.
      //---
      //--- E corta a precisao dos dois lados na do ARQUIVO antes de comparar.
      //--- O que o EA aplicou pode ter mais casas do que o disco guarda — ele
      //--- nao passa pelo corte da GUI —, e sem isto uma gravacao correta seria
      //--- anunciada como falha por uma casa decimal que o arquivo nunca teve.
      SEASettings expected=applied;
      FusionApplyStoragePrecision(expected);
      return (m_store.LoadProfile(m_echoProfile,onDisk) &&
              FusionSettingsEqual(onDisk,expected));
     }

   void              AnnounceSaveOutcome(const bool saved)
     {
      //--- Restauracao: nao ha gravacao a conferir. Ela CHEGOU, e o simples
      //--- fato de o EA ter recarregado ja e a confirmacao — o estado perigoso
      //--- (configuracao aplicada sem perfil que a tenha) acabou.
      if(m_echoKind==3)
        {
         m_renderer.NoteFailedCreate(false);
         //--- A divida de persistencia que existia ANTES da criacao volta com o
         //--- resto do contexto. Limpa-la aqui apagava um aviso legitimo: se o
         //--- SALVAR do perfil ativo ja tinha falhado, o arquivo dele continua
         //--- desatualizado depois do rollback — o rollback desfaz a criacao,
         //--- nao a gravacao que falhou antes dela.
         m_staleProfile=m_preCreateStale;
         m_renderer.SetPersistenceFailed(m_staleProfile!="");
         m_hasPreCreate=false; m_preCreateStale="";
         m_renderer.SetNotice("CRIACAO ABANDONADA",
                              "A configuracao anterior do perfil "+m_echoProfile+
                              " voltou a valer, e a do perfil que nao chegou a ser "+
                              "gravado foi descartada.",FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
         return;
        }

      //--- A marca fica ATE a proxima gravacao bem-sucedida: e ela que mantem o
      //--- SALVAR aceso para o usuario tentar de novo, e que faz o EA avisar ao
      //--- fechar o grafico que ha algo por gravar.
      //---
      //--- Vale para os dois casos, e no da criacao ela nao e sobre o perfil
      //--- novo: a configuracao dele ja esta VALENDO nesta sessao, entao o
      //--- arquivo do perfil ATIVO ficou para tras. Guardamos o nome para saber
      //--- de qual arquivo estamos falando quando alguem trocar de perfil.
      m_renderer.SetPersistenceFailed(!saved);
      m_staleProfile = saved ? "" : m_snapshot.activeProfileName;
      //--- Criacao que falhou tem semantica propria de abandono: o DESCARTAR
      //--- passa a pedir a restauracao do estado anterior em vez de so fechar a
      //--- tela. E o contexto so e liberado quando a transacao ACABA — criou, ou
      //--- abandonou. Liberado antes, uma segunda tentativa fotografaria o
      //--- estado que a primeira ja tinha alterado.
      m_renderer.NoteFailedCreate(!saved && m_echoKind==2);
      if(saved && m_echoKind==2) { m_hasPreCreate=false; m_preCreateStale=""; }

      if(saved)
        {
         m_renderer.SetNotice((m_echoKind==2) ? "PERFIL CRIADO" : "PERFIL SALVO",
                              (m_echoKind==2)
                              ? "O perfil "+m_echoProfile+" foi criado e esta ativo neste grafico."
                              : "As alteracoes foram gravadas em "+m_echoProfile+".",
                              FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
         return;
        }
      //--- Sem prazo: e recusa, e recusa pede decisao. E o texto separa as duas
      //--- metades do que aconteceu — a configuracao VALE agora, o arquivo NAO
      //--- foi escrito —, porque dizer so "falhou" faria o usuario procurar na
      //--- tela uma alteracao que nao se perdeu.
      //---
      //--- ⚠ O botao citado MUDA com a operacao, e mandar o botao errado aqui
      //--- era o defeito: numa criacao que falhou, "clique SALVAR" grava no
      //--- perfil ATIVO — ou seja, sobrescreveria o perfil anterior com a
      //--- configuracao do que se tentou criar.
      if(m_echoKind==2)
        {
         m_renderer.SetNotice("PERFIL NAO CRIADO",
                              "O arquivo de "+m_echoProfile+" nao foi escrito, e a "+
                              "configuracao dele esta valendo nesta sessao. O formulario "+
                              "continua aberto: clique CRIAR PERFIL para tentar de novo.",
                              FCV_SEM_BAD);
         return;
        }
      m_renderer.SetNotice("PERFIL NAO GRAVADO",
                           "A configuracao esta valendo nesta sessao, mas o arquivo de "+
                           m_echoProfile+" nao foi escrito. Clique SALVAR para tentar de novo.",
                           FCV_SEM_BAD);
     }

   //--- Enumera os perfis e le o Magic de cada um. O Magic exige abrir o
   //--- arquivo: nao ha caminho barato para le-lo, e a propria 1.058 faz assim
   //--- em FusionFindProfileByMagicNumber. Por isso esta funcao roda em troca
   //--- de perfil, nunca por quadro.
   void              RefreshProfiles(void)
     {
      string names[];
      if(!m_store.ListProfiles(names)) return;

      int total=ArraySize(names);
      string keep[]; int magics[]; double lots[];
      ArrayResize(keep,total);
      ArrayResize(magics,total);
      ArrayResize(lots,total);
      int n=0;
      for(int i=0;i<total;++i)
        {
         SEASettings s;
         //--- Perfil ilegivel fica FORA da lista: exibi-lo sem Magic ofereceria
         //--- acoes sobre um arquivo que nem abriu.
         if(!m_store.LoadProfile(names[i],s)) continue;
         keep[n]  =names[i];
         magics[n]=s.magicNumber;
         lots[n]  =s.fixedLot;
         n++;
        }
      m_renderer.SetProfiles(keep,magics,lots,n,names);
     }

   //+---------------------------------------------------------------+
   //| Revalidacao no instante da acao.                               |
   //|                                                                |
   //| ⚠ E a divida nº 1 registrada no plano para esta etapa, e ela   |
   //| nao e teorica: a tela decide o que oferecer com dados em cache |
   //| — as travas de concorrencia sao reconsultadas no maximo uma    |
   //| vez por segundo, e a lista de perfis so na troca de perfil     |
   //| ativo. Entre o que a tela mostrou e o clique existe uma janela  |
   //| em que outro grafico pode ter iniciado, carregado o mesmo      |
   //| perfil ou criado um arquivo com o nome que este vai gravar.    |
   //|                                                                |
   //| Nada aqui repete a regra de acesso do renderizador. O que se   |
   //| reconfere e so o que MUDA POR FORA: disco e registros.         |
   //+---------------------------------------------------------------+
   bool              ProfileLockedByPeer(const string profileName,string &reason)
     {
      reason="";
      if(profileName=="") return false;

      SEASettings settings;
      if(m_store.LoadProfile(profileName,settings))
        {
         CInstanceRegistry instances;
         if(instances.HasActiveConflict(settings.magicNumber,m_chartId,reason))
            return true;
        }

      CActiveProfileRegistry profiles;
      reason="";
      return profiles.HasActiveProfilePeer(profileName,m_chartId,reason);
     }

   //--- Nome livre em DISCO, agora. A tela ja conferiu contra a lista em
   //--- memoria; esta e a conferencia que impede gravar por cima de um arquivo
   //--- criado por outro grafico nesse intervalo — divida nº 2 do plano.
   bool              NameFreeOnDisk(const string profileName)
     { return !m_store.ProfileExists(profileName); }

   bool              MagicFreeOnDisk(const int magic,const string exceptProfile,string &owner)
     {
      owner="";
      if(magic<=0) return false;
      return !m_store.FindProfileByMagicNumber(magic,exceptProfile,owner);
     }

   //--- "BTCUSD" -> "BTCUSD_copy", "..._copy_2"... Mesma regra da 1.058
   //--- (SuggestedDuplicateName), inclusive o sufixo em ingles ja consagrado
   //--- nos perfis existentes de quem atualiza.
   string            SuggestedDuplicateName(const string sourceName)
     {
      string base=m_store.SanitizeProfileName(sourceName);
      if(base=="") base="perfil";
      string candidate=base+"_copy";
      if(!m_store.ProfileExists(candidate)) return candidate;
      for(int i=2;i<1000;++i)
        {
         candidate=base+"_copy_"+IntegerToString(i);
         if(!m_store.ProfileExists(candidate)) return candidate;
        }
      return candidate;
     }

   //+---------------------------------------------------------------+
   //| Uma intencao vira comando, virou acao local, ou e recusada.    |
   //|                                                                |
   //| Devolve true quando `command` foi preenchido e deve seguir     |
   //| para o EA. Recusa e acao local devolvem false — e nos dois     |
   //| casos o usuario fica sabendo por escrito: recusar em silencio  |
   //| seria um botao que nao faz nada.                               |
   //+---------------------------------------------------------------+
   bool              TranslateIntent(const SCanvasIntent &intent,SUICommand &command)
     {
      command.type        = UI_COMMAND_NONE;
      command.text        = "";
      command.hasSettings = false;
      command.reloadScope = RELOAD_HOT;

      if(intent.kind==FCV_INTENT_TOGGLE_RUN)
        {
         command.type=UI_COMMAND_TOGGLE_RUNNING;
         command.text=m_snapshot.activeProfileName;
         return true;
        }

      if(intent.kind==FCV_INTENT_SAVE_ACTIVE)
        {
         string profileName=(intent.profile=="") ? m_snapshot.activeProfileName : intent.profile;
         string reason="";
         //--- O perfil ativo pode ter sido tomado por outro grafico desde o
         //--- ultimo desenho. Gravar assim mesmo poria dois graficos escrevendo
         //--- no mesmo arquivo.
         if(ProfileLockedByPeer(profileName,reason))
           {
            //--- O motivo vindo do registro ja e uma frase completa ("Magic N ja
            //--- esta em uso por outro Fusion ativo"). Prefixar com a minha
            //--- versao dizia a mesma coisa duas vezes e empurrava o aviso para
            //--- uma terceira linha — que e o que faz a caixa crescer e o
            //--- conteudo pular de lugar.
            m_renderer.SetNotice("NAO FOI POSSIVEL SALVAR",
                                 (reason!="") ? reason
                                 : "O perfil "+profileName+" esta em uso por outro grafico.",
                                 FCV_SEM_BAD);
            return false;
           }
         command.type        = UI_COMMAND_SAVE_PROFILE;
         command.text        = profileName;
         command.hasSettings = true;
         command.settings    = intent.settings;
         command.reloadScope = RELOAD_COLD;
         m_echoKind=1; m_echoProfile=profileName;
         return true;
        }

      if(intent.kind==FCV_INTENT_CREATE_PROFILE)
        {
         //--- SANEADO aqui, como a 1.058 faz (ProfileDraftName ja devolve o nome
         //--- saneado antes de enfileirar o comando). O renderizador manda o
         //--- texto cru porque ele nao conhece a regra de nome de arquivo — ela
         //--- e do store, e o store e deste lado.
         //---
         //--- Sem isto o perfil nascia com DUAS identidades: o arquivo virava
         //--- "Meu_Perfil.cfg" e aparecia assim na lista, enquanto o cabecalho e
         //--- o aviso diziam "Meu Perfil". Tecnicamente funcionava — a
         //--- comparacao de perfil ja e feita pela forma saneada —, mas a tela
         //--- afirmava dois nomes para a mesma coisa.
         string newName=m_store.SanitizeProfileName(intent.profile);
         if(newName=="")
           {
            m_renderer.SetNotice("NOME OBRIGATORIO",
                                 "Informe um nome para o perfil novo.",FCV_SEM_BAD);
            return false;
           }
         //--- Reconferencia em disco, nao na lista em memoria: e o unico jeito
         //--- de ver o arquivo que outro grafico criou desde a ultima leitura —
         //--- inclusive um que nem abre, e que ainda assim ocupa o nome.
         if(!NameFreeOnDisk(newName))
           {
            RefreshProfiles();
            m_renderer.SetNotice("NOME JA EXISTE",
                                 "Ja existe um perfil chamado "+newName+" em disco. "+
                                 "Escolha outro nome.",FCV_SEM_BAD);
            return false;
           }
         string owner="";
         if(!MagicFreeOnDisk(intent.magic,newName,owner))
           {
            RefreshProfiles();
            m_renderer.SetNotice("MAGIC JA USADO",
                                 (intent.magic<=0)
                                 ? "Informe um Magic inteiro positivo."
                                 : "O Magic "+IntegerToString(intent.magic)+
                                   " ja pertence ao perfil "+owner+". Escolha outro numero.",
                                 FCV_SEM_BAD);
            return false;
           }
         //--- O Magic do formulario vence o do rascunho: o rascunho descreve o
         //--- perfil ATIVO (ou, numa duplicacao, o de origem), e o numero novo e
         //--- justamente o que distingue o perfil que esta nascendo.
         SEASettings settings=intent.settings;
         settings.magicNumber=intent.magic;
         //--- Fotografa o estado ANTES de o EA aplicar o perfil novo, e SO na
         //--- primeira tentativa: da segunda em diante o snapshot ja carrega a
         //--- configuracao da tentativa anterior, e recapturar faria o desfazer
         //--- restaurar exatamente o que ele deveria descartar.
         if(!m_hasPreCreate)
           {
            m_preCreateSettings = m_snapshot.settings;
            m_preCreateStale    = m_staleProfile;
            m_hasPreCreate      = true;
           }

         command.type        = UI_COMMAND_SAVE_PROFILE;
         command.text        = newName;
         command.hasSettings = true;
         command.settings    = settings;
         command.reloadScope = RELOAD_COLD;
         m_echoKind=2; m_echoProfile=newName;
         return true;
        }

      if(intent.kind==FCV_INTENT_LOAD_PROFILE)
        {
         string profileName=intent.profile;
         if(profileName=="") return false;

         SEASettings target;
         if(!m_store.LoadProfile(profileName,target))
           {
            RefreshProfiles();
            m_renderer.SetNotice("PERFIL NAO CARREGADO",
                                 "O arquivo de "+profileName+" nao pode ser lido. "+
                                 "A configuracao atual foi preservada.",FCV_SEM_BAD);
            return false;
           }
         //--- Mesma recusa da 1.058: com o DD do dia em curso, trocar para um
         //--- perfil de parametros diferentes recomecaria a conta no meio.
         if(m_snapshot.drawdownConfigLocked &&
            !FusionDrawdownSettingsCompatible(m_snapshot.settings,target))
           {
            m_renderer.SetNotice("PERFIL NAO CARREGADO",
                                 FusionDrawdownProfileBlockMessage(),FCV_SEM_WARN);
            return false;
           }
         string reason="";
         if(ProfileLockedByPeer(profileName,reason))
           {
            m_renderer.SetNotice("PERFIL EM USO",
                                 (reason!="") ? reason
                                 : "O perfil "+profileName+" esta em uso por outro grafico.",
                                 FCV_SEM_BAD);
            return false;
           }
         command.type=UI_COMMAND_LOAD_PROFILE;
         command.text=profileName;
         return true;
        }

      //+------------------------------------------------------------+
      //| Abandonar uma criacao que falhou ao gravar.                 |
      //|                                                             |
      //| ⚠ Comando PROPRIO, e nao um LOAD_PROFILE do perfil ativo.   |
      //| Traduzido para LOAD, a distincao morria na fronteira: o EA  |
      //| aplica ali as recusas que protegem contra ADOTAR outro      |
      //| perfil — drawdown ativo, perfil ou Magic em uso por outro   |
      //| grafico —, e uma delas nega justamente o desfazer.          |
      //|                                                             |
      //| O caso e concreto: com o perfil ativo preso por outro       |
      //| grafico, CRIAR PERFIL e uma saida deliberadamente permitida.|
      //| Se a criacao aplicar e falhar ao gravar, o DESCARTAR pediria|
      //| a volta — e a MESMA trava que motivou a criacao a recusaria,|
      //| deixando o usuario preso na retentativa.                    |
      //|                                                             |
      //| E vai com as CONFIGURACOES, nao so com o nome: reler o      |
      //| perfil ativo do disco falha justamente quando o arquivo dele|
      //| e o que sumiu. Com o estado anterior em maos, o desfazer     |
      //| independe do disco.                                          |
      //+------------------------------------------------------------+
      if(intent.kind==FCV_INTENT_RESTORE_ACTIVE)
        {
         string profileName=(intent.profile=="") ? m_snapshot.activeProfileName : intent.profile;
         command.type        = UI_COMMAND_RESTORE_ACTIVE_PROFILE;
         command.text        = profileName;
         command.hasSettings = m_hasPreCreate;
         if(m_hasPreCreate) command.settings=m_preCreateSettings;
         command.reloadScope = RELOAD_COLD;
         m_echoKind=3; m_echoProfile=profileName;
         return true;
        }

      //--- As duas que NAO chegam ao EA. Ambas sao operacoes de disco do
      //--- proprio painel, como na 1.058.
      if(intent.kind==FCV_INTENT_DELETE_PROFILE)
        {
         ExecuteDelete(intent.profile);
         return false;
        }

      if(intent.kind==FCV_INTENT_DUPLICATE)
        {
         ExecuteDuplicate(intent.profile);
         return false;
        }

      return false;
     }

   void              ExecuteDelete(const string profileName)
     {
      if(profileName=="") return;
      //--- Apagar o perfil ATIVO deixaria o EA operando sobre um arquivo que
      //--- nao existe mais. A tela ja nao oferece, mas o estado pode ter mudado
      //--- desde o desenho — e este e o unico ponto que apaga de verdade.
      if(FusionSanitizeProfileName(profileName)==
         FusionSanitizeProfileName(m_snapshot.activeProfileName))
        {
         m_renderer.SetNotice("PERFIL NAO EXCLUIDO",
                              "O perfil "+profileName+" e o perfil ativo deste grafico. "+
                              "Carregue outro antes de apaga-lo.",FCV_SEM_BAD);
         return;
        }
      string reason="";
      if(ProfileLockedByPeer(profileName,reason))
        {
         m_renderer.SetNotice("PERFIL NAO EXCLUIDO",
                              (reason!="") ? reason
                              : "O perfil "+profileName+" esta em uso por outro grafico.",
                              FCV_SEM_BAD);
         RefreshProfiles();
         return;
        }
      if(m_store.DeleteProfile(profileName))
        {
         RefreshProfiles();
         //--- Confirmacao expira; recusa nao. Quem le "deu certo" nao precisa
         //--- fazer nada com a informacao, e o aviso vira sujeira depois de
         //--- alguns segundos. Recusa pede uma decisao, e some so quando o
         //--- usuario volta a agir — que e justamente quando ele decidiu.
         m_renderer.SetNotice("PERFIL EXCLUIDO",
                              "O perfil "+profileName+" foi apagado do disco.",
                              FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
         return;
        }
      RefreshProfiles();
      m_renderer.SetNotice("PERFIL NAO EXCLUIDO",
                           "Nao foi possivel apagar o arquivo de "+profileName+".",FCV_SEM_BAD);
     }

   void              ExecuteDuplicate(const string sourceName)
     {
      if(sourceName=="") return;
      SEASettings source;
      if(!m_store.LoadProfile(sourceName,source))
        {
         RefreshProfiles();
         m_renderer.SetNotice("NAO FOI POSSIVEL DUPLICAR",
                              "O arquivo de "+sourceName+" nao pode ser lido.",FCV_SEM_BAD);
         return;
        }
      m_renderer.BeginDuplicate(source,SuggestedDuplicateName(sourceName),sourceName);
     }

public:
                     CFusionCanvasPanel(void)
     {
      m_created=false; m_lastActiveProfile=""; m_chartId=0;
      m_echoKind=0; m_echoProfile=""; m_staleProfile="";
      m_hasPreCreate=false; m_preCreateStale="";
      SetDefaultSettings(m_preCreateSettings);
     }

   //--- Ciclo de vida. O renderizador da Fase 1 ja faz isto de verdade.
   bool              CreatePanel(const long chartId,const string name,const int subwin,
                                 const int x1,const int y1,const int x2,const int y2,
                                 const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      m_chartId=chartId;
      //--- Antes do Create: ele ja desenha o primeiro quadro, e desenhar com
      //--- dado neutro para so depois receber o real causaria um piscada.
      m_renderer.SetSnapshot(m_snapshot);
      //--- TODO Fase 3: paleta/tema/escala vem de input do EA, nao existe
      //--- ainda um caminho para eles chegarem aqui. Petroleo/Automatico por
      //--- ora, igual ao harness da Fase 1.
      m_created=m_renderer.Create(chartId,name,FUSION_CANVAS_THEME_AUTO,
                                  FUSION_PALETTE_PETROLEO,true,x1,y1);
      if(m_created)
        {
         RefreshProfiles();
         m_lastActiveProfile=m_snapshot.activeProfileName;
        }
      return m_created;
     }

   bool              StartDialog(void) { return m_created; }

   void              Destroy(const int reason=REASON_REMOVE)
     {
      if(m_created) m_renderer.Destroy();
      m_created=false;
     }

   void              ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(m_created) m_renderer.ChartEvent(id,lparam,dparam,sparam);
     }

   //--- Dados reais entrando. TODAS as telas leem daqui: cabecalho, Status,
   //--- Resultados, Estrategias, Filtros, Gestao, Perfis e Layout — as de
   //--- configuracao pelo rascunho de SEASettings, via identificador de campo
   //--- por controle; Perfis tambem pela lista lida do disco.
   void              Update(const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      if(!m_created) return;
      //--- Trocou o perfil ativo: relê o disco antes de desenhar, senao a lista
      //--- mostraria o estado anterior e o selo ATIVO ficaria na linha errada.
      if(m_snapshot.activeProfileName!=m_lastActiveProfile)
        {
         RefreshProfiles();
         m_lastActiveProfile=m_snapshot.activeProfileName;
        }
      //--- Botao ATUALIZAR: a lista e estado de disco e muda por fora, entao
      //--- precisa de um gatilho manual alem da troca de perfil ativo.
      else if(m_renderer.ConsumeProfileRefreshRequest())
         RefreshProfiles();
      //--- Chegou Update com uma gravacao pendente de resposta: o EA recusou.
      //--- Ele registra o motivo no log, mas o painel nao pode ficar calado —
      //--- da tela, o clique em SALVAR simplesmente nao teria feito nada.
      //--- Chegou Update com um pedido pendente de resposta: o EA recusou.
      //--- A recusa da restauracao merece texto proprio — ali o formulario
      //--- continua aberto de proposito, e dizer "as alteracoes continuam
      //--- pendentes" descreveria outra coisa.
      if(m_echoKind==3)
        {
         m_renderer.SetNotice("NAO FOI POSSIVEL ABANDONAR",
                              "O EA nao recarregou o perfil "+m_echoProfile+
                              ". O formulario continua aberto; o motivo esta no log.",
                              FCV_SEM_BAD);
         ClearEcho();
        }
      else if(m_echoKind!=0)
        {
         //+---------------------------------------------------------+
         //| Recusa: o EA voltou sem recarregar o painel.             |
         //|                                                          |
         //| ⚠ "Recusou" NAO significa "nada aconteceu". `ApplySettings`|
         //| atribui m_settings, recarrega execucao e protecoes, e so |
         //| DEPOIS devolve o resultado do ReloadAll — um indicador   |
         //| que nao recria seus handles a faz responder `false` com a|
         //| sessao ja alterada. O chamador entende como "nao aplicado"|
         //| e volta sem tocar no painel.                             |
         //|                                                          |
         //| Entao aqui tambem se PERGUNTA AO DISCO, em vez de deduzir|
         //| do sinal — mesma escolha do AnnounceSaveOutcome, pelo    |
         //| mesmo motivo. Assim o aviso e o estado ficam certos      |
         //| independentemente de qual caminho o EA tomou.            |
         //+---------------------------------------------------------+
         bool landed=SaveLandedOnDisk(m_snapshot.settings);
         m_renderer.SetPersistenceFailed(!landed);
         m_staleProfile = landed ? "" : m_snapshot.activeProfileName;
         //--- Aqui o formulario NAO foi fechado (o ReloadFromEA nem rodou), entao
         //--- a criacao continua na tela e o DESCARTAR precisa saber desfazer.
         m_renderer.NoteFailedCreate(!landed && m_echoKind==2);
         if(landed && m_echoKind==2) { m_hasPreCreate=false; m_preCreateStale=""; }
         m_renderer.SetNotice("GRAVACAO NAO CONFIRMADA",
                              "O EA nao concluiu a gravacao do perfil "+m_echoProfile+
                              ". O motivo esta no log.",FCV_SEM_BAD);
         ClearEcho();
        }
      m_renderer.SetSnapshot(m_snapshot);
      m_renderer.Render();
     }

   void              LoadSettings(const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      LoadSettings(snapshot.settings,snapshot.activeProfileName,snapshot.symbolSpec);
     }

   //+---------------------------------------------------------------+
   //| RECARGA — e nao mais um apelido de Update.                     |
   //|                                                                |
   //| O EA chama por aqui depois de aplicar um perfil (carga,        |
   //| gravacao, restauracao). E o unico caminho em que o valor de    |
   //| origem muda POR DECISAO DO USUARIO no meio de uma edicao — o   |
   //| caso residual que o plano deixou como decisao de politica.     |
   //|                                                                |
   //| Politica adotada: o EA vence, com aviso. Carregar um perfil e  |
   //| um clique deliberado; manter na tela o texto digitado antes    |
   //| dele contradiria a acao que o usuario acabou de pedir. E o     |
   //| aviso existe porque descartar em silencio faria o valor sumir  |
   //| sem explicacao.                                                |
   //+---------------------------------------------------------------+
   void              LoadSettings(const SEASettings &settings,const string profileName,
                                  const SSymbolSpec &spec)
     {
      m_snapshot.settings=settings;
      m_snapshot.activeProfileName=profileName;
      m_snapshot.symbolSpec=spec;
      m_snapshot.symbol=spec.symbol;
      if(!m_created) return;
      //--- Ordem importa: o comprometido precisa ser o novo ANTES de o rascunho
      //--- ser puxado para ele. Invertido, a recarga devolveria os campos ao
      //--- perfil ANTERIOR e o novo so apareceria no quadro seguinte.
      m_renderer.SetSnapshot(m_snapshot);
      //--- A resposta vem ANTES da recarga: e ela que decide se o formulario de
      //--- criacao continua aberto, e quem fecha o formulario e o ReloadFromEA.
      //--- O eco de restauracao (3) nao tem gravacao a conferir: ele so precisa
      //--- ter CHEGADO. Trata-lo como sucesso aqui e o que fecha o formulario.
      bool saved=(m_echoKind==0 || m_echoKind==3) || SaveLandedOnDisk(settings);
      //--- Esta recarga e a RESPOSTA ao nosso pedido: o rascunho nao se perdeu,
      //--- foi gravado. O aviso do ReloadFromEA descreveria uma perda que nao
      //--- houve, entao e substituido por AnnounceSaveOutcome.
      m_renderer.ReloadFromEA("Os campos passaram a mostrar o perfil "+profileName+
                              ". O que estava sendo editado e nao foi salvo se perdeu.",
                              (m_echoKind==2 && !saved));
      //+------------------------------------------------------------+
      //| Trocou o perfil ativo com um arquivo para tras.             |
      //|                                                             |
      //| CARREGAR continua permitido nesse estado, e isto e escolha: |
      //| bloquea-lo com o disco quebrado deixaria o usuario sem saida|
      //| — e o principio de que carregar outro perfil E a saida ja   |
      //| vale aqui para o perfil preso por outro grafico.            |
      //|                                                             |
      //| O que nao pode e a perda ser silenciosa. Mesma politica ja  |
      //| adotada para a recarga: o EA vence, com aviso.              |
      //+------------------------------------------------------------+
      if(profileName!=m_lastActiveProfile)
        {
         if(m_staleProfile!="" && m_echoKind==0)
            m_renderer.SetNotice("CONFIGURACAO NAO GRAVADA DESCARTADA",
                                 "A configuracao que nao chegou ao arquivo de "+
                                 m_staleProfile+" foi substituida pelo perfil "+
                                 profileName+".",FCV_SEM_WARN);
         m_renderer.SetPersistenceFailed(false);
         m_staleProfile="";
        }
      if(m_echoKind!=0)
        {
         AnnounceSaveOutcome(saved);
         ClearEcho();
        }
      RefreshProfiles();
      m_lastActiveProfile=profileName;
      m_renderer.Render();
     }

   //+---------------------------------------------------------------+
   //| Comandos saindo. Cada intencao publicada pelo renderizador e   |
   //| reconferida aqui contra o disco e os registros do terminal —   |
   //| e so entao vira comando do EA.                                 |
   //|                                                                |
   //| O EA chama em laco (`while(ConsumeCommand(c)) Handle(c)`), e   |
   //| o laco termina quando nao ha mais intencao. Uma intencao que   |
   //| se resolve aqui dentro (excluir, duplicar) ou que e recusada   |
   //| nao interrompe a drenagem: seguimos para a proxima.            |
   //+---------------------------------------------------------------+
   bool              ConsumeCommand(SUICommand &command)
     {
      if(!m_created) return false;
      SCanvasIntent intent;
      while(m_renderer.ConsumeIntent(intent))
        {
         if(TranslateIntent(intent,command)) return true;
         //--- Recusa ou acao local: a tela ja recebeu o aviso, mas ninguem
         //--- pediu redesenho — o clique que gerou a intencao ja repintou com o
         //--- estado de antes.
         m_renderer.Render();
        }
      return false;
     }

   //--- Pendencia real, medida pela diferenca entre rascunho e comprometido.
   //--- O EA a consulta para avisar antes de fechar o grafico.
   bool              HasUnsavedDraftChanges(void)
     { return m_created && m_renderer.HasPendingChanges(); }
  };

#endif
