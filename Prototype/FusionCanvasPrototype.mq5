//+------------------------------------------------------------------+
//| FusionCanvasPrototype.mq5                                        |
//| Prototipo descartavel: valida uma GUI do Fusion desenhada em      |
//| CCanvas, com campos de digitacao nativos sobrepostos.             |
//|                                                                   |
//| NAO faz parte do EA. Nao opera, nao le perfil, nao toca em ordem. |
//| Existe para responder tres perguntas antes de qualquer decisao:   |
//|   1. o visual do conceito se sustenta desenhado pelo terminal?    |
//|   2. OBJ_EDIT fica acima do canvas e aceita digitacao?            |
//|   3. clique em alvo desenhado (aba) funciona sem objeto proprio?  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "1.058"
#property strict

#include <Canvas\Canvas.mqh>

//+------------------------------------------------------------------+
//| Paleta (ARGB). Espelha o conceito aprovado.                       |
//+------------------------------------------------------------------+
//--- Canvas.mqh ja define ARGB; usamos nome proprio para nao colidir.
#define OPAQUE(r,g,b) ((uint)(0xFF000000|((uint)(r)<<16)|((uint)(g)<<8)|(uint)(b)))

#define C_GROUND      OPAQUE( 15, 19, 25)
#define C_SURFACE     OPAQUE( 23, 28, 36)
#define C_RAISED      OPAQUE( 30, 36, 46)
#define C_LINE        OPAQUE( 38, 46, 58)
#define C_LINE_SOFT   OPAQUE( 31, 38, 48)
#define C_FG          OPAQUE(228,233,240)
#define C_MUTED       OPAQUE(125,136,153)
#define C_DIM         OPAQUE( 90,101,119)

#define C_ACCENT      OPAQUE( 62,159,224)
#define C_ACCENT_STR  OPAQUE( 95,180,236)
#define C_ACCENT_DIM  OPAQUE( 35, 68, 95)

#define C_GOOD        OPAQUE( 47,191,113)
#define C_GOOD_DIM    OPAQUE( 22, 53, 42)
#define C_BAD         OPAQUE(229, 72, 77)
#define C_BAD_DIM     OPAQUE( 58, 29, 34)
#define C_WARN        OPAQUE(245,165, 36)
#define C_WARN_DIM    OPAQUE( 58, 45, 20)

#define C_BTN_GOOD_TX OPAQUE(  6, 24, 15)
#define C_BTN_ACC_TX  OPAQUE(  4, 18, 28)

//+------------------------------------------------------------------+
//| Geometria — mesmas medidas do painel atual                        |
//+------------------------------------------------------------------+
#define PANEL_X        10
#define PANEL_Y        20
#define PANEL_W       590
#define PANEL_H       626

#define TITLEBAR_H     34
#define HEADER_BOTTOM 134
#define TABS_H         30
#define TABS_BOTTOM   (HEADER_BOTTOM + TABS_H)
#define PAD            14

#define FONT_UI       "Segoe UI"
#define FONT_MONO     "Consolas"

#define FW_NORMAL_    400
#define FW_SEMI       600
#define FW_BOLD_      700

#define TAB_COUNT       6
#define SUBTAB_COUNT    5

//+------------------------------------------------------------------+
//| Estado do prototipo                                               |
//+------------------------------------------------------------------+
CCanvas  g_canvas;
string   g_prefix   = "FusProto_";
int      g_tab      = 0;          // 0=STATUS ... 5=CONFIG
int      g_subtab   = 0;
bool     g_mouseDown = false;
bool     g_editsUp  = false;

string   g_tabNames[TAB_COUNT]      = {"STATUS","RESULTS","STRATS","FILTERS","PERFIS","CONFIG"};
int      g_tabX[TAB_COUNT];
int      g_tabW[TAB_COUNT];
string   g_subNames[SUBTAB_COUNT]   = {"LOTE","SL/TP","TP PARCIAL","BREAKEVEN","TRAILING"};
int      g_subX[SUBTAB_COUNT];
int      g_subW[SUBTAB_COUNT];

