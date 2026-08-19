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
   //--- Deduplicacao do log de recusa: uma linha por candle de sinal, por
   //--- estrategia. Os chamadores ja consomem o sinal, entao na pratica nao
   //--- repetiria por tick; isto garante o limite mesmo se algum caminho futuro
   //--- reavaliar o mesmo candle.
   bool             m_freshCandleBlockLogged;
   datetime         m_freshCandleLoggedBar;

   string            FormatBarTime(const datetime value) const
     {
      if(value <= 0)
         return "horario indisponivel";
      return TimeToString(value, TIME_DATE | TIME_SECONDS);
     }

   //--- Instrumentacao permanente, so com "logs detalhados de debug" ligados.
   //--- Sem ela, uma recusa da quarentena e uma AUSENCIA de ordem: o operador
   //--- teria de deduzir pelo grafico que algo foi barrado, e um aceite nao se
   //--- sustenta em deducao. Diz qual estrategia, o candle do sinal e a barreira.
   void              LogFreshCandleBlock(const datetime signalBarTime)
     {
      if(m_logger == NULL)
         return;
      if(m_freshCandleBlockLogged && signalBarTime == m_freshCandleLoggedBar)
         return;

      m_freshCandleBlockLogged = true;
      m_freshCandleLoggedBar   = signalBarTime;

      string barrier = (m_freshCandleBarrier > 0)
                       ? FormatBarTime(m_freshCandleBarrier)
                       : "ainda desconhecida (serie indisponivel)";

      m_logger.Debug("SIGNAL",
                     StringFormat("Sinal bloqueado pela quarentena - %s. Candle do sinal %s, barreira %s.",
                                  m_name,
                                  FormatBarTime(signalBarTime),
                                  barrier));
     }

   //--- Devolve true quando ha horario utilizavel.
   //---
   //--- ⚠️ SO PODE SER CHAMADA A PARTIR DE UMA AVALIACAO DE ENTRADA, isto e,
   //--- debaixo de um tick. Chamar no momento da suspensao era um defeito real,
   //--- pego no primeiro teste: quando a transicao e percebida pelo TIMER, ainda
   //--- nao chegou tick nenhum no candle corrente, a serie nao criou esse candle e
   //--- iTime(0) devolve o ANTERIOR. O valor entrava congelado (a funcao retorna
   //--- cedo com barreira ja preenchida) e um candle iniciado ANTES da liberacao
   //--- passava a ser elegivel. Observado em 2026-08-19: permissao restaurada as
   //--- 23:27:18 de servidor, barreira captada como 23:26:00.
   //---
   //--- Captura tardia continua proposital: se a serie so responder alguns candles
   //--- depois, a referencia passa a ser o candle corrente daquele momento e ainda
   //--- se exige um posterior. Mais conservador que o necessario, nunca mais
   //--- permissivo.
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
      m_freshCandleQuarantine  = false;
      m_freshCandleBarrier     = 0;
      m_freshCandleBlockLogged = false;
      m_freshCandleLoggedBar   = 0;
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
      m_freshCandleQuarantine  = false;
      m_freshCandleBarrier     = 0;
      m_freshCandleBlockLogged = false;
      m_freshCandleLoggedBar   = 0;
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
   //---
   //--- ⚠️ AQUI NAO SE CAPTURA NADA. A transicao pode ser percebida pelo timer, e
   //--- nesse instante a serie ainda esta no candle anterior - capturar aqui
   //--- congelava uma barreira velha demais e deixava passar um candle iniciado
   //--- antes da liberacao. A barreira nasce desconhecida, e desconhecida bloqueia.
   virtual void      SuspendEntriesUntilFreshCandle(void)
     {
      m_freshCandleQuarantine  = true;
      m_freshCandleBarrier     = 0;
      m_freshCandleBlockLogged = false;
      m_freshCandleLoggedBar   = 0;
     }

   //--- **Unico** ponto de captura da barreira, e por isso ele importa: e chamado
   //--- por SignalManager::GetEntryDecision(), ou seja, debaixo de um tick, com a
   //--- serie ja atualizada por esse tick. O candle corrente lido aqui e o de
   //--- verdade, nao o que sobrou do ultimo tick antes da queda.
   //---
   //--- Roda a cada avaliacao normal de entrada, com ou sem sinal candidato: e o
   //--- que impede que a quarentena sem horario atravesse horas e acabe capturando
   //--- a referencia no primeiro sinal legitimo - que seria entao descartado por
   //--- servir de referencia. Aqui so se capta; quem bloqueia e
   //--- FreshCandleBarrierBlocks.
   void              RefreshFreshCandleBarrier(void)
     {
      if(!m_freshCandleQuarantine)
         return;
      CaptureFreshCandleBarrier();
     }

   //--- signalBarTime e a abertura do candle que formou o sinal (sempre o [1]).
   //--- Enquanto a quarentena estiver ativa sem horario confiavel, TUDO e
   //--- bloqueado - falha fechado de verdade. A recuperacao e automatica e sem
   //--- prazo: no primeiro tick que alcancar a avaliacao normal de entrada com a
   //--- serie respondendo, o candle corrente daquele momento vira a referencia e a
   //--- exigencia volta a ser um candle posterior a ele. Essa referencia pode cair
   //--- no mesmo candle da restauracao ou num posterior - o que ela nunca pode ser
   //--- e ANTERIOR, que era o defeito.
   //---
   //--- Aqui NAO se captura: quem chega neste ponto veio de GetEntryDecision(),
   //--- que ja passou por RefreshFreshCandleBarrier() no mesmo tick. Barreira
   //--- desconhecida neste ponto significa serie que nao respondeu - bloqueia.
   bool              FreshCandleBarrierBlocks(const datetime signalBarTime)
     {
      if(!m_freshCandleQuarantine)
         return false;

      if(m_freshCandleBarrier <= 0 || signalBarTime <= 0)
        {
         LogFreshCandleBlock(signalBarTime);
         return true;
        }

      if(signalBarTime > m_freshCandleBarrier)
        {
         m_freshCandleQuarantine  = false;
         m_freshCandleBarrier     = 0;
         m_freshCandleBlockLogged = false;
         m_freshCandleLoggedBar   = 0;
         return false;
        }

      LogFreshCandleBlock(signalBarTime);
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
