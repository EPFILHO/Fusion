#ifndef __FUSION_RSI_FILTER_MQH__
#define __FUSION_RSI_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CRSIFilter : public CFilterBase
  {
private:
   int                m_handle;
   ENUM_RSI_FILTER_MODE m_mode;
   int                m_period;
   int                m_buyMin;
   int                m_sellMax;
   ENUM_APPLIED_PRICE m_price;

   void               ReleaseHandle(void)
     {
      ReleaseIndicatorHandle(m_handle);
     }

   bool               CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iRSI(m_symbol, m_timeframe, m_period, m_price);
      return (m_handle != INVALID_HANDLE);
     }

   bool               BlockAdvanced(const ENUM_SIGNAL_TYPE signal,const double rsi,string &reason) const
     {
      if(signal == SIGNAL_BUY && rsi < m_buyMin)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " abaixo do minimo de compra " + IntegerToString(m_buyMin);
         return true;
        }

      if(signal == SIGNAL_SELL && rsi > m_sellMax)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " acima do maximo de venda " + IntegerToString(m_sellMax);
         return true;
        }

      return false;
     }

   bool               BlockDirection(const ENUM_SIGNAL_TYPE signal,const double rsi,string &reason) const
     {
      int level = m_buyMin;
      if(signal == SIGNAL_BUY && rsi < level)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " abaixo da linha de direcao " + IntegerToString(level);
         return true;
        }

      if(signal == SIGNAL_SELL && rsi > level)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " acima da linha de direcao " + IntegerToString(level);
         return true;
        }

      return false;
     }

   bool               BlockNeutral(const ENUM_SIGNAL_TYPE signal,const double rsi,string &reason) const
     {
      int buyLevel = m_buyMin;
      int sellLevel = m_sellMax;
      if(signal == SIGNAL_BUY && rsi < buyLevel)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " abaixo da zona de compra " + IntegerToString(buyLevel);
         return true;
        }

      if(signal == SIGNAL_SELL && rsi > sellLevel)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " acima da zona de venda " + IntegerToString(sellLevel);
         return true;
        }

      return false;
     }

   bool               BlockExtremes(const double rsi,string &reason) const
     {
      int oversold = m_buyMin;
      int overbought = m_sellMax;
      if(rsi <= oversold || rsi >= overbought)
        {
         reason = "RSI " + DoubleToString(rsi, 2) + " em zona extrema " +
                  IntegerToString(oversold) + "-" + IntegerToString(overbought);
         return true;
        }

      return false;
     }

public:
                     CRSIFilter(void) : CFilterBase("rsi_filter", "RSI Filter")
     {
      m_handle  = INVALID_HANDLE;
      m_mode    = RSI_FILTER_ADVANCED;
      m_period  = 14;
      m_buyMin  = 50;
      m_sellMax = 50;
      m_price   = PRICE_CLOSE;
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
      m_enabled = settings.useRSIFilter;
      m_mode    = settings.rsiFilterMode;
      m_buyMin  = settings.rsiFilterBuyMin;
      m_sellMax = settings.rsiFilterSellMax;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.rsiFilterPeriod ||
                      m_timeframe != settings.rsiFilterTimeframe ||
                      m_price != settings.rsiFilterPrice);
      m_period     = settings.rsiFilterPeriod;
      m_timeframe  = settings.rsiFilterTimeframe;
      m_price      = settings.rsiFilterPrice;

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
      if(m_handle == INVALID_HANDLE)
         return true;

      double buffer[];
      ArrayResize(buffer, 2);
      ArraySetAsSeries(buffer, true);
      if(CopyBuffer(m_handle, 0, 0, 2, buffer) < 2)
         return true;

      double rsi = buffer[1];

      bool blocked = false;
      if(m_mode == RSI_FILTER_DIRECTION)
         blocked = BlockDirection(signal, rsi, reason);
      else if(m_mode == RSI_FILTER_NEUTRAL)
         blocked = BlockNeutral(signal, rsi, reason);
      else if(m_mode == RSI_FILTER_EXTREMES)
         blocked = BlockExtremes(rsi, reason);
      else
         blocked = BlockAdvanced(signal, rsi, reason);

      if(blocked)
         return false;

      return true;
     }
  };

#endif
