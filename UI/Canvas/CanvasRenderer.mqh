//+------------------------------------------------------------------+
//| CanvasRenderer.mqh                                                |
//| Renderizador da GUI 2.0 em CCanvas — Fase 1: dados falsos.        |
//|                                                                   |
//| Porta os padroes provados em Prototype/FusionCanvasPrototype.mq5  |
//| para a estrutura definitiva. O prototipo permanece intocado como  |
//| referencia. Na Fase 2 esta classe passa a ser alimentada pelo     |
//| snapshot real e embrulhada na interface do CFusionPanel.          |
//|                                                                   |
//| Segue o idioma de UI do projeto: uma classe com muitos membros    |
//| compartilhados, dividida em fragmentos incluidos no corpo.        |
//|                                                                   |
//| Duas diferencas deliberadas em relacao ao prototipo:              |
//|  - Resize so quando a altura muda (EnsureSize), nao a cada quadro |
//|  - FontSet so quando a fonte muda (cache em SetFontCached)        |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_RENDERER_MQH__
#define __FUSION_CANVAS_RENDERER_MQH__

#include <Canvas\Canvas.mqh>
#include "..\..\Core\Version.mqh"
//--- Fase 2b: as telas passam a ler do snapshot que o EA monta, em vez dos
//--- valores fixos da Fase 1. O renderizador deixa de ser um widget avulso e
//--- passa a conhecer o formato de dados do EA — que e o proposito dele.
#include "..\..\Core\Types.mqh"
//--- Avisos derivados so de SEASettings, compartilhados com o painel 1.058.
#include "..\..\Core\SettingsNotices.mqh"
//--- Comparacao campo a campo: e ela que responde "ha alteracao pendente?".
#include "..\..\Core\SettingsCompare.mqh"
#include "CanvasTheme.mqh"
#include "CanvasLayout.mqh"
#include "CanvasFields.mqh"
#include "CanvasForm.mqh"

