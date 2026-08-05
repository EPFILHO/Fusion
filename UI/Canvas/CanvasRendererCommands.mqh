//+------------------------------------------------------------------+
//| CanvasRendererCommands.mqh                                        |
//| Fragmento do corpo de CFusionCanvasRenderer — Etapa 2c.           |
//|                                                                   |
//| O caminho de VOLTA: ate aqui todo dado corria do EA para a tela.  |
//| Este arquivo e a direcao contraria.                               |
//|                                                                   |
//| O renderizador NAO decide se uma acao e possivel — ele nao le      |
//| disco nem sabe o que outro grafico fez no ultimo segundo. Publica |
//| a intencao e a resposta volta como aviso. Quem reconfere e         |
//| executa e CFusionCanvasPanel.                                     |
//+------------------------------------------------------------------+

private:
//+------------------------------------------------------------------+
//| Fila de intencoes: UMA posicao.                                   |
//|                                                                   |
//| Um clique produz uma intencao, e ela e drenada antes do proximo   |
//| quadro. Mesmo desenho do m_pendingCommand da 1.058. Uma fila      |
//| maior guardaria pedidos feitos sobre uma tela que ja mudou —      |
//| exatamente o que a revalidacao existe para impedir.               |
//+------------------------------------------------------------------+
void QueueIntent(const int kind,const string profile,const int magic=0)
  {
   m_intent.kind    =kind;
   m_intent.profile =profile;
   m_intent.magic   =magic;
   //--- Rascunho copiado NO CLIQUE. Lido depois, ja poderia ter sido
   //--- sobrescrito por um snapshot que chegou no meio do caminho.
   m_intent.settings=m_draft;
   m_hasIntent      =true;
   //--- O aviso anterior respondia a uma acao que acabou de ser substituida.
   ClearNotice();
  }

//--- Nome do perfil que as acoes de lista miram. Vazio quando nao ha selecao —
//--- e ai a acao nao deveria ter sido oferecida, mas quem confere e o painel.
string SelectedProfileName(void)
  { return (m_profSel>=0 && m_profSel<m_profCount) ? m_profName[m_profSel] : ""; }

//--- Nome digitado no formulario, aparado mas NAO saneado: o saneamento e de
//--- quem grava o arquivo. ProfileFormName() devolve a chave de comparacao;
//--- este devolve o que o usuario escreveu, que e o que deve virar o perfil.
string ProfileFormRawName(void)
  { return TrimEdges(m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_NAME)]); }

//+------------------------------------------------------------------+
//| Aviso — a resposta do painel ao clique.                           |
//|                                                                   |
//| Morre quando o usuario volta a agir: navegar ou mexer em qualquer |
//| campo o apaga. Assim ele dura exatamente enquanto e a resposta a  |
//| ultima coisa feita.                                               |
//|                                                                   |
//| Alguns tambem tem PRAZO, e a distincao importa:                   |
//|                                                                   |
//|  - aviso que descreve um EVENTO passado (texto recusado, perfil   |
//|    salvo) expira sozinho — ficar na tela depois que deixou de ser |
//|    novidade e sujeira;                                            |
//|  - aviso que descreve um ESTADO em vigor (exclusao armada) NAO    |
//|    expira. Sumir enquanto o CONFIRMAR continua na tela deixaria   |
//|    um botao vermelho sem a frase que explica o que ele apaga.     |
//|                                                                   |
//| Por isso o prazo e por chamada, e o padrao e nao ter.             |
//+------------------------------------------------------------------+
void ClearNotice(void)
  {
   if(m_noticeBody=="" && m_noticeTitle=="") return;
   m_noticeTitle=""; m_noticeBody=""; m_noticeSem=FCV_SEM_NEUTRAL;
   m_noticeTtl=0;
   m_viewDirty=true;
  }

//--- Diferenca de tempos sem sinal: imune a volta do contador a zero, que
//--- acontece a cada 49 dias de terminal ligado. Comparar `agora >= limite`
//--- daria um aviso eterno exatamente quando isso ocorresse.
bool NoticeExpired(void)
  {
   if(m_noticeTtl==0 || StringLen(m_noticeBody)==0) return false;
   return ((GetTickCount()-m_noticeAt)>=m_noticeTtl);
  }

