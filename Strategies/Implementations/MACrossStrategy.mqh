#ifndef __FUSION_MACROSS_STRATEGY_MQH__
#define __FUSION_MACROSS_STRATEGY_MQH__

#include "../Base/StrategyBase.mqh"

class CMACrossStrategy : public CStrategyBase
  {
private:
   int                 m_fastHandle;
   int                 m_slowHandle;
   int                 m_fastPeriod;
   int                 m_slowPeriod;
   ENUM_TIMEFRAMES     m_fastTimeframe;
   ENUM_TIMEFRAMES     m_slowTimeframe;
   ENUM_MA_METHOD      m_fastMethod;
   ENUM_MA_METHOD      m_slowMethod;
   ENUM_APPLIED_PRICE  m_fastPrice;
   ENUM_APPLIED_PRICE  m_slowPrice;
   ENUM_ENTRY_MODE     m_entryMode;
   ENUM_EXIT_MODE      m_exitMode;
   datetime            m_lastCrossTime;
   ENUM_SIGNAL_TYPE    m_lastCrossSignal;
   int                 m_candlesAfterCross;
   datetime            m_lastCheckBarTime;

   void              ReleaseHandles(void)
     {
      ReleaseIndicatorHandle(m_fastHandle);
      ReleaseIndicatorHandle(m_slowHandle);
     }

   void              ResetEntryTracking(void)
     {
      m_lastCrossTime     = 0;
      m_lastCrossSignal   = SIGNAL_NONE;
      m_candlesAfterCross = 0;
      m_lastCheckBarTime  = 0;
     }

   bool              CreateHandles(void)
     {
      ReleaseHandles();

      if((int)m_fastTimeframe <= 0 || (int)m_slowTimeframe <= 0)
        {
         if(m_logger != NULL)
            m_logger.Error("STRAT_MA", "Invalid configured timeframes");
         return false;
        }

      m_fastHandle = iMA(m_symbol, m_fastTimeframe, m_fastPeriod, 0, m_fastMethod, m_fastPrice);
      m_slowHandle = iMA(m_symbol, m_slowTimeframe, m_slowPeriod, 0, m_slowMethod, m_slowPrice);

      if(m_fastHandle == INVALID_HANDLE || m_slowHandle == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Error("STRAT_MA", "Failed to create MA handles");
         return false;
        }

      ResetEntryTracking();
      return true;
     }

   bool              LoadBuffers(double &fastBuffer[],double &slowBuffer[])
     {
      ArrayResize(fastBuffer, 3);
      ArrayResize(slowBuffer, 3);
      ArraySetAsSeries(fastBuffer, true);
      ArraySetAsSeries(slowBuffer, true);

      if(CopyBuffer(m_fastHandle, 0, 0, 3, fastBuffer) < 3)
         return false;
      if(CopyBuffer(m_slowHandle, 0, 0, 3, slowBuffer) < 3)
         return false;
      return true;
     }

   void              LogCrossSnapshot(const string scope,const ENUM_SIGNAL_TYPE signal,const double &fastBuffer[],const double &slowBuffer[]) const
     {
      if(m_logger == NULL)
         return;

      string message = StringFormat("%s fast[2]=%.5f fast[1]=%.5f slow[2]=%.5f slow[1]=%.5f => %s",
                                    scope,
                                    fastBuffer[2],
                                    fastBuffer[1],
                                    slowBuffer[2],
                                    slowBuffer[1],
                                    SignalToString(signal));
      m_logger.Info("STRAT_MA", message);
     }

   ENUM_SIGNAL_TYPE  DetectCross(const double &fastBuffer[],const double &slowBuffer[]) const
     {
      double previousDiff = fastBuffer[2] - slowBuffer[2];
      double currentDiff  = fastBuffer[1] - slowBuffer[1];

      if(previousDiff < 0.0 && currentDiff > 0.0)
         return SIGNAL_BUY;

      if(previousDiff > 0.0 && currentDiff < 0.0)
         return SIGNAL_SELL;

      return SIGNAL_NONE;
     }

public:
                     CMACrossStrategy(void) : CStrategyBase("ma_cross", "MA Cross", "MA", 10)
     {
      m_fastHandle        = INVALID_HANDLE;
      m_slowHandle        = INVALID_HANDLE;
      m_fastPeriod        = 9;
      m_slowPeriod        = 21;
      m_fastTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_slowTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_fastMethod        = MODE_EMA;
      m_slowMethod        = MODE_EMA;
      m_fastPrice         = PRICE_CLOSE;
      m_slowPrice         = PRICE_CLOSE;
      m_entryMode         = ENTRY_NEXT_CANDLE;
      m_exitMode          = EXIT_OPPOSITE_SIGNAL;
      ResetEntryTracking();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandles();
      ResetEntryTracking();
      CStrategyBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      bool coldChanged = (m_fastPeriod != settings.maFastPeriod ||
                          m_slowPeriod != settings.maSlowPeriod ||
                          m_fastTimeframe != settings.maFastTimeframe ||
                          m_slowTimeframe != settings.maSlowTimeframe ||
                          m_fastMethod != settings.maFastMethod ||
                          m_slowMethod != settings.maSlowMethod ||
                          m_fastPrice != settings.maFastPrice ||
                          m_slowPrice != settings.maSlowPrice);
      bool entryChanged = (m_entryMode != settings.maEntryMode);

      m_enabled        = settings.useMACross;
      m_priority       = settings.maCrossPriority;
      m_fastPeriod     = settings.maFastPeriod;
      m_slowPeriod     = settings.maSlowPeriod;
      m_fastTimeframe  = settings.maFastTimeframe;
      m_slowTimeframe  = settings.maSlowTimeframe;
      m_timeframe      = m_fastTimeframe;
      m_fastMethod     = settings.maFastMethod;
      m_slowMethod     = settings.maSlowMethod;
      m_fastPrice      = settings.maFastPrice;
      m_slowPrice      = settings.maSlowPrice;
      m_entryMode      = settings.maEntryMode;
      m_exitMode       = settings.maExitMode;

      if(entryChanged)
         ResetEntryTracking();

      if(!m_initialized)
         return true;

      if(!m_enabled)
        {
         ReleaseHandles();
         ResetEntryTracking();
         return true;
        }

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || coldChanged || m_fastHandle == INVALID_HANDLE || m_slowHandle == INVALID_HANDLE)
         return CreateHandles();

      return true;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CStrategyBase::Initialize(logger, symbol))
         return false;
      if(!m_enabled)
         return true;
      return CreateHandles();
     }

   virtual ENUM_SIGNAL_TYPE GetEntrySignal(void) override
     {
      if(!m_enabled || !m_initialized)
         return SIGNAL_NONE;

      double fastBuffer[];
      double slowBuffer[];
      if(!LoadBuffers(fastBuffer, slowBuffer))
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE crossSignal = DetectCross(fastBuffer, slowBuffer);
      datetime crossBarTime = iTime(m_symbol, m_fastTimeframe, 1);

      if(crossSignal != SIGNAL_NONE && crossBarTime != m_lastCrossTime)
        {
         m_lastCrossTime = crossBarTime;
         m_lastCrossSignal = crossSignal;
         m_candlesAfterCross = 0;
         m_lastCheckBarTime = iTime(m_symbol, m_fastTimeframe, 0);

         if(m_entryMode == ENTRY_NEXT_CANDLE)
           {
            LogCrossSnapshot("NEXT_CANDLE", crossSignal, fastBuffer, slowBuffer);
            m_lastCrossSignal = SIGNAL_NONE;
            return crossSignal;
           }

         LogCrossSnapshot("E2C_WAIT", crossSignal, fastBuffer, slowBuffer);
         return SIGNAL_NONE;
        }

      if(m_entryMode == ENTRY_2ND_CANDLE && m_lastCrossSignal != SIGNAL_NONE)
        {
         datetime currentBarTime = iTime(m_symbol, m_fastTimeframe, 0);
         if(currentBarTime != m_lastCheckBarTime)
           {
            m_lastCheckBarTime = currentBarTime;
            m_candlesAfterCross++;
           }

         if(m_candlesAfterCross >= 1)
           {
            ENUM_SIGNAL_TYPE signal = m_lastCrossSignal;
            LogCrossSnapshot("E2C_FIRE", signal, fastBuffer, slowBuffer);
            ResetEntryTracking();
            return signal;
           }
        }

      return SIGNAL_NONE;
     }

   virtual ENUM_SIGNAL_TYPE GetExitSignal(const ENUM_POSITION_TYPE currentPosition) override
     {
      if(m_exitMode != EXIT_OPPOSITE_SIGNAL || !m_enabled || !m_initialized)
         return SIGNAL_NONE;

      double fastBuffer[];
      double slowBuffer[];
      if(!LoadBuffers(fastBuffer, slowBuffer))
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE crossSignal = DetectCross(fastBuffer, slowBuffer);
      if(currentPosition == POSITION_TYPE_BUY && crossSignal == SIGNAL_SELL)
         return SIGNAL_SELL;
      if(currentPosition == POSITION_TYPE_SELL && crossSignal == SIGNAL_BUY)
         return SIGNAL_BUY;

      return SIGNAL_NONE;
     }
  };

#endif
