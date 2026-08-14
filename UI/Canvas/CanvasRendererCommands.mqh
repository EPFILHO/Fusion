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
//|    expira. Sumir enquanto o SIM continua na tela deixaria um      |
//|    botao vermelho sem a frase que explica o que ele apaga — e a   |
//|    pergunta inteira vive nesse aviso, nao no rotulo do botao.     |
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
   //--- ⚠ "nao e um valor valido", e nao "nao e um numero". Digitar 0.3 num
   //--- campo inteiro caia aqui, e a frase afirmava algo FALSO: 0.3 e um numero,
   //--- so nao serve naquele campo. Dizer "invalido" cobre os dois casos — o
   //--- que nao e numero e o que e numero do tipo errado — sem o painel ter de
   //--- explicar qual dos dois foi.
   SetNotice("VALOR NAO ACEITO",
             "\""+shown+"\" nao e um valor valido"+
             ((kind==FCV_FTYPE_DEC) ? " (use ponto ou virgula para decimais)" : "")+
             ". O campo voltou ao valor anterior.",
             FCV_SEM_WARN,FCV_NOTICE_TTL_MS);
  }

//+------------------------------------------------------------------+
//| Confirmacao da exclusao.                                          |
//|                                                                   |
//| Apagar perfil e irreversivel e nao tem desfazer. A confirmacao    |
//| acontece no PROPRIO cartao — o botao vermelho vira SIM e ganha um |
//| NAO ao lado —, e nao num popup: o popup teria de suprimir os      |
//| campos nativos sob ele (regra do modelo hibrido) e esconderia     |
//| justamente a linha do perfil que esta prestes a sumir.            |
//|                                                                   |
//| SIM/NAO, e nao CONFIRMAR/VOLTAR: a coluna tem 124 px e            |
//| "CONFIRMAR" vazou dela. A pergunta inteira vive no aviso do       |
//| rodape, entao o botao so precisa carregar a resposta.             |
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
//| CONFIRMAR ABANDONO — quando a acao descarta a unica copia.        |
//|                                                                   |
//| O estado: o arquivo do perfil ativo sumiu E a configuracao nao    |
//| pode ser gravada porque nao vale para ESTE ativo (lote legitimo   |
//| no ouro, impossivel num indice de 1 contrato). A trava            |
//| `AccSaveFirstLock` nao engata ali de proposito — sem SALVAR nao   |
//| ha saida a oferecer, e trancar viraria beco. So que sem trava a   |
//| perda fica a um clique, e a faixa sozinha apenas a torna visivel. |
//|                                                                   |
//| Entao nem trancar nem deixar passar: CONFIRMAR. O usuario que     |
//| realmente quer abandonar continua podendo, e quem ia clicar sem   |
//| saber e avisado do que custa.                                     |
//|                                                                   |
//| ⚠ SO NOS DOIS CAMINHOS QUE PERDEM DE VERDADE. Abrir o NOVO nao    |
//| perde nada — o CRIAR PERFIL de dentro dele exige a mesma          |
//| configuracao valida e fica apagado. EXCLUIR mexe em OUTRO perfil. |
//| Atualizar lista so relê a pasta. Pedir confirmacao neles          |
//| ensinaria o usuario a clicar SIM sem ler, que e como uma          |
//| confirmacao deixa de proteger.                                    |
//|                                                                   |
//| ⚠ A duplicacao e confirmada ao CONCLUIR, e nao ao entrar: entrar  |
//| no formulario nao aplica nada, e o DESCARTAR devolve o rascunho.  |
//| Quem abandona e o CRIAR COPIA — e ele so acende porque o rascunho |
//| passou a ser o do perfil de ORIGEM, que pode valer neste grafico  |
//| enquanto o ativo nao vale.                                        |
//+------------------------------------------------------------------+
bool AbandonNeedsConfirm(void)
  { return (ActiveProfileOrphan() && !ConfigInputsValid()); }

bool AbandonArmed(const int op)
  { return (m_abandonOp==op); }

void ArmAbandonConfirm(const int op,const string target)
  {
   m_abandonOp=op;
   m_abandonTarget=target;
   //--- Sem prazo, como a do EXCLUIR: descreve um ESTADO em vigor, e sumindo
   //--- sozinha deixaria SIM e NAO na tela sem a frase que diz o que fazem.
   string what=(op==FCV_ABANDON_LOAD)
               ? "Carregar "+target
               : "Criar "+target;
   SetNotice("ISTO DESCARTA A CONFIGURACAO EM USO",
             what+" ativa outro perfil neste grafico. O perfil "+
             m_snap.activeProfileName+" esta sem arquivo em disco e nao pode ser "+
             "gravado aqui — a configuracao dele existe SO na memoria e sera "+
             "perdida. Restaurar o arquivo dele preserva tudo. Clique SIM para "+
             "abandonar mesmo assim, ou NAO para voltar.",FCV_SEM_BAD);
  }

