#ifndef __FUSION_BOLLINGER_STRATEGY_MQH__
#define __FUSION_BOLLINGER_STRATEGY_MQH__

#include "../Base/StrategyBase.mqh"

class CBollingerStrategy : public CStrategyBase
  {
private:
   int                 m_handle;
   int                 m_period;
   double              m_deviation;
   ENUM_APPLIED_PRICE  m_price;
   ENUM_BB_SIGNAL_MODE m_mode;
   ENUM_EXIT_MODE      m_exitMode;

   void                ReleaseHandle(void)
     {
      if(m_handle != INVALID_HANDLE)
         IndicatorRelease(m_handle);
      m_handle = INVALID_HANDLE;
     }

   bool                CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iBands(m_symbol, m_timeframe, m_period, 0, m_deviation, m_price);
      return (m_handle != INVALID_HANDLE);
     }

   bool                LoadBuffers(double &middle[],double &upper[],double &lower[])
     {
      ArrayResize(middle, 4);
      ArrayResize(upper, 4);
      ArrayResize(lower, 4);

      if(CopyBuffer(m_handle, 0, 0, 4, middle) < 4)
         return false;
      if(CopyBuffer(m_handle, 1, 0, 4, upper) < 4)
         return false;
      if(CopyBuffer(m_handle, 2, 0, 4, lower) < 4)
         return false;
      return true;
     }

   ENUM_SIGNAL_TYPE    EvaluateSignal(void)
     {
      double middle[];
      double upper[];
      double lower[];
      if(!LoadBuffers(middle, upper, lower))
         return SIGNAL_NONE;

      double close1 = iClose(m_symbol, m_timeframe, 1);
      double close2 = iClose(m_symbol, m_timeframe, 2);
      double high1  = iHigh(m_symbol, m_timeframe, 1);
      double low1   = iLow(m_symbol, m_timeframe, 1);

      switch(m_mode)
        {
         case BB_SIGNAL_REENTRY:
            if(close2 < lower[2] && close1 >= lower[1])
               return SIGNAL_BUY;
            if(close2 > upper[2] && close1 <= upper[1])
               return SIGNAL_SELL;
            break;

         case BB_SIGNAL_REBOUND:
            if(low1 <= lower[1] && close1 > lower[1])
               return SIGNAL_BUY;
            if(high1 >= upper[1] && close1 < upper[1])
               return SIGNAL_SELL;
            break;

         case BB_SIGNAL_BREAKOUT:
            if(close1 > upper[1])
               return SIGNAL_BUY;
            if(close1 < lower[1])
               return SIGNAL_SELL;
            break;
        }

      return SIGNAL_NONE;
     }

public:
                     CBollingerStrategy(void) : CStrategyBase("bollinger", "Bollinger", "BB", 6)
     {
      m_handle    = INVALID_HANDLE;
      m_period    = 20;
      m_deviation = 2.0;
      m_price     = PRICE_CLOSE;
      m_mode      = BB_SIGNAL_REENTRY;
      m_exitMode  = EXIT_OPPOSITE_SIGNAL;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol,const ENUM_TIMEFRAMES timeframe) override
     {
      if(!CStrategyBase::Initialize(logger, symbol, timeframe))
         return false;
      return CreateHandle();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandle();
      CStrategyBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled  = settings.useBollinger;
      m_magicNumber = settings.bbMagicNumber;
      m_priority = settings.bbPriority;
      m_mode     = settings.bbMode;
      m_exitMode = settings.bbExitMode;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.bbPeriod ||
                      m_deviation != settings.bbDeviation ||
                      m_price != settings.bbPrice);

      m_period    = settings.bbPeriod;
      m_deviation = settings.bbDeviation;
      m_price     = settings.bbPrice;

      if(!m_initialized)
         return true;

      if(scope == RELOAD_WARM || scope == RELOAD_COLD || changed)
         return CreateHandle();

      return true;
     }

   virtual ENUM_SIGNAL_TYPE GetEntrySignal(void) override
     {
      if(!m_enabled || !m_initialized)
         return SIGNAL_NONE;
      return EvaluateSignal();
     }

   virtual ENUM_SIGNAL_TYPE GetExitSignal(const ENUM_POSITION_TYPE currentPosition) override
     {
      if(m_exitMode != EXIT_OPPOSITE_SIGNAL)
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE signal = EvaluateSignal();
      if(currentPosition == POSITION_TYPE_BUY && signal == SIGNAL_SELL)
         return SIGNAL_SELL;
      if(currentPosition == POSITION_TYPE_SELL && signal == SIGNAL_BUY)
         return SIGNAL_BUY;

      return SIGNAL_NONE;
     }
  };

#endif
