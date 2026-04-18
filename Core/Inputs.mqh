#ifndef __MODULAR_EA_INPUTS_MQH__
#define __MODULAR_EA_INPUTS_MQH__

#include "Types.mqh"

input group "General"
input int    inp_MagicNumber               = 10001;
input int    inp_SlippagePoints            = 20;
input bool   inp_EnableDebugLogs           = false;

input group "Panel"
input bool   inp_ShowPanel                 = true;
input string inp_DefaultProfileName        = "default";
input bool   inp_AutoRestoreChartState     = true;
input bool   inp_AutoSaveChartState        = true;

input group "Signal Engine"
input ENUM_CONFLICT_RESOLUTION inp_ConflictMode = CONFLICT_PRIORITY;
input ENUM_TRADE_DIRECTION     inp_TradeDirection = DIRECTION_BOTH;

input group "Protection"
input int    inp_MaxSpreadPoints           = 0;
input bool   inp_EnableSessionFilter       = false;
input int    inp_SessionStartHour          = 9;
input int    inp_SessionStartMinute        = 0;
input int    inp_SessionEndHour            = 17;
input int    inp_SessionEndMinute          = 0;
input bool   inp_CloseOnSessionEnd         = false;
input bool   inp_EnableDailyLimits         = false;
input int    inp_MaxDailyTrades            = 0;
input double inp_MaxDailyLoss              = 0.0;
input double inp_MaxDailyGain              = 0.0;
input bool   inp_EnableDrawdown            = false;
input double inp_MaxDrawdown               = 0.0;
input bool   inp_EnableStreak              = false;
input int    inp_MaxLossStreak             = 0;
input int    inp_MaxWinStreak              = 0;

input group "Risk"
input double inp_FixedLot                  = 0.10;
input int    inp_FixedSLPoints             = 200;
input int    inp_FixedTPPoints             = 400;
input bool   inp_UsePartialTP              = false;
input bool   inp_EnableTP1                 = false;
input double inp_TP1Percent                = 50.0;
input int    inp_TP1DistancePoints         = 150;
input bool   inp_EnableTP2                 = false;
input double inp_TP2Percent                = 25.0;
input int    inp_TP2DistancePoints         = 300;
input bool   inp_UseTrailing               = false;
input int    inp_TrailingStartPoints       = 150;
input int    inp_TrailingStepPoints        = 80;
input bool   inp_UseBreakeven              = false;
input int    inp_BreakevenTriggerPoints    = 120;
input int    inp_BreakevenOffsetPoints     = 10;

input group "Strategy - MA Cross"
input bool               inp_UseMACross    = true;
input int                inp_MACrossPriority = 10;
input int                inp_MAFastPeriod  = 9;
input int                inp_MASlowPeriod  = 21;
input ENUM_MA_METHOD     inp_MAMethod      = MODE_EMA;
input ENUM_APPLIED_PRICE inp_MAPrice       = PRICE_CLOSE;
input ENUM_EXIT_MODE     inp_MAExitMode    = EXIT_OPPOSITE_SIGNAL;

input group "Strategy - RSI"
input bool                   inp_UseRSI    = false;
input int                    inp_RSIPriority = 8;
input int                    inp_RSIPeriod = 14;
input int                    inp_RSIOversold = 30;
input int                    inp_RSIOverbought = 70;
input int                    inp_RSIMiddle = 50;
input ENUM_RSI_SIGNAL_MODE   inp_RSIMode   = RSI_SIGNAL_CROSSOVER;
input ENUM_APPLIED_PRICE     inp_RSIPrice  = PRICE_CLOSE;
input ENUM_EXIT_MODE         inp_RSIExitMode = EXIT_OPPOSITE_SIGNAL;

input group "Strategy - Bollinger"
input bool                   inp_UseBollinger = false;
input int                    inp_BollingerPriority = 6;
input int                    inp_BollingerPeriod = 20;
input double                 inp_BollingerDeviation = 2.0;
input ENUM_APPLIED_PRICE     inp_BollingerPrice = PRICE_CLOSE;
input ENUM_BB_SIGNAL_MODE    inp_BollingerMode = BB_SIGNAL_REENTRY;
input ENUM_EXIT_MODE         inp_BollingerExitMode = EXIT_OPPOSITE_SIGNAL;

input group "Filter - Trend"
input bool               inp_UseTrendFilter = false;
input int                inp_TrendMAPeriod  = 50;
input ENUM_MA_METHOD     inp_TrendMAMethod  = MODE_SMA;
input ENUM_APPLIED_PRICE inp_TrendMAPrice   = PRICE_CLOSE;

input group "Filter - RSI"
input bool               inp_UseRSIFilter   = false;
input int                inp_RSIFilterPeriod = 14;
input int                inp_RSIFilterBuyMin = 50;
input int                inp_RSIFilterSellMax = 50;
input ENUM_APPLIED_PRICE inp_RSIFilterPrice = PRICE_CLOSE;