//+------------------------------------------------------------------+
//| Texto digitado que o parse recusou.                               |
//|                                                                   |
//| O campo ja voltou ao valor bom sozinho — este e o recado que      |
//| explica por que. Cita o que foi digitado porque e a unica coisa   |
//| que o usuario reconhece: "nao e um numero" sem o texto ao lado    |
//| deixa a duvida de QUAL campo reclamou.                            |
//+------------------------------------------------------------------+
void RejectTypedText(const string typed,const int kind)
  {
   //--- Texto longo cortado: a caixa cresce com o conteudo, e um campo colado
   //--- de um documento inteiro empurraria a area util para fora da tela.
   string shown=TrimEdges(typed);
   if(StringLen(shown)>24) shown=StringSubstr(shown,0,24)+"...";
   if(StringLen(shown)==0) shown="(vazio)";
   SetNotice("VALOR NAO ACEITO",
             "\""+shown+"\" nao e um numero"+
             ((kind==FCV_FTYPE_DEC) ? " (use ponto ou virgula para decimais)" : "")+
             ". O campo voltou ao valor anterior.",
             FCV_SEM_WARN,FCV_NOTICE_TTL_MS);
  }

//+------------------------------------------------------------------+
//| Confirmacao da exclusao.                                          |
//|                                                                   |
//| Apagar perfil e irreversivel e nao tem desfazer. A confirmacao    |
//| acontece no PROPRIO cartao — o botao vermelho vira CONFIRMAR e    |
//| ganha um VOLTAR ao lado —, e nao num popup: o popup teria de      |
//| suprimir os campos nativos sob ele (regra do modelo hibrido) e    |
//| esconderia justamente a linha do perfil que esta prestes a sumir. |
//|                                                                   |
//| Ela cai sozinha em toda mudanca de contexto. Uma confirmacao      |
//| armada que sobrevive a uma troca de selecao apontaria para outro  |
//| perfil, e o segundo clique apagaria o errado.                     |
//+------------------------------------------------------------------+
void ArmDeleteConfirm(void)
  {
   m_delConfirm=true;
   //--- Sem prazo: este aviso descreve um ESTADO em vigor. Sumindo sozinho,
   //--- deixaria os dois botoes na tela sem a frase que diz o que eles fazem.
   SetNotice("CONFIRMAR EXCLUSAO",
             "O perfil "+SelectedProfileName()+" sera apagado DEFINITIVAMENTE. "+
             "Clique SIM para confirmar ou NAO para cancelar.",FCV_SEM_BAD);
  }

void CancelDeleteConfirm(void)
  {
   if(!m_delConfirm) return;
   m_delConfirm=false;
   ClearNotice();
   m_viewDirty=true;
  }

//+------------------------------------------------------------------+
//| Recarga deliberada do rascunho.                                   |
//|                                                                   |
//| Usada pelo CANCELAR e pelo LoadSettings do EA (carga de perfil,   |
//| restauracao). Nos dois casos o comprometido passa a mandar e o    |
//| que estava sendo digitado e descartado — e a politica de conflito |
//| decidida para a 2d: quem pediu a troca foi o usuario, e manter o  |
//| texto velho contradiria o clique que ele acabou de dar.           |
//|                                                                   |
//| Soltar o foco e parte da operacao, nao um detalhe: com um campo   |
//| em edicao, o controle interno do terminal continuaria mostrando o |
//| texto antigo por cima do valor novo — a tela diria duas coisas.   |
//+------------------------------------------------------------------+
void ReloadDraft(void)
  {
   ReleaseEditFocus();
   m_draft=m_committed;
   SyncDerivedSettings();
   
   m_viewDirty=true;
  }

