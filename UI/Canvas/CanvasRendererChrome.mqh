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
      int rx=FCV_PANEL_W-50;
      Rect(rx,11,rx,21,m_t.muted);            // haste
      Chevron(rx,14,false,m_t.muted);         // ponta para cima
      Chevron(rx,18,true, m_t.muted);         // ponta para baixo
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

//--- Estado operacional em tres nomes, os mesmos da 1.058 (Pages/StatusPage).
//--- Bloqueado vence rodando: se o EA esta impedido de operar, dizer que ele
//--- esta rodando seria a pior informacao possivel nesta linha.
string RunStateText(void)
  {
   if(m_snap.runtimeBlocked) return "BLOQUEADO";
   return m_snap.started ? "RODANDO" : "PAUSADO";
  }

uint RunStateColor(void)
  {
   if(m_snap.runtimeBlocked) return m_t.bad;
   return m_snap.started ? m_t.good : m_t.warn;
  }

//--- O botao diz o que o clique FAZ, nao o que o estado E — com uma excecao
//--- deliberada, herdada da 1.058: com posicao aberta ele mostra "OPERANDO".
//--- Ali o estado importa mais que a acao, porque pausar com posicao aberta
//--- nao fecha nada, so impede novas entradas; anunciar "PAUSAR" faria o
//--- usuario achar que o clique encerra a operacao em curso.
//+------------------------------------------------------------------+
//| Camada de acesso — quem pode o que, e quando.                     |
//| Portada de UI/UIPanelAccessState.mqh, mesmos predicados.          |
//|                                                                   |
//| Pendente da Etapa 2d: configInputsValid, que so existe quando a   |
//| validacao entrar. Ate la vale true — isto AFROUXA a regra (deixa  |
//| iniciar com campo invalido), nunca a aperta.                      |
//+------------------------------------------------------------------+
//--- Campos de configuracao so aceitam edicao quando o EA permite. Era a
//--- lacuna registrada para a 2d: m_locked existia mas so respondia a tecla de
//--- simulacao, nunca ao estado do EA — os campos seguiam editaveis operando.
//--- A tecla B continua valendo como forcador manual, para exercitar o estado.
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
   if(m_locked) return true;
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
//--- Vale SO para esses dois botoes. Nao vale para o INICIAR, que bloquearia
//--- uma acao real so porque ha um cursor num campo, nem para o aviso
//--- "alteracoes nao salvas", que afirmaria uma mudanca que pode nao existir.
bool EditingNow(void) { return EditHasFocus(); }

//--- Perfil preso a outro grafico.
bool AccPeerLock(void)
  { return (HasText(m_snap.startBlockedReason) || HasText(m_snap.activeProfileBlockedReason)); }

//--- Editar configuracao exige EA parado, sem posicao e sem bloqueio.
bool AccRuntimeEditable(void)
  { return (!m_snap.started && !m_snap.hasPosition && !m_snap.runtimeBlocked); }

//--- Rearmar NAO depende de posicao aberta. A 1.058 e explicita: com a posicao
//--- em curso o Fusion ja a gerencia, e o clique apenas autoriza novas entradas
//--- quando ela fechar.
bool AccRuntimeArmable(void)
  { return (!m_snap.started && !m_snap.runtimeBlocked); }

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

//--- Iniciar com alteracao pendente rodaria a configuracao COMPROMETIDA
//--- enquanto a tela mostra outra. Por isso a pendencia bloqueia o INICIAR.
//--- Magic do perfil ativo repetido em disco impede INICIAR. E o Magic que faz
//--- o EA reconhecer as proprias ordens: comecar com ele ambiguo e comecar sem
//--- saber quais ordens sao suas. Bloqueio proprio da 2.0 — a 1.058 so recusa
//--- CRIAR um perfil com Magic tomado, e nao ve o estado gerado por arquivo
//--- copiado por fora.
//--- E, desde a Etapa 2d, configuracao valida. Era o `true` provisorio anotado
//--- aqui: ele AFROUXAVA a regra, deixando iniciar com campo invalido.
bool AccCanStart(void)
  {
   return (AccRuntimeArmable() && !AccPeerLock() && !HasPending() &&
           ConfigInputsValid() &&
           !m_snap.tradePermissionBlocked && !ActiveMagicConflicts());
  }

//--- Pausar nao depende de pendencia: parar de operar nunca deve ficar refem
//--- de um formulario pela metade. Com posicao aberta, porem, nao ha o que
//--- pausar — o rotulo vira OPERANDO e o botao nao aceita clique.
bool AccCanPause(void)
  { return (m_snap.started && !m_snap.hasPosition); }

//--- Carregar perfil com o EA RODANDO trocaria os parametros sob a operacao —
//--- inaceitavel mesmo sem posicao aberta. Por isso exige EA parado.
//--- A excecao da 1.058 e deliberada: com o perfil preso por outro grafico,
//--- carregar continua liberado, porque escolher outro perfil e justamente a
//--- saida para desfazer esse bloqueio. Carregar nao libera a operacao.
bool AccCanLoadProfile(void)
  {
   if(m_snap.started) return false;
   if(AccPeerLock())  return true;
   return (!m_snap.hasPosition && !HasPending());
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
   if(m_profSel<0 || m_profSel>=m_profCount) return false;
   if(m_profSel==ActiveProfileIndex()) return false;
   if(ProfileIsDefault(m_profSel)) return false;
   if(m_selRuntimeLocked || m_selProfileLocked) return false;
   return AccCanAdminProfile();
  }

string StartBtnText(void)
  {
   if(m_snap.runtimeBlocked) return "BLOQUEADO";
   if(m_snap.started)        return m_snap.hasPosition ? "OPERANDO" : "PAUSAR";
   return "INICIAR";
  }

//--- Ambar ao parar, verde ao iniciar: a cor acompanha o peso da acao.
uint StartBtnColor(void) { return m_snap.started ? m_t.warn : m_t.good; }

uint RunStateDim(void)
  {
   if(m_snap.runtimeBlocked) return m_t.bdim;
   return m_snap.started ? m_t.gdim : m_t.wdim;
  }

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
   PutButton(bx,by,bw2,bh,StartBtnText(), true, StartBtnColor(), m_t.onGood,
             FCV_BTN_START,headerLive && (m_snap.started ? AccCanPause() : AccCanStart()));
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
             FCV_BTN_SAVECFG,headerLive && AccActiveProfileEditable() && ConfigInputsValid() &&
                             (HasPending() || EditingNow() ||
                              m_snap.activeProfileFileMissing || m_notSaved));
   bx+=bw2+8;
   PutButton(bx,by,bw2,bh,"CANCELAR",true, m_t.warn, m_t.onAcc,
             FCV_BTN_CANCELCFG,headerLive && AccRuntimeEditable() &&
                               (HasPending() || EditingNow()));
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
