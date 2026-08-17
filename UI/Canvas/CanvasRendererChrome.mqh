//+------------------------------------------------------------------+
//| CanvasRendererChrome.mqh                                          |
//| Fragmento do corpo de CFusionCanvasRenderer — barra de titulo,    |
//| cabecalho, ficharios, trilho, rolagem e aviso.                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| A cadeia de erro — trilho -> subaba -> aba.                       |
//|                                                                   |
//| Montada desde a Fase 1 e alimentada com dado real desde a Etapa   |
//| 2d: cada elo pergunta a validacao, e a validacao le o rascunho.   |
//|                                                                   |
//| Ate aqui ela respondia "nao sei de nenhum erro". Antes disso,     |
//| durante a Fase 1, respondia um erro FIXO em Protecao > Noticias —  |
//| util para exercitar o vermelho subindo, e que passou a acusar     |
//| horarios corretos assim que a tela leu dados de verdade. As duas   |
//| respostas eram provisorias; esta nao e.                            |
//+------------------------------------------------------------------+
//--- Itens do trilho de cada subaba de Gestao. Risco tem cinco, Protecao sete.
int RailCountFor(const int cfg) { return (cfg==0) ? 5 : FCV_RAIL_MAX; }

bool RailHasError(const int cfg,const int idx)
  {
   if(idx<0 || idx>=RailCountFor(cfg)) return false;
   int base=(cfg==0) ? FCV_SCREEN_RISK0 : FCV_SCREEN_PROT0;
   return (ScreenError(base+idx)!="");
  }

//--- ⚠ Recebe a ABA, e nao so o indice da subaba. A faixa de nivel 2 pertence
//--- sempre a aba corrente, mas o mesmo indice significa coisas diferentes em
//--- cada uma — cfg 1 e "Medias" nas Estrategias e "Protecao" na Gestao. Lendo
//--- m_tab por dentro, esta funcao ficaria certa por acidente e quebraria no
//--- dia em que alguem a chamasse de outro lugar.
bool CfgHasError(const int tab,const int cfg)
  {
   if(cfg<0) return false;
   if(tab==2) return (cfg<4 && ScreenError(FCV_SCREEN_STRAT0 +cfg)!="");
   if(tab==3) return (cfg<4 && ScreenError(FCV_SCREEN_FILTER0+cfg)!="");
   if(tab==FCV_TAB_GESTAO)
     {
      if(cfg>1) return false;
      for(int i=0;i<RailCountFor(cfg);++i) if(RailHasError(cfg,i)) return true;
     }
   return false;
  }

//--- O erro sobe ate a aba que contem a subaba invalida. Com Risco e Protecao
//--- agora em Gestao, e Gestao que fica vermelha — e isso informa mais do que
//--- "Config", que nao dizia de que assunto era o problema.
bool TabHasError(const int tab)
  {
   //--- Magic repetido acende a aba Perfis. Sai da lista ja lida do disco, e
   //--- convive com o erro do proprio campo Magic do perfil ativo.
   if(tab==FCV_TAB_PERFIS)
      return (HasDuplicateMagic() || ScreenError(FCV_SCREEN_PROFILES)!="");
   if(tab!=2 && tab!=3 && tab!=FCV_TAB_GESTAO) return false;
   for(int c=0;c<Level2Count(tab);++c) if(CfgHasError(tab,c)) return true;
   return false;
  }

//--- geometria da area util
int Surf1Top(void)      { return FCV_F1_BOTTOM; }
int F2Top(void)         { return FCV_F1_BOTTOM + FCV_F2_GAP; }
int ContentTop(void)    { return HasLevel2(m_tab) ? F2Top()+FCV_F2_H+10 : FCV_F1_BOTTOM+FCV_PAD; }
int ContentBottom(void) { return m_ph - FCV_PAD - m_alertH - (m_alertH>0 ? 9 : 0); }

bool ScrollBy(const int d)
  {
   int viewH=ContentBottom()-ContentTop();
   int maxS=m_contentH-viewH;
   if(maxS<=0) return false;
   int ns=m_scroll+d;
   if(ns<0) ns=0;
   if(ns>maxS) ns=maxS;
   if(ns==m_scroll) return false;
   m_scroll=ns;
   return true;
  }

//+------------------------------------------------------------------+
//| Recorte do deslocamento contra o maximo de AGORA.                 |
//|                                                                   |
//| ⚠ O ScrollBy acima recorta, mas so roda quando ha EVENTO de       |
//| rolagem — e o maximo muda sem evento nenhum. Basta a area util    |
//| crescer ou o conteudo encolher:                                   |
//|                                                                   |
//|   - a caixa de aviso aparecendo ou sumindo (ContentBottom depende |
//|     de m_alertH), que e o caso mais comum: qualquer campo que      |
//|     entra e sai de invalido move a area util;                     |
//|   - a lista de perfis encolhendo, relida pelo pulso sem clique;   |
//|   - um cartao perdendo linhas porque uma chave desligou os        |
//|     parametros dependentes.                                        |
//|                                                                   |
//| Sem este recorte o conteudo continua desenhado em                 |
//| ContentTop()-m_scroll com um m_scroll que ja nao cabe: o topo     |
//| some. E o estado nao tem saida pela propria tela — cabendo o      |
//| conteudo, o ScrollBy volta `false` no `maxS<=0` sem tocar em      |
//| nada, e a barra nem e desenhada. So trocar de aba (que zera)      |
//| devolvia o painel ao lugar.                                        |
//|                                                                   |
//| Por isso o recorte e por QUADRO, e nao por evento. Devolve true   |
//| quando mexeu, para quem chamar decidir se precisa repintar.       |
//+------------------------------------------------------------------+
bool ClampScroll(void)
  {
   int maxS=m_contentH-(ContentBottom()-ContentTop());
   if(maxS<0) maxS=0;
   if(m_scroll>=0 && m_scroll<=maxS) return false;
   m_scroll=(m_scroll>maxS) ? maxS : 0;
   return true;
  }

//+------------------------------------------------------------------+
//| Fichario: a aba ativa perde a borda de baixo e recebe o fundo da  |
//| superficie; a linha do estado atravessa toda a largura. Erro      |
//| prevalece sobre selecao.                                          |
//+------------------------------------------------------------------+
void FolderStrip(const int y,const int h,const int x0,const int xEnd,
                 string &names[],const int count,const int active,
                 const int pt10,const uint surfaceBelow,
                 int &outX[],int &outW[],const bool markErrors,const int cfgForErr)
  {
   bool activeErr = markErrors && ((cfgForErr<0) ? TabHasError(active) : CfgHasError(m_tab,active));
   uint edge = activeErr ? m_t.bad : m_t.acc;

   //--- Linha do fichario, largura inteira, 1 px. Com 2 px ela competia com o
   //--- proprio conteudo: e um separador, nao um elemento.
   Rect(0, y+h-2, FCV_PANEL_W-1, y+h-2, edge);

   int tx=x0;
   for(int i=0;i<count;++i)
     {
      int w=TxtW(names[i],FCV_FONT_UI,pt10,FCV_FW_SEMI)+24;
      outX[i]=tx; outW[i]=w;
      bool on =(i==active);
      bool err=markErrors && ((cfgForErr<0) ? TabHasError(i) : CfgHasError(m_tab,i));

      if(on)
        {
         //--- A aba cobre o trecho da linha sob ela e para exatamente nela: se
         //--- passar, sobra um degrau abaixo do fichario. Cantos de cima
         //--- arredondados no mesmo raio dos botoes do cabecalho, para o painel
         //--- ter um raio so; os de baixo retos, encostando na linha.
         //--- Borda de 1 px, igual a linha, e fundo ate exatamente nela: a aba
         //--- cobre o trecho da linha sob si sem passar por baixo.
         //--- Recuo de 1 PIXEL REAL, como toda borda: em unidade logica ele
         //--- virava 1 ou 2 pixels conforme a posicao da aba, e a espessura da
         //--- borda mudava de aba para aba. Embaixo NAO ha recuo — o fundo tem
         //--- de alcancar a linha do fichario, que e o que faz a aba parecer
         //--- aberta sobre ela.
         uint fill = err ? m_t.bdim : surfaceBelow;
         uint bclr = err ? m_t.bad : m_t.acc;
         int dx1=S(tx), dy1=S(y+2), dx2=S(tx+w), dy2=S(y+h-2), dr=S(FCV_RADIUS_CTRL);
         RoundRectDev(dx1,  dy1,  dx2,  dy2,dr,  bclr,m_t.ground,FCV_CORNER_TOP);
         RoundRectDev(dx1+1,dy1+1,dx2-1,dy2,dr-1,fill,bclr,      FCV_CORNER_TOP);
        }
      Txt(tx+w/2, y+h/2, names[i],
          err ? m_t.bad : (on ? m_t.fg : m_t.faint),
          FCV_FONT_UI, pt10, FCV_FW_SEMI, TA_CENTER|TA_VCENTER);
      //+------------------------------------------------------------+
      //| Marcador operacional do Status: ponto AMBAR, forma propria. |
      //|                                                             |
      //| ⚠ Deliberadamente diferente do vermelho de erro, que ali ao |
      //| lado significa uma coisa precisa: "ha campo invalido para   |
      //| corrigir NESTA tela". O que este marca nao se corrige em    |
      //| tela nenhuma do painel — AutoTrading, conexao e permissao   |
      //| da conta se resolvem fora dele. Pintar de vermelho mandaria |
      //| o usuario a um lugar onde nao ha o que fazer, que e a licao |
      //| 1 da secao 8 do plano; e faria o vermelho significar duas   |
      //| coisas, deixando de ser acionavel de relance.                |
      //|                                                             |
      //| O que ele promete e so isto: "ha uma explicacao operacional |
      //| aqui". So o nivel 1 o desenha — no nivel 2 nao ha Status.   |
      //+------------------------------------------------------------+
      if(cfgForErr<0 && i==FCV_TAB_STATUS && m_hdr.statusMark && !err)
         Disc(tx+w-9, y+h/2-6, 3, m_t.warn);
      tx += w+3;
     }
  }

