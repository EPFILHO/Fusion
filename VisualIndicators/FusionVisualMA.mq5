#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "1.056"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "MA Rapida"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "MA Lenta"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "Trend MA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

input string             InpShortName = "Fusion Visual MA";
input bool               InpFastEnabled = true;
input color              InpFastColor = clrLime;
input int                InpFastPeriod = 9;
input ENUM_MA_METHOD     InpFastMethod = MODE_EMA;
input ENUM_APPLIED_PRICE InpFastPrice = PRICE_CLOSE;
input bool               InpSlowEnabled = true;
input color              InpSlowColor = clrRed;
input int                InpSlowPeriod = 21;
input ENUM_MA_METHOD     InpSlowMethod = MODE_EMA;
input ENUM_APPLIED_PRICE InpSlowPrice = PRICE_CLOSE;
input bool               InpTrendEnabled = false;
input color              InpTrendColor = clrMagenta;
input int                InpTrendPeriod = 50;
input ENUM_MA_METHOD     InpTrendMethod = MODE_SMA;
input ENUM_APPLIED_PRICE InpTrendPrice = PRICE_CLOSE;

double FastBuffer[];
double SlowBuffer[];
double TrendBuffer[];
int    FastHandle = INVALID_HANDLE;
int    SlowHandle = INVALID_HANDLE;
int    TrendHandle = INVALID_HANDLE;

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

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, InpFastEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, InpSlowEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, InpTrendEnabled ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(0, InpFastPeriod - 1));
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(0, InpSlowPeriod - 1));
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MathMax(0, InpTrendPeriod - 1));
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpFastColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpSlowColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, InpTrendColor);
   IndicatorSetString(INDICATOR_SHORTNAME, InpShortName);

   if(!CreateMAHandle(InpFastEnabled, InpFastPeriod, InpFastMethod, InpFastPrice, FastHandle) ||
      !CreateMAHandle(InpSlowEnabled, InpSlowPeriod, InpSlowMethod, InpSlowPrice, SlowHandle) ||
      !CreateMAHandle(InpTrendEnabled, InpTrendPeriod, InpTrendMethod, InpTrendPrice, TrendHandle))
      return INIT_FAILED;

   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ReleaseMAHandle(FastHandle);
   ReleaseMAHandle(SlowHandle);
   ReleaseMAHandle(TrendHandle);
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
      !CopyMABuffer(TrendHandle, ratesTotal, toCopy, TrendBuffer))
      return prevCalculated;

   return ratesTotal;
  }
