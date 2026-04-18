#ifndef __MODULAR_EA_RSI_FILTER_MQH__
#define __MODULAR_EA_RSI_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CRSIFilter : public CFilterBase
  {
private:
   int                m_handle;
   int                m_period;
   int                m_buyMin;
   int                m_sellMax;
   ENUM_APPLIED_PRICE m_price;

   void               ReleaseHandle(void)
     {
      if(m_handle != INVALID_HANDLE)
         IndicatorRelease(m_handle);
      m_handle = INVALID_HANDLE;
     }

   bool               CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iRSI(m_symbol, m_timeframe, m_period, m_price);
      return (m_handle != INVALID_HANDLE);
     }

public:
                     CRSIFilter(void) : CFilterBase("rsi_filter", "RSI Filter")
     {
      m_handle  = INVALID_HANDLE;
      m_period  = 14;
      m_buyMin  = 50;
      m_sellMax = 50;
      m_price   = PRICE_CLOSE;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol,const ENUM_TIMEFRAMES timeframe) override
     {
      if(!CFilterBase::Initialize(logger, symbol, timeframe))
         return false;
      return CreateHandle();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandle();
      CFilterBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled = settings.useRSIFilter;
      m_buyMin  = settings.rsiFilterBuyMin;
      m_sellMax = settings.rsiFilterSellMax;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.rsiFilterPeriod || m_price != settings.rsiFilterPrice);
      m_period     = settings.rsiFilterPeriod;
      m_price      = settings.rsiFilterPrice;

      if(!m_initialized)
         return true;

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed)
         return CreateHandle();

      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;

      double buffer[];
      ArrayResize(buffer, 2);
      if(CopyBuffer(m_handle, 0, 0, 2, buffer) < 2)
         return true;

      double rsi = buffer[1];

      if(signal == SIGNAL_BUY && rsi < m_buyMin)
        {
         reason = "RSI filter blocked BUY";
         return false;
        }

      if(signal == SIGNAL_SELL && rsi > m_sellMax)
        {
         reason = "RSI filter blocked SELL";
         return false;
        }

      return true;
     }
  };

#endif