//+------------------------------------------------------------------+
void DrawTitlebar(void)
  {
   Rect(0,0,FCV_PANEL_W-1,FCV_TITLEBAR_H-1,m_t.surface);
   HLine(0,FCV_PANEL_W-1,FCV_TITLEBAR_H-1,m_t.line);
   Txt(13,16,"EP Fusion",m_t.fg,FCV_FONT_UI,FCV_FS_VAL,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int bw=TxtW("EP Fusion",FCV_FONT_UI,FCV_FS_VAL,FCV_FW_SEMI);
   Txt(13+bw+8,17,FUSION_APP_VERSION,m_t.faint,FCV_FONT_MONO,FCV_FS_SM,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);

   //--- Tema: circulo meio-preto meio-branco, o icone universal de troca de
   //--- claro/escuro. As duas metades sao fixas (nao seguem a paleta) de
   //--- proposito — e o simbolo, nao a amostra do tema atual; um icone tingido
   //--- de acento ficaria ambiguo com o resto dos controles preenchidos.
   int tx=FCV_PANEL_W-76, ty=16, tr=7;
   HalfDisc(tx,ty,tr,FCV_OPAQUE(20,20,24),FCV_OPAQUE(248,248,251));
   Ring(tx,ty,tr,m_t.muted);

   //--- Reajustar altura ao grafico: SETA DUPLA VERTICAL. Ela diz o que a acao
   //--- faz — crescer e encolher na vertical — em vez de depender de convencao
   //--- de janela, que era o problema do retangulo: ele significava "maximizar"
   //--- e disputava leitura com o botao de restaurar ao lado.
   //---
   //--- A decisao anterior de recusar setas continua valendo e nao e esta: o que
   //--- foi recusado eram duas setas DIVERGENTES na diagonal, que liam como "X"
   //--- de fechar. Num painel que opera dinheiro, sugerir fechamento por engano
   //--- e inaceitavel. Vertical nao tem essa ambiguidade.
   //---
   //--- Escondido enquanto minimizado: la nao ha o que reajustar, e controle
   //--- visivel que nao faz nada e pior do que controle ausente.
   if(!m_minimized)
     {
      //--- ⚠ Haste e pontas ancoradas nos MESMOS pixels. Antes cada uma
      //--- convertia sua propria posicao logica (11/21 para a haste, 14 e 18
      //--- para as pontas), e os floors nao concordavam: a distancia entre
      //--- ponta e haste ia de 3 para 4 px conforme a escala, entao uma ponta
      //--- colava na haste e a outra deixava uma fresta. As pontas em si sempre
      //--- estiveram certas — o Chevron ja e pixel-a-pixel; o que faltava era o
      //--- conjunto ser montado na mesma moeda.
      //--- A haste maior e a do MEIO: as pontas se afastam do centro (2 -> 4) e
      //--- a haste cresce junto, terminando EXATAMENTE nelas. Antes o trecho
      //--- visivel entre as duas cabecas tinha 4 px e o icone lia-se como duas
      //--- setas soltas em vez de um eixo com dois sentidos.
      //---
      //--- ⚠ A haste NAO passa das pontas. O Chevron tem a base em `dy` e a
      //--- ponta 3 px adiante, entao o fim da haste e `base + 3` — sobrar um
      //--- filete de 1 px alem da cabeca nao le como eixo, le como defeito de
      //--- ponta, que foi o que motivou esta rodada inteira.
      int rx=FCV_PANEL_W-50, dcx=S(rx), dcy=S(16);
      int arm=4;                                              // pontas: +-4 do centro
      RectDev(dcx,dcy-arm-3,dcx,dcy+arm+3,m_t.muted);         // haste, ponta a ponta
      ChevronDev(dcx,dcy-arm,false,m_t.muted);                // ponta para cima
      ChevronDev(dcx,dcy+arm,true, m_t.muted);                // ponta para baixo
     }

   //--- Minimizado, o botao RESTAURA — e a janelinha e o simbolo disso. Ela
   //--- estava sendo gasta no reajuste de altura, onde nao queria dizer nada:
   //--- agora cada glifo tem um significado so.
   int mx=FCV_PANEL_W-24;
   if(m_minimized)
     {
      Frame(mx-6,12,mx+6,20,m_t.muted);
      Rect (mx-6,12,mx+6,13,m_t.muted);
     }
   else Rect(mx-6,16,mx+6,17,m_t.muted);
  }

//--- Cor REAL do fundo naquela altura. O canvas nao antialiasa sozinho: as
//--- primitivas suavizam os cantos misturando com uma cor de fundo INFORMADA, e
//--- informar a errada deixa um halo daquela cor nos quatro cantos.
//---
//--- Era o que acontecia com os botoes: eles passavam m_t.ground fixo, mas do
//--- titulo para baixo o fundo e m_t.surface — no tema claro, cinza contra
//--- branco. O halo aparecia como uma "sombrinha", e o botao DESABILITADO ainda
//--- era PREENCHIDO de cinza, virando uma placa em vez de um contorno apagado.
//--- So a faixa da barra de titulo fica em ground.
uint BgAt(const int y) { return (y<Surf1Top()) ? m_t.ground : m_t.surface; }

void Btn(const int x,const int y,const int w,const int h,const string label,
         const bool filled,const uint fillClr,const uint onFill)
  {
   uint bg=BgAt(y);
   if(filled)
     {
      RoundRect(x,y,x+w,y+h,FCV_RADIUS_CTRL,fillClr,bg);
      Txt(x+w/2,y+h/2,label,onFill,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
     }
   else
     {
      //--- Sem preenchimento, a COR VAI NO CONTORNO E NO TEXTO. Antes o botao
      //--- vazado era desenhado em cinza neutro e a cor recebida era descartada
      //--- — ficava igual a um botao desabilitado, e o usuario nao tinha como
      //--- saber que aquilo respondia a clique.
      //---
      //--- A regra que fica: PREENCHIDO = age sobre um dado (carregar, criar,
      //--- excluir); VAZADO = acao secundaria, disponivel mas nao protagonista.
      //--- Desabilitado continua cinza pelo caminho de cima, entao "vazado" e
      //--- "apagado" deixam de se confundir.
      RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,fillClr,bg,bg);
      Txt(x+w/2,y+h/2,label,fillClr,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
     }
  }

//--- Botao que publica a propria caixa e o comando que dispara. Bloqueado, ele
//--- e desenhado apagado e NAO publica caixa: nao basta parecer inativo.
void PutButton(const int x,const int y,const int w,const int h,const string label,
               const bool filled,const uint fillClr,const uint onFill,
               const int id,const bool enabled)
  {
   //--- Licao 3 da secao 8 do plano — "medir a mensagem contra o espaco
   //--- disponivel antes de escreve-la" — aplicada aos botoes, que nao a
   //--- cumpriam. "CONFIRMAR" vazou da coluna de 124 px de Perfis e so foi
   //--- descoberto por captura de tela; a faixa de abas ja tinha essa conferencia
   //--- desde a Fase 1, os botoes nao.
   //---
   //--- Loga UMA VEZ por sessao: o desenho roda ate 5x por segundo, e um aviso
   //--- por quadro afogaria o log — que e onde o proximo caso precisa aparecer.
   if(!m_btnFitLogged && TxtW(label,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD) > w-12)
     {
      m_btnFitLogged=true;
      PrintFormat("ATENCAO: o rotulo \"%s\" nao cabe no botao (%d px de caixa). Encurte-o.",
                  label,w);
     }
   if(!enabled)
     {
      //--- Preenchimento IGUAL ao fundo: botao apagado e contorno, nao placa.
      uint bg=BgAt(y);
      RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.disabled,bg,bg);
      Txt(x+w/2,y+h/2,label,m_t.disabled,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
      return;
     }
   Btn(x,y,w,h,label,filled,fillClr,onFill);
   if(m_btnCount>=FCV_BTN_MAX) return;
   m_btnX[m_btnCount]=x; m_btnY[m_btnCount]=y;
   m_btnW[m_btnCount]=w; m_btnH[m_btnCount]=h;
   m_btnId[m_btnCount]=id;
   m_btnCount++;
  }

//--- "PERIOD_H1" -> "H1". O EA tem ShortTimeframeName, mas e metodo da classe
//--- de aplicacao e o renderizador nao a alcanca — nem deve.
string ShortTF(const ENUM_TIMEFRAMES tf)
  {
   string s=EnumToString(tf);
   return (StringFind(s,"PERIOD_")==0) ? StringSubstr(s,7) : s;
  }

//--- Estado operacional em SEIS nomes, do mais grave ao mais brando:
//--- BLOQUEADO > IMPEDIDO > OPERANDO > SEM ENTRADAS > RODANDO > PAUSADO.
//--- A 1.058 tem tres (no Pages/StatusPage.mqh dela). IMPEDIDO e OPERANDO
//--- nasceram na Fase 3 — o primeiro para separar "o EA nao pode operar por
//--- condicao externa" de "o contexto o travou", e o segundo porque era rotulo de
//--- botao e estado pertence aqui. SEM ENTRADAS veio depois, na Fase 4: o EA
//--- podia estar com uma protecao suspendendo entradas e o distintivo dizia
//--- RODANDO em verde, com a informacao so na aba Resultados.
//--- A ordem e a regra: se o EA esta impedido de operar — ou nao vai procurar
//--- entrada —, dizer que ele esta rodando seria a pior informacao desta linha.
//--- Distintivo e botao leem do resolvedor, resolvido uma vez por quadro no
//--- inicio do DrawFrame. Perguntar por conta aqui reabriria a divergencia que
//--- SHeaderAction existe para fechar.
string RunStateText(void)
  { return m_hdr.badge; }

uint RunStateColor(void)
  { return SemColor(m_hdr.badgeSem); }

//--- O botao diz o que o clique FAZ, nao o que o estado E — sem excecao. Houve
//--- uma, herdada da 1.058: com posicao aberta o rotulo virava "OPERANDO". O
//--- receio era que "PAUSAR" fizesse o usuario achar que o clique encerra a
//--- operacao em curso; mas ali o botao esta APAGADO, e quem explica que a saida
//--- e pela estrategia ou pela protecao e a faixa. O estado subiu para o
//--- distintivo, que e onde estado pertence.
//+------------------------------------------------------------------+
//| Camada de acesso — quem pode o que, e quando.                     |
//| Portada de UI/UIPanelAccessState.mqh, mesmos predicados.          |
//|                                                                   |
//| Pendente da Etapa 2d: configInputsValid, que so existe quando a   |
//| validacao entrar. Ate la vale true — isto AFROUXA a regra (deixa  |
//| iniciar com campo invalido), nunca a aperta.                      |
//+------------------------------------------------------------------+
//--- Campos de configuracao so aceitam edicao quando o EA permite. Era a
//--- lacuna registrada para a 2d: existia um sinalizador que so respondia a uma
//--- tecla de simulacao, nunca ao estado do EA — os campos seguiam editaveis
//--- operando. Hoje as duas linhas abaixo SAO a regra, e a simulacao saiu na
//--- Fase 3 junto com a tecla (ver a nota das teclas em CanvasRendererInput).
//--- ⚠ A regra de acesso NAO e a mesma para todo campo, e tratar como se fosse
//--- ja produziu os dois lados do erro:
//---
//---   - so `runtimeEditable` deixava os campos do perfil ATIVO editaveis com
//---     ele preso por outro grafico, criando pendencia impossivel de gravar;
//---   - so `activeProfileEditable` trancava os campos do formulario de CRIAR,
//---     que a 1.058 permite justamente durante esse bloqueio — e o resultado
//---     era um NOVO habilitado, formulario aberto, e nada digitavel nele.
//---
//--- O criterio e DE QUEM e o campo, e a tela ja carrega essa informacao: o
//--- formulario de criar/duplicar tem identidade propria (FCV_SCREEN_PROFILE_EDIT),
//--- decidida na Fase 1 por outro motivo — separar os slots — e que serve aqui
//--- exatamente porque significa "estes campos nao sao do perfil ativo".
bool FieldsLocked(void)
  {
   if(m_screen==FCV_SCREEN_PROFILE_EDIT) return !AccCanCreateProfile();
   return !AccActiveProfileEditable();
  }

//+------------------------------------------------------------------+
//| Identidade de perfil.                                             |
//|                                                                   |
//| Perfil se compara pela forma SANEADA do nome, nunca pelo texto    |
//| cru: e assim que o arquivo e nomeado em disco, e "BTC USD" e      |
//| "btcusd" podem ser o mesmo perfil. Mesma funcao que a 1.058 usa   |
//| (FusionSanitizeProfileName), para os dois paineis concordarem     |
//| sobre o que e o mesmo perfil.                                     |
//+------------------------------------------------------------------+
string ProfileKey(const string name) { return FusionSanitizeProfileName(name); }

//--- Indice do perfil ATIVO na lista, ou -1 se ele nao esta nela (perfil
//--- apagado por fora, lista ainda nao carregada). Quem manda e o snapshot: o
//--- ativo e o que o EA carregou, nao o que a tela selecionou.
int ActiveProfileIndex(void)
  {
   string key=ProfileKey(m_snap.activeProfileName);
   if(StringLen(key)==0) return -1;
   for(int i=0;i<m_profCount;++i)
      if(ProfileKey(m_profName[i])==key) return i;
   return -1;
  }

//--- O perfil "default" nao se apaga. A 1.058 recusa a exclusao e o proprio
//--- painel avisa por escrito ("Nao apague o perfil default"); sem esta regra a
//--- 2.0 ofereceria EXCLUIR num perfil que o EA usa como base de tudo.
//--- O nome vem da configuracao (defaultProfileName), com "default" como ultimo
//--- recurso — igual ao DefaultProfileKey da 1.058.
bool ProfileIsDefault(const int idx)
  {
   if(idx<0 || idx>=m_profCount) return false;
   string def=ProfileKey(m_draft.defaultProfileName);
   if(StringLen(def)==0) def=ProfileKey(m_committed.defaultProfileName);
   if(StringLen(def)==0) def="default";
   string key=ProfileKey(m_profName[idx]);
   return (StringLen(key)>0 && key==def);
  }

//--- Geometria das tres colunas de Perfis (lista | setas | acoes), medida da
//--- direita para a esquerda. Vive aqui, e nao no desenho, porque o alvo do
//--- clique nas linhas precisa da MESMA borda direita: enquanto ela era um 135
//--- escrito a mao no hit-test, mudar a largura das colunas deslocava o alvo
//--- sem deslocar o desenho.
#define FCV_PROF_ACT_W   124   // coluna dos botoes de acao
#define FCV_PROF_NAV_W    22   // coluna das setas de rolagem
//--- Folga entre a moldura da lista e a coluna de acoes. Era 8 e a borda direita
//--- da moldura ficava colada nos botoes; o contorno precisa de ar para ler-se
//--- como moldura e nao como parte do botao.
#define FCV_PROF_COL_GAP  16
//--- Respiro entre o topo da area util e a moldura. Sem ele a moldura comeca
//--- exatamente em ContentTop(), e a faixa que o desenho repinta para recortar
//--- o conteudo rolavel come a linha de cima — era por isso que a borda superior
//--- da moldura nao aparecia.
#define FCV_PROF_TOP_PAD   8

int ProfileActionsLeft(void) { return m_fx2-FCV_PROF_ACT_W; }
int ProfileNavLeft(void)     { return ProfileActionsLeft()-FCV_PROF_COL_GAP-FCV_PROF_NAV_W; }
int ProfileListRight(void)   { return ProfileNavLeft()-FCV_PROF_COL_GAP; }

//+------------------------------------------------------------------+
//| Formulario de criar/duplicar: o que ele tem e se da para gravar.  |
//|                                                                   |
//| A regra e a de ProfileEditDraftState (UIPanelProfileValidation):  |
//| nome preenchido, nome livre, Magic valido e Magic livre. Os quatro,|
//| ou o botao nao acende.                                            |
//|                                                                   |
//| A 1.058 pergunta ao disco (ProfileExists, FindProfileByMagicNumber)|
//| a cada passada. Aqui a resposta sai da LISTA JA CARREGADA, que tem |
//| nome e Magic de todos: mesma informacao, sem tocar em disco por    |
//| quadro. O preco e a lista poder estar velha — outro grafico pode   |
//| ter criado um perfil desde a ultima leitura —, e por isso o        |
//| comando de gravar tera de reconferir no disco na 2c. Aqui o papel  |
//| e nao deixar o usuario preencher um formulario que ja se sabe      |
//| impossivel.                                                       |
//+------------------------------------------------------------------+
//--- Slots do formulario, na ordem em que as linhas sao declaradas. Nomeados
//--- porque a validacao le por indice: inverter as duas linhas sem mexer aqui
//--- faria o nome ser validado como Magic.
#define FCV_PROF_SLOT_NAME   0
#define FCV_PROF_SLOT_MAGIC  1

int ProfileFormSlot(const int seq)
  { return FCV_SCREEN_PROFILE_EDIT*FCV_SLOT_MAX+seq; }

//--- Espacos das pontas fora. A 1.058 apara ANTES de sanear e a ordem importa:
//--- saneando primeiro, "   " viraria "___" — um nome nao vazio feito de nada.
string TrimEdges(const string s)
  {
   int a=0, b=StringLen(s);
   while(a<b && StringGetCharacter(s,a)==' ') a++;
   while(b>a && StringGetCharacter(s,b-1)==' ') b--;
   return StringSubstr(s,a,b-a);
  }

//--- Nome ja na forma com que viraria arquivo: e essa que precisa ser unica.
string ProfileFormName(void)
  { return ProfileKey(TrimEdges(m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_NAME)])); }

