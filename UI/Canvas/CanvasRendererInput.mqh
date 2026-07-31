//+------------------------------------------------------------------+
//| CanvasRendererInput.mqh                                           |
//| Fragmento do corpo de CFusionCanvasRenderer — mouse, teclado,     |
//| arrasto do painel e da rolagem.                                   |
//|                                                                   |
//| Todo alvo e testado contra a caixa publicada no desenho, e so     |
//| aceito se estiver dentro da area visivel: a caixa acompanha a     |
//| rolagem, mas o que rolou para fora nao pode continuar clicavel.   |
//+------------------------------------------------------------------+

//--- O que o CAppDialog dava de graca: com o cursor sobre o painel, o
//--- grafico nao pode rolar no lugar dele.
void SetChartScroll(const bool on) { ChartSetInteger(m_chart,CHART_MOUSE_SCROLL,on); }

bool InsidePanel(const int cx,const int cy)
  {
   int h=m_minimized?FCV_TITLEBAR_H:m_ph;
   return (cx>=m_px && cx<m_px+S(FCV_PANEL_W) && cy>=m_py && cy<m_py+S(h));
  }

bool InContentView(const int ly,const int hgt)
  { return (ly>=ContentTop() && ly+hgt<=ContentBottom()); }

void GoTo(const int tab,const int sub,const int rail)
  {
   if(tab>=0)  m_tab=tab;
   if(sub>=0)  m_sub[m_tab]=sub;
   //--- sair da aba abandona a criacao em andamento; voltar mostra a lista
   m_profEdit=FCV_PROF_VIEW;
   if(rail>=0 && HasRail()) m_railSel[Sub()]=rail;
   m_scroll=0;
   m_comboOpen=-1;
   m_colorOpen=-1;
   m_stress=false;
   Render();
  }

bool HandleColorClick(const int lx,const int ly)
  {
   if(m_colorOpen>=0 && m_colorOpen<m_colorCount)
     {
      int x,y,w,h;
      ColorPopupBox(m_colorOpen,x,y,w,h);
      if(lx>=x && lx<x+w && ly>=y && ly<y+h)
        {
         int c=(lx-x-5)/26, r=(ly-y-5)/26;
         int idx=r*FCV_SWATCH_COLS+c;
         if(c>=0 && c<FCV_SWATCH_COLS && idx>=0 && idx<FCV_SWATCH_COUNT)
           { m_stColor[m_colorSlot[m_colorOpen]]=idx; m_dirty=true; }
        }
      m_colorOpen=-1; Render(); return true;
     }
   for(int i=0;i<m_colorCount;++i)
      if(lx>=m_colorX[i] && lx<m_colorX[i]+m_colorW[i] &&
         ly>=m_colorY[i] && ly<m_colorY[i]+22 && InContentView(m_colorY[i],22))
        { m_colorOpen=i; m_comboOpen=-1; Render(); return true; }
   return false;
  }

//--- Combos que mudam a aparencia agem no ato da escolha, sem passar por
//--- SALVAR: sao preferencia de exibicao, nao configuracao do perfil.
void ApplyComboSideEffect(const int kind,const int value)
  {
   if(kind==FCV_COMBO_PALETTE)
     {
      m_palette=(ENUM_FUSION_CANVAS_PALETTE)value;
      ResolveTheme();
      SaveAppearance();
      return;
     }
   if(kind==FCV_COMBO_THEMEMODE)
     {
      m_themeMode=(ENUM_FUSION_CANVAS_THEME)value;
      m_userTheme=(m_themeMode!=FUSION_CANVAS_THEME_AUTO);
      ResolveTheme();
      SaveAppearance();
      return;
     }
   if(kind==FCV_COMBO_SCALE)
     {
      //--- A altura e guardada em unidade logica, entao mudar a escala nao a
      //--- altera — mas o painel pode passar a nao caber, e ai ele encolhe pelo
      //--- mesmo caminho do reajuste manual.
      m_scale=FCV_SCALE_MIN+value*FCV_SCALE_STEP;
      int fit=DecidePanelHeight();
      if(fit<m_ph) m_ph=fit;
      m_scroll=0;
      SaveAppearance();
      return;
     }
  }

