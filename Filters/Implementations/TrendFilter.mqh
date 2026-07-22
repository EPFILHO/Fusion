#ifndef __FUSION_TREND_FILTER_MQH__
#define __FUSION_TREND_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CTrendFilter : public CFilterBase
  {
private:
   int               m_handle;
   int               m_sellHandle;
   int               m_period;
   ENUM_MA_METHOD    m_method;
   ENUM_APPLIED_PRICE m_price;
   bool              m_dualBarrierEnabled;
   int               m_sellPeriod;
   ENUM_TIMEFRAMES   m_sellTimeframe;
   ENUM_MA_METHOD    m_sellMethod;
   ENUM_APPLIED_PRICE m_sellPrice;

   void              ReleaseHandle(void)
     {
      ReleaseIndicatorHandle(m_handle);
      ReleaseIndicatorHandle(m_sellHandle);
     }

   bool              CreateHandles(void)
     {
      ReleaseHandle();
      m_handle = iMA(m_symbol, m_timeframe, m_period, 0, m_method, m_price);
      if(m_handle == INVALID_HANDLE)
         return false;
      if(!m_dualBarrierEnabled)
         return true;

      m_sellHandle = iMA(m_symbol, m_sellTimeframe, m_sellPeriod, 0, m_sellMethod, m_sellPrice);
      if(m_sellHandle != INVALID_HANDLE)
         return true;

      ReleaseHandle();
      return false;
     }

public:
                     CTrendFilter(void) : CFilterBase("trend_filter", "Trend Filter")
     {
      m_handle = INVALID_HANDLE;
      m_sellHandle = INVALID_HANDLE;
      m_period = 50;
      m_method = MODE_SMA;
      m_price  = PRICE_CLOSE;
      m_dualBarrierEnabled = false;
      m_sellPeriod = 21;
      m_sellTimeframe = FUSION_DEFAULT_TIMEFRAME;
      m_sellMethod = MODE_SMA;
      m_sellPrice = PRICE_CLOSE;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CFilterBase::Initialize(logger, symbol))
         return false;
      if(!m_enabled)
         return true;
      return CreateHandles();
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
                      m_price  != settings.trendMAPrice ||
                      m_dualBarrierEnabled != settings.trendDualBarrierEnabled ||
                      m_sellPeriod != settings.trendSellMAPeriod ||
                      m_sellTimeframe != settings.trendSellMATimeframe ||
                      m_sellMethod != settings.trendSellMAMethod ||
                      m_sellPrice != settings.trendSellMAPrice);

      m_period = settings.trendMAPeriod;
      m_timeframe = settings.trendMATimeframe;
      m_method = settings.trendMAMethod;
      m_price  = settings.trendMAPrice;
      m_dualBarrierEnabled = settings.trendDualBarrierEnabled;
      m_sellPeriod = settings.trendSellMAPeriod;
      m_sellTimeframe = settings.trendSellMATimeframe;
      m_sellMethod = settings.trendSellMAMethod;
      m_sellPrice = settings.trendSellMAPrice;

      if(!m_initialized)
         return true;

      if(!m_enabled)
        {
         ReleaseHandle();
         return true;
        }

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed || m_handle == INVALID_HANDLE ||
         (m_dualBarrierEnabled && m_sellHandle == INVALID_HANDLE))
         return CreateHandles();

      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;
      int activeHandle = (m_dualBarrierEnabled && signal == SIGNAL_SELL) ? m_sellHandle : m_handle;
      ENUM_TIMEFRAMES activeTimeframe = (m_dualBarrierEnabled && signal == SIGNAL_SELL) ? m_sellTimeframe : m_timeframe;
      int activePeriod = (m_dualBarrierEnabled && signal == SIGNAL_SELL) ? m_sellPeriod : m_period;
      if(activeHandle == INVALID_HANDLE)
        {
         reason = "indicador indisponivel";
         return false;
        }

      double ma[];
      ArrayResize(ma, 2);
      ArraySetAsSeries(ma, true);
      if(CopyBuffer(activeHandle, 0, 0, 2, ma) < 2)
        {
         reason = "sem dados suficientes do indicador";
         return false;
        }

      double close1 = iClose(m_symbol, activeTimeframe, 1);
      if(close1 <= 0.0)
        {
         reason = "preco fechado indisponivel";
         return false;
        }

      if(signal == SIGNAL_BUY && close1 < ma[1])
        {
         reason = "preco abaixo da MA de compra (" + IntegerToString(activePeriod) + ")";
         return false;
        }

      if(signal == SIGNAL_SELL && close1 > ma[1])
        {
         reason = m_dualBarrierEnabled
                  ? "preco acima da MA de venda (" + IntegerToString(activePeriod) + ")"
                  : "preco acima da MA (" + IntegerToString(activePeriod) + ")";
         return false;
        }

      return true;
     }
  };

#endif
