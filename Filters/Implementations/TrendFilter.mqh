#ifndef __FUSION_TREND_FILTER_MQH__
#define __FUSION_TREND_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CTrendFilter : public CFilterBase
  {
private:
   int               m_handle;
   int               m_period;
   ENUM_MA_METHOD    m_method;
   ENUM_APPLIED_PRICE m_price;

   void              ReleaseHandle(void)
     {
      if(m_handle != INVALID_HANDLE)
         IndicatorRelease(m_handle);
      m_handle = INVALID_HANDLE;
     }

   bool              CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iMA(m_symbol, m_timeframe, m_period, 0, m_method, m_price);
      return (m_handle != INVALID_HANDLE);
     }

public:
                     CTrendFilter(void) : CFilterBase("trend_filter", "Trend Filter")
     {
      m_handle = INVALID_HANDLE;
      m_period = 50;
      m_method = MODE_SMA;
      m_price  = PRICE_CLOSE;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CFilterBase::Initialize(logger, symbol))
         return false;
      if(!m_enabled)
         return true;
      return CreateHandle();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandle();
      CFilterBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled = settings.useTrendFilter;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.trendMAPeriod ||
                      m_timeframe != settings.trendMATimeframe ||
                      m_method != settings.trendMAMethod ||
                      m_price  != settings.trendMAPrice);

      m_period = settings.trendMAPeriod;
      m_timeframe = settings.trendMATimeframe;
      m_method = settings.trendMAMethod;
      m_price  = settings.trendMAPrice;

      if(!m_initialized)
         return true;

      if(!m_enabled)
        {
         ReleaseHandle();
         return true;
        }

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed || m_handle == INVALID_HANDLE)
         return CreateHandle();

      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;

      double ma[];
      ArrayResize(ma, 2);
      if(CopyBuffer(m_handle, 0, 0, 2, ma) < 2)
         return true;

      double close1 = iClose(m_symbol, m_timeframe, 1);

      if(signal == SIGNAL_BUY && close1 < ma[1])
        {
         reason = "Trend filter blocked BUY";
         return false;
        }

      if(signal == SIGNAL_SELL && close1 > ma[1])
        {
         reason = "Trend filter blocked SELL";
         return false;
        }

      return true;
     }
  };

#endif
