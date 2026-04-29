#ifndef __FUSION_SETTINGS_STORE_MQH__
#define __FUSION_SETTINGS_STORE_MQH__

#include "../Core/Types.mqh"

class CSettingsStore
  {
private:
   string            SanitizeName(const string value) const
     {
      string safe = value;
      string invalid = "\\/:*?\"<>| ";
      for(int i = 0; i < StringLen(invalid); i++)
        {
         string token = StringSubstr(invalid, i, 1);
         StringReplace(safe, token, "_");
        }
      return safe;
     }

   bool              ParseLine(const string line,string &key,string &value) const
     {
      int separator = StringFind(line, "=");
      if(separator < 0)
         return false;

      key   = StringSubstr(line, 0, separator);
      value = StringSubstr(line, separator + 1);
      return true;
     }

   string            ProfilesFolderRelative(void) const
     {
      return "Fusion\\Profiles";
     }

   string            ChartStateFolderRelative(void) const
     {
      return "Fusion\\ChartState";
     }

   string            ProfileFileName(const string profileName) const
     {
      return ProfilesFolderRelative() + "\\" + SanitizeName(profileName) + ".cfg";
     }

   void              EnsureFolders(void) const
     {
      FolderCreate("Fusion");
      FolderCreate(ProfilesFolderRelative());
      FolderCreate(ChartStateFolderRelative());
     }

   bool              WriteLine(const int handle,const string key,const string value) const
     {
      return (FileWriteString(handle, key + "=" + value + "\r\n") > 0);
     }

   bool              SaveSettingsBlock(const int handle,const SEASettings &settings) const
     {
      WriteLine(handle, "schemaVersion", IntegerToString(settings.schemaVersion));
      WriteLine(handle, "panelEnabled", IntegerToString((int)settings.panelEnabled));
      WriteLine(handle, "autoRestoreChartState", IntegerToString((int)settings.autoRestoreChartState));
      WriteLine(handle, "autoSaveChartState", IntegerToString((int)settings.autoSaveChartState));
      WriteLine(handle, "defaultProfileName", settings.defaultProfileName);
      WriteLine(handle, "magicNumber", IntegerToString(settings.magicNumber));
      WriteLine(handle, "slippagePoints", IntegerToString(settings.slippagePoints));
      WriteLine(handle, "debugLogs", IntegerToString((int)settings.debugLogs));
      WriteLine(handle, "conflictMode", IntegerToString((int)settings.conflictMode));
      WriteLine(handle, "tradeDirection", IntegerToString((int)settings.tradeDirection));
      WriteLine(handle, "enableSpreadProtection", IntegerToString((int)settings.enableSpreadProtection));
      WriteLine(handle, "maxSpreadPoints", IntegerToString(settings.maxSpreadPoints));
      WriteLine(handle, "enableSessionFilter", IntegerToString((int)settings.enableSessionFilter));
      WriteLine(handle, "sessionStartHour", IntegerToString(settings.sessionStartHour));
      WriteLine(handle, "sessionStartMinute", IntegerToString(settings.sessionStartMinute));
      WriteLine(handle, "sessionEndHour", IntegerToString(settings.sessionEndHour));
      WriteLine(handle, "sessionEndMinute", IntegerToString(settings.sessionEndMinute));
      WriteLine(handle, "closeOnSessionEnd", IntegerToString((int)settings.closeOnSessionEnd));
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         string prefix = "news" + IntegerToString(newsIndex + 1) + ".";
         WriteLine(handle, prefix + "enabled", IntegerToString((int)settings.newsWindows[newsIndex].enabled));
         WriteLine(handle, prefix + "startHour", IntegerToString(settings.newsWindows[newsIndex].startHour));
         WriteLine(handle, prefix + "startMinute", IntegerToString(settings.newsWindows[newsIndex].startMinute));
         WriteLine(handle, prefix + "endHour", IntegerToString(settings.newsWindows[newsIndex].endHour));
         WriteLine(handle, prefix + "endMinute", IntegerToString(settings.newsWindows[newsIndex].endMinute));
         WriteLine(handle, prefix + "action", IntegerToString((int)settings.newsWindows[newsIndex].action));
        }
      WriteLine(handle, "enableDailyLimits", IntegerToString((int)settings.enableDailyLimits));
      WriteLine(handle, "maxDailyTrades", IntegerToString(settings.maxDailyTrades));
      WriteLine(handle, "maxDailyLoss", DoubleToString(settings.maxDailyLoss, 2));
      WriteLine(handle, "maxDailyGain", DoubleToString(settings.maxDailyGain, 2));
      WriteLine(handle, "enableDrawdown", IntegerToString((int)settings.enableDrawdown));
      WriteLine(handle, "maxDrawdown", DoubleToString(settings.maxDrawdown, 2));
      WriteLine(handle, "enableStreak", IntegerToString((int)settings.enableStreak));
      WriteLine(handle, "maxLossStreak", IntegerToString(settings.maxLossStreak));
      WriteLine(handle, "maxWinStreak", IntegerToString(settings.maxWinStreak));
      WriteLine(handle, "fixedLot", DoubleToString(settings.fixedLot, 4));
      WriteLine(handle, "fixedSLPoints", IntegerToString(settings.fixedSLPoints));
      WriteLine(handle, "fixedTPPoints", IntegerToString(settings.fixedTPPoints));
      WriteLine(handle, "usePartialTP", IntegerToString((int)settings.usePartialTP));
      WriteLine(handle, "tp1.enabled", IntegerToString((int)settings.tp1.enabled));
      WriteLine(handle, "tp1.percent", DoubleToString(settings.tp1.percent, 2));
      WriteLine(handle, "tp1.distancePoints", IntegerToString(settings.tp1.distancePoints));
      WriteLine(handle, "tp2.enabled", IntegerToString((int)settings.tp2.enabled));
      WriteLine(handle, "tp2.percent", DoubleToString(settings.tp2.percent, 2));
      WriteLine(handle, "tp2.distancePoints", IntegerToString(settings.tp2.distancePoints));
      WriteLine(handle, "useTrailing", IntegerToString((int)settings.useTrailing));
      WriteLine(handle, "trailingStartPoints", IntegerToString(settings.trailingStartPoints));
      WriteLine(handle, "trailingStepPoints", IntegerToString(settings.trailingStepPoints));
      WriteLine(handle, "useBreakeven", IntegerToString((int)settings.useBreakeven));
      WriteLine(handle, "breakevenTriggerPoints", IntegerToString(settings.breakevenTriggerPoints));
      WriteLine(handle, "breakevenOffsetPoints", IntegerToString(settings.breakevenOffsetPoints));
      WriteLine(handle, "useMACross", IntegerToString((int)settings.useMACross));
      WriteLine(handle, "maCrossPriority", IntegerToString(settings.maCrossPriority));
      WriteLine(handle, "maFastPeriod", IntegerToString(settings.maFastPeriod));
      WriteLine(handle, "maSlowPeriod", IntegerToString(settings.maSlowPeriod));
      WriteLine(handle, "maFastTimeframe", IntegerToString((int)settings.maFastTimeframe));
      WriteLine(handle, "maSlowTimeframe", IntegerToString((int)settings.maSlowTimeframe));
      WriteLine(handle, "maFastMethod", IntegerToString((int)settings.maFastMethod));
      WriteLine(handle, "maSlowMethod", IntegerToString((int)settings.maSlowMethod));
      WriteLine(handle, "maFastPrice", IntegerToString((int)settings.maFastPrice));
      WriteLine(handle, "maSlowPrice", IntegerToString((int)settings.maSlowPrice));
      WriteLine(handle, "maEntryMode", IntegerToString((int)settings.maEntryMode));
      WriteLine(handle, "maExitMode", IntegerToString((int)settings.maExitMode));
      WriteLine(handle, "useRSI", IntegerToString((int)settings.useRSI));
      WriteLine(handle, "rsiPriority", IntegerToString(settings.rsiPriority));
      WriteLine(handle, "rsiPeriod", IntegerToString(settings.rsiPeriod));
      WriteLine(handle, "rsiTimeframe", IntegerToString((int)settings.rsiTimeframe));
      WriteLine(handle, "rsiOversold", IntegerToString(settings.rsiOversold));
      WriteLine(handle, "rsiOverbought", IntegerToString(settings.rsiOverbought));
      WriteLine(handle, "rsiMiddle", IntegerToString(settings.rsiMiddle));
      WriteLine(handle, "rsiMode", IntegerToString((int)settings.rsiMode));
      WriteLine(handle, "rsiPrice", IntegerToString((int)settings.rsiPrice));
      WriteLine(handle, "rsiExitMode", IntegerToString((int)settings.rsiExitMode));
      WriteLine(handle, "useBollinger", IntegerToString((int)settings.useBollinger));
      WriteLine(handle, "bbPriority", IntegerToString(settings.bbPriority));
      WriteLine(handle, "bbPeriod", IntegerToString(settings.bbPeriod));
      WriteLine(handle, "bbTimeframe", IntegerToString((int)settings.bbTimeframe));
      WriteLine(handle, "bbDeviation", DoubleToString(settings.bbDeviation, 2));
      WriteLine(handle, "bbPrice", IntegerToString((int)settings.bbPrice));
      WriteLine(handle, "bbMode", IntegerToString((int)settings.bbMode));
      WriteLine(handle, "bbExitMode", IntegerToString((int)settings.bbExitMode));
      WriteLine(handle, "useTrendFilter", IntegerToString((int)settings.useTrendFilter));
      WriteLine(handle, "trendMAPeriod", IntegerToString(settings.trendMAPeriod));
      WriteLine(handle, "trendMATimeframe", IntegerToString((int)settings.trendMATimeframe));
      WriteLine(handle, "trendMAMethod", IntegerToString((int)settings.trendMAMethod));
      WriteLine(handle, "trendMAPrice", IntegerToString((int)settings.trendMAPrice));
      WriteLine(handle, "useRSIFilter", IntegerToString((int)settings.useRSIFilter));
      WriteLine(handle, "rsiFilterPeriod", IntegerToString(settings.rsiFilterPeriod));
      WriteLine(handle, "rsiFilterTimeframe", IntegerToString((int)settings.rsiFilterTimeframe));
      WriteLine(handle, "rsiFilterBuyMin", IntegerToString(settings.rsiFilterBuyMin));
      WriteLine(handle, "rsiFilterSellMax", IntegerToString(settings.rsiFilterSellMax));
      WriteLine(handle, "rsiFilterPrice", IntegerToString((int)settings.rsiFilterPrice));
      return true;
     }

   void              ApplySetting(const string key,const string value,SEASettings &settings) const
     {
      if(key == "schemaVersion") settings.schemaVersion = (int)StringToInteger(value);
      else if(key == "panelEnabled") settings.panelEnabled = (bool)StringToInteger(value);
      else if(key == "autoRestoreChartState") settings.autoRestoreChartState = (bool)StringToInteger(value);
      else if(key == "autoSaveChartState") settings.autoSaveChartState = (bool)StringToInteger(value);
      else if(key == "defaultProfileName") settings.defaultProfileName = value;
      else if(key == "magicNumber") settings.magicNumber = (int)StringToInteger(value);
      else if(key == "slippagePoints") settings.slippagePoints = (int)StringToInteger(value);
      else if(key == "debugLogs") settings.debugLogs = (bool)StringToInteger(value);
      else if(key == "conflictMode") settings.conflictMode = (ENUM_CONFLICT_RESOLUTION)StringToInteger(value);
      else if(key == "tradeDirection") settings.tradeDirection = (ENUM_TRADE_DIRECTION)StringToInteger(value);
      else if(key == "enableSpreadProtection") settings.enableSpreadProtection = (bool)StringToInteger(value);
      else if(key == "maxSpreadPoints") settings.maxSpreadPoints = (int)StringToInteger(value);
      else if(key == "enableSessionFilter") settings.enableSessionFilter = (bool)StringToInteger(value);
      else if(key == "sessionStartHour") settings.sessionStartHour = (int)StringToInteger(value);
      else if(key == "sessionStartMinute") settings.sessionStartMinute = (int)StringToInteger(value);
      else if(key == "sessionEndHour") settings.sessionEndHour = (int)StringToInteger(value);
      else if(key == "sessionEndMinute") settings.sessionEndMinute = (int)StringToInteger(value);
      else if(key == "closeOnSessionEnd") settings.closeOnSessionEnd = (bool)StringToInteger(value);
      else if(key == "news1.enabled") settings.newsWindows[0].enabled = (bool)StringToInteger(value);
      else if(key == "news1.startHour") settings.newsWindows[0].startHour = (int)StringToInteger(value);
      else if(key == "news1.startMinute") settings.newsWindows[0].startMinute = (int)StringToInteger(value);
      else if(key == "news1.endHour") settings.newsWindows[0].endHour = (int)StringToInteger(value);
      else if(key == "news1.endMinute") settings.newsWindows[0].endMinute = (int)StringToInteger(value);
      else if(key == "news1.action") settings.newsWindows[0].action = (ENUM_NEWS_WINDOW_ACTION)StringToInteger(value);
      else if(key == "news2.enabled") settings.newsWindows[1].enabled = (bool)StringToInteger(value);
      else if(key == "news2.startHour") settings.newsWindows[1].startHour = (int)StringToInteger(value);
      else if(key == "news2.startMinute") settings.newsWindows[1].startMinute = (int)StringToInteger(value);
      else if(key == "news2.endHour") settings.newsWindows[1].endHour = (int)StringToInteger(value);
      else if(key == "news2.endMinute") settings.newsWindows[1].endMinute = (int)StringToInteger(value);
      else if(key == "news2.action") settings.newsWindows[1].action = (ENUM_NEWS_WINDOW_ACTION)StringToInteger(value);
      else if(key == "news3.enabled") settings.newsWindows[2].enabled = (bool)StringToInteger(value);
      else if(key == "news3.startHour") settings.newsWindows[2].startHour = (int)StringToInteger(value);
      else if(key == "news3.startMinute") settings.newsWindows[2].startMinute = (int)StringToInteger(value);
      else if(key == "news3.endHour") settings.newsWindows[2].endHour = (int)StringToInteger(value);
      else if(key == "news3.endMinute") settings.newsWindows[2].endMinute = (int)StringToInteger(value);
      else if(key == "news3.action") settings.newsWindows[2].action = (ENUM_NEWS_WINDOW_ACTION)StringToInteger(value);
      else if(key == "enableDailyLimits") settings.enableDailyLimits = (bool)StringToInteger(value);
      else if(key == "maxDailyTrades") settings.maxDailyTrades = (int)StringToInteger(value);
      else if(key == "maxDailyLoss") settings.maxDailyLoss = StringToDouble(value);
      else if(key == "maxDailyGain") settings.maxDailyGain = StringToDouble(value);
      else if(key == "enableDrawdown") settings.enableDrawdown = (bool)StringToInteger(value);
      else if(key == "maxDrawdown") settings.maxDrawdown = StringToDouble(value);
      else if(key == "enableStreak") settings.enableStreak = (bool)StringToInteger(value);
      else if(key == "maxLossStreak") settings.maxLossStreak = (int)StringToInteger(value);
      else if(key == "maxWinStreak") settings.maxWinStreak = (int)StringToInteger(value);
      else if(key == "fixedLot") settings.fixedLot = StringToDouble(value);
      else if(key == "fixedSLPoints") settings.fixedSLPoints = (int)StringToInteger(value);
      else if(key == "fixedTPPoints") settings.fixedTPPoints = (int)StringToInteger(value);
      else if(key == "usePartialTP") settings.usePartialTP = (bool)StringToInteger(value);
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
      else if(key == "maFastTimeframe") settings.maFastTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "maSlowTimeframe") settings.maSlowTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "maFastMethod") settings.maFastMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "maSlowMethod") settings.maSlowMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "maFastPrice") settings.maFastPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "maSlowPrice") settings.maSlowPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "maEntryMode") settings.maEntryMode = (ENUM_ENTRY_MODE)StringToInteger(value);
      else if(key == "maMethod")
        {
         ENUM_MA_METHOD method = (ENUM_MA_METHOD)StringToInteger(value);
         settings.maFastMethod = method;
         settings.maSlowMethod = method;
        }
      else if(key == "maPrice")
        {
         ENUM_APPLIED_PRICE price = (ENUM_APPLIED_PRICE)StringToInteger(value);
         settings.maFastPrice = price;
         settings.maSlowPrice = price;
        }
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
      else if(key == "rsiExitMode") settings.rsiExitMode = (ENUM_EXIT_MODE)StringToInteger(value);
      else if(key == "useBollinger") settings.useBollinger = (bool)StringToInteger(value);
      else if(key == "bbPriority") settings.bbPriority = (int)StringToInteger(value);
      else if(key == "bbPeriod") settings.bbPeriod = (int)StringToInteger(value);
      else if(key == "bbTimeframe") settings.bbTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "bbDeviation") settings.bbDeviation = StringToDouble(value);
      else if(key == "bbPrice") settings.bbPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "bbMode") settings.bbMode = (ENUM_BB_SIGNAL_MODE)StringToInteger(value);
      else if(key == "bbExitMode") settings.bbExitMode = (ENUM_EXIT_MODE)StringToInteger(value);
      else if(key == "useTrendFilter") settings.useTrendFilter = (bool)StringToInteger(value);
      else if(key == "trendMAPeriod") settings.trendMAPeriod = (int)StringToInteger(value);
      else if(key == "trendMATimeframe") settings.trendMATimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "trendMAMethod") settings.trendMAMethod = (ENUM_MA_METHOD)StringToInteger(value);
      else if(key == "trendMAPrice") settings.trendMAPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
      else if(key == "useRSIFilter") settings.useRSIFilter = (bool)StringToInteger(value);
      else if(key == "rsiFilterPeriod") settings.rsiFilterPeriod = (int)StringToInteger(value);
      else if(key == "rsiFilterTimeframe") settings.rsiFilterTimeframe = (ENUM_TIMEFRAMES)StringToInteger(value);
      else if(key == "rsiFilterBuyMin") settings.rsiFilterBuyMin = (int)StringToInteger(value);
      else if(key == "rsiFilterSellMax") settings.rsiFilterSellMax = (int)StringToInteger(value);
      else if(key == "rsiFilterPrice") settings.rsiFilterPrice = (ENUM_APPLIED_PRICE)StringToInteger(value);
     }

   void              ApplyRuntimeField(const string key,const string value,string &activeProfileName,bool &started,SPositionRuntimeState &state) const
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
      else if(key == "state.dayPeakProjectedProfit") state.dayPeakProjectedProfit = StringToDouble(value);
     }

   void              ApplyContextField(const string key,const string value,SChartStateContext &context) const
     {
      if(key == "context.chartId") context.chartId = (ulong)StringToInteger(value);
      else if(key == "context.symbol") context.symbol = value;
      else if(key == "context.timeframe") context.timeframe = value;
      else if(key == "context.periodValue") context.periodValue = (int)StringToInteger(value);
      else if(key == "context.deinitReason") context.deinitReason = (int)StringToInteger(value);
     }

