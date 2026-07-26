#ifndef __FUSION_SETTINGS_STORE_MQH__
#define __FUSION_SETTINGS_STORE_MQH__

#include "../Core/Types.mqh"
#include "../Core/ProfileNameUtils.mqh"
#include "Modules/SettingsFileUtils.mqh"

class CSettingsStore
  {
private:
   bool              SaveSettingsBlock(const int handle,const SEASettings &settings) const
     {
      bool ok = true;
      ok = FusionSettingsWriteLine(handle, "schemaVersion", IntegerToString(FUSION_SETTINGS_SCHEMA_VERSION)) && ok;
      ok = FusionSettingsWriteLine(handle, "panelEnabled", IntegerToString((int)settings.panelEnabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "defaultProfileName", settings.defaultProfileName) && ok;
      ok = FusionSettingsWriteLine(handle, "magicNumber", IntegerToString(settings.magicNumber)) && ok;
      ok = FusionSettingsWriteLine(handle, "slippagePoints", IntegerToString(settings.slippagePoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "debugLogs", IntegerToString((int)settings.debugLogs)) && ok;
      ok = FusionSettingsWriteLine(handle, "showChartIndicators", IntegerToString((int)settings.showChartIndicators)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMAFastColor", IntegerToString((int)settings.visualMAFastColor)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMASlowColor", IntegerToString((int)settings.visualMASlowColor)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMATrendColor", IntegerToString((int)settings.visualMATrendColor)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMATrend2Color", IntegerToString((int)settings.visualMATrend2Color)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualBBColor", IntegerToString((int)settings.visualBBColor)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMAFastStyle", IntegerToString((int)settings.visualMAFastStyle)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMASlowStyle", IntegerToString((int)settings.visualMASlowStyle)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMATrendStyle", IntegerToString((int)settings.visualMATrendStyle)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualMATrend2Style", IntegerToString((int)settings.visualMATrend2Style)) && ok;
      ok = FusionSettingsWriteLine(handle, "visualBBStyle", IntegerToString((int)settings.visualBBStyle)) && ok;
      ok = FusionSettingsWriteLine(handle, "conflictMode", IntegerToString((int)settings.conflictMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "tradeDirection", IntegerToString((int)settings.tradeDirection)) && ok;
      ok = FusionSettingsWriteLine(handle, "enableSpreadProtection", IntegerToString((int)settings.enableSpreadProtection)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxSpreadPoints", IntegerToString(settings.maxSpreadPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "enableSessionFilter", IntegerToString((int)settings.enableSessionFilter)) && ok;
      ok = FusionSettingsWriteLine(handle, "sessionStartHour", IntegerToString(settings.sessionStartHour)) && ok;
      ok = FusionSettingsWriteLine(handle, "sessionStartMinute", IntegerToString(settings.sessionStartMinute)) && ok;
      ok = FusionSettingsWriteLine(handle, "sessionEndHour", IntegerToString(settings.sessionEndHour)) && ok;
      ok = FusionSettingsWriteLine(handle, "sessionEndMinute", IntegerToString(settings.sessionEndMinute)) && ok;
      ok = FusionSettingsWriteLine(handle, "sessionOvernight", IntegerToString((int)settings.sessionOvernight)) && ok;
      ok = FusionSettingsWriteLine(handle, "closeOnSessionEnd", IntegerToString((int)settings.closeOnSessionEnd)) && ok;
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         string prefix = "news" + IntegerToString(newsIndex + 1) + ".";
         ok = FusionSettingsWriteLine(handle, prefix + "enabled", IntegerToString((int)settings.newsWindows[newsIndex].enabled)) && ok;
         ok = FusionSettingsWriteLine(handle, prefix + "startHour", IntegerToString(settings.newsWindows[newsIndex].startHour)) && ok;
         ok = FusionSettingsWriteLine(handle, prefix + "startMinute", IntegerToString(settings.newsWindows[newsIndex].startMinute)) && ok;
         ok = FusionSettingsWriteLine(handle, prefix + "endHour", IntegerToString(settings.newsWindows[newsIndex].endHour)) && ok;
         ok = FusionSettingsWriteLine(handle, prefix + "endMinute", IntegerToString(settings.newsWindows[newsIndex].endMinute)) && ok;
         ok = FusionSettingsWriteLine(handle, prefix + "action", IntegerToString((int)settings.newsWindows[newsIndex].action)) && ok;
        }
      ok = FusionSettingsWriteLine(handle, "enableDailyLimits", IntegerToString((int)settings.enableDailyLimits)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxDailyTrades", IntegerToString(settings.maxDailyTrades)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxDailyLoss", DoubleToString(settings.maxDailyLoss, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxDailyGain", DoubleToString(settings.maxDailyGain, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "profitTargetAction", IntegerToString((int)settings.profitTargetAction)) && ok;
      ok = FusionSettingsWriteLine(handle, "enableDrawdown", IntegerToString((int)settings.enableDrawdown)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxDrawdown", DoubleToString(settings.maxDrawdown, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdownType", IntegerToString((int)settings.drawdownType)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdownPeakMode", IntegerToString((int)settings.drawdownPeakMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "lossStreakEnabled", IntegerToString((int)settings.lossStreakEnabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxLossStreak", IntegerToString(settings.maxLossStreak)) && ok;
      ok = FusionSettingsWriteLine(handle, "lossStreakAction", IntegerToString((int)settings.lossStreakAction)) && ok;
      ok = FusionSettingsWriteLine(handle, "lossStreakPauseMinutes", IntegerToString(settings.lossStreakPauseMinutes)) && ok;
      ok = FusionSettingsWriteLine(handle, "winStreakEnabled", IntegerToString((int)settings.winStreakEnabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "maxWinStreak", IntegerToString(settings.maxWinStreak)) && ok;
      ok = FusionSettingsWriteLine(handle, "winStreakAction", IntegerToString((int)settings.winStreakAction)) && ok;
      ok = FusionSettingsWriteLine(handle, "winStreakPauseMinutes", IntegerToString(settings.winStreakPauseMinutes)) && ok;
      ok = FusionSettingsWriteLine(handle, "fixedLot", DoubleToString(settings.fixedLot, 4)) && ok;
      ok = FusionSettingsWriteLine(handle, "fixedSLPoints", IntegerToString(settings.fixedSLPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "fixedTPPoints", IntegerToString(settings.fixedTPPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "compensateSLSpread", IntegerToString((int)settings.compensateSLSpread)) && ok;
      ok = FusionSettingsWriteLine(handle, "compensateTPSpread", IntegerToString((int)settings.compensateTPSpread)) && ok;
      ok = FusionSettingsWriteLine(handle, "usePartialTP", IntegerToString((int)settings.usePartialTP)) && ok;
      ok = FusionSettingsWriteLine(handle, "freeFinalTP", IntegerToString((int)settings.freeFinalTP)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp1.enabled", IntegerToString((int)settings.tp1.enabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp1.percent", DoubleToString(settings.tp1.percent, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp1.distancePoints", IntegerToString(settings.tp1.distancePoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp2.enabled", IntegerToString((int)settings.tp2.enabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp2.percent", DoubleToString(settings.tp2.percent, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "tp2.distancePoints", IntegerToString(settings.tp2.distancePoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "useTrailing", IntegerToString((int)settings.useTrailing)) && ok;
      ok = FusionSettingsWriteLine(handle, "trailingStartPoints", IntegerToString(settings.trailingStartPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "trailingStepPoints", IntegerToString(settings.trailingStepPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "useBreakeven", IntegerToString((int)settings.useBreakeven)) && ok;
      ok = FusionSettingsWriteLine(handle, "breakevenTriggerPoints", IntegerToString(settings.breakevenTriggerPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "breakevenOffsetPoints", IntegerToString(settings.breakevenOffsetPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "useMACross", IntegerToString((int)settings.useMACross)) && ok;
      ok = FusionSettingsWriteLine(handle, "maCrossPriority", IntegerToString(settings.maCrossPriority)) && ok;
      ok = FusionSettingsWriteLine(handle, "maFastPeriod", IntegerToString(settings.maFastPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "maSlowPeriod", IntegerToString(settings.maSlowPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "maMinDistancePoints", IntegerToString(settings.maMinDistancePoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "maFastTimeframe", IntegerToString((int)settings.maFastTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "maSlowTimeframe", IntegerToString((int)settings.maSlowTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "maFastMethod", IntegerToString((int)settings.maFastMethod)) && ok;
      ok = FusionSettingsWriteLine(handle, "maSlowMethod", IntegerToString((int)settings.maSlowMethod)) && ok;
      ok = FusionSettingsWriteLine(handle, "maFastPrice", IntegerToString((int)settings.maFastPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "maSlowPrice", IntegerToString((int)settings.maSlowPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "maEntryMode", IntegerToString((int)settings.maEntryMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "maExitMode", IntegerToString((int)settings.maExitMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "useRSI", IntegerToString((int)settings.useRSI)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiPriority", IntegerToString(settings.rsiPriority)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiPeriod", IntegerToString(settings.rsiPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiTimeframe", IntegerToString((int)settings.rsiTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiOversold", IntegerToString(settings.rsiOversold)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiOverbought", IntegerToString(settings.rsiOverbought)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiMiddle", IntegerToString(settings.rsiMiddle)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiMode", IntegerToString((int)settings.rsiMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiPrice", IntegerToString((int)settings.rsiPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiExitMode", IntegerToString((int)settings.rsiExitMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "useBollinger", IntegerToString((int)settings.useBollinger)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbPriority", IntegerToString(settings.bbPriority)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbPeriod", IntegerToString(settings.bbPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbTimeframe", IntegerToString((int)settings.bbTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbDeviation", DoubleToString(settings.bbDeviation, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbPrice", IntegerToString((int)settings.bbPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbMode", IntegerToString((int)settings.bbMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbExitMode", IntegerToString((int)settings.bbExitMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "useTrendFilter", IntegerToString((int)(settings.trendMA1Enabled || settings.trendMA2Enabled))) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMA1Enabled", IntegerToString((int)settings.trendMA1Enabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMAPeriod", IntegerToString(settings.trendMAPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMATimeframe", IntegerToString((int)settings.trendMATimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMAMethod", IntegerToString((int)settings.trendMAMethod)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMAPrice", IntegerToString((int)settings.trendMAPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendMA2Enabled", IntegerToString((int)settings.trendMA2Enabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendSellMAPeriod", IntegerToString(settings.trendSellMAPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendSellMATimeframe", IntegerToString((int)settings.trendSellMATimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendSellMAMethod", IntegerToString((int)settings.trendSellMAMethod)) && ok;
      ok = FusionSettingsWriteLine(handle, "trendSellMAPrice", IntegerToString((int)settings.trendSellMAPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "useRSIFilter", IntegerToString((int)settings.useRSIFilter)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterMode", IntegerToString((int)settings.rsiFilterMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterPeriod", IntegerToString(settings.rsiFilterPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterTimeframe", IntegerToString((int)settings.rsiFilterTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterBuyMin", IntegerToString(settings.rsiFilterBuyMin)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterSellMax", IntegerToString(settings.rsiFilterSellMax)) && ok;
      ok = FusionSettingsWriteLine(handle, "rsiFilterPrice", IntegerToString((int)settings.rsiFilterPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterEnabled", IntegerToString((int)settings.bbFilterEnabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterMode", IntegerToString((int)settings.bbFilterMode)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterPeriod", IntegerToString(settings.bbFilterPeriod)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterTimeframe", IntegerToString((int)settings.bbFilterTimeframe)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterDeviation", DoubleToString(settings.bbFilterDeviation, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterPrice", IntegerToString((int)settings.bbFilterPrice)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterMinWidthPoints", IntegerToString(settings.bbFilterMinWidthPoints)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterMinWidthPercent", DoubleToString(settings.bbFilterMinWidthPercent, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterSlopeDirectionEnabled", IntegerToString((int)settings.bbFilterSlopeDirectionEnabled)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterSlopeLookback", IntegerToString(settings.bbFilterSlopeLookback)) && ok;
      ok = FusionSettingsWriteLine(handle, "bbFilterMinSlopePoints", IntegerToString(settings.bbFilterMinSlopePoints)) && ok;
      return ok;
     }

   bool              ApplyNewsWindowSetting(const string key,const string value,SEASettings &settings) const
     {
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         string prefix = "news" + IntegerToString(newsIndex + 1) + ".";
         if(StringFind(key, prefix) != 0)
            continue;

         string field = StringSubstr(key, StringLen(prefix));
         if(field == "enabled")
           {
            settings.newsWindows[newsIndex].enabled = (bool)StringToInteger(value);
            return true;
           }
         if(field == "startHour")
           {
            settings.newsWindows[newsIndex].startHour = (int)StringToInteger(value);
            return true;
           }
         if(field == "startMinute")
           {
            settings.newsWindows[newsIndex].startMinute = (int)StringToInteger(value);
            return true;
           }
         if(field == "endHour")
           {
            settings.newsWindows[newsIndex].endHour = (int)StringToInteger(value);
            return true;
           }
         if(field == "endMinute")
           {
            settings.newsWindows[newsIndex].endMinute = (int)StringToInteger(value);
            return true;
           }
         if(field == "action")
           {
            settings.newsWindows[newsIndex].action = (ENUM_NEWS_WINDOW_ACTION)StringToInteger(value);
            return true;
           }

         return false;
        }

      return false;
     }

   void              ApplySetting(const string key,const string value,SEASettings &settings) const
     {
      if(key == "schemaVersion") settings.schemaVersion = (int)StringToInteger(value);
      else if(key == "panelEnabled") settings.panelEnabled = (bool)StringToInteger(value);
      else if(key == "defaultProfileName") settings.defaultProfileName = value;
      else if(key == "magicNumber") settings.magicNumber = (int)StringToInteger(value);
      else if(key == "slippagePoints") settings.slippagePoints = (int)StringToInteger(value);
      else if(key == "debugLogs") settings.debugLogs = (bool)StringToInteger(value);
      else if(key == "showChartIndicators") settings.showChartIndicators = (bool)StringToInteger(value);
      else if(key == "visualMAFastColor") settings.visualMAFastColor = (color)StringToInteger(value);
      else if(key == "visualMASlowColor") settings.visualMASlowColor = (color)StringToInteger(value);
      else if(key == "visualMATrendColor") settings.visualMATrendColor = (color)StringToInteger(value);
      else if(key == "visualMATrend2Color") settings.visualMATrend2Color = (color)StringToInteger(value);
      else if(key == "visualBBColor") settings.visualBBColor = (color)StringToInteger(value);
      else if(key == "visualMAFastStyle") settings.visualMAFastStyle = (ENUM_LINE_STYLE)StringToInteger(value);
      else if(key == "visualMASlowStyle") settings.visualMASlowStyle = (ENUM_LINE_STYLE)StringToInteger(value);
      else if(key == "visualMATrendStyle") settings.visualMATrendStyle = (ENUM_LINE_STYLE)StringToInteger(value);
      else if(key == "visualMATrend2Style") settings.visualMATrend2Style = (ENUM_LINE_STYLE)StringToInteger(value);
      else if(key == "visualBBStyle") settings.visualBBStyle = (ENUM_LINE_STYLE)StringToInteger(value);
      else if(key == "conflictMode") settings.conflictMode = (ENUM_CONFLICT_RESOLUTION)StringToInteger(value);
      else if(key == "tradeDirection") settings.tradeDirection = (ENUM_TRADE_DIRECTION)StringToInteger(value);
      else if(key == "enableSpreadProtection") settings.enableSpreadProtection = (bool)StringToInteger(value);
      else if(key == "maxSpreadPoints") settings.maxSpreadPoints = (int)StringToInteger(value);
      else if(key == "enableSessionFilter") settings.enableSessionFilter = (bool)StringToInteger(value);
      else if(key == "sessionStartHour") settings.sessionStartHour = (int)StringToInteger(value);
      else if(key == "sessionStartMinute") settings.sessionStartMinute = (int)StringToInteger(value);
      else if(key == "sessionEndHour") settings.sessionEndHour = (int)StringToInteger(value);
      else if(key == "sessionEndMinute") settings.sessionEndMinute = (int)StringToInteger(value);
      else if(key == "sessionOvernight") settings.sessionOvernight = (bool)StringToInteger(value);
      else if(key == "closeOnSessionEnd") settings.closeOnSessionEnd = (bool)StringToInteger(value);
      else if(ApplyNewsWindowSetting(key, value, settings)) return;
      else if(key == "enableDailyLimits") settings.enableDailyLimits = (bool)StringToInteger(value);
      else if(key == "maxDailyTrades") settings.maxDailyTrades = (int)StringToInteger(value);
      else if(key == "maxDailyLoss") settings.maxDailyLoss = StringToDouble(value);
      else if(key == "maxDailyGain") settings.maxDailyGain = StringToDouble(value);
      else if(key == "profitTargetAction") settings.profitTargetAction = (ENUM_PROFIT_TARGET_ACTION)StringToInteger(value);
      else if(key == "enableDrawdown") settings.enableDrawdown = (bool)StringToInteger(value);
      else if(key == "maxDrawdown") settings.maxDrawdown = StringToDouble(value);
      else if(key == "drawdownType") settings.drawdownType = (ENUM_DRAWDOWN_TYPE)StringToInteger(value);
      else if(key == "drawdownPeakMode") settings.drawdownPeakMode = (ENUM_DRAWDOWN_PEAK_MODE)StringToInteger(value);
      else if(key == "lossStreakEnabled") settings.lossStreakEnabled = (bool)StringToInteger(value);
      else if(key == "maxLossStreak") settings.maxLossStreak = (int)StringToInteger(value);
      else if(key == "lossStreakAction") settings.lossStreakAction = (ENUM_STREAK_ACTION)StringToInteger(value);
      else if(key == "lossStreakPauseMinutes") settings.lossStreakPauseMinutes = (int)StringToInteger(value);
      else if(key == "winStreakEnabled") settings.winStreakEnabled = (bool)StringToInteger(value);
      else if(key == "maxWinStreak") settings.maxWinStreak = (int)StringToInteger(value);
      else if(key == "winStreakAction") settings.winStreakAction = (ENUM_STREAK_ACTION)StringToInteger(value);
      else if(key == "winStreakPauseMinutes") settings.winStreakPauseMinutes = (int)StringToInteger(value);
      else if(key == "fixedLot") settings.fixedLot = StringToDouble(value);
      else if(key == "fixedSLPoints") settings.fixedSLPoints = (int)StringToInteger(value);
      else if(key == "fixedTPPoints") settings.fixedTPPoints = (int)StringToInteger(value);
      else if(key == "compensateSLSpread") settings.compensateSLSpread = (bool)StringToInteger(value);
      else if(key == "compensateTPSpread") settings.compensateTPSpread = (bool)StringToInteger(value);
      else if(key == "usePartialTP") settings.usePartialTP = (bool)StringToInteger(value);
      else if(key == "freeFinalTP") settings.freeFinalTP = (bool)StringToInteger(value);
      else if(key == "tp1.enabled") settings.tp1.enabled = (bool)StringToInteger(value);
      else if(key == "tp1.percent") settings.tp1.percent = StringToDouble(value);
      else if(key == "tp1.distancePoints") settings.tp1.distancePoints = (int)StringToInteger(value);
      else if(key == "tp2.enabled") settings.tp2.enabled = (bool)StringToInteger(value);
      else if(key == "tp2.percent") settings.tp2.percent = StringToDouble(value);
      else if(key == "tp2.distancePoints") settings.tp2.distancePoints = (int)StringToInteger(value);
      else if(key == "useTrailing") settings.useTrailing = (bool)StringToInteger(value);
      else if(key == "trailingStartPoints") settings.trailingStartPoints = (int)StringToInteger(value);
      else if(key == "trailingStepPoints") settings.trailingStepPoints = (int)StringToInteger(value);
      else if(key == "useBreakeven") settings.useBreakeven = (bool)StringToInteger(value);
      else if(key == "breakevenTriggerPoints") settings.breakevenTriggerPoints = (int)StringToInteger(value);
      else if(key == "breakevenOffsetPoints") settings.breakevenOffsetPoints = (int)StringToInteger(value);
      else if(key == "useMACross") settings.useMACross = (bool)StringToInteger(value);
      else if(key == "maCrossPriority") settings.maCrossPriority = (int)StringToInteger(value);
      else if(key == "maFastPeriod") settings.maFastPeriod = (int)StringToInteger(value);
      else if(key == "maSlowPeriod") settings.maSlowPeriod = (int)StringToInteger(value);
      else if(key == "maMinDistancePoints") settings.maMinDistancePoints = (int)StringToInteger(value);
      else if(key == "maFastTimeframe") settings.maFastTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "maSlowTimeframe") settings.maSlowTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "maFastMethod") settings.maFastMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "maSlowMethod") settings.maSlowMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "maFastPrice") settings.maFastPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "maSlowPrice") settings.maSlowPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "maEntryMode") settings.maEntryMode = (ENUM_ENTRY_MODE)StringToInteger(value);
      else if(key == "maExitMode") settings.maExitMode = (ENUM_EXIT_MODE)StringToInteger(value);
      else if(key == "useRSI") settings.useRSI = (bool)StringToInteger(value);
      else if(key == "rsiPriority") settings.rsiPriority = (int)StringToInteger(value);
      else if(key == "rsiPeriod") settings.rsiPeriod = (int)StringToInteger(value);
      else if(key == "rsiTimeframe") settings.rsiTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "rsiOversold") settings.rsiOversold = (int)StringToInteger(value);
      else if(key == "rsiOverbought") settings.rsiOverbought = (int)StringToInteger(value);
      else if(key == "rsiMiddle") settings.rsiMiddle = (int)StringToInteger(value);
      else if(key == "rsiMode") settings.rsiMode = (ENUM_RSI_SIGNAL_MODE)StringToInteger(value);
      else if(key == "rsiPrice") settings.rsiPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "rsiExitMode") settings.rsiExitMode = (ENUM_RSI_EXIT_MODE)StringToInteger(value);
      else if(key == "useBollinger") settings.useBollinger = (bool)StringToInteger(value);
      else if(key == "bbPriority") settings.bbPriority = (int)StringToInteger(value);
      else if(key == "bbPeriod") settings.bbPeriod = (int)StringToInteger(value);
      else if(key == "bbTimeframe") settings.bbTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "bbDeviation") settings.bbDeviation = StringToDouble(value);
      else if(key == "bbPrice") settings.bbPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "bbMode") settings.bbMode = (ENUM_BB_SIGNAL_MODE)StringToInteger(value);
      else if(key == "bbExitMode") settings.bbExitMode = (ENUM_EXIT_MODE)StringToInteger(value);
      else if(key == "useTrendFilter") settings.useTrendFilter = (bool)StringToInteger(value);
      else if(key == "trendMA1Enabled") settings.trendMA1Enabled = (bool)StringToInteger(value);
      else if(key == "trendMAPeriod") settings.trendMAPeriod = (int)StringToInteger(value);
      else if(key == "trendMATimeframe") settings.trendMATimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "trendMAMethod") settings.trendMAMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "trendMAPrice") settings.trendMAPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "trendMA2Enabled") settings.trendMA2Enabled = (bool)StringToInteger(value);
      else if(key == "trendDualBarrierEnabled") settings.trendMA2Enabled = (bool)StringToInteger(value);
      else if(key == "trendSellMAPeriod") settings.trendSellMAPeriod = (int)StringToInteger(value);
      else if(key == "trendSellMATimeframe") settings.trendSellMATimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "trendSellMAMethod") settings.trendSellMAMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "trendSellMAPrice") settings.trendSellMAPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "useRSIFilter") settings.useRSIFilter = (bool)StringToInteger(value);
      else if(key == "rsiFilterMode") settings.rsiFilterMode = (ENUM_RSI_FILTER_MODE)StringToInteger(value);
      else if(key == "rsiFilterPeriod") settings.rsiFilterPeriod = (int)StringToInteger(value);
      else if(key == "rsiFilterTimeframe") settings.rsiFilterTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "rsiFilterBuyMin") settings.rsiFilterBuyMin = (int)StringToInteger(value);
      else if(key == "rsiFilterSellMax") settings.rsiFilterSellMax = (int)StringToInteger(value);
      else if(key == "rsiFilterPrice") settings.rsiFilterPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "bbFilterEnabled") settings.bbFilterEnabled = (bool)StringToInteger(value);
      else if(key == "bbFilterMode") settings.bbFilterMode = (ENUM_BB_FILTER_WIDTH_MODE)StringToInteger(value);
      else if(key == "bbFilterPeriod") settings.bbFilterPeriod = (int)StringToInteger(value);
      else if(key == "bbFilterTimeframe") settings.bbFilterTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "bbFilterDeviation") settings.bbFilterDeviation = StringToDouble(value);
      else if(key == "bbFilterPrice") settings.bbFilterPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "bbFilterMinWidthPoints") settings.bbFilterMinWidthPoints = (int)StringToInteger(value);
      else if(key == "bbFilterMinWidthPercent") settings.bbFilterMinWidthPercent = StringToDouble(value);
      else if(key == "bbFilterSlopeDirectionEnabled") settings.bbFilterSlopeDirectionEnabled = (bool)StringToInteger(value);
      else if(key == "bbFilterSlopeLookback") settings.bbFilterSlopeLookback = (int)StringToInteger(value);
      else if(key == "bbFilterMinSlopePoints") settings.bbFilterMinSlopePoints = (int)StringToInteger(value);
     }

   bool              ProfileHasRequiredFields(const int schemaVersion,
                                               const int settingLineCount,
                                               const bool seenSchema,
                                               const bool seenMagic,
                                               const bool seenFixedLot,
                                               const bool seenMA,
                                               const bool seenRSI,
                                               const bool seenBB,
                                               const bool seenTrend,
                                               const bool seenRSIFilter,
                                               const bool seenBBFilter,
                                               const bool seenLegacyTail,
                                               const bool seenCurrentTail) const
     {
      if(!seenSchema || schemaVersion <= 0 || schemaVersion > FUSION_SETTINGS_SCHEMA_VERSION)
         return false;
      if(!seenMagic || !seenFixedLot || !seenMA || !seenRSI || !seenBB || !seenTrend || !seenRSIFilter)
         return false;

      // bbFilterMinWidthPercent era a ultima linha gravada pela 1.055 e pelas
      // versoes anteriores ainda migraveis. Exigi-la impede que um arquivo
      // truncado seja completado silenciosamente com defaults.
      if(!seenLegacyTail)
         return false;

      // Schemas legados sao migrados pelos defaults conhecidos. A partir do
      // schema 8, o bloco do BB Filter passou a fazer parte do perfil.
      if(schemaVersion >= 8 && !seenBBFilter)
         return false;

      // O schema atual e estrito: um perfil novo deve conter o bloco completo
      // gravado por SaveSettingsBlock e o seu ultimo campo obrigatorio.
      if(schemaVersion == FUSION_SETTINGS_SCHEMA_VERSION)
         return (settingLineCount >= FUSION_SETTINGS_SCHEMA_LINE_COUNT && seenCurrentTail);

      return true;
     }

   ENUM_STREAK_ACTION NormalizeStreakAction(const ENUM_STREAK_ACTION action,const ENUM_STREAK_ACTION fallback) const
     {
      if(action == STREAK_ACTION_PAUSE || action == STREAK_ACTION_STOP_DAY)
         return action;
      return fallback;
     }

   ENUM_PROFIT_TARGET_ACTION NormalizeProfitTargetAction(const ENUM_PROFIT_TARGET_ACTION action) const
     {
      if(action == PROFIT_ACTION_ATIVAR_DD)
         return action;
      return PROFIT_ACTION_PARAR;
     }

   ENUM_DRAWDOWN_TYPE NormalizeDrawdownType(const ENUM_DRAWDOWN_TYPE value) const
     {
      if(value == DD_TIPO_PERCENTUAL)
         return value;
      return DD_TIPO_FINANCEIRO;
     }

   ENUM_DRAWDOWN_PEAK_MODE NormalizeDrawdownPeakMode(const ENUM_DRAWDOWN_PEAK_MODE value) const
     {
      if(value == DD_PICO_REALIZADO)
         return value;
      return DD_PICO_FLUTUANTE;
     }

   void              NormalizeProtectionSettings(SEASettings &settings) const
     {
      settings.profitTargetAction = NormalizeProfitTargetAction(settings.profitTargetAction);
      settings.drawdownType = NormalizeDrawdownType(settings.drawdownType);
      settings.drawdownPeakMode = NormalizeDrawdownPeakMode(settings.drawdownPeakMode);
     }

   void              NormalizeStreakSettings(SEASettings &settings) const
     {
      if(settings.maxLossStreak < 0)
         settings.maxLossStreak = 0;
      if(settings.maxWinStreak < 0)
         settings.maxWinStreak = 0;
      if(settings.lossStreakPauseMinutes < 0)
         settings.lossStreakPauseMinutes = 0;
      if(settings.winStreakPauseMinutes < 0)
         settings.winStreakPauseMinutes = 0;

      settings.lossStreakAction = NormalizeStreakAction(settings.lossStreakAction, STREAK_ACTION_PAUSE);
      settings.winStreakAction = NormalizeStreakAction(settings.winStreakAction, STREAK_ACTION_STOP_DAY);

     }

   void              NormalizeRiskSettings(SEASettings &settings) const
     {
      if(!settings.tp1.enabled)
        {
         settings.tp2.enabled = false;
         settings.freeFinalTP = false;
        }

      settings.usePartialTP = settings.tp1.enabled;
     }

   ENUM_LINE_STYLE   NormalizeVisualStyle(const ENUM_LINE_STYLE style) const
     {
      if(style == STYLE_DASH || style == STYLE_DOT)
         return style;
      return STYLE_SOLID;
     }

   void              NormalizeVisualSettings(SEASettings &settings) const
     {
      settings.visualMAFastStyle = NormalizeVisualStyle(settings.visualMAFastStyle);
      settings.visualMASlowStyle = NormalizeVisualStyle(settings.visualMASlowStyle);
      settings.visualMATrendStyle = NormalizeVisualStyle(settings.visualMATrendStyle);
      settings.visualMATrend2Style = NormalizeVisualStyle(settings.visualMATrend2Style);
      settings.visualBBStyle = NormalizeVisualStyle(settings.visualBBStyle);
     }

   void              NormalizeTrendSettings(SEASettings &settings) const
     {
      if(settings.schemaVersion <= 13)
        {
         settings.trendMA1Enabled = settings.useTrendFilter;
         settings.trendMA2Enabled = (settings.useTrendFilter && settings.trendMA2Enabled);
        }

      settings.useTrendFilter = (settings.trendMA1Enabled || settings.trendMA2Enabled);
     }

   void              ApplyRuntimeField(const string key,
                                       const string value,
                                       string &activeProfileName,
                                       bool &started,
                                       SPositionRuntimeState &state,
                                       SStreakRuntimeState &streakState,
                                       SDailyLimitsRuntimeState &dailyState,
                                       SDrawdownRuntimeState &drawdownState) const
     {
      if(key == "activeProfileName") activeProfileName = value;
      else if(key == "started") started = (bool)StringToInteger(value);
      else if(key == "state.hasPosition") state.hasPosition = (bool)StringToInteger(value);
      else if(key == "state.positionId") state.positionId = (ulong)StringToInteger(value);
      else if(key == "state.ownerStrategyId") state.ownerStrategyId = value;
      else if(key == "state.ownerStrategyName") state.ownerStrategyName = value;
      else if(key == "state.tp1Executed") state.tp1Executed = (bool)StringToInteger(value);
      else if(key == "state.tp2Executed") state.tp2Executed = (bool)StringToInteger(value);
      else if(key == "state.breakevenActive") state.breakevenActive = (bool)StringToInteger(value);
      else if(key == "state.trailingActive") state.trailingActive = (bool)StringToInteger(value);
      else if(key == "state.realizedPartialProfit") state.realizedPartialProfit = StringToDouble(value);
      else if(key == "state.tp1Price") state.tp1Price = StringToDouble(value);
      else if(key == "state.tp1Volume") state.tp1Volume = StringToDouble(value);
      else if(key == "state.tp2Price") state.tp2Price = StringToDouble(value);
      else if(key == "state.tp2Volume") state.tp2Volume = StringToDouble(value);
      else if(key == "state.partialClosePending") state.partialClosePending = (bool)StringToInteger(value);
      else if(key == "state.pendingPartialLevel") state.pendingPartialLevel = (ENUM_PARTIAL_CLOSE_LEVEL)StringToInteger(value);
      else if(key == "state.pendingPartialInitialVolume") state.pendingPartialInitialVolume = StringToDouble(value);
      else if(key == "state.pendingPartialRequestedVolume") state.pendingPartialRequestedVolume = StringToDouble(value);
      else if(key == "state.pendingPartialBaselineExitVolume") state.pendingPartialBaselineExitVolume = StringToDouble(value);
      else if(key == "state.pendingPartialPreProjectedProfit") state.pendingPartialPreProjectedProfit = StringToDouble(value);
      else if(key == "state.pendingPartialFloatingReferenceSet") state.pendingPartialFloatingReferenceSet = (bool)StringToInteger(value);
      else if(key == "state.pendingPartialFloatingReference") state.pendingPartialFloatingReference = StringToDouble(value);
      else if(key == "state.pendingPartialOrderTicket") state.pendingPartialOrderTicket = (ulong)StringToInteger(value);
      else if(key == "state.pendingPartialDealTicket") state.pendingPartialDealTicket = (ulong)StringToInteger(value);
      else if(key == "state.pendingPartialRetcode") state.pendingPartialRetcode = (uint)StringToInteger(value);
      else if(key == "state.pendingPartialSince") state.pendingPartialSince = (datetime)StringToInteger(value);
      else if(key == "state.dayPeakProjectedProfit") state.dayPeakProjectedProfit = StringToDouble(value);
      else if(key == "streak.dayKey") streakState.dayKey = (int)StringToInteger(value);
      else if(key == "streak.lossStreak") streakState.lossStreak = (int)StringToInteger(value);
      else if(key == "streak.winStreak") streakState.winStreak = (int)StringToInteger(value);
      else if(key == "streak.lossStopDayBlocked") streakState.lossStopDayBlocked = (bool)StringToInteger(value);
      else if(key == "streak.winStopDayBlocked") streakState.winStopDayBlocked = (bool)StringToInteger(value);
      else if(key == "streak.lossPauseUntil") streakState.lossPauseUntil = (datetime)StringToInteger(value);
      else if(key == "streak.winPauseUntil") streakState.winPauseUntil = (datetime)StringToInteger(value);
      else if(key == "day.dayKey") dailyState.dayKey = (int)StringToInteger(value);
      else if(key == "day.dailyTradeCount") dailyState.dailyTradeCount = (int)StringToInteger(value);
      else if(key == "day.dailyLossCount") dailyState.dailyLossCount = (int)StringToInteger(value);
      else if(key == "day.dailyWinCount") dailyState.dailyWinCount = (int)StringToInteger(value);
      else if(key == "day.dailyBreakevenCount") dailyState.dailyBreakevenCount = (int)StringToInteger(value);
      else if(key == "day.outcomeCountsKnown") dailyState.outcomeCountsKnown = (bool)StringToInteger(value);
      else if(key == "day.dailyClosedProfit") dailyState.dailyClosedProfit = StringToDouble(value);
      else if(key == "day.tradesLimitReached") dailyState.tradesLimitReached = (bool)StringToInteger(value);
      else if(key == "day.lossLimitReached") dailyState.lossLimitReached = (bool)StringToInteger(value);
      else if(key == "day.gainLimitReached") dailyState.gainLimitReached = (bool)StringToInteger(value);
      else if(key == "drawdown.dayKey") drawdownState.dayKey = (int)StringToInteger(value);
      else if(key == "drawdown.protectionActive") drawdownState.protectionActive = (bool)StringToInteger(value);
      else if(key == "drawdown.limitReached") drawdownState.limitReached = (bool)StringToInteger(value);
      else if(key == "drawdown.peakProjectedProfit") drawdownState.peakProjectedProfit = StringToDouble(value);
      else if(key == "drawdown.triggerProjectedProfit") drawdownState.triggerProjectedProfit = StringToDouble(value);
      else if(key == "drawdown.triggerDrawdownAmount") drawdownState.triggerDrawdownAmount = StringToDouble(value);
      else if(key == "drawdown.triggerBufferProfit") drawdownState.triggerBufferProfit = StringToDouble(value);
     }

   void              ApplyContextField(const string key,const string value,SChartStateContext &context) const
     {
      if(key == "context.chartId") context.chartId = (ulong)StringToInteger(value);
      else if(key == "context.symbol") context.symbol = value;
      else if(key == "context.timeframe") context.timeframe = value;
      else if(key == "context.periodValue") context.periodValue = (int)StringToInteger(value);
      else if(key == "context.deinitReason") context.deinitReason = (int)StringToInteger(value);
      else if(key == "context.discardedUnsavedDraft") context.discardedUnsavedDraft = (bool)StringToInteger(value);
     }

   int               ChartStateContextFieldIndex(const string key) const
     {
      if(key == "context.chartId") return 0;
      if(key == "context.symbol") return 1;
      if(key == "context.timeframe") return 2;
      if(key == "context.periodValue") return 3;
      if(key == "context.deinitReason") return 4;
      if(key == "context.discardedUnsavedDraft") return 5;
      return -1;
     }

   int               ChartStateHeaderFieldIndex(const string key) const
     {
      if(key == "activeProfileName") return 0;
      if(key == "started") return 1;
      return -1;
     }

   int               ChartStatePositionFieldIndex(const string key) const
     {
      if(key == "state.hasPosition") return 0;
      if(key == "state.positionId") return 1;
      if(key == "state.ownerStrategyId") return 2;
      if(key == "state.ownerStrategyName") return 3;
      if(key == "state.tp1Executed") return 4;
      if(key == "state.tp2Executed") return 5;
      if(key == "state.breakevenActive") return 6;
      if(key == "state.trailingActive") return 7;
      if(key == "state.realizedPartialProfit") return 8;
      if(key == "state.tp1Price") return 9;
      if(key == "state.tp1Volume") return 10;
      if(key == "state.tp2Price") return 11;
      if(key == "state.tp2Volume") return 12;
      if(key == "state.partialClosePending") return 13;
      if(key == "state.pendingPartialLevel") return 14;
      if(key == "state.pendingPartialInitialVolume") return 15;
      if(key == "state.pendingPartialRequestedVolume") return 16;
      if(key == "state.pendingPartialBaselineExitVolume") return 17;
      if(key == "state.pendingPartialPreProjectedProfit") return 18;
      if(key == "state.pendingPartialFloatingReferenceSet") return 19;
      if(key == "state.pendingPartialFloatingReference") return 20;
      if(key == "state.pendingPartialOrderTicket") return 21;
      if(key == "state.pendingPartialDealTicket") return 22;
      if(key == "state.pendingPartialRetcode") return 23;
      if(key == "state.pendingPartialSince") return 24;
      if(key == "state.dayPeakProjectedProfit") return 25;
      return -1;
     }

   int               ChartStateStreakFieldIndex(const string key) const
     {
      if(key == "streak.dayKey") return 0;
      if(key == "streak.lossStreak") return 1;
      if(key == "streak.winStreak") return 2;
      if(key == "streak.lossStopDayBlocked") return 3;
      if(key == "streak.winStopDayBlocked") return 4;
      if(key == "streak.lossPauseUntil") return 5;
      if(key == "streak.winPauseUntil") return 6;
      return -1;
     }

   int               ChartStateDayFieldIndex(const string key) const
     {
      if(key == "day.dayKey") return 0;
      if(key == "day.dailyTradeCount") return 1;
      if(key == "day.dailyLossCount") return 2;
      if(key == "day.dailyWinCount") return 3;
      if(key == "day.dailyBreakevenCount") return 4;
      if(key == "day.outcomeCountsKnown") return 5;
      if(key == "day.dailyClosedProfit") return 6;
      if(key == "day.tradesLimitReached") return 7;
      if(key == "day.lossLimitReached") return 8;
      if(key == "day.gainLimitReached") return 9;
      return -1;
     }

   int               ChartStateDrawdownFieldIndex(const string key) const
     {
      if(key == "drawdown.dayKey") return 0;
      if(key == "drawdown.protectionActive") return 1;
      if(key == "drawdown.limitReached") return 2;
      if(key == "drawdown.peakProjectedProfit") return 3;
      if(key == "drawdown.triggerProjectedProfit") return 4;
      if(key == "drawdown.triggerDrawdownAmount") return 5;
      if(key == "drawdown.triggerBufferProfit") return 6;
      return -1;
     }

public:
   string            ProfilesFolderPath(void) const
     {
      FusionSettingsEnsureFolders();
      return TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + FusionProfilesFolderRelative();
     }

   string            SanitizeProfileName(const string profileName) const
     {
      return FusionSanitizeProfileName(profileName);
     }

   bool              ProfileExists(const string profileName) const
     {
      FusionSettingsEnsureFolders();
      string fileName = FusionProfileFileName(profileName);
      return FileIsExist(fileName);
     }

   bool              FindProfileByMagicNumber(const int magicNumber,const string exceptProfileName,string &foundProfileName) const
     {
      foundProfileName = "";
      if(magicNumber <= 0)
         return false;

      string profiles[];
      if(!ListProfiles(profiles))
         return false;

      string exceptSafe = FusionSanitizeProfileName(exceptProfileName);
      for(int i = 0; i < ArraySize(profiles); ++i)
        {
         if(FusionSanitizeProfileName(profiles[i]) == exceptSafe)
            continue;

         SEASettings settings;
         if(!LoadProfile(profiles[i], settings))
            continue;

         if(settings.magicNumber == magicNumber)
           {
            foundProfileName = profiles[i];
            return true;
           }
        }

      return false;
     }

   bool              ListProfiles(string &profiles[]) const
     {
      FusionSettingsEnsureFolders();
      ArrayResize(profiles, 0);

      string fileName = "";
      long handle = FileFindFirst(FusionProfilesFolderRelative() + "\\*.cfg", fileName);
      if(handle == INVALID_HANDLE)
         return true;

      do
        {
         string profileName = fileName;
         int slash = StringFind(profileName, "\\");
         while(slash >= 0)
           {
            profileName = StringSubstr(profileName, slash + 1);
            slash = StringFind(profileName, "\\");
           }

         int len = StringLen(profileName);
         if(len > 4 && StringSubstr(profileName, len - 4) == ".cfg")
            profileName = StringSubstr(profileName, 0, len - 4);

         if(profileName != "")
           {
            int count = ArraySize(profiles);
            ArrayResize(profiles, count + 1);
            profiles[count] = profileName;
           }
        }
      while(FileFindNext(handle, fileName));

      FileFindClose(handle);

      int count = ArraySize(profiles);
      for(int i = 0; i < count - 1; ++i)
        {
         for(int j = i + 1; j < count; ++j)
           {
            if(StringCompare(profiles[j], profiles[i]) < 0)
              {
               string tmp = profiles[i];
               profiles[i] = profiles[j];
               profiles[j] = tmp;
              }
           }
        }

      return true;
     }

   bool              SaveProfile(const string profileName,const SEASettings &settings)
     {
      FusionSettingsEnsureFolders();

      string fileName = FusionProfileFileName(profileName);
      string tempFileName = fileName + ".tmp";
      FileDelete(tempFileName);
      int handle = FileOpen(tempFileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      bool ok = SaveSettingsBlock(handle, settings);
      FileFlush(handle);
      FileClose(handle);
      if(!ok)
        {
         FileDelete(tempFileName);
         return false;
        }

      if(!FileMove(tempFileName, 0, fileName, FILE_REWRITE))
        {
         FileDelete(tempFileName);
         return false;
        }
      return true;
     }

   bool              DeleteProfile(const string profileName)
     {
      FusionSettingsEnsureFolders();
      string fileName = FusionProfileFileName(profileName);
      if(!FileIsExist(fileName))
         return false;
      return FileDelete(fileName);
     }

   bool              LoadProfile(const string profileName,SEASettings &settings) const
     {
      FusionSettingsEnsureFolders();
      SEASettings candidate;
      SetDefaultSettings(candidate);

      string fileName = FusionProfileFileName(profileName);
      int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      int settingLineCount = 0;
      bool seenSchema = false;
      bool seenMagic = false;
      bool seenFixedLot = false;
      bool seenMA = false;
      bool seenRSI = false;
      bool seenBB = false;
      bool seenTrend = false;
      bool seenRSIFilter = false;
      bool seenBBFilter = false;
      bool seenLegacyTail = false;
      bool seenCurrentTail = false;

      while(!FileIsEnding(handle))
        {
         string line = FileReadString(handle);
         string key = "";
         string value = "";
         if(!FusionSettingsParseLine(line, key, value))
            continue;

         settingLineCount++;
         if(key == "schemaVersion") seenSchema = true;
         else if(key == "magicNumber") seenMagic = true;
         else if(key == "fixedLot") seenFixedLot = true;
         else if(key == "useMACross") seenMA = true;
         else if(key == "useRSI") seenRSI = true;
         else if(key == "useBollinger") seenBB = true;
         else if(key == "useTrendFilter") seenTrend = true;
         else if(key == "useRSIFilter") seenRSIFilter = true;
         else if(key == "bbFilterEnabled") seenBBFilter = true;
         else if(key == "bbFilterMinWidthPercent") seenLegacyTail = true;
         else if(key == "bbFilterMinSlopePoints") seenCurrentTail = true;
         ApplySetting(key, value, candidate);
        }

      FileClose(handle);
      if(!ProfileHasRequiredFields(candidate.schemaVersion,
                                   settingLineCount,
                                   seenSchema,
                                   seenMagic,
                                   seenFixedLot,
                                   seenMA,
                                   seenRSI,
                                   seenBB,
                                   seenTrend,
                                   seenRSIFilter,
                                   seenBBFilter,
                                   seenLegacyTail,
                                   seenCurrentTail))
         return false;

      NormalizeProtectionSettings(candidate);
      NormalizeStreakSettings(candidate);
      NormalizeRiskSettings(candidate);
      NormalizeTrendSettings(candidate);
      NormalizeVisualSettings(candidate);
      candidate.schemaVersion = FUSION_SETTINGS_SCHEMA_VERSION;
      settings = candidate;
      return true;
     }

   bool              SaveChartState(const SChartStateContext &context,
                                    const string activeProfileName,
                                    const bool started,
                                    const SEASettings &settings,
                                    const SPositionRuntimeState &state,
                                    const SStreakRuntimeState &streakState,
                                    const SDailyLimitsRuntimeState &dailyState,
                                    const SDrawdownRuntimeState &drawdownState)
     {
      FusionSettingsEnsureFolders();

      string fileName = FusionChartStateFileName(context.chartId);
      string tempFileName = fileName + ".tmp";
      FileDelete(tempFileName);
      int handle = FileOpen(tempFileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      bool ok = true;
      ok = FusionSettingsWriteLine(handle, "context.chartId", StringFormat("%I64u", context.chartId)) && ok;
      ok = FusionSettingsWriteLine(handle, "context.symbol", context.symbol) && ok;
      ok = FusionSettingsWriteLine(handle, "context.timeframe", context.timeframe) && ok;
      ok = FusionSettingsWriteLine(handle, "context.periodValue", IntegerToString(context.periodValue)) && ok;
      ok = FusionSettingsWriteLine(handle, "context.deinitReason", IntegerToString(context.deinitReason)) && ok;
      ok = FusionSettingsWriteLine(handle, "context.discardedUnsavedDraft", IntegerToString((int)context.discardedUnsavedDraft)) && ok;
      ok = SaveSettingsBlock(handle, settings) && ok;
      ok = FusionSettingsWriteLine(handle, "activeProfileName", activeProfileName) && ok;
      ok = FusionSettingsWriteLine(handle, "started", IntegerToString((int)started)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.hasPosition", IntegerToString((int)state.hasPosition)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.positionId", StringFormat("%I64u", state.positionId)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.ownerStrategyId", state.ownerStrategyId) && ok;
      ok = FusionSettingsWriteLine(handle, "state.ownerStrategyName", state.ownerStrategyName) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp1Executed", IntegerToString((int)state.tp1Executed)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp2Executed", IntegerToString((int)state.tp2Executed)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.breakevenActive", IntegerToString((int)state.breakevenActive)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.trailingActive", IntegerToString((int)state.trailingActive)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.realizedPartialProfit", DoubleToString(state.realizedPartialProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp1Price", DoubleToString(state.tp1Price, 8)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp1Volume", DoubleToString(state.tp1Volume, 4)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp2Price", DoubleToString(state.tp2Price, 8)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.tp2Volume", DoubleToString(state.tp2Volume, 4)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.partialClosePending", IntegerToString((int)state.partialClosePending)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialLevel", IntegerToString((int)state.pendingPartialLevel)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialInitialVolume", DoubleToString(state.pendingPartialInitialVolume, 8)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialRequestedVolume", DoubleToString(state.pendingPartialRequestedVolume, 8)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialBaselineExitVolume", DoubleToString(state.pendingPartialBaselineExitVolume, 8)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialPreProjectedProfit", DoubleToString(state.pendingPartialPreProjectedProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialFloatingReferenceSet", IntegerToString((int)state.pendingPartialFloatingReferenceSet)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialFloatingReference", DoubleToString(state.pendingPartialFloatingReference, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialOrderTicket", StringFormat("%I64u", state.pendingPartialOrderTicket)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialDealTicket", StringFormat("%I64u", state.pendingPartialDealTicket)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialRetcode", IntegerToString((int)state.pendingPartialRetcode)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.pendingPartialSince", IntegerToString((long)state.pendingPartialSince)) && ok;
      ok = FusionSettingsWriteLine(handle, "state.dayPeakProjectedProfit", DoubleToString(state.dayPeakProjectedProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.dayKey", IntegerToString(streakState.dayKey)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.lossStreak", IntegerToString(streakState.lossStreak)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.winStreak", IntegerToString(streakState.winStreak)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.lossStopDayBlocked", IntegerToString((int)streakState.lossStopDayBlocked)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.winStopDayBlocked", IntegerToString((int)streakState.winStopDayBlocked)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.lossPauseUntil", IntegerToString((long)streakState.lossPauseUntil)) && ok;
      ok = FusionSettingsWriteLine(handle, "streak.winPauseUntil", IntegerToString((long)streakState.winPauseUntil)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dayKey", IntegerToString(dailyState.dayKey)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dailyTradeCount", IntegerToString(dailyState.dailyTradeCount)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dailyLossCount", IntegerToString(dailyState.dailyLossCount)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dailyWinCount", IntegerToString(dailyState.dailyWinCount)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dailyBreakevenCount", IntegerToString(dailyState.dailyBreakevenCount)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.outcomeCountsKnown", IntegerToString((int)dailyState.outcomeCountsKnown)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.dailyClosedProfit", DoubleToString(dailyState.dailyClosedProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.tradesLimitReached", IntegerToString((int)dailyState.tradesLimitReached)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.lossLimitReached", IntegerToString((int)dailyState.lossLimitReached)) && ok;
      ok = FusionSettingsWriteLine(handle, "day.gainLimitReached", IntegerToString((int)dailyState.gainLimitReached)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.dayKey", IntegerToString(drawdownState.dayKey)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.protectionActive", IntegerToString((int)drawdownState.protectionActive)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.limitReached", IntegerToString((int)drawdownState.limitReached)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.peakProjectedProfit", DoubleToString(drawdownState.peakProjectedProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.triggerProjectedProfit", DoubleToString(drawdownState.triggerProjectedProfit, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.triggerDrawdownAmount", DoubleToString(drawdownState.triggerDrawdownAmount, 2)) && ok;
      ok = FusionSettingsWriteLine(handle, "drawdown.triggerBufferProfit", DoubleToString(drawdownState.triggerBufferProfit, 2)) && ok;

      FileFlush(handle);
      FileClose(handle);
      if(!ok)
        {
         FileDelete(tempFileName);
         return false;
        }

      if(!FileMove(tempFileName, 0, fileName, FILE_REWRITE))
        {
         FileDelete(tempFileName);
         return false;
        }
      return true;
     }

   bool              LoadChartState(const ulong chartId,
                                     SChartStateContext &context,
                                     string &activeProfileName,
                                     bool &started,
                                     SEASettings &settings,
                                     SPositionRuntimeState &state,
                                     SStreakRuntimeState &streakState,
                                     SDailyLimitsRuntimeState &dailyState,
                                     SDrawdownRuntimeState &drawdownState,
                                     string &errorReason)
      {
      FusionSettingsEnsureFolders();
      errorReason = "";

      string fileName = FusionChartStateFileName(chartId);
      int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      SChartStateContext candidateContext;
      candidateContext.chartId = 0;
      candidateContext.symbol = "";
      candidateContext.timeframe = "";
      candidateContext.periodValue = 0;
      candidateContext.deinitReason = -1;
      candidateContext.discardedUnsavedDraft = false;

      SEASettings candidateSettings;
      SetDefaultSettings(candidateSettings);
      SPositionRuntimeState candidateState;
      SStreakRuntimeState candidateStreakState;
      SDailyLimitsRuntimeState candidateDailyState;
      SDrawdownRuntimeState candidateDrawdownState;
      ResetPositionRuntimeState(candidateState);
      ResetStreakRuntimeState(candidateStreakState);
      ResetDailyLimitsRuntimeState(candidateDailyState);
      ResetDrawdownRuntimeState(candidateDrawdownState);
      string candidateActiveProfileName = "";
      bool candidateStarted = false;

      int settingLineCount = 0;
      int contextLineCount = 0;
      int runtimeHeaderLineCount = 0;
      int positionLineCount = 0;
      int streakLineCount = 0;
      int dayLineCount = 0;
      int drawdownLineCount = 0;
      const int requiredContextLines = 6;
      const int requiredRuntimeHeaderLines = 2;
      const int requiredPositionLines = 26;
      const int requiredStreakLines = 7;
      const int requiredDayLines = 10;
      const int requiredDrawdownLines = 7;

      bool seenContextFields[6];
      bool seenRuntimeHeaderFields[2];
      bool seenPositionFields[26];
      bool seenStreakFields[7];
      bool seenDayFields[10];
      bool seenDrawdownFields[7];
      ArrayInitialize(seenContextFields, false);
      ArrayInitialize(seenRuntimeHeaderFields, false);
      ArrayInitialize(seenPositionFields, false);
      ArrayInitialize(seenStreakFields, false);
      ArrayInitialize(seenDayFields, false);
      ArrayInitialize(seenDrawdownFields, false);

      bool seenSchema = false;
      bool seenMagic = false;
      bool seenFixedLot = false;
      bool seenMA = false;
      bool seenRSI = false;
      bool seenBB = false;
      bool seenTrend = false;
      bool seenRSIFilter = false;
      bool seenBBFilter = false;
      bool seenLegacyTail = false;
      bool seenCurrentTail = false;

      string structuralError = "";

      while(!FileIsEnding(handle))
        {
         string line = FileReadString(handle);
         string key = "";
         string value = "";
         if(!FusionSettingsParseLine(line, key, value))
            continue;

         if(StringFind(key, "context.") == 0)
           {
            int fieldIndex = ChartStateContextFieldIndex(key);
            if(fieldIndex < 0)
               structuralError = "contexto contem chave desconhecida: " + key;
            else if(seenContextFields[fieldIndex])
               structuralError = "contexto contem chave duplicada: " + key;
            else
              {
               seenContextFields[fieldIndex] = true;
               contextLineCount++;
              }
           }
         else if(key == "activeProfileName" || key == "started")
           {
            int fieldIndex = ChartStateHeaderFieldIndex(key);
            if(seenRuntimeHeaderFields[fieldIndex])
               structuralError = "cabecalho operacional contem chave duplicada: " + key;
            else
              {
               seenRuntimeHeaderFields[fieldIndex] = true;
               runtimeHeaderLineCount++;
              }
           }
         else if(StringFind(key, "state.") == 0)
           {
            int fieldIndex = ChartStatePositionFieldIndex(key);
            if(fieldIndex < 0)
               structuralError = "estado da posicao contem chave desconhecida: " + key;
            else if(seenPositionFields[fieldIndex])
               structuralError = "estado da posicao contem chave duplicada: " + key;
            else
              {
               seenPositionFields[fieldIndex] = true;
               positionLineCount++;
              }
           }
         else if(StringFind(key, "streak.") == 0)
           {
            int fieldIndex = ChartStateStreakFieldIndex(key);
            if(fieldIndex < 0)
               structuralError = "estado de streak contem chave desconhecida: " + key;
            else if(seenStreakFields[fieldIndex])
               structuralError = "estado de streak contem chave duplicada: " + key;
            else
              {
               seenStreakFields[fieldIndex] = true;
               streakLineCount++;
              }
           }
         else if(StringFind(key, "day.") == 0)
           {
            int fieldIndex = ChartStateDayFieldIndex(key);
            if(fieldIndex < 0)
               structuralError = "estado diario contem chave desconhecida: " + key;
            else if(seenDayFields[fieldIndex])
               structuralError = "estado diario contem chave duplicada: " + key;
            else
              {
               seenDayFields[fieldIndex] = true;
               dayLineCount++;
              }
           }
         else if(StringFind(key, "drawdown.") == 0)
           {
            int fieldIndex = ChartStateDrawdownFieldIndex(key);
            if(fieldIndex < 0)
               structuralError = "estado de drawdown contem chave desconhecida: " + key;
            else if(seenDrawdownFields[fieldIndex])
               structuralError = "estado de drawdown contem chave duplicada: " + key;
            else
              {
               seenDrawdownFields[fieldIndex] = true;
               drawdownLineCount++;
              }
           }
         else
           {
            settingLineCount++;
            if(key == "schemaVersion") seenSchema = true;
            else if(key == "magicNumber") seenMagic = true;
            else if(key == "fixedLot") seenFixedLot = true;
            else if(key == "useMACross") seenMA = true;
            else if(key == "useRSI") seenRSI = true;
            else if(key == "useBollinger") seenBB = true;
            else if(key == "useTrendFilter") seenTrend = true;
            else if(key == "useRSIFilter") seenRSIFilter = true;
            else if(key == "bbFilterEnabled") seenBBFilter = true;
            else if(key == "bbFilterMinWidthPercent") seenLegacyTail = true;
            else if(key == "bbFilterMinSlopePoints") seenCurrentTail = true;
           }

         if(structuralError != "")
            break;

         ApplySetting(key, value, candidateSettings);
         ApplyRuntimeField(key,
                           value,
                           candidateActiveProfileName,
                           candidateStarted,
                           candidateState,
                           candidateStreakState,
                           candidateDailyState,
                           candidateDrawdownState);
         ApplyContextField(key, value, candidateContext);
        }

      FileClose(handle);

      if(structuralError != "")
        {
         errorReason = structuralError;
         return false;
        }

      if(!ProfileHasRequiredFields(candidateSettings.schemaVersion,
                                   settingLineCount,
                                   seenSchema,
                                   seenMagic,
                                   seenFixedLot,
                                   seenMA,
                                   seenRSI,
                                   seenBB,
                                   seenTrend,
                                   seenRSIFilter,
                                   seenBBFilter,
                                   seenLegacyTail,
                                   seenCurrentTail))
        {
         errorReason = "bloco de configuracao incompleto ou schema invalido";
         return false;
        }

      if(contextLineCount != requiredContextLines ||
         candidateContext.symbol == "" || candidateContext.timeframe == "" ||
         candidateContext.periodValue <= 0)
        {
         errorReason = "contexto do grafico incompleto";
         return false;
        }
      if(candidateContext.chartId != chartId)
        {
         errorReason = "chartId divergente";
         return false;
        }

      if(runtimeHeaderLineCount != requiredRuntimeHeaderLines)
        {
         errorReason = "cabecalho operacional incompleto";
         return false;
        }
      if(positionLineCount != requiredPositionLines)
        {
         errorReason = "estado da posicao incompleto";
         return false;
        }
      if(streakLineCount != requiredStreakLines)
        {
         errorReason = "estado de streak incompleto";
         return false;
        }
      if(dayLineCount != requiredDayLines)
        {
         errorReason = "estado diario incompleto";
         return false;
        }
      if(drawdownLineCount != requiredDrawdownLines)
        {
         errorReason = "estado de drawdown incompleto";
         return false;
        }

      NormalizeProtectionSettings(candidateSettings);
      NormalizeStreakSettings(candidateSettings);
      NormalizeRiskSettings(candidateSettings);
      NormalizeTrendSettings(candidateSettings);
      NormalizeVisualSettings(candidateSettings);
      candidateSettings.schemaVersion = FUSION_SETTINGS_SCHEMA_VERSION;

      context = candidateContext;
      activeProfileName = candidateActiveProfileName;
      started = candidateStarted;
      settings = candidateSettings;
      state = candidateState;
      streakState = candidateStreakState;
      dailyState = candidateDailyState;
      drawdownState = candidateDrawdownState;
      return true;
      }
  };

#endif
