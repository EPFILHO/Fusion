//+------------------------------------------------------------------+
//| FusionCanvasPrototype.mq5                                        |
//| Prototipo descartavel: valida uma GUI do Fusion desenhada em      |
//| CCanvas, com campos de digitacao nativos sobrepostos.             |
//|                                                                   |
//| NAO faz parte do EA. Nao opera, nao le perfil, nao toca em ordem. |
//|                                                                   |
//| Segunda rodada, atendendo ao teste no grafico:                    |
//|   - arrastar pelo cabecalho (com o scroll do grafico suprimido)   |
//|   - minimizar/restaurar                                           |
//|   - tema claro e escuro, escolhido pelo fundo do grafico          |
//|   - layout de CONFIG em linhas, sem campos sobrepostos            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "1.058"
#property strict

#include <Canvas\Canvas.mqh>

#define OPAQUE(r,g,b) ((uint)(0xFF000000|((uint)(r)<<16)|((uint)(g)<<8)|(uint)(b)))

enum ENUM_PROTO_THEME
  {
   PROTO_THEME_AUTO = 0,   // Automatico (segue o fundo do grafico)
   PROTO_THEME_DARK = 1,   // Escuro
   PROTO_THEME_LIGHT= 2    // Claro
  };

input ENUM_PROTO_THEME inp_Theme = PROTO_THEME_AUTO; // Tema do painel

//+------------------------------------------------------------------+
//| Tema                                                              |
//+------------------------------------------------------------------+
struct STheme
  {
   uint ground, surface, raised, line, lineSoft;
   uint fg, muted, dim;
   uint accent, accentStr, accentDim;
   uint good, goodDim, bad, badDim, warn, warnDim;
   uint onGood, onAccent;
   uint alertTextWarn, alertTextBad;
   uint toggleOff, knob;
   uint shell;                 // contorno externo do painel
  };

STheme T;
bool   g_dark = true;
bool   g_userTheme = false;   // usuario escolheu pelo painel: nao sobrescrever

void ApplyDark(void)
  {
   T.ground=OPAQUE(15,19,25);      T.surface=OPAQUE(23,28,36);
   T.raised=OPAQUE(30,36,46);      T.line=OPAQUE(38,46,58);
   T.lineSoft=OPAQUE(31,38,48);
   //--- Sobre fundo escuro o olho perde tom baixo antes do esperado; muted e dim
   //--- ficam mais claros aqui do que a simetria com o tema claro sugeriria.
   T.fg=OPAQUE(233,238,245);       T.muted=OPAQUE(154,166,184);
   T.dim=OPAQUE(122,134,152);
   T.accent=OPAQUE(62,159,224);    T.accentStr=OPAQUE(95,180,236);
   T.accentDim=OPAQUE(35,68,95);
   T.good=OPAQUE(47,191,113);      T.goodDim=OPAQUE(22,53,42);
   T.bad=OPAQUE(229,72,77);        T.badDim=OPAQUE(58,29,34);
   T.warn=OPAQUE(245,165,36);      T.warnDim=OPAQUE(58,45,20);
   T.onGood=OPAQUE(6,24,15);       T.onAccent=OPAQUE(4,18,28);
   T.alertTextWarn=OPAQUE(216,201,166);
   T.alertTextBad=OPAQUE(227,185,187);
   T.toggleOff=OPAQUE(48,57,72);   T.knob=OPAQUE(15,19,25);
   T.shell=OPAQUE(52,62,78);
   g_dark = true;
  }

void ApplyLight(void)
  {
   T.ground=OPAQUE(247,249,252);   T.surface=OPAQUE(255,255,255);
   T.raised=OPAQUE(241,244,249);   T.line=OPAQUE(214,222,233);
   T.lineSoft=OPAQUE(232,237,244);
   T.fg=OPAQUE(27,34,48);          T.muted=OPAQUE(91,105,128);
   T.dim=OPAQUE(137,150,168);
   T.accent=OPAQUE(38,124,190);    T.accentStr=OPAQUE(28,100,158);
   T.accentDim=OPAQUE(227,240,250);
   T.good=OPAQUE(24,150,84);       T.goodDim=OPAQUE(226,246,236);
   T.bad=OPAQUE(200,48,54);        T.badDim=OPAQUE(252,234,234);
   T.warn=OPAQUE(184,116,12);      T.warnDim=OPAQUE(252,242,223);
   T.onGood=OPAQUE(255,255,255);   T.onAccent=OPAQUE(255,255,255);
   T.alertTextWarn=OPAQUE(112,78,16);
   T.alertTextBad=OPAQUE(140,38,42);
   T.toggleOff=OPAQUE(199,208,220); T.knob=OPAQUE(255,255,255);
   T.shell=OPAQUE(198,208,222);
   g_dark = false;
  }

//--- Auto: painel contrasta com o fundo do grafico.
void ResolveTheme(void)
  {
   if(inp_Theme == PROTO_THEME_DARK)  { ApplyDark();  return; }
   if(inp_Theme == PROTO_THEME_LIGHT) { ApplyLight(); return; }

   color bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   int r = (int)(bg & 0xFF), g = (int)((bg>>8) & 0xFF), b = (int)((bg>>16) & 0xFF);
   double lum = (0.2126*r + 0.7152*g + 0.0722*b) / 255.0;
   if(lum < 0.45) ApplyLight(); else ApplyDark();
  }

//+------------------------------------------------------------------+
//| Geometria                                                         |
//+------------------------------------------------------------------+
#define PANEL_W       590
#define PANEL_H       626
#define TITLEBAR_H     34
#define HEADER_BOTTOM 134
#define TABS_H         30
#define TABS_BOTTOM   (HEADER_BOTTOM + TABS_H)
#define PAD            14
#define EDIT_W        128
#define EDIT_H         26

#define FONT_UI       "Segoe UI"
#define FONT_MONO     "Consolas"
#define FW_NORMAL_    400
#define FW_SEMI       600
#define FW_BOLD_      700

