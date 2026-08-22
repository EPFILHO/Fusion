#ifndef __FUSION_TYPES_MQH__
#define __FUSION_TYPES_MQH__

#define FUSION_DEFAULT_TIMEFRAME PERIOD_M15
#define FUSION_NEWS_WINDOW_COUNT 3
#define FUSION_SETTINGS_SCHEMA_VERSION 14
//--- Quantas linhas o FusionSaveSettingsBlock grava. A validacao usa >=, entao
//--- arquivos de versoes anteriores com mais linhas continuam aceitos — mas
//--- ACRESCENTAR OU REMOVER UMA LINHA DO GRAVADOR EXIGE ATUALIZAR ESTE NUMERO.
//--- Esquecer faz todo perfil recem-salvo ser recusado como incompleto no
//--- carregamento seguinte, sem erro de compilacao para avisar. Ja aconteceu
//--- ao tirar debugLogs do perfil: 142 virou 141.
#define FUSION_SETTINGS_SCHEMA_LINE_COUNT 141

enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE = 0,
   SIGNAL_BUY  = 1,
   SIGNAL_SELL = -1
  };

enum ENUM_CONFLICT_RESOLUTION
  {
   CONFLICT_PRIORITY = 0,
   CONFLICT_CANCEL   = 1
  };

enum ENUM_TRADE_DIRECTION
  {
   DIRECTION_BOTH = 0,
   DIRECTION_BUY_ONLY,
   DIRECTION_SELL_ONLY
  };

enum ENUM_EXIT_MODE
  {
   EXIT_TP_SL = 0,
   EXIT_OPPOSITE_SIGNAL,
   EXIT_REVERSE_SIGNAL
  };

enum ENUM_PARTIAL_CLOSE_LEVEL
  {
   PARTIAL_CLOSE_NONE = 0,
   PARTIAL_CLOSE_TP1,
   PARTIAL_CLOSE_TP2
  };

enum ENUM_RSI_EXIT_MODE
  {
   RSI_EXIT_TP_SL = 0,
   RSI_EXIT_OPPOSITE_SIGNAL,
   RSI_EXIT_REVERSE_SIGNAL,
   RSI_EXIT_MIDDLE_TARGET
  };

enum ENUM_ENTRY_MODE
  {
   ENTRY_NEXT_CANDLE = 0,
   ENTRY_2ND_CANDLE
  };

enum ENUM_RSI_SIGNAL_MODE
  {
   RSI_SIGNAL_CROSSOVER = 0,
   RSI_SIGNAL_ZONE,
   RSI_SIGNAL_MIDDLE
  };

enum ENUM_RSI_FILTER_MODE
  {
   RSI_FILTER_DIRECTION = 0,
   RSI_FILTER_NEUTRAL,
   RSI_FILTER_EXTREMES
  };

enum ENUM_BB_FILTER_WIDTH_MODE
  {
   BB_FILTER_WIDTH_ABSOLUTE = 0,
   BB_FILTER_WIDTH_RELATIVE
  };

enum ENUM_BB_SIGNAL_MODE
  {
   BB_SIGNAL_REENTRY = 0,
   BB_SIGNAL_REBOUND,
   BB_SIGNAL_BREAKOUT
  };

enum ENUM_RELOAD_SCOPE
  {
   RELOAD_HOT = 0,
   RELOAD_WARM,
   RELOAD_COLD
  };

enum ENUM_NEWS_WINDOW_ACTION
  {
   NEWS_ACTION_BLOCK_ENTRIES = 0,
   NEWS_ACTION_CLOSE_AND_BLOCK
  };

enum ENUM_STREAK_ACTION
  {
   STREAK_ACTION_PAUSE = 0,
   STREAK_ACTION_STOP_DAY
  };

enum ENUM_PROFIT_TARGET_ACTION
  {
   PROFIT_ACTION_PARAR = 0,
   PROFIT_ACTION_ATIVAR_DD
  };

enum ENUM_DRAWDOWN_TYPE
  {
   DD_TIPO_FINANCEIRO = 0,
   DD_TIPO_PERCENTUAL
  };

enum ENUM_DRAWDOWN_PEAK_MODE
  {
   DD_PICO_REALIZADO = 0,
   DD_PICO_FLUTUANTE
  };

enum ENUM_UI_COMMAND
  {
   UI_COMMAND_NONE = 0,
   UI_COMMAND_TOGGLE_RUNNING,
   UI_COMMAND_TOGGLE_MACROSS,
   UI_COMMAND_TOGGLE_RSI,
   UI_COMMAND_TOGGLE_BB,
   UI_COMMAND_TOGGLE_TREND_MA1,
   UI_COMMAND_TOGGLE_TREND_MA2,
   UI_COMMAND_TOGGLE_RSI_FILTER,
   UI_COMMAND_TOGGLE_BB_FILTER,
   UI_COMMAND_TOGGLE_BB_SLOPE_DIRECTION,
   UI_COMMAND_SAVE_PROFILE,
   UI_COMMAND_LOAD_PROFILE,
   //--- Voltar a configuracao que o grafico JA usava, sem trocar de perfil.
   //--- Acrescentado no FIM de proposito: o valor dos anteriores nao muda.
   //---
   //--- Nao e um LOAD_PROFILE com outro nome. O LOAD existe para ADOTAR um
   //--- perfil, e por isso passa por recusas que protegem contra trocar
   //--- identidade sob uma operacao em curso — drawdown ativo, perfil ou Magic
   //--- em uso por outro grafico. Aqui nao ha adocao: e o retorno ao estado
   //--- anterior deste mesmo grafico, e aplicar aquelas recusas negaria
   //--- justamente o desfazer.
   //---
   //--- O caso que o exige: com o perfil ativo preso por outro grafico, CRIAR
   //--- PERFIL e uma saida deliberadamente permitida. Se a criacao aplicar e
   //--- falhar ao gravar, abandonar precisa desfazer — e a mesma trava que
   //--- motivou a criacao recusaria a volta, prendendo o usuario na retentativa.
   //---
   //--- Carrega as configuracoes a restaurar (hasSettings). Sem elas, cai para
   //--- o arquivo do perfil ativo — que pode nao existir, e por isso nao serve
   //--- como unico caminho.
   UI_COMMAND_RESTORE_ACTIVE_PROFILE
  };

struct SPartialTPConfig
  {
   bool   enabled;
   double percent;
   int    distancePoints;
  };

struct SNewsWindowConfig
  {
   bool                    enabled;
   int                     startHour;
   int                     startMinute;
   int                     endHour;
   int                     endMinute;
   ENUM_NEWS_WINDOW_ACTION action;
  };

struct SSymbolSpec
  {
   string symbol;
   int    digits;
   double point;
   double tickSize;
   double tickValue;
   double volumeMin;
   double volumeMax;
   double volumeStep;
   int    stopsLevel;
   int    freezeLevel;
   long   fillingMode;
  };

struct SEASettings
  {
   int                      schemaVersion;
   bool                     panelEnabled;
   string                   defaultProfileName;
   int                      magicNumber;
   int                      slippagePoints;
   bool                     debugLogs;
   bool                     showChartIndicators;
   color                    visualMAFastColor;
   color                    visualMASlowColor;
   color                    visualMATrendColor;
   color                    visualMATrend2Color;
   color                    visualBBColor;
   ENUM_LINE_STYLE          visualMAFastStyle;
   ENUM_LINE_STYLE          visualMASlowStyle;
   ENUM_LINE_STYLE          visualMATrendStyle;
   ENUM_LINE_STYLE          visualMATrend2Style;
   ENUM_LINE_STYLE          visualBBStyle;
   ENUM_CONFLICT_RESOLUTION conflictMode;
   ENUM_TRADE_DIRECTION     tradeDirection;
   bool                     enableSpreadProtection;
   int                      maxSpreadPoints;
   bool                     enableSessionFilter;
   int                      sessionStartHour;
   int                      sessionStartMinute;
   int                      sessionEndHour;
   int                      sessionEndMinute;
   bool                     sessionOvernight;
   bool                     closeOnSessionEnd;
   SNewsWindowConfig        newsWindows[FUSION_NEWS_WINDOW_COUNT];
   bool                     enableDailyLimits;
   int                      maxDailyTrades;
   double                   maxDailyLoss;
   double                   maxDailyGain;
   ENUM_PROFIT_TARGET_ACTION profitTargetAction;
   bool                     enableDrawdown;
   double                   maxDrawdown;
   ENUM_DRAWDOWN_TYPE       drawdownType;
   ENUM_DRAWDOWN_PEAK_MODE  drawdownPeakMode;
   bool                     lossStreakEnabled;
   int                      maxLossStreak;
   ENUM_STREAK_ACTION       lossStreakAction;
   int                      lossStreakPauseMinutes;
   bool                     winStreakEnabled;
   int                      maxWinStreak;
   ENUM_STREAK_ACTION       winStreakAction;
   int                      winStreakPauseMinutes;
   double                   fixedLot;
   int                      fixedSLPoints;
   int                      fixedTPPoints;
   bool                     compensateSLSpread;
   bool                     compensateTPSpread;
   bool                     usePartialTP;
   bool                     freeFinalTP;
   SPartialTPConfig         tp1;
   SPartialTPConfig         tp2;
   bool                     useTrailing;
   int                      trailingStartPoints;
   int                      trailingStepPoints;
   bool                     useBreakeven;
   int                      breakevenTriggerPoints;
   int                      breakevenOffsetPoints;
   bool                     useMACross;
   int                      maCrossPriority;
   int                      maFastPeriod;
   int                      maSlowPeriod;
   int                      maMinDistancePoints;
   ENUM_TIMEFRAMES          maFastTimeframe;
   ENUM_TIMEFRAMES          maSlowTimeframe;
   ENUM_MA_METHOD           maFastMethod;
   ENUM_MA_METHOD           maSlowMethod;
   ENUM_APPLIED_PRICE       maFastPrice;
   ENUM_APPLIED_PRICE       maSlowPrice;
   ENUM_ENTRY_MODE          maEntryMode;
   ENUM_EXIT_MODE           maExitMode;
   bool                     useRSI;
   int                      rsiPriority;
   int                      rsiPeriod;
   ENUM_TIMEFRAMES          rsiTimeframe;
   int                      rsiOversold;
   int                      rsiOverbought;
   int                      rsiMiddle;
   ENUM_RSI_SIGNAL_MODE     rsiMode;
   ENUM_APPLIED_PRICE       rsiPrice;
   ENUM_RSI_EXIT_MODE       rsiExitMode;
   bool                     useBollinger;
   int                      bbPriority;
   int                      bbPeriod;
   ENUM_TIMEFRAMES          bbTimeframe;
   double                   bbDeviation;
   ENUM_APPLIED_PRICE       bbPrice;
   ENUM_BB_SIGNAL_MODE      bbMode;
   ENUM_EXIT_MODE           bbExitMode;
   bool                     useTrendFilter;
   bool                     trendMA1Enabled;
   int                      trendMAPeriod;
   ENUM_TIMEFRAMES          trendMATimeframe;
   ENUM_MA_METHOD           trendMAMethod;
   ENUM_APPLIED_PRICE       trendMAPrice;
   bool                     trendMA2Enabled;
   int                      trendSellMAPeriod;
   ENUM_TIMEFRAMES          trendSellMATimeframe;
   ENUM_MA_METHOD           trendSellMAMethod;
   ENUM_APPLIED_PRICE       trendSellMAPrice;
   bool                     useRSIFilter;
   ENUM_RSI_FILTER_MODE     rsiFilterMode;
   int                      rsiFilterPeriod;
   ENUM_TIMEFRAMES          rsiFilterTimeframe;
   int                      rsiFilterBuyMin;
   int                      rsiFilterSellMax;
   ENUM_APPLIED_PRICE       rsiFilterPrice;
   bool                     bbFilterEnabled;
   ENUM_BB_FILTER_WIDTH_MODE bbFilterMode;
   int                      bbFilterPeriod;
   ENUM_TIMEFRAMES          bbFilterTimeframe;
   double                   bbFilterDeviation;
   ENUM_APPLIED_PRICE       bbFilterPrice;
   int                      bbFilterMinWidthPoints;
   double                   bbFilterMinWidthPercent;
   bool                     bbFilterSlopeDirectionEnabled;
   int                      bbFilterSlopeLookback;
   int                      bbFilterMinSlopePoints;
   bool                     isTester;
  };

//--- Faixa normativa de periodo de indicador, uma so para a tela e para o
//--- motor. O VPeriod da GUI le daqui.
#define FUSION_INDICATOR_PERIOD_MIN 1
#define FUSION_INDICATOR_PERIOD_MAX 1000

bool FusionIndicatorPeriodInRange(const int period)
  {
   return (period >= FUSION_INDICATOR_PERIOD_MIN && period <= FUSION_INDICATOR_PERIOD_MAX);
  }

long FusionMAHorizonSeconds(const int period,const ENUM_TIMEFRAMES timeframe)
  {
   int timeframeSeconds = PeriodSeconds(timeframe);
   if(period <= 0 || timeframeSeconds <= 0)
      return 0;
   return ((long)period * (long)timeframeSeconds);
  }

//--- ⚠ Regra do TREND FILTER, nao da MA Cross. Aqui a ordem e ESTRITA: a MA1 e a
//--- barreira longa e a MA2 a curta, e horizontes iguais nao servem porque as
//--- duas barreiras coincidiriam. A MA Cross tem outra semantica e outro
//--- predicado (FusionMACrossConfigState, abaixo) - nao unifique os dois.
bool FusionTrendMAOrderValid(const SEASettings &settings)
  {
   if(!settings.trendMA1Enabled || !settings.trendMA2Enabled)
      return true;

   long ma1Horizon = FusionMAHorizonSeconds(settings.trendMAPeriod, settings.trendMATimeframe);
   long ma2Horizon = FusionMAHorizonSeconds(settings.trendSellMAPeriod, settings.trendSellMATimeframe);
   return (ma1Horizon > 0 && ma2Horizon > 0 && ma1Horizon > ma2Horizon);
  }

//+------------------------------------------------------------------+
//| Validade da configuracao das medias da estrategia MA Cross.       |
//|                                                                    |
//| FONTE UNICA: a GUI e o motor leem daqui. Nao replique a compara-  |
//| cao em outro arquivo — a regra antiga vivia so na tela, era       |
//| `maFastPeriod < maSlowPeriod`, e errava dos dois lados:           |
//|   · recusava SMA 9 contra EMA 9, que sao curvas diferentes e uma  |
//|     configuracao legitima;                                        |
//|   · aceitava EMA 9 H4 como "rapida" contra EMA 21 M1 como         |
//|     "lenta", em que a rapida tem horizonte 96x maior.             |
//|                                                                    |
//| O que decide e o HORIZONTE (periodo x duracao do timeframe), nao  |
//| o periodo cru. Horizontes IGUAIS sao validos desde que as curvas  |
//| difiram em algum campo: EMA 10 M1 e EMA 5 M2 cobrem o mesmo tempo |
//| por caminhos diferentes e cruzam de verdade. So e invalido quando |
//| os quatro campos coincidem — ai as duas curvas sao a MESMA linha  |
//| e nao existe cruzamento possivel.                                 |
//+------------------------------------------------------------------+
enum ENUM_MA_CROSS_CONFIG
  {
   MA_CROSS_CONFIG_OK = 0,           // valida
   MA_CROSS_CONFIG_PERIOD_RANGE,     // periodo fora de 1..1000
   MA_CROSS_CONFIG_HORIZON_INVALID,  // periodo ou timeframe nao dao horizonte
   MA_CROSS_CONFIG_IDENTICAL,        // as duas curvas sao a mesma linha
   MA_CROSS_CONFIG_FAST_LONGER       // rapida com horizonte maior que a lenta
  };

ENUM_MA_CROSS_CONFIG FusionMACrossConfigState(const SEASettings &settings)
  {
   //--- A faixa normativa tambem mora aqui, e nao so no VPeriod da tela. Sem
   //--- isto, um periodo 1001 vindo do F7 ou de um perfil antigo produzia
   //--- horizonte positivo, passava por valido e chegava ao iMA - a tela
   //--- recusava e o motor aceitava, que e a assimetria que este item veio
   //--- fechar.
   if(!FusionIndicatorPeriodInRange(settings.maFastPeriod) ||
      !FusionIndicatorPeriodInRange(settings.maSlowPeriod))
      return MA_CROSS_CONFIG_PERIOD_RANGE;

   long fastHorizon = FusionMAHorizonSeconds(settings.maFastPeriod, settings.maFastTimeframe);
   long slowHorizon = FusionMAHorizonSeconds(settings.maSlowPeriod, settings.maSlowTimeframe);

   //--- Falha fechada: sem horizonte calculavel nao ha como afirmar a ordem.
   if(fastHorizon <= 0 || slowHorizon <= 0)
      return MA_CROSS_CONFIG_HORIZON_INVALID;

   if(fastHorizon > slowHorizon)
      return MA_CROSS_CONFIG_FAST_LONGER;

   //--- Identidade e conferida nos QUATRO campos, nao pelo horizonte: dois
   //--- horizontes iguais podem vir de curvas bem diferentes.
   if(settings.maFastPeriod    == settings.maSlowPeriod &&
      settings.maFastTimeframe == settings.maSlowTimeframe &&
      settings.maFastMethod    == settings.maSlowMethod &&
      settings.maFastPrice     == settings.maSlowPrice)
      return MA_CROSS_CONFIG_IDENTICAL;

   return MA_CROSS_CONFIG_OK;
  }

bool FusionMACrossConfigValid(const SEASettings &settings)
  {
   return (FusionMACrossConfigState(settings) == MA_CROSS_CONFIG_OK);
  }

bool FusionDrawdownSettingsCompatible(const SEASettings &currentSettings,const SEASettings &candidateSettings)
  {
   const double tolerance = 0.0000001;
   return (currentSettings.magicNumber == candidateSettings.magicNumber &&
           currentSettings.enableDailyLimits == candidateSettings.enableDailyLimits &&
           MathAbs(currentSettings.maxDailyGain - candidateSettings.maxDailyGain) <= tolerance &&
           currentSettings.profitTargetAction == candidateSettings.profitTargetAction &&
           currentSettings.enableDrawdown == candidateSettings.enableDrawdown &&
           MathAbs(currentSettings.maxDrawdown - candidateSettings.maxDrawdown) <= tolerance &&
           currentSettings.drawdownType == candidateSettings.drawdownType &&
           currentSettings.drawdownPeakMode == candidateSettings.drawdownPeakMode);
  }

string FusionDrawdownProfileBlockMessage(void)
  {
   return "Perfil nao carregado: DD diario ativo. " +
          "O novo perfil deve manter a mesma regra ate o novo dia. " +
          "A consistencia no trade comeca por obedecer ao gerenciamento inicial.";
  }

struct SSignalCandidate
  {
   ENUM_SIGNAL_TYPE signal;
   int              priority;
   string           strategyId;
   string           strategyName;
   string           shortName;
  };

struct SSignalDecision
  {
   ENUM_SIGNAL_TYPE signal;
   string           strategyId;
   string           strategyName;
   string           shortName;
   string           blockedBy;
  };

struct SRiskPlan
  {
   double volume;
   double stopLoss;
   double takeProfit;
   bool   usePartialTP;
   double tp1Price;
   double tp1Volume;
   double tp2Price;
   double tp2Volume;
  };

struct SPositionRuntimeState
  {
   bool               hasPosition;
   ulong              ticket;
   ulong              positionId;
   ENUM_POSITION_TYPE type;
   string             symbol;
   double             entryPrice;
   double             volume;
   double             stopLoss;
   double             takeProfit;
   string             ownerStrategyId;
   string             ownerStrategyName;
   bool               tp1Executed;
   bool               tp2Executed;
   bool               breakevenActive;
   bool               trailingActive;
   double             realizedPartialProfit;
   double             tp1Price;
   double             tp1Volume;
   double             tp2Price;
   double             tp2Volume;
   bool               partialClosePending;
   ENUM_PARTIAL_CLOSE_LEVEL pendingPartialLevel;
   double             pendingPartialInitialVolume;
   double             pendingPartialRequestedVolume;
   double             pendingPartialBaselineExitVolume;
   double             pendingPartialPreProjectedProfit;
   bool               pendingPartialFloatingReferenceSet;
   double             pendingPartialFloatingReference;
   ulong              pendingPartialOrderTicket;
   ulong              pendingPartialDealTicket;
   uint               pendingPartialRetcode;
   datetime           pendingPartialSince;
   double             dayPeakProjectedProfit;
  };

struct SStreakRuntimeState
  {
   int      dayKey;
   int      lossStreak;
   int      winStreak;
   bool     lossStopDayBlocked;
   bool     winStopDayBlocked;
   datetime lossPauseUntil;
   datetime winPauseUntil;
  };

struct SDailyLimitsRuntimeState
  {
   int    dayKey;
   int    dailyTradeCount;
   int    dailyLossCount;
   int    dailyWinCount;
   int    dailyBreakevenCount;
   bool   outcomeCountsKnown;
   double dailyClosedProfit;
   bool   tradesLimitReached;
   bool   lossLimitReached;
   bool   gainLimitReached;
  };