bool ProfileFormMagic(int &magic)
  {
   magic=0;
   string t=TrimEdges(m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_MAGIC)]);
   if(StringLen(t)==0) return false;
   //--- Inteiro positivo e so digitos: "12a" nao vira 12 por StringToInteger
   //--- sem ninguem perceber.
   for(int i=0;i<StringLen(t);++i)
     {
      ushort ch=StringGetCharacter(t,i);
      if(ch<'0' || ch>'9') return false;
     }
   magic=(int)StringToInteger(t);
   return (magic>0);
  }

//--- Varre TODOS os arquivos, nao so os que abriram. Um perfil ilegivel nao
//--- aparece na lista e mesmo assim ocupa o nome: liberar a criacao sobre ele
//--- faria a gravacao escrever por cima de um arquivo que so esta com problema
//--- — e que o usuario provavelmente quer recuperar, nao perder.
bool ProfileNameTaken(const string key)
  {
   if(StringLen(key)==0) return false;
   for(int i=0;i<m_profAllCount;++i)
      if(ProfileKey(m_profAllName[i])==key) return true;
   return false;
  }

bool ProfileMagicTaken(const int magic,string &owner)
  {
   owner="";
   if(magic<=0) return false;
   for(int i=0;i<m_profCount;++i)
      if(m_profMagic[i]==magic) { owner=m_profName[i]; return true; }
   return false;
  }

//--- Estado completo do formulario. `nameBad`/`magicBad` marcam o campo de
//--- vermelho, e so quando ha CONTEUDO errado: campo ainda vazio nao e erro, e
//--- pintar um formulario intocado de vermelho e gritar antes da hora — o botao
//--- apagado ja diz que falta preencher. (A 1.058 pinta o Magic vazio porque la
//--- ele nasce preenchido; aqui nasce em branco.)
bool ProfileFormReady(bool &nameBad,bool &magicBad,string &error)
  {
   nameBad=false; magicBad=false; error="";

   string key=ProfileFormName();
   bool hasName=(StringLen(key)>0);
   bool nameFree=(hasName && !ProfileNameTaken(key));

   int magic=0;
   bool magicOk=ProfileFormMagic(magic);
   string owner="";
   bool magicFree=(magicOk && !ProfileMagicTaken(magic,owner));

   bool magicTyped=(StringLen(TrimEdges(m_stEdit[ProfileFormSlot(FCV_PROF_SLOT_MAGIC)]))>0);

   if(hasName && !nameFree)
     { nameBad=true;  error="Nome ja existe. Escolha outro nome."; }
   else if(magicTyped && !magicOk)
     { magicBad=true; error="Magic invalido. Informe um numero inteiro positivo."; }
   else if(magicOk && !magicFree)
     { magicBad=true; error="Magic ja usado pelo perfil "+owner+"."; }

   return (hasName && nameFree && magicOk && magicFree);
  }

//--- Rolagem da lista de perfis. Portada de UIPanelProfileListView.mqh, que
//--- resolve os mesmos dois casos: nao deixar o deslocamento passar do fim, e
//--- trazer a selecao de volta para dentro da janela quando ela sai (ao trocar
//--- de perfil ativo, ou quando a lista encolhe por uma exclusao).
int  ProfileMaxOffset(void)
  {
   int max=m_profCount-FCV_PROF_ROWS;
   return (max>0) ? max : 0;
  }

void ClampProfileOffset(void)
  {
   int max=ProfileMaxOffset();
   if(m_profOffset>max) m_profOffset=max;
   if(m_profOffset<0)   m_profOffset=0;
  }

void EnsureProfileVisible(void)
  {
   if(m_profSel<0) { ClampProfileOffset(); return; }
   if(m_profSel<m_profOffset) m_profOffset=m_profSel;
   if(m_profSel>=m_profOffset+FCV_PROF_ROWS)
      m_profOffset=m_profSel-FCV_PROF_ROWS+1;
   ClampProfileOffset();
  }

//--- Ha Magic repetido em disco? Alimenta a cadeia de erro: e um problema que
//--- precisa ser visto DE FORA da aba Perfis, senao so quem ja desconfia olha.
bool HasDuplicateMagic(void)
  {
   for(int i=0;i<m_profCount;++i) if(m_profDup[i]) return true;
   return false;
  }

//--- O Magic DESTE grafico esta repetido em disco? E a pergunta que interessa
//--- para operar, e nao "ha algum Magic repetido em algum lugar": se GOLD e
//--- JP225 colidem entre si mas o perfil ativo tem numero proprio, esta conta
//--- corre sem ambiguidade, e recusar o INICIAR ali seria travar a operacao por
//--- um arquivo parado que nao participa dela.
//---
//--- Com o perfil ativo fora da lista (apagado por fora, lista desatualizada),
//--- basta o numero existir em algum arquivo: nao da para provar que e o mesmo
//--- perfil, e no escuro a resposta segura e recusar.
bool ActiveMagicConflicts(void)
  {
   int idx=ActiveProfileIndex();
   if(idx>=0) return m_profDup[idx];
   int magic=m_snap.magicNumber;
   if(magic<=0) return false;
   for(int i=0;i<m_profCount;++i) if(m_profMagic[i]==magic) return true;
   return false;
  }

//--- Quem divide o Magic com o perfil INDICADO. Recebe o indice em vez de
//--- varrer do inicio: havendo mais de um grupo de repetidos, a versao anterior
//--- descrevia sempre o primeiro grupo — e o cartao de um perfil do segundo
//--- grupo acusava nomes que nada tinham a ver com ele. Errar o nome do culpado
//--- e pior que nao nomear ninguem.
string DuplicateMagicNote(const int idx)
  {
   if(idx<0 || idx>=m_profCount || !m_profDup[idx]) return "";
   string peers="";
   int shared=m_profMagic[idx];
   for(int j=0;j<m_profCount;++j)
     {
      if(j==idx || m_profMagic[j]!=shared) continue;
      if(StringLen(peers)>0) peers+=", ";
      peers+=m_profName[j];
     }
   return "Magic "+IntegerToString(shared)+" usado por "+m_profName[idx]+
          " e "+peers+". O EA reconhece as proprias ordens pelo Magic: "+
          "dois perfis com o mesmo numero em dois graficos fazem cada um "+
          "adotar as ordens do outro.";
  }

//+------------------------------------------------------------------+
//| Travas do perfil selecionado, vindas dos registros do terminal.   |
//|                                                                   |
//| Portadas de BuildProfileActionState (UIPanelProfileActions.mqh).  |
//| Sao o OUTRO tipo de conflito: o de Magic repetido olha arquivos    |
//| parados em disco; estes olham o que esta RODANDO agora em outros   |
//| graficos. Sem eles a tela habilitaria acoes que o EA recusaria     |
//| depois — e prometer uma acao que falha e pior que nao oferece-la.  |
//|                                                                   |
//| Calculadas na troca de selecao, nunca por quadro: cada consulta    |
//| percorre as variaveis globais do terminal duas vezes.              |
//+------------------------------------------------------------------+
void RefreshSelectedProfileLocks(void)
  {
   m_selLocksAt=GetTickCount();
   m_selRuntimeLocked=false;
   m_selProfileLocked=false;
   m_selLockReason="";
   if(m_profSel<0 || m_profSel>=m_profCount) return;

   string reason="";
   CInstanceRegistry instances;
   if(instances.HasActiveConflict(m_profMagic[m_profSel],m_chart,reason))
     {
      m_selRuntimeLocked=true;
      m_selLockReason=reason;
      return;
     }

   CActiveProfileRegistry profiles;
   reason="";
   if(profiles.HasActiveProfilePeer(m_profName[m_profSel],m_chart,reason))
     {
      m_selProfileLocked=true;
      m_selLockReason=reason;
     }
  }

//--- Reconsulta periodica das travas, com limite de uma vez por segundo.
//---
//--- Elas descrevem o que OUTROS graficos estao fazendo, e nenhum evento deste
//--- painel avisa quando um deles inicia, para ou troca de perfil. Sem isto, a
//--- tela mantinha para sempre a resposta do instante em que a selecao mudou.
//---
//--- Um segundo, e nao por quadro: cada consulta percorre as variaveis globais
//--- do terminal duas vezes, e sao duas consultas. So roda com a aba Perfis a
//--- vista — no resto do painel a resposta nao e usada por ninguem.
//---
//--- Devolve true quando o estado MUDOU, para quem chama decidir se repinta.
//--- ⚠ Isto mantem o DESENHO fresco; nao substitui reconsultar na hora de
//--- executar CARREGAR/DUPLICAR/EXCLUIR, que entra com os comandos na 2c — ali
//--- a janela entre o que a tela mostrou e o clique ainda existe.
bool TouchProfileLocks(void)
  {
   if(m_tab!=FCV_TAB_PERFIS || m_minimized) return false;
   uint now=GetTickCount();
   if(m_selLocksAt!=0 && (now-m_selLocksAt)<1000) return false;

   bool wasRuntime=m_selRuntimeLocked, wasProfile=m_selProfileLocked;
   RefreshSelectedProfileLocks();
   return (wasRuntime!=m_selRuntimeLocked || wasProfile!=m_selProfileLocked);
  }