#define TAB_COUNT       6
#define SUBTAB_COUNT    5

CCanvas  g_canvas;
string   g_prefix    = "FusProto_";
string   g_canvasName;
int      g_px = 10, g_py = 20;
int      g_tab = 0, g_subtab = 0;
bool     g_minimized = false;

bool     g_mouseDown = false;
bool     g_dragging  = false;
int      g_dragDX = 0, g_dragDY = 0;
bool     g_overPanel = false;
bool     g_origScroll = true;

string   g_tabNames[TAB_COUNT]    = {"STATUS","RESULTS","STRATS","FILTERS","PERFIS","CONFIG"};
int      g_tabX[TAB_COUNT], g_tabW[TAB_COUNT];
string   g_subNames[SUBTAB_COUNT] = {"LOTE","SL/TP","TP PARCIAL","BREAKEVEN","TRAILING"};
int      g_subX[SUBTAB_COUNT], g_subW[SUBTAB_COUNT];

//--- posicoes calculadas no desenho e reaproveitadas pelos campos
int      g_editY[4];
int      g_editCount = 0;

//--- Toggles: estado proprio e caixa de clique publicada pelo desenho, pelo
//--- mesmo motivo dos campos — alvo e pintura nao podem divergir.
#define TOGGLE_COUNT 2
bool     g_toggleOn[TOGGLE_COUNT] = {true, false};
int      g_toggleX[TOGGLE_COUNT], g_toggleY[TOGGLE_COUNT];
int      g_toggleCount = 0;

//--- Rolagem do conteudo de CONFIG. Tres entradas de proposito: roda serve o
//--- mouse, arrasto serve o touchpad do notebook, teclado serve quem nao usa
//--- nenhum dos dois. Uma so nao cobre todo mundo.
int      g_scroll   = 0;    // deslocamento atual, em pixels
int      g_contentH = 0;    // altura medida no ultimo render
int      g_alertH   = 62;   // altura do aviso do rodape no ultimo render
bool     g_scrollDrag = false;
int      g_scrollDragY = 0, g_scrollDragBase = 0;

#define VK_PRIOR_ 33
#define VK_NEXT_  34
#define VK_HOME_  36
#define VK_END_   35
#define VK_UP_    38
#define VK_DOWN_  40

//--- Aplica um passo de rolagem respeitando os limites. Devolve true se mudou.
bool ScrollBy(const int delta)
  {
   int viewH = ContentBottom() - ContentTop();
   int maxScroll = g_contentH - viewH;
   if(maxScroll <= 0)
      return false;
   int ns = g_scroll + delta;
   if(ns < 0) ns = 0;
   if(ns > maxScroll) ns = maxScroll;
   if(ns == g_scroll)
      return false;
   g_scroll = ns;
   return true;
  }

//+------------------------------------------------------------------+
//| Helpers de desenho                                                |
//+------------------------------------------------------------------+
void SetFont(const string name,const int pt10,const int weight)
  {
   g_canvas.FontSet(name, -pt10, weight);
  }

uint Blend(const uint fg,const uint bg,const double k)
  {
   double t = (k < 0.0) ? 0.0 : ((k > 1.0) ? 1.0 : k);
   int fr=(int)((fg>>16)&0xFF), fgn=(int)((fg>>8)&0xFF), fb=(int)(fg&0xFF);
   int br=(int)((bg>>16)&0xFF), bgn=(int)((bg>>8)&0xFF), bb=(int)(bg&0xFF);
   return OPAQUE((int)(br+(fr-br)*t), (int)(bgn+(fgn-bgn)*t), (int)(bb+(fb-bb)*t));
  }

void RoundRect(const int x1,const int y1,const int x2,const int y2,
               const int r,const uint clr,const uint bg)
  {
   if(r <= 0) { g_canvas.FillRectangle(x1,y1,x2,y2,clr); return; }

   g_canvas.FillRectangle(x1+r, y1,   x2-r, y2,   clr);
   g_canvas.FillRectangle(x1,   y1+r, x1+r, y2-r, clr);
   g_canvas.FillRectangle(x2-r, y1+r, x2,   y2-r, clr);

   for(int c = 0; c < 4; ++c)
     {
      int cx0 = (c==0 || c==2) ? x1+r : x2-r;
      int cy0 = (c<2)          ? y1+r : y2-r;
      for(int px = -r; px <= r; ++px)
         for(int py = -r; py <= r; ++py)
           {
            if((c==0||c==2) && px>0) continue;
            if((c==1||c==3) && px<0) continue;
            if(c<2  && py>0) continue;
            if(c>=2 && py<0) continue;
            double d = MathSqrt((double)px*px + (double)py*py);
            double cov = (double)r - d + 0.5;
            if(cov <= 0.0) continue;
            g_canvas.PixelSet(cx0+px, cy0+py, (cov>=1.0) ? clr : Blend(clr,bg,cov));
           }
     }
  }

//--- moldura de 1px arredondada
void RoundFrame(const int x1,const int y1,const int x2,const int y2,
                const int r,const uint border,const uint fill,const uint bg)
  {
   RoundRect(x1, y1, x2, y2, r, border, bg);
   RoundRect(x1+1, y1+1, x2-1, y2-1, r-1, fill, border);
  }

void HLine(const int x1,const int x2,const int y,const uint clr)
  {
   g_canvas.FillRectangle(x1,y,x2,y,clr);
  }

void Txt(const int x,const int y,const string s,const uint clr,
         const string font,const int pt10,const int weight,const uint align)
  {
   SetFont(font, pt10, weight);
   g_canvas.TextOut(x, y, s, clr, align);
  }

int TxtW(const string s,const string font,const int pt10,const int weight)
  {
   SetFont(font, pt10, weight);
   return (int)g_canvas.TextWidth(s);
  }

