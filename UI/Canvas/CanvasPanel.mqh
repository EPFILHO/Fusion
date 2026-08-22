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

//+------------------------------------------------------------------+
//| Namespace tecnico dos objetos deste painel.                       |
//|                                                                   |
//| ⚠ NAO derivado do nome do programa, e a diferenca e o ponto.      |
//| O EA passa "EP Fusion" no CreatePanel, e usar isso como prefixo   |
//| de objeto significava que a limpeza — que apaga POR PREFIXO —     |
//| alcancava qualquer objeto do grafico comecando por "EP Fusion",   |
//| inclusive um desenho do usuario. Improvavel, mas irreversivel.    |
//|                                                                   |
//| Um namespace tecnico proprio resolve os dois lados: nao e um nome |
//| que alguem escolheria para uma anotacao no grafico, e o escopo do |
//| ObjectsDeleteAll fica trivial de auditar — e literalmente isto.   |
//|                                                                   |
//| Nao colide com nada existente: o painel classico cria a casca do  |
//| dialogo sob um prefixo NUMERICO do CAppDialog (m_instance_id, um  |
//| rand de 5 digitos) e seus 274 controles sob nomes fixos iniciados |
//| por "Fusion_"; a legenda dos indicadores vive em                  |
//| "Fusion_indicator_legend_". Nenhum comeca por "Fusion2".          |
//|                                                                   |
//| O ponto final faz parte do namespace: sem ele, um prefixo futuro  |
//| "Fusion2.Canvas2" seria varrido junto por engano.                 |
//+------------------------------------------------------------------+
#define FCV_OBJ_NAMESPACE "Fusion2.Canvas."

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
   int                   m_echoKind;     // 0 nenhum, 1 SALVAR do perfil ativo
   string                m_echoProfile;
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

   //--- ⚠ SO o SALVAR do perfil ATIVO chega aqui. A criacao nao passa mais pelo
   //--- EA: ela grava direto em disco, confirma pelo retorno do store e nao tem
   //--- eco a interpretar.
   void              AnnounceSaveOutcome(const bool saved)
     {
      //--- A marca fica ATE a proxima gravacao bem-sucedida: e ela que mantem o
      //--- SALVAR aceso para o usuario tentar de novo, e que faz o EA avisar ao
      //--- fechar o grafico que ha algo por gravar.
      m_renderer.SetPersistenceFailed(!saved);
      m_staleProfile = saved ? "" : m_snapshot.activeProfileName;

      if(saved)
        {
         m_renderer.SetNotice("PERFIL SALVO",
                              "As alteracoes foram gravadas em "+m_echoProfile+".",
                              FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
         return;
        }
      //--- Sem prazo: e recusa, e recusa pede decisao. E o texto separa as duas
      //--- metades do que aconteceu — a configuracao VALE agora, o arquivo NAO
      //--- foi escrito —, porque dizer so "falhou" faria o usuario procurar na
      //--- tela uma alteracao que nao se perdeu.
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
            //--- esta em uso por outro Fusion em execucao"). Prefixar com a minha
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

      //--- ⚠ NAO vira UI_COMMAND. Ate aqui a criacao era traduzida para
      //--- UI_COMMAND_SAVE_PROFILE — o MESMO comando do SALVAR —, e o EA
      //--- aplicava a configuracao antes de gravar. Dali vinha tudo: o perfil
      //--- nascia ativo sem ninguem ter pedido, uma falha de disco deixava a
      //--- configuracao valendo sob o nome do perfil anterior, e desfazer isso
      //--- exigia um verbo proprio de rollback.
      //---
      //--- Criar e operacao de DISCO, como o EXCLUIR. O motor nao muda, entao
      //--- nao ha o que desfazer.
      if(intent.kind==FCV_INTENT_CREATE_PROFILE)
        {
         ExecuteCreate(intent.profile,intent.magic,intent.settings);
         return false;
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
         //--- ⚠ ULTIMA porta antes de o EA aplicar. O ramo de LOAD_PROFILE em
         //--- EAApplicationCommands le, resolve timeframes e chama
         //--- ApplySettings — nao ha ali validacao de lote, stops ou plano
         //--- parcial contra o simbolo. A lacuna e ANTERIOR a este item; ela so
         //--- ficou alcancavel porque agora e possivel guardar em disco um
         //--- perfil valido para OUTRO ativo.
         //---
         //--- ⚠ Validado o que o EA VAI APLICAR, e nao o que o arquivo traz. O
         //--- motor normaliza timeframe legado antes de aplicar; validando o
         //--- alvo cru, um perfil antigo com campo zerado seria recusado aqui
         //--- por algo que o EA teria consertado sozinho. A copia e local — nem
         //--- o arquivo nem `target` sao alterados para validar — e o fallback e
         //--- o MESMO do snapshot, para os dois caminhos concordarem.
         SEASettings candidate=target;
         ResolveOperationalTimeframes(candidate,m_snapshot.operationalFallbackTimeframe);

         //--- Validado o ALVO, e nao o rascunho do perfil ativo, e no escopo
         //--- completo — aqui o ativo atual e criterio, porque carregar E adotar.
         string cfgTab="", cfgError="";
         if(!m_renderer.SettingsValidForSymbol(candidate,cfgTab,cfgError))
           {
            //--- ⚠ O texto NAO manda "corrigir em <aba>": o perfil recusado nao e
            //--- o ativo, e a GUI so edita o ativo. Pior, ele nao pode virar
            //--- ativo aqui — a incompatibilidade e justamente o motivo da
            //--- recusa. A rota que existe vem de FusionProfileFixElsewhereHint.
            m_renderer.SetNotice("PERFIL INCOMPATIVEL COM "+m_snapshot.symbol,
                                 "O perfil "+profileName+" nao foi carregado porque "+
                                 "sua configuracao nao e valida para "+m_snapshot.symbol+
                                 ": "+cfgError+" "+
                                 FusionProfileFixElsewhereHint(cfgTab,
                                       "tente carrega-lo novamente aqui"),
                                 FCV_SEM_BAD);
            return false;
           }

         //--- ⚠ PORTA PROPRIA DA IDENTIDADE. `SettingsValidForSymbol` entra no
         //--- modo DUP de proposito, e ali `ScreenErrorProfiles` nao roda — logo
         //--- a validacao acima nao diz NADA sobre o Magic. Sem esta reconferencia
         //--- sobrariam dois furos: Magic <= 0 num arquivo editado por fora, e a
         //--- colisao que outro grafico criou depois do ultimo "Atualizar lista"
         //--- (o `m_profDup` do botao vem da lista em memoria, nao do disco).
         string magicOwner="";
         if(!MagicFreeOnDisk(target.magicNumber,profileName,magicOwner))
           {
            RefreshProfiles();
            m_renderer.SetNotice("PERFIL NAO CARREGADO",
                                 (target.magicNumber<=0)
                                 ? "O perfil "+profileName+" tem Magic invalido: "+
                                   "ele precisa ser um inteiro positivo."
                                 : "O Magic "+IntegerToString(target.magicNumber)+
                                   " de "+profileName+" ja pertence ao perfil "+
                                   magicOwner+". Corrija um dos dois antes de carregar.",
                                 FCV_SEM_BAD);
            return false;
           }
         command.type=UI_COMMAND_LOAD_PROFILE;
         command.text=profileName;
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

   //+---------------------------------------------------------------+
   //| CRIAR PERFIL / CRIAR COPIA — gravacao, e SO gravacao.          |
   //|                                                                |
   //| Irmao do ExecuteDelete: opera o disco pelo store do painel e   |
   //| nao manda nada ao EA. Nenhuma chamada daqui alcanca            |
   //| ApplySettings, ReloadAll, PrimeEntryStates, PersistChartState, |
   //| m_activeProfileName ou o registro de instancia — o motor       |
   //| termina esta funcao exatamente como comecou.                   |
   //|                                                                |
   //| E dai vem a melhor propriedade do desenho: uma gravacao que    |
   //| FALHA nao precisa de desfazer. Nao ha estado hibrido a         |
   //| reconciliar, entao o formulario so continua aberto para a      |
   //| retentativa.                                                   |
   //|                                                                |
   //| ⚠ Nao mexe na DIVIDA DE PERSISTENCIA do perfil ativo           |
   //| (`m_staleProfile`). Ela e sobre outro arquivo, e criar um      |
   //| perfil novo nao a quita nem a agrava.                          |
   //+---------------------------------------------------------------+
   void              ExecuteCreate(const string rawName,const int magic,
                                   const SEASettings &source)
     {
      //--- SANEADO aqui, como a 1.058 faz. O renderizador manda o texto cru
      //--- porque ele nao conhece a regra de nome de arquivo — ela e do store, e
      //--- o store e deste lado.
      //---
      //--- Sem isto o perfil nascia com DUAS identidades: o arquivo virava
      //--- "Meu_Perfil.cfg" e aparecia assim na lista, enquanto o cabecalho e o
      //--- aviso diziam "Meu Perfil".
      string newName=m_store.SanitizeProfileName(rawName);
      if(newName=="")
        {
         m_renderer.SetNotice("NOME OBRIGATORIO",
                              "Informe um nome para o perfil novo.",FCV_SEM_BAD);
         return;
        }

      //--- ⚠ TRAVA PRESERVADA, e nao herdada por acidente. Ate aqui o drawdown
      //--- travado recusava a criacao por efeito colateral: ela passava por
      //--- ApplySettings, que nega mudanca de Magic com o DD ativo — e toda
      //--- criacao muda o Magic, porque exige um numero livre. Saindo do EA, a
      //--- recusa desapareceria sozinha. Mantida aqui de proposito: ampliar
      //--- quando criar funciona nao e assunto deste item.
      if(m_snapshot.drawdownConfigLocked)
        {
         m_renderer.SetNotice("PERFIL NAO CRIADO",
                              (m_snapshot.drawdownConfigLockReason!="")
                              ? m_snapshot.drawdownConfigLockReason
                              : "A protecao de drawdown esta travando a configuracao.",
                              FCV_SEM_BAD);
         return;
        }

      //--- Reconferencia em disco, e nao na lista em memoria: e o unico jeito de
      //--- ver o arquivo que outro grafico criou desde a ultima leitura —
      //--- inclusive um que nem abre, e que ainda assim ocupa o nome. Fica
      //--- imediatamente antes da gravacao para encolher a janela de corrida,
      //--- que sem lock de arquivo nao fecha.
      if(!NameFreeOnDisk(newName))
        {
         RefreshProfiles();
         m_renderer.SetNotice("NOME JA EXISTE",
                              "Ja existe um perfil chamado "+newName+" em disco. "+
                              "Escolha outro nome.",FCV_SEM_BAD);
         return;
        }
      string owner="";
      if(!MagicFreeOnDisk(magic,newName,owner))
        {
         RefreshProfiles();
         m_renderer.SetNotice("MAGIC JA USADO",
                              (magic<=0)
                              ? "Informe um Magic inteiro positivo."
                              : "O Magic "+IntegerToString(magic)+
                                " ja pertence ao perfil "+owner+". Escolha outro numero.",
                              FCV_SEM_BAD);
         return;
        }

      SEASettings settings=source;
      //--- O Magic do formulario vence o da origem: a origem descreve o perfil
      //--- ATIVO (ou, numa duplicacao, o de origem), e o numero novo e
      //--- justamente o que distingue o perfil que esta nascendo.
      settings.magicNumber=magic;
      //--- ⚠ MESMA normalizacao do caminho anterior, com o MESMO fallback. O EA
      //--- resolvia com `OperationalFallbackTimeframe()`; o painel nao calcula
      //--- esse valor, entao ele vem pronto no snapshot. Escolher outro aqui —
      //--- `Period()`, ou uma constante — faria dois caminhos de gravacao
      //--- discordarem sobre a mesma configuracao. So age sobre campo zerado,
      //--- herdado de arquivo antigo: `FusionLoadProfile` converte o texto sem
      //--- validar, entao um perfil legado chega aqui com o zero intacto.
      ResolveOperationalTimeframes(settings,m_snapshot.operationalFallbackTimeframe);
      //--- Corta na precisao que o arquivo guarda, para o que fica em memoria ser
      //--- exatamente o que foi para o disco.
      FusionApplyStoragePrecision(settings);

      if(!m_store.SaveProfile(newName,settings))
        {
         RefreshProfiles();
         //--- Sem prazo: e recusa, e recusa pede decisao. E o texto diz o que NAO
         //--- aconteceu, porque aqui isso e a informacao principal.
         m_renderer.SetNotice("PERFIL NAO CRIADO",
                              "O arquivo de "+newName+" nao foi escrito. Nada mudou "+
                              "neste grafico: o perfil ativo e a configuracao em uso "+
                              "continuam como estavam. Clique de novo para tentar mais "+
                              "uma vez, ou DESCARTAR para sair.",FCV_SEM_BAD);
         return;
        }

      RefreshProfiles();
      m_renderer.EndProfileFormSelecting(newName);
      m_renderer.SetNotice("PERFIL CRIADO",
                           "Perfil "+newName+" criado e selecionado. Clique CARREGAR "+
                           "para ativa-lo neste grafico.",
                           FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
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
      m_renderer.BeginDuplicate(source,SuggestedDuplicateName(sourceName));
     }

public:
                     CFusionCanvasPanel(void)
     {
      m_created=false; m_lastActiveProfile=""; m_chartId=0;
      m_echoKind=0; m_echoProfile=""; m_staleProfile="";
     }

   //--- Ciclo de vida. O renderizador da Fase 1 ja faz isto de verdade.
   //+------------------------------------------------------------------+
   //| ⚠ A assinatura ENCOLHEU na Fase 4: sairam name, subwin, x2 e y2.  |
   //|                                                                   |
   //| Os quatro existiam por causa de CFusionPanel, que herdava de      |
   //| CAppDialog: `name` era a legenda do dialogo, `subwin` a           |
   //| subjanela, e x2,y2 fechavam o retangulo. Esta classe nunca leu    |
   //| nenhum deles — o prefixo dos objetos e FCV_OBJ_NAMESPACE, o       |
   //| titulo e desenhado por ela, o bitmap vive sempre na janela 0, a   |
   //| largura e FCV_PANEL_W e a altura sai de DecidePanelHeight().      |
   //|                                                                   |
   //| Enquanto os dois paineis conviviam a assinatura TINHA de ser      |
   //| identica nos dois lados: era ela que fazia o compilador garantir  |
   //| a troca (secao 5 do plano). Com um painel so, manter os quatro    |
   //| seria afirmar que o painel aceita coisas que ele ignora.          |
   //+------------------------------------------------------------------+
   bool              CreatePanel(const long chartId,
                                 const int x,const int y,
                                 const SUIPanelSnapshot &snapshot)
     {
      m_snapshot=snapshot;
      m_chartId=chartId;
      //+---------------------------------------------------------------+
      //| Sobras do PROPRIO canvas, antes de desenhar por cima.          |
      //|                                                                |
      //| O Destroy ja limpa na saida ordenada — inclusive ao remover o  |
      //| EA do grafico, que e como a troca de painel acontece. Isto     |
      //| cobre a saida que NAO roda Destroy: terminal encerrado de      |
      //| forma anormal com o painel no ar.                              |
      //|                                                                |
      //| ⚠ Cobre so os objetos DESTE painel, e a promessa e essa.       |
      //|                                                                |
      //| Sobras do painel CLASSICO nao sao alcancadas daqui, e a Fase 4 |
      //| decidiu por escrito nao acrescentar codigo para isso: a casca  |
      //| do dialogo dele nascia sob um prefixo numerico do CAppDialog e |
      //| seus controles sob nomes fixos `Fusion_*`, e varrer aquilo     |
      //| seria escrever uma limpeza nova dentro da fase que existe para |
      //| REMOVER codigo. Na troca normal o assunto nem aparece: trocar  |
      //| o EA do grafico roda o Destroy do painel que sai. O caso       |
      //| descoberto e o terminal encerrado de forma anormal com o       |
      //| painel antigo no ar — ali as sobras se apagam uma vez, pela    |
      //| lista de objetos do grafico.                                   |
      //|                                                                |
      //| Saiu junto a limpeza de compatibilidade dos nomes que builds   |
      //| anteriores do canvas usaram ("EP Fusioncanvas", "EP           |
      //| Fusionedit_"): eram anteriores a correcao do namespace, nunca  |
      //| sairam da maquina de desenvolvimento, e ja fizeram o trabalho. |
      //+---------------------------------------------------------------+
      ObjectsDeleteAll(chartId,FCV_OBJ_NAMESPACE);
      //--- Antes do Create: ele ja desenha o primeiro quadro, e desenhar com
      //--- dado neutro para so depois receber o real causaria um piscada.
      m_renderer.SetSnapshot(m_snapshot);
      //+---------------------------------------------------------------+
      //| Paleta, tema e escala: por que nao ha input do EA aqui.        |
      //|                                                                |
      //| A Fase 2 deixou isto marcado como pendencia da Fase 3, com a   |
      //| leitura de que faltava um caminho do EA ate ca. Faltava — mas  |
      //| conferido o mecanismo, ele nao e necessario: os tres sao       |
      //| escolhidos na aba Layout e ficam em variavel global do         |
      //| terminal (CanvasRendererPrefs.mqh), valendo para todo grafico  |
      //| e sobrevivendo a fechar o MT5. O `true` abaixo e esse lembrar. |
      //|                                                                |
      //| Um input so governaria a PRIMEIRA abertura de todas: a partir  |
      //| da segunda a preferencia salva vence, de proposito (ela e a    |
      //| ultima escolha consciente do usuario). Input que deixa de      |
      //| valer depois do primeiro uso engana mais do que ajuda —        |
      //| mudariam o valor, nada aconteceria, e a explicacao estaria     |
      //| escondida em outro arquivo.                                    |
      //|                                                                |
      //| Petroleo/Automatico sao, entao, o padrao de fabrica: valem uma |
      //| vez, ate a primeira escolha na aba Layout.                     |
      //+---------------------------------------------------------------+
      //--- O prefixo dos objetos e uma constante nossa (FCV_OBJ_NAMESPACE), e nao
      //--- um nome vindo do EA: nenhum OUTRO objeto do grafico comeca por
      //--- "Fusion2", e e isso que mantem a limpeza estreita.
      //--- ⚠ Nao alargar para "Fusion_": sob esse prefixo vive a LEGENDA DAS
      //--- MEDIAS (Fusion_indicator_legend_*, seis objetos criados por
      //--- UI/IndicatorLegendOverlay.mqh), que e do grafico e nao do painel.
      //--- As LINHAS em si nao sao objeto: sao indicadores anexados por
      //--- ChartIndicatorAdd, com nome "Fusion Visual MA|BB|RSI <chartId>".
      m_created=m_renderer.Create(chartId,FCV_OBJ_NAMESPACE,FUSION_CANVAS_THEME_AUTO,
                                  FUSION_PALETTE_PETROLEO,true,x,y);
      if(m_created)
        {
         RefreshProfiles();
         m_lastActiveProfile=m_snapshot.activeProfileName;
        }
      return m_created;
     }

   bool              StartDialog(void) { return m_created; }

   //--- Retangulo interativo do painel, somente leitura. FALSE quando nao ha
   //--- painel na tela — nao criado, destruido ou desabilitado —, e nesse caso
   //--- nao existe area proibida para ninguem.
   bool              GetInteractiveRect(int &left,int &top,int &right,int &bottom)
     {
      left = top = right = bottom = 0;
      if(!m_created)
         return false;
      m_renderer.PanelInteractiveRect(left, top, right, bottom);
      return (right > left && bottom > top);
     }

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
      //--- Chegou Update com uma gravacao pendente de resposta: o EA recusou o
      //--- SALVAR. Ele registra o motivo no log, mas o painel nao pode ficar
      //--- calado — da tela, o clique simplesmente nao teria feito nada.
      //---
      //--- ⚠ "Recusou" NAO significa "nada aconteceu". `ApplySettings` atribui
      //--- m_settings, recarrega execucao e protecoes, e so DEPOIS devolve o
      //--- resultado do ReloadAll — um indicador que nao recria seus handles a
      //--- faz responder `false` com a sessao ja alterada. Por isso aqui tambem
      //--- se PERGUNTA AO DISCO, em vez de deduzir do sinal: mesma escolha do
      //--- AnnounceSaveOutcome, pelo mesmo motivo.
      //---
      //--- A criacao nao chega mais aqui — ela nao vira comando, e responde pelo
      //--- retorno do store no proprio ExecuteCreate.
      if(m_echoKind!=0)
        {
         bool landed=SaveLandedOnDisk(m_snapshot.settings);
         m_renderer.SetPersistenceFailed(!landed);
         m_staleProfile = landed ? "" : m_snapshot.activeProfileName;
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
      //--- Sem eco pendente nao ha gravacao a conferir.

      bool saved=(m_echoKind==0) || SaveLandedOnDisk(settings);
      //--- Esta recarga e a RESPOSTA ao nosso pedido: o rascunho nao se perdeu,
      //--- foi gravado. O aviso do ReloadFromEA descreveria uma perda que nao
      //--- houve, entao e substituido por AnnounceSaveOutcome.
      m_renderer.ReloadFromEA("Os campos passaram a mostrar o perfil "+profileName+
                              ". O que estava sendo editado e nao foi salvo se perdeu.");
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
