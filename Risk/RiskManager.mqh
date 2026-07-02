#ifndef __FUSION_RISK_MANAGER_MQH__
#define __FUSION_RISK_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"

class CRiskManager
  {
private:
   CLogger *m_logger;

   double   NormalizeVolumeToSpec(const double volume,const SSymbolSpec &spec) const
     {
      if(spec.volumeStep <= 0.0)
         return volume;

      double normalized = MathRound(volume / spec.volumeStep) * spec.volumeStep;
      normalized = MathMax(spec.volumeMin, normalized);
      normalized = MathMin(spec.volumeMax, normalized);

      double temp = spec.volumeStep;
      int digits = 0;
      while(digits < 8 && MathAbs(temp - MathRound(temp)) > 0.0000001)
        {
         temp *= 10.0;
         digits++;
        }

      return NormalizeDouble(normalized, digits);
     }

   bool     PartialVolumePlanValid(const SRiskPlan &plan,const double reserved,const SSymbolSpec &spec) const
     {
      if(spec.volumeMin <= 0.0)
         return false;
      if(reserved <= 0.0)
         return false;
      if((plan.volume - reserved) + 0.0000001 < spec.volumeMin)
         return false;
      return true;
     }

   bool     CurrentPrices(const SSymbolSpec &spec,double &bid,double &ask) const
     {
      bid = 0.0;
      ask = 0.0;
      if(spec.symbol == "")
         return false;

      bid = SymbolInfoDouble(spec.symbol, SYMBOL_BID);
      ask = SymbolInfoDouble(spec.symbol, SYMBOL_ASK);
      return (bid > 0.0 && ask > 0.0 && ask >= bid);
     }

   double   CurrentSpreadPoints(const SSymbolSpec &spec,const double bid,const double ask) const
     {
      if(spec.point <= 0.0)
         return 0.0;
      return MathMax(0.0, (ask - bid) / spec.point);
     }

   double   StopLossDistancePoints(const SEASettings &settings,const double spreadPoints) const
     {
      if(settings.fixedSLPoints <= 0)
         return 0.0;

      double distance = (double)settings.fixedSLPoints;
      if(settings.compensateSLSpread)
         distance += spreadPoints;
      return distance;
     }

   double   TakeProfitDistancePoints(const SEASettings &settings,const double spreadPoints) const
     {
      if(settings.fixedTPPoints <= 0)
         return 0.0;

      double distance = (double)settings.fixedTPPoints;
      if(settings.compensateTPSpread)
         distance -= spreadPoints;
      return distance;
     }

   string   RuntimeStopsDetail(const SEASettings &settings,
                               const double spreadPoints,
                               const string reason) const
     {
      bool slIssue = (StringFind(reason, "SL ") == 0);
      string levelName = slIssue ? "SL" : "TP";
      int configuredPoints = slIssue ? settings.fixedSLPoints : settings.fixedTPPoints;
      return levelName + " " + IntegerToString(configuredPoints) +
             " pts | Spread " + DoubleToString(spreadPoints, 1) +
             " pts | " + reason;
     }

   bool     PlannedStopsAllowed(const ENUM_SIGNAL_TYPE signal,
                                const SSymbolSpec &spec,
                                const double bid,
                                const double ask,
                                const double stopLoss,
                                const double takeProfit,
                                string &reason) const
     {
     reason = "";
      if(spec.point <= 0.0 || bid <= 0.0 || ask <= 0.0)
        {
         reason = "Especificacao/preco indisponivel.";
         return false;
        }

      double slDistance = 0.0;
      double tpDistance = 0.0;

      if(signal == SIGNAL_BUY)
        {
         if(stopLoss > 0.0 && stopLoss >= bid)
           {
            reason = "SL fora do lado valido do Bid atual.";
            return false;
           }
         if(takeProfit > 0.0 && takeProfit <= bid)
           {
            reason = "TP fora do lado valido do Bid atual.";
            return false;
           }
         if(stopLoss > 0.0)
            slDistance = (bid - stopLoss) / spec.point;
         if(takeProfit > 0.0)
            tpDistance = (takeProfit - bid) / spec.point;
        }
      else
        {
         if(stopLoss > 0.0 && stopLoss <= ask)
           {
            reason = "SL fora do lado valido do Ask atual.";
            return false;
           }
         if(takeProfit > 0.0 && takeProfit >= ask)
           {
            reason = "TP fora do lado valido do Ask atual.";
            return false;
           }
         if(stopLoss > 0.0)
            slDistance = (stopLoss - ask) / spec.point;
         if(takeProfit > 0.0)
            tpDistance = (ask - takeProfit) / spec.point;
        }

      if(spec.stopsLevel <= 0)
         return true;

      if(stopLoss > 0.0 && slDistance + 0.0000001 < spec.stopsLevel)
        {
         reason = "SL abaixo do stopsLevel com spread atual.";
         return false;
        }
      if(takeProfit > 0.0 && tpDistance + 0.0000001 < spec.stopsLevel)
        {
         reason = "TP abaixo do stopsLevel com spread atual.";
         return false;
        }

      return true;
     }

public:
                     CRiskManager(void)
     {
      m_logger = NULL;
     }

   bool              Init(CLogger *logger)
     {
      m_logger = logger;
      return true;
     }

   bool              BuildEntryPlan(const ENUM_SIGNAL_TYPE signal,
                                    const SEASettings &settings,
                                    const SSymbolSpec &spec,
                                    const double entryPrice,
                                    SRiskPlan &plan,
                                    string &runtimeStopsError,
                                    string &runtimeStopsDetail)
     {
      runtimeStopsError = "";
      runtimeStopsDetail = "";
      if(settings.fixedLot <= 0.0)
        {
         if(m_logger != NULL)
            m_logger.Error("RISK", "Lote fixo deve ser maior que zero; entrada bloqueada.");
         return false;
        }

      plan.volume       = NormalizeVolumeToSpec(settings.fixedLot, spec);
      plan.stopLoss     = 0.0;
      plan.takeProfit   = 0.0;
      plan.usePartialTP = settings.usePartialTP;
      plan.tp1Price     = 0.0;
      plan.tp1Volume    = 0.0;
      plan.tp2Price     = 0.0;
      plan.tp2Volume    = 0.0;

      if(plan.volume <= 0.0)
         return false;

      double bid = 0.0;
      double ask = 0.0;
      bool pricesReady = CurrentPrices(spec, bid, ask);
      if(!pricesReady && (settings.fixedSLPoints > 0 || settings.fixedTPPoints > 0))
        {
         runtimeStopsError = "Entrada bloqueada: SL/TP sem Bid/Ask valido.";
         runtimeStopsDetail = "Bid/Ask indisponivel para validar os stops.";
         if(m_logger != NULL)
            m_logger.Warn("RISK", "SL/TP nao pode ser validado com Bid/Ask atual.");
         return false;
        }

      double direction = (signal == SIGNAL_BUY) ? 1.0 : -1.0;
      double effectiveEntryPrice = entryPrice;
      double spreadPoints = 0.0;
      if(pricesReady)
        {
         effectiveEntryPrice = (signal == SIGNAL_BUY) ? ask : bid;
         spreadPoints = CurrentSpreadPoints(spec, bid, ask);
        }

      if(settings.fixedSLPoints > 0)
        {
         double slDistance = StopLossDistancePoints(settings, spreadPoints);
         plan.stopLoss = NormalizeDouble(effectiveEntryPrice - (direction * slDistance * spec.point), spec.digits);
        }

      if(settings.fixedTPPoints > 0)
        {
         double tpDistance = TakeProfitDistancePoints(settings, spreadPoints);
         if(tpDistance <= 0.0)
           {
            runtimeStopsError = "Entrada bloqueada: TP invalido para o spread atual.";
            runtimeStopsDetail = "TP " + IntegerToString(settings.fixedTPPoints) +
                                 " pts | Spread " + DoubleToString(spreadPoints, 1) +
                                 " pts | Compensar Spread TP esta ON.";
            if(m_logger != NULL)
               m_logger.Warn("RISK", "TP fixo menor que o spread atual com compensacao ativa.");
            return false;
           }
         plan.takeProfit = NormalizeDouble(effectiveEntryPrice + (direction * tpDistance * spec.point), spec.digits);
        }

      string stopsReason = "";
      if(pricesReady && !PlannedStopsAllowed(signal, spec, bid, ask, plan.stopLoss, plan.takeProfit, stopsReason))
        {
         bool slIssue = (StringFind(stopsReason, "SL ") == 0);
         runtimeStopsError = slIssue ? "Entrada bloqueada: SL invalido no preco atual."
                                     : "Entrada bloqueada: TP invalido no preco atual.";
         runtimeStopsDetail = RuntimeStopsDetail(settings, spreadPoints, stopsReason);
         if(m_logger != NULL)
            m_logger.Warn("RISK", "SL/TP invalido para stopsLevel/spread atual: " + stopsReason);
         return false;
        }

      if(settings.usePartialTP)
        {
         double reserved = 0.0;

         if(settings.tp1.enabled)
           {
            plan.tp1Volume = NormalizeVolumeToSpec(plan.volume * (settings.tp1.percent / 100.0), spec);
            plan.tp1Price  = NormalizeDouble(effectiveEntryPrice + (direction * settings.tp1.distancePoints * spec.point), spec.digits);
            if(plan.tp1Volume <= 0.0 || plan.tp1Volume + 0.0000001 >= plan.volume)
               return false;
            reserved      += plan.tp1Volume;
           }

         if(settings.tp2.enabled)
           {
            double requested = NormalizeVolumeToSpec(plan.volume * (settings.tp2.percent / 100.0), spec);
            double remaining = plan.volume - reserved;
            if(requested <= 0.0 || remaining <= spec.volumeMin)
               return false;
            plan.tp2Volume = MathMin(requested, remaining);
            plan.tp2Price  = NormalizeDouble(effectiveEntryPrice + (direction * settings.tp2.distancePoints * spec.point), spec.digits);
            if(plan.tp2Volume <= 0.0 || plan.tp2Volume + 0.0000001 >= remaining)
               return false;
            reserved      += plan.tp2Volume;
           }

         if(!PartialVolumePlanValid(plan, reserved, spec))
            return false;
        }

      return true;
     }

   bool              CalculateBreakevenSL(const SPositionRuntimeState &state,const SEASettings &settings,const SSymbolSpec &spec,const double currentPrice,double &newSL) const
     {
      newSL = 0.0;
      if(!settings.useBreakeven || state.breakevenActive)
         return false;

      double profitPoints = 0.0;
      if(state.type == POSITION_TYPE_BUY)
         profitPoints = (currentPrice - state.entryPrice) / spec.point;
      else
         profitPoints = (state.entryPrice - currentPrice) / spec.point;

      if(profitPoints < settings.breakevenTriggerPoints)
         return false;

      if(state.type == POSITION_TYPE_BUY)
         newSL = NormalizeDouble(state.entryPrice + (settings.breakevenOffsetPoints * spec.point), spec.digits);
      else
         newSL = NormalizeDouble(state.entryPrice - (settings.breakevenOffsetPoints * spec.point), spec.digits);

      if(state.stopLoss > 0.0)
        {
         if(state.type == POSITION_TYPE_BUY && newSL <= state.stopLoss)
            return false;
         if(state.type == POSITION_TYPE_SELL && newSL >= state.stopLoss)
            return false;
        }

      return true;
     }

   bool              CalculateTrailingSL(const SPositionRuntimeState &state,const SEASettings &settings,const SSymbolSpec &spec,const double currentPrice,double &newSL) const
     {
      newSL = 0.0;
      if(!settings.useTrailing)
         return false;

      double profitPoints = 0.0;
      if(state.type == POSITION_TYPE_BUY)
         profitPoints = (currentPrice - state.entryPrice) / spec.point;
      else
         profitPoints = (state.entryPrice - currentPrice) / spec.point;

      if(profitPoints < settings.trailingStartPoints)
         return false;

      if(state.type == POSITION_TYPE_BUY)
        {
         newSL = NormalizeDouble(currentPrice - (settings.trailingStepPoints * spec.point), spec.digits);
         if(state.stopLoss > 0.0 && newSL <= state.stopLoss)
            return false;
        }
      else
        {
         newSL = NormalizeDouble(currentPrice + (settings.trailingStepPoints * spec.point), spec.digits);
         if(state.stopLoss > 0.0 && newSL >= state.stopLoss)
            return false;
        }

      return true;
     }
  };

#endif
