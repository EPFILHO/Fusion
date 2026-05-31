#ifndef __FUSION_TYPES_MQH__
#define __FUSION_TYPES_MQH__

#define FUSION_DEFAULT_TIMEFRAME PERIOD_M15
#define FUSION_NEWS_WINDOW_COUNT 3

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
   UI_COMMAND_TOGGLE_TREND_FILTER,
   UI_COMMAND_TOGGLE_RSI_FILTER,
   UI_COMMAND_TOGGLE_BB_FILTER,
   UI_COMMAND_SAVE_PROFILE,
   UI_COMMAND_LOAD_PROFILE
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
   bool                     autoRestoreChartState;
   bool                     autoSaveChartState;
   string                   defaultProfileName;
   int                      magicNumber;
   int                      slippagePoints;
   bool                     debugLogs;
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
   int                      trendMAPeriod;
   ENUM_TIMEFRAMES          trendMATimeframe;
   ENUM_MA_METHOD           trendMAMethod;
   ENUM_APPLIED_PRICE       trendMAPrice;
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
   bool                     isTester;
  };

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
  };

struct SClosedTradeSummary
  {
   bool   found;
   double totalProfit;
   double finalProfit;
   int    exitDeals;
  };

struct SChartStateContext
  {
   ulong  chartId;
   string symbol;
   string timeframe;
   int    periodValue;
   int    deinitReason;
  };

struct SUIPanelSnapshot
  {
   SEASettings settings;
   bool   started;
   bool   hasPosition;
   string activeProfileName;
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
   bool   pendingReverseExit;
   bool   tradePermissionBlocked;
   string tradePermissionReason;
   int    dailyTradeCount;
   double dailyClosedProfit;
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
   settings.schemaVersion         = 12;
   settings.panelEnabled          = true;
   settings.autoRestoreChartState = true;
   settings.autoSaveChartState    = true;
   settings.defaultProfileName    = "default";
   settings.magicNumber           = 10001;
   settings.slippagePoints        = 20;
   settings.debugLogs             = false;
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
   settings.trendMAPeriod         = 50;
   settings.trendMATimeframe      = FUSION_DEFAULT_TIMEFRAME;
   settings.trendMAMethod         = MODE_SMA;
   settings.trendMAPrice          = PRICE_CLOSE;
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
  }

#endif
