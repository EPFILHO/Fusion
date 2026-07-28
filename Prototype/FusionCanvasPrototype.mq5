//+------------------------------------------------------------------+
//| FusionCanvasPrototype.mq5                                        |
//| Prototipo descartavel da GUI 2.0 desenhada em CCanvas.            |
//| NAO faz parte do EA: nao opera, nao le perfil, nao toca em ordem. |
//|                                                                   |
//| Terceira rodada — aplica as decisoes de desenho ja aprovadas:     |
//|   - paleta revista (dois fundos, semanticas dentro do sistema)    |
//|   - abas em fichario, com a linha do estado atravessando a largura|
//|   - trilho vertical no terceiro nivel                             |
//|   - rotulos em portugues, ingles so no jargao de mercado          |
//|   - um unico botao preenchido por vez                             |
//|   - altura calculada no anexo, nao elastica durante o uso         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "2.000"
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
   uint ground, surface, inset, line, soft;
   uint fg, muted, faint;
   uint acc, accs, accd;
   uint good, gdim, bad, bdim, warn, wdim;
   uint onGood, onAcc;
   uint shell;
  };

STheme T;
bool   g_dark = true;
bool   g_userTheme = false;

void ApplyDark(void)
  {
   T.ground=OPAQUE(11,15,20);    T.surface=OPAQUE(21,26,34);
   T.inset =OPAQUE(11,15,20);    T.line   =OPAQUE(40,50,63);
   T.soft  =OPAQUE(27,34,43);
   T.fg    =OPAQUE(232,237,244); T.muted  =OPAQUE(147,160,178);
   T.faint =OPAQUE(95,107,122);
   T.acc   =OPAQUE(74,150,214);  T.accs   =OPAQUE(124,184,232);
   T.accd  =OPAQUE(27,52,72);
   T.good  =OPAQUE(53,184,122);  T.gdim   =OPAQUE(18,46,35);
   T.bad   =OPAQUE(222,87,96);   T.bdim   =OPAQUE(51,25,29);
   T.warn  =OPAQUE(217,152,47);  T.wdim   =OPAQUE(48,37,17);
   T.onGood=OPAQUE(4,21,12);     T.onAcc  =OPAQUE(4,18,28);
   T.shell =OPAQUE(56,66,79);
   g_dark = true;
  }

void ApplyLight(void)
  {
   //--- No claro as semanticas precisam ser MAIS ESCURAS, nao a mesma cor do
   //--- tema escuro: um verde que brilha sobre preto fica ilegivel sobre branco.
   T.ground=OPAQUE(239,242,247); T.surface=OPAQUE(255,255,255);
   T.inset =OPAQUE(244,246,250); T.line   =OPAQUE(213,220,230);
   T.soft  =OPAQUE(231,236,243);
   T.fg    =OPAQUE(19,26,36);    T.muted  =OPAQUE(84,98,122);
   T.faint =OPAQUE(138,150,168);
   T.acc   =OPAQUE(42,111,176);  T.accs   =OPAQUE(30,90,147);
   T.accd  =OPAQUE(221,234,247);
   T.good  =OPAQUE(23,134,76);   T.gdim   =OPAQUE(223,243,231);
   T.bad   =OPAQUE(192,53,61);   T.bdim   =OPAQUE(251,231,232);
   T.warn  =OPAQUE(156,107,16);  T.wdim   =OPAQUE(250,240,218);
   T.onGood=OPAQUE(255,255,255); T.onAcc  =OPAQUE(255,255,255);
   T.shell =OPAQUE(198,208,222);
   g_dark = false;
  }

void ResolveTheme(void)
  {
   if(inp_Theme == PROTO_THEME_DARK)  { ApplyDark();  return; }
   if(inp_Theme == PROTO_THEME_LIGHT) { ApplyLight(); return; }

   color bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   int r=(int)(bg & 0xFF), g=(int)((bg>>8)&0xFF), b=(int)((bg>>16)&0xFF);
   double lum = (0.2126*r + 0.7152*g + 0.0722*b) / 255.0;
   if(lum < 0.45) ApplyLight(); else ApplyDark();
  }

//+------------------------------------------------------------------+
//| Geometria                                                         |
//+------------------------------------------------------------------+
#define PANEL_W        590
#define PANEL_H_MIN    560
#define PANEL_H_MAX    900
#define TITLEBAR_H      32
#define HEADER_BOTTOM  136
#define F1_H            30
#define F1_BOTTOM      (HEADER_BOTTOM + F1_H)
#define F2_H            26
#define PAD             13
#define EDIT_W         112
#define EDIT_H          26
#define RAIL_W         136
#define RAIL_ROW        26

#define FONT_UI   "Segoe UI"
#define FONT_MONO "Consolas"
#define FW_NORMAL_ 400
#define FW_SEMI    600
#define FW_BOLD_   700

#define TAB_COUNT    6
#define CFG_COUNT    4
#define RAIL_MAX     7

CCanvas g_canvas;
string  g_prefix = "FusProto_";
string  g_canvasName;
int     g_px = 10, g_py = 20;
int     g_ph = 700;                 // altura decidida no anexo
int     g_tab = 5, g_cfg = 1, g_rail = 5;
bool    g_minimized = false;
bool    g_dirty = true;             // ha alteracoes nao salvas

string  g_tabNames[TAB_COUNT] = {"Status","Resultados","Estrategias","Filtros","Perfis","Config"};
int     g_tabX[TAB_COUNT], g_tabW[TAB_COUNT];
string  g_cfgNames[CFG_COUNT] = {"Risco","Protecao","Sistema","Visual"};
int     g_cfgX[CFG_COUNT], g_cfgW[CFG_COUNT];

string  g_railRisco[5]  = {"Lote","SL/TP","TP Parcial","BreakEven","Trailing"};
string  g_railProt[7]   = {"Geral","Spread/Lado","Sessao","Noticias","Limites Diarios","Drawdown","Sequencias"};
int     g_railY[RAIL_MAX], g_railCount = 0;

//--- estado de interacao
bool g_mouseDown=false, g_dragging=false, g_scrollDrag=false, g_overPanel=false;
int  g_dragDX=0, g_dragDY=0, g_scrollDragY=0, g_scrollDragBase=0;
bool g_origScroll=true;
int  g_scroll=0, g_contentH=0, g_alertH=0;

