#ifndef __FUSION_MACROSS_STRATEGY_MQH__
#define __FUSION_MACROSS_STRATEGY_MQH__

#include "../Base/StrategyBase.mqh"

//+------------------------------------------------------------------+
//| Configuracao que os handles VIVOS realmente representam.          |
//|                                                                    |
//| ⚠ Existe porque "configuracao solicitada" e "configuracao ativa"  |
//| deixaram de ser a mesma coisa. Quando um reload traz configuracao |
//| invalida, os campos m_fast*/m_slow* passam a descrever o que o    |
//| usuario pediu, enquanto os handles seguem sendo os da ultima      |
//| configuracao valida — a mesma sob a qual uma posicao aberta foi   |
//| montada, e que a saida por cruzamento precisa continuar usando.   |
//|                                                                    |
//| Ler buffer de um handle M1/M5 interpretando-o como H4/M1 calcula  |
//| shift errado, inventa cruzamento e pode FECHAR OU REVERTER uma    |
//| posicao sem motivo. Por isso todo o caminho de leitura de buffer  |
//| — LoadBuffers, LastClosedSlowShiftAt, DetectCross — le daqui, e   |
//| nao dos campos solicitados.                                       |
//|                                                                    |
//| Com configuracao valida os dois conjuntos sao identicos: este     |
//| struct e atualizado no mesmo instante em que os handles nascem.   |
//+------------------------------------------------------------------+
struct SMACrossActiveConfig
  {
   bool               ready;              // ha par de handles valido
   int                fastPeriod;
   int                slowPeriod;
   int                minDistancePoints;
   ENUM_TIMEFRAMES    fastTimeframe;
   ENUM_TIMEFRAMES    slowTimeframe;
   ENUM_MA_METHOD     fastMethod;
   ENUM_MA_METHOD     slowMethod;
   ENUM_APPLIED_PRICE fastPrice;
   ENUM_APPLIED_PRICE slowPrice;
  };

class CMACrossStrategy : public CStrategyBase
  {
private:
   int                 m_fastHandle;
   int                 m_slowHandle;
   int                 m_fastPeriod;
   int                 m_slowPeriod;
   int                 m_minDistancePoints;
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
   //--- Espelho do predicado central (FusionMACrossConfigState). Guardado no
   //--- Reload porque e la que a configuracao chega; GetEntrySignal e
   //--- Initialize apenas o consultam. m_configLoggedState evita repetir a
   //--- mesma queixa a cada reload que nao mudou nada — e nunca ha log por
   //--- tick, porque nada disso e reavaliado no caminho do tick.
   ENUM_MA_CROSS_CONFIG m_configState;
   ENUM_MA_CROSS_CONFIG m_configLoggedState;
   //--- O que os handles vivos representam. Ver o comentario do struct.
   SMACrossActiveConfig m_active;

   void              ClearActiveConfig(void)
     {
      m_active.ready             = false;
      m_active.fastPeriod        = 0;
      m_active.slowPeriod        = 0;
      m_active.minDistancePoints = 0;
      m_active.fastTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_active.slowTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_active.fastMethod        = MODE_EMA;
      m_active.slowMethod        = MODE_EMA;
      m_active.fastPrice         = PRICE_CLOSE;
      m_active.slowPrice         = PRICE_CLOSE;
     }

   //--- O par ativo descreve exatamente o que o usuario pediu?
   //---
   //--- ⚠ Pode nao descrever mesmo com configuracao SEMANTICAMENTE valida: basta
   //--- o iMA() falhar ao criar o par novo. Ai a troca atomica preserva o par
   //--- antigo (correto, a saida depende dele), mas os campos solicitados ja
   //--- foram atualizados e o ApplySettings ja publicou a configuracao nova, sem
   //--- rollback. Sem esta conferencia, as entradas voltariam a ser avaliadas com
   //--- BUFFER velho e RELOGIO novo — o mesmo defeito que a separacao veio matar,
   //--- so que no caminho de entrada.
   bool              ActiveMatchesRequested(void) const
     {
      return (m_active.ready &&
              m_active.fastPeriod        == m_fastPeriod &&
              m_active.slowPeriod        == m_slowPeriod &&
              m_active.minDistancePoints == m_minDistancePoints &&
              m_active.fastTimeframe     == m_fastTimeframe &&
              m_active.slowTimeframe     == m_slowTimeframe &&
              m_active.fastMethod        == m_fastMethod &&
              m_active.slowMethod        == m_slowMethod &&
              m_active.fastPrice         == m_fastPrice &&
              m_active.slowPrice         == m_slowPrice);
     }

   //--- Unica porta das ENTRADAS. Saida nao passa por aqui: ela pode e deve
   //--- continuar usando o par ativo antigo enquanto ele existir.
   bool              EntriesOperational(void) const
     {
      return (m_enabled && m_initialized &&
              m_configState == MA_CROSS_CONFIG_OK &&
              ActiveMatchesRequested());
     }

   string            ConfigStateText(const ENUM_MA_CROSS_CONFIG state) const
     {
      switch(state)
        {
         case MA_CROSS_CONFIG_IDENTICAL:
            return "MA Rapida e MA Lenta sao a mesma curva (periodo, timeframe, metodo e preco iguais).";
         case MA_CROSS_CONFIG_FAST_LONGER:
            return "horizonte da MA Rapida e maior que o da MA Lenta (periodo x timeframe).";
         case MA_CROSS_CONFIG_HORIZON_INVALID:
            return "periodo ou timeframe nao produzem horizonte valido.";
         case MA_CROSS_CONFIG_PERIOD_RANGE:
            return "periodo fora da faixa de 1 a 1000.";
        }
      return "";
     }

   //--- Uma linha por transicao de estado invalido, no Initialize ou no Reload.
   //--- Nao derruba o EA: a MA Cross para de ENTRAR, e todo o resto - painel,
   //--- gerenciamento da posicao aberta, protecoes e as outras estrategias -
   //--- segue funcionando.
   //---
   //--- ⚠ A recuperacao NAO e anunciada aqui. Ela sai em CreateHandlesAndReport(),
   //--- depois de os handles existirem de fato: dizer "operacional novamente" e
   //--- so entao tentar criar handle e afirmar no log algo que ainda pode falhar.
   //---
   //--- ⚠ E o que se diz sobre a SAIDA depende de haver par ativo. Num boot ja
   //--- invalido nunca houve handle nesta instancia, e prometer que a saida por
   //--- cruzamento continua avaliada seria mentira — justamente para quem esta
   //--- lendo o log com uma posicao aberta na tela.
   void              ReportConfigInvalid(void)
     {
      if(m_configState == MA_CROSS_CONFIG_OK)
         return;
      if(m_configState == m_configLoggedState)
         return;
      m_configLoggedState = m_configState;

      if(m_logger == NULL)
         return;

      string exitNote = m_active.ready
                        ? " Uma posicao aberta continua com a saida por cruzamento avaliada pelas medias com que foi aberta."
                        : " Nao ha par de medias ativo: a saida por cruzamento fica indisponivel ate a correcao (SL, TP, trailing, breakeven e parcial seguem).";

      m_logger.Error("STRAT_MA",
                     "Entradas da MA Cross suspensas por configuracao invalida: " + ConfigStateText(m_configState) +
                     " O restante do EA segue normal." + exitNote);
     }

   //--- Fecha o ciclo: so aqui o estado logado volta a OK, e so com os dois
   //--- handles ja criados.
   bool              CreateHandlesAndReport(void)
     {
      if(!CreateHandles())
         return false;

      if(m_configLoggedState != MA_CROSS_CONFIG_OK)
        {
         m_configLoggedState = MA_CROSS_CONFIG_OK;
         if(m_logger != NULL)
            m_logger.Info("STRAT_MA", "Configuracao das medias corrigida e handles recriados. MA Cross operacional novamente.");
        }
      return true;
     }

   void              ReleaseHandles(void)
     {
      ReleaseIndicatorHandle(m_fastHandle);
      ReleaseIndicatorHandle(m_slowHandle);
      ClearActiveConfig();
     }

   void              ResetEntryTracking(void)
     {
      m_lastCrossTime     = 0;
      m_lastCrossSignal   = SIGNAL_NONE;
      m_candlesAfterCross = 0;
      m_lastCheckBarTime  = 0;
     }

   //--- ⚠ TROCA ATOMICA. A versao anterior comecava liberando o par vivo: se a
   //--- criacao do novo falhasse no meio, o EA ficava sem par nenhum e a saida
   //--- por cruzamento de uma posicao aberta ia junto. Agora o par antigo so
   //--- morre depois de os DOIS novos existirem, e handles e metadados sao
   //--- publicados no mesmo instante — nunca ha um par ativo descrito por
   //--- metadado que nao e o dele.
   bool              CreateHandles(void)
     {
      if((int)m_fastTimeframe <= 0 || (int)m_slowTimeframe <= 0)
        {
         if(m_logger != NULL)
            m_logger.Error("STRAT_MA", "Invalid configured timeframes");
         return false;
        }

      int newFastHandle = iMA(m_symbol, m_fastTimeframe, m_fastPeriod, 0, m_fastMethod, m_fastPrice);
      int newSlowHandle = iMA(m_symbol, m_slowTimeframe, m_slowPeriod, 0, m_slowMethod, m_slowPrice);

      if(newFastHandle == INVALID_HANDLE || newSlowHandle == INVALID_HANDLE)
        {
         //--- Desfaz o que chegou a nascer e devolve o par anterior intacto.
         ReleaseIndicatorHandle(newFastHandle);
         ReleaseIndicatorHandle(newSlowHandle);
         if(m_logger != NULL)
            m_logger.Error("STRAT_MA", "Failed to create MA handles");
         return false;
        }

      ReleaseHandles();
      m_fastHandle = newFastHandle;
      m_slowHandle = newSlowHandle;

      m_active.ready             = true;
      m_active.fastPeriod        = m_fastPeriod;
      m_active.slowPeriod        = m_slowPeriod;
      m_active.minDistancePoints = m_minDistancePoints;
      m_active.fastTimeframe     = m_fastTimeframe;
      m_active.slowTimeframe     = m_slowTimeframe;
      m_active.fastMethod        = m_fastMethod;
      m_active.slowMethod        = m_slowMethod;
      m_active.fastPrice         = m_fastPrice;
      m_active.slowPrice         = m_slowPrice;

      ResetEntryTracking();
      return true;
     }

   bool              LastClosedSlowShiftAt(const datetime cutoffTime,int &shift) const
     {
      shift = -1;
      if(cutoffTime <= 0)
         return false;

      int correspondingShift = iBarShift(m_symbol, m_active.slowTimeframe, cutoffTime, false);
      if(correspondingShift < 0)
         return false;

      datetime correspondingOpen = iTime(m_symbol, m_active.slowTimeframe, correspondingShift);
      if(correspondingOpen <= 0)
         return false;

      if(correspondingShift == 0)
         shift = 1;
      else
        {
         datetime newerOpen = iTime(m_symbol, m_active.slowTimeframe, correspondingShift - 1);
         if(newerOpen <= 0)
            return false;

         // If the cutoff is inside this slow bar, use the preceding closed bar.
         shift = (newerOpen > cutoffTime) ? correspondingShift + 1
                                          : correspondingShift;
        }

      if(shift <= 0)
         return false;
      return (iTime(m_symbol, m_active.slowTimeframe, shift) > 0);
     }

   bool              CopyIndicatorValue(const int handle,const int shift,double &value) const
     {
      value = 0.0;
      if(shift <= 0)
         return false;

      double singleValue[];
      ArrayResize(singleValue, 1);
      if(CopyBuffer(handle, 0, shift, 1, singleValue) != 1)
         return false;

      value = singleValue[0];
      return true;
     }

   bool              LoadBuffers(double &fastBuffer[],double &slowBuffer[])
     {
      //--- Sem par ativo nao se le nada. Vale para entrada e para saida.
      if(!m_active.ready)
         return false;

      ArrayResize(fastBuffer, 3);
      ArrayResize(slowBuffer, 3);
      ArraySetAsSeries(fastBuffer, true);
      ArraySetAsSeries(slowBuffer, true);

      if(CopyBuffer(m_fastHandle, 0, 0, 3, fastBuffer) < 3)
         return false;

      if(m_active.fastTimeframe == m_active.slowTimeframe)
         return (CopyBuffer(m_slowHandle, 0, 0, 3, slowBuffer) >= 3);

      ArrayInitialize(slowBuffer, 0.0);

      // A closed fast bar ends when the next newer fast bar opens.
      datetime fastCloseTime1 = iTime(m_symbol, m_active.fastTimeframe, 0);
      datetime fastCloseTime2 = iTime(m_symbol, m_active.fastTimeframe, 1);
      if(fastCloseTime1 <= 0 || fastCloseTime2 <= 0)
         return false;

      int slowShift1 = -1;
      int slowShift2 = -1;
      if(!LastClosedSlowShiftAt(fastCloseTime1, slowShift1) ||
         !LastClosedSlowShiftAt(fastCloseTime2, slowShift2))
         return false;

      double slowValue1 = 0.0;
      double slowValue2 = 0.0;
      if(!CopyIndicatorValue(m_slowHandle, slowShift1, slowValue1) ||
         !CopyIndicatorValue(m_slowHandle, slowShift2, slowValue2))
         return false;

      slowBuffer[1] = slowValue1;
      slowBuffer[2] = slowValue2;
      slowBuffer[0] = slowValue1;
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

   bool              HasMinimumDistance(const double diff) const
     {
      if(m_active.minDistancePoints <= 0)
         return true;

      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0)
         return true;

      return ((MathAbs(diff) / point) >= m_active.minDistancePoints);
     }

   ENUM_SIGNAL_TYPE  DetectCross(const double &fastBuffer[],const double &slowBuffer[]) const
     {
      double previousDiff = fastBuffer[2] - slowBuffer[2];
      double currentDiff  = fastBuffer[1] - slowBuffer[1];

      if(previousDiff < 0.0 && currentDiff > 0.0 && HasMinimumDistance(currentDiff))
         return SIGNAL_BUY;

      if(previousDiff > 0.0 && currentDiff < 0.0 && HasMinimumDistance(currentDiff))
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
      m_minDistancePoints = 0;
      m_fastTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_slowTimeframe     = FUSION_DEFAULT_TIMEFRAME;
      m_fastMethod        = MODE_EMA;
      m_slowMethod        = MODE_EMA;
      m_fastPrice         = PRICE_CLOSE;
      m_slowPrice         = PRICE_CLOSE;
      m_entryMode         = ENTRY_NEXT_CANDLE;
      m_exitMode          = EXIT_OPPOSITE_SIGNAL;
      m_configState       = MA_CROSS_CONFIG_OK;
      m_configLoggedState = MA_CROSS_CONFIG_OK;
      ClearActiveConfig();
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
      //--- Antes de qualquer campo mudar: as entradas estavam liberadas?
      bool wasOperational = EntriesOperational();

      bool coldChanged = (m_fastPeriod != settings.maFastPeriod ||
                          m_slowPeriod != settings.maSlowPeriod ||
                          m_minDistancePoints != settings.maMinDistancePoints ||
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
      m_minDistancePoints = settings.maMinDistancePoints;
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

      m_configState = FusionMACrossConfigState(settings);

      if(!m_initialized)
         return true;

      ReportConfigInvalid();

      if(!m_enabled)
        {
         ReleaseHandles();
         ResetEntryTracking();
         return true;
        }

      //--- ⚠ Devolve TRUE de proposito. SignalManager::Initialize e o ReloadAll
      //--- tratam false como falha de carga, e essa falha sobe ate
      //--- EAApplication::Initialize(), que aborta o EA inteiro. Configuracao de
      //--- media invalida nao pode derrubar painel, gerenciamento de posicao,
      //--- protecoes nem as outras estrategias: e falha FECHADA para as
      //--- ENTRADAS da MA Cross, so isso.
      //---
      //--- ⚠⚠ E por isso que os handles NAO sao liberados aqui. Uma posicao pode
      //--- ter sido aberta com a configuracao anterior, que era valida, e a saida
      //--- por sinal contrario / reversao depende desses handles: descarta-los
      //--- deixaria a posicao sem a saida que a governava, com SL e trailing
      //--- apenas. Os handles vivos seguem sendo os da ULTIMA configuracao
      //--- VALIDA - que e exatamente sob a qual a posicao foi aberta - enquanto
      //--- os campos ja refletem a configuracao nova. Quem separa os dois mundos e
      //--- EntriesOperational(): a saida usa o par ativo, a entrada exige que o
      //--- par ativo seja identico ao solicitado.
      //---
      //--- Resta um caso sem solucao possivel aqui: EA reiniciado JA com
      //--- configuracao invalida e posicao restaurada do chart state. Nunca houve
      //--- handle nesta instancia, e criar um a partir de configuracao invalida e
      //--- o que este item proibe. Ai a saida por cruzamento nao roda ate a
      //--- correcao.
      if(m_configState != MA_CROSS_CONFIG_OK)
        {
         ResetEntryTracking();
         return true;
        }

      //--- ⚠ `!ActiveMatchesRequested()` e o que garante NOVA TENTATIVA. Sem ele,
      //--- uma configuracao valida B que falhou no iMA() ficava suspensa para
      //--- sempre: `coldChanged` e falso (os campos solicitados JA estao em B) e
      //--- os handles nao estao invalidos (o par A foi preservado de proposito),
      //--- entao nada era recriado e o reload devolvia sucesso sem ter aplicado
      //--- B. Seguro — nenhuma entrada passava — mas parado.
      bool created = true;
      if(scope == RELOAD_COLD || scope == RELOAD_WARM || coldChanged ||
         !ActiveMatchesRequested() ||
         m_fastHandle == INVALID_HANDLE || m_slowHandle == INVALID_HANDLE)
         created = CreateHandlesAndReport();

      //--- Reativacao: as entradas estavam suspensas e voltaram agora. O estado
      //--- vigente e consumido para que um cruzamento formado ENQUANTO a
      //--- estrategia estava fora do ar nao vire entrada no primeiro tick. Nao
      //--- vale para o caminho normal (operacional -> operacional), que segue
      //--- como sempre foi.
      if(!wasOperational && EntriesOperational())
         PrimeEntryState();

      return created;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CStrategyBase::Initialize(logger, symbol))
         return false;

      //--- O Reload roda ANTES deste Initialize (SignalManager::Initialize), entao
      //--- m_configState ja esta preenchido. Aqui e onde o logger passa a existir,
      //--- e por isso o aviso da configuracao invalida sai deste ponto no boot.
      ReportConfigInvalid();

      if(!m_enabled)
         return true;
      if(m_configState != MA_CROSS_CONFIG_OK)
         return true;
      return CreateHandlesAndReport();
     }

   //--- Relogio de referencia da estrategia (quarentena de sinais e bloqueio de
   //--- reentrada no mesmo candle). Segue o par ATIVO: enquanto ele existir, e
   //--- ele que descreve os candles que a estrategia realmente enxerga.
   virtual ENUM_TIMEFRAMES ReferenceTimeframe(void) const override
     {
      return (m_active.ready ? m_active.fastTimeframe : m_timeframe);
     }

   virtual void      PrimeEntryState(void) override
     {
      ResetEntryTracking();
      if(!m_enabled || !m_initialized)
         return;

      m_lastCrossTime = iTime(m_symbol, m_active.fastTimeframe, 1);
      m_lastCheckBarTime = iTime(m_symbol, m_active.fastTimeframe, 0);
     }

   virtual ENUM_SIGNAL_TYPE GetEntrySignal(void) override
     {
      //--- Porta unica das entradas: configuracao valida E par ativo idêntico ao
      //--- solicitado. Nao basta olhar m_configState — com configuracao valida e
      //--- iMA() falhando, o par ativo continua sendo o antigo. Nao se loga nada
      //--- aqui: isto roda por tick.
      if(!EntriesOperational())
         return SIGNAL_NONE;

      double fastBuffer[];
      double slowBuffer[];
      if(!LoadBuffers(fastBuffer, slowBuffer))
         return SIGNAL_NONE;

      ENUM_SIGNAL_TYPE crossSignal = DetectCross(fastBuffer, slowBuffer);
      datetime crossBarTime = iTime(m_symbol, m_active.fastTimeframe, 1);

      if(crossSignal != SIGNAL_NONE && crossBarTime != m_lastCrossTime)
        {
         //--- A barreira e conferida na DETECCAO do cruzamento, nao no disparo: o
         //--- candle que importa e o que formou o sinal. Com `Segundo candle` isso
         //--- impede que um cruzamento nascido no escuro fique armado para disparar
         //--- depois. O cruzamento e consumido (m_lastCrossTime) para nao ser
         //--- reavaliado a cada tick do mesmo candle.
         if(FreshCandleBarrierBlocks(crossBarTime))
           {
            m_lastCrossTime = crossBarTime;
            m_lastCrossSignal = SIGNAL_NONE;
            m_candlesAfterCross = 0;
            m_lastCheckBarTime = iTime(m_symbol, m_active.fastTimeframe, 0);
            return SIGNAL_NONE;
           }

         m_lastCrossTime = crossBarTime;
         m_lastCrossSignal = crossSignal;
         m_candlesAfterCross = 0;
         m_lastCheckBarTime = iTime(m_symbol, m_active.fastTimeframe, 0);

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
         datetime currentBarTime = iTime(m_symbol, m_active.fastTimeframe, 0);
         if(currentBarTime != m_lastCheckBarTime)
           {
            m_lastCheckBarTime = currentBarTime;
            m_candlesAfterCross++;
           }

         if(m_candlesAfterCross >= 1)
           {
            //--- Rede de seguranca do disparo: um cruzamento armado ANTES da suspensao
            //--- normalmente e apagado pelo priming, mas o priming nao roda com posicao
            //--- aberta nem com o EA pausado. Aqui o invariante vale sozinho, sem
            //--- depender de quem chamou o que. Zera so o sinal armado e preserva
            //--- m_lastCrossTime, que ja identifica este cruzamento como consumido.
            if(FreshCandleBarrierBlocks(m_lastCrossTime))
              {
               m_lastCrossSignal = SIGNAL_NONE;
               m_candlesAfterCross = 0;
               return SIGNAL_NONE;
              }

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
      if((m_exitMode != EXIT_OPPOSITE_SIGNAL && m_exitMode != EXIT_REVERSE_SIGNAL) || !m_enabled || !m_initialized)
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

   virtual ENUM_EXIT_MODE ExitMode(void) const override
     {
      return m_exitMode;
     }
  };

#endif