//+------------------------------------------------------------------+
//| Bloqueios operacionais de secao — alem do bloqueio geral.         |
//|                                                                   |
//| Sao trancas que o EA impoe a UMA parte da Gestao enquanto ela esta|
//| valendo, e nao dependem de o EA estar rodando: batido o limite    |
//| diario, a configuracao daquele limite fica suspensa ate o dia     |
//| virar, mesmo com o EA pausado. Pausar nao remove nem permite      |
//| alterar — e essa a razao de existirem: sem elas, quem batesse o   |
//| limite poderia pausar, aumentar o teto e voltar a operar,         |
//| desfazendo por edicao a protecao que acabou de agir.              |
//|                                                                   |
//| Portadas de UIPanelProtectionValidation.mqh. Cada uma le um campo |
//| do snapshot; nenhuma e deduzida do rascunho.                      |
//+------------------------------------------------------------------+
bool DailyConfigLocked(void)    { return m_snap.dailyLimitsBlocked; }
bool DrawdownConfigLocked(void) { return m_snap.drawdownConfigLocked; }
bool StreakConfigLocked(void)   { return m_snap.streakProtectionBlocked; }

//--- Ha um campo em edicao neste instante?
//---
//--- O texto digitado e INVISIVEL para o programa ate o terminal encerrar a
//--- edicao. Ler o objeto, da para ler; o que ele devolve ate o
//--- CHARTEVENT_OBJECT_ENDEDIT e o texto ANTERIOR, porque o buffer so e
//--- atualizado no fim. E nao ha evento de alteracao para avisar antes.
//--- Confirmado na documentacao e no forum oficial — nao e limitacao deste
//--- codigo. Por isso EditTextOutOfSync nao detecta digitacao em curso: ela e
//--- rede de seguranca, e quem cobre este caso e a funcao abaixo.
//---
//--- Entao tratamos a EDICAO EM CURSO como motivo suficiente para oferecer as
//--- duas saidas dela. E um palpite, mas honesto: enquanto o cursor esta no
//--- campo, SALVAR e CANCELAR sao exatamente o que o usuario pode querer, e
//--- oferece-los apagados enquanto ja funcionam era pior.
//---
//--- Nao vale para o aviso "alteracoes nao salvas", que afirmaria uma mudanca
//--- que pode nao existir, nem para o INICIAR — bloquear uma acao real so porque
//--- ha um cursor num campo seria pior que o problema.
//---
//--- ⚠ VALE, SIM, PARA AS QUATRO ACOES DE PERFIL, e isso foi acrescentado depois
//--- de o usuario notar a assimetria na tela: SALVAR e CANCELAR acendiam com o
//--- cursor no Magic enquanto NOVO e DUPLICAR continuavam acesos, sugerindo que
//--- criariam um perfil COM o Magic recem-digitado.
//---
//--- O criterio nao e "acao real", e se a acao CONSOME a edicao em curso. As
//--- quatro consomem, e por um caminho que nao e obvio: sair do campo por um
//--- clique passa por ReleaseEditFocus, que LE ANTES DE DESTRUIR e chama
//--- FieldSetText. O numero digitado vira pendencia do perfil ATIVO, e so entao
//--- o botao age — o usuario acaba dentro do formulario de criacao com uma
//--- alteracao pendente que ele nunca quis, no perfil errado. O INICIAR nao tem
//--- esse problema porque a pendencia que nasce ali ja o bloqueia pela escada.
bool EditingNow(void) { return EditHasFocus(); }

//--- Perfil preso a outro grafico.
bool AccPeerLock(void)
  { return (HasText(m_snap.startBlockedReason) || HasText(m_snap.activeProfileBlockedReason)); }

//--- Editar configuracao exige EA parado, sem posicao e sem bloqueio.
bool AccRuntimeEditable(void)
  { return (!m_snap.started && !m_snap.hasPosition && !m_snap.runtimeBlocked); }

//--- EDITAR O PERFIL ATIVO exige, alem do EA parado, que o perfil nao esteja
//--- preso por outro grafico. E o `activeProfileEditable` da 1.058
//--- (UIPanelAccessState.mqh:75), e e ele — nao o `runtimeEditable` — que
//--- governa cada campo, o SALVAR e a administracao de perfis.
//---
//--- A distincao nao e sutil: com o perfil preso, o `runtimeEditable` sozinho
//--- deixava os campos aceitarem digitacao enquanto o SALVAR — que ja checava a
//--- trava — ficava apagado. Dava para criar uma pendencia impossivel de gravar.
//--- E como CARREGAR segue liberado nesse estado (e a saida do bloqueio) e
//--- ignora pendencia por regra, a edicao feita ali seria descartada sem aviso
//--- assim que os comandos existirem.
bool AccActiveProfileEditable(void)
  { return (AccRuntimeEditable() && !AccPeerLock()); }

//+------------------------------------------------------------------+
//| A resposta unica do cabecalho. Ver SHeaderAction em CanvasLayout. |
//|                                                                   |
//| ⚠ AccCanStart() e AccCanPause() FORAM REMOVIDOS, e nao esquecidos:|
//| a escada abaixo E o predicado. Mantidos ao lado dela, seriam duas |
//| escritas da mesma regra — e quando divergissem, o painel apagaria |
//| o botao por um motivo e exibiria outro, que e precisamente o      |
//| defeito que esta funcao existe para tornar impossivel.            |
//|                                                                   |
//| A escada do INICIAR cobre termo a termo o que AccCanStart() dizia:|
//| runtime, perfil preso, configuracao valida, pendencia, Magic em   |
//| conflito e permissao de trading — mais o formulario de perfil     |
//| aberto, que antes ficava fora, no ponto do desenho.               |
//|                                                                   |
//| ⚠ PAUSAR NAO herda os bloqueios do INICIAR, e isto e regra. O EA  |
//| confirma: em EAApplicationCommands, o ramo de pausa so exige nao  |
//| haver posicao gerenciada — permissao de trading, validade da      |
//| configuracao e travas de perfil sao conferidas apenas no ramo de  |
//| INICIAR. O caso que fecha o argumento e AutoTrading desligado com |
//| o EA rodando: o motor mantem `m_started` de proposito, e tirar o  |
//| PAUSAR ali seria prender o Fusion ligado por condicao externa.    |
//|                                                                   |
//| `runtimeBlocked` e a unica excecao: ali o EA recusa QUALQUER      |
//| alternancia (`if(m_runtimeBlocked) return;`). Hoje o estado e     |
//| inalcancavel — ApplyRuntimeBlock e o unico ponto que o liga e     |
//| zera `m_started` no mesmo passo —, entao a guarda e defensiva: se |
//| o motor mudar, o painel nao passa a oferecer um clique inerte.    |
//|                                                                   |
//| Por que cada bloqueio do INICIAR existe:                          |
//|  - PENDENCIA: iniciar com alteracao nao gravada rodaria a         |
//|    configuracao COMPROMETIDA enquanto a tela mostra outra;        |
//|  - MAGIC repetido em disco: e o Magic que faz o EA reconhecer as  |
//|    proprias ordens, e comecar com ele ambiguo e comecar sem saber |
//|    quais ordens sao suas. Bloqueio proprio da 2.0 — a 1.058 so    |
//|    recusa CRIAR perfil com Magic tomado, e nao ve o estado gerado |
//|    por arquivo copiado por fora;                                  |
//|  - CONFIG invalida: era o `true` provisorio da 2b, que AFROUXAVA  |
//|    a regra e deixava iniciar com campo invalido.                  |
//+------------------------------------------------------------------+
//--- Fachada: a escada decide, e esta camada aplica a UNICA regra que vale para
//--- todos os desfechos dela. Sem ela a supressao teria de ser repetida em cada
//--- `return` da escada, e bastaria um esquecido para o card e a faixa dizerem
//--- a mesma coisa duas vezes.
//+------------------------------------------------------------------+
//| ResolveEntryRestriction — fonte unica de "novas entradas estao    |
//| suspensas, e por que".                                            |
//|                                                                   |
//| Consumida pelo distintivo, pela faixa e pelo marcador da aba      |
//| Status, e tambem pela escada de alertas do Status. Uma pergunta,  |
//| uma resposta: enquanto os dois lados a calculavam por conta        |
//| propria, a Fase 2 ja tinha visto o resultado — o "Estado DD" era  |
//| montado em dois arquivos com prioridades OPOSTAS, e as duas telas |
//| discordavam dentro do mesmo painel.                               |
//|                                                                   |
//| ⚠ A ORDEM E A DO MOTOR, nao uma de gravidade nossa.               |
//| ProtectionManager::CanOpen() recusa nesta sequencia — streak,     |
//| sessao, noticias, spread, limites diarios, drawdown — e nomear a  |
//| causa em outra ordem faria a faixa apontar para um bloqueio que   |
//| nao e o que efetivamente barra a entrada. Spread nao entra: e     |
//| instantaneo (ver SEntryRestriction).                              |
//|                                                                   |
//| ⚠⚠ FILTRO E PROTECAO TRAVADA NAO SE GUARDAM IGUAL, e supor que    |
//| sim esconde protecao em vigor. Extraido modulo a modulo de        |
//| Protection/Modules/, nao presumido:                               |
//|                                                                   |
//|  - FILTRO (sessao, noticias) so bloqueia com a chave LIGADA. O    |
//|    proprio modulo devolve "pode abrir" quando desligado           |
//|    (`IsInsideSession` retorna true sem o filtro). A guarda aqui e |
//|    defensiva, e existe para nunca acusar quem nao agiu;           |
//|                                                                   |
//|  - PROTECAO TRAVADA (sequencia, limites diarios, drawdown) NAO E  |
//|    GUARDADA, de proposito. `StreakProtection::CanOpen` nao olha   |
//|    as chaves em momento algum, e `DailyLimitsProtection::CanOpen` |
//|    consulta `CurrentBlockReason()` ANTES de olhar                 |
//|    `enableDailyLimits` — ou seja, o bloqueio ja travado sobrevive |
//|    a chave ser desligada depois. E isso e deliberado no motor:    |
//|    senao quem batesse o limite desligaria a protecao e voltaria a |
//|    operar, desfazendo por edicao o que ela acabou de fazer.       |
//|    Guardar aqui faria a tela dizer "sem restricao" com o EA       |
//|    recusando entradas — dado certo sob desenho errado, que e pior |
//|    que erro visivel.                                              |
//|                                                                   |
//| ⚠ DD ARMADO NAO ENTRA AQUI. `drawdownProtectionActive` protege a  |
//| configuracao e recusa perfil incompativel, mas as entradas SEGUEM |
//| PERMITIDAS ate o preco tocar o piso. So `drawdownLimitReached`    |
//| suspende. Confundir os dois transformaria a protecao agindo       |
//| normalmente num bloqueio que nao existe.                          |
//+------------------------------------------------------------------+
SEntryRestriction ResolveEntryRestriction(void)
  {
   SEntryRestriction r;
   r.active=false; r.cause=""; r.reason="";

   //--- Protecao travada: sem guarda de chave (ver o cabecalho).
   if(m_snap.streakProtectionBlocked)
     { r.active=true; r.cause="SEQUENCIA"; r.reason=m_snap.streakProtectionBlockReason; return r; }
   //--- Filtros: so falam ligados.
   if(m_snap.settings.enableSessionFilter && m_snap.sessionProtectionBlocked)
     { r.active=true; r.cause="SESSAO";    r.reason=m_snap.sessionProtectionBlockReason; return r; }
   if(FusionHasEnabledNewsWindow(m_snap.settings) && m_snap.newsProtectionBlocked)
     { r.active=true; r.cause="NOTICIAS";  r.reason=m_snap.newsProtectionBlockReason; return r; }
   //--- Protecao travada, as duas ultimas.
   if(m_snap.dailyLimitsBlocked)
     { r.active=true; r.cause="LIMITE DIARIO"; r.reason=m_snap.dailyLimitsBlockReason; return r; }
   if(m_snap.drawdownLimitReached)
     { r.active=true; r.cause="DRAWDOWN";  r.reason=m_snap.drawdownConfigLockReason; return r; }
   return r;
  }