//+------------------------------------------------------------------+
//| Botoes. A caixa vem do desenho, e so existe se o botao estava     |
//| habilitado — entao chegar aqui ja significa que a tela oferecia a |
//| acao. O que ela NAO garante e que a acao ainda cabe: quem         |
//| reconfere contra o disco e os registros e o painel.               |
//+------------------------------------------------------------------+
bool HandleButtonClick(const int lx,const int ly)
  {
   for(int i=0;i<m_btnCount;++i)
     {
      if(lx<m_btnX[i] || lx>=m_btnX[i]+m_btnW[i]) continue;
      if(ly<m_btnY[i] || ly>=m_btnY[i]+m_btnH[i]) continue;
      //--- Botao acima da area util e chrome (cabecalho) e nao rola; dentro
      //--- dela, so vale se ainda estiver visivel.
      if(m_btnY[i]>=ContentTop() && !InContentView(m_btnY[i],m_btnH[i])) continue;

      //--- Qualquer outro botao desarma a confirmacao pendente. Sem isto ela
      //--- ficaria armada enquanto o usuario faz outra coisa, e o proximo
      //--- clique no lugar do CONFIRMAR apagaria um perfil sem aviso.
      if(m_btnId[i]!=FCV_BTN_DELOK && m_delConfirm) CancelDeleteConfirm();

      switch(m_btnId[i])
        {
         //--- Comecar uma criacao limpa o formulario. Sem isto, cancelar e
         //--- recomecar traria de volta o que foi digitado antes.
         case FCV_BTN_NEW:
            m_profEdit=FCV_PROF_NEW;
            ClearProfileForm();
            ClearNotice();
            break;

         //--- DUPLICAR precisa do perfil de ORIGEM lido do disco, e o
         //--- renderizador nao le disco. Vai como intencao; o painel carrega o
         //--- arquivo e devolve por BeginDuplicate.
         case FCV_BTN_DUP:
            QueueIntent(FCV_INTENT_DUPLICATE,SelectedProfileName());
            break;

         //--- CRIAR PERFIL / CRIAR COPIA. O nome e o Magic saem do formulario,
         //--- que e local; o resto da configuracao sai do rascunho.
         case FCV_BTN_SAVE:
           {
            int magic=0;
            ProfileFormMagic(magic);
            QueueIntent(FCV_INTENT_CREATE_PROFILE,ProfileFormRawName(),magic);
            break;
           }

         //--- DESCARTAR sai do formulario E devolve o rascunho ao comprometido:
         //--- duplicar semeia o rascunho com o perfil de origem, e sair sem
         //--- desfazer isso deixaria a configuracao de OUTRO perfil pendente
         //--- sobre o ativo.
         //---
         //--- ⚠ Depois de uma criacao que FALHOU AO GRAVAR, abandonar nao pode
         //--- ser so fechar a tela: o EA ja aplicou a configuracao do perfil que
         //--- nao nasceu, e ela continuaria valendo sob o nome do perfil
         //--- anterior — com o SALVAR do cabecalho, que reaparece, apontando
         //--- para ele. Ali o DESCARTAR pede ao EA que RECARREGUE o perfil
         //--- ativo do disco, que e o desfazer que existe. O formulario so
         //--- fecha quando a recarga volta; recusada, ele continua aberto e a
         //--- saida perigosa segue fechada.
         case FCV_BTN_CANCEL:
            if(m_createFailed)
              {
               QueueIntent(FCV_INTENT_RESTORE_ACTIVE,m_snap.activeProfileName);
               break;
              }
            m_profEdit=FCV_PROF_VIEW;
            ClearProfileForm();
            ReloadDraft();
            ClearNotice();
            break;

         case FCV_BTN_LOAD:
            QueueIntent(FCV_INTENT_LOAD_PROFILE,SelectedProfileName());
            break;

         //--- Primeiro clique arma; o segundo, no CONFIRMAR, executa.
         case FCV_BTN_DEL:   ArmDeleteConfirm(); break;
         case FCV_BTN_DELNO: CancelDeleteConfirm(); break;
         case FCV_BTN_DELOK:
            m_delConfirm=false;
            QueueIntent(FCV_INTENT_DELETE_PROFILE,SelectedProfileName());
            break;

         //--- Rolagem da lista: move a janela, nunca a selecao. Arrastar a
         //--- selecao junto faria o usuario perder o perfil escolhido so por
         //--- olhar o resto da lista.
         case FCV_BTN_PROFUP: m_profOffset--; ClampProfileOffset(); break;
         case FCV_BTN_PROFDN: m_profOffset++; ClampProfileOffset(); break;
         //--- So registra o pedido; quem le o disco e o dono do painel.
         case FCV_BTN_PROFREFRESH: m_profRefreshWanted=true; break;

         //--- INICIAR/PAUSAR nao mexe em pendencia: ligar o EA nao e alteracao
         //--- de configuracao. Quem alterna o estado e o EA, e a tela so o
         //--- mostra quando o snapshot volta — inverter m_snap.started aqui
         //--- faria o painel afirmar um estado que talvez tenha sido recusado.
         case FCV_BTN_START:
            QueueIntent(FCV_INTENT_TOGGLE_RUN,"");
            break;

         //--- SALVAR grava o rascunho no perfil ATIVO. O comprometido nao e
         //--- atualizado aqui: ele volta pelo snapshot de resposta, e so
         //--- entao a pendencia se apaga. Atualizar por conta propria diria
         //--- "salvo" antes de saber se o EA aceitou.
         case FCV_BTN_SAVECFG:
            QueueIntent(FCV_INTENT_SAVE_ACTIVE,m_snap.activeProfileName);
            break;

         //--- CANCELAR restaura o COMPROMETIDO, nao o padrao de fabrica:
         //--- descartar edicao e voltar ao que esta salvo.
         case FCV_BTN_CANCELCFG:
            ReloadDraft();
            SetNotice("ALTERACOES DESCARTADAS",
                      "Os campos voltaram ao que esta gravado no perfil "+
                      m_snap.activeProfileName+".",FCV_SEM_GOOD,FCV_NOTICE_TTL_MS);
            break;
        }
      m_scroll=0;
      Render();
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
public:
//--- Drena a intencao. Devolve false quando nao ha nada — e o que encerra o
//--- laco de quem consome.
bool ConsumeIntent(SCanvasIntent &out)
  {
   if(!m_hasIntent) return false;
   out=m_intent;
   m_hasIntent=false;
   m_intent.kind=FCV_INTENT_NONE;
   return true;
  }

//+------------------------------------------------------------------+
//| Ha alteracao por gravar?                                          |
//|                                                                   |
//| Duas coisas diferentes cabem nesta pergunta, e so quem pergunta   |
//| de fora quer as duas somadas:                                     |
//|                                                                   |
//|  - HasPending(): o rascunho diverge do comprometido. E o que      |
//|    governa a TELA — SALVAR aceso, INICIAR travado.                |
//|  - m_notSaved: a configuracao ja foi aplicada mas o arquivo NAO   |
//|    foi escrito. A tela nao tem pendencia nenhuma (rascunho e      |
//|    comprometido sao iguais), e ainda assim ha algo por gravar.    |
//|                                                                   |
//| O EA pergunta antes de fechar o grafico, e ali o que importa e a  |
//| soma: nos dois casos o usuario perde a alteracao ao reiniciar.    |
//+------------------------------------------------------------------+
bool HasPendingChanges(void) { return (HasPending() || m_notSaved); }

//+------------------------------------------------------------------+
//| A gravacao falhou e o arquivo ficou para tras.                    |
//|                                                                   |
//| Estado proprio, e nao pendencia de rascunho, porque nao E uma:    |
//| o EA aplicou a configuracao, entao rascunho e comprometido sao    |
//| iguais e nao ha o que "descartar". Tratar como pendencia acenderia|
//| o CANCELAR, que nao teria o que desfazer, e travaria o INICIAR    |
//| por uma configuracao que ja esta valendo e valida.                |
//|                                                                   |
//| O que ele PRECISA fazer e manter o SALVAR aceso. Sem isto o painel|
//| dizia "PERFIL NAO GRAVADO" com os tres botoes apagados e nenhuma  |
//| forma de tentar de novo — um beco, e a licao 2 da secao 8 do      |
//| plano existe exatamente para isso: todo bloqueio precisa de saida |
//| pela propria GUI.                                                 |
//+------------------------------------------------------------------+
void SetPersistenceFailed(const bool failed)
  {
   if(m_notSaved==failed) return;
   m_notSaved=failed;
   m_viewDirty=true;
  }

//--- A ultima CRIACAO falhou ao gravar e o formulario ficou aberto para a
//--- retentativa. Estado separado de m_notSaved porque muda o significado do
//--- DESCARTAR: aqui abandonar exige desfazer, e nao so fechar a tela.
void NoteFailedCreate(const bool failed)
  {
   if(m_createFailed==failed) return;
   m_createFailed=failed;
   m_viewDirty=true;
  }

//--- Resposta a uma intencao, ou a qualquer outra coisa que o painel precise
//--- dizer. Aparece na caixa de aviso. `ttlMs` = 0 e o padrao: sem prazo.
void SetNotice(const string title,const string body,const int sem,const uint ttlMs=0)
  {
   m_noticeTitle=title;
   m_noticeBody =body;
   m_noticeSem  =sem;
   m_noticeAt   =GetTickCount();
   m_noticeTtl  =ttlMs;
   m_viewDirty  =true;
  }

//+------------------------------------------------------------------+
//| Duplicacao: o painel leu o perfil de origem e devolve aqui.       |
//|                                                                   |
//| O rascunho recebe a configuracao DA ORIGEM — e o que faz a copia  |
//| ser uma copia. Isso cria pendencia contra o perfil ativo, de      |
//| proposito e como na 1.058: enquanto o formulario esta aberto a    |
//| pendencia nao tranca nada (AccCanCreateProfile a ignora dentro do |
//| modo), e sair pelo DESCARTAR a desfaz.                            |
//|                                                                   |
//| O Magic nasce VAZIO, nao copiado: copiar o do original criaria um |
//| formulario que ja se sabe invalido, e o botao apagado sem dizer   |
//| por que. Vazio, o cartao pede o numero.                           |
//+------------------------------------------------------------------+
void BeginDuplicate(const SEASettings &source,const string suggestedName,
                    const string sourceName)
  {
   ReleaseEditFocus();
   m_profEdit=FCV_PROF_DUP;
   ClearProfileForm();
   m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_NAME)]=suggestedName;
   m_draft=source;
   SyncDerivedSettings();
   
   //--- Com prazo: a mesma instrucao esta no cartao do formulario, que fica na
   //--- tela o tempo todo. Aqui ela so anuncia o que acabou de acontecer.
   SetNotice("DUPLICANDO "+sourceName,
             "A configuracao foi copiada. Informe um Magic livre e clique CRIAR COPIA.",
             FCV_SEM_WARN,FCV_NOTICE_TTL_MS);
   m_scroll=0;
   Render();
  }

