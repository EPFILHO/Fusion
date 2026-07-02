#ifndef __FUSION_EXECUTION_SERVICE_MQH__
#define __FUSION_EXECUTION_SERVICE_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "TradeRequestRecorder.mqh"
#include "../Normalization/SymbolNormalizer.mqh"

class CExecutionService
  {
private:
   CLogger           *m_logger;
   CSymbolNormalizer *m_normalizer;
   string             m_symbol;
   int                m_magicNumber;
   int                m_slippagePoints;
   bool               m_needsSync;
   bool               m_lastModifySkippedByFreeze;
   string             m_lastFreezeSkipReason;
   datetime           m_lastFreezeSkipTime;
   bool               m_lastModifySkippedByStopsLevel;
   datetime           m_lastStopsLevelSkipTime;
   CTradeRequestRecorder m_tradeRequestRecorder;
   bool               m_tradeRequestRecordWarningShown;

   string             TrimComment(const string text) const
     {
      int start = 0;
      int end = StringLen(text) - 1;

      while(start <= end)
        {
         ushort ch = StringGetCharacter(text, start);
         if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
            break;
         start++;
        }

      while(end >= start)
        {
         ushort ch = StringGetCharacter(text, end);
         if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
            break;
         end--;
        }

      if(end < start)
         return "";
      return StringSubstr(text, start, end - start + 1);
     }

   string             OrderComment(const string reason) const
     {
      string trimmed = TrimComment(reason);
      if(StringFind(trimmed, "EP Fusion - ") == 0)
         return trimmed;
      if(trimmed == "")
         return "EP Fusion";
      return "EP Fusion - " + trimmed;
     }

   double             CurrentClosePrice(const ENUM_POSITION_TYPE type) const
     {
      if(type == POSITION_TYPE_BUY)
         return SymbolInfoDouble(m_symbol, SYMBOL_BID);
      return SymbolInfoDouble(m_symbol, SYMBOL_ASK);
     }

   bool               LevelInsideFreeze(const double level,
                                        const double currentPrice,
                                        const SSymbolSpec &spec,
                                        double &distancePoints) const
     {
      distancePoints = 0.0;
      if(level <= 0.0)
         return false;
      if(currentPrice <= 0.0 || spec.point <= 0.0 || spec.freezeLevel <= 0)
         return false;

      distancePoints = MathAbs(level - currentPrice) / spec.point;
      return (distancePoints + 0.0000001 < spec.freezeLevel);
     }

   bool               StopsInsideFreeze(const SPositionRuntimeState &state,
                                        const double newSL,
                                        const double newTP,
                                        string &reason) const
     {
      reason = "";
      if(m_normalizer == NULL)
         return false;

      SSymbolSpec spec;
      m_normalizer.GetSpec(spec);
      if(spec.freezeLevel <= 0)
         return false;

      double currentPrice = CurrentClosePrice(state.type);
      if(currentPrice <= 0.0 || spec.point <= 0.0)
        {
         reason = "preco atual indisponivel para validar freezeLevel.";
         return true;
        }

      double distancePoints = 0.0;
      if(LevelInsideFreeze(state.stopLoss, currentPrice, spec, distancePoints))
        {
         reason = "SL atual a " + DoubleToString(distancePoints, 1) +
                  " pts do preco; freezeLevel=" + IntegerToString(spec.freezeLevel) + " pts.";
         return true;
        }
      if(LevelInsideFreeze(state.takeProfit, currentPrice, spec, distancePoints))
        {
         reason = "TP atual a " + DoubleToString(distancePoints, 1) +
                  " pts do preco; freezeLevel=" + IntegerToString(spec.freezeLevel) + " pts.";
         return true;
        }
      if(LevelInsideFreeze(newSL, currentPrice, spec, distancePoints))
        {
         reason = "novo SL a " + DoubleToString(distancePoints, 1) +
                  " pts do preco; freezeLevel=" + IntegerToString(spec.freezeLevel) + " pts.";
         return true;
        }
      if(LevelInsideFreeze(newTP, currentPrice, spec, distancePoints))
        {
         reason = "novo TP a " + DoubleToString(distancePoints, 1) +
                  " pts do preco; freezeLevel=" + IntegerToString(spec.freezeLevel) + " pts.";
         return true;
        }

      return false;
     }

   bool               StopsInvalidForStopsLevel(const SPositionRuntimeState &state,
                                                 const double newSL,
                                                 const double newTP,
                                                 string &reason) const
     {
      reason = "";
      if(m_normalizer == NULL)
         return false;

      SSymbolSpec spec;
      m_normalizer.GetSpec(spec);
      if(spec.stopsLevel <= 0)
         return false;

      double currentPrice = CurrentClosePrice(state.type);
      if(currentPrice <= 0.0 || spec.point <= 0.0)
        {
         reason = "preco atual indisponivel para validar stopsLevel.";
         return true;
        }

      double slDistance = 0.0;
      double tpDistance = 0.0;
      if(state.type == POSITION_TYPE_BUY)
        {
         if(newSL > 0.0)
            slDistance = (currentPrice - newSL) / spec.point;
         if(newTP > 0.0)
            tpDistance = (newTP - currentPrice) / spec.point;
        }
      else
        {
         if(newSL > 0.0)
            slDistance = (newSL - currentPrice) / spec.point;
         if(newTP > 0.0)
            tpDistance = (currentPrice - newTP) / spec.point;
        }

      if(newSL > 0.0 && slDistance < -0.0000001)
        {
         reason = "SL solicitado esta do lado invalido do preco atual.";
         return true;
        }
      if(newTP > 0.0 && tpDistance < -0.0000001)
        {
         reason = "TP solicitado esta do lado invalido do preco atual.";
         return true;
        }
      if(newSL > 0.0 && slDistance + 0.0000001 < spec.stopsLevel)
        {
         reason = "SL solicitado a " + DoubleToString(slDistance, 1) +
                  " pts do preco; stopsLevel=" + IntegerToString(spec.stopsLevel) + " pts.";
         return true;
        }
      if(newTP > 0.0 && tpDistance + 0.0000001 < spec.stopsLevel)
        {
         reason = "TP solicitado a " + DoubleToString(tpDistance, 1) +
                  " pts do preco; stopsLevel=" + IntegerToString(spec.stopsLevel) + " pts.";
         return true;
        }

      return false;
     }

   void               LogFreezeSkip(const string reason)
     {
      datetime now = TimeCurrent();
      if(now <= 0)
         now = TimeLocal();

      if(reason == m_lastFreezeSkipReason &&
         m_lastFreezeSkipTime > 0 &&
         now - m_lastFreezeSkipTime < 60)
         return;

      m_lastFreezeSkipReason = reason;
      m_lastFreezeSkipTime = now;

      if(m_logger != NULL)
         m_logger.Debug("RISK", "SL/TP dentro do freezeLevel; nova tentativa no proximo tick. " + reason);
     }

   void               LogStopsLevelSkip(const string reason)
     {
      datetime now = TimeCurrent();
      if(now <= 0)
         now = TimeLocal();

      if(m_lastStopsLevelSkipTime > 0 &&
         now - m_lastStopsLevelSkipTime < 60)
         return;

      m_lastStopsLevelSkipTime = now;

      if(m_logger != NULL)
         m_logger.Debug("RISK", "SL/TP nao atende stopsLevel; nova tentativa no proximo tick. " + reason);
     }

   void               RecordTradeRequest(const string eventName,
                                         const MqlTradeRequest &request,
                                         const MqlTradeResult &result,
                                         const bool orderSendOk,
                                         const int terminalError)
     {
      if(m_tradeRequestRecorder.Record(eventName, request, result, orderSendOk, terminalError) ||
         m_tradeRequestRecordWarningShown)
         return;

      m_tradeRequestRecordWarningShown = true;
      if(m_logger != NULL)
         m_logger.Warn("EXEC_AUDIT", "Nao foi possivel gravar o diagnostico CSV. Erro " +
                       IntegerToString(m_tradeRequestRecorder.LastError()) + ".");
     }

   bool               TryGetDealProfit(const ulong dealTicket,double &profit) const
     {
      profit = 0.0;
      if(dealTicket == 0)
         return false;
      if(!HistoryDealSelect(dealTicket))
         return false;

      profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      return true;
     }

   bool               IsPositionIdentifierOpen(const ulong positionId) const
     {
      if(positionId == 0)
         return false;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(PositionGetSymbol(i) == "")
            continue;
         if((ulong)PositionGetInteger(POSITION_IDENTIFIER) == positionId)
            return true;
        }
      return false;
     }

   void               CopyRuntimeState(const SPositionRuntimeState &source,SPositionRuntimeState &target) const
     {
      target.ownerStrategyId       = source.ownerStrategyId;
      target.ownerStrategyName     = source.ownerStrategyName;
      target.tp1Executed           = source.tp1Executed;
      target.tp2Executed           = source.tp2Executed;
      target.breakevenActive       = source.breakevenActive;
      target.trailingActive        = source.trailingActive;
      target.realizedPartialProfit = source.realizedPartialProfit;
      target.tp1Price              = source.tp1Price;
      target.tp1Volume             = source.tp1Volume;
      target.tp2Price              = source.tp2Price;
      target.tp2Volume             = source.tp2Volume;
      target.dayPeakProjectedProfit= source.dayPeakProjectedProfit;
     }