//--- Quebra o texto pela largura real medida, e nao por contagem de letras:
//--- rotulo traduzido ou fonte diferente mudaria o ponto de corte.
//--- Quebra pela largura medida. Com draw=false so conta as linhas, o que
//--- permite dimensionar a caixa antes de desenhar.
int WrapText(const int x,const int y,const int maxW,const int lineH,const string s,
             const uint clr,const int pt10,const bool draw)
  {
   string words[];
   int n = StringSplit(s, ' ', words);
   string line = "";
   int ly = y, count = 0;

   for(int i = 0; i < n; ++i)
     {
      string cand = (line == "") ? words[i] : line + " " + words[i];
      if(TxtW(cand, FONT_UI, pt10, FW_NORMAL_) <= maxW || line == "")
         line = cand;
      else
        {
         if(draw) Txt(x, ly, line, clr, FONT_UI, pt10, FW_NORMAL_, TA_LEFT|TA_VCENTER);
         ly += lineH; count++;
         line = words[i];
        }
     }
   if(line != "")
     {
      if(draw) Txt(x, ly, line, clr, FONT_UI, pt10, FW_NORMAL_, TA_LEFT|TA_VCENTER);
      count++;
     }
   return count;
  }

//--- Aviso ancorado no rodape que CRESCE conforme o texto. O painel atual nao
//--- consegue isso: ele tem tres CLabel fixos e corta em 174 caracteres. Aqui a
//--- mensagem define a altura da caixa, entao nenhuma instrucao se perde.
void AlertBottom(const int x1,const int x2,const int bottomY,const string title,
                 const string body,const uint accentClr,const uint bgClr,const uint textClr)
  {
   int textX  = x1 + 24;
   int maxW   = (x2 - 14) - textX;
   int lineH  = 15;
   int titleH = 16;
   int gap    = 4;
   int padV   = 14;

   int lines    = WrapText(textX, 0, maxW, lineH, body, textClr, 82, false);
   //--- O bloco titulo+texto define a altura, e o respiro fica igual em cima e
   //--- embaixo: com padding fixo, uma mensagem de 1 ou 3 linhas ficaria torta.
   int contentH = titleH + gap + lines*lineH;
   int h        = contentH + 2*padV;
   int y        = bottomY - h;
   g_alertH     = h;   // a area rolavel precisa saber onde o aviso comeca

   RoundRect(x1, y, x2, y+h, 8, bgClr, T.ground);
   g_canvas.FillRectangle(x1+12, y+padV, x1+14, y+h-padV, accentClr);
   Txt(textX, y+padV+titleH/2, title, accentClr, FONT_UI, 78, FW_BOLD_, TA_LEFT|TA_VCENTER);
   WrapText(textX, y+padV+titleH+gap+lineH/2, maxW, lineH, body, textClr, 82, true);
  }

void Pill(const int x,const int y,const string label,const uint fg,const uint bg,const uint under)
  {
   int w = TxtW(label, FONT_UI, 80, FW_BOLD_) + 30;
   RoundRect(x, y, x+w, y+20, 10, bg, under);
   g_canvas.FillCircle(x+12, y+10, 3, fg);
   Txt(x+21, y+10, label, fg, FONT_UI, 80, FW_BOLD_, TA_LEFT|TA_VCENTER);
  }

//+------------------------------------------------------------------+
//| Cabecalho / abas                                                  |
//+------------------------------------------------------------------+
void DrawTitlebar(void)
  {
   g_canvas.FillRectangle(0, 0, PANEL_W-1, TITLEBAR_H-1, T.surface);
   HLine(0, PANEL_W-1, TITLEBAR_H-1, T.line);
   Txt(14, 17, "EP Fusion", T.fg, FONT_UI, 95, FW_SEMI, TA_LEFT|TA_VCENTER);
   int bw = TxtW("EP Fusion", FONT_UI, 95, FW_SEMI);
   Txt(14+bw+8, 18, "1.058", T.dim, FONT_MONO, 80, FW_NORMAL_, TA_LEFT|TA_VCENTER);

   //--- alternador de tema: circulo com metade preenchida
   int tx = PANEL_W - 52;
   g_canvas.Circle(tx, 17, 7, T.muted);
   for(int dy = -6; dy <= 6; ++dy)
      for(int dx = -6; dx <= 0; ++dx)
         if(dx*dx + dy*dy <= 36)
            g_canvas.PixelSet(tx+dx, 17+dy, T.muted);

   //--- botao minimizar / restaurar
   int mx = PANEL_W - 24;
   if(g_minimized)
     {
      g_canvas.FillRectangle(mx-6, 15, mx+6, 16, T.muted);
      g_canvas.FillRectangle(mx-6, 15, mx-5, 21, T.muted);
      g_canvas.FillRectangle(mx+5, 15, mx+6, 21, T.muted);
      g_canvas.FillRectangle(mx-6, 20, mx+6, 21, T.muted);
     }
   else
      g_canvas.FillRectangle(mx-6, 17, mx+6, 18, T.muted);
  }

//--- No prototipo a subaba SL/TP esta sempre invalida, para exercitar o estado.
bool ConfigHasError(void) { return true; }