//--- DD ARMADO: informacao, e nao restricao. Fica fora do resolvedor acima de
//--- proposito, e a faixa so a mostra quando nao ha nada mais forte a dizer.
//--- As duas consequencias sao reais e hoje so aparecem quando o usuario
//--- esbarra nelas: os parametros de DD ficam so-leitura, e o CARREGAR recusa
//--- perfil com regra de DD diferente (o passo H4 do aceite da Fase 3).
bool DrawdownArmedOnly(void)
  {
   return (m_snap.drawdownProtectionActive && !m_snap.drawdownLimitReached);
  }

SHeaderAction ResolveHeaderActionState(void)
  {
   SHeaderAction s=ResolveHeaderActionLadder();
   //+------------------------------------------------------------------+
   //| Faixa livre: quem ocupa e a restricao de entradas.                |
   //|                                                                   |
   //| A escada acima tem prioridade porque a faixa dela responde "por   |
   //| que este botao esta apagado" ou "por que o distintivo diz         |
   //| IMPEDIDO" — perguntas que o usuario acabou de fazer com o cursor. |
   //| A restricao de entradas nao instrui acao nenhuma no cabecalho;    |
   //| ela informa. Informacao nao empurra instrucao para fora da tela.  |
   //|                                                                   |
   //| Na pratica quase nunca competem: com o EA rodando e sem posicao,  |
   //| a escada so escreve na faixa quando ha bloqueio de permissao.     |
   //+------------------------------------------------------------------+
   if(!HasText(s.band))
     {
      SEntryRestriction r=ResolveEntryRestriction();
      //--- `started`: parado o distintivo ja diz PAUSADO, e ninguem espera
      //--- entrada de EA parado — anunciar suspensao ali seria ruido.
      if(m_snap.started && r.active)
        {
         s.band=r.cause+" — "+r.reason;
         s.bandSem=FCV_SEM_WARN;
        }
      //+---------------------------------------------------------------+
      //| DD ARMADO: informacao de baixa prioridade, e SEM condicao de   |
      //| `started`.                                                     |
      //|                                                                |
      //| Parado e justamente quando ela mais serve: e o estado em que o |
      //| usuario vai a aba Perfis e leva uma recusa no CARREGAR. Foi o  |
      //| que o passo H4 do aceite da Fase 3 exercitou, e ate aqui a     |
      //| unica pista vinha DEPOIS do clique.                            |
      //|                                                                |
      //| Nao diz "sem entradas" em lugar nenhum, de proposito: com o DD |
      //| apenas armado elas continuam permitidas ate o piso.            |
      //+---------------------------------------------------------------+
      else if(DrawdownArmedOnly())
        {
         s.band="DD ATIVO — parametros protegidos; perfil incompativel nao pode ser carregado";
         s.bandSem=FCV_SEM_WARN;
        }
     }
   //--- Card critico no ar: a faixa cala, sempre. Ele ja diz, e mais alto e com
   //--- o texto grave do motor. Antes a supressao existia so no ramo
   //--- "rodando com posicao", entao o EA PARADO com posicao e permissao
   //--- perdida mostrava os dois com a mesma causa.
   if(s.critical) { s.band=""; s.bandSem=FCV_SEM_NEUTRAL; }
   return s;
  }

