//+------------------------------------------------------------------+
//| CanvasTheme.mqh                                                   |
//| Paletas da GUI 2.0. Sem estado: um struct e funcoes livres que o  |
//| preenchem. Cada paleta tem par escuro e claro.                    |
//|                                                                   |
//| Regras que valem para qualquer paleta, e que nao devem ser        |
//| quebradas ao acrescentar uma nova:                                |
//|  - dois fundos, nao tres; o campo de entrada e recuado, com borda |
//|  - tres niveis de texto com distancia real entre eles             |
//|  - semanticas na temperatura dos neutros, saturacao reduzida      |
//|  - no claro as semanticas sao MAIS ESCURAS, nao as mesmas cores   |
//|  - o acento nao pode ocupar a mesma faixa de matiz que 'bom' ou   |
//|    'atencao': os tres aparecem preenchidos ao mesmo tempo         |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_THEME_MQH__
#define __FUSION_CANVAS_THEME_MQH__

//--- O canvas trabalha em ARGB; 'color' do MQL5 e BGR. Este macro monta o
//--- pixel opaco a partir de R,G,B explicitos para nao haver conversao
//--- implicita errada em lugar nenhum.
#define FCV_OPAQUE(r,g,b) ((uint)(0xFF000000|((uint)(r)<<16)|((uint)(g)<<8)|(uint)(b)))
#define FCV_HEX(v)        ((uint)(0xFF000000|(uint)(v)))

enum ENUM_FUSION_CANVAS_THEME
  {
   FUSION_CANVAS_THEME_AUTO = 0,   // Automatico (segue o fundo do grafico)
   FUSION_CANVAS_THEME_DARK = 1,   // Escuro
   FUSION_CANVAS_THEME_LIGHT= 2    // Claro
  };

enum ENUM_FUSION_CANVAS_PALETTE
  {
   FUSION_PALETTE_PETROLEO = 0,    // Petroleo
   FUSION_PALETTE_MARINHO  = 1,    // Marinho
   FUSION_PALETTE_ARDOSIA  = 2,    // Ardosia
   FUSION_PALETTE_AMBAR    = 3     // Ambar
  };

#define FCV_PALETTE_COUNT 4

struct SCanvasTheme
  {
   uint ground, surface, inset, line, soft;
   uint fg, muted, faint;
   uint acc, accs, accd;
   uint good, gdim, bad, bdim, warn, wdim;
   uint onGood, onAcc;
   uint shell;
   //--- estados que o painel da 1.058 tem e a 2.0 precisa reproduzir
   uint disabled;      // texto e borda de controle bloqueado
   uint fieldDim;      // fundo de campo bloqueado
   uint fieldErr;      // fundo de campo invalido
  };

//+------------------------------------------------------------------+
//| Petroleo — neutros tingidos de azul-petroleo. O acento pende para |
//| o azul (nao o teal puro) porque teal fica vizinho do verde de     |
//| 'bom', e os dois aparecem preenchidos na mesma tela.              |
//+------------------------------------------------------------------+
void FusionPalettePetroleoDark(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0x0A161C); t.surface=FCV_HEX(0x122530); t.inset=FCV_HEX(0x071219);
   t.line  =FCV_HEX(0x22414F); t.soft   =FCV_HEX(0x1A3441);
   t.fg    =FCV_HEX(0xE9F2F6); t.muted  =FCV_HEX(0x9DB4BE); t.faint=FCV_HEX(0x728D97);
   t.acc   =FCV_HEX(0x3392BC); t.accs   =FCV_HEX(0x7FCDE8); t.accd =FCV_HEX(0x103544);
   t.good  =FCV_HEX(0x3BB489); t.gdim   =FCV_HEX(0x0E3A2F);
   t.bad   =FCV_HEX(0xCF7378); t.bdim   =FCV_HEX(0x3A2125);
   t.warn  =FCV_HEX(0xD2A04A); t.wdim   =FCV_HEX(0x382C16);
   t.onGood=FCV_HEX(0x041410); t.onAcc  =FCV_HEX(0x04141C);
   t.shell =FCV_HEX(0x2E4B58);
   t.disabled=FCV_HEX(0x4A6570); t.fieldDim=FCV_HEX(0x0D1E26); t.fieldErr=FCV_HEX(0x2C1A1D);
  }

