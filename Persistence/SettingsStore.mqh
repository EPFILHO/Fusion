#ifndef __FUSION_SETTINGS_STORE_MQH__
#define __FUSION_SETTINGS_STORE_MQH__

#include "../Core/Types.mqh"
#include "../Core/ProfileNameUtils.mqh"
#include "Modules/SettingsFileUtils.mqh"
#include "Modules/ProfileSettingsSerializer.mqh"
#include "Modules/ChartStateSerializer.mqh"
#include "Modules/ProfileStore.mqh"

class CSettingsStore
  {
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
      return FusionProfileExists(profileName);
     }

   bool              FindProfileByMagicNumber(const int magicNumber,const string exceptProfileName,string &foundProfileName) const
     {
      return FusionFindProfileByMagicNumber(magicNumber, exceptProfileName, foundProfileName);
     }

   bool              ListProfiles(string &profiles[]) const
     {
      return FusionListProfiles(profiles);
     }

   bool              SaveProfile(const string profileName,const SEASettings &settings)
     {
      return FusionSaveProfile(profileName, settings);
     }

   bool              DeleteProfile(const string profileName)
     {
      return FusionDeleteProfile(profileName);
     }

   bool              LoadProfile(const string profileName,SEASettings &settings) const
     {
      return FusionLoadProfile(profileName, settings);
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
            int fieldIndex = FusionChartStateContextFieldIndex(key);
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
            int fieldIndex = FusionChartStateHeaderFieldIndex(key);
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
            int fieldIndex = FusionChartStatePositionFieldIndex(key);
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
            int fieldIndex = FusionChartStateStreakFieldIndex(key);
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
            int fieldIndex = FusionChartStateDayFieldIndex(key);
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
            int fieldIndex = FusionChartStateDrawdownFieldIndex(key);
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
         FusionApplyRuntimeField(key,
                                 value,
                                 candidateActiveProfileName,
                                 candidateStarted,
                                 candidateState,
                                 candidateStreakState,
                                 candidateDailyState,
                                 candidateDrawdownState);
         FusionApplyContextField(key, value, candidateContext);
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