SHeaderAction ResolveHeaderActionLadder(void)
  {
   SHeaderAction s;
   s.action=FCV_HACT_NONE; s.label="INICIAR"; s.enabled=false;
   s.block=FCV_HBLK_NONE;  s.band="";         s.bandSem=FCV_SEM_WARN;
   //--- PAUSADO em ambar, como sempre foi: "parado e pronto" nao e defeito.
   s.badge="PAUSADO";      s.badgeSem=FCV_SEM_WARN;
   s.statusMark=false;     s.critical=false;

   SEntryRestriction entryR=ResolveEntryRestriction();

   //--- Distintivo: ESTADO, nunca causa. Nomear a causa aqui seria mentir em
   //--- quatro dos cinco motivos que o guard cobre — ele bloqueia por conexao
   //--- perdida e por permissao da conta tambem, nao so por AutoTrading.
   if(m_snap.runtimeBlocked)
     { s.badge="BLOQUEADO"; s.badgeSem=FCV_SEM_BAD; }
   //--- Vermelho como BLOQUEADO, e nao ambar como PAUSADO: os dois primeiros
   //--- dizem "o EA nao pode operar" e o terceiro diz "esta parado e pronto".
   //--- E a distincao que o usuario precisa de relance; qual das duas causas e
   //--- ele le no texto do distintivo e na faixa.
   else if(m_snap.tradePermissionBlocked)
     { s.badge="IMPEDIDO";  s.badgeSem=FCV_SEM_BAD; }
   //--- OPERANDO e o estado MAIS ESPECIFICO verdadeiro quando ha posicao, e por
   //--- isso vem antes de RODANDO. Ele morava no ROTULO DO BOTAO, que era a
   //--- ultima violacao do modelo — botao nomeia acao, distintivo nomeia estado.
   //--- Trazido para ca, o distintivo ganha a informacao que faltava no topo e o
   //--- botao volta a nomear a acao em 100% dos casos.
   //--- Verde como RODANDO: os dois sao estados saudaveis; o que os distingue e
   //--- a palavra, nao a cor.
   //--- `hasOpenPosition`, nao `hasPosition`: o segundo tambem e verdadeiro
   //--- durante a reconciliacao de um fechamento, quando a posicao JA fechou.
   //--- Dizer OPERANDO ali anunciaria uma operacao que nao existe mais.
   else if(m_snap.started && m_snap.hasOpenPosition)
     { s.badge="OPERANDO";  s.badgeSem=FCV_SEM_GOOD; }
   //+------------------------------------------------------------------+
   //| SEM ENTRADAS — armado, mas nao vai procurar entrada.              |
   //|                                                                   |
   //| ⚠ AMBAR, e nao vermelho. Vermelho e para "o EA nao pode operar"   |
   //| (BLOQUEADO, IMPEDIDO); aqui a protecao esta FUNCIONANDO, e pintar |
   //| de vermelho o mecanismo agindo como devia ensinaria o usuario a   |
   //| tratar a propria protecao como defeito.                           |
   //|                                                                   |
   //| ⚠ DEPOIS de OPERANDO. Com posicao aberta ha dinheiro exposto      |
   //| agora, e esse e o estado mais especifico verdadeiro; a suspensao  |
   //| de NOVAS entradas nao muda o que ja esta em gerenciamento e desce |
   //| para a faixa. Antes de RODANDO porque "rodando" afirma aptidao —  |
   //| e a mesma razao que fez BLOQUEADO vencer RODANDO na Fase 2.       |
   //|                                                                   |
   //| ⚠ So com `started`: parado, o distintivo ja diz PAUSADO, que e    |
   //| mais forte e mais simples — ninguem espera entrada de EA parado.  |
   //+------------------------------------------------------------------+
   else if(m_snap.started && entryR.active)
     { s.badge="SEM ENTRADAS"; s.badgeSem=FCV_SEM_WARN; }
   else if(m_snap.started)
     { s.badge="RODANDO";   s.badgeSem=FCV_SEM_GOOD; }

   //--- O marcador da aba aponta para onde a EXPLICACAO esta. Os dois primeiros
   //--- tem a explicacao no Status; os demais motivos moram na tela deles. A
   //--- restricao de entradas entra porque o detalhe dela tambem vive la, na
   //--- escada de alertas — que agora le ESTE mesmo resolvedor.
   s.statusMark = (m_snap.runtimeBlocked || m_snap.tradePermissionBlocked ||
                   (m_snap.started && entryR.active));
   //--- Trading indisponivel com posicao aberta: o gerenciamento parou no meio
   //--- de uma operacao. E o unico estado que merece tomar espaco de conteudo
   //--- em qualquer aba.
   //---
   //--- ⚠ `hasOpenPosition`, e NAO `hasPosition`. O segundo inclui o fechamento
   //--- aguardando o historico confirmar, e nesse estado a posicao ja pode ter
   //--- fechado — o card anunciaria "COM POSICAO ABERTA" sobre um corpo na
   //--- forma branda, porque o guard recebe justamente `hasOpenPosition` e
   //--- escreve a versao grave so quando ele e verdadeiro. Os dois lados tem de
   //--- olhar o mesmo booleano.
   s.critical   = (m_snap.tradePermissionBlocked && m_snap.hasOpenPosition);

   bool formOpen = (m_profEdit!=FCV_PROF_VIEW);
   //+---------------------------------------------------------------+
   //| Fechamento aguardando o historico confirmar.                   |
   //|                                                                |
   //| `hasPosition` verdadeiro com `hasOpenPosition` falso e          |
   //| exatamente isto: HasManagedOrPendingPosition() soma a           |
   //| reconciliacao pendente, e nesse instante a posicao ja fechou.   |
   //|                                                                |
   //| ⚠ O EA recusa OS DOIS comandos enquanto durar — o ramo de       |
   //| pausa por HasManagedOrPendingPosition(), o de inicio por        |
   //| m_closeReconciliationPending. Sem este estado o painel          |
   //| oferecia INICIAR aceso com clique inerte, e ainda anunciava     |
   //| "posicao em gerenciamento" sem posicao nenhuma.                 |
   //+---------------------------------------------------------------+
   bool reconciling = (m_snap.hasPosition && !m_snap.hasOpenPosition);
   string reconcileBand="FECHAMENTO EM RECONCILIACAO — aguarde a confirmacao do historico";

   //=== EA rodando COM posicao aberta: nao ha acao ===================
   if(m_snap.started && m_snap.hasOpenPosition)
     {
      //--- PAUSAR apagado, e nao "OPERANDO". A acao que o botao representaria e
      //--- pausar; o que impede e a posicao aberta, e quem diz isso e a faixa —
      //--- exatamente o padrao que ja vale para o INICIAR bloqueado. O estado
      //--- OPERANDO subiu para o distintivo, onde estado pertence.
      s.label="PAUSAR";  s.action=FCV_HACT_PAUSE;
      s.enabled=false;   s.block=FCV_HBLK_POSITION;
      //--- Se o card critico estiver no ar, a fachada apaga esta faixa.
      s.band="POSICAO ABERTA — a saida e pela estrategia ou pela protecao";
      s.bandSem=FCV_SEM_NEUTRAL;
      return s;
     }

   //=== EA rodando, fechamento em reconciliacao =====================
   if(m_snap.started && reconciling)
     {
      s.label="PAUSAR"; s.action=FCV_HACT_PAUSE;
      s.enabled=false;  s.block=FCV_HBLK_RECONCILE;
      s.band=reconcileBand; s.bandSem=FCV_SEM_NEUTRAL;
      return s;
     }

   //=== EA rodando SEM posicao: PAUSAR ==============================
   if(m_snap.started)
     {
      s.label="PAUSAR"; s.action=FCV_HACT_PAUSE;
      if(m_snap.runtimeBlocked)
        {
         s.block=FCV_HBLK_RUNTIME; s.band=m_snap.runtimeBlockReason;
         s.bandSem=FCV_SEM_BAD; return s;
        }
      if(formOpen)
        {
         s.block=FCV_HBLK_PROFFORM;
         s.band="FORMULARIO DE PERFIL ABERTO — conclua ou descarte";
         return s;
        }
      s.enabled=true;
      //+---------------------------------------------------------------+
      //| ⚠ Texto do MOTOR aqui tambem, e nao um neutro nosso.           |
      //|                                                                |
      //| A versao anterior dizia "TRADING INDISPONIVEL — PAUSAR         |
      //| CONTINUA DISPONIVEL". Era verdade e nao servia: nao dizia o    |
      //| que FAZER. O motivo de eu ter evitado o texto do motor era que |
      //| ele termina em "Habilite para iniciar" com o EA ja rodando —   |
      //| mas isso descreve exatamente a acao necessaria, e o distintivo |
      //| ao lado ja diz IMPEDIDO: armado e impedido, habilite para      |
      //| passar a operar. A leitura fecha.                              |
      //|                                                                |
      //| E a nota sobre o PAUSAR sobrava: o botao esta logo acima,      |
      //| aceso, em ambar. Nesta linha a faixa nao responde "por que o   |
      //| botao esta apagado" — ele nao esta —, responde "por que o      |
      //| distintivo diz IMPEDIDO". So o texto do motor responde isso    |
      //| nomeando a causa entre as cinco que o guard cobre.             |
      //+---------------------------------------------------------------+
      if(m_snap.tradePermissionBlocked)
        {
         s.band=m_snap.tradePermissionReason;
         s.bandSem=FCV_SEM_WARN;
        }
      return s;
     }

   //=== EA parado: INICIAR ==========================================
   s.label="INICIAR"; s.action=FCV_HACT_START;

   if(m_snap.runtimeBlocked)
     { s.block=FCV_HBLK_RUNTIME; s.band=m_snap.runtimeBlockReason; s.bandSem=FCV_SEM_BAD; return s; }
   //--- ⚠ LOGO APOS o runtime, e nao no fim como esteve. A regra "primeiro o que
   //--- o usuario resolve aqui" nao se aplica quando NADA e resolvivel: durante
   //--- a reconciliacao os campos estao travados (AccRuntimeEditable inclui
   //--- hasPosition), o SALVAR e recusado, o CANCELAR tambem e o CARREGAR
   //--- idem. Todas as mensagens abaixo — "corrija ou cancele", "salve ou
   //--- cancele", "carregue outro perfil" — instruiriam acoes indisponiveis,
   //--- que e a licao 1 da secao 8. A unica informacao util ali e que a espera
   //--- existe e passa sozinha.
   if(reconciling)
     { s.block=FCV_HBLK_RECONCILE; s.band=reconcileBand; s.bandSem=FCV_SEM_NEUTRAL; return s; }
   if(formOpen)
     { s.block=FCV_HBLK_PROFFORM; s.band="FORMULARIO DE PERFIL ABERTO — conclua ou descarte"; return s; }
   //--- Antes de CONFIG de proposito: preso, o perfil ativo fica so-leitura
   //--- (AccActiveProfileEditable), entao mandar corrigir a configuracao
   //--- apontaria para campos que nao aceitam digitacao. CARREGAR segue
   //--- liberado nesse estado e e a saida — e por isso que ela e citada.
   if(AccPeerLock())
     {
      s.block=FCV_HBLK_PEERLOCK;
      s.band=HasText(m_snap.startBlockedReason) ? m_snap.startBlockedReason
                                                : m_snap.activeProfileBlockedReason;
      return s;
     }
   //--- ⚠ ANTES de CONFIG, e nao depois. Magic repetido no perfil ativo JA
   //--- reprova ConfigInputsValid() — ScreenErrorProfiles cobra unicidade em
   //--- modo de visualizacao, via VMagicTakenByOther. Posto depois, este ramo
   //--- era inalcancavel na pratica e a faixa dizia "CONFIGURACAO INVALIDA"
   //--- para um problema que tem nome. **Causa especifica vence a generica.**
   if(ActiveMagicConflicts())
     { s.block=FCV_HBLK_MAGIC; s.band="MAGIC DO PERFIL EM CONFLITO — resolva em Perfis"; s.bandSem=FCV_SEM_BAD; return s; }
   //--- Antes de PENDING, senao a faixa diria "salve" com o SALVAR apagado: ele
   //--- tambem exige ConfigInputsValid(). CANCELAR nao exige, e continua sendo
   //--- saida nos dois casos — daí "ou cancele" nos dois textos.
   //+---------------------------------------------------------------+
   //| Perfil ativo sem arquivo — ACIMA de CONFIG, e o resto da escada |
   //| inalterado.                                                     |
   //|                                                                |
   //| Vence PENDING porque as duas se resolvem com o MESMO SALVAR e   |
   //| esta e a mais grave: "salve ou cancele" sugere que CANCELAR e   |
   //| saida, e aqui ele nao e — nao ha arquivo para onde voltar.      |
   //|                                                                |
   //| Perde para PEERLOCK, que continua acima: preso por outro        |
   //| grafico o SALVAR nem acende, e ali CARREGAR e a saida — mandar  |
   //| gravar seria instruir o impossivel.                             |
   //|                                                                |
   //| E e a faixa que sustenta a trava das acoes de perfil            |
   //| (AccSaveFirstLock). Sem ela seriam botoes apagados sem          |
   //| explicacao — trocariamos um problema por outro.                 |
   //|                                                                |
   //| ⚠ SAO CINCO BOTOES, E NAO QUATRO: estar na escada apaga tambem  |
   //| o INICIAR, porque todo ramo daqui retorna com `s.enabled` ainda |
   //| falso. Passou despercebido na primeira versao; a auditoria      |
   //| achou, e o efeito era real e nao documentado.                   |
   //|                                                                |
   //| Conferido, esta CERTO, e o motivo nao e o das outras quatro:    |
   //| INICIAR nao abandona o perfil, ele FECHA A PORTA DA RECUPERACAO.|
   //| O SALVAR exige AccActiveProfileEditable, que exige `!started` — |
   //| iniciar com o arquivo ausente deixa a unica copia da            |
   //| configuracao presa na memoria, sem forma de grava-la, a um      |
   //| reinicio de sumir.                                              |
   //+---------------------------------------------------------------+
   //--- ⚠ SUBIU PARA CIMA DO CONFIG. Estava abaixo, e por isso a faixa calava
   //--- exatamente no pior estado: arquivo ausente COM configuracao invalida
   //--- mostrava "CONFIGURACAO INVALIDA — corrija ou cancele" e nao dizia uma
   //--- palavra sobre o perfil estar a um clique de sumir. O usuario encontrou
   //--- assim, e o unico sinal era o subtitulo vermelho do cabecalho.
   //---
   //--- ⚠ Aqui a faixa deixa de ter a MESMA condicao da trava, e isso e
   //--- deliberado: `ActiveProfileOrphan` e o estado, `AccSaveFirstLock` e o
   //--- estado MAIS o SALVAR ser saida. Onde a trava se cala por nao ter saida a
   //--- oferecer, o risco continua existindo — e calar junto seria esconde-lo.
   //--- O texto muda com isso, e nao so o gatilho.
   if(ActiveProfileOrphan())
     {
      s.block=FCV_HBLK_NOFILE;
      s.bandSem=FCV_SEM_BAD;
      //--- ⚠ Com a configuracao invalida NAO mandamos "corrigir". A
      //--- incompatibilidade pode ser so com ESTE ativo — lote legitimo no ouro,
      //--- impossivel no indice —, e "corrija" induziria a trocar 0.40 por 1.00,
      //--- descaracterizando um perfil que esta perfeitamente certo para o ativo
      //--- dele. O que preserva a configuracao ali e o arquivo original.
      s.band=ConfigInputsValid()
             ? "PERFIL EM USO SEM ARQUIVO — grave antes de iniciar ou trocar de perfil"
             : "PERFIL SEM ARQUIVO E INVALIDO NESTE ATIVO — restaure o arquivo para preservar";
      return s;
     }
   if(!ConfigInputsValid())
     { s.block=FCV_HBLK_CONFIG; s.band="CONFIGURACAO INVALIDA — corrija ou cancele"; s.bandSem=FCV_SEM_BAD; return s; }
   if(HasPending())
     { s.block=FCV_HBLK_PENDING; s.band="ALTERACOES PENDENTES — salve ou cancele"; return s; }
   //--- Por ultimo: e o unico que nao se resolve dentro do painel. Aqui o texto
   //--- do motor vale LITERAL — com o EA parado, "Habilite para iniciar" e
   //--- exatamente o que o usuario precisa fazer. E ele distingue as cinco
   //--- causas do guard sem o painel precisar saber qual e.
   if(m_snap.tradePermissionBlocked)
     { s.block=FCV_HBLK_PERMISSION; s.band=m_snap.tradePermissionReason; return s; }
   s.enabled=true;
   //+---------------------------------------------------------------+
   //| INICIAR disponivel, mas ha posicao aberta em gerenciamento.     |
   //|                                                                |
   //| Nao e bloqueio — e por isso vem DEPOIS do `enabled=true`, e nao |
   //| na escada. Aqui a faixa nao responde "por que o botao esta      |
   //| apagado"; responde "por que o distintivo diz PAUSADO havendo    |
   //| operacao em curso", como ja faz no caso do trading indisponivel |
   //| com o EA rodando.                                               |
   //|                                                                |
   //| Existe porque o Status conta isso (selo ENTRADAS SUSPENSAS mais |
   //| a nota), e de qualquer outra aba nao ha sinal nenhum — o usuario |
   //| reabre o MT5 com posicao aberta e nao sabe que precisa clicar    |
   //| INICIAR para voltar a aceitar entradas.                          |
   //|                                                                |
   //| Faixa e nao card de rodape, decidido com o usuario: o card       |
   //| encurta a area util em TODAS as abas enquanto durar, e uma       |
   //| posicao aberta dura horas. O card fica reservado ao caso critico |
   //| (permissao perdida COM posicao), onde competir por espaco e      |
   //| correto. Ambar e nao verde: verde diria "nao ha nada a decidir", |
   //| e ha — as entradas estao suspensas. E o mesmo ambar do selo do   |
   //| Status, de proposito.                                            |
   //+---------------------------------------------------------------+
   //--- `hasOpenPosition`: durante a reconciliacao nao ha posicao a gerenciar,
   //--- e aquele estado ja saiu acima com texto proprio.
   if(m_snap.hasOpenPosition)
     {
      s.band="POSICAO EM GERENCIAMENTO — clique INICIAR para liberar novas entradas futuras";
      s.bandSem=FCV_SEM_WARN;
     }
   return s;
  }

//--- Carregar perfil com o EA RODANDO trocaria os parametros sob a operacao —
//--- inaceitavel mesmo sem posicao aberta. Por isso exige EA parado.
//--- A excecao da 1.058 e deliberada: com o perfil preso por outro grafico,
//--- carregar continua liberado, porque escolher outro perfil e justamente a
//--- saida para desfazer esse bloqueio. Carregar nao libera a operacao.
//+------------------------------------------------------------------+
//| ⚠ A TRAVA LOCAL VENCE A EXCECAO DO PEER LOCK.                     |
//|                                                                   |
//| A composicao anterior — herdada fielmente da 1.058                |
//| (UIPanelAccessState.mqh:97) — devolvia true no peer lock ANTES de |
//| olhar `hasPosition`, e a excecao furava a trava local em dois     |
//| estados:                                                          |
//|                                                                   |
//|  - reconciliacao + peer lock: CARREGAR acendia e o EA recusava    |
//|    sem executar (`m_closeReconciliationPending`). Clique inerte.  |
//|  - POSICAO ABERTA + peer lock: pior. Na epoca o LOAD_PROFILE do   |
//|    motor nao tinha guarda para posicao aberta — recusava so por   |
//|    reconciliacao, drawdown e travas de concorrencia —, entao o    |
//|    clique CHEGAVA a trocar a configuracao ativa (o Magic entre    |
//|    ela) com uma operacao em gerenciamento.                        |
//|                                                                   |
//| A excecao continua existindo, e a razao dela tambem: com o perfil |
//| preso por outro grafico, escolher outro perfil e a saida do       |
//| bloqueio. Ela so deixa de valer quando ha trava local — e ai nao  |
//| ha saida a oferecer, ha uma operacao a proteger.                  |
//|                                                                   |
//| ⚠ Hoje sao DUAS guardas, e esta e a de fora. O motor tambem       |
//| recusa: o UI_COMMAND_LOAD_PROFILE ganhou, no mesmo aceite, a      |
//| recusa por posicao em gerenciamento, com a leitura sincronizada   |
//| antes de decidir. Esta camada existe para o botao nem acender —   |
//| aquela, para que nenhum emissor do comando escape.                |
//|                                                                   |
//| A 1.058 nao foi alterada e acendia o botao nesse estado — sem     |
//| perigo, porque o comando chegava ao motor e voltava recusado. A   |
//| Fase 4 removeu aquele painel, e essa incoerencia foi com ele; a   |
//| guarda do motor fica, que e a que protege o COMANDO.              |
//+------------------------------------------------------------------+
bool AccCanLoadProfile(void)
  {
   if(m_snap.started || m_snap.hasPosition) return false;
   if(AccPeerLock())  return true;
   return !HasPending();
  }