public:
                     CExecutionService(void)
     {
      m_logger         = NULL;
      m_normalizer     = NULL;
      m_symbol         = "";
      m_magicNumber    = 0;
      m_slippagePoints = 0;
      m_needsSync      = false;
      m_lastModifySkippedByFreeze = false;
      m_lastFreezeSkipReason = "";
      m_lastFreezeSkipTime = 0;
      m_lastModifySkippedByStopsLevel = false;
      m_lastStopsLevelSkipTime = 0;
      m_tradeRequestRecordWarningShown = false;
     }

   bool              Init(CLogger *logger,CSymbolNormalizer *normalizer,const string symbol,const SEASettings &settings)
     {
      m_logger         = logger;
      m_normalizer     = normalizer;
      m_symbol         = symbol;
      m_magicNumber    = settings.magicNumber;
      m_slippagePoints = settings.slippagePoints;
      m_needsSync      = false;
      m_lastModifySkippedByFreeze = false;
      m_lastFreezeSkipReason = "";
      m_lastFreezeSkipTime = 0;
      m_lastModifySkippedByStopsLevel = false;
      m_lastStopsLevelSkipTime = 0;
      m_tradeRequestRecorder.Init(m_symbol, m_magicNumber);
      m_tradeRequestRecordWarningShown = false;
      return true;
     }

   void              Reload(const SEASettings &settings)
     {
      m_magicNumber    = settings.magicNumber;
      m_slippagePoints = settings.slippagePoints;
      m_needsSync      = true;
      m_lastModifySkippedByFreeze = false;
      m_lastModifySkippedByStopsLevel = false;
      m_tradeRequestRecorder.Init(m_symbol, m_magicNumber);
     }

   void              MarkNeedsSync(void)
     {
      m_needsSync = true;
     }

   bool              NeedsSync(void) const
     {
      return m_needsSync;
     }

   bool              LastModifySkippedByFreeze(void) const
     {
      return m_lastModifySkippedByFreeze;
     }

   bool              LastModifySkippedByStopsLevel(void) const
     {
      return m_lastModifySkippedByStopsLevel;
     }

   bool              SyncPosition(SPositionRuntimeState &state)
     {
      SPositionRuntimeState previous = state;
      ResetPositionRuntimeState(state);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(PositionGetSymbol(i) != m_symbol)
            continue;

         if((int)PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
            continue;

         state.hasPosition = true;
         state.ticket      = (ulong)PositionGetInteger(POSITION_TICKET);
         state.positionId  = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
         state.type        = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         state.symbol      = m_symbol;
         state.entryPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
         state.volume      = PositionGetDouble(POSITION_VOLUME);
         state.stopLoss    = PositionGetDouble(POSITION_SL);
         state.takeProfit  = PositionGetDouble(POSITION_TP);

         if(previous.positionId == state.positionId)
            CopyRuntimeState(previous, state);
         else if(!previous.hasPosition && previous.positionId == 0 && previous.ownerStrategyId != "")
            CopyRuntimeState(previous, state);

         m_needsSync = false;
         return true;
        }

      m_needsSync = false;
      return false;
     }

   bool              PlaceEntry(const ENUM_SIGNAL_TYPE signal,const SRiskPlan &plan,const SSignalDecision &decision,SPositionRuntimeState &state)
     {
      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};
      SSymbolSpec     spec;
      m_normalizer.GetSpec(spec);

      request.action       = TRADE_ACTION_DEAL;
      request.symbol       = m_symbol;
      request.magic        = m_magicNumber;
      request.deviation    = m_slippagePoints;
      request.type_filling = m_normalizer.ResolveFillingMode();
      request.volume       = plan.volume;
      request.type         = (signal == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      request.price        = (signal == SIGNAL_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK)
                                                    : SymbolInfoDouble(m_symbol, SYMBOL_BID);
      request.sl           = plan.stopLoss;
      request.tp           = plan.takeProfit;
      request.comment      = OrderComment(decision.shortName);

      ResetLastError();
      bool orderSendOk = OrderSend(request, result);
      int terminalError = orderSendOk ? 0 : GetLastError();
      RecordTradeRequest("ENTRY", request, result, orderSendOk, terminalError);
      if(!orderSendOk)
        {
         if(m_logger != NULL)
            m_logger.Error("EXEC", "OrderSend failed on entry");
         return false;
        }

      if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
        {
         if(m_logger != NULL)
            m_logger.Error("EXEC", "Entry retcode " + IntegerToString((int)result.retcode));
         return false;
        }

      state.ownerStrategyId    = decision.strategyId;
      state.ownerStrategyName  = decision.strategyName;
      state.tp1Price           = plan.tp1Price;
      state.tp1Volume          = plan.tp1Volume;
      state.tp2Price           = plan.tp2Price;
      state.tp2Volume          = plan.tp2Volume;
      state.realizedPartialProfit = 0.0;
      m_needsSync = true;

      if(m_logger != NULL)
         m_logger.Trade("EXEC", "Entry sent by " + decision.strategyName + " (" + SignalToString(signal) + ")");

      return true;
     }

   bool              ClosePosition(const SPositionRuntimeState &state,const string reason)
     {
      if(!state.hasPosition)
         return false;

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};

      request.action       = TRADE_ACTION_DEAL;
      request.position     = state.ticket;
      request.symbol       = m_symbol;
      request.magic        = m_magicNumber;
      request.deviation    = m_slippagePoints;
      request.type_filling = m_normalizer.ResolveFillingMode();
      request.volume       = state.volume;
      request.type         = (state.type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price        = CurrentClosePrice(state.type);
      request.comment      = OrderComment(reason);

      ResetLastError();
      bool orderSendOk = OrderSend(request, result);
      int terminalError = orderSendOk ? 0 : GetLastError();
      RecordTradeRequest("FULL_CLOSE", request, result, orderSendOk, terminalError);
      if(!orderSendOk)
        {
         if(m_logger != NULL)
            m_logger.Error("EXEC", "Failed to close position");
         return false;
        }

      if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
        {
         if(m_logger != NULL)
            m_logger.Error("EXEC", "Close retcode " + IntegerToString((int)result.retcode));
         return false;
        }

      m_needsSync = true;
      return true;
     }

   bool              PartialClose(SPositionRuntimeState &state,const double lotToClose,const string reason,double &estimatedProfit)
     {
      estimatedProfit = 0.0;
      if(!state.hasPosition || lotToClose <= 0.0 || lotToClose >= state.volume)
         return false;

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};

      request.action       = TRADE_ACTION_DEAL;
      request.position     = state.ticket;
      request.symbol       = m_symbol;
      request.magic        = m_magicNumber;
      request.deviation    = m_slippagePoints;
      request.type_filling = m_normalizer.ResolveFillingMode();
      request.volume       = lotToClose;
      request.type         = (state.type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price        = CurrentClosePrice(state.type);
      request.comment      = OrderComment(reason);

      ResetLastError();
      bool orderSendOk = OrderSend(request, result);
      int terminalError = orderSendOk ? 0 : GetLastError();
      RecordTradeRequest("PARTIAL_CLOSE", request, result, orderSendOk, terminalError);
      if(!orderSendOk)
         return false;

      if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
         return false;

      if(!TryGetDealProfit(result.deal, estimatedProfit))
        {
         ENUM_ORDER_TYPE closeType = (state.type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         if(!OrderCalcProfit(closeType, m_symbol, lotToClose, state.entryPrice, request.price, estimatedProfit))
            estimatedProfit = 0.0;
        }
      m_needsSync = true;
      return true;
     }

   bool              ModifyStops(SPositionRuntimeState &state,const double newSL,const double newTP)
     {
      m_lastModifySkippedByFreeze = false;
      m_lastModifySkippedByStopsLevel = false;
      if(!state.hasPosition)
         return false;

      string freezeReason = "";
      if(StopsInsideFreeze(state, newSL, newTP, freezeReason))
        {
         m_lastModifySkippedByFreeze = true;
         LogFreezeSkip(freezeReason);
         return false;
        }

      string stopsLevelReason = "";
      if(StopsInvalidForStopsLevel(state, newSL, newTP, stopsLevelReason))
        {
         m_lastModifySkippedByStopsLevel = true;
         LogStopsLevelSkip(stopsLevelReason);
         return false;
        }

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};

      request.action   = TRADE_ACTION_SLTP;
      request.position = state.ticket;
      request.symbol   = m_symbol;
      request.sl       = newSL;
      request.tp       = newTP;

      if(!OrderSend(request, result))
         return false;

      if(result.retcode != TRADE_RETCODE_DONE)
         return false;

      state.stopLoss   = newSL;
      state.takeProfit = newTP;
      return true;
     }

   bool              GetClosedTradeSummary(const ulong positionId,SClosedTradeSummary &summary)
     {
      summary.found       = false;
      summary.complete    = false;
      summary.contextMatched = false;
      summary.totalProfit = 0.0;
      summary.finalProfit = 0.0;
      summary.entryVolume = 0.0;
      summary.exitVolume  = 0.0;
      summary.exitDeals   = 0;
      summary.lastExitTime= 0;

      if(positionId == 0)
         return false;

      if(!HistorySelectByPosition(positionId))
         return false;

      datetime lastExitTime = 0;

      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;

         if((ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID) != positionId)
            continue;

         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         if(entryType == DEAL_ENTRY_IN)
           {
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) == m_symbol &&
               (int)HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_magicNumber)
               summary.contextMatched = true;
            summary.entryVolume += volume;
            continue;
           }

         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY)
            continue;

         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);

         summary.found = true;
         summary.totalProfit += profit;
         summary.exitVolume += volume;
         summary.exitDeals++;

         if(dealTime >= lastExitTime)
           {
            lastExitTime = dealTime;
            summary.lastExitTime = dealTime;
            summary.finalProfit = profit;
           }
        }

      double volumeStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      double tolerance = MathMax(volumeStep * 0.1, 0.00000001);
      summary.complete = (summary.found &&
                          summary.entryVolume > 0.0 &&
                          summary.exitVolume + tolerance >= summary.entryVolume);
      return summary.found;
     }

   bool              GetDailyHistorySummary(const datetime dayStart,
                                             const datetime now,
                                             const int dayKey,
                                             SDailyHistorySummary &summary)
     {
      summary.complete = false;
      summary.dayKey = dayKey;
      summary.closedProfit = 0.0;
      summary.tradeCount = 0;
      summary.lossCount = 0;
      summary.winCount = 0;
      summary.breakevenCount = 0;
      summary.lossStreak = 0;
      summary.winStreak = 0;

      if(dayStart <= 0 || now < dayStart || !HistorySelect(dayStart, now))
         return false;

      ulong positionIds[];
      double dayProfits[];
      int positionCount = 0;

      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetString(ticket, DEAL_SYMBOL) != m_symbol)
            continue;

         long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY)
            continue;

         ulong positionId = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         if(positionId == 0)
            continue;

         int positionIndex = -1;
         for(int index = 0; index < positionCount; index++)
           {
            if(positionIds[index] == positionId)
              {
               positionIndex = index;
               break;
              }
           }

         if(positionIndex < 0)
           {
            positionIndex = positionCount++;
            ArrayResize(positionIds, positionCount);
            ArrayResize(dayProfits, positionCount);
            positionIds[positionIndex] = positionId;
            dayProfits[positionIndex] = 0.0;
           }
         dayProfits[positionIndex] += HistoryDealGetDouble(ticket, DEAL_PROFIT);
        }

      double closedProfits[];
      datetime closeTimes[];
      int closedCount = 0;

      for(int positionIndex = 0; positionIndex < positionCount; positionIndex++)
        {
         SClosedTradeSummary positionSummary;
         if(!GetClosedTradeSummary(positionIds[positionIndex], positionSummary))
            return false;
         if(!positionSummary.contextMatched)
            continue;

         summary.closedProfit += dayProfits[positionIndex];
         if(!positionSummary.complete)
           {
            if(!IsPositionIdentifierOpen(positionIds[positionIndex]))
               return false;
            continue;
           }

         if(positionSummary.lastExitTime < dayStart || positionSummary.lastExitTime > now)
            continue;

         ArrayResize(closedProfits, closedCount + 1);
         ArrayResize(closeTimes, closedCount + 1);
         closedProfits[closedCount] = positionSummary.totalProfit;
         closeTimes[closedCount] = positionSummary.lastExitTime;
         closedCount++;
        }

      for(int left = 0; left < closedCount - 1; left++)
        {
         for(int right = left + 1; right < closedCount; right++)
           {
            if(closeTimes[left] <= closeTimes[right])
               continue;
            datetime timeSwap = closeTimes[left];
            closeTimes[left] = closeTimes[right];
            closeTimes[right] = timeSwap;
            double profitSwap = closedProfits[left];
            closedProfits[left] = closedProfits[right];
            closedProfits[right] = profitSwap;
           }
        }

      for(int closedIndex = 0; closedIndex < closedCount; closedIndex++)
        {
         double profit = closedProfits[closedIndex];
         summary.tradeCount++;
         if(profit > 0.0)
           {
            summary.winCount++;
            summary.winStreak++;
            summary.lossStreak = 0;
           }
         else if(profit < 0.0)
           {
            summary.lossCount++;
            summary.lossStreak++;
            summary.winStreak = 0;
           }
         else
            summary.breakevenCount++;
        }

      summary.complete = true;
      return true;
     }
  };

#endif
