#ifndef __FUSION_SETTINGS_STORE_MQH__
#define __FUSION_SETTINGS_STORE_MQH__

#include "../Core/Types.mqh"
#include "../Core/ProfileNameUtils.mqh"
#include "Modules/SettingsFileUtils.mqh"
#include "Modules/ProfileSettingsSerializer.mqh"

class CSettingsStore
  {
private:
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

      bool ok = FusionSaveSettingsBlock(handle, settings);
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
         FusionApplySetting(key, value, candidate);
        }

      FileClose(handle);
      if(!FusionProfileHasRequiredFields(candidate.schemaVersion,
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

      FusionNormalizeProtectionSettings(candidate);
      FusionNormalizeStreakSettings(candidate);
      FusionNormalizeRiskSettings(candidate);
      FusionNormalizeTrendSettings(candidate);
      FusionNormalizeVisualSettings(candidate);
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
      ok = FusionSaveSettingsBlock(handle, settings) && ok;
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

         FusionApplySetting(key, value, candidateSettings);
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

      if(!FusionProfileHasRequiredFields(candidateSettings.schemaVersion,
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

      FusionNormalizeProtectionSettings(candidateSettings);
      FusionNormalizeStreakSettings(candidateSettings);
      FusionNormalizeRiskSettings(candidateSettings);
      FusionNormalizeTrendSettings(candidateSettings);
      FusionNormalizeVisualSettings(candidateSettings);
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