class CFusionCanvasRenderer
  {
private:
   CCanvas           m_canvas;
   long              m_chart;
   string            m_prefix;
   string            m_canvasName;
   int               m_curW, m_curH;          // tamanho atual do bitmap

   SCanvasTheme      m_t;
   bool              m_dark;
   bool              m_userTheme;             // usuario travou o tema no botao
   ENUM_FUSION_CANVAS_THEME   m_themeMode;
   ENUM_FUSION_CANVAS_PALETTE m_palette;

   int               m_px, m_py, m_ph;        // posicao e altura (decidida no anexo)
   int               m_tab;                   // aba de nivel 1
   int               m_sub[FCV_TAB_COUNT];    // nivel 2, guardado por aba
   int               m_railSel[2];            // nivel 3, guardado por Risco e Protecao
   bool              m_minimized;
   //--- Pendencia de controles ainda NAO ligados a SEASettings (Gestao, Perfis,
   //--- Layout). A pendencia de configuracao nao mora aqui: e a diferenca entre
   //--- rascunho e comprometido, calculada em HasPending().
   bool              m_dirty;
   //--- Pendencia que a tela esta mostrando agora, para o pulso comparar.
   bool              m_lastPending;

   string            m_tabNames[FCV_TAB_COUNT];
   int               m_tabX[FCV_TAB_COUNT], m_tabW[FCV_TAB_COUNT];
   int               m_cfgX[FCV_CFG_COUNT], m_cfgW[FCV_CFG_COUNT];
   string            m_railRisco[5];
   string            m_railProt[FCV_RAIL_MAX];
   int               m_railY[FCV_RAIL_MAX];
   int               m_railCount;

   //--- interacao
   bool              m_mouseDown, m_dragging, m_scrollDrag, m_overPanel;
   int               m_dragDX, m_dragDY, m_scrollDragY, m_scrollDragBase;
   bool              m_origScroll;
   int               m_scroll, m_contentH, m_alertH;

   //--- Formulario em construcao e cursor de layout
   SCanvasFormRow    m_rows[FCV_ROWS_MAX];
   int               m_rowCount;
   int               m_fx1, m_fx2, m_fy;
   int               m_screen, m_slotSeq;

   //--- Caixas publicadas pelo desenho da tela atual
   int               m_editX[FCV_CTRL_MAX], m_editY[FCV_CTRL_MAX];
   int               m_editSlot[FCV_CTRL_MAX], m_editFid[FCV_CTRL_MAX];
   string            m_editVal[FCV_CTRL_MAX];
   bool              m_editEnabled[FCV_CTRL_MAX], m_editValid[FCV_CTRL_MAX];
   int               m_editCount;
   int               m_toggleX[FCV_CTRL_MAX], m_toggleY[FCV_CTRL_MAX];
   int               m_toggleSlot[FCV_CTRL_MAX], m_toggleFid[FCV_CTRL_MAX];
   int               m_toggleCount;
   int               m_comboX[FCV_CTRL_MAX], m_comboY[FCV_CTRL_MAX], m_comboW[FCV_CTRL_MAX];
   int               m_comboSlot[FCV_CTRL_MAX], m_comboKind[FCV_CTRL_MAX], m_comboFid[FCV_CTRL_MAX];
   int               m_comboCount;
   int               m_colorX[FCV_CTRL_MAX], m_colorY[FCV_CTRL_MAX], m_colorW[FCV_CTRL_MAX];
   int               m_colorSlot[FCV_CTRL_MAX];
   int               m_colorCount;
   int               m_comboOpen, m_colorOpen;   // indice no registro, -1 = fechado
   int               m_comboScroll;               // deslocamento da lista aberta

   //--- Botoes publicados pelo desenho, com o comando que cada um dispara
   int               m_btnX[FCV_BTN_MAX], m_btnY[FCV_BTN_MAX];
   int               m_btnW[FCV_BTN_MAX], m_btnH[FCV_BTN_MAX];
   int               m_btnId[FCV_BTN_MAX];
   int               m_btnCount;
   //--- Perfis: ver a lista, criar um novo ou duplicar o selecionado
   int               m_profEdit;
   int               m_profSel;

   //--- Campos nativos realmente existentes no grafico, com a posicao local em
   //--- que foram criados. E o que permite mover o painel sem repintar nada.
   string            m_liveEditName[FCV_CTRL_MAX];
   int               m_liveEditX[FCV_CTRL_MAX], m_liveEditY[FCV_CTRL_MAX];
   int               m_liveEditSlot[FCV_CTRL_MAX], m_liveEditFid[FCV_CTRL_MAX];
   string            m_liveEditText[FCV_CTRL_MAX];
   int               m_liveEditCount;
   //--- slot do campo que o terminal provavelmente colocou em edicao. Nao ha
   //--- como perguntar ao MQL5 quem tem foco; isto e deducao pelo clique.
   int               m_focusSlot;

   //--- Estado persistente por tela
   bool              m_stToggle[FCV_STATE_MAX];
   int               m_stCombo[FCV_STATE_MAX];
   int               m_stColor[FCV_STATE_MAX];
   string            m_stEdit[FCV_STATE_MAX];    // "" = usar o padrao declarado

   uint              m_swatches[FCV_SWATCH_COUNT];

   //--- barra de rolagem: geometria publicada pelo desenho
   int               m_thumbY, m_thumbH, m_trackTop, m_trackH;
   bool              m_barDrag;
   //--- Arrasto da barra do proprio popup, independente da barra do conteudo.
   bool              m_comboBarDrag;
   //--- Ha campo nativo esperando para nascer porque o botao do mouse continua
   //--- pressionado. Ver a nota em BuildEdits.
   bool              m_editsPending;
   int               m_barDragY, m_barDragBase;

   //--- Retangulo do popup aberto. Objeto nativo fica SEMPRE acima do canvas:
   //--- o popup publica sua area e os campos sob ela nao sao criados.
   bool              m_popupOn;
   int               m_popupX1, m_popupY1, m_popupX2, m_popupY2;

   //--- cache de fonte: FontSet e caro e a maioria das chamadas repete a fonte
   string            m_fontName;
   int               m_fontPt10, m_fontWeight;

   //--- Escala: 100 = unidades logicas de projeto. So as primitivas, a
   //--- conversao de clique e a criacao dos campos nativos a enxergam.
   int               m_scale;
   //--- Acesso: espelha o CanEditActiveProfile() da 1.058. Com o perfil
   //--- bloqueado, os controles ficam apagados e param de aceitar clique.
   bool              m_locked;
   //--- lembrar paleta, tema e tamanho entre sessoes
   bool              m_remember;

   //--- Dados vindos do EA. Fonte unica de verdade das telas: nenhum valor
   //--- exibido deve estar escrito no desenho.
   SUIPanelSnapshot  m_snap;
   //--- Rascunho de configuracao: o que os controles editam. O comprometido e
   //--- o espelho do que o EA aplicou; o rascunho diverge dele enquanto o
   //--- usuario edita, e a diferenca e a pendencia.
   SEASettings       m_draft;
   SEASettings       m_committed;

   //--- medicao
   bool              m_stress;                // tela sintetica de pior caso
   int               m_frameTexts, m_frameTextsVis, m_frameRects; // contadores da ultima passada

public:
                     CFusionCanvasRenderer(void);
   bool              Create(const long chart,const string prefix,
                            const ENUM_FUSION_CANVAS_THEME mode,
                            const ENUM_FUSION_CANVAS_PALETTE palette,
                            const bool remember,
                            const int x,const int y);
   void              Destroy(void);
   void              Render(void);

   //--- Pulso periodico. O painel observa uma coisa que ninguem lhe conta: o
   //--- texto digitado e ainda nao confirmado, que muda o estado dos botoes.
   //--- Sem isto, SALVAR e CANCELAR so acendiam no proximo evento de mouse —
   //--- e o usuario via botao apagado sobre uma edicao ja feita. O EA chama
   //--- pelo Update(); o harness, por temporizador.
   void              Pulse(void)
     {
      if(HasPending()==m_lastPending) return;
      Render();
     }
   //--- Regra da 1.058: o snapshot so sobrescreve o rascunho quando nao ha
   //--- edicao pendente. Com pendencia, o que o usuario digitou permanece ate
   //--- SALVAR ou CANCELAR — senao a atualizacao periodica do EA (ate 5x/s com
   //--- posicao aberta) apagaria o valor no meio da digitacao.
   void              SetSnapshot(const SUIPanelSnapshot &snap)
     {
      m_snap=snap;
      //--- A pendencia e medida contra o comprometido ANTERIOR. Medida depois
      //--- da troca, uma mudanca vinda do EA pareceria edicao do usuario e o
      //--- painel se recusaria a exibi-la — ficaria preso no valor velho.
      bool pending=HasPending();
      m_committed=snap.settings;
      if(!pending) { m_draft=m_committed; SyncDerivedSettings(); }
     }
   void              MoveTo(const int x,const int y);
   void              ToggleStress(void);
   //--- ChartEvent e RunPerfSuite sao definidos nos fragmentos Input e Perf

private:
   void              ResolveTheme(void);
   int               DecidePanelHeight(void);
   bool              EnsureSize(const int w,const int h);
   void              DrawFrame(void);
   void              PublishPopup(const int x1,const int y1,const int x2,const int y2)
     { m_popupOn=true; m_popupX1=x1; m_popupY1=y1; m_popupX2=x2; m_popupY2=y2; }

#include "CanvasRendererPrimitives.mqh"
#include "CanvasRendererFields.mqh"
#include "CanvasRendererChrome.mqh"
#include "CanvasRendererForm.mqh"
#include "CanvasRendererScreens.mqh"
#include "CanvasRendererStress.mqh"
#include "CanvasRendererEdits.mqh"
#include "CanvasRendererPrefs.mqh"
#include "CanvasRendererInput.mqh"
#include "CanvasRendererPerf.mqh"
  };