void CancelAbandonConfirm(void)
  {
   if(m_abandonOp==FCV_ABANDON_NONE) return;
   m_abandonOp=FCV_ABANDON_NONE;
   m_abandonTarget="";
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
//--- Os quatro que a edicao em curso apaga (ver EditingNow e a coluna em
//--- ScreenProfiles). Numa funcao para a guarda do clique abaixo e a decisao do
//--- desenho nomearem o mesmo conjunto — em duas listas, uma envelheceria.
//--- FCV_BTN_PROFREFRESH fica de fora de proposito: ele nao consome a edicao,
//--- nunca esteve apagado por ela, e continua respondendo ao primeiro clique.
bool ProfileActionButton(const int id)
  {
   return (id==FCV_BTN_LOAD || id==FCV_BTN_NEW ||
           id==FCV_BTN_DUP  || id==FCV_BTN_DEL);
  }

bool HandleButtonClick(const int lx,const int ly,const bool editJustEnded)
  {
   for(int i=0;i<m_btnCount;++i)
     {
      if(lx<m_btnX[i] || lx>=m_btnX[i]+m_btnW[i]) continue;
      if(ly<m_btnY[i] || ly>=m_btnY[i]+m_btnH[i]) continue;
      //--- Botao acima da area util e chrome (cabecalho) e nao rola; dentro
      //--- dela, so vale se ainda estiver visivel.
      if(m_btnY[i]>=ContentTop() && !InContentView(m_btnY[i],m_btnH[i])) continue;

      //+---------------------------------------------------------------+
      //| ESTE CLIQUE SO ENCERROU UMA EDICAO: os quatro nao executam nele.|
      //|                                                                |
      //| O registro de caixas vem do desenho, e o desenho aconteceu HA   |
      //| POUCOS MICROSSEGUNDOS, dentro deste mesmo evento: sair do campo |
      //| apaga `EditingNow`, o HandlePress repinta para acender SALVAR e |
      //| CANCELAR, e nesse repinte os quatro — que estavam apagados por  |
      //| causa da edicao — voltam a publicar caixa. Sem esta guarda o    |
      //| clique num NOVO visivelmente APAGADO o executava.               |
      //|                                                                |
      //| ⚠ So quando a edicao NAO virou pendencia. Com o valor alterado, |
      //| `HasPending()` os mantem apagados e nao ha caixa a acertar — a  |
      //| brecha existia exatamente no caso inocente de entrar no campo e |
      //| sair sem mudar nada.                                            |
      //|                                                                |
      //| ⚠ E so para estes quatro. O repinte foi criado para o SALVAR    |
      //| aceitar o clique unico depois da digitacao (ver o comentario no |
      //| HandlePress), e engolir tudo devolveria aquele defeito. A       |
      //| diferenca e de contrato: SALVAR e CANCELAR SAO as saidas da     |
      //| edicao, entao clicar neles ao sair e o gesto esperado; os       |
      //| quatro a consomem por efeito colateral.                         |
      //|                                                                |
      //| Consome o clique (`return true`) em vez de seguir procurando    |
      //| alvo: a caixa foi acertada, e deixar cair para as abas faria um |
      //| clique num botao trocar de tela.                                |
      //+---------------------------------------------------------------+
      if(editJustEnded && ProfileActionButton(m_btnId[i])) return true;

      //--- Qualquer outro botao desarma a confirmacao pendente. Sem isto ela
      //--- ficaria armada enquanto o usuario faz outra coisa, e o proximo
      //--- clique no lugar do SIM apagaria um perfil sem aviso.
      if(m_btnId[i]!=FCV_BTN_DELOK && m_delConfirm) CancelDeleteConfirm();
      //--- Mesma regra para a do abandono. O SIM dela e o unico que a preserva —
      //--- inclusive o NAO desarma, que e o que ele significa.
      if(m_btnId[i]!=FCV_BTN_ABANDONOK && m_abandonOp!=FCV_ABANDON_NONE)
         CancelAbandonConfirm();

      //+---------------------------------------------------------------+
      //| Primeiro clique nos dois caminhos que abandonam: ARMA, nao age.|
      //| Ver AbandonNeedsConfirm — inclusive por que nao vale para o    |
      //| NOVO, para o EXCLUIR nem para Atualizar lista.                 |
      //|                                                                |
      //| O alvo e capturado AQUI e nao lido de novo no SIM: entre um    |
      //| clique e outro a selecao pode mudar, e a pergunta nomearia um  |
      //| perfil e executaria outro. Trocar a selecao desarma, entao o   |
      //| alvo guardado e sempre o que estava na pergunta.                |
      //+---------------------------------------------------------------+
      if(AbandonNeedsConfirm())
        {
         if(m_btnId[i]==FCV_BTN_LOAD && !AbandonArmed(FCV_ABANDON_LOAD))
           { ArmAbandonConfirm(FCV_ABANDON_LOAD,SelectedProfileName()); Render(); return true; }
         //--- So a DUPLICACAO: no NOVO o rascunho continua sendo o do perfil
         //--- orfao, entao o CRIAR PERFIL ja esta apagado pela configuracao
         //--- invalida e este ramo nunca e alcancado por ele.
         if(m_btnId[i]==FCV_BTN_SAVE && m_profEdit==FCV_PROF_DUP &&
            !AbandonArmed(FCV_ABANDON_CREATE))
           { ArmAbandonConfirm(FCV_ABANDON_CREATE,ProfileFormRawName()); Render(); return true; }
        }

      switch(m_btnId[i])
        {
         //--- SIM do abandono: executa a operacao guardada. NAO so desarma, e ja
         //--- foi tratado pela regra acima.
         case FCV_BTN_ABANDONOK:
           {
            int op=m_abandonOp;
            m_abandonOp=FCV_ABANDON_NONE;
            string target=m_abandonTarget;
            m_abandonTarget="";
            ClearNotice();
            if(op==FCV_ABANDON_LOAD)
               QueueIntent(FCV_INTENT_LOAD_PROFILE,target);
            else if(op==FCV_ABANDON_CREATE)
              {
               int magic=0;
               ProfileFormMagic(magic);
               QueueIntent(FCV_INTENT_CREATE_PROFILE,ProfileFormRawName(),magic);
              }
            break;
           }
         case FCV_BTN_ABANDONNO: break;   // o desarme ja aconteceu acima

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

         //--- Primeiro clique arma; o segundo, no SIM, executa.
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
//--- `sourceName` era o terceiro parametro e saiu com o aviso de entrada, que
//--- era seu unico leitor. Quem nomeia a origem no cartao e o perfil
//--- selecionado (m_profSel), que e o mesmo — a selecao nao muda entre o clique
//--- e esta chamada.
void BeginDuplicate(const SEASettings &source,const string suggestedName)
  {
   ReleaseEditFocus();
   m_profEdit=FCV_PROF_DUP;
   ClearProfileForm();
   m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_NAME)]=suggestedName;
   m_draft=source;
   SyncDerivedSettings();
   
   //+---------------------------------------------------------------+
   //| Entrar no formulario LIMPA a caixa, como o NOVO ja fazia.       |
   //|                                                                |
   //| Havia aqui um aviso de entrada — "DUPLICANDO X / A configuracao |
   //| foi copiada. Informe um Magic livre e clique CRIAR COPIA" — com |
   //| prazo de 5 s. Ele causava tres coisas de uma vez, e o proprio   |
   //| comentario dele ja admitia a primeira:                          |
   //|                                                                |
   //|  - REDUNDANCIA: a mesma instrucao esta no cartao, que fica na   |
   //|    tela o tempo todo, ao lado do nome ja preenchido e do titulo |
   //|    DUPLICAR COMO. Nada se perde tirando-o.                      |
   //|  - ATRASO: a caixa e uma so, e o aviso vence o erro da tela.    |
   //|    Por 5 s o painel escondia o motivo real de o CRIAR COPIA     |
   //|    estar apagado.                                               |
   //|  - INSTRUCAO IMPEDIDA: ele mandava clicar num botao que podia   |
   //|    estar desabilitado — duplicar perfil de outro ativo reprova  |
   //|    a configuracao para o simbolo deste grafico. Licao 1 da      |
   //|    secao 8, agravada por esconder a explicacao verdadeira.      |
   //|                                                                |
   //| E limpar (em vez de so nao escrever) importa: um aviso anterior |
   //| ainda no prazo ocuparia a caixa pelo tempo restante, com os     |
   //| mesmos dois ultimos efeitos — e impediria a rolagem automatica  |
   //| de disparar, que reage a transicao "sem aviso -> com aviso".    |
   //+---------------------------------------------------------------+
   ClearNotice();
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