void FusionPalettePetroleoLight(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0xEDF2F4); t.surface=FCV_HEX(0xFFFFFF); t.inset=FCV_HEX(0xF3F7F9);
   t.line  =FCV_HEX(0xCFDCE2); t.soft   =FCV_HEX(0xE2EAEE);
   t.fg    =FCV_HEX(0x0F1E25); t.muted  =FCV_HEX(0x4E6672); t.faint=FCV_HEX(0x7D939D);
   t.acc   =FCV_HEX(0x1F7A9E); t.accs   =FCV_HEX(0x155F7D); t.accd =FCV_HEX(0xDBEDF4);
   t.good  =FCV_HEX(0x127A5C); t.gdim   =FCV_HEX(0xDDF1EA);
   t.bad   =FCV_HEX(0xB03A42); t.bdim   =FCV_HEX(0xFAE4E5);
   t.warn  =FCV_HEX(0x96650F); t.wdim   =FCV_HEX(0xFAEFD8);
   t.onGood=FCV_HEX(0xFFFFFF); t.onAcc  =FCV_HEX(0xFFFFFF);
   t.shell =FCV_HEX(0xB9CBD3);
   t.disabled=FCV_HEX(0xA6B6BE); t.fieldDim=FCV_HEX(0xE9EFF2); t.fieldErr=FCV_HEX(0xFDECEC);
  }

//+------------------------------------------------------------------+
//| Marinho — mais frio. Separa melhor de graficos com velas verdes e |
//| vermelhas, porque o painel inteiro fica numa familia que as velas |
//| nao ocupam.                                                       |
//+------------------------------------------------------------------+
void FusionPaletteMarinhoDark(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0x0A1020); t.surface=FCV_HEX(0x141D33); t.inset=FCV_HEX(0x070C18);
   t.line  =FCV_HEX(0x253352); t.soft   =FCV_HEX(0x1B2742);
   t.fg    =FCV_HEX(0xEAEEF8); t.muted  =FCV_HEX(0xA0ADC8); t.faint=FCV_HEX(0x74829E);
   t.acc   =FCV_HEX(0x4C8AE0); t.accs   =FCV_HEX(0x93B8F2); t.accd =FCV_HEX(0x16264A);
   t.good  =FCV_HEX(0x3BB07A); t.gdim   =FCV_HEX(0x0F3327);
   t.bad   =FCV_HEX(0xCE6F78); t.bdim   =FCV_HEX(0x351E23);
   t.warn  =FCV_HEX(0xD0A050); t.wdim   =FCV_HEX(0x342A16);
   t.onGood=FCV_HEX(0x04140D); t.onAcc  =FCV_HEX(0x050B18);
   t.shell =FCV_HEX(0x33436B);
   t.disabled=FCV_HEX(0x515F80); t.fieldDim=FCV_HEX(0x0E1628); t.fieldErr=FCV_HEX(0x2A171C);
  }

void FusionPaletteMarinhoLight(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0xEDF0F7); t.surface=FCV_HEX(0xFFFFFF); t.inset=FCV_HEX(0xF4F6FB);
   t.line  =FCV_HEX(0xD3DAE8); t.soft   =FCV_HEX(0xE4E9F3);
   t.fg    =FCV_HEX(0x101728); t.muted  =FCV_HEX(0x4F5B75); t.faint=FCV_HEX(0x8390A8);
   t.acc   =FCV_HEX(0x2A5FBF); t.accs   =FCV_HEX(0x1E4A99); t.accd =FCV_HEX(0xDEE8FA);
   t.good  =FCV_HEX(0x12784F); t.gdim   =FCV_HEX(0xDDF0E6);
   t.bad   =FCV_HEX(0xB0353E); t.bdim   =FCV_HEX(0xFAE3E4);
   t.warn  =FCV_HEX(0x8F6410); t.wdim   =FCV_HEX(0xF9EFD9);
   t.onGood=FCV_HEX(0xFFFFFF); t.onAcc  =FCV_HEX(0xFFFFFF);
   t.shell =FCV_HEX(0xBCC7DA);
   t.disabled=FCV_HEX(0xAAB4C8); t.fieldDim=FCV_HEX(0xEAEDF5); t.fieldErr=FCV_HEX(0xFDEBEC);
  }