struct SDrawdownRuntimeState
  {
   int    dayKey;
   bool   protectionActive;
   bool   limitReached;
   double peakProjectedProfit;
   double triggerProjectedProfit;
   double triggerDrawdownAmount;
   double triggerBufferProfit;
  };

struct SClosedTradeSummary
  {
   bool     found;
   bool     complete;
   bool     contextMatched;
   double   totalProfit;
   double   finalProfit;
   double   entryVolume;
   double   exitVolume;
   int      exitDeals;
   datetime lastExitTime;
  };

struct SDailyHistorySummary
  {
   bool   complete;
   int    dayKey;
   double closedProfit;
   int    tradeCount;
   int    lossCount;
   int    winCount;
   int    breakevenCount;
   int    lossStreak;
   int    winStreak;
  };

struct SChartStateContext
  {
   ulong  chartId;
   string symbol;
   string timeframe;
   int    periodValue;
   int    deinitReason;
   bool   discardedUnsavedDraft;
  };

//+------------------------------------------------------------------+
//| Estado LOGICO de entrada das estrategias, para atravessar a troca |
//| do timeframe visual.                                              |
//|                                                                    |
//| ⚠ Nao e uma ordem pronta nem um sinal armado. E o que cada        |
//| estrategia ja tinha OBSERVADO antes do desligamento: qual candle  |
//| ja foi contado, qual cruzamento ja disparou, qual espera de        |
//| segundo candle estava em curso. Depois da restauracao, qualquer    |
//| entrada ainda precisa nascer num tick normal e passar de novo por  |
//| permissao, protecoes, spread, sessao, noticias, resolvedor,        |
//| filtros, direcao, risco e execucao.                               |
//|                                                                    |
//| ⚠ `eligible` e decidido na EXPORTACAO, nao na leitura: so uma      |
//| troca controlada de grafico, mesmo simbolo, EA iniciado e sem      |
//| bloqueio conhecido produz continuidade. Fora disso o bloco e       |
//| gravado inelegivel e o boot cai no caminho conservador.            |
//|                                                                    |
//| A quarentena do item 12 viaja junto, por estrategia, para que a    |
//| continuidade NAO possa ser usada para burlar a exigencia de sinal  |
//| fresco depois de uma volta de permissao.                          |
//+------------------------------------------------------------------+
#define FUSION_ENTRY_STATE_VERSION           1
//--- Janela de validade do handoff. Estado mais velho que isto nunca
//--- ressuscita sinal: uma troca de timeframe leva segundos, e o que
//--- passa disso ja nao e "a mesma sessao".
#define FUSION_ENTRY_STATE_HANDOFF_SECONDS 120

struct SEntryStateSnapshot
  {
   //--- ⚠ NAO SERIALIZADO. Diz se o arquivo TRAZIA bloco `entry.*`, e nao se ele
   //--- prestava. Sem isto, arquivo antigo (bloco ausente) e bloco corrompido
   //--- chegavam identicos ao predicado — os dois com valid=false e
   //--- capturedAt=0 — e o diagnostico saia errado, ainda que o fallback fosse
   //--- igualmente seguro. O loader publica `present=true` mesmo quando recusa o
   //--- bloco, sem publicar os campos parciais.
   bool     present;
   //--- Integridade e origem
   bool     valid;                 // bloco presente, completo e semanticamente sao
   bool     eligible;              // continuidade autorizada na exportacao
   int      version;
   datetime capturedAt;            // TimeLocal() do desligamento
   //--- MA Cross
   datetime maLastCrossTime;
   int      maLastCrossSignal;     // ENUM_SIGNAL_TYPE serializado como int
   int      maCandlesAfterCross;
   datetime maLastCheckBarTime;
   bool     maPendingObserved;     // havia E2C_WAIT realmente observado
   bool     maQuarantine;
   datetime maBarrier;
   //--- RSI
   datetime rsiLastSignalBarTime;
   bool     rsiQuarantine;
   datetime rsiBarrier;
   //--- Bollinger
   datetime bbLastSignalBarTime;
   bool     bbQuarantine;
   datetime bbBarrier;
  };

void ResetEntryStateSnapshot(SEntryStateSnapshot &snapshot)
  {
   snapshot.present              = false;
   snapshot.valid                = false;
   snapshot.eligible             = false;
   snapshot.version              = FUSION_ENTRY_STATE_VERSION;
   snapshot.capturedAt           = 0;
   snapshot.maLastCrossTime      = 0;
   snapshot.maLastCrossSignal    = (int)SIGNAL_NONE;
   snapshot.maCandlesAfterCross  = 0;
   snapshot.maLastCheckBarTime   = 0;
   snapshot.maPendingObserved    = false;
   snapshot.maQuarantine         = false;
   snapshot.maBarrier            = 0;
   snapshot.rsiLastSignalBarTime = 0;
   snapshot.rsiQuarantine        = false;
   snapshot.rsiBarrier           = 0;
   snapshot.bbLastSignalBarTime  = 0;
   snapshot.bbQuarantine         = false;
   snapshot.bbBarrier            = 0;
  }

//--- Janela do handoff. Fora dela o estado nunca ressuscita sinal.
//---
//--- ⚠ Relogio que anda para tras tambem reprova: `now` anterior a captura e
//--- sinal de ajuste de hora ou de arquivo de outra maquina, e nenhum dos dois
//--- autoriza continuidade.
bool FusionEntryStateHandoffFresh(const SEntryStateSnapshot &entry,const datetime now)
  {
   if(!entry.valid)          return false;
   if(entry.capturedAt <= 0) return false;
   if(now <= 0)              return false;
   if(now < entry.capturedAt) return false;
   return ((long)(now - entry.capturedAt) <= FUSION_ENTRY_STATE_HANDOFF_SECONDS);
  }

//+------------------------------------------------------------------+
//| Compatibilidade da configuracao, POR ESTRATEGIA.                  |
//|                                                                    |
//| O estado so pode ser importado quando a configuracao final for a   |
//| mesma que produziu o estado — nos campos que afetam ENTRADA.       |
//|                                                                    |
//| ⚠ Por estrategia, e nao global: mexer na MA nao pode invalidar o   |
//| estado do RSI e do Bollinger, que continuam coerentes.            |
//|                                                                    |
//| ⚠ Diferenca puramente VISUAL ou de sessao nao entra aqui. Cor de   |
//| linha, tema, painel e logs de debug nao mudam sinal nenhum, e      |
//| trata-los como incompatibilidade jogaria fora estado bom.         |
//+------------------------------------------------------------------+
bool FusionMACrossEntryStateCompatible(const SEASettings &origin,const SEASettings &current)
  {
   return (origin.useMACross          == current.useMACross &&
           origin.maCrossPriority     == current.maCrossPriority &&
           origin.maFastPeriod        == current.maFastPeriod &&
           origin.maSlowPeriod        == current.maSlowPeriod &&
           origin.maFastTimeframe     == current.maFastTimeframe &&
           origin.maSlowTimeframe     == current.maSlowTimeframe &&
           origin.maFastMethod        == current.maFastMethod &&
           origin.maSlowMethod        == current.maSlowMethod &&
           origin.maFastPrice         == current.maFastPrice &&
           origin.maSlowPrice         == current.maSlowPrice &&
           origin.maMinDistancePoints == current.maMinDistancePoints &&
           origin.maEntryMode         == current.maEntryMode);
  }

bool FusionRSIEntryStateCompatible(const SEASettings &origin,const SEASettings &current)
  {
   //--- rsiExitMode entra de proposito: o modo de saida por linha media muda a
   //--- elegibilidade da propria ENTRADA (SignalAlreadyReachedMiddleTarget).
   return (origin.useRSI       == current.useRSI &&
           origin.rsiPriority  == current.rsiPriority &&
           origin.rsiPeriod    == current.rsiPeriod &&
           origin.rsiTimeframe == current.rsiTimeframe &&
           origin.rsiOversold  == current.rsiOversold &&
           origin.rsiOverbought== current.rsiOverbought &&
           origin.rsiMiddle    == current.rsiMiddle &&
           origin.rsiMode      == current.rsiMode &&
           origin.rsiPrice     == current.rsiPrice &&
           origin.rsiExitMode  == current.rsiExitMode);
  }

bool FusionBollingerEntryStateCompatible(const SEASettings &origin,const SEASettings &current)
  {
   return (origin.useBollinger == current.useBollinger &&
           origin.bbPriority   == current.bbPriority &&
           origin.bbPeriod     == current.bbPeriod &&
           origin.bbTimeframe  == current.bbTimeframe &&
           origin.bbDeviation  == current.bbDeviation &&
           origin.bbPrice      == current.bbPrice &&
           origin.bbMode       == current.bbMode);
  }

//+------------------------------------------------------------------+
//| Aceite GLOBAL do handoff.                                         |
//|                                                                    |
//| ⚠ Funcao PURA e UNICA. O EA e a sonda chamam esta mesma decisao —  |
//| uma sonda que reimplementasse a regra provaria a copia, nao o      |
//| produto, e as duas divergiriam no primeiro ajuste.                |
//|                                                                    |
//| Os bloqueios chegam ja resolvidos pelo motor (posicao, contexto,   |
//| permissao, protecao). Nao se deriva elegibilidade de texto de      |
//| aviso nem de estado visual da GUI: mensagem e consequencia, nao    |
//| fonte de verdade.                                                 |
//+------------------------------------------------------------------+
enum ENUM_ENTRY_HANDOFF_RESULT
  {
   ENTRY_HANDOFF_ACCEPTED = 0,
   ENTRY_HANDOFF_NO_BLOCK,        // arquivo antigo, sem bloco entry.*
   ENTRY_HANDOFF_INVALID_BLOCK,   // bloco presente porem invalido
   ENTRY_HANDOFF_NOT_ELIGIBLE,    // exportado sem continuidade autorizada
   ENTRY_HANDOFF_STALE,           // fora da janela de 120 s
   ENTRY_HANDOFF_NOT_CHART_CHANGE,
   ENTRY_HANDOFF_SYMBOL_CHANGED,
   ENTRY_HANDOFF_NOT_STARTED,
   ENTRY_HANDOFF_POSITION,        // posicao ou pendencia: caminho conservador
   ENTRY_HANDOFF_BLOCKED,         // contexto, permissao ou protecao
   ENTRY_HANDOFF_ORIGIN_UNKNOWN   // settings que produziram o estado nao chegaram
  };

struct SEntryHandoffContext
  {
   bool     originSettingsKnown;
   bool     wasChartChange;
   bool     sameSymbol;
   bool     wasStarted;
   bool     hasPositionOrPending;
   bool     operationalBlocked;   // contexto/runtime bloqueado
   bool     permissionBlocked;
   bool     protectionBlocked;
   datetime now;
  };

ENUM_ENTRY_HANDOFF_RESULT FusionEvaluateEntryHandoff(const SEntryStateSnapshot &entry,
                                                     const SEntryHandoffContext &context)
  {
   //--- Ordem deliberada: primeiro o que e AUSENCIA (arquivo antigo), depois o
   //--- que e DEFEITO, depois o que e CONTEXTO. Assim o motivo relatado e o mais
   //--- especifico, e nao o primeiro que por acaso reprovou.
   //---
   //--- ⚠ `present` e a UNICA fonte de "o arquivo trazia bloco". Deduzir isso de
   //--- capturedAt/version confundia arquivo antigo com bloco corrompido, porque
   //--- os dois chegam resetados.
   if(!entry.present)
      return ENTRY_HANDOFF_NO_BLOCK;
   if(!entry.valid)
      return ENTRY_HANDOFF_INVALID_BLOCK;
   if(!entry.eligible)
      return ENTRY_HANDOFF_NOT_ELIGIBLE;
   //--- Sem as settings que produziram o estado nao ha como julgar
   //--- compatibilidade por estrategia, e importar as cegas seria pior que
   //--- primear.
   if(!context.originSettingsKnown)
      return ENTRY_HANDOFF_ORIGIN_UNKNOWN;
   if(!context.wasChartChange)
      return ENTRY_HANDOFF_NOT_CHART_CHANGE;
   if(!context.sameSymbol)
      return ENTRY_HANDOFF_SYMBOL_CHANGED;
   if(!context.wasStarted)
      return ENTRY_HANDOFF_NOT_STARTED;
   if(!FusionEntryStateHandoffFresh(entry, context.now))
      return ENTRY_HANDOFF_STALE;
   if(context.hasPositionOrPending)
      return ENTRY_HANDOFF_POSITION;
   if(context.operationalBlocked || context.permissionBlocked || context.protectionBlocked)
      return ENTRY_HANDOFF_BLOCKED;

   return ENTRY_HANDOFF_ACCEPTED;
  }

string FusionEntryHandoffReason(const ENUM_ENTRY_HANDOFF_RESULT result)
  {
   switch(result)
     {
      case ENTRY_HANDOFF_ACCEPTED:         return "";
      case ENTRY_HANDOFF_NO_BLOCK:         return "estado anterior nao trazia bloco de sinais";
      case ENTRY_HANDOFF_INVALID_BLOCK:    return "bloco de sinais invalido";
      case ENTRY_HANDOFF_NOT_ELIGIBLE:     return "novas entradas nao estavam liberadas no momento da troca";
      case ENTRY_HANDOFF_STALE:            return "estado antigo demais para continuidade";
      case ENTRY_HANDOFF_NOT_CHART_CHANGE: return "reinicio nao foi troca de timeframe";
      case ENTRY_HANDOFF_SYMBOL_CHANGED:   return "ativo do grafico mudou";
      case ENTRY_HANDOFF_NOT_STARTED:      return "EA nao estava iniciado";
      case ENTRY_HANDOFF_POSITION:         return "posicao ou fechamento pendente";
      case ENTRY_HANDOFF_BLOCKED:          return "bloqueio operacional, de permissao ou de protecao";
      case ENTRY_HANDOFF_ORIGIN_UNKNOWN:   return "configuracao de origem do estado desconhecida";
     }
   return "motivo desconhecido";
  }

//+------------------------------------------------------------------+
//| Maquina de estados do cruzamento da MA — LOGICA PURA.             |
//|                                                                    |
//| Nao conhece handle, buffer, iTime, logger, ordem, filtro nem       |
//| protecao. Recebe estado + evento, devolve acao. O caminho de       |
//| producao detecta o cruzamento, consulta as barreiras e emite os    |
//| logs conforme a acao devolvida.                                   |
//|                                                                    |
//| ⚠ Existe para a sonda exercitar a MESMA transicao que o EA usa.    |
//| Uma sonda com maquina de estados paralela provaria a copia.        |
//|                                                                    |
//| ⚠ As barreiras chegam como resultado JA calculado, e nao como      |
//| dependencia, porque consulta-las tem efeito colateral: desarmam ao |
//| passar e logam ao recusar. Chama-las fora da hora certa gastaria a |
//| quarentena. Por isso as duas pre-condicoes que decidem QUANDO      |
//| consultar sao funcoes proprias, usadas pela producao e por este    |
//| helper — uma definicao, dois chamadores, sem duplicar a regra.     |
//+------------------------------------------------------------------+
enum ENUM_MA_CROSS_ACTION
  {
   MA_ACTION_NONE = 0,
   MA_ACTION_NEXT_CANDLE_FIRE,     // modo Candle seguinte: dispara na deteccao
   MA_ACTION_E2C_ARM,              // Segundo candle: espera armada
   MA_ACTION_E2C_FIRE,             // disparo de pendencia local
   MA_ACTION_E2C_FIRE_IMPORTED,    // disparo de pendencia vinda do chart state
   MA_ACTION_NEW_CROSS_BLOCKED,    // cruzamento novo recusado por barreira
   MA_ACTION_PENDING_BLOCKED       // pendencia recusada pela quarentena do item 12
  };

struct SMACrossTrackingState
  {
   datetime lastCrossTime;
   int      lastCrossSignal;      // ENUM_SIGNAL_TYPE serializado
   int      candlesAfterCross;
   datetime lastCheckBarTime;
   bool     pendingImported;
  };

struct SMACrossEvent
  {
   bool     crossDetected;
   int      crossSignal;
   datetime crossBarTime;         // abertura do candle [1]
   datetime currentBarTime;       // abertura do candle [0]
   bool     secondCandleMode;
  };

struct SMACrossOutcome
  {
   ENUM_MA_CROSS_ACTION action;
   int                  signal;            // sinal a devolver, ou SIGNAL_NONE
   bool                 importedCancelled; // pendencia importada morreu neste passo
  };

//--- Pre-condicao 1: ha cruzamento novo, ainda nao consumido?
bool FusionMACrossHasNewCross(const SMACrossTrackingState &state,const SMACrossEvent &event)
  {
   return (event.crossDetected &&
           event.crossSignal != (int)SIGNAL_NONE &&
           event.crossBarTime != state.lastCrossTime);
  }

//--- Pre-condicao 2: a pendencia armada dispararia NESTE passo?
//---
//--- ⚠ Inclui a virada de candle que ainda nao foi contada. Sem isso, a
//--- producao consultaria a quarentena em passos em que nada dispara — e cada
//--- consulta indevida pode desarma-la cedo demais.
bool FusionMACrossPendingWouldFire(const SMACrossTrackingState &state,const SMACrossEvent &event)
  {
   if(!event.secondCandleMode)
      return false;
   if(state.lastCrossSignal == (int)SIGNAL_NONE)
      return false;
   if(FusionMACrossHasNewCross(state, event))
      return false;

   int advanced = state.candlesAfterCross;
   if(event.currentBarTime != state.lastCheckBarTime)
      advanced++;
   return (advanced >= 1);
  }

void FusionMACrossApply(SMACrossTrackingState &state,
                        const SMACrossEvent &event,
                        const bool newCrossBlocked,
                        const bool pendingBlocked,
                        SMACrossOutcome &outcome)
  {
   outcome.action            = MA_ACTION_NONE;
   outcome.signal            = (int)SIGNAL_NONE;
   outcome.importedCancelled = false;

   if(FusionMACrossHasNewCross(state, event))
     {
      //--- Contracruzamento: a identidade importada morre antes de qualquer
      //--- decisao, nos dois desfechos.
      if(state.pendingImported)
        {
         state.pendingImported     = false;
         outcome.importedCancelled = true;
        }

      state.lastCrossTime     = event.crossBarTime;
      state.candlesAfterCross = 0;
      state.lastCheckBarTime  = event.currentBarTime;

      if(newCrossBlocked)
        {
         //--- Cruzamento do intervalo cego (ou da quarentena): descartado, e a
         //--- pendencia antiga cai junto.
         state.lastCrossSignal = (int)SIGNAL_NONE;
         outcome.action        = MA_ACTION_NEW_CROSS_BLOCKED;
         return;
        }

      state.lastCrossSignal = event.crossSignal;

      if(!event.secondCandleMode)
        {
         state.lastCrossSignal = (int)SIGNAL_NONE;
         outcome.action        = MA_ACTION_NEXT_CANDLE_FIRE;
         outcome.signal        = event.crossSignal;
         return;
        }

      outcome.action = MA_ACTION_E2C_ARM;
      return;
     }

   if(event.secondCandleMode && state.lastCrossSignal != (int)SIGNAL_NONE)
     {
      if(event.currentBarTime != state.lastCheckBarTime)
        {
         state.lastCheckBarTime = event.currentBarTime;
         state.candlesAfterCross++;
        }

      if(state.candlesAfterCross >= 1)
        {
         if(pendingBlocked)
           {
            state.lastCrossSignal   = (int)SIGNAL_NONE;
            state.candlesAfterCross = 0;
            state.pendingImported   = false;
            outcome.action          = MA_ACTION_PENDING_BLOCKED;
            return;
           }

         outcome.signal = state.lastCrossSignal;
         outcome.action = state.pendingImported ? MA_ACTION_E2C_FIRE_IMPORTED
                                                : MA_ACTION_E2C_FIRE;
         //--- Disparou: o tracking inteiro zera, inclusive a marca de importado.
         state.lastCrossTime     = 0;
         state.lastCrossSignal   = (int)SIGNAL_NONE;
         state.candlesAfterCross = 0;
         state.lastCheckBarTime  = 0;
         state.pendingImported   = false;
        }
     }
  }

struct SUIPanelSnapshot
  {
   SEASettings settings;
   bool   started;
   //--- "ha posicao gerenciada OU fechamento aguardando o historico confirmar"
   //--- (HasManagedOrPendingPosition). E o conceito certo para BLOQUEAR EDICAO:
   //--- nos dois casos o EA nao esta livre.
   //--- ⚠ NAO serve para o distintivo OPERANDO nem para dizer "posicao aberta":
   //--- durante a reconciliacao a posicao ja fechou, e anunciar operacao em
   //--- curso ali seria falso. Para isso existe o campo abaixo.
   bool   hasPosition;
   //--- Posicao REALMENTE aberta agora (m_positionState.hasPosition), sem a
   //--- reconciliacao pendente.
   //---
   //--- ⚠ Existe porque e ESTE o booleano que o CTradePermissionGuard recebe
   //--- (`Refresh(m_positionState.hasPosition)`), e e ele que decide a forma
   //--- GRAVE da mensagem — "Gerenciamento da posicao interrompido" em vez de
   //--- "Habilite para iniciar". Um consumidor que decida "isto e critico" pelo
   //--- `hasPosition` acima anuncia posicao aberta durante uma reconciliacao em
   //--- que ela ja fechou, e ainda por cima com o texto na forma branda, porque
   //--- o guard recebeu false. Os dois conceitos precisam vir separados.
   //---
   //--- Aditivo: o painel 1.058 nao le este campo.
   bool   hasOpenPosition;
   string activeProfileName;
   bool   activeProfileFileMissing;
   string symbol;
   string timeframe;
   SSymbolSpec symbolSpec;
   int    magicNumber;
   int    activeStrategies;
   int    activeFilters;
   ENUM_CONFLICT_RESOLUTION conflictMode;
   double fixedLot;
   int    maxSpreadPoints;
   string ownerStrategyName;
   bool   useMACross;
   bool   useRSI;
   bool   useBollinger;
   bool   useTrendFilter;
   bool   useRSIFilter;
   bool   bbFilterEnabled;
   bool   runtimeBlocked;
   string runtimeBlockReason;
   string startBlockedReason;
   string activeProfileBlockedReason;
   string runtimeNotice;
   string entryBlockReason;
   bool   entryBlockIsRiskStops;
   string entryBlockDetail;
   bool   pendingReverseExit;
   bool   tradePermissionBlocked;
   string tradePermissionReason;
   int    dailyTradeCount;
   int    dailyLossCount;
   int    dailyWinCount;
   int    dailyBreakevenCount;
   bool   dailyOutcomeCountsKnown;
   double dailyClosedProfit;
   double dailyFloatingProfit;
   double dailyProjectedProfit;
   bool   partialReconciliationPending;
   bool   dailyLimitsBlocked;
   string dailyLimitsBlockReason;
   bool   sessionProtectionBlocked;
   string sessionProtectionBlockReason;
   bool   newsProtectionBlocked;
   string newsProtectionBlockReason;
   int    lossStreak;
   int    winStreak;
   bool   streakProtectionBlocked;
   string streakProtectionBlockReason;
   bool   drawdownProtectionActive;
   bool   drawdownLimitReached;
   bool   drawdownConfigLocked;
   string drawdownConfigLockReason;
   double drawdownPeakProfit;
   double drawdownFloorProfit;
   double drawdownBufferProfit;
   double drawdownTriggerProfit;
   double drawdownTriggerDrawdown;
   double drawdownTriggerBuffer;
  };

struct SUICommand
  {
   ENUM_UI_COMMAND type;
   string          text;
   bool            hasSettings;
   ENUM_RELOAD_SCOPE reloadScope;
   SEASettings     settings;
  };

string SignalToString(ENUM_SIGNAL_TYPE signal)
  {
   switch(signal)
     {
      case SIGNAL_BUY:
         return "BUY";
      case SIGNAL_SELL:
         return "SELL";
      default:
         return "NONE";
     }
  }

void SetDefaultSettings(SEASettings &settings)
  {
   settings.schemaVersion         = FUSION_SETTINGS_SCHEMA_VERSION;
   settings.panelEnabled          = true;
   settings.defaultProfileName    = "default";
   settings.magicNumber           = 10001;
   settings.slippagePoints        = 20;
   settings.debugLogs             = false;
   settings.showChartIndicators   = false;
   settings.visualMAFastColor      = clrLime;
   settings.visualMASlowColor      = clrRed;
   settings.visualMATrendColor     = clrMagenta;
   settings.visualMATrend2Color    = clrOrange;
   settings.visualBBColor          = clrDodgerBlue;
   settings.visualMAFastStyle      = STYLE_SOLID;
   settings.visualMASlowStyle      = STYLE_SOLID;
   settings.visualMATrendStyle     = STYLE_SOLID;
   settings.visualMATrend2Style    = STYLE_SOLID;
   settings.visualBBStyle          = STYLE_SOLID;
   settings.conflictMode          = CONFLICT_PRIORITY;
   settings.tradeDirection        = DIRECTION_BOTH;
   settings.enableSpreadProtection= false;
   settings.maxSpreadPoints       = 0;
   settings.enableSessionFilter   = false;
   settings.sessionStartHour      = 0;
   settings.sessionStartMinute    = 0;
   settings.sessionEndHour        = 23;
   settings.sessionEndMinute      = 59;
   settings.sessionOvernight      = false;
   settings.closeOnSessionEnd     = false;
   for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
     {
      settings.newsWindows[newsIndex].enabled = false;
      settings.newsWindows[newsIndex].startHour = 0;
      settings.newsWindows[newsIndex].startMinute = 0;
      settings.newsWindows[newsIndex].endHour = 0;
      settings.newsWindows[newsIndex].endMinute = 0;
      settings.newsWindows[newsIndex].action = NEWS_ACTION_BLOCK_ENTRIES;
     }
   settings.enableDailyLimits     = false;
   settings.maxDailyTrades        = 0;
   settings.maxDailyLoss          = 0.0;
   settings.maxDailyGain          = 0.0;
   settings.profitTargetAction    = PROFIT_ACTION_PARAR;
   settings.enableDrawdown        = false;
   settings.maxDrawdown           = 0.0;
   settings.drawdownType          = DD_TIPO_FINANCEIRO;
   settings.drawdownPeakMode      = DD_PICO_FLUTUANTE;
   settings.lossStreakEnabled     = false;
   settings.maxLossStreak         = 0;
   settings.lossStreakAction      = STREAK_ACTION_PAUSE;
   settings.lossStreakPauseMinutes= 30;
   settings.winStreakEnabled      = false;
   settings.maxWinStreak          = 0;
   settings.winStreakAction       = STREAK_ACTION_STOP_DAY;
   settings.winStreakPauseMinutes = 30;
   settings.fixedLot              = 0.10;
   settings.fixedSLPoints         = 200;
   settings.fixedTPPoints         = 400;
   settings.compensateSLSpread    = false;
   settings.compensateTPSpread    = false;
   settings.usePartialTP          = false;
   settings.freeFinalTP           = false;
   settings.tp1.enabled           = false;
   settings.tp1.percent           = 50.0;
   settings.tp1.distancePoints    = 150;
   settings.tp2.enabled           = false;
   settings.tp2.percent           = 25.0;
   settings.tp2.distancePoints    = 300;
   settings.useTrailing           = false;
   settings.trailingStartPoints   = 150;
   settings.trailingStepPoints    = 80;
   settings.useBreakeven          = false;
   settings.breakevenTriggerPoints= 120;
   settings.breakevenOffsetPoints = 10;
   settings.useMACross            = true;
   settings.maCrossPriority       = 10;
   settings.maFastPeriod          = 9;
   settings.maSlowPeriod          = 21;
   settings.maMinDistancePoints   = 0;
   settings.maFastTimeframe       = FUSION_DEFAULT_TIMEFRAME;
   settings.maSlowTimeframe       = FUSION_DEFAULT_TIMEFRAME;
   settings.maFastMethod          = MODE_EMA;
   settings.maSlowMethod          = MODE_EMA;
   settings.maFastPrice           = PRICE_CLOSE;
   settings.maSlowPrice           = PRICE_CLOSE;
   settings.maEntryMode           = ENTRY_NEXT_CANDLE;
   settings.maExitMode            = EXIT_OPPOSITE_SIGNAL;
   settings.useRSI                = false;
   settings.rsiPriority           = 8;
   settings.rsiPeriod             = 14;
   settings.rsiTimeframe          = FUSION_DEFAULT_TIMEFRAME;
   settings.rsiOversold           = 30;
   settings.rsiOverbought         = 70;
   settings.rsiMiddle             = 50;
   settings.rsiMode               = RSI_SIGNAL_CROSSOVER;
   settings.rsiPrice              = PRICE_CLOSE;
   settings.rsiExitMode           = RSI_EXIT_OPPOSITE_SIGNAL;
   settings.useBollinger          = false;
   settings.bbPriority            = 6;
   settings.bbPeriod              = 20;
   settings.bbTimeframe           = FUSION_DEFAULT_TIMEFRAME;
   settings.bbDeviation           = 2.0;
   settings.bbPrice               = PRICE_CLOSE;
   settings.bbMode                = BB_SIGNAL_REENTRY;
   settings.bbExitMode            = EXIT_OPPOSITE_SIGNAL;
   settings.useTrendFilter        = false;
   settings.trendMA1Enabled       = false;
   settings.trendMAPeriod         = 50;
   settings.trendMATimeframe      = FUSION_DEFAULT_TIMEFRAME;
   settings.trendMAMethod         = MODE_SMA;
   settings.trendMAPrice          = PRICE_CLOSE;
   settings.trendMA2Enabled       = false;
   settings.trendSellMAPeriod     = 21;
   settings.trendSellMATimeframe  = FUSION_DEFAULT_TIMEFRAME;
   settings.trendSellMAMethod     = MODE_SMA;
   settings.trendSellMAPrice      = PRICE_CLOSE;
   settings.useRSIFilter          = false;
   settings.rsiFilterMode         = RSI_FILTER_DIRECTION;
   settings.rsiFilterPeriod       = 14;
   settings.rsiFilterTimeframe    = FUSION_DEFAULT_TIMEFRAME;
   settings.rsiFilterBuyMin       = 50;
   settings.rsiFilterSellMax      = 50;
   settings.rsiFilterPrice        = PRICE_CLOSE;
   settings.bbFilterEnabled       = false;
   settings.bbFilterMode          = BB_FILTER_WIDTH_ABSOLUTE;
   settings.bbFilterPeriod        = 20;
   settings.bbFilterTimeframe     = FUSION_DEFAULT_TIMEFRAME;
   settings.bbFilterDeviation     = 2.0;
   settings.bbFilterPrice         = PRICE_CLOSE;
   settings.bbFilterMinWidthPoints = 100;
   settings.bbFilterMinWidthPercent = 0.20;
   settings.bbFilterSlopeDirectionEnabled = false;
   settings.bbFilterSlopeLookback = 3;
   settings.bbFilterMinSlopePoints = 0;
   settings.isTester              = false;
  }

ENUM_TIMEFRAMES ResolveOperationalTimeframe(const ENUM_TIMEFRAMES configured,const ENUM_TIMEFRAMES fallbackTimeframe)
  {
   if((int)configured > 0)
      return configured;
   if((int)fallbackTimeframe > 0)
      return fallbackTimeframe;
   return FUSION_DEFAULT_TIMEFRAME;
  }

void ResolveOperationalTimeframes(SEASettings &settings,const ENUM_TIMEFRAMES fallbackTimeframe)
  {
   settings.maFastTimeframe    = ResolveOperationalTimeframe(settings.maFastTimeframe, fallbackTimeframe);
   settings.maSlowTimeframe    = ResolveOperationalTimeframe(settings.maSlowTimeframe, fallbackTimeframe);
   settings.rsiTimeframe       = ResolveOperationalTimeframe(settings.rsiTimeframe, fallbackTimeframe);
   settings.bbTimeframe        = ResolveOperationalTimeframe(settings.bbTimeframe, fallbackTimeframe);
   settings.trendMATimeframe   = ResolveOperationalTimeframe(settings.trendMATimeframe, fallbackTimeframe);
   settings.trendSellMATimeframe = ResolveOperationalTimeframe(settings.trendSellMATimeframe, fallbackTimeframe);
   settings.rsiFilterTimeframe = ResolveOperationalTimeframe(settings.rsiFilterTimeframe, fallbackTimeframe);
   settings.bbFilterTimeframe  = ResolveOperationalTimeframe(settings.bbFilterTimeframe, fallbackTimeframe);
  }

void ResetSignalDecision(SSignalDecision &decision)
  {
   decision.signal       = SIGNAL_NONE;
   decision.strategyId   = "";
   decision.strategyName = "";
   decision.shortName    = "";
   decision.blockedBy    = "";
  }

void ResetPositionRuntimeState(SPositionRuntimeState &state)
  {
   state.hasPosition          = false;
   state.ticket               = 0;
   state.positionId           = 0;
   state.type                 = POSITION_TYPE_BUY;
   state.symbol               = "";
   state.entryPrice           = 0.0;
   state.volume               = 0.0;
   state.stopLoss             = 0.0;
   state.takeProfit           = 0.0;
   state.ownerStrategyId      = "";
   state.ownerStrategyName    = "";
   state.tp1Executed          = false;
   state.tp2Executed          = false;
   state.breakevenActive      = false;
   state.trailingActive       = false;
   state.realizedPartialProfit= 0.0;
   state.tp1Price             = 0.0;
   state.tp1Volume            = 0.0;
   state.tp2Price             = 0.0;
   state.tp2Volume            = 0.0;
   state.partialClosePending  = false;
   state.pendingPartialLevel  = PARTIAL_CLOSE_NONE;
   state.pendingPartialInitialVolume = 0.0;
   state.pendingPartialRequestedVolume = 0.0;
   state.pendingPartialBaselineExitVolume = 0.0;
   state.pendingPartialPreProjectedProfit = 0.0;
   state.pendingPartialFloatingReferenceSet = false;
   state.pendingPartialFloatingReference = 0.0;
   state.pendingPartialOrderTicket = 0;
   state.pendingPartialDealTicket = 0;
   state.pendingPartialRetcode = 0;
   state.pendingPartialSince = 0;
   state.dayPeakProjectedProfit = 0.0;
  }

void ResetStreakRuntimeState(SStreakRuntimeState &state)
  {
   state.dayKey = 0;
   state.lossStreak = 0;
   state.winStreak = 0;
   state.lossStopDayBlocked = false;
   state.winStopDayBlocked = false;
   state.lossPauseUntil = 0;
   state.winPauseUntil = 0;
  }

void ResetDailyLimitsRuntimeState(SDailyLimitsRuntimeState &state)
  {
   state.dayKey = 0;
   state.dailyTradeCount = 0;
   state.dailyLossCount = 0;
   state.dailyWinCount = 0;
   state.dailyBreakevenCount = 0;
   state.outcomeCountsKnown = false;
   state.dailyClosedProfit = 0.0;
   state.tradesLimitReached = false;
   state.lossLimitReached = false;
   state.gainLimitReached = false;
  }

void ResetDrawdownRuntimeState(SDrawdownRuntimeState &state)
  {
   state.dayKey = 0;
   state.protectionActive = false;
   state.limitReached = false;
   state.peakProjectedProfit = 0.0;
   state.triggerProjectedProfit = 0.0;
   state.triggerDrawdownAmount = 0.0;
   state.triggerBufferProfit = 0.0;
  }

#endif