//+------------------------------------------------------------------+
//| POR QUE o CARREGAR do selecionado esta apagado — ou "" se ele nao |
//| esta.                                                             |
//|                                                                   |
//| A ordem espelha a composicao de `canLoad` em ScreenProfiles, e    |
//| nao uma sequencia propria: uma nota que explica um botao tem de   |
//| acusar a MESMA condicao que o apagou. Com ordem propria ela       |
//| mandaria consertar o que nao e o impedimento — e o usuario        |
//| consertaria, sem o botao acender.                                 |
//|                                                                   |
//| Dois membros daquela composicao nao aparecem aqui porque a nota   |
//| so e desenhada fora deles: formulario aberto e selecionado ja     |
//| ativo.                                                            |
//+------------------------------------------------------------------+
string LoadBlockedWhy(void)
  {
   if(m_profSel>=0 && m_profDup[m_profSel])
      return "Ele tem Magic repetido em disco e por isso nao carrega: DUPLICAR com outro Magic, ou EXCLUIR.";
   if(m_selRuntimeLocked || m_selProfileLocked)
      return "Ele esta em uso por outro Fusion em execucao.";
   if(AccSaveFirstLock())
      return "Antes, grave o perfil em uso: a configuracao dele nao esta no disco.";
   if(EditingNow())
      return "Ha um campo em edicao: conclua com SALVAR ou CANCELAR.";
   if(m_snap.started)
      return "Carregar exige o EA parado.";
   if(m_snap.hasPosition)
      return m_snap.hasOpenPosition
             ? "Ha posicao em gerenciamento: carregar trocaria os parametros sob a operacao."
             : "O fechamento aguarda a confirmacao do historico.";
   //--- A excecao do peer lock vem depois do que trava de verdade e ANTES da
   //--- pendencia, igual em AccCanLoadProfile: com o perfil preso por outro
   //--- grafico, carregar outro E a saida, e ali a pendencia deixa de pesar.
   if(AccPeerLock()) return "";
   if(HasPending())
      return "Salve ou cancele as alteracoes pendentes primeiro.";
   return "";
  }

//+------------------------------------------------------------------+
//| PERFIL ATIVO SEM ARQUIVO: as acoes de perfil ficam trancadas ate  |
//| gravar.                                                           |
//|                                                                   |
//| O estado ja acendia o SALVAR, e so isso. Nao segurava nenhuma das |
//| portas que levam para longe dele, e as quatro levam:              |
//|                                                                   |
//|  - CARREGAR troca o perfil ativo: a configuracao em uso some;     |
//|  - NOVO e DUPLICAR criam, e criar tambem ATIVA (divida registrada |
//|    da secao 6), entao abandonam o perfil sem arquivo do mesmo     |
//|    jeito — a configuracao sobrevive sob outro nome, a identidade  |
//|    nao;                                                           |
//|  - EXCLUIR apaga OUTRO perfil e nao abandonaria nada, mas fica    |
//|    junto por decisao do usuario: primeiro grave, depois apague    |
//|    com o perfil ja fora de risco. Quatro botoes apagados de uma   |
//|    vez tambem leem melhor que tres e um aceso.                     |
//|                                                                   |
//| ⚠ O RESTO DA FUNCAO E O QUE IMPEDE UM BECO, e nao detalhe: a      |
//| trava so vale quando o SALVAR REALMENTE resolve. E a licao 2 —    |
//| todo bloqueio precisa de saida pela propria GUI.                  |
//|                                                                   |
//| ⚠⚠ `m_notSaved` FICA DE FORA, e essa exclusao e a mais            |
//| importante daqui. Ele nao e "outra porta para o mesmo estado": e  |
//| a PROVA DE QUE O SALVAR NAO RESOLVE — so existe depois de uma     |
//| gravacao tentada e falhada (SetPersistenceFailed). Trancar por    |
//| ele deixaria o usuario com quatro botoes apagados e um SALVAR que |
//| falha de novo a cada clique, que e exatamente o beco que a decisao|
//| registrada no plano evita ("CARREGAR continua permitido... com o  |
//| disco quebrado deixaria o usuario sem saida"). Ali vale a politica|
//| de la: carregar segue liberado e a perda e ANUNCIADA, com o nome  |
//| do perfil que ficou para tras.                                    |
//|                                                                   |
//| E isso da a saida de graca, sem mecanismo nenhum: preso na trava, |
//| o usuario clica SALVAR; se falhar, `m_notSaved` liga e a trava    |
//| levanta sozinha. A tentativa frustrada E a chave.                  |
//|                                                                   |
//| As demais condicoes sao as mesmas que acendem o SALVAR (ver o     |
//| botao em DrawHeader). Sem elas o caso mortal seria o perfil preso |
//| por OUTRO grafico: ali o SALVAR nem acende, e CARREGAR e a unica  |
//| saida — trancar as quatro deixaria o usuario sem nenhuma.         |
//+------------------------------------------------------------------+
//--- O ESTADO: o arquivo sumiu e a configuracao em uso so existe na memoria.
//--- Separado da trava por UMA condicao — a validade da configuracao —, e e
//--- justamente nessa diferenca que mora o caso que o usuario encontrou: perfil
//--- de OUTRO ativo (lote 0.40 num indice de 1 contrato) nao pode ser gravado,
//--- entao a trava nao engata e ele fica sem protecao nenhuma. O estado existe
//--- para a FAIXA poder falar mesmo ali, onde a trava se cala.
bool ActiveProfileOrphan(void)
  {
   if(!m_snap.activeProfileFileMissing) return false;
   if(m_notSaved) return false;
   //--- `m_createFailed` entra porque o SALVAR tambem o consulta: com uma
   //--- criacao falhada pendente ele fica apagado de proposito, e a saida dali e
   //--- o DESCARTAR do formulario.
   return (!m_createFailed && AccActiveProfileEditable());
  }

bool AccSaveFirstLock(void)
  { return (ActiveProfileOrphan() && ConfigInputsValid()); }

//+------------------------------------------------------------------+
//| CARREGAR do SELECIONADO, e CONCLUIR a copia — numa funcao cada.   |
//|                                                                   |
//| Pela mesma razao que fez `AccCanDeleteSelected` existir: quem     |
//| desarma uma confirmacao precisa da MESMA resposta que a ofereceu. |
//| Escritas so na tela, a confirmacao de abandono sumia da vista     |
//| quando a acao ficava indisponivel (peer lock, por exemplo) e o    |
//| estado dela continuava vivo — voltando o acesso, a pergunta       |
//| RESSUSCITAVA. Foi o P2 da auditoria, e e o mesmo furo que a       |
//| Etapa 2b abriu com uma copia divergente de predicado.             |
//+------------------------------------------------------------------+
bool AccCanLoadSelected(void)
  {
   if(m_profEdit!=FCV_PROF_VIEW) return false;
   if(m_profSel<0 || m_profSel>=m_profCount) return false;
   if(m_profSel==ActiveProfileIndex()) return false;
   if(m_profDup[m_profSel]) return false;
   if(m_selRuntimeLocked || m_selProfileLocked) return false;
   if(AccSaveFirstLock() || EditingNow()) return false;
   return AccCanLoadProfile();
  }

bool AccCanCreateCopy(void)
  {
   if(m_profEdit!=FCV_PROF_DUP) return false;
   bool nameBad=false, magicBad=false; string err="";
   if(!ProfileFormReady(nameBad,magicBad,err)) return false;
   return ConfigInputsValid();
  }

//--- Excluir mexe no disco: exige o perfil ativo editavel e nada pendente.
bool AccCanAdminProfile(void)
  { return (AccActiveProfileEditable() && !HasPending()); }

//--- Criar e duplicar nao tocam no perfil ativo, mas ainda exigem EA parado.
//---
//--- Repare no que NAO esta aqui: a trava de perfil por outro grafico. E
//--- deliberado na 1.058 e faz sentido — criar um perfil novo nao mexe no que
//--- esta preso, e e um dos caminhos de saida do bloqueio.
//---
//--- E a pendencia so pesa para ENTRAR no formulario. Ja dentro dele, deixa de
//--- contar: `profileEditMode || !hasPendingChanges` (UIPanelAccessState:76).
//--- Sem essa metade, uma pendencia surgida com o formulario aberto trancaria
//--- os proprios campos dele — o usuario ficaria num formulario que nao aceita
//--- digitacao e cujo unico botao promete criar o que ele nao consegue
//--- preencher.
bool AccCanCreateProfile(void)
  { return (AccRuntimeEditable() && (m_profEdit!=FCV_PROF_VIEW || !HasPending())); }

//--- EXCLUIR do perfil SELECIONADO, numa funcao so.
//---
//--- Uma funcao, e nao a expressao escrita na tela, porque ela e consultada em
//--- dois lugares que precisam concordar: o desenho, que decide se oferece; e o
//--- pulso, que DESARMA a confirmacao quando a oferta some. Divergindo, ficaria
//--- uma confirmacao armada para uma acao que a tela ja nao oferece — e foi
//--- exatamente uma copia divergente de predicado de acesso que abriu o quarto
//--- furo encontrado na revisao da Etapa 2b.
//---
//--- Nem o ativo nem o DEFAULT se apagam, e perfil preso por outro grafico
//--- tambem nao. EXCLUIR segue liberado em perfil com Magic repetido, de
//--- proposito: e a saida daquele bloqueio.
bool AccCanDeleteSelected(void)
  {
   if(m_profEdit!=FCV_PROF_VIEW) return false;
   //--- AQUI DENTRO, e nao ao lado do PutButton como as outras tres: esta funcao
   //--- e a fonte unica que o desenho e o pulso consultam, e a divergencia entre
   //--- os dois e exatamente o furo que ela existe para nao ter. Posta fora, uma
   //--- exclusao armada sobreviveria ao botao que a ofereceu.
   if(AccSaveFirstLock()) return false;
   //--- Edicao em curso, pelo mesmo motivo — e aqui dentro pela mesma razao que a
   //--- linha acima: e desta funcao que o pulso desarma a confirmacao.
   if(EditingNow()) return false;
   if(m_profSel<0 || m_profSel>=m_profCount) return false;
   if(m_profSel==ActiveProfileIndex()) return false;
   if(ProfileIsDefault(m_profSel)) return false;
   if(m_selRuntimeLocked || m_selProfileLocked) return false;
   return AccCanAdminProfile();
  }

//--- ⚠ O rotulo nomeia a ACAO, sempre. Ele devolvia "BLOQUEADO" com o runtime
//--- travado — um motivo no lugar da acao —, e ali o usuario perdia a
//--- referencia de qual botao liga o EA justamente quando precisava dela.
//--- Motivo agora vai para a faixa, que tem espaco para dizer o que fazer.
string StartBtnText(void)
  { return m_hdr.label; }

//--- Ambar ao parar, verde ao iniciar: a cor acompanha o peso da acao.
uint StartBtnColor(void) { return m_snap.started ? m_t.warn : m_t.good; }

uint RunStateDim(void)
  { return SemDim(m_hdr.badgeSem); }

