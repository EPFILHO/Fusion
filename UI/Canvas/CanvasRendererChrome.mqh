//+------------------------------------------------------------------+
//| CanvasRendererChrome.mqh                                          |
//| Fragmento do corpo de CFusionCanvasRenderer — barra de titulo,    |
//| cabecalho, ficharios, trilho, rolagem e aviso.                    |
//+------------------------------------------------------------------+

//--- Nao ha erro conhecido enquanto a validacao nao existir (Etapa 2d).
//---
//--- Ate a Etapa 2b isto era `cfg==1 && idx==3`: um erro FIXO em
//--- Protecao > Noticias, da epoca dos dados inventados, que servia para exibir
//--- a cadeia de vermelho subindo do trilho ate a aba. Com a tela lendo o
//--- rascunho real, ele passou a acusar erro em horarios corretos — e mandava
//--- corrigir o que ja estava certo.
//---
//--- A cadeia em si (trilho -> subaba -> aba) continua montada e e o que a 2d
//--- vai alimentar; so a resposta e que hoje e "nao sei de nenhum erro". Mesma
//--- decisao do ScreenAlert, pelo mesmo motivo: melhor calado que errado.
bool RailHasError(const int cfg,const int idx)
  { return false; }

bool CfgHasError(const int cfg)
  {
   if(cfg==1) { for(int i=0;i<FCV_RAIL_MAX;++i) if(RailHasError(1,i)) return true; }
   return false;
  }

