#ifndef __FUSION_TREND_FILTER_MQH__
#define __FUSION_TREND_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CTrendFilter : public CFilterBase
  {
private:
   int               m_ma1Handle;
   int               m_ma2Handle;
   bool              m_ma1Enabled;
   bool              m_ma2Enabled;
   int               m_period;
   ENUM_MA_METHOD    m_method;
   ENUM_APPLIED_PRICE m_price;
   int               m_sellPeriod;
   ENUM_TIMEFRAMES   m_sellTimeframe;
   ENUM_MA_METHOD    m_sellMethod;
   ENUM_APPLIED_PRICE m_sellPrice;

   void              ReleaseHandle(void)
     {
      ReleaseIndicatorHandle(m_ma1Handle);
      ReleaseIndicatorHandle(m_ma2Handle);
     }

   bool              CreateHandles(void)
     {
      ReleaseHandle();
      if(m_ma1Enabled)
        {
         m_ma1Handle = iMA(m_symbol, m_timeframe, m_period, 0, m_method, m_price);
         if(m_ma1Handle == INVALID_HANDLE)
           {
            ReleaseHandle();
            return false;
           }
        }

      if(m_ma2Enabled)
        {
         m_ma2Handle = iMA(m_symbol, m_sellTimeframe, m_sellPeriod, 0, m_sellMethod, m_sellPrice);
         if(m_ma2Handle == INVALID_HANDLE)
           {
            ReleaseHandle();
            return false;
           }
        }
      return true;
     }

   bool              CurrentMAValue(const int handle,double &value) const
     {
      value = 0.0;
      if(handle == INVALID_HANDLE)
         return false;

      double buffer[];
      ArrayResize(buffer, 1);
      if(CopyBuffer(handle, 0, 0, 1, buffer) != 1 || buffer[0] <= 0.0)
         return false;

      value = buffer[0];
      return true;
     }

   bool              BlocksSignal(const ENUM_SIGNAL_TYPE signal,
                                  const double currentPrice,
                                  const double maValue,
                                  const string label,
                                  const int period,
                                  string &reason) const
     {
      if(signal == SIGNAL_BUY && currentPrice <= maValue)
        {
         reason = "preco atual nao esta acima da " + label + " (" + IntegerToString(period) + ")";
         return true;
        }
      if(signal == SIGNAL_SELL && currentPrice >= maValue)
        {
         reason = "preco atual nao esta abaixo da " + label + " (" + IntegerToString(period) + ")";
         return true;
        }
      return false;
     }

public:
                     CTrendFilter(void) : CFilterBase("trend_filter", "Trend Filter")
     {
      m_ma1Handle = INVALID_HANDLE;
      m_ma2Handle = INVALID_HANDLE;
      m_ma1Enabled = false;
      m_ma2Enabled = false;
      m_period = 50;
      m_method = MODE_SMA;
      m_price  = PRICE_CLOSE;
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
      m_enabled = (settings.trendMA1Enabled || settings.trendMA2Enabled);

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_ma1Enabled != settings.trendMA1Enabled ||
                      m_ma2Enabled != settings.trendMA2Enabled ||
                      m_period != settings.trendMAPeriod ||
                      m_timeframe != settings.trendMATimeframe ||
                      m_method != settings.trendMAMethod ||
                      m_price  != settings.trendMAPrice ||
                      m_sellPeriod != settings.trendSellMAPeriod ||
                      m_sellTimeframe != settings.trendSellMATimeframe ||
                      m_sellMethod != settings.trendSellMAMethod ||
                      m_sellPrice != settings.trendSellMAPrice);

      m_ma1Enabled = settings.trendMA1Enabled;
      m_ma2Enabled = settings.trendMA2Enabled;
      m_period = settings.trendMAPeriod;
      m_timeframe = settings.trendMATimeframe;
      m_method = settings.trendMAMethod;
      m_price  = settings.trendMAPrice;
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

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed ||
         (m_ma1Enabled && m_ma1Handle == INVALID_HANDLE) ||
         (m_ma2Enabled && m_ma2Handle == INVALID_HANDLE))
         return CreateHandles();

      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;
      if(m_ma1Enabled && m_ma2Enabled)
        {
         long ma1Horizon = FusionMAHorizonSeconds(m_period, m_timeframe);
         long ma2Horizon = FusionMAHorizonSeconds(m_sellPeriod, m_sellTimeframe);
         if(ma1Horizon <= 0 || ma2Horizon <= 0 || ma1Horizon <= ma2Horizon)
           {
            reason = "configuracao invalida: M1 deve ser mais longa que M2";
            return false;
           }
        }

      MqlTick tick;
      if(!SymbolInfoTick(m_symbol, tick))
        {
         reason = "preco atual indisponivel";
         return false;
        }

      double currentPrice = (tick.last > 0.0) ? tick.last : tick.bid;
      if(currentPrice <= 0.0)
        {
         reason = "preco atual indisponivel";
         return false;
        }

      if(m_ma1Enabled)
        {
         double ma1Value = 0.0;
         if(!CurrentMAValue(m_ma1Handle, ma1Value))
           {
            reason = "M1 indisponivel";
            return false;
           }
         if(BlocksSignal(signal, currentPrice, ma1Value, "M1", m_period, reason))
            return false;
        }

      if(m_ma2Enabled)
        {
         double ma2Value = 0.0;
         if(!CurrentMAValue(m_ma2Handle, ma2Value))
           {
            reason = "M2 indisponivel";
            return false;
           }
         if(BlocksSignal(signal, currentPrice, ma2Value, "M2", m_sellPeriod, reason))
            return false;
        }

      return true;
     }
  };

#endif
