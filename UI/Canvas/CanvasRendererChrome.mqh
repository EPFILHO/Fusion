//+------------------------------------------------------------------+
//| CanvasRendererChrome.mqh                                          |
//| Fragmento do corpo de CFusionCanvasRenderer — barra de titulo,    |
//| cabecalho, ficharios, trilho, rolagem e aviso.                    |
//+------------------------------------------------------------------+

//--- Estado de erro fake da Fase 1: Protecao > Noticias esta invalido, e o
//--- vermelho sobe a cadeia inteira ate a aba de topo.
bool RailHasError(const int cfg,const int idx)
  { return (cfg==1 && idx==3); }

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

   //--- linha do fichario, largura inteira
   Rect(0, y+h-2, FCV_PANEL_W-1, y+h-1, edge);

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
         uint fill = err ? m_t.bdim : surfaceBelow;
         RoundRect(tx, y+2, tx+w, y+h-1, FCV_RADIUS_CTRL,
                   err ? m_t.bad : m_t.acc, m_t.ground, FCV_CORNER_TOP);
         RoundRect(tx+2, y+4, tx+w-2, y+h-1, FCV_RADIUS_CTRL-1,
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

void DrawHeader(void)
  {
   Txt(FCV_PAD,52,"BTCUSD",m_t.fg,FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   int sw=TxtW("BTCUSD",FCV_FONT_UI,FCV_FS_LG,FCV_FW_SEMI);
   RoundFrame(FCV_PAD+sw+9,44,FCV_PAD+sw+41,61,FCV_RADIUS_SM,m_t.line,m_t.inset,m_t.ground);
   Txt(FCV_PAD+sw+25,52,"M1",m_t.muted,FCV_FONT_MONO,FCV_FS_SM,FCV_FW_NORMAL,TA_CENTER|TA_VCENTER);

   string st="PAUSADO";
   int pw=TxtW(st,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD)+30;
   RoundRect(FCV_PANEL_W-FCV_PAD-pw,43,FCV_PANEL_W-FCV_PAD,63,FCV_RADIUS_PILL,m_t.wdim,m_t.ground);
   Disc(FCV_PANEL_W-FCV_PAD-pw+12,53,3,m_t.warn);
   Txt(FCV_PANEL_W-FCV_PAD-pw+21,53,st,m_t.warn,FCV_FONT_UI,FCV_FS_SM,FCV_FW_BOLD,TA_LEFT|TA_VCENTER);

   Txt(FCV_PAD,76,"Perfil",m_t.faint,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
   int lw=TxtW("Perfil",FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL);
   Txt(FCV_PAD+lw+8,76,"BTCUSD",m_t.accs,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI,TA_LEFT|TA_VCENTER);
   if(m_dirty)
     {
      int vw=TxtW("BTCUSD",FCV_FONT_UI,FCV_FS_BODY,FCV_FW_SEMI);
      Txt(FCV_PAD+lw+vw+16,76,"· alteracoes nao salvas",m_t.faint,FCV_FONT_UI,FCV_FS_BODY,FCV_FW_NORMAL,TA_LEFT|TA_VCENTER);
     }

   //--- Um unico botao preenchido: ele indica o proximo passo. Com pendencias
   //--- e Salvar; sem elas, Iniciar. A cor orienta em vez de decorar.
   //---
   //--- Durante a criacao de um perfil os tres ficam bloqueados. Nao e so para
   //--- desfazer a ambiguidade de ter dois "salvar" na tela: SALVAR aqui grava
   //--- alteracoes no perfil ATIVO, e essa acao nao faz sentido no meio da
   //--- criacao de outro. Bloqueados, eles ainda sinalizam sozinhos que a tela
   //--- esta num modo, sem precisar de aviso escrito.
   bool headerLive=(m_profEdit==FCV_PROF_VIEW);
   int bw2=(FCV_PANEL_W-2*FCV_PAD-16)/3, bx=FCV_PAD, by=94, bh=29;
   PutButton(bx,by,bw2,bh,"INICIAR", !m_dirty, m_t.good, m_t.onGood,
             FCV_BTN_START,headerLive);
   bx+=bw2+8;
   PutButton(bx,by,bw2,bh,"SALVAR",   m_dirty, m_t.acc,  m_t.onAcc,
             FCV_BTN_SAVECFG,headerLive);
   bx+=bw2+8;
   PutButton(bx,by,bw2,bh,"CANCELAR", false,   m_t.acc,  m_t.onAcc,
             FCV_BTN_CANCELCFG,headerLive);
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