void DrawHeader(void)
  {
   string sym=m_snap.symbol;
   Txt(FCV_PAD,52,sym,m_t.fg,FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int sw=TxtW(sym,FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI);
   //--- Timeframe DO GRAFICO, lido do proprio grafico. Nao e o mesmo que
   //--- snapshot.timeframe: aquele e o resumo dos TFs de cada estrategia
   //--- ligada ("MA M1/M5 | RSI M15") e vive no Status, num bloco largo.
   //--- A caixa acompanha o texto: "MN1" nao cabe na largura de "M1".
   string chartTF=ShortTF((ENUM_TIMEFRAMES)ChartPeriod(m_chart));
   int tfw=TxtW(chartTF,FCV_FONT_MONO,FCV_FS_SM,FCV_FW_NORMAL)+20;
   RoundFrame(FCV_PAD+sw+9,44,FCV_PAD+sw+9+tfw,61,FCV_RADIUS_SM,m_t.line,m_t.inset,m_t.ground);
   Txt(FCV_PAD+sw+9+tfw/2,52,chartTF,m_t.muted,FCV_FONT_MONO,FCV_FS_SM,FCV_FW_NORMAL,TA_CENTER|TA_VCENTER);

   string st=RunStateText();
   uint stClr=RunStateColor();
   int pw=TxtW(st,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD)+30;
   RoundRect(FCV_PANEL_W-FCV_PAD-pw,43,FCV_PANEL_W-FCV_PAD,63,FCV_RADIUS_PILL,RunStateDim(),m_t.ground);
   Disc(FCV_PANEL_W-FCV_PAD-pw+12,53,3,stClr);
   Txt(FCV_PANEL_W-FCV_PAD-pw+21,53,st,stClr,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD,TA_LEFT|TA_VCENTER);

   Txt(FCV_PAD,76,"Perfil",m_t.faint,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   int lw=TxtW("Perfil",FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL);
   string prof=m_snap.activeProfileName;
   Txt(FCV_PAD+lw+8,76,prof,m_t.accs,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int vw=TxtW(prof,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI);
   int tailX=FCV_PAD+lw+vw+16;
   //--- Tres estados disputam a mesma linha, do mais grave para o menos:
   //--- arquivo ausente, arquivo desatualizado por falha de gravacao, e
   //--- alteracao ainda nao gravada. Os dois primeiros sao vermelhos porque
   //--- descrevem um perfil que nao existe em disco como o usuario acredita.
   if(m_snap.activeProfileFileMissing)
      Txt(tailX,76,"· arquivo do perfil nao encontrado",m_t.bad,
          FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   else if(m_notSaved)
      Txt(tailX,76,"· nao gravado no disco",m_t.bad,
          FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   else if(HasPending())
      Txt(tailX,76,"· alteracoes nao salvas",m_t.faint,
          FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);

   //--- Cada acao com a propria cor, como no painel 1.058: verde para iniciar,
   //--- azul para gravar, ambar para descartar. A cor identifica a acao; o que
   //--- diz se ela cabe agora e estar habilitada ou nao.
   //---
   //--- SALVAR e CANCELAR so existem havendo pendencia: sem alteracao nao ha o
   //--- que gravar nem o que descartar, e botao que nao tem efeito nao deve
   //--- aceitar clique.
   //---
   //--- Durante a criacao de um perfil os tres ficam bloqueados. SALVAR aqui
   //--- grava no perfil ATIVO, e isso nao faz sentido no meio da criacao de
   //--- outro. Bloqueados, eles sinalizam o modo sem precisar de aviso escrito.
   bool headerLive=(m_profEdit==FCV_PROF_VIEW);
   int bw2=(FCV_PANEL_W-2*FCV_PAD-16)/3, bx=FCV_PAD, by=94, bh=29;
   //--- Bloqueado pelo runtime, o botao nao aceita clique: o rotulo ja diz que
   //--- nao ha acao disponivel, e deixa-lo clicavel prometeria o contrario.
   //--- Uma condicao so, vinda do resolvedor. O `headerLive && (...)` que estava
   //--- aqui era a segunda metade de um predicado partido: com o formulario de
   //--- perfil aberto o botao apagava sem que nada soubesse explicar por que.
   PutButton(bx,by,bw2,bh,StartBtnText(), true, StartBtnColor(), m_t.onGood,
             FCV_BTN_START,m_hdr.enabled);
   bx+=bw2+8;
   PutButton(bx,by,bw2,bh,"SALVAR",  true, m_t.acc,  m_t.onAcc,
             //--- Perfil cujo arquivo sumiu pode ser regravado mesmo sem
             //--- pendencia: salvar recria o arquivo com a configuracao em uso.
             //--- ConfigInputsValid entra aqui pela mesma razao que no INICIAR,
             //--- e este e o caso GRAVE: sem ele, a Etapa 2c teria aberto um
             //--- caminho para gravar configuracao invalida NO PERFIL. E o
             //--- ponto que o plano marca como o unico em que fechar a 2c
             //--- sozinha pioraria o sistema.
             //--- `m_notSaved` acende o SALVAR sem pendencia pelo mesmo motivo
             //--- que o arquivo ausente: a alteracao ja esta valendo, mas o
             //--- disco nao a tem. Sem isto o painel anunciava "PERFIL NAO
             //--- GRAVADO" com os tres botoes apagados — um beco.
             //--- E NUNCA com uma criacao falhada pendente: ali este botao
             //--- gravaria no perfil ATIVO a configuracao do perfil que se
             //--- tentou criar. O `headerLive` ja cobre isso enquanto o
             //--- formulario esta aberto; esta segunda guarda existe porque a
             //--- condicao que importa e o estado, nao a tela que o mostra.
             FCV_BTN_SAVECFG,headerLive && !m_createFailed &&
                             AccActiveProfileEditable() && ConfigInputsValid() &&
                             (HasPending() || EditingNow() ||
                              m_snap.activeProfileFileMissing || m_notSaved));
   bx+=bw2+8;
   PutButton(bx,by,bw2,bh,"CANCELAR",true, m_t.warn, m_t.onAcc,
             FCV_BTN_CANCELCFG,headerLive && AccRuntimeEditable() &&
                               (HasPending() || EditingNow()));

   //+---------------------------------------------------------------+
   //| Faixa de motivo: por que a acao do cabecalho nao esta          |
   //| disponivel, visivel em QUALQUER aba.                            |
   //|                                                                |
   //| Era o buraco que o usuario encontrou: INICIAR apagado, nenhuma |
   //| palavra na tela, e a explicacao existindo so dentro do Status. |
   //| A 1.058 nunca teve esse buraco — ela mantem um rotulo unico e   |
   //| compartilhado no cabecalho, alimentado por uma escada de        |
   //| precedencia (ApplySharedParentStatus, UIPanelTabStatus.mqh). A  |
   //| 2.0 perdeu isso na migracao; esta faixa e a paridade de volta.  |
   //|                                                                |
   //| Altura FIXA, reservada sempre: uma faixa que aparece e some     |
   //| moveria ContentTop() e faria o conteudo saltar a cada campo que |
   //| entra e sai de invalido — o mesmo mecanismo que produziu o bug  |
   //| de rolagem da caixa de aviso. Perder 16 unidades estaveis e     |
   //| melhor que um layout que pula.                                  |
   //+---------------------------------------------------------------+
   if(StringLen(m_hdr.band)>0)
     {
      uint bandClr=SemColor(m_hdr.bandSem);
      //--- Marca de 2 px a esquerda, como no aviso do rodape: e o mesmo tipo de
      //--- informacao, e repetir o sinal ensina a le-lo.
      Rect(FCV_PAD,FCV_BAND_Y-6,FCV_PAD+1,FCV_BAND_Y+6,bandClr);
      //--- ⚠ MEDIDO antes de escrever. Os textos que o painel compoe cabem, mas
      //--- os que vem do motor nao: o bloqueio por troca de ativo do grafico
      //--- passa de 130 caracteres para as ~556 unidades desta linha, e o
      //--- CCanvas escreve alem da borda sem avisar. O que sumiria e o fim da
      //--- frase — onde mora a instrucao. Encurtado, a parte acionavel (que nos
      //--- textos do motor vem primeiro) sobrevive, e o texto integral continua
      //--- na aba Status, para onde o marcador ambar aponta.
      int bandX=FCV_PAD+8;
      string band=FitText(m_hdr.band,(FCV_PANEL_W-FCV_PAD)-bandX,
                          FCV_FONT_UI,FCV_FS_CAP,FCV_FW_SEMI);
      Txt(bandX,FCV_BAND_Y,band,bandClr,
          FCV_FONT_UI,FCV_FS_CAP,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
     }
  }

//+------------------------------------------------------------------+
//| Aviso que cresce com o texto: a caixa e dimensionada pelo texto   |
//| medido, nao por um numero fixo de linhas.                         |
//+------------------------------------------------------------------+
void AlertBottom(const int x1,const int x2,const int bottomY,const string title,
                 const string body,const uint accentClr,const uint bgClr,const uint textClr)
  {
   int textX=x1+24, maxW=(x2-14)-textX, lineH=15, titleH=16, gap=4, padV=14;
   int realLines,boxLines;
   AlertLines(body,realLines,boxLines);
   int h=titleH+gap+boxLines*lineH+2*padV;
   int y=bottomY-h;
   //--- a altura ja foi publicada por MeasureAlert antes do conteudo
   RoundRect(x1,y,x2,y+h,8,bgClr,m_t.surface);
   Rect(x1+12,y+padV,x1+14,y+h-padV,accentClr);
   //--- Texto CENTRADO na caixa quando ela e maior que o conteudo. Encostado no
   //--- topo, um aviso de uma linha deixaria um vao vazio embaixo — a caixa
   //--- pareceria quebrada, e nao reservada.
   int blockH=titleH+gap+realLines*lineH;
   int top=y+(h-blockH)/2;
   Txt(textX,top+titleH/2,title,accentClr,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD,TA_LEFT|TA_VCENTER);
   WrapText(textX,top+titleH+gap+lineH/2,maxW,lineH,body,textClr,FCV_FS_SM,true);
  }

//+------------------------------------------------------------------+
//| Trilho do terceiro nivel: 136 px, so onde existe. Sete itens numa |
//| faixa horizontal ficariam abreviados; no trilho cabem por extenso.|
//+------------------------------------------------------------------+
void DrawRail(const int x,const int y,const int h,string &items[],const int count,
              const int active,const int cfg)
  {
   m_railCount=count;
   Rect(x+FCV_RAIL_W-1,y,x+FCV_RAIL_W-1,y+h,m_t.soft);
   for(int i=0;i<count;++i)
     {
      int ry=y+i*(FCV_RAIL_ROW+2);
      m_railY[i]=ry;
      bool on=(i==active), err=RailHasError(cfg,i);
      if(on) RoundRect(x,ry,x+FCV_RAIL_W-10,ry+FCV_RAIL_ROW,5, err?m_t.bdim:m_t.accd, m_t.ground);
      Txt(x+10,ry+FCV_RAIL_ROW/2,items[i],
          err?m_t.bad:(on?m_t.accs:m_t.muted),FCV_FONT_UI,FCV_FS_BODY,on?FCV_FW_SEMI:FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
      if(err) Disc(x+FCV_RAIL_W-19,ry+FCV_RAIL_ROW/2,3,m_t.bad);
     }
  }

//+------------------------------------------------------------------+
void DrawScrollbar(void)
  {
   int top=ContentTop(), bottom=ContentBottom(), viewH=bottom-top;
   m_trackH=0;
   if(m_contentH<=viewH) return;
   int maxS=m_contentH-viewH;
   m_trackTop=top+FCV_SB_ARROW;
   int tBot=bottom-FCV_SB_ARROW;
   m_trackH=tBot-m_trackTop;
   RoundRect(FCV_SB_X,m_trackTop,FCV_SB_X+FCV_SB_W,tBot,3,m_t.soft,m_t.surface);
   m_thumbH=(int)MathMax(28,(double)m_trackH*viewH/m_contentH);
   m_thumbY=m_trackTop+(int)((double)(m_trackH-m_thumbH)*m_scroll/maxS);
   RoundRect(FCV_SB_X,m_thumbY,FCV_SB_X+FCV_SB_W,m_thumbY+m_thumbH,3,m_t.faint,m_t.soft);
   //--- Mesmas setas dos combos, pelo mesmo desenho: eram 4 linhas somadas em
   //--- unidade logica e sofriam do mesmo defeito — umas grossas, outras com
   //--- fresta, conforme a altura em que a barra comecava.
   int cx=FCV_SB_X+FCV_SB_W/2;
   Chevron(cx,top+8,     false,(m_scroll>0)    ? m_t.acc : m_t.soft);
   Chevron(cx,bottom-12, true, (m_scroll<maxS) ? m_t.acc : m_t.soft);
  }