//+------------------------------------------------------------------+
//| Ardosia — a paleta original, tingida de azul e com o texto        |
//| secundario mais claro. E a de menor risco: muda o que incomodava  |
//| sem mexer no que ja estava aprovado.                              |
//+------------------------------------------------------------------+
void FusionPaletteArdosiaDark(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0x0B1117); t.surface=FCV_HEX(0x16202B); t.inset=FCV_HEX(0x080D12);
   t.line  =FCV_HEX(0x283947); t.soft   =FCV_HEX(0x1D2A36);
   t.fg    =FCV_HEX(0xECF1F6); t.muted  =FCV_HEX(0xA2B2C0); t.faint=FCV_HEX(0x758897);
   t.acc   =FCV_HEX(0x4A96D6); t.accs   =FCV_HEX(0x8FC3EC); t.accd =FCV_HEX(0x113047);
   t.good  =FCV_HEX(0x3BB584); t.gdim   =FCV_HEX(0x0F3529);
   t.bad   =FCV_HEX(0xCE6F76); t.bdim   =FCV_HEX(0x332024);
   t.warn  =FCV_HEX(0xD3A048); t.wdim   =FCV_HEX(0x362B18);
   t.onGood=FCV_HEX(0x04140E); t.onAcc  =FCV_HEX(0x04121C);
   t.shell =FCV_HEX(0x35485A);
   t.disabled=FCV_HEX(0x53687A); t.fieldDim=FCV_HEX(0x101820); t.fieldErr=FCV_HEX(0x2B191D);
  }

void FusionPaletteArdosiaLight(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0xEFF2F7); t.surface=FCV_HEX(0xFFFFFF); t.inset=FCV_HEX(0xF4F6FA);
   t.line  =FCV_HEX(0xD5DCE6); t.soft   =FCV_HEX(0xE7ECF3);
   t.fg    =FCV_HEX(0x131A24); t.muted  =FCV_HEX(0x54627A); t.faint=FCV_HEX(0x8A96A8);
   t.acc   =FCV_HEX(0x2A6FB0); t.accs   =FCV_HEX(0x1E5A93); t.accd =FCV_HEX(0xDDEAF7);
   t.good  =FCV_HEX(0x17864C); t.gdim   =FCV_HEX(0xDFF3E7);
   t.bad   =FCV_HEX(0xC0353D); t.bdim   =FCV_HEX(0xFBE7E8);
   t.warn  =FCV_HEX(0x9C6B10); t.wdim   =FCV_HEX(0xFAF0DA);
   t.onGood=FCV_HEX(0xFFFFFF); t.onAcc  =FCV_HEX(0xFFFFFF);
   t.shell =FCV_HEX(0xC6D0DE);
   t.disabled=FCV_HEX(0xAEB8C6); t.fieldDim=FCV_HEX(0xEBEEF3); t.fieldErr=FCV_HEX(0xFDECEC);
  }

//+------------------------------------------------------------------+
//| Ambar — grafite quente. E a paleta com menos folga entre estados: |
//| o acento ocupa naturalmente a faixa de 'atencao', entao atencao   |
//| foi empurrada para laranja e o erro para um vermelho mais fechado.|
//+------------------------------------------------------------------+
void FusionPaletteAmbarDark(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0x14110D); t.surface=FCV_HEX(0x201C16); t.inset=FCV_HEX(0x0F0D09);
   t.line  =FCV_HEX(0x3A3327); t.soft   =FCV_HEX(0x2A251C);
   t.fg    =FCV_HEX(0xF5F0E6); t.muted  =FCV_HEX(0xBCB09B); t.faint=FCV_HEX(0x8A8070);
   t.acc   =FCV_HEX(0xD9A441); t.accs   =FCV_HEX(0xF0C77A); t.accd =FCV_HEX(0x3D2F14);
   t.good  =FCV_HEX(0x7FB069); t.gdim   =FCV_HEX(0x26301C);
   t.bad   =FCV_HEX(0xC9524F); t.bdim   =FCV_HEX(0x38201E);
   t.warn  =FCV_HEX(0xE08A2E); t.wdim   =FCV_HEX(0x3A2A12);
   t.onGood=FCV_HEX(0x0D1408); t.onAcc  =FCV_HEX(0x1A1206);
   t.shell =FCV_HEX(0x4A4132);
   t.disabled=FCV_HEX(0x6B6252); t.fieldDim=FCV_HEX(0x191510); t.fieldErr=FCV_HEX(0x2C1A18);
  }