//+------------------------------------------------------------------+
CFusionCanvasRenderer::CFusionCanvasRenderer(void)
  {
   m_chart=0; m_prefix=""; m_canvasName="";
   m_curW=0; m_curH=0;
   m_dark=true; m_userTheme=false; m_themeMode=FUSION_CANVAS_THEME_AUTO;
   m_palette=FUSION_PALETTE_PETROLEO;
   m_px=10; m_py=20; m_ph=700;
   m_tab=0;
   for(int i=0;i<FCV_TAB_COUNT;++i) m_sub[i]=0;
   m_sub[FCV_TAB_GESTAO]=1;          // abre em Gestao > Protecao ao alternar
   m_railSel[0]=0; m_railSel[1]=5;
   //--- Painel recem-criado nao tem alteracao pendente. Nascia com m_dirty=true
   //--- na Fase 1, so para os botoes aparecerem acesos na demonstracao — e isso
   //--- passou a impedir que o primeiro snapshot semeasse o rascunho, deixando
   //--- a tela presa nos valores padrao.
   m_minimized=false; m_dirty=false; m_lastPending=false;
   m_railCount=0;

   m_mouseDown=false; m_dragging=false; m_scrollDrag=false; m_overPanel=false;
   m_dragDX=0; m_dragDY=0; m_scrollDragY=0; m_scrollDragBase=0;
   m_origScroll=true;
   m_scroll=0; m_contentH=0; m_alertH=0;

   m_editCount=0; m_toggleCount=0; m_comboCount=0; m_colorCount=0;
   m_rowCount=0; m_slotSeq=0; m_screen=0;
   m_fx1=FCV_PAD; m_fx2=FCV_PANEL_W-FCV_PAD; m_fy=0;
   m_comboOpen=-1; m_colorOpen=-1; m_comboScroll=0;
   m_profSel=0; m_profEdit=FCV_PROF_VIEW; m_btnCount=0;
   for(int i=0;i<FCV_BTN_MAX;++i)
     { m_btnX[i]=0; m_btnY[i]=0; m_btnW[i]=0; m_btnH[i]=0; m_btnId[i]=FCV_BTN_NONE; }
   m_liveEditCount=0;
   for(int i=0;i<FCV_CTRL_MAX;++i)
     {
      m_liveEditName[i]=""; m_liveEditX[i]=0; m_liveEditY[i]=0;
      m_liveEditSlot[i]=-1; m_liveEditFid[i]=FCV_FLD_NONE; m_liveEditText[i]="";
     }
   m_focusSlot=-1;
   for(int i=0;i<FCV_STATE_MAX;++i)
     { m_stToggle[i]=false; m_stCombo[i]=0; m_stColor[i]=0; m_stEdit[i]=""; }

   m_thumbY=0; m_thumbH=0; m_trackTop=0; m_trackH=0;
   m_barDrag=false; m_barDragY=0; m_barDragBase=0;
   m_comboBarDrag=false; m_editsPending=false;

   m_popupOn=false; m_popupX1=0; m_popupY1=0; m_popupX2=0; m_popupY2=0;

   //--- Snapshot neutro ate o EA mandar o primeiro. Sem isto o painel nasceria
   //--- com campos vazios no primeiro quadro — parece defeito, nao "sem dado".
   m_snap.symbol="—";
   m_snap.timeframe="—";
   m_snap.activeProfileName="—";
   m_snap.ownerStrategyName="";
   m_snap.started=false;
   m_snap.hasPosition=false;
   m_snap.runtimeBlocked=false;
   m_snap.magicNumber=0;
   m_snap.activeStrategies=0;
   m_snap.activeFilters=0;
   m_snap.conflictMode=CONFLICT_PRIORITY;

   m_fontName=""; m_fontPt10=0; m_fontWeight=0;
   m_scale=FCV_SCALE_DEFAULT; m_locked=false; m_remember=true;
   SetDefaultSettings(m_draft);
   SetDefaultSettings(m_committed);
   m_stress=false; m_frameTexts=0; m_frameTextsVis=0; m_frameRects=0;

   string tn[FCV_TAB_COUNT]={"Status","Resultados","Estrategias","Filtros",
                             "Gestao","Perfis","Layout"};
   ArrayCopy(m_tabNames,tn);
   string rr[5]={"Lote","SL/TP","TP Parcial","BreakEven","Trailing"};
   ArrayCopy(m_railRisco,rr);
   string rp[FCV_RAIL_MAX]={"Geral","Spread/Lado","Sessao","Noticias","Limites Diarios","Drawdown","Sequencias"};
   ArrayCopy(m_railProt,rp);

   for(int i=0;i<FCV_TAB_COUNT;++i) { m_tabX[i]=0; m_tabW[i]=0; }
   for(int i=0;i<FCV_CFG_COUNT;++i) { m_cfgX[i]=0; m_cfgW[i]=0; }
   for(int i=0;i<FCV_RAIL_MAX;++i)  m_railY[i]=0;
   for(int i=0;i<FCV_CTRL_MAX;++i)
     {
      m_editX[i]=0; m_editY[i]=0; m_editSlot[i]=0; m_editFid[i]=FCV_FLD_NONE; m_editVal[i]="";
      m_editEnabled[i]=true; m_editValid[i]=true;
      m_toggleX[i]=0; m_toggleY[i]=0; m_toggleSlot[i]=0; m_toggleFid[i]=FCV_FLD_NONE;
      m_comboX[i]=0; m_comboY[i]=0; m_comboW[i]=0; m_comboSlot[i]=0; m_comboKind[i]=0;
      m_comboFid[i]=FCV_FLD_NONE;
      m_colorX[i]=0; m_colorY[i]=0; m_colorW[i]=64; m_colorSlot[i]=0;
     }

   //--- Grade de cores: matiz na horizontal, luminosidade na vertical, para a
   //--- grade se navegar pelo olho. Nao existe seletor do sistema em MQL5.
   uint sw[FCV_SWATCH_COUNT]=
     {
      FCV_OPAQUE(105,240,174), FCV_OPAQUE(128,216,255), FCV_OPAQUE(179,157,219), FCV_OPAQUE(255,138,128), FCV_OPAQUE(255,224,130), FCV_OPAQUE(255,255,255),
      FCV_OPAQUE(0,230,118),   FCV_OPAQUE(41,182,246),  FCV_OPAQUE(149,117,205), FCV_OPAQUE(255,82,82),   FCV_OPAQUE(255,193,7),   FCV_OPAQUE(207,216,220),
      FCV_OPAQUE(0,200,83),    FCV_OPAQUE(41,121,255),  FCV_OPAQUE(124,77,255),  FCV_OPAQUE(244,67,54),   FCV_OPAQUE(255,152,0),   FCV_OPAQUE(144,164,174),
      FCV_OPAQUE(0,137,71),    FCV_OPAQUE(21,101,192),  FCV_OPAQUE(81,45,168),   FCV_OPAQUE(198,40,40),   FCV_OPAQUE(230,81,0),    FCV_OPAQUE(84,110,122),
      FCV_OPAQUE(0,229,255),   FCV_OPAQUE(26,35,126),   FCV_OPAQUE(233,30,99),   FCV_OPAQUE(136,14,79),   FCV_OPAQUE(121,85,72),   FCV_OPAQUE(38,50,56)
     };
   ArrayCopy(m_swatches,sw);

   //--- Estados iniciais: dao variedade visual e mantem o erro fake coerente —
   //--- a janela de noticias esta ATIVA e com horarios invalidos, que e o que
   //--- justifica o vermelho subindo ate a aba Config.
   m_stToggle[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_INDICATORS)]=true;
   int swatch[5]={6,15,26,16,13};   // MA Rapida, MA Lenta, Trend M1, Trend M2, Bandas
   for(int i=0;i<5;++i)
      m_stColor[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_COLOR0+i*FCV_VISUAL_SLOT_STRIDE)]=swatch[i];
   m_stToggle[(FCV_SCREEN_STRAT0+0)*FCV_SLOT_MAX+0]=true; // Estrategias > Geral > MA Cross
   m_stToggle[(FCV_SCREEN_STRAT0+1)*FCV_SLOT_MAX+0]=true; // Estrategias > Medias > Ativo
   m_stToggle[(FCV_SCREEN_FILTER0+0)*FCV_SLOT_MAX+0]=true;// Filtros > Geral > Tendencia
   m_stToggle[(FCV_SCREEN_RISK0+1)*FCV_SLOT_MAX+2]=true;  // Risco > SL/TP > Compensar Spread SL
   m_stToggle[(FCV_SCREEN_PROT0+2)*FCV_SLOT_MAX+0]=true;  // Protecao > Sessao > Ativo
   m_stToggle[(FCV_SCREEN_PROT0+3)*FCV_SLOT_MAX+0]=true;  // Protecao > Noticias > Janela 1
  }

