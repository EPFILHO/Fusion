#ifndef __FUSION_CHART_STATE_SERIALIZER_MQH__
#define __FUSION_CHART_STATE_SERIALIZER_MQH__

#include "../../Core/Types.mqh"

void FusionApplyRuntimeField(const string key,
                             const string value,
                             string &activeProfileName,
                             bool &started,
                             SPositionRuntimeState &state,
                             SStreakRuntimeState &streakState,
                             SDailyLimitsRuntimeState &dailyState,
                             SDrawdownRuntimeState &drawdownState)
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

void FusionApplyContextField(const string key,const string value,SChartStateContext &context)
  {
   if(key == "context.chartId") context.chartId = (ulong)StringToInteger(value);
   else if(key == "context.symbol") context.symbol = value;
   else if(key == "context.timeframe") context.timeframe = value;
   else if(key == "context.periodValue") context.periodValue = (int)StringToInteger(value);
   else if(key == "context.deinitReason") context.deinitReason = (int)StringToInteger(value);
   else if(key == "context.discardedUnsavedDraft") context.discardedUnsavedDraft = (bool)StringToInteger(value);
  }

int FusionChartStateContextFieldIndex(const string key)
  {
   if(key == "context.chartId") return 0;
   if(key == "context.symbol") return 1;
   if(key == "context.timeframe") return 2;
   if(key == "context.periodValue") return 3;
   if(key == "context.deinitReason") return 4;
   if(key == "context.discardedUnsavedDraft") return 5;
   return -1;
  }

int FusionChartStateHeaderFieldIndex(const string key)
  {
   if(key == "activeProfileName") return 0;
   if(key == "started") return 1;
   return -1;
  }

int FusionChartStatePositionFieldIndex(const string key)
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

int FusionChartStateStreakFieldIndex(const string key)
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

int FusionChartStateDayFieldIndex(const string key)
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

int FusionChartStateDrawdownFieldIndex(const string key)
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

#endif
