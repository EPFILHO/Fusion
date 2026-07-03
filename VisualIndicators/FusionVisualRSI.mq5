#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "1.054"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input string             InpShortName = "Fusion Visual RSI";
input int                InpPeriod = 14;
input ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE;

double RSIBuffer[];
int    RSIHandle = INVALID_HANDLE;

void ReleaseRSIHandle(void)
  {
   if(RSIHandle == INVALID_HANDLE)
      return;
   IndicatorRelease(RSIHandle);
   RSIHandle = INVALID_HANDLE;
  }

int OnInit(void)
  {
   SetIndexBuffer(0, RSIBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(0, InpPeriod));
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   IndicatorSetDouble(INDICATOR_MINIMUM, 0.0);
   IndicatorSetDouble(INDICATOR_MAXIMUM, 100.0);
   IndicatorSetString(INDICATOR_SHORTNAME, InpShortName);

   RSIHandle = iRSI(_Symbol, _Period, InpPeriod, InpPrice);
   if(RSIHandle == INVALID_HANDLE)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ReleaseRSIHandle();
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
   if(BarsCalculated(RSIHandle) < ratesTotal)
      return prevCalculated;

   int toCopy = ratesTotal;
   if(prevCalculated >= 0 && prevCalculated <= ratesTotal)
     {
      toCopy = ratesTotal - prevCalculated;
      if(prevCalculated > 0)
         toCopy++;
     }

   if(CopyBuffer(RSIHandle, 0, 0, toCopy, RSIBuffer) <= 0)
      return prevCalculated;
   return ratesTotal;
  }