//+------------------------------------------------------------------+
void CFusionCanvasRenderer::ResolveTheme(void)
  {
   if(m_themeMode==FUSION_CANVAS_THEME_DARK)       m_dark=true;
   else if(m_themeMode==FUSION_CANVAS_THEME_LIGHT) m_dark=false;
   else                                            m_dark=!FusionCanvasChartWantsLight(m_chart);
   FusionCanvasApplyPalette(m_t,m_palette,m_dark);
  }

//+------------------------------------------------------------------+
//| Altura: decidida ao anexar, nao elastica durante o uso. Um painel |
//| que encolhe e cresce sozinho faz a informacao mudar de lugar sem  |
//| que o usuario tenha feito nada.                                   |
//+------------------------------------------------------------------+
int CFusionCanvasRenderer::DecidePanelHeight(void)
  {
   int chartH=(int)ChartGetInteger(m_chart,CHART_HEIGHT_IN_PIXELS);
   //--- o espaco disponivel vem em pixels do grafico; a altura do painel vive
   //--- em unidades logicas, entao converte antes de comparar com os limites
   int h=L(chartH-m_py-16);
   if(h<FCV_PANEL_H_MIN) h=FCV_PANEL_H_MIN;
   if(h>FCV_PANEL_H_MAX) h=FCV_PANEL_H_MAX;
   return h;
  }