//+------------------------------------------------------------------+
//| Recarga vinda do EA (carga de perfil, restauracao).               |
//|                                                                   |
//| Ver ReloadDraft: o valor do EA vence o texto em edicao, com aviso.|
//|                                                                   |
//| `keepForm` existe para UM caso, e ele era grave: a CRIACAO que    |
//| falhou ao gravar. Fechando o formulario ali, o perfil novo perdia |
//| o nome — o painel so guardava "houve falha" — e o aviso mandava   |
//| clicar SALVAR, que grava no perfil ATIVO. Seguindo a instrucao da |
//| tela, o usuario sobrescreveria o perfil anterior com a            |
//| configuracao do perfil que tentou criar.                          |
//|                                                                   |
//| Com o formulario aberto, o alvo continua na tela, os botoes do    |
//| cabecalho seguem apagados (headerLive exige modo de navegacao) e  |
//| a retentativa e o proprio CRIAR PERFIL. O estado guarda a         |
//| operacao, e nao so o fato de ter falhado.                         |
//+------------------------------------------------------------------+
void ReloadFromEA(const string reason,const bool keepForm=false)
  {
   bool lostTyping=(EditHasFocus() || HasPending());
   if(!keepForm) m_profEdit=FCV_PROF_VIEW;
   m_delConfirm=false;
   ReloadDraft();
   //--- Com o formulario mantido, nada se perdeu: o que o usuario digitou
   //--- continua ali. Anunciar perda seria falso.
   if(lostTyping && !keepForm)
      SetNotice("CAMPOS RECARREGADOS",reason,FCV_SEM_WARN,FCV_NOTICE_TTL_MS);
  }
private:
