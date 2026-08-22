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
   //--- Barreira do INTERVALO CEGO da troca do timeframe visual.
   //---
   //--- ⚠ SEPARADA da quarentena do item 12, de proposito. As duas parecem
   //--- iguais e decidem coisas diferentes:
   //---
   //---   quarentena (item 12) — a permissao de trading voltou. Pode invalidar
   //---     ate um sinal que ja estava pendente, porque o EA esteve cego para o
   //---     mercado inteiro.
   //---   barreira visual — o EA se reinicializou por troca de timeframe. So
   //---     recusa sinais NOVOS, nao observados antes do desligamento. Um
   //---     E2C_WAIT importado atravessa esta, porque ele JA tinha sido visto.
   //---
   //--- Um booleano so para as duas deixaria o estado importado burlar o item
   //--- 12 ou a barreira visual apagar a pendencia preservada.
   bool             m_visualQuarantine;
   datetime         m_visualBarrier;
   bool             m_visualBlockLogged;
   datetime         m_visualLoggedBar;

   //--- Mesma licao do item 12: captura TARDIA, debaixo do primeiro tick com a
   //--- serie respondendo. Capturar na reinicializacao leria o mundo do ultimo
   //--- tick antes do desligamento.
   bool              CaptureVisualBarrier(void)
     {
      if(m_visualBarrier > 0)
         return true;
      if(!m_initialized || m_symbol == "")
         return false;

      datetime openBar = iTime(m_symbol, ReferenceTimeframe(), 0);
      if(openBar <= 0)
         return false;

      m_visualBarrier = openBar;
      return true;
     }

   void              LogVisualBlock(const datetime signalBarTime)
     {
      if(m_logger == NULL)
         return;
      if(m_visualBlockLogged && signalBarTime == m_visualLoggedBar)
         return;

      m_visualBlockLogged = true;
      m_visualLoggedBar   = signalBarTime;

      string barrier = (m_visualBarrier > 0)
                       ? FormatBarTime(m_visualBarrier)
                       : "ainda desconhecida (serie indisponivel)";

      m_logger.Debug("SIGNAL",
                     StringFormat("Sinal do intervalo cego recusado - %s. Candle do sinal %s, barreira visual %s.",
                                  m_name,
                                  FormatBarTime(signalBarTime),
                                  barrier));
     }

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
      m_visualQuarantine       = false;
      m_visualBarrier          = 0;
      m_visualBlockLogged      = false;
      m_visualLoggedBar        = 0;
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
      m_visualQuarantine       = false;
      m_visualBarrier          = 0;
      m_visualBlockLogged      = false;
      m_visualLoggedBar        = 0;
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) = 0;
   virtual void      PrimeEntryState(void) {}

   //--- Contrato do handoff de estado logico. Virtual para o SignalManager
   //--- percorrer as estrategias sem conhecer o tipo concreto de cada uma —
   //--- casts por id seriam uma segunda tabela de "quem e quem".
   //--- ⚠ TODOS os defaults falham FECHADO. Uma estrategia futura que esquecesse
   //--- um override seria anunciada como restaurada sem ter importado nada — e o
   //--- log mentiria sobre preservacao de sinal. Sem suporte explicito, ela e
   //--- incompativel, nao esta pronta e a importacao recusa com motivo.
   virtual void      ExportEntryState(SEntryStateSnapshot &snapshot) const {}

   virtual bool      ImportEntryState(const SEntryStateSnapshot &snapshot,string &reason)
     {
      reason = "estrategia sem suporte a handoff de estado de entrada";
      return false;
     }

   virtual bool      EntryStateCompatible(const SEASettings &origin,const SEASettings &current) const
     { return false; }

   virtual bool      ReadyForEntryStateImport(void) const
     { return false; }

   //--- Quarentena do item 12, exposta para atravessar a troca de timeframe.
   //---
   //--- ⚠ Ela viaja com o estado de propriedade: um E2C_WAIT importado NAO pode
   //--- servir de atalho para burlar a exigencia de sinal fresco depois de uma
   //--- volta de permissao. Se a quarentena estava armada no desligamento, ela
   //--- volta armada.
   bool              ExportQuarantine(datetime &barrier) const
     {
      barrier = m_freshCandleBarrier;
      return m_freshCandleQuarantine;
     }

   void              ImportQuarantine(const bool active,const datetime barrier)
     {
      //--- ⚠ NAO toca a barreira visual. As duas sao independentes: importar a
      //--- quarentena do item 12 nao pode apagar a protecao do intervalo cego.
      m_freshCandleQuarantine  = active;
      m_freshCandleBarrier     = (active && barrier > 0) ? barrier : 0;
      m_freshCandleBlockLogged = false;
      m_freshCandleLoggedBar   = 0;
     }

   //--- Arma a barreira do intervalo cego. Nasce ATIVA e sem horario; quem
   //--- captura e RefreshVisualBarrier, no primeiro tick com serie.
   //---
   //--- Trocas visuais sucessivas apenas rearmam: o estado pendente importado
   //--- nao e tocado aqui.
   void              SuspendEntriesUntilFreshCandleVisual(void)
     {
      m_visualQuarantine  = true;
      m_visualBarrier     = 0;
      m_visualBlockLogged = false;
      m_visualLoggedBar   = 0;
     }

   void              RefreshVisualBarrier(void)
     {
      if(!m_visualQuarantine)
         return;
      CaptureVisualBarrier();
     }

   //--- Recusa sinal NOVO nascido no intervalo cego. Mesmo criterio do item 12:
   //--- so vale candle iniciado DEPOIS da barreira, e sem horario bloqueia.
   bool              VisualBarrierBlocks(const datetime signalBarTime)
     {
      if(!m_visualQuarantine)
         return false;

      if(m_visualBarrier <= 0 || signalBarTime <= 0)
        {
         LogVisualBlock(signalBarTime);
         return true;
        }

      if(signalBarTime > m_visualBarrier)
        {
         m_visualQuarantine  = false;
         m_visualBarrier     = 0;
         m_visualBlockLogged = false;
         m_visualLoggedBar   = 0;
         return false;
        }

      LogVisualBlock(signalBarTime);
      return true;
     }

   //--- Porta unica dos sinais NOVOS: as duas barreiras, nesta ordem. A do item
   //--- 12 vem primeiro porque e a mais forte — ela pode recusar o que a visual
   //--- deixaria passar.
   bool              EntryBarriersBlock(const datetime signalBarTime)
     {
      if(FreshCandleBarrierBlocks(signalBarTime))
         return true;
      return VisualBarrierBlocks(signalBarTime);
     }

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
      //--- ⚠ NAO toca a barreira visual: dominios separados.
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
         //--- Desarma SO a quarentena do item 12. A barreira visual, se armada,
         //--- continua valendo e e avaliada em VisualBarrierBlocks.
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