//+------------------------------------------------------------------+
//| Resize recria o recurso do bitmap — caro. So quando muda mesmo.   |
//+------------------------------------------------------------------+
bool CFusionCanvasRenderer::EnsureSize(const int w,const int h)
  {
   if(w==m_curW && h==m_curH) return true;
   if(!m_canvas.Resize(w,h)) return false;
   m_curW=w; m_curH=h;
   return true;
  }

//+------------------------------------------------------------------+
bool CFusionCanvasRenderer::Create(const long chart,const string prefix,
                                   const ENUM_FUSION_CANVAS_THEME mode,
                                   const ENUM_FUSION_CANVAS_PALETTE palette,
                                   const bool remember,
                                   const int x,const int y)
  {
   m_chart=chart; m_prefix=prefix; m_themeMode=mode; m_palette=palette;
   m_remember=remember;
   m_px=x; m_py=y;
   //--- A preferencia salva vence o input: ela e a ultima escolha consciente
   //--- do usuario. Para o input voltar a mandar, basta desligar o lembrar.
   LoadAppearance();
   //--- os combos da subaba Visual comecam refletindo a aparencia em vigor
   m_stCombo[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_PALETTE)]=(int)m_palette;
   m_stCombo[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_THEME)]  =(int)m_themeMode;
   m_stCombo[FCV_VISUAL_STATE(FCV_VISUAL_SLOT_SCALE)]  =(m_scale-FCV_SCALE_MIN)/FCV_SCALE_STEP;
   ResolveTheme();
   ChartSetInteger(m_chart,CHART_EVENT_MOUSE_MOVE,true);
   ChartSetInteger(m_chart,CHART_EVENT_MOUSE_WHEEL,true);
   m_origScroll=(bool)ChartGetInteger(m_chart,CHART_MOUSE_SCROLL);
   m_ph=DecidePanelHeight();

   m_canvasName=m_prefix+"canvas";
   if(!m_canvas.CreateBitmapLabel(m_chart,0,m_canvasName,m_px,m_py,
                                  S(FCV_PANEL_W),S(m_ph),COLOR_FORMAT_ARGB_NORMALIZE))
      return false;
   m_curW=S(FCV_PANEL_W); m_curH=S(m_ph);
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_ZORDER,0);

   Render();

   //--- Com sete abas a faixa do nivel 1 ficou apertada. As caixas ja foram
   //--- publicadas pelo desenho, entao da para conferir de verdade em vez de
   //--- estimar: se um rotulo crescer e a faixa estourar, aparece no log.
   int stripEnd=m_tabX[FCV_TAB_COUNT-1]+m_tabW[FCV_TAB_COUNT-1];
   int stripRoom=FCV_PANEL_W-10-stripEnd;
   if(stripRoom<0)
      PrintFormat("ATENCAO: a faixa de abas estourou %d px. Encurte um rotulo.",-stripRoom);
   else
      PrintFormat("Faixa de abas: %d px usados, %d px de folga.",stripEnd,stripRoom);
   return true;
  }

