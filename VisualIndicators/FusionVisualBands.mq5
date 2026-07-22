#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "1.056"
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

input string             InpShortName = "Fusion Visual BB";
input color              InpLineColor = clrDodgerBlue;
input int                InpPeriod = 20;
input double             InpDeviation = 2.0;
input ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE;

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
