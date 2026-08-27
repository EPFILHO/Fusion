#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "2.000"
//--- Aba Comum das Propriedades. Tem de ficar no modulo principal: #property
//--- description dentro de include nao chega ao dialogo.
#property description "Indicador exclusivamente visual."
#property description "Alterações nesta janela afetam somente a exibição no gráfico."
#property description "Não alteram estratégias, filtros, perfis ou operações do Fusion."
#property description "O Identificador interno é reservado ao Fusion e não deve ser alterado."
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_label1  "MA Rápida"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "MA Lenta"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "Trend MA1"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "Trend MA2"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrOrange
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//--- ⚠ CONTRATO POSICIONAL. O Fusion anexa este indicador por iCustom
//--- (UI/ChartIndicatorVisualizer.mqh), que passa os 25 argumentos por POSICAO
//--- e nunca por nome. Ordem, tipo e quantidade sao o contrato; o
//--- input(name="...") e so o rotulo do dialogo e nao entra nele. Renomear o
//--- identificador tambem nao quebra o iCustom, mas quebra qualquer .set que
//--- ja exista — o identificador e a chave la.
//---
//--- Os quatro nomes de linha ("MA Rapida", "MA Lenta", "Trend MA1",
//--- "Trend MA2") sao os MESMOS de tres lugares: o indicator_labelN acima, a
//--- legenda do grafico e a aba Layout do painel. Nao renomeie em um so.
input(name="Identificador interno (não alterar)")   string             InpShortName = "Fusion Visual MA";

input(name="Exibir a MA Rápida")          bool               InpFastEnabled = true;
input(name="Cor da MA Rápida")            color              InpFastColor = clrLime;
input(name="Estilo da MA Rápida")         ENUM_LINE_STYLE    InpFastStyle = STYLE_SOLID;
input(name="Período da MA Rápida")        int                InpFastPeriod = 9;
input(name="Método da MA Rápida")         ENUM_MA_METHOD     InpFastMethod = MODE_EMA;
input(name="Preço da MA Rápida")          ENUM_APPLIED_PRICE InpFastPrice = PRICE_CLOSE;

input(name="Exibir a MA Lenta")           bool               InpSlowEnabled = true;
input(name="Cor da MA Lenta")             color              InpSlowColor = clrRed;
input(name="Estilo da MA Lenta")          ENUM_LINE_STYLE    InpSlowStyle = STYLE_SOLID;
input(name="Período da MA Lenta")         int                InpSlowPeriod = 21;
input(name="Método da MA Lenta")          ENUM_MA_METHOD     InpSlowMethod = MODE_EMA;
input(name="Preço da MA Lenta")           ENUM_APPLIED_PRICE InpSlowPrice = PRICE_CLOSE;

input(name="Exibir a Trend MA1")          bool               InpTrendEnabled = false;
input(name="Cor da Trend MA1")            color              InpTrendColor = clrMagenta;
input(name="Estilo da Trend MA1")         ENUM_LINE_STYLE    InpTrendStyle = STYLE_SOLID;
input(name="Período da Trend MA1")        int                InpTrendPeriod = 50;
input(name="Método da Trend MA1")         ENUM_MA_METHOD     InpTrendMethod = MODE_SMA;
input(name="Preço da Trend MA1")          ENUM_APPLIED_PRICE InpTrendPrice = PRICE_CLOSE;

input(name="Exibir a Trend MA2")          bool               InpTrend2Enabled = false;
input(name="Cor da Trend MA2")            color              InpTrend2Color = clrOrange;
input(name="Estilo da Trend MA2")         ENUM_LINE_STYLE    InpTrend2Style = STYLE_SOLID;
input(name="Período da Trend MA2")        int                InpTrend2Period = 21;
input(name="Método da Trend MA2")         ENUM_MA_METHOD     InpTrend2Method = MODE_SMA;
input(name="Preço da Trend MA2")          ENUM_APPLIED_PRICE InpTrend2Price = PRICE_CLOSE;

double FastBuffer[];
double SlowBuffer[];
double TrendBuffer[];
double Trend2Buffer[];
int    FastHandle = INVALID_HANDLE;
int    SlowHandle = INVALID_HANDLE;
int    TrendHandle = INVALID_HANDLE;
int    Trend2Handle = INVALID_HANDLE;

bool CreateMAHandle(const bool enabled,
                    const int period,
                    const ENUM_MA_METHOD method,
                    const ENUM_APPLIED_PRICE price,
                    int &handle)
  {
   handle = INVALID_HANDLE;
   if(!enabled)
      return true;
   handle = iMA(_Symbol, _Period, period, 0, method, price);
   return (handle != INVALID_HANDLE);
  }

void ReleaseMAHandle(int &handle)
  {
   if(handle == INVALID_HANDLE)
      return;
   IndicatorRelease(handle);
   handle = INVALID_HANDLE;
  }

bool CopyMABuffer(const int handle,const int ratesTotal,const int toCopy,double &buffer[])
  {
   if(handle == INVALID_HANDLE)
      return true;
   if(BarsCalculated(handle) < ratesTotal)
      return false;
   return (CopyBuffer(handle, 0, 0, toCopy, buffer) > 0);
  }

int OnInit(void)
  {
   SetIndexBuffer(0, FastBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SlowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, TrendBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, Trend2Buffer, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, InpFastEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, InpSlowEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, InpTrendEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, InpTrend2Enabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(0, InpFastPeriod - 1));
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(0, InpSlowPeriod - 1));
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MathMax(0, InpTrendPeriod - 1));
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, MathMax(0, InpTrend2Period - 1));
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpFastColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpSlowColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, InpTrendColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, InpTrend2Color);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, InpFastStyle);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, InpSlowStyle);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, InpTrendStyle);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, InpTrend2Style);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, InpFastStyle == STYLE_SOLID ? 2 : 1);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, InpSlowStyle == STYLE_SOLID ? 2 : 1);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, InpTrendStyle == STYLE_SOLID ? 2 : 1);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, InpTrend2Style == STYLE_SOLID ? 2 : 1);
   IndicatorSetString(INDICATOR_SHORTNAME, InpShortName);

   if(!CreateMAHandle(InpFastEnabled, InpFastPeriod, InpFastMethod, InpFastPrice, FastHandle) ||
      !CreateMAHandle(InpSlowEnabled, InpSlowPeriod, InpSlowMethod, InpSlowPrice, SlowHandle) ||
      !CreateMAHandle(InpTrendEnabled, InpTrendPeriod, InpTrendMethod, InpTrendPrice, TrendHandle) ||
      !CreateMAHandle(InpTrend2Enabled, InpTrend2Period, InpTrend2Method, InpTrend2Price, Trend2Handle))
      return INIT_FAILED;

   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ReleaseMAHandle(FastHandle);
   ReleaseMAHandle(SlowHandle);
   ReleaseMAHandle(TrendHandle);
   ReleaseMAHandle(Trend2Handle);
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

   if(!CopyMABuffer(FastHandle, ratesTotal, toCopy, FastBuffer) ||
      !CopyMABuffer(SlowHandle, ratesTotal, toCopy, SlowBuffer) ||
      !CopyMABuffer(TrendHandle, ratesTotal, toCopy, TrendBuffer) ||
      !CopyMABuffer(Trend2Handle, ratesTotal, toCopy, Trend2Buffer))
      return prevCalculated;

   return ratesTotal;
  }