//+------------------------------------------------------------------+
void CFusionCanvasRenderer::Destroy(void)
  {
   SetChartScroll(m_origScroll);
   DestroyEdits();
   m_canvas.Destroy();
   ObjectsDeleteAll(m_chart,m_prefix);
   ChartRedraw(m_chart);
  }

//+------------------------------------------------------------------+
//| Pintura pura de um quadro. Sem Update, sem campos nativos: e o    |
//| que a medicao cronometra isolado.                                 |
//+------------------------------------------------------------------+
void CFusionCanvasRenderer::DrawFrame(void)
  {
   int h = m_minimized ? FCV_TITLEBAR_H : m_ph;
   m_frameTexts=0; m_frameTextsVis=0; m_frameRects=0;

   m_canvas.Erase(m_t.ground);
   m_popupOn=false;

   if(m_minimized) { DrawTitlebar(); return; }

   //--- O aviso e medido ANTES do conteudo: ele encurta a area util, e medir
   //--- depois faria o conteudo desta passada usar a altura da passada
   //--- anterior — um quadro de atraso a cada troca de tela.
   MeasureAlert();

   //--- superficie do nivel 1: e nela que as abas do fichario se apoiam
   Rect(0,Surf1Top(),FCV_PANEL_W-1,h-1,m_t.surface);

   //--- Conteudo rolavel primeiro; depois as faixas de fora sao repintadas e o
   //--- chrome fecha por cima, entao nada rolado alcanca as abas. O canvas nao
   //--- recorta sozinho: e essa repintura que devolve o recorte.
   DrawScreenContent();
   Rect(0,Surf1Top(),FCV_PANEL_W-1,ContentTop()-1,m_t.surface);
   Rect(0,ContentBottom()+1,FCV_PANEL_W-1,h-1,m_t.surface);
   Rect(0,0,FCV_PANEL_W-1,Surf1Top()-1,m_t.ground);

   DrawTitlebar();
   DrawHeader();
   FolderStrip(FCV_HEADER_BOTTOM,FCV_F1_H,10,FCV_PANEL_W-10,
               m_tabNames,FCV_TAB_COUNT,m_tab,82,m_t.surface,m_tabX,m_tabW,true,-1);

   if(HasLevel2(m_tab))
     {
      string names[];
      int n=Level2Names(m_tab,names);
      FolderStrip(F2Top(),FCV_F2_H,FCV_PAD,FCV_PANEL_W-FCV_PAD,
                  names,n,Sub(),FCV_FS_SM,m_t.ground,m_cfgX,m_cfgW,
                  (m_tab==FCV_TAB_GESTAO),1);
     }

   DrawScrollbar();
   DrawAlert();
   //--- popups por ultimo: no canvas a ordem de desenho ja basta
   DrawComboPopup();
   DrawColorPopup();

   //--- contorno de 1px: sem ele, painel escuro sobre grafico escuro perde a silhueta
   Frame(0,0,FCV_PANEL_W-1,h-1,m_t.shell);
  }