bool HandleComboClick(const int lx,const int ly)
  {
   if(m_comboOpen>=0 && m_comboOpen<m_comboCount)
     {
      int x,y,w,h,n;
      ComboPopupBox(m_comboOpen,x,y,w,h,n);
      if(lx>=x && lx<x+w && ly>=y && ly<y+h)
        {
         int idx=m_comboScroll+(ly-y-4)/FCV_COMBO_ITEM_H;
         if(idx>=0 && idx<n)
           {
            int kind=m_comboKind[m_comboOpen];
            m_stCombo[m_comboSlot[m_comboOpen]]=idx;
            if(kind==FCV_COMBO_PALETTE || kind==FCV_COMBO_THEMEMODE || kind==FCV_COMBO_SCALE)
               ApplyComboSideEffect(kind,idx);
            else
               m_dirty=true;
           }
        }
      m_comboOpen=-1; Render(); return true;
     }
   for(int i=0;i<m_comboCount;++i)
      if(lx>=m_comboX[i] && lx<m_comboX[i]+m_comboW[i] &&
         ly>=m_comboY[i] && ly<m_comboY[i]+FCV_EDIT_H && InContentView(m_comboY[i],FCV_EDIT_H))
        {
         m_comboOpen=i; m_colorOpen=-1;
         //--- abre mostrando o item selecionado, nao o topo da lista
         string items[];
         int n=ComboItems(m_comboKind[i],items);
         int sel=m_stCombo[m_comboSlot[i]];
         int maxS=ComboMaxScroll(n);
         m_comboScroll=sel-FCV_COMBO_WINDOW/2;
         if(m_comboScroll>maxS) m_comboScroll=maxS;
         if(m_comboScroll<0)    m_comboScroll=0;
         Render(); return true;
        }
   return false;
  }

//--- Roda do mouse sobre um popup aberto rola a lista, nao o conteudo atras.
bool HandleComboWheel(const int lx,const int ly,const int step)
  {
   if(m_comboOpen<0 || m_comboOpen>=m_comboCount) return false;
   int x,y,w,h,n;
   ComboPopupBox(m_comboOpen,x,y,w,h,n);
   if(lx<x || lx>=x+w || ly<y || ly>=y+h) return false;
   int maxS=ComboMaxScroll(n);
   int ns=m_comboScroll+step;
   if(ns>maxS) ns=maxS;
   if(ns<0)    ns=0;
   if(ns==m_comboScroll) return true;
   m_comboScroll=ns;
   Render();
   return true;
  }

//--- Botoes: a caixa vem do desenho, e so existe se o botao estava habilitado.
//--- Na Fase 1 os comandos so movem estado de tela; na Fase 2 viram os
//--- comandos que o EA ja sabe executar.
bool HandleButtonClick(const int lx,const int ly)
  {
   for(int i=0;i<m_btnCount;++i)
     {
      if(lx<m_btnX[i] || lx>=m_btnX[i]+m_btnW[i]) continue;
      if(ly<m_btnY[i] || ly>=m_btnY[i]+m_btnH[i]) continue;
      //--- Botao acima da area util e chrome (cabecalho) e nao rola; dentro
      //--- dela, so vale se ainda estiver visivel.
      if(m_btnY[i]>=ContentTop() && !InContentView(m_btnY[i],m_btnH[i])) continue;
      switch(m_btnId[i])
        {
         case FCV_BTN_NEW:    m_profEdit=FCV_PROF_NEW; break;
         case FCV_BTN_DUP:    m_profEdit=FCV_PROF_DUP; break;
         case FCV_BTN_SAVE:
         case FCV_BTN_CANCEL: m_profEdit=FCV_PROF_VIEW; break;
         case FCV_BTN_LOAD:   m_profSel=m_profSel;      break; // fake: nada muda
         case FCV_BTN_DEL:    Print("EXCLUIR (simulacao): pediria confirmacao."); break;
         //--- cabecalho: na Fase 1 so exercitam a regra do unico preenchido
         case FCV_BTN_START:
         case FCV_BTN_SAVECFG:
         case FCV_BTN_CANCELCFG: m_dirty=!m_dirty; break;
        }
      m_scroll=0;
      Render();
      return true;
     }
   return false;
  }

bool HandleToggleClick(const int lx,const int ly)
  {
   for(int t=0;t<m_toggleCount;++t)
      if(lx>=m_toggleX[t]-6 && lx<m_toggleX[t]+44 &&
         ly>=m_toggleY[t]-6 && ly<m_toggleY[t]+27 && InContentView(m_toggleY[t],21))
        {
         int slot=m_toggleSlot[t];
         m_stToggle[slot]=!m_stToggle[slot];
         m_dirty=true;
         Render();
         return true;
        }
   return false;
  }