//--- O chrome nao limpa mais o fundo: em telas rolaveis ele e desenhado DEPOIS
//--- do conteudo, para que nada rolado possa pintar por cima das abas.
void DrawChrome(const bool running,const bool dirty)
  {
   DrawTitlebar();

   Txt(PAD, 52, "BTCUSD", T.fg, FONT_UI, 110, FW_SEMI, TA_LEFT|TA_VCENTER);
   int sw = TxtW("BTCUSD", FONT_UI, 110, FW_SEMI);
   RoundFrame(PAD+sw+9, 43, PAD+sw+41, 61, 4, T.line, T.raised, T.ground);
   Txt(PAD+sw+25, 52, "M1", T.muted, FONT_MONO, 80, FW_NORMAL_, TA_CENTER|TA_VCENTER);

   if(running) Pill(PANEL_W-PAD-104, 42, "OPERANDO", T.good, T.goodDim, T.ground);
   else        Pill(PANEL_W-PAD-94,  42, "PAUSADO",  T.warn, T.warnDim, T.ground);

   Txt(PAD, 74, "Perfil", T.dim, FONT_UI, 85, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   int pw = TxtW("Perfil", FONT_UI, 85, FW_NORMAL_);
   Txt(PAD+pw+8, 74, "BTCUSD", T.accentStr, FONT_UI, 85, FW_SEMI, TA_LEFT|TA_VCENTER);
   if(dirty)
     {
      int vw = TxtW("BTCUSD", FONT_UI, 85, FW_SEMI);
      Txt(PAD+pw+vw+16, 74, "· alteracoes nao salvas", T.dim, FONT_UI, 85, FW_NORMAL_, TA_LEFT|TA_VCENTER);
     }

   int bx = PAD, byy = 90, bh = 30;
   int bwid = (PANEL_W - 2*PAD - 16) / 3;

   if(running)
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, T.surface, T.ground);
      Txt(bx+bwid/2, byy+bh/2, "OPERANDO", T.dim, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, T.good, T.ground);
      Txt(bx+bwid/2, byy+bh/2, "INICIAR", T.onGood, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }

   bx += bwid + 8;
   if(dirty)
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, T.accent, T.ground);
      Txt(bx+bwid/2, byy+bh/2, "SALVAR", T.onAccent, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundFrame(bx, byy, bx+bwid, byy+bh, 6, T.line, T.ground, T.ground);
      Txt(bx+bwid/2, byy+bh/2, "SALVAR", T.muted, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }

   bx += bwid + 8;
   RoundFrame(bx, byy, bx+bwid, byy+bh, 6,
              dirty ? T.warn : T.line, T.ground, T.ground);
   Txt(bx+bwid/2, byy+bh/2, "CANCELAR", dirty ? T.warn : T.muted, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);

   HLine(0, PANEL_W-1, HEADER_BOTTOM-1, T.lineSoft);

   int tx = 10;
   for(int i = 0; i < TAB_COUNT; ++i)
     {
      int w = TxtW(g_tabNames[i], FONT_UI, 82, FW_SEMI) + 22;
      g_tabX[i] = tx; g_tabW[i] = w;
      bool on = (i == g_tab);
      //--- Uma aba herda o erro das suas subabas: quem esta em STATUS precisa
      //--- enxergar que existe problema em CONFIG sem abrir CONFIG.
      bool err = (i == 5 && ConfigHasError());
      Txt(tx + w/2, HEADER_BOTTOM + TABS_H/2, g_tabNames[i],
          err ? T.bad : (on ? T.fg : T.dim), FONT_UI, 82, FW_SEMI, TA_CENTER|TA_VCENTER);
      if(on)
         g_canvas.FillRectangle(tx+4, TABS_BOTTOM-3, tx+w-4, TABS_BOTTOM-1, err ? T.bad : T.accent);
      tx += w + 2;
     }
   HLine(0, PANEL_W-1, TABS_BOTTOM-1, T.line);
  }

