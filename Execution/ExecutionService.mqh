#ifndef __FUSION_EXECUTION_SERVICE_MQH__
#define __FUSION_EXECUTION_SERVICE_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
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

   double             CurrentClosePrice(const ENUM_POSITION_TYPE type) const
     {
      if(type == POSITION_TYPE_BUY)
         return SymbolInfoDouble(m_symbol, SYMBOL_BID);
      return SymbolInfoDouble(m_symbol, SYMBOL_ASK);
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
     }

   bool              Init(CLogger *logger,CSymbolNormalizer *normalizer,const string symbol,const SEASettings &settings)
     {
      m_logger         = logger;
      m_normalizer     = normalizer;
      m_symbol         = symbol;
      m_magicNumber    = settings.magicNumber;
      m_slippagePoints = settings.slippagePoints;
      m_needsSync      = false;
      return true;
     }

   void              Reload(const SEASettings &settings)
     {
      m_magicNumber    = settings.magicNumber;
      m_slippagePoints = settings.slippagePoints;
      m_needsSync      = true;
     }

   void              MarkNeedsSync(void)
     {
      m_needsSync = true;
     }

   bool              NeedsSync(void) const
     {
      return m_needsSync;
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
      request.comment      = "EA " + decision.shortName;

      if(!OrderSend(request, result))
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
      request.comment      = reason;

      if(!OrderSend(request, result))
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
      request.comment      = reason;

      if(!OrderSend(request, result))
         return false;

      if(result.retcode != TRADE_RETCODE_DONE && result.retcode != TRADE_RETCODE_PLACED)
         return false;

      ENUM_ORDER_TYPE closeType = (state.type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      if(!OrderCalcProfit(closeType, m_symbol, lotToClose, state.entryPrice, request.price, estimatedProfit))
         estimatedProfit = 0.0;
      m_needsSync = true;
      return true;
     }

   bool              ModifyStops(SPositionRuntimeState &state,const double newSL,const double newTP)
     {
      if(!state.hasPosition)
         return false;

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
      summary.totalProfit = 0.0;
      summary.finalProfit = 0.0;
      summary.exitDeals   = 0;

      if(positionId == 0)
         return false;

      if(!HistorySelect(0, TimeCurrent()))
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
         if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY)
            continue;

         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);

         summary.found = true;
         summary.totalProfit += profit;
         summary.exitDeals++;

         if(dealTime >= lastExitTime)
           {
            lastExitTime = dealTime;
            summary.finalProfit = profit;
           }
        }

      return summary.found;
     }
  };

#endif