//--- Setas, alcinha e trilho. A alcinha arrasta na direcao da barra; o trilho
//--- pagina. Sao gestos diferentes do arrasto do conteudo, que vai ao contrario.
bool HandleScrollbarClick(const int lx,const int ly)
  {
   if(m_trackH<=0) return false;
   int top=ContentTop(), bottom=ContentBottom();
   if(lx<FCV_SB_X-6 || lx>FCV_SB_X+FCV_SB_W+6) return false;

   if(ly>=top && ly<top+FCV_SB_ARROW)       { if(ScrollBy(-40)) Render(); return true; }
   if(ly<=bottom && ly>bottom-FCV_SB_ARROW) { if(ScrollBy( 40)) Render(); return true; }

   if(ly>=m_thumbY && ly<m_thumbY+m_thumbH)
     { m_barDrag=true; m_barDragY=ly; m_barDragBase=m_scroll; return true; }

   int page=(bottom-top);
   if(ly<m_thumbY)           { if(ScrollBy(-page)) Render(); return true; }
   if(ly>=m_thumbY+m_thumbH) { if(ScrollBy( page)) Render(); return true; }
   return true;
  }

void HandleBarDrag(const int ly)
  {
   int viewH=ContentBottom()-ContentTop();
   int maxS=m_contentH-viewH;
   int span=m_trackH-m_thumbH;
   if(maxS<=0 || span<=0) return;
   int target=m_barDragBase+(int)((double)(ly-m_barDragY)*maxS/span);
   if(ScrollBy(target-m_scroll)) Render();
  }

void HandlePress(const int cx,const int cy)
  {
   //--- Segunda fronteira de escala: o clique chega em pixels do grafico e daqui
   //--- para baixo tudo e unidade logica, igual as caixas publicadas no desenho.
   int lx=L(cx-m_px), ly=L(cy-m_py);

   if(ly<FCV_TITLEBAR_H)
     {
      if(lx>=FCV_PANEL_W-40) { m_minimized=!m_minimized; Render(); return; }
      //--- o alvo so existe quando o icone existe
      if(!m_minimized && lx>=FCV_PANEL_W-64 && lx<FCV_PANEL_W-40)
        {
         m_ph=DecidePanelHeight(); m_scroll=0; Render();
         Print("Altura reajustada ao grafico: ",m_ph," (unidade logica)");
         return;
        }
      if(lx>=FCV_PANEL_W-90 && lx<FCV_PANEL_W-64)
        {
         //--- o botao da barra alterna claro/escuro; a paleta continua a mesma
         m_userTheme=true;
         m_themeMode=m_dark ? FUSION_CANVAS_THEME_LIGHT : FUSION_CANVAS_THEME_DARK;
         m_stCombo[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_THEME)]=(int)m_themeMode;
         ResolveTheme();
         SaveAppearance();
         Render(); return;
        }
      //--- O arrasto do painel trabalha em pixels do grafico, nao em unidades
      //--- logicas: e a posicao do objeto que muda, nao o desenho dentro dele.
      m_dragging=true; m_dragDX=cx-m_px; m_dragDY=cy-m_py; return;
     }
   if(m_minimized) return;

   //--- Clique dentro de um campo marca o foco. Nao limpamos aqui: quem
   //--- encerra a edicao e o terminal, e ele avisa por ENDEDIT.
   NoteEditFocus(lx,ly);

   //--- popup aberto consome o clique antes de qualquer outro alvo
   if(HandleColorClick(lx,ly)) return;
   if(HandleComboClick(lx,ly)) return;

   //--- Todo botao, do cabecalho ou de conteudo, e resolvido pelo registro
   //--- publicado no desenho. Antes o cabecalho tinha a propria aritmetica de
   //--- retangulo aqui, repetindo a conta que o desenho ja fazia.
   if(HandleButtonClick(lx,ly)) return;

   if(ly>=FCV_HEADER_BOTTOM && ly<FCV_F1_BOTTOM)
     {
      for(int i=0;i<FCV_TAB_COUNT;++i)
         if(lx>=m_tabX[i] && lx<m_tabX[i]+m_tabW[i])
           { if(m_tab!=i) GoTo(i,-1,-1); return; }
      return;
     }

   if(HasLevel2(m_tab))
     {
      int f2y=F2Top();
      if(ly>=f2y && ly<f2y+FCV_F2_H)
        {
         for(int i=0;i<Level2Count(m_tab);++i)
            if(lx>=m_cfgX[i] && lx<m_cfgX[i]+m_cfgW[i])
              { if(Sub()!=i) GoTo(-1,i,-1); return; }
         return;
        }
     }

   if(HandleScrollbarClick(lx,ly)) return;

   if(HasRail() && lx<FCV_PAD+FCV_RAIL_W)
     {
      for(int i=0;i<m_railCount;++i)
         if(ly>=m_railY[i] && ly<m_railY[i]+FCV_RAIL_ROW)
           { if(RailIdx()!=i) GoTo(-1,-1,i); return; }
      return;
     }

   if(HandleToggleClick(lx,ly)) return;

   if(m_tab==FCV_TAB_PERFIS && m_profEdit==FCV_PROF_VIEW)
     {
      //--- durante a edicao a lista nao aceita clique: trocar de selecao no
      //--- meio de criar um perfil deixaria a tela contradizendo o cartao
      int y=ContentTop()-m_scroll;
      for(int i=0;i<6;++i)
         if(ly>=y+i*34 && ly<y+i*34+30 && lx<FCV_PANEL_W-FCV_PAD-135 &&
            InContentView(y+i*34,30))
           { if(m_profSel!=i) { m_profSel=i; Render(); } return; }
     }

   if(ly>=ContentTop() && ly<=ContentBottom() && lx<FCV_PANEL_W-16)
     { m_scrollDrag=true; m_scrollDragY=ly; m_scrollDragBase=m_scroll; }
  }