//+------------------------------------------------------------------+
//| Helpers de desenho                                                |
//+------------------------------------------------------------------+
void SetFont(const string name,const int pt10,const int weight)
  {
   g_canvas.FontSet(name, -pt10, weight);
  }

//--- Mistura duas cores opacas por cobertura (0..1). Usado para
//--- suavizar os cantos arredondados, que o CCanvas nao antialiasa.
uint Blend(const uint fg,const uint bg,const double k)
  {
   double t = (k < 0.0) ? 0.0 : ((k > 1.0) ? 1.0 : k);
   int fr = (int)((fg>>16)&0xFF), fgn = (int)((fg>>8)&0xFF), fb = (int)(fg&0xFF);
   int br = (int)((bg>>16)&0xFF), bgn = (int)((bg>>8)&0xFF), bb = (int)(bg&0xFF);
   int r = (int)(br + (fr-br)*t);
   int g = (int)(bgn + (fgn-bgn)*t);
   int b = (int)(bb + (fb-bb)*t);
   return OPAQUE(r,g,b);
  }

//--- Retangulo de cantos arredondados com bordas suavizadas.
void RoundRect(const int x1,const int y1,const int x2,const int y2,
               const int r,const uint clr,const uint bg)
  {
   if(r <= 0)
     {
      g_canvas.FillRectangle(x1,y1,x2,y2,clr);
      return;
     }

   g_canvas.FillRectangle(x1+r, y1,     x2-r, y2,     clr);
   g_canvas.FillRectangle(x1,   y1+r,   x1+r, y2-r,   clr);
   g_canvas.FillRectangle(x2-r, y1+r,   x2,   y2-r,   clr);

   for(int cy = 0; cy < 4; ++cy)
     {
      int cx0 = (cy == 0 || cy == 2) ? x1+r : x2-r;
      int cy0 = (cy < 2) ? y1+r : y2-r;
      for(int px = -r; px <= r; ++px)
        {
         for(int py = -r; py <= r; ++py)
           {
            if((cy == 0 || cy == 2) && px > 0) continue;
            if((cy == 1 || cy == 3) && px < 0) continue;
            if(cy < 2 && py > 0) continue;
            if(cy >= 2 && py < 0) continue;

            double d = MathSqrt((double)px*px + (double)py*py);
            double cov = (double)r - d + 0.5;
            if(cov <= 0.0) continue;
            uint c = (cov >= 1.0) ? clr : Blend(clr, bg, cov);
            g_canvas.PixelSet(cx0+px, cy0+py, c);
           }
        }
     }
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

//--- Pill de estado: ponto + rotulo, fundo arredondado.
void Pill(const int x,const int y,const string label,const uint fg,const uint bg,const uint under)
  {
   int tw = TxtW(label, FONT_UI, 80, FW_BOLD_);
   int w  = tw + 30;
   int h  = 20;
   RoundRect(x, y, x+w, y+h, h/2, bg, under);
   g_canvas.FillCircle(x+12, y+h/2, 3, fg);
   Txt(x+21, y+h/2, label, fg, FONT_UI, 80, FW_BOLD_, TA_LEFT|TA_VCENTER);
  }

//+------------------------------------------------------------------+
//| Cabecalho e abas (comuns as duas telas)                           |
//+------------------------------------------------------------------+
void DrawChrome(const bool running,const bool dirty)
  {
   g_canvas.Erase(C_GROUND);

   //--- barra de titulo
   g_canvas.FillRectangle(0, 0, PANEL_W-1, TITLEBAR_H-1, C_SURFACE);
   HLine(0, PANEL_W-1, TITLEBAR_H-1, C_LINE);
   Txt(14, 17, "EP Fusion", C_FG, FONT_UI, 95, FW_SEMI, TA_LEFT|TA_VCENTER);
   int bw = TxtW("EP Fusion", FONT_UI, 95, FW_SEMI);
   Txt(14+bw+8, 18, "1.058", C_DIM, FONT_MONO, 80, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(PANEL_W-16, 17, "—", C_DIM, FONT_UI, 95, FW_NORMAL_, TA_RIGHT|TA_VCENTER);

   //--- contexto
   Txt(PAD, 52, "BTCUSD", C_FG, FONT_UI, 110, FW_SEMI, TA_LEFT|TA_VCENTER);
   int sw = TxtW("BTCUSD", FONT_UI, 110, FW_SEMI);
   RoundRect(PAD+sw+9, 44, PAD+sw+9+30, 61, 4, C_RAISED, C_GROUND);
   Txt(PAD+sw+24, 52, "M1", C_MUTED, FONT_MONO, 80, FW_NORMAL_, TA_CENTER|TA_VCENTER);

   if(running)
      Pill(PANEL_W-PAD-104, 42, "OPERANDO", C_GOOD, C_GOOD_DIM, C_GROUND);
   else
      Pill(PANEL_W-PAD-94,  42, "PAUSADO",  C_WARN, C_WARN_DIM, C_GROUND);

   //--- perfil
   Txt(PAD, 74, "Perfil", C_DIM, FONT_UI, 85, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   int pw = TxtW("Perfil", FONT_UI, 85, FW_NORMAL_);
   Txt(PAD+pw+8, 74, "BTCUSD", C_ACCENT_STR, FONT_UI, 85, FW_SEMI, TA_LEFT|TA_VCENTER);
   if(dirty)
     {
      int vw = TxtW("BTCUSD", FONT_UI, 85, FW_SEMI);
      Txt(PAD+pw+vw+16, 74, "· alteracoes nao salvas", C_DIM, FONT_UI, 85, FW_NORMAL_, TA_LEFT|TA_VCENTER);
     }

   //--- acoes
   int bx = PAD, byy = 90, bh = 30;
   int bwid = (PANEL_W - 2*PAD - 16) / 3;

   if(running)
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, C_SURFACE, C_GROUND);
      Txt(bx+bwid/2, byy+bh/2, "OPERANDO", C_DIM, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, C_GOOD, C_GROUND);
      Txt(bx+bwid/2, byy+bh/2, "INICIAR", C_BTN_GOOD_TX, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }

   bx += bwid + 8;
   if(dirty)
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, C_ACCENT, C_GROUND);
      Txt(bx+bwid/2, byy+bh/2, "SALVAR", C_BTN_ACC_TX, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundRect(bx, byy, bx+bwid, byy+bh, 6, C_LINE_SOFT, C_GROUND);
      RoundRect(bx+1, byy+1, bx+bwid-1, byy+bh-1, 5, C_GROUND, C_LINE_SOFT);
      Txt(bx+bwid/2, byy+bh/2, "SALVAR", C_MUTED, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);
     }

   bx += bwid + 8;
   RoundRect(bx, byy, bx+bwid, byy+bh, 6, dirty ? OPAQUE(74,58,24) : C_LINE_SOFT, C_GROUND);
   RoundRect(bx+1, byy+1, bx+bwid-1, byy+bh-1, 5, C_GROUND, dirty ? OPAQUE(74,58,24) : C_LINE_SOFT);
   Txt(bx+bwid/2, byy+bh/2, "CANCELAR", dirty ? C_WARN : C_MUTED, FONT_UI, 85, FW_BOLD_, TA_CENTER|TA_VCENTER);

   HLine(0, PANEL_W-1, HEADER_BOTTOM-1, C_LINE_SOFT);

   //--- abas
   int tx = 10;
   for(int i = 0; i < TAB_COUNT; ++i)
     {
      int w = TxtW(g_tabNames[i], FONT_UI, 82, FW_SEMI) + 22;
      g_tabX[i] = tx;
      g_tabW[i] = w;
      bool on = (i == g_tab);
      Txt(tx + w/2, HEADER_BOTTOM + TABS_H/2, g_tabNames[i],
          on ? C_FG : C_DIM, FONT_UI, 82, FW_SEMI, TA_CENTER|TA_VCENTER);
      if(on)
         g_canvas.FillRectangle(tx+4, TABS_BOTTOM-2, tx+w-4, TABS_BOTTOM-1, C_ACCENT);
      tx += w + 2;
     }
   HLine(0, PANEL_W-1, TABS_BOTTOM-1, C_LINE);
  }

//+------------------------------------------------------------------+
//| Tela STATUS                                                       |
//+------------------------------------------------------------------+
void DrawStatus(void)
  {
   int x1 = PAD, x2 = PANEL_W - PAD;
   int y  = TABS_BOTTOM + PAD;

   //--- cartao de destaque
   RoundRect(x1, y, x2, y+56, 8, C_SURFACE, C_GROUND);
   Txt(x1+14, y+18, "ESTADO", C_DIM, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x1+14, y+38, "Rodando", C_FG, FONT_UI, 150, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x2-14, y+18, "POSICAO", C_DIM, FONT_UI, 78, FW_SEMI, TA_RIGHT|TA_VCENTER);
   Txt(x2-14, y+38, "BUY 0.06", C_GOOD, FONT_MONO, 115, FW_SEMI, TA_RIGHT|TA_VCENTER);
   y += 56 + 10;

   //--- blocos
   string tk[4] = {"ESTRATEGIAS","FILTROS","MAGIC","TF OPER."};
   string tv[4] = {"1","0","1","M1"};
   int tw = (x2 - x1 - 24) / 4;
   for(int i = 0; i < 4; ++i)
     {
      int bx = x1 + i*(tw+8);
      RoundRect(bx, y, bx+tw, y+54, 7, C_SURFACE, C_GROUND);
      Txt(bx+11, y+17, tk[i], C_DIM, FONT_UI, 75, FW_SEMI, TA_LEFT|TA_VCENTER);
      bool mono = (i >= 2);
      Txt(bx+11, y+37, tv[i], (i==1) ? C_DIM : C_FG,
          mono ? FONT_MONO : FONT_UI, mono ? 105 : 120, FW_SEMI, TA_LEFT|TA_VCENTER);
     }
   y += 54 + 12;

   //--- linhas
   string rk[5] = {"Responsavel","Conflito","Resultado do dia","Trades hoje","Drawdown"};
   string rv[5] = {"MA Cross","Prioridade","+128,40","3","—"};
   for(int i = 0; i < 5; ++i)
     {
      Txt(x1+2,  y+15, rk[i], C_MUTED, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
      bool mono = (i >= 2);
      uint vc = (i == 2) ? C_GOOD : C_FG;
      Txt(x2-2,  y+15, rv[i], vc, mono ? FONT_MONO : FONT_UI, mono ? 95 : 88, FW_SEMI, TA_RIGHT|TA_VCENTER);
      HLine(x1, x2, y+31, C_LINE_SOFT);
      y += 32;
     }

   //--- aviso ancorado ao rodape
   int ay = PANEL_H - PAD - 58;
   RoundRect(x1, ay, x2, ay+58, 8, C_WARN_DIM, C_GROUND);
   g_canvas.FillRectangle(x1+12, ay+13, x1+14, ay+45, C_WARN);
   Txt(x1+24, ay+21, "SESSAO", C_WARN, FONT_UI, 78, FW_BOLD_, TA_LEFT|TA_VCENTER);
   Txt(x1+24, ay+39, "Janela operacional encerra as 18:00. Entradas novas bloqueiam 5 min antes.",
       OPAQUE(216,201,166), FONT_UI, 82, FW_NORMAL_, TA_LEFT|TA_VCENTER);
  }

//+------------------------------------------------------------------+
//| Tela CONFIG > RISK                                                |
//+------------------------------------------------------------------+
void DrawConfig(void)
  {
   int x1 = PAD, x2 = PANEL_W - PAD;
   int y  = TABS_BOTTOM + PAD;

   //--- subabas
   int sx = x1;
   for(int i = 0; i < SUBTAB_COUNT; ++i)
     {
      int w = TxtW(g_subNames[i], FONT_UI, 78, FW_BOLD_) + 22;
      g_subX[i] = sx;
      g_subW[i] = w;
      bool on  = (i == g_subtab);
      bool err = (i == 1);
      uint bgc = on ? C_ACCENT_DIM : C_SURFACE;
      RoundRect(sx, y, sx+w, y+26, 5, bgc, C_GROUND);
      if(on)
        {
         RoundRect(sx, y, sx+w, y+26, 5, C_ACCENT, C_GROUND);
         RoundRect(sx+1, y+1, sx+w-1, y+25, 4, C_ACCENT_DIM, C_ACCENT);
        }
      else if(err)
        {
         RoundRect(sx, y, sx+w, y+26, 5, OPAQUE(74,34,38), C_GROUND);
         RoundRect(sx+1, y+1, sx+w-1, y+25, 4, C_SURFACE, OPAQUE(74,34,38));
        }
      Txt(sx+w/2, y+13, g_subNames[i],
          on ? C_ACCENT_STR : (err ? C_BAD : C_DIM), FONT_UI, 78, FW_BOLD_, TA_CENTER|TA_VCENTER);
      sx += w + 6;
     }
   y += 26 + 12;

   //--- grupo VOLUME (2 campos digitaveis)
   RoundRect(x1, y, x2, y+96, 8, C_SURFACE, C_GROUND);
   Txt(x1+13, y+17, "VOLUME", C_DIM, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+42, "Lote fixo", C_FG, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+58, "Min. 0,01 · passo 0,01", C_DIM, FONT_UI, 75, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+78, "Slippage", C_FG, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   y += 96 + 12;

   //--- grupo STOPS (toggles desenhados)
   RoundRect(x1, y, x2, y+118, 8, C_SURFACE, C_GROUND);
   Txt(x1+13, y+17, "STOPS", C_DIM, FONT_UI, 78, FW_SEMI, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+42, "Stop Loss", C_FG, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+58, "Abaixo do minimo da corretora", C_BAD, FONT_UI, 75, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+80, "Compensar spread no SL", C_FG, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+13, y+102,"Compensar spread no TP", C_FG, FONT_UI, 88, FW_NORMAL_, TA_LEFT|TA_VCENTER);

   //--- toggle ligado
   int tgx = x2 - 54, tgy = y + 70;
   RoundRect(tgx, tgy, tgx+40, tgy+22, 11, C_GOOD, C_SURFACE);
   g_canvas.FillCircle(tgx+29, tgy+11, 9, C_GROUND);
   //--- toggle desligado
   tgy = y + 92;
   RoundRect(tgx, tgy, tgx+40, tgy+22, 11, OPAQUE(48,57,72), C_SURFACE);
   g_canvas.FillCircle(tgx+11, tgy+11, 9, C_GROUND);

   //--- aviso de validacao
   int ay = PANEL_H - PAD - 62;
   RoundRect(x1, ay, x2, ay+62, 8, C_BAD_DIM, C_GROUND);
   g_canvas.FillRectangle(x1+12, ay+13, x1+14, ay+49, C_BAD);
   Txt(x1+24, ay+21, "SL/TP", C_BAD, FONT_UI, 78, FW_BOLD_, TA_LEFT|TA_VCENTER);
   Txt(x1+24, ay+40, "Stop Loss de 120 pts esta abaixo do minimo exigido pela",
       OPAQUE(227,185,187), FONT_UI, 82, FW_NORMAL_, TA_LEFT|TA_VCENTER);
   Txt(x1+24, ay+54, "corretora (180 pts) para BTCUSD.",
       OPAQUE(227,185,187), FONT_UI, 82, FW_NORMAL_, TA_LEFT|TA_VCENTER);
  }

//+------------------------------------------------------------------+
//| Campos de digitacao nativos, sobrepostos ao canvas.               |
//| Criados DEPOIS do bitmap: no MT5 a ordem de desenho e a ordem de  |
//| criacao, e o OBJPROP_ZORDER so afeta o roteamento do clique.      |
//+------------------------------------------------------------------+
void MakeEdit(const string id,const int lx,const int ly,const int w,const int h,
              const string value,const uint borderClr,const uint textClr)
  {
   string n = g_prefix + id;
   ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, PANEL_X + lx);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, PANEL_Y + ly);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, (color)C'30,36,46');
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, (color)borderClr);
   ObjectSetInteger(0, n, OBJPROP_COLOR, (color)textClr);
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
   g_editsUp = false;
  }