//--- controles do conteudo
int  g_editY[4]; int g_editCount=0;
#define TOGGLE_COUNT 2
bool g_toggleOn[TOGGLE_COUNT]={true,false};
int  g_toggleX[TOGGLE_COUNT], g_toggleY[TOGGLE_COUNT], g_toggleCount=0;
#define COMBO_ITEMS 6
string g_comboItems[COMBO_ITEMS]={"M1","M5","M15","M30","H1","H4"};
int  g_comboIndex=0; bool g_comboOpen=false;
int  g_comboX=0, g_comboY=0, g_comboW=0;
int  g_profSel = 0;

//--- Grade de cores. O MQL5 nao expoe o seletor do Windows (so via DLL, que
//--- exige permissao do usuario e nao cabe num EA distribuido). No canvas a
//--- grade e melhor de qualquer forma: uma escolha em vez de onze cliques
//--- ciclando a paleta, que e como o painel atual funciona.
#define SWATCH_COUNT 12
uint g_swatches[SWATCH_COUNT] =
  {
   OPAQUE(0,230,118),  OPAQUE(0,137,71),   OPAQUE(255,82,82),  OPAQUE(176,0,32),
   OPAQUE(233,30,99),  OPAQUE(41,121,255), OPAQUE(26,35,126),  OPAQUE(255,214,0),
   OPAQUE(255,171,0),  OPAQUE(0,229,255),  OPAQUE(255,109,0),  OPAQUE(236,239,241)
  };
int  g_colorSel[3] = {0,2,5};
int  g_colorOpen = -1;               // qual seletor esta aberto
int  g_colorX[3], g_colorY[3];
int  g_colorCount = 0;

//--- barra de rolagem: geometria publicada pelo desenho
int  g_thumbY=0, g_thumbH=0, g_trackTop=0, g_trackH=0;
bool g_barDrag=false; int g_barDragY=0, g_barDragBase=0;

#define VK_PRIOR_ 33
#define VK_NEXT_  34
#define VK_HOME_  36
#define VK_END_   35
#define VK_UP_    38
#define VK_DOWN_  40

//+------------------------------------------------------------------+
//| Desenho — primitivas                                              |
//+------------------------------------------------------------------+
void SetFont(const string n,const int pt10,const int w) { g_canvas.FontSet(n, -pt10, w); }

uint Blend(const uint fg,const uint bg,const double k)
  {
   double t = (k<0.0)?0.0:((k>1.0)?1.0:k);
   int fr=(int)((fg>>16)&0xFF), fgn=(int)((fg>>8)&0xFF), fb=(int)(fg&0xFF);
   int br=(int)((bg>>16)&0xFF), bgn=(int)((bg>>8)&0xFF), bb=(int)(bg&0xFF);
   return OPAQUE((int)(br+(fr-br)*t),(int)(bgn+(fgn-bgn)*t),(int)(bb+(fb-bb)*t));
  }

void RoundRect(const int x1,const int y1,const int x2,const int y2,
               const int r,const uint clr,const uint bg)
  {
   if(r<=0) { g_canvas.FillRectangle(x1,y1,x2,y2,clr); return; }
   g_canvas.FillRectangle(x1+r,y1,  x2-r,y2,  clr);
   g_canvas.FillRectangle(x1,  y1+r,x1+r,y2-r,clr);
   g_canvas.FillRectangle(x2-r,y1+r,x2,  y2-r,clr);
   for(int c=0;c<4;++c)
     {
      int cx0=(c==0||c==2)?x1+r:x2-r, cy0=(c<2)?y1+r:y2-r;
      for(int px=-r;px<=r;++px)
         for(int py=-r;py<=r;++py)
           {
            if((c==0||c==2)&&px>0) continue;
            if((c==1||c==3)&&px<0) continue;
            if(c<2&&py>0) continue;
            if(c>=2&&py<0) continue;
            double d=MathSqrt((double)px*px+(double)py*py);
            double cov=(double)r-d+0.5;
            if(cov<=0.0) continue;
            g_canvas.PixelSet(cx0+px,cy0+py,(cov>=1.0)?clr:Blend(clr,bg,cov));
           }
     }
  }

void RoundFrame(const int x1,const int y1,const int x2,const int y2,
                const int r,const uint border,const uint fill,const uint bg)
  {
   RoundRect(x1,y1,x2,y2,r,border,bg);
   RoundRect(x1+1,y1+1,x2-1,y2-1,r-1,fill,border);
  }

void HLine(const int x1,const int x2,const int y,const uint c) { g_canvas.FillRectangle(x1,y,x2,y,c); }

void Txt(const int x,const int y,const string s,const uint c,
         const string f,const int pt10,const int w,const uint al)
  { SetFont(f,pt10,w); g_canvas.TextOut(x,y,s,c,al); }

int TxtW(const string s,const string f,const int pt10,const int w)
  { SetFont(f,pt10,w); return (int)g_canvas.TextWidth(s); }

int WrapText(const int x,const int y,const int maxW,const int lineH,const string s,
             const uint c,const int pt10,const bool draw)
  {
   string words[]; int n=StringSplit(s,' ',words);
   string line=""; int ly=y, count=0;
   for(int i=0;i<n;++i)
     {
      string cand=(line=="")?words[i]:line+" "+words[i];
      if(TxtW(cand,FONT_UI,pt10,FW_NORMAL_)<=maxW || line=="") line=cand;
      else { if(draw) Txt(x,ly,line,c,FONT_UI,pt10,FW_NORMAL_,TA_LEFT|TA_VCENTER); ly+=lineH; count++; line=words[i]; }
     }
   if(line!="") { if(draw) Txt(x,ly,line,c,FONT_UI,pt10,FW_NORMAL_,TA_LEFT|TA_VCENTER); count++; }
   return count;
  }

//+------------------------------------------------------------------+
//| Estado de erro — o vermelho sobe a cadeia                         |
//+------------------------------------------------------------------+
bool RailHasError(const int cfg,const int idx)
  { return (cfg==1 && idx==3); }        // Protecao > Noticias

bool CfgHasError(const int cfg)
  {
   if(cfg==1) { for(int i=0;i<7;++i) if(RailHasError(1,i)) return true; }
   return false;
  }

