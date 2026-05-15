#ifndef __FUSION_RSI_STRATEGY_MQH__
#define __FUSION_RSI_STRATEGY_MQH__

#include "../Base/StrategyBase.mqh"

class CRSIStrategy : public CStrategyBase
  {
private:
   int                  m_handle;
   int                  m_period;
   int                  m_oversold;
   int                  m_overbought;
   int                  m_middle;
   ENUM_RSI_SIGNAL_MODE m_mode;
   ENUM_APPLIED_PRICE   m_price;
   ENUM_EXIT_MODE       m_exitMode;

   void                 ReleaseHandle(void)
     {
      ReleaseIndicatorHandle(m_handle);
     }

   bool                 CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iRSI(m_symbol, m_timeframe, m_period, m_price);
      return (m_handle != INVALID_HANDLE);
     }

   bool                 LoadBuffer(double &buffer[])
     {
      ArrayResize(buffer, 4);
      return (CopyBuffer(m_handle, 0, 0, 4, buffer) >= 4);
     }

   ENUM_SIGNAL_TYPE     EvaluateSignal(void)
     {
      double buffer[];
      if(!LoadBuffer(buffer))
         return SIGNAL_NONE;

      double current  = buffer[1];
      double previous = buffer[2];

      switch(m_mode)
        {
         case RSI_SIGNAL_CROSSOVER:
            if(previous <= m_oversold && current > m_oversold)
               return SIGNAL_BUY;
            if(previous >= m_overbought && current < m_overbought)
               return SIGNAL_SELL;
            break;

         case RSI_SIGNAL_ZONE:
            if(current <= m_oversold)
               return SIGNAL_BUY;
            if(current >= m_overbought)
               return SIGNAL_SELL;
            break;

         case RSI_SIGNAL_MIDDLE:
            if(previous < m_middle && current >= m_middle)
               return SIGNAL_BUY;
            if(previous > m_middle && current <= m_middle)
               return SIGNAL_SELL;
            break;
        }

      return SIGNAL_NONE;
     }

public:
                     CRSIStrategy(void) : CStrategyBase("rsi", "RSI", "RSI", 8)
     {
      m_handle     = INVALID_HANDLE;
      m_period     = 14;
      m_oversold   = 30;
      m_overbought = 70;
      m_middle     = 50;
      m_mode       = RSI_SIGNAL_CROSSOVER;
      m_price      = PRICE_CLOSE;
      m_exitMode   = EXIT_OPPOSITE_SIGNAL;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CStrategyBase::Initialize(logger, symbol))
         return false;
      if(!m_enabled)
         return true;
      return CreateHandle();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandle();
      CStrategyBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled  = settings.useRSI;
      m_priority = settings.rsiPriority;
      m_oversold = settings.rsiOversold;
      m_overbought = settings.rsiOverbought;
      m_middle   = settings.rsiMiddle;
      m_mode     = settings.rsiMode;
      m_exitMode = settings.rsiExitMode;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.rsiPeriod ||
                      m_timeframe != settings.rsiTimeframe ||
                      m_price != settings.rsiPrice);
      m_period     = settings.rsiPeriod;
      m_timeframe  = settings.rsiTimeframe;
      m_price      = settings.rsiPrice;

      if(!m_initialized)
         return true;

      if(!m_enabled)
        {
         ReleaseHandle();
         return true;
        }

      if(scope == RELOAD_WARM || scope == RELOAD_COLD || changed || m_handle == INVALID_HANDLE)
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
      if(m_exitMode != EXIT_OPPOSITE_SIGNAL && m_exitMode != EXIT_REVERSE_SIGNAL)
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE signal = EvaluateSignal();
      if(currentPosition == POSITION_TYPE_BUY && signal == SIGNAL_SELL)
         return SIGNAL_SELL;
      if(currentPosition == POSITION_TYPE_SELL && signal == SIGNAL_BUY)
         return SIGNAL_BUY;

      return SIGNAL_NONE;
     }

   virtual ENUM_EXIT_MODE ExitMode(void) const override
     {
      return m_exitMode;
     }
  };

#endif
