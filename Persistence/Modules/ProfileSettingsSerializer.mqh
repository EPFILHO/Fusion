#ifndef __FUSION_PROFILE_SETTINGS_SERIALIZER_MQH__
#define __FUSION_PROFILE_SETTINGS_SERIALIZER_MQH__

#include "../../Core/Types.mqh"
#include "SettingsFileUtils.mqh"

bool FusionSaveSettingsBlock(const int handle,const SEASettings &settings)
  {
   bool ok = true;
   ok = FusionSettingsWriteLine(handle, "schemaVersion", IntegerToString(FUSION_SETTINGS_SCHEMA_VERSION)) && ok;
   ok = FusionSettingsWriteLine(handle, "panelEnabled", IntegerToString((int)settings.panelEnabled)) && ok;
   ok = FusionSettingsWriteLine(handle, "defaultProfileName", settings.defaultProfileName) && ok;
   ok = FusionSettingsWriteLine(handle, "magicNumber", IntegerToString(settings.magicNumber)) && ok;
   ok = FusionSettingsWriteLine(handle, "slippagePoints", IntegerToString(settings.slippagePoints)) && ok;
   //--- debugLogs NAO e gravado: e diagnostico de sessao, decidido pelo input
   //--- inp_EnableDebugLogs e reaplicado apos cada carregamento de perfil.
   //--- Guardar por perfil nao fazia sentido — ninguem quer um perfil que loga
   //--- e outro que nao — e criava um estado impossivel de desligar pela GUI
   //--- depois que o controle saiu dela.
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

bool FusionApplyNewsWindowSetting(const string key,const string value,SEASettings &settings)
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

void FusionApplySetting(const string key,const string value,SEASettings &settings)
  {
   if(key == "schemaVersion") settings.schemaVersion = (int)StringToInteger(value);
   else if(key == "panelEnabled") settings.panelEnabled = (bool)StringToInteger(value);
   else if(key == "defaultProfileName") settings.defaultProfileName = value;
   else if(key == "magicNumber") settings.magicNumber = (int)StringToInteger(value);
   else if(key == "slippagePoints") settings.slippagePoints = (int)StringToInteger(value);
   //--- "debugLogs" e ignorado de proposito. Perfis gravados por versoes
   //--- anteriores ainda trazem a chave; le-la sobrescreveria o input.
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
   else if(FusionApplyNewsWindowSetting(key, value, settings)) return;
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

bool FusionProfileHasRequiredFields(const int schemaVersion,
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
                                    const bool seenCurrentTail)
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
   // gravado por FusionSaveSettingsBlock e o seu ultimo campo obrigatorio.
   if(schemaVersion == FUSION_SETTINGS_SCHEMA_VERSION)
      return (settingLineCount >= FUSION_SETTINGS_SCHEMA_LINE_COUNT && seenCurrentTail);

   return true;
  }

ENUM_STREAK_ACTION FusionNormalizeStreakAction(const ENUM_STREAK_ACTION action,const ENUM_STREAK_ACTION fallback)
  {
   if(action == STREAK_ACTION_PAUSE || action == STREAK_ACTION_STOP_DAY)
      return action;
   return fallback;
  }

ENUM_PROFIT_TARGET_ACTION FusionNormalizeProfitTargetAction(const ENUM_PROFIT_TARGET_ACTION action)
  {
   if(action == PROFIT_ACTION_ATIVAR_DD)
      return action;
   return PROFIT_ACTION_PARAR;
  }

ENUM_DRAWDOWN_TYPE FusionNormalizeDrawdownType(const ENUM_DRAWDOWN_TYPE value)
  {
   if(value == DD_TIPO_PERCENTUAL)
      return value;
   return DD_TIPO_FINANCEIRO;
  }

ENUM_DRAWDOWN_PEAK_MODE FusionNormalizeDrawdownPeakMode(const ENUM_DRAWDOWN_PEAK_MODE value)
  {
   if(value == DD_PICO_REALIZADO)
      return value;
   return DD_PICO_FLUTUANTE;
  }

void FusionNormalizeProtectionSettings(SEASettings &settings)
  {
   settings.profitTargetAction = FusionNormalizeProfitTargetAction(settings.profitTargetAction);
   settings.drawdownType = FusionNormalizeDrawdownType(settings.drawdownType);
   settings.drawdownPeakMode = FusionNormalizeDrawdownPeakMode(settings.drawdownPeakMode);
  }

void FusionNormalizeStreakSettings(SEASettings &settings)
  {
   if(settings.maxLossStreak < 0)
      settings.maxLossStreak = 0;
   if(settings.maxWinStreak < 0)
      settings.maxWinStreak = 0;
   if(settings.lossStreakPauseMinutes < 0)
      settings.lossStreakPauseMinutes = 0;
   if(settings.winStreakPauseMinutes < 0)
      settings.winStreakPauseMinutes = 0;

   settings.lossStreakAction = FusionNormalizeStreakAction(settings.lossStreakAction, STREAK_ACTION_PAUSE);
   settings.winStreakAction = FusionNormalizeStreakAction(settings.winStreakAction, STREAK_ACTION_STOP_DAY);

  }

void FusionNormalizeRiskSettings(SEASettings &settings)
  {
   if(!settings.tp1.enabled)
     {
      settings.tp2.enabled = false;
      settings.freeFinalTP = false;
     }

   settings.usePartialTP = settings.tp1.enabled;
  }

ENUM_LINE_STYLE FusionNormalizeVisualStyle(const ENUM_LINE_STYLE style)
  {
   if(style == STYLE_DASH || style == STYLE_DOT)
      return style;
   return STYLE_SOLID;
  }

void FusionNormalizeVisualSettings(SEASettings &settings)
  {
   settings.visualMAFastStyle = FusionNormalizeVisualStyle(settings.visualMAFastStyle);
   settings.visualMASlowStyle = FusionNormalizeVisualStyle(settings.visualMASlowStyle);
   settings.visualMATrendStyle = FusionNormalizeVisualStyle(settings.visualMATrendStyle);
   settings.visualMATrend2Style = FusionNormalizeVisualStyle(settings.visualMATrend2Style);
   settings.visualBBStyle = FusionNormalizeVisualStyle(settings.visualBBStyle);
  }

void FusionNormalizeTrendSettings(SEASettings &settings)
  {
   if(settings.schemaVersion <= 13)
     {
      settings.trendMA1Enabled = settings.useTrendFilter;
      settings.trendMA2Enabled = (settings.useTrendFilter && settings.trendMA2Enabled);
     }

   settings.useTrendFilter = (settings.trendMA1Enabled || settings.trendMA2Enabled);
  }

#endif