public:
   string            ProfilesFolderPath(void) const
     {
      EnsureFolders();
      return TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + ProfilesFolderRelative();
     }

   string            SanitizeProfileName(const string profileName) const
     {
      return SanitizeName(profileName);
     }

   bool              ProfileExists(const string profileName) const
     {
      EnsureFolders();
      string fileName = ProfileFileName(profileName);
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

      string exceptSafe = SanitizeName(exceptProfileName);
      for(int i = 0; i < ArraySize(profiles); ++i)
        {
         if(SanitizeName(profiles[i]) == exceptSafe)
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
      EnsureFolders();
      ArrayResize(profiles, 0);

      string fileName = "";
      long handle = FileFindFirst(ProfilesFolderRelative() + "\\*.cfg", fileName);
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
      EnsureFolders();

      string fileName = ProfileFileName(profileName);
      int handle = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      SaveSettingsBlock(handle, settings);
      FileClose(handle);
      return true;
     }

   bool              DeleteProfile(const string profileName)
     {
      EnsureFolders();
      string fileName = ProfileFileName(profileName);
      if(!FileIsExist(fileName))
         return false;
      return FileDelete(fileName);
     }

   bool              LoadProfile(const string profileName,SEASettings &settings) const
     {
      EnsureFolders();
      SetDefaultSettings(settings);

      string fileName = ProfileFileName(profileName);
      int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      while(!FileIsEnding(handle))
        {
         string line = FileReadString(handle);
         string key = "";
         string value = "";
         if(ParseLine(line, key, value))
            ApplySetting(key, value, settings);
        }

      FileClose(handle);
      return true;
     }

   bool              SaveChartState(const SChartStateContext &context,const string activeProfileName,const bool started,const SEASettings &settings,const SPositionRuntimeState &state)
     {
      EnsureFolders();

      string chartKey = "chart_" + StringFormat("%I64u", context.chartId);
      string fileName = ChartStateFolderRelative() + "\\" + SanitizeName(chartKey) + ".state";
      int handle = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      WriteLine(handle, "context.chartId", StringFormat("%I64u", context.chartId));
      WriteLine(handle, "context.symbol", context.symbol);
      WriteLine(handle, "context.timeframe", context.timeframe);
      WriteLine(handle, "context.periodValue", IntegerToString(context.periodValue));
      WriteLine(handle, "context.deinitReason", IntegerToString(context.deinitReason));
      SaveSettingsBlock(handle, settings);
      WriteLine(handle, "activeProfileName", activeProfileName);
      WriteLine(handle, "started", IntegerToString((int)started));
      WriteLine(handle, "state.hasPosition", IntegerToString((int)state.hasPosition));
      WriteLine(handle, "state.positionId", StringFormat("%I64u", state.positionId));
      WriteLine(handle, "state.ownerStrategyId", state.ownerStrategyId);
      WriteLine(handle, "state.ownerStrategyName", state.ownerStrategyName);
      WriteLine(handle, "state.tp1Executed", IntegerToString((int)state.tp1Executed));
      WriteLine(handle, "state.tp2Executed", IntegerToString((int)state.tp2Executed));
      WriteLine(handle, "state.breakevenActive", IntegerToString((int)state.breakevenActive));
      WriteLine(handle, "state.trailingActive", IntegerToString((int)state.trailingActive));
      WriteLine(handle, "state.realizedPartialProfit", DoubleToString(state.realizedPartialProfit, 2));
      WriteLine(handle, "state.tp1Price", DoubleToString(state.tp1Price, 8));
      WriteLine(handle, "state.tp1Volume", DoubleToString(state.tp1Volume, 4));
      WriteLine(handle, "state.tp2Price", DoubleToString(state.tp2Price, 8));
      WriteLine(handle, "state.tp2Volume", DoubleToString(state.tp2Volume, 4));
      WriteLine(handle, "state.dayPeakProjectedProfit", DoubleToString(state.dayPeakProjectedProfit, 2));

      FileClose(handle);
      return true;
     }

   bool              LoadChartState(const ulong chartId,SChartStateContext &context,string &activeProfileName,bool &started,SEASettings &settings,SPositionRuntimeState &state)
     {
      EnsureFolders();
      SetDefaultSettings(settings);
      ResetPositionRuntimeState(state);
      context.chartId = chartId;
      context.symbol = "";
      context.timeframe = "";
      context.periodValue = 0;
      context.deinitReason = -1;
      activeProfileName = "";
      started = false;

      string chartKey = "chart_" + StringFormat("%I64u", chartId);
      string fileName = ChartStateFolderRelative() + "\\" + SanitizeName(chartKey) + ".state";
      int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
         return false;

      while(!FileIsEnding(handle))
        {
         string line = FileReadString(handle);
         string key = "";
         string value = "";
         if(!ParseLine(line, key, value))
            continue;

         ApplySetting(key, value, settings);
         ApplyRuntimeField(key, value, activeProfileName, started, state);
         ApplyContextField(key, value, context);
        }

      FileClose(handle);
      if(settings.schemaVersion < 2 && settings.maxSpreadPoints > 0)
         settings.enableSpreadProtection = true;
      return true;
     }
  };

#endif