bool TabHasError(const int tab)
  {
   if(tab!=5) return false;
   for(int c=0;c<CFG_COUNT;++c) if(CfgHasError(c)) return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Fichario: a aba ativa perde a borda de baixo e recebe o fundo da  |
//| superficie; a linha do estado atravessa toda a largura.           |
//+------------------------------------------------------------------+
void FolderStrip(const int y,const int h,const int x0,const int xEnd,
                 string &names[],const int count,const int active,
                 const int pt10,const uint surfaceBelow,
                 int &outX[],int &outW[],const bool markErrors,const int cfgForErr)
  {
   bool activeErr = markErrors && ((cfgForErr<0) ? TabHasError(active) : CfgHasError(active));
   uint edge = activeErr ? T.bad : T.acc;

   //--- linha do fichario, largura inteira
   g_canvas.FillRectangle(0, y+h-2, PANEL_W-1, y+h-1, edge);

   int tx = x0;
   for(int i=0;i<count;++i)
     {
      int w = TxtW(names[i],FONT_UI,pt10,FW_SEMI) + 24;
      outX[i]=tx; outW[i]=w;
      bool on  = (i==active);
      bool err = markErrors && ((cfgForErr<0) ? TabHasError(i) : CfgHasError(i));

      if(on)
        {
         //--- cobre o trecho da linha sob a aba e desenha borda em tres lados
         uint fill = err ? T.bdim : surfaceBelow;
         RoundRect(tx, y+2, tx+w, y+h+1, 5, err ? T.bad : T.acc, T.ground);
         RoundRect(tx+2, y+4, tx+w-2, y+h+1, 4, fill, err ? T.bad : T.acc);
        }
      Txt(tx+w/2, y+h/2, names[i],
          err ? T.bad : (on ? T.fg : T.faint),
          FONT_UI, pt10, FW_SEMI, TA_CENTER|TA_VCENTER);
      tx += w + 3;
     }
  }

//+------------------------------------------------------------------+
//| Cabecalho                                                         |
//+------------------------------------------------------------------+
void DrawTitlebar(void)
  {
   g_canvas.FillRectangle(0,0,PANEL_W-1,TITLEBAR_H-1,T.surface);
   HLine(0,PANEL_W-1,TITLEBAR_H-1,T.line);
   Txt(13,16,"EP Fusion",T.fg,FONT_UI,95,FW_SEMI,TA_LEFT|TA_VCENTER);
   int bw=TxtW("EP Fusion",FONT_UI,95,FW_SEMI);
   Txt(13+bw+8,17,"2.000",T.faint,FONT_MONO,80,FW_NORMAL_,TA_LEFT|TA_VCENTER);

   //--- tema
   int tx=PANEL_W-76;
   g_canvas.Circle(tx,16,7,T.muted);
   for(int dy=-6;dy<=6;++dy) for(int dx=-6;dx<=0;++dx)
      if(dx*dx+dy*dy<=36) g_canvas.PixelSet(tx+dx,16+dy,T.muted);

   //--- reajustar altura ao grafico. O painel nunca cresce sozinho, entao
   //--- precisa de um caminho explicito para voltar a ocupar o espaco.
   int rx=PANEL_W-50;
   for(int i=0;i<4;++i)
     {
      g_canvas.FillRectangle(rx-4+i,19-i,rx+4-i,19-i,T.muted);   // seta para cima
      g_canvas.FillRectangle(rx-4+i,13+i,rx+4-i,13+i,T.muted);   // e para baixo
     }

   int mx=PANEL_W-24;
   if(g_minimized)
     {
      g_canvas.FillRectangle(mx-6,13,mx+6,14,T.muted);
      g_canvas.FillRectangle(mx-6,13,mx-5,19,T.muted);
      g_canvas.FillRectangle(mx+5,13,mx+6,19,T.muted);
      g_canvas.FillRectangle(mx-6,18,mx+6,19,T.muted);
     }
   else g_canvas.FillRectangle(mx-6,16,mx+6,17,T.muted);
  }

void Btn(const int x,const int y,const int w,const int h,const string label,
         const bool filled,const uint fillClr,const uint onFill)
  {
   if(filled)
     {
      RoundRect(x,y,x+w,y+h,6,fillClr,T.ground);
      Txt(x+w/2,y+h/2,label,onFill,FONT_UI,85,FW_BOLD_,TA_CENTER|TA_VCENTER);
     }
   else
     {
      RoundFrame(x,y,x+w,y+h,6,T.line,T.ground,T.ground);
      Txt(x+w/2,y+h/2,label,T.muted,FONT_UI,85,FW_BOLD_,TA_CENTER|TA_VCENTER);
     }
  }

void DrawHeader(void)
  {
   Txt(PAD,52,"BTCUSD",T.fg,FONT_UI,110,FW_SEMI,TA_LEFT|TA_VCENTER);
   int sw=TxtW("BTCUSD",FONT_UI,110,FW_SEMI);
   RoundFrame(PAD+sw+9,44,PAD+sw+41,61,4,T.line,T.inset,T.ground);
   Txt(PAD+sw+25,52,"M1",T.muted,FONT_MONO,80,FW_NORMAL_,TA_CENTER|TA_VCENTER);

   string st="PAUSADO"; int pw=TxtW(st,FONT_UI,80,FW_BOLD_)+30;
   RoundRect(PANEL_W-PAD-pw,43,PANEL_W-PAD,63,10,T.wdim,T.ground);
   g_canvas.FillCircle(PANEL_W-PAD-pw+12,53,3,T.warn);
   Txt(PANEL_W-PAD-pw+21,53,st,T.warn,FONT_UI,80,FW_BOLD_,TA_LEFT|TA_VCENTER);

   Txt(PAD,76,"Perfil",T.faint,FONT_UI,85,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   int lw=TxtW("Perfil",FONT_UI,85,FW_NORMAL_);
   Txt(PAD+lw+8,76,"BTCUSD",T.accs,FONT_UI,85,FW_SEMI,TA_LEFT|TA_VCENTER);
   if(g_dirty)
     {
      int vw=TxtW("BTCUSD",FONT_UI,85,FW_SEMI);
      Txt(PAD+lw+vw+16,76,"· alteracoes nao salvas",T.faint,FONT_UI,85,FW_NORMAL_,TA_LEFT|TA_VCENTER);
     }

   //--- Um unico botao preenchido: ele indica o proximo passo. Com pendencias
   //--- e Salvar; sem elas, Iniciar. A cor orienta em vez de decorar.
   int bw2=(PANEL_W-2*PAD-16)/3, bx=PAD, by=94, bh=29;
   Btn(bx,by,bw2,bh,"INICIAR", !g_dirty, T.good, T.onGood);
   bx+=bw2+8;
   Btn(bx,by,bw2,bh,"SALVAR",   g_dirty, T.acc,  T.onAcc);
   bx+=bw2+8;
   Btn(bx,by,bw2,bh,"CANCELAR", false,   T.acc,  T.onAcc);
  }

//+------------------------------------------------------------------+
//| Area util rolavel                                                 |
//+------------------------------------------------------------------+
//--- Folga entre os dois fichários: apertada de proposito. Eles sao niveis
//--- vizinhos da mesma hierarquia e devem parecer encaixados, nao separados.
#define F2_GAP 7
int Surf1Top(void)   { return F1_BOTTOM; }
int F2Top(void)      { return F1_BOTTOM + F2_GAP; }
int ContentTop(void) { return (g_tab==5) ? F2Top() + F2_H + 10 : F1_BOTTOM + PAD; }
int ContentBottom(void){ return g_ph - PAD - g_alertH - (g_alertH>0 ? 9 : 0); }

bool ScrollBy(const int d)
  {
   int viewH=ContentBottom()-ContentTop();
   int maxS=g_contentH-viewH;
   if(maxS<=0) return false;
   int ns=g_scroll+d;
   if(ns<0) ns=0;
   if(ns>maxS) ns=maxS;
   if(ns==g_scroll) return false;
   g_scroll=ns; return true;
  }

void AlertBottom(const int x1,const int x2,const int bottomY,const string title,
                 const string body,const uint accentClr,const uint bgClr,const uint textClr)
  {
   int textX=x1+24, maxW=(x2-14)-textX, lineH=15, titleH=16, gap=4, padV=14;
   int lines=WrapText(textX,0,maxW,lineH,body,textClr,82,false);
   int h=titleH+gap+lines*lineH+2*padV;
   int y=bottomY-h;
   g_alertH=h;
   RoundRect(x1,y,x2,y+h,8,bgClr,T.surface);
   g_canvas.FillRectangle(x1+12,y+padV,x1+14,y+h-padV,accentClr);
   Txt(textX,y+padV+titleH/2,title,accentClr,FONT_UI,78,FW_BOLD_,TA_LEFT|TA_VCENTER);
   WrapText(textX,y+padV+titleH+gap+lineH/2,maxW,lineH,body,textClr,82,true);
  }

//+------------------------------------------------------------------+
//| Trilho do terceiro nivel                                          |
//+------------------------------------------------------------------+
void DrawRail(const int x,const int y,const int h,string &items[],const int count,
              const int active,const int cfg)
  {
   g_railCount=count;
   g_canvas.FillRectangle(x+RAIL_W-1,y,x+RAIL_W-1,y+h,T.soft);
   for(int i=0;i<count;++i)
     {
      int ry=y+i*(RAIL_ROW+2);
      g_railY[i]=ry;
      bool on=(i==active), err=RailHasError(cfg,i);
      if(on) RoundRect(x,ry,x+RAIL_W-10,ry+RAIL_ROW,5, err?T.bdim:T.accd, T.ground);
      Txt(x+10,ry+RAIL_ROW/2,items[i],
          err?T.bad:(on?T.accs:T.muted),FONT_UI,88,on?FW_SEMI:FW_NORMAL_,TA_LEFT|TA_VCENTER);
      if(err) g_canvas.FillCircle(x+RAIL_W-19,ry+RAIL_ROW/2,3,T.bad);
     }
  }

//+------------------------------------------------------------------+
//| Controles de conteudo                                             |
//+------------------------------------------------------------------+
void FieldRow(const int gx1,const int gx2,const int ry,const string label,
              const string hint,const uint hintClr,int &slot)
  {
   Txt(gx1+12,ry+13,label,T.fg,FONT_UI,88,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   if(hint!="") Txt(gx1+12,ry+29,hint,hintClr,FONT_UI,75,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   g_editY[slot]=ry+21-EDIT_H/2; slot++;
  }

void ToggleRow(const int gx1,const int gx2,const int ry,const string label,int &slot)
  {
   bool on=g_toggleOn[slot];
   Txt(gx1+12,ry+15,label,T.fg,FONT_UI,88,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   int tx=gx2-12-38, ty=ry+4;
   RoundRect(tx,ty,tx+38,ty+21,10,on?T.good:T.line,T.surface);
   g_canvas.FillCircle(on?tx+28:tx+10,ty+10,8,T.ground);
   g_toggleX[slot]=tx; g_toggleY[slot]=ty; slot++;
  }

void DrawComboClosed(const int gx1,const int gx2,const int ry,const string label)
  {
   Txt(gx1+12,ry+15,label,T.fg,FONT_UI,88,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   int w=92, cx=gx2-12-w, cy=ry+3;
   g_comboX=cx; g_comboY=cy; g_comboW=w;
   RoundFrame(cx,cy,cx+w,cy+EDIT_H,5,g_comboOpen?T.acc:T.line,T.inset,T.surface);
   Txt(cx+10,cy+EDIT_H/2,g_comboItems[g_comboIndex],T.fg,FONT_MONO,90,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   int ax=cx+w-15, ay=cy+EDIT_H/2-2;
   for(int i=0;i<4;++i) g_canvas.FillRectangle(ax-3+i,ay+i,ax+3-i,ay+i,T.muted);
  }

void ColorRow(const int gx1,const int gx2,const int ry,const string label,int &slot)
  {
   Txt(gx1+12,ry+15,label,T.fg,FONT_UI,88,FW_NORMAL_,TA_LEFT|TA_VCENTER);
   int w=64, cx=gx2-12-w, cy=ry+4;
   g_colorX[slot]=cx; g_colorY[slot]=cy;
   RoundFrame(cx,cy,cx+w,cy+22,5,(g_colorOpen==slot)?T.acc:T.line,g_swatches[g_colorSel[slot]],T.surface);
   slot++;
  }

//--- Grade aberta por ultimo, como o combo: no canvas basta ordem de desenho.
void DrawColorPopup(void)
  {
   if(g_colorOpen<0) return;
   int cell=26, cols=4, rows=SWATCH_COUNT/cols;
   int w=cols*cell+10, h=rows*cell+10;
   int x=g_colorX[g_colorOpen]+64-w;
   int y=g_colorY[g_colorOpen]+24;
   if(y+h>g_ph-PAD) y=g_colorY[g_colorOpen]-h-2;
   RoundFrame(x,y,x+w,y+h,6,T.acc,T.surface,T.ground);
   for(int i=0;i<SWATCH_COUNT;++i)
     {
      int cxx=x+5+(i%cols)*cell, cyy=y+5+(i/cols)*cell;
      bool sel=(i==g_colorSel[g_colorOpen]);
      RoundFrame(cxx+1,cyy+1,cxx+cell-3,cyy+cell-3,4,
                 sel?T.fg:T.line,g_swatches[i],T.surface);
     }
  }

bool HandleColorClick(const int lx,const int ly)
  {
   if(g_colorOpen>=0)
     {
      int cell=26, cols=4, rows=SWATCH_COUNT/cols;
      int w=cols*cell+10, h=rows*cell+10;
      int x=g_colorX[g_colorOpen]+64-w, y=g_colorY[g_colorOpen]+24;
      if(y+h>g_ph-PAD) y=g_colorY[g_colorOpen]-h-2;
      if(lx>=x && lx<x+w && ly>=y && ly<y+h)
        {
         int c=(lx-x-5)/cell, r=(ly-y-5)/cell;
         int idx=r*cols+c;
         if(c>=0 && c<cols && idx>=0 && idx<SWATCH_COUNT)
           { g_colorSel[g_colorOpen]=idx; Print("Cor ",g_colorOpen," -> indice ",idx); }
        }
      g_colorOpen=-1; Render(); return true;
     }
   for(int i=0;i<g_colorCount;++i)
      if(lx>=g_colorX[i] && lx<g_colorX[i]+64 && ly>=g_colorY[i] && ly<g_colorY[i]+22)
        { g_colorOpen=i; Render(); return true; }
   return false;
  }

void DrawComboPopup(void)
  {
   if(!g_comboOpen) return;
   int ih=24, h=COMBO_ITEMS*ih+8, y=g_comboY+EDIT_H+3;
   if(y+h>g_ph-PAD) y=g_comboY-h-3;
   RoundFrame(g_comboX,y,g_comboX+g_comboW,y+h,6,T.acc,T.surface,T.ground);
   for(int i=0;i<COMBO_ITEMS;++i)
     {
      int iy=y+4+i*ih;
      if(i==g_comboIndex) RoundRect(g_comboX+4,iy,g_comboX+g_comboW-4,iy+ih,4,T.accd,T.surface);
      Txt(g_comboX+12,iy+ih/2,g_comboItems[i],
          (i==g_comboIndex)?T.accs:T.fg,FONT_MONO,90,FW_NORMAL_,TA_LEFT|TA_VCENTER);
     }
  }

//+------------------------------------------------------------------+
//| Telas                                                             |
//+------------------------------------------------------------------+
void DrawStatusScreen(void)
  {
   int x1=PAD, x2=PANEL_W-PAD, y=Surf1Top()+PAD;

   RoundRect(x1,y,x2,y+56,8,T.ground,T.surface);
   Txt(x1+14,y+18,"ESTADO",T.faint,FONT_UI,78,FW_SEMI,TA_LEFT|TA_VCENTER);
   Txt(x1+14,y+38,"Pausado",T.fg,FONT_UI,150,FW_SEMI,TA_LEFT|TA_VCENTER);
   Txt(x2-14,y+18,"POSICAO",T.faint,FONT_UI,78,FW_SEMI,TA_RIGHT|TA_VCENTER);
   Txt(x2-14,y+38,"Nenhuma",T.muted,FONT_UI,115,FW_SEMI,TA_RIGHT|TA_VCENTER);
   y+=66;

   string tk[4]={"ESTRATEGIAS","FILTROS","MAGIC","TF OPER."};
   string tv[4]={"1","0","1","M1"};
   int tw=(x2-x1-24)/4;
   for(int i=0;i<4;++i)
     {
      int bx=x1+i*(tw+8);
      RoundRect(bx,y,bx+tw,y+54,7,T.ground,T.surface);
      Txt(bx+11,y+17,tk[i],T.faint,FONT_UI,75,FW_SEMI,TA_LEFT|TA_VCENTER);
      bool mono=(i>=2);
      Txt(bx+11,y+37,tv[i],(i==1)?T.faint:T.fg,
          mono?FONT_MONO:FONT_UI,mono?105:120,FW_SEMI,TA_LEFT|TA_VCENTER);
     }
   y+=66;

   string rk[4]={"Responsavel","Conflito","Resultado do dia","Trades hoje"};
   string rv[4]={"—","Prioridade","0,00","0"};
   for(int i=0;i<4;++i)
     {
      Txt(x1+2,y+15,rk[i],T.muted,FONT_UI,88,FW_NORMAL_,TA_LEFT|TA_VCENTER);
      bool mono=(i>=2);
      Txt(x2-2,y+15,rv[i],T.fg,mono?FONT_MONO:FONT_UI,mono?95:88,FW_SEMI,TA_RIGHT|TA_VCENTER);
      HLine(x1,x2,y+31,T.soft);
      y+=32;
     }

   AlertBottom(x1,x2,g_ph-PAD,"CONFIG",
               "Notificacoes tem uma janela invalida. Corrija em Config > Protecao > Noticias.",
               T.bad,T.bdim,T.bad);
  }

void DrawProfilesScreen(void)
  {
   int x1=PAD, x2=PANEL_W-PAD, y=Surf1Top()+PAD;
   int aw=124, lx2=x2-aw-11;

   string nm[6]={"BTCUSD","GOLD","JP225","US500","default","WIN scalp"};
   string mg[6]={"#1 · lote 0.01","#20 · lote 0.10","#31 · lote 1.00",
                 "#42 · lote 0.50","#1000 · lote 6.00","#77 · lote 2.00"};
   for(int i=0;i<6;++i)
     {
      int ry=y+i*34;
      bool sel=(i==g_profSel);
      if(sel) RoundFrame(x1,ry,lx2,ry+30,6,T.acc,T.accd,T.surface);
      else    RoundFrame(x1,ry,lx2,ry+30,6,T.soft,T.ground,T.surface);
      Txt(x1+11,ry+15,nm[i],T.fg,FONT_UI,90,FW_SEMI,TA_LEFT|TA_VCENTER);
      int nw=TxtW(nm[i],FONT_UI,90,FW_SEMI);
      Txt(x1+11+nw+10,ry+15,mg[i],T.faint,FONT_MONO,78,FW_NORMAL_,TA_LEFT|TA_VCENTER);
      if(i==0)
        {
         int tw2=TxtW("ATIVO",FONT_UI,72,FW_BOLD_)+18;
         RoundRect(lx2-tw2-9,ry+7,lx2-9,ry+23,8,T.gdim,sel?T.accd:T.ground);
         Txt(lx2-tw2/2-9,ry+15,"ATIVO",T.good,FONT_UI,72,FW_BOLD_,TA_CENTER|TA_VCENTER);
        }
     }

   string ab[4]={"CARREGAR","NOVO","DUPLICAR","EXCLUIR"};
   for(int i=0;i<4;++i)
     {
      int by=y+i*34;
      if(i==0) Btn(lx2+11,by,aw,30,ab[i],true,T.acc,T.onAcc);
      else     Btn(lx2+11,by,aw,30,ab[i],false,T.acc,T.onAcc);
     }
   g_alertH=0;
  }

void DrawConfigContent(void)
  {
   int railX=PAD, paneX=PAD+RAIL_W+2, x2=PANEL_W-PAD;
   int top=ContentTop();
   //--- Zerados no inicio de cada render: os campos nativos sao recriados a
   //--- partir daqui, e um contador herdado da subaba anterior faria aparecer
   //--- controle de outra tela, em posicao velha.
   g_colorCount=0;
   g_editCount=0;
   g_toggleCount=0;

   //--- Sistema e Visual nao tem terceiro nivel: sem trilho, conteudo cheio.
   if(g_cfg>=2)
     {
      int yv=top-g_scroll;
      int ghv=26+34+34+34;
      RoundRect(PAD,yv,x2,yv+ghv,8,T.surface,T.ground);
      Txt(PAD+12,yv+17,(g_cfg==2)?"IDENTIFICACAO":"CORES DAS LINHAS",
          T.faint,FONT_UI,78,FW_SEMI,TA_LEFT|TA_VCENTER);
      if(g_cfg==3)
        {
         ColorRow(PAD,x2,yv+26,"Media rapida",g_colorCount);
         ColorRow(PAD,x2,yv+60,"Media lenta",g_colorCount);
         ColorRow(PAD,x2,yv+94,"Bandas",g_colorCount);
        }
      else
        {
         FieldRow(PAD,x2,yv+26,"Magic Number","Identifica as ordens deste grafico",T.faint,g_editCount);
         FieldRow(PAD,x2,yv+68,"Slippage","Desvio maximo aceito",T.faint,g_editCount);
        }
      g_contentH=ghv;
      return;
     }

   if(g_cfg==0)      DrawRail(railX,top,ContentBottom()-top,g_railRisco,5,g_rail>=5?0:g_rail,0);
   else if(g_cfg==1) DrawRail(railX,top,ContentBottom()-top,g_railProt,7,g_rail,1);

   int y=top-g_scroll;
   int gh=26+42+42;
   g_editCount=0;
   RoundRect(paneX,y,x2,y+gh,8,T.surface,T.ground);
   Txt(paneX+12,y+17,"DRAWDOWN DIARIO",T.faint,FONT_UI,78,FW_SEMI,TA_LEFT|TA_VCENTER);
   FieldRow(paneX,x2,y+26,"Limite","Sobre o pico do dia",T.faint,g_editCount);
   FieldRow(paneX,x2,y+26+42,"Gatilho","Valor minimo para armar",T.faint,g_editCount);
   y+=gh+11;

   gh=26+42+42+30+30;
   RoundRect(paneX,y,x2,y+gh,8,T.surface,T.ground);
   Txt(paneX+12,y+17,"COMPORTAMENTO",T.faint,FONT_UI,78,FW_SEMI,TA_LEFT|TA_VCENTER);
   FieldRow(paneX,x2,y+26,"Buffer","Folga antes de bloquear",T.faint,g_editCount);
   FieldRow(paneX,x2,y+26+42,"Rearme","Minutos ate liberar",T.faint,g_editCount);
   ToggleRow(paneX,x2,y+26+84,"Encerrar o dia",g_toggleCount);
   ToggleRow(paneX,x2,y+26+114,"Avisar no painel",g_toggleCount);
   y+=gh+11;

   gh=26+32;
   RoundRect(paneX,y,x2,y+gh,8,T.surface,T.ground);
   Txt(paneX+12,y+17,"REFERENCIA",T.faint,FONT_UI,78,FW_SEMI,TA_LEFT|TA_VCENTER);
   DrawComboClosed(paneX,x2,y+26,"Timeframe");
   y+=gh;

   g_contentH=(y+g_scroll)-top;
  }

#define SB_X    (PANEL_W-11)
#define SB_W      6
#define SB_ARROW 14

void DrawScrollbar(void)
  {
   int top=ContentTop(), bottom=ContentBottom(), viewH=bottom-top;
   g_trackH=0;
   if(g_contentH<=viewH) return;
   int maxS=g_contentH-viewH;
   g_trackTop=top+SB_ARROW;
   int tBot=bottom-SB_ARROW;
   g_trackH=tBot-g_trackTop;
   RoundRect(SB_X,g_trackTop,SB_X+SB_W,tBot,3,T.soft,T.surface);
   g_thumbH=(int)MathMax(28,(double)g_trackH*viewH/g_contentH);
   g_thumbY=g_trackTop+(int)((double)(g_trackH-g_thumbH)*g_scroll/maxS);
   RoundRect(SB_X,g_thumbY,SB_X+SB_W,g_thumbY+g_thumbH,3,T.faint,T.soft);
   int cx=SB_X+SB_W/2;
   for(int i=0;i<4;++i)
     {
      uint cu=(g_scroll>0)?T.acc:T.soft;
      uint cd=(g_scroll<maxS)?T.acc:T.soft;
      g_canvas.FillRectangle(cx-3+i,top+8-i,cx+3-i,top+8-i,cu);
      g_canvas.FillRectangle(cx-3+i,bottom-12+i,cx+3-i,bottom-12+i,cd);
     }
  }

//--- Setas, alcinha e trilho. A alcinha arrasta na direcao da barra; o trilho
//--- pagina. Sao gestos diferentes do arrasto do conteudo, que vai ao contrario.
bool HandleScrollbarClick(const int lx,const int ly)
  {
   if(g_trackH<=0) return false;
   int top=ContentTop(), bottom=ContentBottom();
   if(lx<SB_X-6 || lx>SB_X+SB_W+6) return false;

   if(ly>=top && ly<top+SB_ARROW)      { if(ScrollBy(-40)) Render(); return true; }
   if(ly<=bottom && ly>bottom-SB_ARROW){ if(ScrollBy( 40)) Render(); return true; }

   if(ly>=g_thumbY && ly<g_thumbY+g_thumbH)
     { g_barDrag=true; g_barDragY=ly; g_barDragBase=g_scroll; return true; }

   int page=(bottom-top);
   if(ly<g_thumbY)      { if(ScrollBy(-page)) Render(); return true; }
   if(ly>=g_thumbY+g_thumbH) { if(ScrollBy(page)) Render(); return true; }
   return true;
  }

void HandleBarDrag(const int ly)
  {
   int viewH=ContentBottom()-ContentTop();
   int maxS=g_contentH-viewH;
   int span=g_trackH-g_thumbH;
   if(maxS<=0 || span<=0) return;
   int target=g_barDragBase+(int)((double)(ly-g_barDragY)*maxS/span);
   if(ScrollBy(target-g_scroll)) Render();
  }

//+------------------------------------------------------------------+
//| Campos nativos                                                    |
//+------------------------------------------------------------------+
color ToChartColor(const uint argb)
  {
   int r=(int)((argb>>16)&0xFF), g=(int)((argb>>8)&0xFF), b=(int)(argb&0xFF);
   return (color)((b<<16)|(g<<8)|r);
  }

bool EditVisible(const int ly)
  { return (ly>=ContentTop() && ly+EDIT_H<=ContentBottom()); }

void MakeEdit(const string id,const int lx,const int ly,const string v,
              const uint border,const uint textClr)
  {
   string n=g_prefix+id;
   ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,g_px+lx);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,g_py+ly);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,EDIT_W);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,EDIT_H);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,ToChartColor(T.inset));
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,ToChartColor(border));
   ObjectSetInteger(0,n,OBJPROP_COLOR,ToChartColor(textClr));
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,n,OBJPROP_ALIGN,ALIGN_RIGHT);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,100);
   ObjectSetString (0,n,OBJPROP_FONT,FONT_MONO);
   ObjectSetString (0,n,OBJPROP_TEXT,v);
  }