void FillSettingsFromInputs(SEASettings &settings)
  {
   SetDefaultSettings(settings);

   settings.magicNumber            = inp_MagicNumber;
   settings.slippagePoints         = inp_SlippagePoints;
   settings.debugLogs              = inp_EnableDebugLogs;
   settings.panelEnabled           = inp_ShowPanel;
   settings.defaultProfileName     = inp_DefaultProfileName;
   settings.autoRestoreChartState  = inp_AutoRestoreChartState;
   settings.autoSaveChartState     = inp_AutoSaveChartState;
   settings.conflictMode           = inp_ConflictMode;
   settings.tradeDirection         = inp_TradeDirection;
   settings.maxSpreadPoints        = inp_MaxSpreadPoints;
   settings.enableSessionFilter    = inp_EnableSessionFilter;
   settings.sessionStartHour       = inp_SessionStartHour;
   settings.sessionStartMinute     = inp_SessionStartMinute;
   settings.sessionEndHour         = inp_SessionEndHour;
   settings.sessionEndMinute       = inp_SessionEndMinute;
   settings.closeOnSessionEnd      = inp_CloseOnSessionEnd;
   settings.enableDailyLimits      = inp_EnableDailyLimits;
   settings.maxDailyTrades         = inp_MaxDailyTrades;
   settings.maxDailyLoss           = inp_MaxDailyLoss;
   settings.maxDailyGain           = inp_MaxDailyGain;
   settings.enableDrawdown         = inp_EnableDrawdown;
   settings.maxDrawdown            = inp_MaxDrawdown;
   settings.enableStreak           = inp_EnableStreak;
   settings.maxLossStreak          = inp_MaxLossStreak;
   settings.maxWinStreak           = inp_MaxWinStreak;
   settings.fixedLot               = inp_FixedLot;
   settings.fixedSLPoints          = inp_FixedSLPoints;
   settings.fixedTPPoints          = inp_FixedTPPoints;
   settings.usePartialTP           = inp_UsePartialTP;
   settings.tp1.enabled            = inp_EnableTP1;
   settings.tp1.percent            = inp_TP1Percent;
   settings.tp1.distancePoints     = inp_TP1DistancePoints;
   settings.tp2.enabled            = inp_EnableTP2;
   settings.tp2.percent            = inp_TP2Percent;
   settings.tp2.distancePoints     = inp_TP2DistancePoints;
   settings.useTrailing            = inp_UseTrailing;
   settings.trailingStartPoints    = inp_TrailingStartPoints;
   settings.trailingStepPoints     = inp_TrailingStepPoints;
   settings.useBreakeven           = inp_UseBreakeven;
   settings.breakevenTriggerPoints = inp_BreakevenTriggerPoints;
   settings.breakevenOffsetPoints  = inp_BreakevenOffsetPoints;
   settings.useMACross             = inp_UseMACross;
   settings.maCrossPriority        = inp_MACrossPriority;
   settings.maFastPeriod           = inp_MAFastPeriod;
   settings.maSlowPeriod           = inp_MASlowPeriod;
   settings.maMethod               = inp_MAMethod;
   settings.maPrice                = inp_MAPrice;
   settings.maExitMode             = inp_MAExitMode;
   settings.useRSI                 = inp_UseRSI;
   settings.rsiPriority            = inp_RSIPriority;
   settings.rsiPeriod              = inp_RSIPeriod;
   settings.rsiOversold            = inp_RSIOversold;
   settings.rsiOverbought          = inp_RSIOverbought;
   settings.rsiMiddle              = inp_RSIMiddle;
   settings.rsiMode                = inp_RSIMode;
   settings.rsiPrice               = inp_RSIPrice;
   settings.rsiExitMode            = inp_RSIExitMode;
   settings.useBollinger           = inp_UseBollinger;
   settings.bbPriority             = inp_BollingerPriority;
   settings.bbPeriod               = inp_BollingerPeriod;
   settings.bbDeviation            = inp_BollingerDeviation;
   settings.bbPrice                = inp_BollingerPrice;
   settings.bbMode                 = inp_BollingerMode;
   settings.bbExitMode             = inp_BollingerExitMode;
   settings.useTrendFilter         = inp_UseTrendFilter;
   settings.trendMAPeriod          = inp_TrendMAPeriod;
   settings.trendMAMethod          = inp_TrendMAMethod;
   settings.trendMAPrice           = inp_TrendMAPrice;
   settings.useRSIFilter           = inp_UseRSIFilter;
   settings.rsiFilterPeriod        = inp_RSIFilterPeriod;
   settings.rsiFilterBuyMin        = inp_RSIFilterBuyMin;
   settings.rsiFilterSellMax       = inp_RSIFilterSellMax;
   settings.rsiFilterPrice         = inp_RSIFilterPrice;
  }

#endif

