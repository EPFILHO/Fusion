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
   //--- Quarentena de entrada apos a permissao de trading voltar. Ativa e sempre
   //--- a autoridade: enquanto for true nenhuma entrada passa sem prova.
   bool             m_freshCandleQuarantine;
   //--- Hora de abertura do candle que JA estava em formacao quando as entradas
   //--- foram suspensas. Um sinal so e elegivel se o candle que o formou comecou
   //--- depois desse. Zero aqui significa "ainda nao sei", NAO "pode entrar" -
   //--- quem responde isso e m_freshCandleQuarantine.
   datetime         m_freshCandleBarrier;

   //--- Devolve true quando ha horario utilizavel. Captura tardia e proposital:
   //--- se a serie so responder alguns candles depois, a referencia passa a ser o
   //--- candle corrente daquele momento e ainda se exige um posterior. Fica mais
   //--- conservador que o necessario, nunca mais permissivo.
   bool              CaptureFreshCandleBarrier(void)
     {
      if(m_freshCandleBarrier > 0)
         return true;
      if(!m_initialized || m_symbol == "")
         return false;

      datetime openBar = iTime(m_symbol, ReferenceTimeframe(), 0);
      if(openBar <= 0)
         return false;

      m_freshCandleBarrier = openBar;
      return true;
     }

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
      m_freshCandleQuarantine = false;
      m_freshCandleBarrier    = 0;
     }

   virtual          ~CStrategyBase(void) {}

   virtual bool      Initialize(CLogger *logger,const string symbol)
     {
      m_logger      = logger;
      m_symbol      = symbol;
      m_initialized = true;
      return true;
     }

   //--- Shutdown so acontece no OnDeinit, com o objeto indo embora em seguida; o
   //--- construtor devolve o mesmo estado. Nao e caminho de reabilitacao.
   virtual void      Shutdown(void)
     {
      m_initialized = false;
      m_freshCandleQuarantine = false;
      m_freshCandleBarrier    = 0;
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
   //---
   //--- "Quarentena ativa" e "horario da quarentena conhecido" sao estados
   //--- SEPARADOS de proposito. Amarrar um ao outro fazia a barreira falhar
   //--- ABERTA justamente no cenario que a motivou: serie/historico indisponivel
   //--- e comum logo depois de uma reconexao, iTime() devolve zero, e uma
   //--- barreira que so existisse enquanto houvesse horario simplesmente nao
   //--- existiria ali. A quarentena arma incondicionalmente; o horario e captado
   //--- quando a serie permitir.
   virtual void      SuspendEntriesUntilFreshCandle(void)
     {
      m_freshCandleQuarantine = true;
      m_freshCandleBarrier    = 0;
      CaptureFreshCandleBarrier();
     }

   //--- signalBarTime e a abertura do candle que formou o sinal (sempre o [1]).
   //--- Enquanto a quarentena estiver ativa sem horario confiavel, TUDO e
   //--- bloqueado - falha fechado de verdade. A recuperacao e automatica e sem
   //--- prazo: no primeiro instante em que a serie responde, o candle corrente
   //--- vira a referencia e a exigencia volta a ser um candle posterior a ele.
   bool              FreshCandleBarrierBlocks(const datetime signalBarTime)
     {
      if(!m_freshCandleQuarantine)
         return false;
      if(!CaptureFreshCandleBarrier())
         return true;
      if(signalBarTime <= 0)
         return true;
      if(signalBarTime > m_freshCandleBarrier)
        {
         m_freshCandleQuarantine = false;
         m_freshCandleBarrier    = 0;
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