void DestroyEdits(void) { ObjectsDeleteAll(0,g_prefix+"edit_"); }

void BuildEdits(void)
  {
   DestroyEdits();
   if(g_tab!=5 || g_minimized) return;
   //--- Cria exatamente os campos que a tela atual desenhou. Antes exigia
   //--- quatro, entao Sistema desenhava dois rotulos sem caixa nenhuma.
   int ex=PANEL_W-PAD-12-EDIT_W;
   string vals[4]={"2.50","0.00","0.30","15"};
   string ids[4] ={"edit_a","edit_b","edit_c","edit_d"};
   int n=(g_editCount<4)?g_editCount:4;
   for(int i=0;i<n;++i)
      if(EditVisible(g_editY[i]))
         MakeEdit(ids[i],ex,g_editY[i],vals[i],T.line,T.fg);
  }

//+------------------------------------------------------------------+
void Render(void)
  {
   int h = g_minimized ? TITLEBAR_H : g_ph;
   if(!g_canvas.Resize(PANEL_W,h)) return;
   ObjectSetInteger(0,g_canvasName,OBJPROP_XDISTANCE,g_px);
   ObjectSetInteger(0,g_canvasName,OBJPROP_YDISTANCE,g_py);

   g_canvas.Erase(T.ground);

   if(g_minimized) { DrawTitlebar(); }
   else
     {
      //--- superficie do nivel 1: e nela que as abas do fichario se apoiam
      g_canvas.FillRectangle(0,Surf1Top(),PANEL_W-1,h-1,T.surface);

      if(g_tab==5)
        {
         g_alertH=0;
         //--- conteudo rolavel primeiro; depois as faixas de fora sao repintadas
         //--- e o chrome fecha por cima, entao nada rolado alcanca as abas
         DrawConfigContent();
         g_canvas.FillRectangle(0,Surf1Top(),PANEL_W-1,ContentTop()-1,T.surface);
         g_canvas.FillRectangle(0,ContentBottom()+1,PANEL_W-1,h-1,T.surface);
         g_canvas.FillRectangle(0,0,PANEL_W-1,Surf1Top()-1,T.ground);
        }

      DrawTitlebar();
      DrawHeader();
      FolderStrip(HEADER_BOTTOM,F1_H,10,PANEL_W-10,g_tabNames,TAB_COUNT,g_tab,82,T.surface,g_tabX,g_tabW,true,-1);

      if(g_tab==5)
        {
         FolderStrip(F2Top(),F2_H,PAD,PANEL_W-PAD,g_cfgNames,CFG_COUNT,g_cfg,82,T.ground,g_cfgX,g_cfgW,true,1);
         DrawScrollbar();
         DrawComboPopup();
         DrawColorPopup();
        }
      else if(g_tab==4) DrawProfilesScreen();
      else              DrawStatusScreen();

      g_canvas.Rectangle(0,0,PANEL_W-1,h-1,T.shell);
     }

   g_canvas.Update(false);
   BuildEdits();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Interacao                                                         |
//+------------------------------------------------------------------+
void SetChartScroll(const bool on) { ChartSetInteger(0,CHART_MOUSE_SCROLL,on); }

bool InsidePanel(const int cx,const int cy)
  {
   int h=g_minimized?TITLEBAR_H:g_ph;
   return (cx>=g_px && cx<g_px+PANEL_W && cy>=g_py && cy<g_py+h);
  }

bool HandleComboClick(const int lx,const int ly)
  {
   if(g_comboOpen)
     {
      int ih=24, h=COMBO_ITEMS*ih+8, y=g_comboY+EDIT_H+3;
      if(y+h>g_ph-PAD) y=g_comboY-h-3;
      if(lx>=g_comboX && lx<g_comboX+g_comboW && ly>=y && ly<y+h)
        {
         int idx=(ly-y-4)/ih;
         if(idx>=0 && idx<COMBO_ITEMS) { g_comboIndex=idx; Print("Timeframe: ",g_comboItems[idx]); }
        }
      g_comboOpen=false; Render(); return true;
     }
   if(g_comboY>=ContentTop() && g_comboY+EDIT_H<=ContentBottom() &&
      lx>=g_comboX && lx<g_comboX+g_comboW && ly>=g_comboY && ly<g_comboY+EDIT_H)
     { g_comboOpen=true; Render(); return true; }
   return false;
  }

void HandlePress(const int cx,const int cy)
  {
   int lx=cx-g_px, ly=cy-g_py;

   if(ly<TITLEBAR_H)
     {
      if(lx>=PANEL_W-40) { g_minimized=!g_minimized; Render(); return; }
      if(lx>=PANEL_W-64 && lx<PANEL_W-40)
        { g_ph=DecidePanelHeight(); g_scroll=0; Render();
          Print("Altura reajustada ao grafico: ",g_ph,"px"); return; }
      if(lx>=PANEL_W-90 && lx<PANEL_W-64)
        { g_userTheme=true; if(g_dark) ApplyLight(); else ApplyDark(); Render(); return; }
      g_dragging=true; g_dragDX=lx; g_dragDY=ly; return;
     }
   if(g_minimized) return;

   if(g_tab==5 && HandleColorClick(lx,ly)) return;
   if(g_tab==5 && HandleComboClick(lx,ly)) return;

   //--- botoes do cabecalho: alternam o estado de pendencia, para exercitar
   //--- a regra do unico botao preenchido
   if(ly>=94 && ly<123)
     {
      int bw2=(PANEL_W-2*PAD-16)/3;
      if(lx>=PAD && lx<PAD+bw2*2+8) { g_dirty=!g_dirty; Render(); return; }
     }

   if(ly>=HEADER_BOTTOM && ly<F1_BOTTOM)
     {
      for(int i=0;i<TAB_COUNT;++i)
         if(lx>=g_tabX[i] && lx<g_tabX[i]+g_tabW[i])
           { if(g_tab!=i){g_tab=i;g_scroll=0;g_alertH=0;Render();} return; }
      return;
     }

   if(g_tab==5)
     {
      int f2y=F2Top();
      if(ly>=f2y && ly<f2y+F2_H)
        {
         for(int i=0;i<CFG_COUNT;++i)
            if(lx>=g_cfgX[i] && lx<g_cfgX[i]+g_cfgW[i])
              { if(g_cfg!=i){g_cfg=i;g_rail=0;g_scroll=0;Render();} return; }
         return;
        }

      if(HandleScrollbarClick(lx,ly)) return;

      if(g_cfg<2 && lx<PAD+RAIL_W)
        {
         for(int i=0;i<g_railCount;++i)
            if(ly>=g_railY[i] && ly<g_railY[i]+RAIL_ROW)
              { if(g_rail!=i){g_rail=i;g_scroll=0;Render();} return; }
         return;
        }

      for(int t=0;t<g_toggleCount;++t)
         if(lx>=g_toggleX[t]-6 && lx<g_toggleX[t]+44 &&
            ly>=g_toggleY[t]-6 && ly<g_toggleY[t]+27 &&
            g_toggleY[t]>=ContentTop() && g_toggleY[t]+21<=ContentBottom())
           { g_toggleOn[t]=!g_toggleOn[t]; Print("Toggle ",t,": ",(g_toggleOn[t]?"ON":"OFF")); Render(); return; }

      if(ly>=ContentTop() && ly<=ContentBottom() && lx<PANEL_W-16)
        { g_scrollDrag=true; g_scrollDragY=cy; g_scrollDragBase=g_scroll; }
      return;
     }

   if(g_tab==4)
     {
      int y=Surf1Top()+PAD;
      for(int i=0;i<6;++i)
         if(ly>=y+i*34 && ly<y+i*34+30 && lx<PANEL_W-PAD-135)
           { if(g_profSel!=i){g_profSel=i;Render();} return; }
     }
  }

void HandleScrollDrag(const int cy)
  {
   int target=g_scrollDragBase+(g_scrollDragY-cy);
   if(ScrollBy(target-g_scroll)) Render();
  }

void HandleDrag(const int cx,const int cy)
  {
   int nx=cx-g_dragDX, ny=cy-g_dragDY;
   if(nx<0) nx=0;
   if(ny<0) ny=0;
   if(nx==g_px && ny==g_py) return;
   g_px=nx; g_py=ny; Render();
  }

//+------------------------------------------------------------------+
//| Altura: decidida ao anexar, nao elastica durante o uso. Um painel |
//| que encolhe e cresce sozinho faz a informacao mudar de lugar sem  |
//| que o usuario tenha feito nada.                                   |
//+------------------------------------------------------------------+
int DecidePanelHeight(void)
  {
   int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   int h=chartH-g_py-16;
   if(h<PANEL_H_MIN) h=PANEL_H_MIN;
   if(h>PANEL_H_MAX) h=PANEL_H_MAX;
   return h;
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   ResolveTheme();
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   ChartSetInteger(0,CHART_EVENT_MOUSE_WHEEL,true);
   g_origScroll=(bool)ChartGetInteger(0,CHART_MOUSE_SCROLL);
   g_ph=DecidePanelHeight();

   g_canvasName=g_prefix+"canvas";
   if(!g_canvas.CreateBitmapLabel(0,0,g_canvasName,g_px,g_py,PANEL_W,g_ph,COLOR_FORMAT_ARGB_NORMALIZE))
     { Print("Prototipo: falha ao criar o canvas."); return INIT_FAILED; }
   ObjectSetInteger(0,g_canvasName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,g_canvasName,OBJPROP_ZORDER,0);

   Render();
   Print("Prototipo 2.0 ativo. Altura ",g_ph,"px. Tema ",(g_dark?"escuro":"claro"),
         ". Clique nos botoes do topo para alternar pendencias.");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   SetChartScroll(g_origScroll);
   DestroyEdits();
   g_canvas.Destroy();
   ObjectsDeleteAll(0,g_prefix);
   ChartRedraw(0);
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      //--- so encolhe para nao ficar cortado; nunca cresce sozinho
      int fit=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-g_py-16;
      if(fit<g_ph && fit>=PANEL_H_MIN) { g_ph=fit; Render(); }
      if(inp_Theme==PROTO_THEME_AUTO && !g_userTheme)
        {
         bool was=g_dark; ResolveTheme();
         if(was!=g_dark) Render();
        }
      return;
     }

   if(id==CHARTEVENT_MOUSE_WHEEL)
     {
      int cx=(int)(short)(lparam & 0xFFFF), cy=(int)(short)((lparam>>16)&0xFFFF);
      if(g_minimized || g_tab!=5 || !InsidePanel(cx,cy)) return;
      if(ScrollBy((dparam>0)?-40:40)) Render();
      return;
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      if(g_minimized || g_tab!=5 || !g_overPanel) return;
      int viewH=ContentBottom()-ContentTop(), step=0;
      switch((int)lparam)
        {
         case VK_UP_:    step=-40;         break;
         case VK_DOWN_:  step= 40;         break;
         case VK_PRIOR_: step=-viewH;      break;
         case VK_NEXT_:  step= viewH;      break;
         case VK_HOME_:  step=-g_contentH; break;
         case VK_END_:   step= g_contentH; break;
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
      if(over!=g_overPanel) { SetChartScroll(over?false:g_origScroll); g_overPanel=over; }

      if(down && !g_mouseDown && over)   HandlePress(cx,cy);
      else if(down && g_dragging)        HandleDrag(cx,cy);
      else if(down && g_barDrag)         HandleBarDrag(cy-g_py);
      else if(down && g_scrollDrag)      HandleScrollDrag(cy);

      if(!down) { g_dragging=false; g_scrollDrag=false; g_barDrag=false; }
      g_mouseDown=down;
      return;
     }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && StringFind(sparam,g_prefix+"edit_")==0)
     { Print("Campo ",sparam,": ",ObjectGetString(0,sparam,OBJPROP_TEXT)); return; }
  }

void OnTick(void) { }