//+------------------------------------------------------------------+
//| STATUS                                                            |
//+------------------------------------------------------------------+
void DrawStatus(void)
  {
   int x1 = PAD, x2 = PANEL_W - PAD;
   int y  = TABS_BOTTOM + PAD;

   RoundRect(x1, y, x2, y+56, 8, T.surface, T.ground);
   Txt(x1+14, y+18, "ESTADO", T.dim, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x1+14, y+38, "Rodando", T.fg, FONT_UI, 150, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x2-14, y+18, "POSICAO", T.dim, FONT_UI, 78, FW_SEMI, TA_RIGHT|TA_VCENTER);
   Txt(x2-14, y+38, "BUY 0.06", T.good, FONT_MONO, 115, FW_SEMI, TA_RIGHT|TA_VCENTER);
   y += 66;

   string tk[4] = {"ESTRATEGIAS","FILTROS","MAGIC","TF OPER."};
   string tv[4] = {"1","0","1","M1"};
   int tw = (x2 - x1 - 24) / 4;
   for(int i = 0; i < 4; ++i)
     {
      int bx = x1 + i*(tw+8);
      RoundRect(bx, y, bx+tw, y+54, 7, T.surface, T.ground);
      Txt(bx+11, y+17, tk[i], T.dim, FONT_UI, 75, FW_SEMI, TA_LEFT|TA_VCENTER);
      bool mono = (i >= 2);
      Txt(bx+11, y+37, tv[i], (i==1) ? T.dim : T.fg,
          mono ? FONT_MONO : FONT_UI, mono ? 105 : 120, FW_SEMI, TA_LEFT|TA_VCENTER);
     }
   y += 66;

   string rk[5] = {"Responsavel","Conflito","Resultado do dia","Trades hoje","Drawdown"};
   string rv[5] = {"MA Cross","Prioridade","+128,40","3","—"};
   for(int i = 0; i < 5; ++i)
     {
      Txt(x1+2, y+15, rk[i], T.muted, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
      bool mono = (i >= 2);
      Txt(x2-2, y+15, rv[i], (i==2) ? T.good : T.fg,
          mono ? FONT_MONO : FONT_UI, mono ? 95 : 88, FW_SEMI, TA_RIGHT|TA_VCENTER);
      HLine(x1, x2, y+31, T.lineSoft);
      y += 32;
     }

   AlertBottom(x1, x2, PANEL_H - PAD, "SESSAO",
               "Janela operacional encerra as 18:00. Entradas novas bloqueiam 5 min antes.",
               T.warn, T.warnDim, T.alertTextWarn);
  }

//+------------------------------------------------------------------+
//| CONFIG > RISK — layout por linhas, campos sem sobreposicao        |
//+------------------------------------------------------------------+
void FieldRow(const int gx1,const int gx2,const int ry,const string label,
              const string hint,const uint hintClr,int &editSlot)
  {
   Txt(gx1+13, ry+13, label, T.fg, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   if(hint != "")
      Txt(gx1+13, ry+29, hint, hintClr, FONT_UI, 75, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   g_editY[editSlot] = ry + 21 - EDIT_H/2;
   editSlot++;
  }

void ToggleRow(const int gx1,const int gx2,const int ry,const string label,int &slot)
  {
   bool on = g_toggleOn[slot];
   Txt(gx1+13, ry+15, label, T.fg, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   int tx = gx2 - 13 - 40, ty = ry + 4;
   RoundRect(tx, ty, tx+40, ty+22, 11, on ? T.good : T.toggleOff, T.surface);
   g_canvas.FillCircle(on ? tx+29 : tx+11, ty+11, 9, T.knob);
   g_toggleX[slot] = tx;
   g_toggleY[slot] = ty;
   slot++;
  }

//--- Area util de conteudo rolavel: entre as subabas e o aviso do rodape.
int ContentTop(void)    { return TABS_BOTTOM + PAD + 26 + 12; }
int ContentBottom(void) { return PANEL_H - PAD - g_alertH - 10; }

//--- O canvas se recorta sozinho (basta nao desenhar fora). Um OBJ_EDIT nao:
//--- ele e objeto do grafico e desenharia inteiro, vazando por cima das abas
//--- ou do rodape. Por isso o campo que sai da area util e destruido, nao
//--- reposicionado.
bool EditVisible(const int ly)
  {
   return (ly >= ContentTop() && ly + EDIT_H <= ContentBottom());
  }

//--- Combobox desenhado: fechado e um campo com seta; aberto, a lista e pintada
//--- por ultimo, acima de tudo. Aqui o canvas e mais simples que o nativo — nao
//--- existe objeto para sobrepor nem ordem de criacao a respeitar, so ordem de
//--- desenho. Foi o controle que mais deu trabalho com objetos nativos.
#define COMBO_ITEMS 6
string   g_comboItems[COMBO_ITEMS] = {"M1","M5","M15","M30","H1","H4"};
int      g_comboIndex = 0;
bool     g_comboOpen  = false;
int      g_comboX = 0, g_comboY = 0, g_comboW = 0;

void DrawComboClosed(const int gx1,const int gx2,const int ry,const string label)
  {
   Txt(gx1+13, ry+15, label, T.fg, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);

   int w  = 96;
   int cx = gx2 - 13 - w;
   int cy = ry + 3;
   g_comboX = cx; g_comboY = cy; g_comboW = w;

   RoundFrame(cx, cy, cx+w, cy+EDIT_H, 5,
              g_comboOpen ? T.accent : T.line, T.raised, T.surface);
   Txt(cx+11, cy+EDIT_H/2, g_comboItems[g_comboIndex], T.fg, FONT_MONO, 90, FW_NORMAL_, TA_LEFT|TA_VCENTER);

   int ax = cx + w - 16, ay = cy + EDIT_H/2 - 2;
   for(int i = 0; i < 4; ++i)
      g_canvas.FillRectangle(ax-3+i, ay+i, ax+3-i, ay+i, T.muted);
  }

void DrawComboPopup(void)
  {
   if(!g_comboOpen)
      return;

   int ih = 24;
   int h  = COMBO_ITEMS*ih + 8;
   int y  = g_comboY + EDIT_H + 3;
   if(y + h > PANEL_H - PAD)            // sem espaco abaixo: abre para cima
      y = g_comboY - h - 3;

   RoundFrame(g_comboX, y, g_comboX+g_comboW, y+h, 6, T.accent, T.surface, T.ground);
   for(int i = 0; i < COMBO_ITEMS; ++i)
     {
      int iy = y + 4 + i*ih;
      if(i == g_comboIndex)
         RoundRect(g_comboX+4, iy, g_comboX+g_comboW-4, iy+ih, 4, T.accentDim, T.surface);
      Txt(g_comboX+13, iy+ih/2, g_comboItems[i],
          (i == g_comboIndex) ? T.accentStr : T.fg, FONT_MONO, 90, FW_NORMAL_, TA_LEFT|TA_VCENTER);
     }
  }

bool HandleComboClick(const int lx,const int ly)
  {
   if(g_comboOpen)
     {
      int ih = 24;
      int h  = COMBO_ITEMS*ih + 8;
      int y  = g_comboY + EDIT_H + 3;
      if(y + h > PANEL_H - PAD)
         y = g_comboY - h - 3;

      if(lx >= g_comboX && lx < g_comboX+g_comboW && ly >= y && ly < y+h)
        {
         int idx = (ly - y - 4) / ih;
         if(idx >= 0 && idx < COMBO_ITEMS)
           {
            g_comboIndex = idx;
            Print("Timeframe agora: ", g_comboItems[idx]);
           }
        }
      g_comboOpen = false;      // qualquer clique fecha a lista
      Render();
      return true;
     }

   if(g_comboY >= ContentTop() && g_comboY+EDIT_H <= ContentBottom() &&
      lx >= g_comboX && lx < g_comboX+g_comboW &&
      ly >= g_comboY && ly < g_comboY+EDIT_H)
     {
      g_comboOpen = true;
      Render();
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
void DrawConfigSubtabs(void)
  {
   int x1 = PAD;
   int sx = x1, sy = TABS_BOTTOM + PAD;
   for(int i = 0; i < SUBTAB_COUNT; ++i)
     {
      int w = TxtW(g_subNames[i], FONT_UI, 78, FW_BOLD_) + 22;
      g_subX[i] = sx; g_subW[i] = w;
      //--- Selecao e erro sao estados independentes e devem ser lidos juntos: o
      //--- preenchimento diz qual esta aberta, a cor diz qual precisa de atencao.
      bool on  = (i == g_subtab);
      bool err = (i == 1);
      if(on && err) RoundFrame(sx, sy, sx+w, sy+26, 5, T.bad, T.badDim, T.ground);
      else if(on)   RoundFrame(sx, sy, sx+w, sy+26, 5, T.accent, T.accentDim, T.ground);
      else if(err)  RoundFrame(sx, sy, sx+w, sy+26, 5, T.bad, T.surface, T.ground);
      else          RoundRect (sx, sy, sx+w, sy+26, 5, T.surface, T.ground);
      Txt(sx+w/2, sy+13, g_subNames[i],
          err ? T.bad : (on ? T.accentStr : T.dim), FONT_UI, 78, FW_BOLD_, TA_CENTER|TA_VCENTER);
      sx += w + 6;
     }
  }

void DrawConfigAlert(void)
  {
   AlertBottom(PAD, PANEL_W - PAD, PANEL_H - PAD, "PERFIL",
               "Perfil BTCUSD do grafico nao pode ser carregado. Carregue um perfil na aba PERFIS para liberar a operacao. Assumir outro mudaria lote e Magic.",
               T.bad, T.badDim, T.alertTextBad);
  }

//--- Geometria da barra, compartilhada entre desenho e clique.
#define SB_X       (PANEL_W-10)
#define SB_W        5
#define SB_ARROW   12

void ChevronUp(const int cx,const int cy,const uint clr)
  {
   for(int i = 0; i < 4; ++i)
      g_canvas.FillRectangle(cx-3+i, cy+3-i, cx+3-i, cy+3-i, clr);
  }

void ChevronDown(const int cx,const int cy,const uint clr)
  {
   for(int i = 0; i < 4; ++i)
      g_canvas.FillRectangle(cx-3+i, cy+i, cx+3-i, cy+i, clr);
  }

//--- Trilho visivel e setas direcionais. So a alcinha era discreto demais para
//--- avisar que existe conteudo fora da vista; a seta acesa diz para que lado
//--- ainda da para ir, e a apagada diz que aquele lado acabou.
void DrawScrollbar(void)
  {
   int top = ContentTop(), bottom = ContentBottom();
   int viewH = bottom - top;
   if(g_contentH <= viewH)
      return;

   int maxScroll = g_contentH - viewH;
   int trackTop  = top + SB_ARROW;
   int trackBot  = bottom - SB_ARROW;
   int trackH    = trackBot - trackTop;

   RoundRect(SB_X, trackTop, SB_X+SB_W, trackBot, 2, T.lineSoft, T.ground);

   int thumbH = (int)MathMax(26, (double)trackH * viewH / g_contentH);
   int thumbY = trackTop + (int)((double)(trackH - thumbH) * g_scroll / maxScroll);
   RoundRect(SB_X, thumbY, SB_X+SB_W, thumbY+thumbH, 2, T.dim, T.lineSoft);

   int cx = SB_X + SB_W/2;
   ChevronUp  (cx, top + 4,     (g_scroll > 0)         ? T.accent : T.lineSoft);
   ChevronDown(cx, bottom - 11, (g_scroll < maxScroll) ? T.accent : T.lineSoft);
  }

//--- As setas tambem rolam ao clique: quarta entrada, para quem nao usa roda,
//--- nao arrasta e nao recorre ao teclado.
bool HandleScrollbarClick(const int lx,const int ly)
  {
   int top = ContentTop(), bottom = ContentBottom();
   if(g_contentH <= bottom - top)
      return false;
   if(lx < SB_X - 5 || lx > SB_X + SB_W + 5)
      return false;

   if(ly >= top && ly < top + SB_ARROW)
     {
      if(ScrollBy(-40)) Render();
      return true;
     }
   if(ly <= bottom && ly > bottom - SB_ARROW)
     {
      if(ScrollBy(40)) Render();
      return true;
     }
   return false;
  }

void DrawConfigContent(void)
  {
   int x1 = PAD, x2 = PANEL_W - PAD;
   int contentStart = ContentTop();
   int y = contentStart - g_scroll;
   g_editCount = 0;

   //--- VOLUME
   int gh = 26 + 42 + 42;
   RoundRect(x1, y, x2, y+gh, 8, T.surface, T.ground);
   Txt(x1+13, y+17, "VOLUME", T.dim, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   FieldRow(x1, x2, y+26,    "Lote fixo", "Min. 0,01 · passo 0,01", T.dim, g_editCount);
   FieldRow(x1, x2, y+26+42, "Slippage",  "Desvio maximo aceito",   T.dim, g_editCount);
   y += gh + 12;

   //--- STOPS
   gh = 26 + 42 + 42 + 30 + 30;
   RoundRect(x1, y, x2, y+gh, 8, T.surface, T.ground);
   Txt(x1+13, y+17, "STOPS", T.dim, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   FieldRow  (x1, x2, y+26,     "Stop Loss",   "Abaixo do minimo da corretora", T.bad, g_editCount);
   FieldRow  (x1, x2, y+26+42,  "Take Profit", "0 desativa",                    T.dim, g_editCount);
   g_toggleCount = 0;
   ToggleRow (x1, x2, y+26+84,  "Compensar spread no SL", g_toggleCount);
   ToggleRow (x1, x2, y+26+114, "Compensar spread no TP", g_toggleCount);
   y += gh + 12;

   //--- TIMEFRAME: exercita o combobox
   gh = 26 + 32;
   RoundRect(x1, y, x2, y+gh, 8, T.surface, T.ground);
   Txt(x1+13, y+17, "TIMEFRAME", T.dim, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   DrawComboClosed(x1, x2, y+26, "Timeframe operacional");
   y += gh + 12;

   //--- Bloco extra so para forcar rolagem
   gh = 26 + 30 + 30;
   RoundRect(x1, y, x2, y+gh, 8, T.surface, T.ground);
   Txt(x1+13, y+17, "AVANCADO", T.dim, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+41, "Role com roda, arrasto ou setas do teclado", T.muted, FONT_UI, 82, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+65, "Bloco extra para exercitar a rolagem", T.muted, FONT_UI, 82, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   y += gh;

   g_contentH = (y + g_scroll) - contentStart;
  }
//+------------------------------------------------------------------+
//| Campos nativos — criados apos o canvas para ficarem por cima      |
//+------------------------------------------------------------------+
//--- O canvas trabalha em ARGB (0xAARRGGBB); o tipo `color` do MQL5 e BGR.
//--- Sem esta troca, vermelho vira azul nos objetos nativos.
color ToChartColor(const uint argb)
  {
   int r = (int)((argb>>16)&0xFF), g = (int)((argb>>8)&0xFF), b = (int)(argb&0xFF);
   return (color)((b<<16)|(g<<8)|r);
  }

void MakeEdit(const string id,const int lx,const int ly,const string value,
              const uint borderClr,const uint textClr)
  {
   string n = g_prefix + id;
   ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, g_px + lx);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, g_py + ly);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, EDIT_W);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, EDIT_H);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, ToChartColor(T.raised));
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, ToChartColor(borderClr));
   ObjectSetInteger(0, n, OBJPROP_COLOR, ToChartColor(textClr));
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, n, OBJPROP_ALIGN, ALIGN_RIGHT);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_ZORDER, 100);
   ObjectSetString (0, n, OBJPROP_FONT, FONT_MONO);
   ObjectSetString (0, n, OBJPROP_TEXT, value);
  }

void DestroyEdits(void)
  {
   ObjectsDeleteAll(0, g_prefix + "edit_");
  }

void BuildEdits(void)
  {
   DestroyEdits();
   if(g_tab != 5 || g_minimized || g_editCount < 4)
      return;

   int ex = PANEL_W - PAD - 13 - EDIT_W;
   //--- So existe o campo que cabe inteiro na area util. Um campo parcialmente
   //--- fora seria desenhado inteiro pelo terminal, vazando do painel.
   if(EditVisible(g_editY[0])) MakeEdit("edit_lot",  ex, g_editY[0], "0.06", T.accent, T.fg);
   if(EditVisible(g_editY[1])) MakeEdit("edit_slip", ex, g_editY[1], "30",   T.line,   T.fg);
   if(EditVisible(g_editY[2])) MakeEdit("edit_sl",   ex, g_editY[2], "120",  T.bad,    T.bad);
   if(EditVisible(g_editY[3])) MakeEdit("edit_tp",   ex, g_editY[3], "0",    T.line,   T.fg);
  }

//+------------------------------------------------------------------+
void Render(void)
  {
   int h = g_minimized ? TITLEBAR_H : PANEL_H;

   if(!g_canvas.Resize(PANEL_W, h))
      return;

   ObjectSetInteger(0, g_canvasName, OBJPROP_XDISTANCE, g_px);
   ObjectSetInteger(0, g_canvasName, OBJPROP_YDISTANCE, g_py);

   g_canvas.Erase(T.ground);

   if(g_minimized)
      DrawTitlebar();
   else if(g_tab == 5)
     {
      //--- Ordem importa: o conteudo rolavel pode transbordar para cima e para
      //--- baixo, entao ele vem primeiro, as faixas de fora sao repintadas, e o
      //--- chrome fecha por cima. Assim nenhum recorte precisa ser calculado.
      DrawConfigContent();
      g_canvas.FillRectangle(0, 0, PANEL_W-1, ContentTop()-1, T.ground);
      g_canvas.FillRectangle(0, ContentBottom()+1, PANEL_W-1, PANEL_H-1, T.ground);
      DrawChrome(false, true);
      DrawConfigSubtabs();
      DrawConfigAlert();
      DrawScrollbar();
      DrawComboPopup();          // dropdown aberto cobre tudo, entao vem por ultimo
     }
   else
     {
      DrawChrome(true, false);
      DrawStatus();
     }

   if(!g_minimized)
      g_canvas.Rectangle(0, 0, PANEL_W-1, h-1, T.shell);

   g_canvas.Update(false);
   BuildEdits();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Interacao                                                         |
//+------------------------------------------------------------------+
void SetChartScroll(const bool on)
  {
   ChartSetInteger(0, CHART_MOUSE_SCROLL, on);
  }

bool InsidePanel(const int cx,const int cy)
  {
   int h = g_minimized ? TITLEBAR_H : PANEL_H;
   return (cx >= g_px && cx < g_px+PANEL_W && cy >= g_py && cy < g_py+h);
  }

void HandlePress(const int cx,const int cy)
  {
   int lx = cx - g_px, ly = cy - g_py;

   if(ly < TITLEBAR_H)
     {
      if(lx >= PANEL_W-40)
        {
         g_minimized = !g_minimized;
         Render();
         return;
        }
      if(lx >= PANEL_W-66 && lx < PANEL_W-40)
        {
         //--- escolha manual do tema; passa a mandar sobre a deteccao automatica
         g_userTheme = true;
         if(g_dark) ApplyLight(); else ApplyDark();
         Render();
         return;
        }
      g_dragging = true;
      g_dragDX = lx;
      g_dragDY = ly;
      return;
     }

   if(g_minimized) return;

   //--- Lista aberta captura o proximo clique, venha de onde vier.
   if(g_tab == 5 && HandleComboClick(lx, ly))
      return;

   if(ly >= HEADER_BOTTOM && ly < TABS_BOTTOM)
     {
      for(int i = 0; i < TAB_COUNT; ++i)
         if(lx >= g_tabX[i] && lx < g_tabX[i]+g_tabW[i])
           {
            if(g_tab != i) { g_tab = i; Render(); }
            return;
           }
      return;
     }

   if(g_tab == 5)
     {
      if(HandleScrollbarClick(lx, ly))
         return;

      int sy = TABS_BOTTOM + PAD;
      if(ly >= sy && ly < sy+26)
        {
         for(int i = 0; i < SUBTAB_COUNT; ++i)
            if(lx >= g_subX[i] && lx < g_subX[i]+g_subW[i])
              {
               if(g_subtab != i) { g_subtab = i; Render(); }
               return;
              }
         return;
        }

      //--- Area de clique um pouco maior que o desenho: o alvo tem 40x22 e
      //--- exigir precisao de pixel num toggle irrita mais do que ajuda.
      for(int t = 0; t < g_toggleCount; ++t)
         if(lx >= g_toggleX[t]-6 && lx < g_toggleX[t]+46 &&
            ly >= g_toggleY[t]-6 && ly < g_toggleY[t]+28 &&
            //--- toggle que rolou para fora da area util nao esta na tela
            g_toggleY[t] >= ContentTop() && g_toggleY[t]+22 <= ContentBottom())
           {
            g_toggleOn[t] = !g_toggleOn[t];
            Print("Toggle ", t, " agora: ", (g_toggleOn[t] ? "ON" : "OFF"));
            Render();
            return;
           }

      //--- Nenhum controle sob o cursor: o arrasto na area util rola o conteudo.
      //--- E o que atende touchpad, onde nao ha roda.
      //--- A faixa da barra fica de fora: ali o arrasto do conteudo iria para o
      //--- lado oposto do que se espera ao puxar uma barra de rolagem.
      if(ly >= ContentTop() && ly <= ContentBottom() && lx < SB_X - 5)
        {
         g_scrollDrag = true;
         g_scrollDragY = cy;
         g_scrollDragBase = g_scroll;
        }
     }
  }

void HandleScrollDrag(const int cy)
  {
   //--- Arrastar para cima leva o conteudo para cima, como no toque de um
   //--- celular: o dedo empurra o conteudo, nao a barra de rolagem.
   int target = g_scrollDragBase + (g_scrollDragY - cy);
   if(ScrollBy(target - g_scroll))
      Render();
  }

void HandleDrag(const int cx,const int cy)
  {
   int nx = cx - g_dragDX, ny = cy - g_dragDY;
   if(nx < 0) nx = 0;
   if(ny < 0) ny = 0;
   if(nx == g_px && ny == g_py) return;
   g_px = nx; g_py = ny;
   Render();
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   ResolveTheme();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartSetInteger(0, CHART_EVENT_MOUSE_WHEEL, true);
   g_origScroll = (bool)ChartGetInteger(0, CHART_MOUSE_SCROLL);

   g_canvasName = g_prefix + "canvas";
   if(!g_canvas.CreateBitmapLabel(0, 0, g_canvasName, g_px, g_py, PANEL_W, PANEL_H,
                                  COLOR_FORMAT_ARGB_NORMALIZE))
     {
      Print("Prototipo: falha ao criar o canvas.");
      return INIT_FAILED;
     }
   ObjectSetInteger(0, g_canvasName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_canvasName, OBJPROP_ZORDER, 0);

   Render();
   Print("Prototipo ativo. Tema: ", (g_dark ? "escuro" : "claro"),
         ". Arraste pelo cabecalho; o traco no canto minimiza.");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   SetChartScroll(g_origScroll);
   DestroyEdits();
   g_canvas.Destroy();
   ObjectsDeleteAll(0, g_prefix);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      if(inp_Theme == PROTO_THEME_AUTO && !g_userTheme)
        {
         bool wasDark = g_dark;
         ResolveTheme();
         if(wasDark != g_dark) Render();
        }
      return;
     }

   if(id == CHARTEVENT_MOUSE_WHEEL)
     {
      //--- lparam empacota X na palavra baixa e Y na alta; dparam traz o delta.
      int cx = (int)(short)(lparam & 0xFFFF);
      int cy = (int)(short)((lparam >> 16) & 0xFFFF);
      if(g_minimized || g_tab != 5 || !InsidePanel(cx, cy))
         return;

      if(ScrollBy((dparam > 0) ? -40 : 40))
         Render();
      return;
     }

   if(id == CHARTEVENT_KEYDOWN)
     {
      //--- So responde com o cursor sobre o painel: senao o EA roubaria as setas
      //--- de quem esta navegando o grafico.
      if(g_minimized || g_tab != 5 || !g_overPanel)
         return;

      int viewH = ContentBottom() - ContentTop();
      int step = 0;
      switch((int)lparam)
        {
         case VK_UP_:    step = -40;        break;
         case VK_DOWN_:  step =  40;        break;
         case VK_PRIOR_: step = -viewH;     break;
         case VK_NEXT_:  step =  viewH;     break;
         case VK_HOME_:  step = -g_contentH; break;
         case VK_END_:   step =  g_contentH; break;
         default: return;
        }
      if(ScrollBy(step))
         Render();
      return;
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      int cx = (int)lparam, cy = (int)dparam;
      bool down = (StringToInteger(sparam) & 1) != 0;

      //--- o scroll do grafico e suprimido sobre o painel; sem isso o
      //--- arrasto move o grafico em vez do painel.
      bool over = InsidePanel(cx, cy);
      if(over != g_overPanel)
        {
         SetChartScroll(over ? false : g_origScroll);
         g_overPanel = over;
        }

      if(down && !g_mouseDown && over)
         HandlePress(cx, cy);
      else if(down && g_dragging)
         HandleDrag(cx, cy);
      else if(down && g_scrollDrag)
         HandleScrollDrag(cy);

      if(!down)
        {
         g_dragging   = false;
         g_scrollDrag = false;
        }

      g_mouseDown = down;
      return;
     }

   if(id == CHARTEVENT_OBJECT_ENDEDIT && StringFind(sparam, g_prefix + "edit_") == 0)
     {
      Print("Campo ", sparam, " agora vale: ", ObjectGetString(0, sparam, OBJPROP_TEXT));
      return;
     }
  }
//+------------------------------------------------------------------+

void OnTick(void) { }
