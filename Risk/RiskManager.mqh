#ifndef __FUSION_RISK_MANAGER_MQH__
#define __FUSION_RISK_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
//--- Fonte unica do plano de volumes do TP parcial, compartilhada com a tela.
#include "../Core/PartialVolumePlan.mqh"

class CRiskManager
  {
private:
   CLogger *m_logger;

   //--- Delega para a fonte unica. O corpo que vivia aqui era LETRA POR LETRA o
   //--- de `FusionNormalizePartialVolume` - arredondar ao passo, prender na
   //--- faixa, cortar as casas do passo. Duas copias da mesma conta so esperam
   //--- que uma delas seja corrigida sozinha.
   double   NormalizeVolumeToSpec(const double volume,const SSymbolSpec &spec) const
     {
      return FusionNormalizePartialVolume(volume, spec);
     }

   //--- ⚠ `PartialVolumePlanValid` foi REMOVIDA. Ela conferia se o plano deixava
   //--- o volume minimo aberto - regra que agora vive uma vez so, dentro de
   //--- `FusionBuildPartialVolumePlan` (FUSION_PARTIAL_PLAN_NO_MIN_LEFT).

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
         reason = "Especificação/preço indisponível.";
         return false;
        }

      double slDistance = 0.0;
      double tpDistance = 0.0;

      if(signal == SIGNAL_BUY)
        {
         if(stopLoss > 0.0 && stopLoss >= bid)
           {
            reason = "SL fora do lado válido do Bid atual.";
            return false;
           }
         if(takeProfit > 0.0 && takeProfit <= bid)
           {
            reason = "TP fora do lado válido do Bid atual.";
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
            reason = "SL fora do lado válido do Ask atual.";
            return false;
           }
         if(takeProfit > 0.0 && takeProfit >= ask)
           {
            reason = "TP fora do lado válido do Ask atual.";
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
         runtimeStopsError = "Entrada bloqueada: SL/TP sem Bid/Ask válido.";
         runtimeStopsDetail = "Bid/Ask indisponível para validar os stops.";
         if(m_logger != NULL)
            m_logger.Warn("RISK", "SL/TP não pode ser validado com Bid/Ask atual.");
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
            runtimeStopsError = "Entrada bloqueada: TP inválido para o spread atual.";
            runtimeStopsDetail = "TP " + IntegerToString(settings.fixedTPPoints) +
                                 " pts | Spread " + DoubleToString(spreadPoints, 1) +
                                 " pts | Compensar Spread TP está ON.";
            if(m_logger != NULL)
               m_logger.Warn("RISK", "TP fixo menor que o spread atual com compensação ativa.");
            return false;
           }
         plan.takeProfit = NormalizeDouble(effectiveEntryPrice + (direction * tpDistance * spec.point), spec.digits);
        }

      string stopsReason = "";
      if(pricesReady && !PlannedStopsAllowed(signal, spec, bid, ask, plan.stopLoss, plan.takeProfit, stopsReason))
        {
         bool slIssue = (StringFind(stopsReason, "SL ") == 0);
         runtimeStopsError = slIssue ? "Entrada bloqueada: SL inválido no preço atual."
                                     : "Entrada bloqueada: TP inválido no preço atual.";
         runtimeStopsDetail = RuntimeStopsDetail(settings, spreadPoints, stopsReason);
         if(m_logger != NULL)
            m_logger.Warn("RISK", "SL/TP inválido para stopsLevel/spread atual: " + stopsReason);
         return false;
        }

      //+---------------------------------------------------------------+
      //| TP PARCIAL - fonte unica, atras da PORTA GLOBAL.                |
      //|                                                                |
      //| A formula percentual que vivia aqui foi REMOVIDA, nao movida:  |
      //| ela era a segunda escrita da mesma regra que a tela ja fazia   |
      //| em `VPartialVolumePlan`, e duas escritas do mesmo criterio      |
      //| divergem. O sintoma seria a tela aprovando o que a entrada      |
      //| recusa - ou pior, o contrario.                                  |
      //|                                                                |
      //| ⚠ `settings.usePartialTP` CONTINUA SENDO A PORTA EXTERNA, como |
      //| era antes. Chamar o helper incondicionalmente e deixa-lo        |
      //| decidir por `tp1.enabled` MUDARIA O CONTRATO: um perfil com o   |
      //| global desligado e valores dormentes invalidos nos estagios era |
      //| aceito e passaria a ser BLOQUEADO. `BuildEntryPlan` e API       |
      //| publica e nao pode presumir que todo chamador ja normalizou o   |
      //| struct - a normalizacao sincroniza os dois campos, mas depender |
      //| disso implicitamente e como nao ter a guarda.                   |
      //|                                                                |
      //| Com o global desligado: nada e calculado, nada e recusado,      |
      //| nenhum motivo e publicado, e os campos parciais ficam zerados   |
      //| como ja nasceram acima.                                         |
      //+---------------------------------------------------------------+
      if(!settings.usePartialTP)
        {
         plan.usePartialTP = false;
         return true;
        }

      //--- Global ligado: daqui para baixo o helper e a UNICA autoridade, sem
      //--- fallback para a formula antiga.
      SPartialVolumePlan partial;
      if(!FusionBuildPartialVolumePlan(plan.volume, settings.partialSizeMode,
                                       settings.tp1, settings.tp2, spec, partial))
        {
         //--- ⚠ CONTRATO: plano recusado NAO deixa reserva utilizavel. Os campos
         //--- parciais ja nasceram zerados acima e continuam zerados aqui - um
         //--- valor residual de um plano invalido poderia ser copiado para o
         //--- estado da posicao e virar um fechamento parcial que ninguem pediu.
         plan.tp1Volume = 0.0; plan.tp1Price = 0.0;
         plan.tp2Volume = 0.0; plan.tp2Price = 0.0;
         plan.usePartialTP = false;

         //--- ⚠ E o motivo passa a SAIR. Antes este ramo devolvia false com
         //--- `runtimeStopsError` vazio, e o chamador so publica aviso quando ele
         //--- vem preenchido: a entrada era bloqueada em silencio, sem nada na
         //--- tela dizendo por que.
         runtimeStopsError  = "Entrada bloqueada: TP parcial inválido.";
         runtimeStopsDetail = FusionPartialPlanReason(partial.code);
         if(m_logger != NULL)
            m_logger.Warn("RISK", "Plano de TP parcial recusado: " + FusionPartialPlanReason(partial.code));
         return false;
        }

      //--- DISABLED nao e erro: e simplesmente ausencia de TP parcial. Mas com o
      //--- global LIGADO ele denuncia uma configuracao inconsistente (TP1
      //--- desligado por dentro), e ai `plan.usePartialTP` tem de cair junto:
      //--- deixa-lo verdadeiro com volumes zerados descreveria uma posicao que
      //--- espera parcial e nunca vai receber uma.
      if(partial.code != FUSION_PARTIAL_PLAN_OK)
        {
         plan.usePartialTP = false;
         return true;
        }

      plan.tp1Volume = partial.tp1Volume;
      plan.tp1Price  = NormalizeDouble(effectiveEntryPrice + (direction * settings.tp1.distancePoints * spec.point), spec.digits);

      if(partial.tp2Volume > 0.0)
        {
         plan.tp2Volume = partial.tp2Volume;
         plan.tp2Price  = NormalizeDouble(effectiveEntryPrice + (direction * settings.tp2.distancePoints * spec.point), spec.digits);
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
