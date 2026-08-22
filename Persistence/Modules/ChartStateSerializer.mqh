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

//+------------------------------------------------------------------+
//| Bloco `entry.*` — estado logico de entrada.                       |
//|                                                                    |
//| ⚠ Dominio SEPARADO dos demais. Nenhuma chave daqui pode alcancar   |
//| FusionApplySetting: elas nao sao configuracao, e cair no catch-all |
//| de settings envenenaria a contagem que valida o bloco de perfil.   |
//+------------------------------------------------------------------+
void FusionApplyEntryStateField(const string key,const string value,SEntryStateSnapshot &entry)
  {
   if(key == "entry.version") entry.version = (int)StringToInteger(value);
   else if(key == "entry.capturedAt") entry.capturedAt = (datetime)StringToInteger(value);
   else if(key == "entry.eligible") entry.eligible = (bool)StringToInteger(value);
   else if(key == "entry.ma.lastCrossTime") entry.maLastCrossTime = (datetime)StringToInteger(value);
   else if(key == "entry.ma.lastCrossSignal") entry.maLastCrossSignal = (int)StringToInteger(value);
   else if(key == "entry.ma.candlesAfterCross") entry.maCandlesAfterCross = (int)StringToInteger(value);
   else if(key == "entry.ma.lastCheckBarTime") entry.maLastCheckBarTime = (datetime)StringToInteger(value);
   else if(key == "entry.ma.pendingObserved") entry.maPendingObserved = (bool)StringToInteger(value);
   else if(key == "entry.ma.quarantine") entry.maQuarantine = (bool)StringToInteger(value);
   else if(key == "entry.ma.barrier") entry.maBarrier = (datetime)StringToInteger(value);
   else if(key == "entry.rsi.lastSignalBarTime") entry.rsiLastSignalBarTime = (datetime)StringToInteger(value);
   else if(key == "entry.rsi.quarantine") entry.rsiQuarantine = (bool)StringToInteger(value);
   else if(key == "entry.rsi.barrier") entry.rsiBarrier = (datetime)StringToInteger(value);
   else if(key == "entry.bb.lastSignalBarTime") entry.bbLastSignalBarTime = (datetime)StringToInteger(value);
   else if(key == "entry.bb.quarantine") entry.bbQuarantine = (bool)StringToInteger(value);
   else if(key == "entry.bb.barrier") entry.bbBarrier = (datetime)StringToInteger(value);
  }

#define FUSION_ENTRY_STATE_FIELD_COUNT 16

int FusionChartStateEntryFieldIndex(const string key)
  {
   if(key == "entry.version") return 0;
   if(key == "entry.capturedAt") return 1;
   if(key == "entry.eligible") return 2;
   if(key == "entry.ma.lastCrossTime") return 3;
   if(key == "entry.ma.lastCrossSignal") return 4;
   if(key == "entry.ma.candlesAfterCross") return 5;
   if(key == "entry.ma.lastCheckBarTime") return 6;
   if(key == "entry.ma.pendingObserved") return 7;
   if(key == "entry.ma.quarantine") return 8;
   if(key == "entry.ma.barrier") return 9;
   if(key == "entry.rsi.lastSignalBarTime") return 10;
   if(key == "entry.rsi.quarantine") return 11;
   if(key == "entry.rsi.barrier") return 12;
   if(key == "entry.bb.lastSignalBarTime") return 13;
   if(key == "entry.bb.quarantine") return 14;
   if(key == "entry.bb.barrier") return 15;
   return -1;
  }

//--- Sanidade do CONTEUDO, depois da estrutural. Devolve "" quando o bloco
//--- pode ser considerado para continuidade.
//---
//--- ⚠ Nao decide elegibilidade nem janela de tempo: isso e do chamador, que
//--- conhece o relogio e o contexto. Aqui so se recusa o que e impossivel.
string FusionValidateEntryStateSnapshot(const SEntryStateSnapshot &entry)
  {
   if(entry.version != FUSION_ENTRY_STATE_VERSION)
      return "versao do bloco de entrada desconhecida";
   if(entry.capturedAt <= 0)
      return "horario de captura invalido";

   if(entry.maLastCrossSignal != (int)SIGNAL_NONE &&
      entry.maLastCrossSignal != (int)SIGNAL_BUY &&
      entry.maLastCrossSignal != (int)SIGNAL_SELL)
      return "direcao pendente da MA Cross invalida";

   //--- ⚠ INVARIANTE GERAL: o contador so pode ser ZERO, com ou sem pendencia.
   //--- Ele nunca sobrevive a um evento — ao chegar a 1, o proprio
   //--- GetEntrySignal dispara e chama ResetEntryTracking antes de devolver o
   //--- controle; e se a quarentena recusar o disparo, ela tambem o zera. Fora
   //--- do modo `Segundo candle` ele sequer e incrementado. Qualquer valor
   //--- diferente de zero, portanto, e estado que o motor nao consegue produzir.
   if(entry.maCandlesAfterCross != 0)
      return "contador de candles da MA Cross fora do dominio observavel";

   if(entry.maLastCrossTime < 0 || entry.maLastCheckBarTime < 0 ||
      entry.rsiLastSignalBarTime < 0 || entry.bbLastSignalBarTime < 0 ||
      entry.maBarrier < 0 || entry.rsiBarrier < 0 || entry.bbBarrier < 0)
      return "timestamp negativo no bloco de entrada";

   //--- Coerencia da pendencia da MA, nos DOIS sentidos.
   //---
   //--- ⚠ `m_lastCrossSignal` so fica preenchido enquanto uma espera de segundo
   //--- candle esta armada: no modo `Candle seguinte` ele e limpo no mesmo
   //--- GetEntrySignal que o produziu. Entao, ENTRE eventos, direcao pendente e
   //--- pendencia observada sao a mesma coisa — um sem o outro e estado que o
   //--- motor nao consegue gerar, e aceita-lo seria importar ficcao.
   if(entry.maPendingObserved)
     {
      if(entry.maLastCrossSignal == (int)SIGNAL_NONE)
         return "pendencia da MA Cross sem direcao";
      if(entry.maLastCrossTime <= 0)
         return "pendencia da MA Cross sem candle do cruzamento";
      if(entry.maLastCheckBarTime <= 0)
         return "pendencia da MA Cross sem candle de referencia";
     }
   else if(entry.maLastCrossSignal != (int)SIGNAL_NONE)
      return "direcao pendente da MA Cross sem pendencia observada";

   return "";
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