//--- Recebe a coordenada ja em unidade logica, como a que foi guardada ao
//--- iniciar o arrasto: a rolagem e medida no conteudo, nao na tela.
void HandleScrollDrag(const int ly)
  {
   int target=m_scrollDragBase+(m_scrollDragY-ly);
   if(ScrollBy(target-m_scroll)) Render();
  }

void HandleDrag(const int cx,const int cy)
  {
   int nx=cx-m_dragDX, ny=cy-m_dragDY;
   if(nx<0) nx=0;
   if(ny<0) ny=0;
   if(nx==m_px && ny==m_py) return;
   //--- move sem repintar: o conteudo do quadro nao depende da posicao
   MoveTo(nx,ny);
  }

//+------------------------------------------------------------------+
public:
void ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      //--- so encolhe para nao ficar cortado; nunca cresce sozinho
      int fit=L((int)ChartGetInteger(m_chart,CHART_HEIGHT_IN_PIXELS)-m_py-16);
      if(fit<m_ph && fit>=FCV_PANEL_H_MIN) { m_ph=fit; Render(); }
      if(m_themeMode==FUSION_CANVAS_THEME_AUTO && !m_userTheme)
        {
         bool was=m_dark;
         ResolveTheme();
         if(was!=m_dark) Render();
        }
      return;
     }

   if(id==CHARTEVENT_MOUSE_WHEEL)
     {
      int cx=(int)(short)(lparam & 0xFFFF), cy=(int)(short)((lparam>>16)&0xFFFF);
      if(m_minimized || !InsidePanel(cx,cy)) return;
      if(HandleComboWheel(L(cx-m_px),L(cy-m_py),(dparam>0)?-1:1)) return;
      //--- Com um campo em edicao a roda nao rola o conteudo: o controle de
      //--- edicao do terminal nao acompanha o objeto e ficaria solto sobre o
      //--- painel. Barra, setinhas, teclado e arrasto continuam disponiveis,
      //--- e confirmar o campo (Enter) devolve a roda no ato.
      if(EditHasFocus()) return;
      if(ScrollBy((dparam>0)?-40:40)) Render();
      return;
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      if((int)lparam==FCV_VK_M) { RunPerfSuite(); return; }
      if((int)lparam==FCV_VK_S) { ToggleStress(); return; }
      if((int)lparam==FCV_VK_B)
        {
         //--- simula o perfil bloqueado da 1.058 para exercitar o estado
         m_locked=!m_locked;
         m_comboOpen=-1; m_colorOpen=-1;
         Render();
         Print(m_locked ? "Perfil BLOQUEADO (simulacao): controles desabilitados."
                        : "Perfil liberado.");
         return;
        }
      if(m_minimized || !m_overPanel) return;
      int viewH=ContentBottom()-ContentTop(), step=0;
      switch((int)lparam)
        {
         case FCV_VK_UP:    step=-40;         break;
         case FCV_VK_DOWN:  step= 40;         break;
         case FCV_VK_PRIOR: step=-viewH;      break;
         case FCV_VK_NEXT:  step= viewH;      break;
         case FCV_VK_HOME:  step=-m_contentH; break;
         case FCV_VK_END:   step= m_contentH; break;
         default: return;
        }
      if(ScrollBy(step)) Render();
      return;
     }

   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      int cx=(int)lparam, cy=(int)dparam;
      bool down=(StringToInteger(sparam)&1)!=0;
      bool over=InsidePanel(cx,cy);
      if(over!=m_overPanel) { SetChartScroll(over?false:m_origScroll); m_overPanel=over; }

      if(down && !m_mouseDown && over)   HandlePress(cx,cy);
      else if(down && m_dragging)        HandleDrag(cx,cy);
      else if(down && m_barDrag)         HandleBarDrag(L(cy-m_py));
      else if(down && m_scrollDrag)      HandleScrollDrag(L(cy-m_py));

      if(!down) { m_dragging=false; m_scrollDrag=false; m_barDrag=false; }
      m_mouseDown=down;
      return;
     }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && StringFind(sparam,m_prefix+"edit_")==0)
     { m_focusSlot=-1; StoreEditText(sparam); Render(); return; }
  }
private:
