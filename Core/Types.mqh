#ifndef __FUSION_TYPES_MQH__
#define __FUSION_TYPES_MQH__

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
   EXIT_OPPOSITE_SIGNAL
  };

enum ENUM_RSI_SIGNAL_MODE
  {
   RSI_SIGNAL_CROSSOVER = 0,
   RSI_SIGNAL_ZONE,
   RSI_SIGNAL_MIDDLE
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

enum ENUM_UI_COMMAND
  {
   UI_COMMAND_NONE = 0,
   UI_COMMAND_TOGGLE_RUNNING,
   UI_COMMAND_TOGGLE_MACROSS,
   UI_COMMAND_TOGGLE_RSI,
   UI_COMMAND_TOGGLE_BB,
   UI_COMMAND_TOGGLE_TREND_FILTER,
   UI_COMMAND_TOGGLE_RSI_FILTER,
   UI_COMMAND_SAVE_PROFILE,
   UI_COMMAND_LOAD_PROFILE
  };

struct SPartialTPConfig
  {
   bool   enabled;
   double percent;
   int    distancePoints;
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
   int                      maxSpreadPoints;
   bool                     enableSessionFilter;
   int                      sessionStartHour;
   int                      sessionStartMinute;
   int                      sessionEndHour;
   int                      sessionEndMinute;
   bool                     closeOnSessionEnd;
   bool                     enableDailyLimits;
   int                      maxDailyTrades;
   double                   maxDailyLoss;
   double                   maxDailyGain;
   bool                     enableDrawdown;
   double                   maxDrawdown;
   bool                     enableStreak;
   int                      maxLossStreak;
   int                      maxWinStreak;
   double                   fixedLot;
   int                      fixedSLPoints;
   int                      fixedTPPoints;
   bool                     usePartialTP;
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
   ENUM_MA_METHOD           maMethod;
   ENUM_APPLIED_PRICE       maPrice;
   ENUM_EXIT_MODE           maExitMode;
   bool                     useRSI;
   int                      rsiPriority;
   int                      rsiPeriod;
   int                      rsiOversold;
   int                      rsiOverbought;
   int                      rsiMiddle;
   ENUM_RSI_SIGNAL_MODE     rsiMode;
   ENUM_APPLIED_PRICE       rsiPrice;
   ENUM_EXIT_MODE           rsiExitMode;
   bool                     useBollinger;
   int                      bbPriority;
   int                      bbPeriod;
   double                   bbDeviation;
   ENUM_APPLIED_PRICE       bbPrice;
   ENUM_BB_SIGNAL_MODE      bbMode;
   ENUM_EXIT_MODE           bbExitMode;
   bool                     useTrendFilter;
   int                      trendMAPeriod;
   ENUM_MA_METHOD           trendMAMethod;
   ENUM_APPLIED_PRICE       trendMAPrice;
   bool                     useRSIFilter;
   int                      rsiFilterPeriod;
   int                      rsiFilterBuyMin;
   int                      rsiFilterSellMax;
   ENUM_APPLIED_PRICE       rsiFilterPrice;
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
  };

struct SUIPanelSnapshot
  {
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
   bool   runtimeBlocked;
   string runtimeBlockReason;
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
   settings.schemaVersion         = 1;
   settings.panelEnabled          = true;
   settings.autoRestoreChartState = true;
   settings.autoSaveChartState    = true;
   settings.defaultProfileName    = "default";
   settings.magicNumber           = 10001;
   settings.slippagePoints        = 20;
   settings.debugLogs             = false;
   settings.conflictMode          = CONFLICT_PRIORITY;
   settings.tradeDirection        = DIRECTION_BOTH;
   settings.maxSpreadPoints       = 0;
   settings.enableSessionFilter   = false;
   settings.sessionStartHour      = 0;
   settings.sessionStartMinute    = 0;
   settings.sessionEndHour        = 23;
   settings.sessionEndMinute      = 59;
   settings.closeOnSessionEnd     = false;
   settings.enableDailyLimits     = false;
   settings.maxDailyTrades        = 0;
   settings.maxDailyLoss          = 0.0;
   settings.maxDailyGain          = 0.0;
   settings.enableDrawdown        = false;
   settings.maxDrawdown           = 0.0;
   settings.enableStreak          = false;
   settings.maxLossStreak         = 0;
   settings.maxWinStreak          = 0;
   settings.fixedLot              = 0.10;
   settings.fixedSLPoints         = 200;
   settings.fixedTPPoints         = 400;
   settings.usePartialTP          = false;
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
   settings.maMethod              = MODE_EMA;
   settings.maPrice               = PRICE_CLOSE;
   settings.maExitMode            = EXIT_OPPOSITE_SIGNAL;
   settings.useRSI                = false;
   settings.rsiPriority           = 8;
   settings.rsiPeriod             = 14;
   settings.rsiOversold           = 30;
   settings.rsiOverbought         = 70;
   settings.rsiMiddle             = 50;
   settings.rsiMode               = RSI_SIGNAL_CROSSOVER;
   settings.rsiPrice              = PRICE_CLOSE;
   settings.rsiExitMode           = EXIT_OPPOSITE_SIGNAL;
   settings.useBollinger          = false;
   settings.bbPriority            = 6;
   settings.bbPeriod              = 20;
   settings.bbDeviation           = 2.0;
   settings.bbPrice               = PRICE_CLOSE;
   settings.bbMode                = BB_SIGNAL_REENTRY;
   settings.bbExitMode            = EXIT_OPPOSITE_SIGNAL;
   settings.useTrendFilter        = false;
   settings.trendMAPeriod         = 50;
   settings.trendMAMethod         = MODE_SMA;
   settings.trendMAPrice          = PRICE_CLOSE;
   settings.useRSIFilter          = false;
   settings.rsiFilterPeriod       = 14;
   settings.rsiFilterBuyMin       = 50;
   settings.rsiFilterSellMax      = 50;
   settings.rsiFilterPrice        = PRICE_CLOSE;
   settings.isTester              = false;
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

#endif