void BuildEdits(void)
  {
   DestroyEdits();
   if(g_tab != 5)
      return;

   int x2 = PANEL_W - PAD;
   int y  = TABS_BOTTOM + PAD + 26 + 12;   // topo do grupo VOLUME

   MakeEdit("edit_lot",  x2-138, y+34, 128, 26, "0.06", C_ACCENT, OPAQUE(228,233,240));
   MakeEdit("edit_slip", x2-138, y+66, 128, 26, "30",   C_LINE,   OPAQUE(228,233,240));

   y += 96 + 12;                            // topo do grupo STOPS
   MakeEdit("edit_sl",   x2-138, y+30, 128, 26, "120",  C_BAD,    OPAQUE(229,72,77));
   MakeEdit("edit_tp",   x2-138, y+58, 128, 26, "0",    C_LINE,   OPAQUE(228,233,240));

   g_editsUp = true;
  }

//+------------------------------------------------------------------+
//| Render                                                            |
//+------------------------------------------------------------------+
void Render(void)
  {
   bool config = (g_tab == 5);
   DrawChrome(!config, config);
   if(config)
      DrawConfig();
   else
      DrawStatus();

   g_canvas.Update(false);
   BuildEdits();                 // recriados apos o canvas: ficam por cima
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Hit-test: alvos desenhados nao sao objetos, entao o clique vem    |
//| por CHARTEVENT_MOUSE_MOVE e e resolvido por coordenada.           |
//+------------------------------------------------------------------+
bool HandleClick(const int cx,const int cy)
  {
   int lx = cx - PANEL_X;
   int ly = cy - PANEL_Y;
   if(lx < 0 || ly < 0 || lx >= PANEL_W || ly >= PANEL_H)
      return false;

   if(ly >= HEADER_BOTTOM && ly < TABS_BOTTOM)
     {
      for(int i = 0; i < TAB_COUNT; ++i)
        {
         if(lx >= g_tabX[i] && lx < g_tabX[i] + g_tabW[i])
           {
            if(g_tab != i) { g_tab = i; Render(); }
            return true;
           }
        }
      return true;
     }

   if(g_tab == 5)
     {
      int sy = TABS_BOTTOM + PAD;
      if(ly >= sy && ly < sy + 26)
        {
         for(int i = 0; i < SUBTAB_COUNT; ++i)
           {
            if(lx >= g_subX[i] && lx < g_subX[i] + g_subW[i])
              {
               if(g_subtab != i) { g_subtab = i; Render(); }
               return true;
              }
           }
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   if(!g_canvas.CreateBitmapLabel(0, 0, g_prefix + "canvas",
                                  PANEL_X, PANEL_Y, PANEL_W, PANEL_H,
                                  COLOR_FORMAT_ARGB_NORMALIZE))
     {
      Print("Prototipo: falha ao criar o canvas.");
      return INIT_FAILED;
     }

   ObjectSetInteger(0, g_prefix + "canvas", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_prefix + "canvas", OBJPROP_ZORDER, 0);

   Render();
   Print("Prototipo de GUI em canvas ativo. Clique nas abas; CONFIG tem campos digitaveis.");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DestroyEdits();
   g_canvas.Destroy();
   ObjectsDeleteAll(0, g_prefix);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      bool down = (StringToInteger(sparam) & 1) != 0;
      if(down && !g_mouseDown)
         HandleClick((int)lparam, (int)dparam);
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