//--- O erro sobe ate a aba que contem a subaba invalida. Com Risco e Protecao
//--- agora em Gestao, e Gestao que fica vermelha — e isso informa mais do que
//--- "Config", que nao dizia de que assunto era o problema.
bool TabHasError(const int tab)
  {
   if(tab!=FCV_TAB_GESTAO) return false;
   for(int c=0;c<Level2Count(FCV_TAB_GESTAO);++c) if(CfgHasError(c)) return true;
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
   bool activeErr = markErrors && ((cfgForErr<0) ? TabHasError(active) : CfgHasError(active));
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
      bool err=markErrors && ((cfgForErr<0) ? TabHasError(i) : CfgHasError(i));

      if(on)
        {
         //--- A aba cobre o trecho da linha sob ela e para exatamente nela: se
         //--- passar, sobra um degrau abaixo do fichario. Cantos de cima
         //--- arredondados no mesmo raio dos botoes do cabecalho, para o painel
         //--- ter um raio so; os de baixo retos, encostando na linha.
         //--- Borda de 1 px, igual a linha, e fundo ate exatamente nela: a aba
         //--- cobre o trecho da linha sob si sem passar por baixo.
         uint fill = err ? m_t.bdim : surfaceBelow;
         RoundRect(tx, y+2, tx+w, y+h-2, FCV_RADIUS_CTRL,
                   err ? m_t.bad : m_t.acc, m_t.ground, FCV_CORNER_TOP);
         RoundRect(tx+1, y+3, tx+w-1, y+h-2, FCV_RADIUS_CTRL-1,
                   fill, err ? m_t.bad : m_t.acc, FCV_CORNER_TOP);
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
   for(int dy=-tr;dy<=tr;++dy)
      for(int dx=-tr;dx<=tr;++dx)
        {
         if(dx*dx+dy*dy>tr*tr) continue;
         Rect(tx+dx,ty+dy,tx+dx,ty+dy,(dx<0)?FCV_OPAQUE(20,20,24):FCV_OPAQUE(248,248,251));
        }
   Ring(tx,ty,tr,m_t.muted);

   //--- Reajustar altura ao grafico. Duas setas divergentes liam como "X" de
   //--- fechar; num painel que opera dinheiro, sugerir fechamento por engano e
   //--- inaceitavel. Retangulo e o simbolo de maximizar que todo mundo conhece.
   //--- Escondido enquanto minimizado: la ele nao teria o que reajustar, e
   //--- controle visivel que nao faz nada e pior do que controle ausente.
   if(!m_minimized)
     {
      int rx=FCV_PANEL_W-50;
      Frame(rx-6,11,rx+6,21,m_t.muted);
      Rect(rx-6,11,rx+6,12,m_t.muted);
     }

   int mx=FCV_PANEL_W-24;
   if(m_minimized)
     {
      Rect(mx-6,13,mx+6,14,m_t.muted);
      Rect(mx-6,13,mx-5,19,m_t.muted);
      Rect(mx+5,13,mx+6,19,m_t.muted);
      Rect(mx-6,18,mx+6,19,m_t.muted);
     }
   else Rect(mx-6,16,mx+6,17,m_t.muted);
  }

void Btn(const int x,const int y,const int w,const int h,const string label,
         const bool filled,const uint fillClr,const uint onFill)
  {
   if(filled)
     {
      RoundRect(x,y,x+w,y+h,FCV_RADIUS_CTRL,fillClr,m_t.ground);
      Txt(x+w/2,y+h/2,label,onFill,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.line,m_t.ground,m_t.ground);
      Txt(x+w/2,y+h/2,label,m_t.muted,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_BOLD,TA_CENTER|TA_VCENTER);
     }
  }

//--- Botao que publica a propria caixa e o comando que dispara. Bloqueado, ele
//--- e desenhado apagado e NAO publica caixa: nao basta parecer inativo.
void PutButton(const int x,const int y,const int w,const int h,const string label,
               const bool filled,const uint fillClr,const uint onFill,
               const int id,const bool enabled)
  {
   if(!enabled)
     {
      RoundFrame(x,y,x+w,y+h,FCV_RADIUS_CTRL,m_t.disabled,m_t.ground,m_t.ground);
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
bool FieldsLocked(void)
  { return (m_locked || !AccRuntimeEditable()); }

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

//--- Iniciar com alteracao pendente rodaria a configuracao COMPROMETIDA
//--- enquanto a tela mostra outra. Por isso a pendencia bloqueia o INICIAR.
bool AccCanStart(void)
  { return (AccRuntimeArmable() && !AccPeerLock() && !HasPending() && !m_snap.tradePermissionBlocked); }

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
  { return (AccRuntimeEditable() && !AccPeerLock() && !HasPending()); }

//--- Criar e duplicar nao tocam no perfil ativo, mas ainda exigem EA parado.
bool AccCanCreateProfile(void)
  { return (AccRuntimeEditable() && !HasPending()); }

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
   //--- Perfil sem arquivo e mais grave que pendencia de gravacao, entao vence
   //--- a linha. Os dois avisos disputam o mesmo espaco.
   if(m_snap.activeProfileFileMissing)
      Txt(tailX,76,"· arquivo do perfil nao encontrado",m_t.bad,
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
             FCV_BTN_SAVECFG,headerLive && AccRuntimeEditable() && !AccPeerLock() &&
                             (HasPending() || EditingNow() || m_snap.activeProfileFileMissing));
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
   int lines=WrapText(textX,0,maxW,lineH,body,textClr,FCV_FS_SM,false);
   int h=titleH+gap+lines*lineH+2*padV;
   int y=bottomY-h;
   //--- a altura ja foi publicada por MeasureAlert antes do conteudo
   RoundRect(x1,y,x2,y+h,8,bgClr,m_t.surface);
   Rect(x1+12,y+padV,x1+14,y+h-padV,accentClr);
   Txt(textX,y+padV+titleH/2,title,accentClr,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD,TA_LEFT|TA_VCENTER);
   WrapText(textX,y+padV+titleH+gap+lineH/2,maxW,lineH,body,textClr,FCV_FS_SM,true);
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
   int cx=FCV_SB_X+FCV_SB_W/2;
   for(int i=0;i<4;++i)
     {
      uint cu=(m_scroll>0)?m_t.acc:m_t.soft;
      uint cd=(m_scroll<maxS)?m_t.acc:m_t.soft;
      Rect(cx-3+i,top+8-i,cx+3-i,top+8-i,cu);
      Rect(cx-3+i,bottom-12+i,cx+3-i,bottom-12+i,cd);
     }
  }