void FusionPaletteAmbarLight(SCanvasTheme &t)
  {
   t.ground=FCV_HEX(0xF5F1E8); t.surface=FCV_HEX(0xFFFDF8); t.inset=FCV_HEX(0xFAF7F0);
   t.line  =FCV_HEX(0xDED5C4); t.soft   =FCV_HEX(0xEDE7DA);
   t.fg    =FCV_HEX(0x241E14); t.muted  =FCV_HEX(0x6B5F4B); t.faint=FCV_HEX(0x9A8E7A);
   t.acc   =FCV_HEX(0x9A6B12); t.accs   =FCV_HEX(0x7A5410); t.accd =FCV_HEX(0xF6E9CE);
   t.good  =FCV_HEX(0x4A7A2E); t.gdim   =FCV_HEX(0xE6F0DC);
   t.bad   =FCV_HEX(0xA83C2E); t.bdim   =FCV_HEX(0xF8E4DF);
   t.warn  =FCV_HEX(0xA85E14); t.wdim   =FCV_HEX(0xF8EBD6);
   t.onGood=FCV_HEX(0xFFFFFF); t.onAcc  =FCV_HEX(0xFFFFFF);
   t.shell =FCV_HEX(0xC9BCA4);
   t.disabled=FCV_HEX(0xB8AC96); t.fieldDim=FCV_HEX(0xF0ECE2); t.fieldErr=FCV_HEX(0xFAE9E4);
  }

//+------------------------------------------------------------------+
void FusionCanvasApplyPalette(SCanvasTheme &t,
                              const ENUM_FUSION_CANVAS_PALETTE palette,
                              const bool dark)
  {
   switch(palette)
     {
      case FUSION_PALETTE_MARINHO:
         if(dark) FusionPaletteMarinhoDark(t);  else FusionPaletteMarinhoLight(t);
         return;
      case FUSION_PALETTE_ARDOSIA:
         if(dark) FusionPaletteArdosiaDark(t);  else FusionPaletteArdosiaLight(t);
         return;
      case FUSION_PALETTE_AMBAR:
         if(dark) FusionPaletteAmbarDark(t);    else FusionPaletteAmbarLight(t);
         return;
      default:
         if(dark) FusionPalettePetroleoDark(t); else FusionPalettePetroleoLight(t);
         return;
     }
  }

string FusionCanvasPaletteName(const ENUM_FUSION_CANVAS_PALETTE palette)
  {
   switch(palette)
     {
      case FUSION_PALETTE_MARINHO: return "Marinho";
      case FUSION_PALETTE_ARDOSIA: return "Ardosia";
      case FUSION_PALETTE_AMBAR:   return "Ambar";
     }
   return "Petroleo";
  }

//--- Deteccao automatica: le a luminancia do fundo do grafico. 'color' e BGR,
//--- dai a ordem dos bytes. Grafico escuro pede painel claro e vice-versa.
bool FusionCanvasChartWantsLight(const long chart)
  {
   color bg=(color)ChartGetInteger(chart,CHART_COLOR_BACKGROUND);
   int r=(int)(bg&0xFF), g=(int)((bg>>8)&0xFF), b=(int)((bg>>16)&0xFF);
   double lum=(0.2126*r+0.7152*g+0.0722*b)/255.0;
   return (lum<0.45);
  }

#endif
