#ifndef __FUSION_MACROSS_STRATEGY_MQH__
#define __FUSION_MACROSS_STRATEGY_MQH__

#include "../Base/StrategyBase.mqh"

class CMACrossStrategy : public CStrategyBase
  {
private:
   int               m_fastHandle;
   int               m_slowHandle;
   int               m_fastPeriod;
   int               m_slowPeriod;
   ENUM_MA_METHOD    m_method;
   ENUM_APPLIED_PRICE m_price;
   ENUM_EXIT_MODE    m_exitMode;

   void              ReleaseHandles(void)
     {
      if(m_fastHandle != INVALID_HANDLE)
         IndicatorRelease(m_fastHandle);
      if(m_slowHandle != INVALID_HANDLE)
         IndicatorRelease(m_slowHandle);
      m_fastHandle = INVALID_HANDLE;
      m_slowHandle = INVALID_HANDLE;
     }

   bool              CreateHandles(void)
     {
      ReleaseHandles();

      m_fastHandle = iMA(m_symbol, m_timeframe, m_fastPeriod, 0, m_method, m_price);
      m_slowHandle = iMA(m_symbol, m_timeframe, m_slowPeriod, 0, m_method, m_price);

      if(m_fastHandle == INVALID_HANDLE || m_slowHandle == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Error("STRAT_MA", "Failed to create MA handles");
         return false;
        }

      return true;
     }

   bool              LoadBuffers(double &fastBuffer[],double &slowBuffer[])
     {
      ArrayResize(fastBuffer, 3);
      ArrayResize(slowBuffer, 3);

      if(CopyBuffer(m_fastHandle, 0, 0, 3, fastBuffer) < 3)
         return false;
      if(CopyBuffer(m_slowHandle, 0, 0, 3, slowBuffer) < 3)
         return false;
      return true;
     }

public:
                     CMACrossStrategy(void) : CStrategyBase("ma_cross", "MA Cross", "MA", 10)
     {
      m_fastHandle = INVALID_HANDLE;
      m_slowHandle = INVALID_HANDLE;
      m_fastPeriod = 9;
      m_slowPeriod = 21;
      m_method     = MODE_EMA;
      m_price      = PRICE_CLOSE;
      m_exitMode   = EXIT_OPPOSITE_SIGNAL;
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandles();
      CStrategyBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled  = settings.useMACross;
      m_magicNumber = settings.maCrossMagicNumber;
      m_priority = settings.maCrossPriority;
      m_exitMode = settings.maExitMode;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_fastPeriod != settings.maFastPeriod ||
                      m_slowPeriod != settings.maSlowPeriod ||
                      m_method     != settings.maMethod ||
                      m_price      != settings.maPrice);

      m_fastPeriod = settings.maFastPeriod;
      m_slowPeriod = settings.maSlowPeriod;
      m_method     = settings.maMethod;
      m_price      = settings.maPrice;

      if(!m_initialized)
         return true;

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed)
         return CreateHandles();

      return true;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol,const ENUM_TIMEFRAMES timeframe) override
     {
      if(!CStrategyBase::Initialize(logger, symbol, timeframe))
         return false;
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

      if(fastBuffer[2] <= slowBuffer[2] && fastBuffer[1] > slowBuffer[1])
         return SIGNAL_BUY;

      if(fastBuffer[2] >= slowBuffer[2] && fastBuffer[1] < slowBuffer[1])
         return SIGNAL_SELL;

      return SIGNAL_NONE;
     }

   virtual ENUM_SIGNAL_TYPE GetExitSignal(const ENUM_POSITION_TYPE currentPosition) override
     {
      if(m_exitMode != EXIT_OPPOSITE_SIGNAL)
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE signal = GetEntrySignal();
      if(currentPosition == POSITION_TYPE_BUY && signal == SIGNAL_SELL)
         return SIGNAL_SELL;
      if(currentPosition == POSITION_TYPE_SELL && signal == SIGNAL_BUY)
         return SIGNAL_BUY;

      return SIGNAL_NONE;
     }
  };

#endif
