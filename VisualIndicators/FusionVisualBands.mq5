#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "2.000"
//--- Aba Comum das Propriedades. Tem de ficar no modulo principal: #property
//--- description dentro de include nao chega ao dialogo.
#property description "Indicador exclusivamente visual."
#property description "Alteracoes nesta janela afetam somente a exibicao no grafico."
#property description "Nao alteram estrategias, filtros, perfis ou operacoes do Fusion."
#property description "O Identificador interno e reservado ao Fusion e nao deve ser alterado."
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "BB Media"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "BB Superior"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "BB Inferior"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

//--- ⚠ CONTRATO POSICIONAL. O Fusion anexa este indicador por iCustom
//--- (UI/ChartIndicatorVisualizer.mqh), que passa os 6 argumentos por POSICAO e
//--- nunca por nome. Ordem, tipo e quantidade sao o contrato; o
//--- input(name="...") e so o rotulo do dialogo e nao entra nele.
//---
//--- As tres linhas compartilham cor e estilo de proposito: a aba Layout do
//--- painel tem uma unica entrada "Bandas", nao tres.
input(name="Identificador interno (nao alterar)")   string             InpShortName = "Fusion Visual BB";
input(name="Cor das bandas")              color              InpLineColor = clrDodgerBlue;
input(name="Estilo das bandas")           ENUM_LINE_STYLE    InpLineStyle = STYLE_SOLID;
input(name="Periodo das bandas")          int                InpPeriod = 20;
input(name="Desvio padrao das bandas")    double             InpDeviation = 2.0;
input(name="Preco das bandas")            ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE;

double MiddleBuffer[];
double UpperBuffer[];
double LowerBuffer[];
int    BandsHandle = INVALID_HANDLE;

void ReleaseBandsHandle(void)
  {
   if(BandsHandle == INVALID_HANDLE)
      return;
   IndicatorRelease(BandsHandle);
   BandsHandle = INVALID_HANDLE;
  }

bool CopyBandsBuffer(const int sourceBuffer,const int ratesTotal,const int toCopy,double &target[])
  {
   if(BarsCalculated(BandsHandle) < ratesTotal)
      return false;
   return (CopyBuffer(BandsHandle, sourceBuffer, 0, toCopy, target) > 0);
  }

int OnInit(void)
  {
   SetIndexBuffer(0, MiddleBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, UpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowerBuffer, INDICATOR_DATA);

   int drawBegin = MathMax(0, InpPeriod - 1);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, drawBegin);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, drawBegin);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, drawBegin);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpLineColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpLineColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, InpLineColor);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, InpLineStyle);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, InpLineStyle);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, InpLineStyle);
   IndicatorSetString(INDICATOR_SHORTNAME, InpShortName);

   BandsHandle = iBands(_Symbol, _Period, InpPeriod, 0, InpDeviation, InpPrice);
   if(BandsHandle == INVALID_HANDLE)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ReleaseBandsHandle();
  }

int OnCalculate(const int ratesTotal,
                const int prevCalculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickVolume[],
                const long &volume[],
                const int &spread[])
  {
   int toCopy = ratesTotal;
   if(prevCalculated >= 0 && prevCalculated <= ratesTotal)
     {
      toCopy = ratesTotal - prevCalculated;
      if(prevCalculated > 0)
         toCopy++;
     }

   if(!CopyBandsBuffer(0, ratesTotal, toCopy, MiddleBuffer) ||
      !CopyBandsBuffer(1, ratesTotal, toCopy, UpperBuffer) ||
      !CopyBandsBuffer(2, ratesTotal, toCopy, LowerBuffer))
      return prevCalculated;

   return ratesTotal;
  }
