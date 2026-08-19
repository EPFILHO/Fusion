#ifndef __FUSION_STRATEGY_BASE_MQH__
#define __FUSION_STRATEGY_BASE_MQH__

#include "../../Core/Types.mqh"
#include "../../Core/Logger.mqh"

class CStrategyBase
  {
protected:
   CLogger         *m_logger;
   string           m_id;
   string           m_name;
   string           m_shortName;
   string           m_symbol;
   ENUM_TIMEFRAMES  m_timeframe;
   int              m_priority;
   bool             m_enabled;
   bool             m_initialized;
   //--- Hora de abertura do candle que JA estava em formacao quando as entradas
   //--- foram suspensas. Um sinal so e elegivel se o candle que o formou comecou
   //--- depois desse; zero significa barreira desarmada.
   datetime         m_freshCandleBarrier;

   void              ReleaseIndicatorHandle(int &handle)
     {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
      handle = INVALID_HANDLE;
     }

public:
                     CStrategyBase(const string id,const string name,const string shortName,const int priority)
     {
      m_logger      = NULL;
      m_id          = id;
      m_name        = name;
      m_shortName   = shortName;
      m_symbol      = "";
      m_timeframe   = FUSION_DEFAULT_TIMEFRAME;
      m_priority    = priority;
      m_enabled     = true;
      m_initialized = false;
      m_freshCandleBarrier = 0;
     }

   virtual          ~CStrategyBase(void) {}

   virtual bool      Initialize(CLogger *logger,const string symbol)
     {
      m_logger      = logger;
      m_symbol      = symbol;
      m_initialized = true;
      return true;
     }

   virtual void      Shutdown(void)
     {
      m_initialized = false;
      m_freshCandleBarrier = 0;
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) = 0;
   virtual void      PrimeEntryState(void) {}

   //--- Consumir o estado vigente nao basta quando a permissao de trading volta no
   //--- meio de um candle: esse candle vira [1] no fechamento e comecou a se formar
   //--- durante o bloqueio, sem o EA acompanhando. A barreira exige que o primeiro
   //--- sinal elegivel venha de um candle iniciado DEPOIS da suspensao. Cada
   //--- estrategia arma no proprio ReferenceTimeframe(), entao timeframes
   //--- diferentes esperam candles diferentes. So entrada: nenhum caminho de saida
   //--- le esta barreira.
   virtual void      SuspendEntriesUntilFreshCandle(void)
     {
      if(!m_initialized || m_symbol == "")
         return;

      datetime openBar = iTime(m_symbol, ReferenceTimeframe(), 0);
      if(openBar > 0)
         m_freshCandleBarrier = openBar;
     }

   //--- signalBarTime e a abertura do candle que formou o sinal (sempre o [1]).
   //--- Sem hora confiavel a barreira falha fechado, como o resto do EA.
   bool              FreshCandleBarrierBlocks(const datetime signalBarTime)
     {
      if(m_freshCandleBarrier <= 0)
         return false;
      if(signalBarTime <= 0)
         return true;
      if(signalBarTime > m_freshCandleBarrier)
        {
         m_freshCandleBarrier = 0;
         return false;
        }
      return true;
     }
   virtual ENUM_SIGNAL_TYPE GetEntrySignal(void) = 0;
   virtual ENUM_SIGNAL_TYPE GetExitSignal(const ENUM_POSITION_TYPE currentPosition) = 0;
   virtual ENUM_EXIT_MODE ExitMode(void) const { return EXIT_TP_SL; }

   string            Id(void) const          { return m_id; }
   string            Name(void) const        { return m_name; }
   string            ShortName(void) const   { return m_shortName; }
   int               Priority(void) const    { return m_priority; }
   void              SetPriority(const int value) { m_priority = value; }
   bool              Enabled(void) const     { return m_enabled; }
   void              SetEnabled(const bool value) { m_enabled = value; }
   bool              IsInitialized(void) const { return m_initialized; }
   virtual ENUM_TIMEFRAMES ReferenceTimeframe(void) const { return m_timeframe; }
  };

#endif