//+------------------------------------------------------------------+
void CFusionCanvasRenderer::Render(void)
  {
   int h = m_minimized ? FCV_TITLEBAR_H : m_ph;
   if(!EnsureSize(S(FCV_PANEL_W),S(h))) return;
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_XDISTANCE,m_px);
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_YDISTANCE,m_py);

   DrawFrame();

   m_canvas.Update(false);
   BuildEdits();
   ChartRedraw(m_chart);
   //--- Guardado DEPOIS do desenho: e o estado que a tela esta mostrando, e e
   //--- contra ele que o pulso decide se ha algo novo a mostrar.
   m_lastPending=HasPending();
  }

//+------------------------------------------------------------------+
//| Move o painel sem repintar. O quadro e desenhado inteiramente em  |
//| coordenadas locais do painel, entao arrastar nao muda um pixel do |
//| conteudo — so onde ele fica. Este e o caminho de maior frequencia |
//| que existe (o mouse envia dezenas de eventos por segundo), e e o  |
//| unico em que repintar sairia caro numa maquina modesta.           |
//+------------------------------------------------------------------+
void CFusionCanvasRenderer::MoveTo(const int x,const int y)
  {
   m_px=x; m_py=y;
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_XDISTANCE,m_px);
   ObjectSetInteger(m_chart,m_canvasName,OBJPROP_YDISTANCE,m_py);
   //--- Os campos nativos sao reposicionados, nao recriados: destruir e criar
   //--- objeto de grafico a cada evento de mouse custaria mais que o desenho
   //--- que estamos evitando.
   for(int i=0;i<m_liveEditCount;++i)
     {
      ObjectSetInteger(m_chart,m_liveEditName[i],OBJPROP_XDISTANCE,m_px+S(m_liveEditX[i]));
      ObjectSetInteger(m_chart,m_liveEditName[i],OBJPROP_YDISTANCE,m_py+S(m_liveEditY[i]));
     }
   ChartRedraw(m_chart);
  }

//+------------------------------------------------------------------+
void CFusionCanvasRenderer::ToggleStress(void)
  {
   m_stress=!m_stress;
   if(m_stress) { m_tab=FCV_TAB_GESTAO; m_sub[FCV_TAB_GESTAO]=1; m_railSel[1]=4; }
   m_scroll=0;
   Render();
   Print(m_stress ? "Tela de estresse LIGADA (pior caso sintetico)."
                  : "Tela de estresse desligada.");
  }

#endif
