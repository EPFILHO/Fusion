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

   bool              BuildEntryPlan(const ENUM_SIGNAL_TYPE signal,const SEASettings &settings,const SSymbolSpec &spec,const double entryPrice,SRiskPlan &plan)
     {
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

      double direction = (signal == SIGNAL_BUY) ? 1.0 : -1.0;

      if(settings.fixedSLPoints > 0)
         plan.stopLoss = NormalizeDouble(entryPrice - (direction * settings.fixedSLPoints * spec.point), spec.digits);

      if(settings.fixedTPPoints > 0)
         plan.takeProfit = NormalizeDouble(entryPrice + (direction * settings.fixedTPPoints * spec.point), spec.digits);

      if(settings.usePartialTP)
        {
         double reserved = 0.0;

         if(settings.tp1.enabled)
           {
            plan.tp1Volume = NormalizeVolumeToSpec(plan.volume * (settings.tp1.percent / 100.0), spec);
            plan.tp1Price  = NormalizeDouble(entryPrice + (direction * settings.tp1.distancePoints * spec.point), spec.digits);
            reserved      += plan.tp1Volume;
           }

         if(settings.tp2.enabled)
           {
            double requested = NormalizeVolumeToSpec(plan.volume * (settings.tp2.percent / 100.0), spec);
            double remaining = MathMax(spec.volumeMin, plan.volume - reserved);
            plan.tp2Volume = MathMin(requested, remaining);
            plan.tp2Price  = NormalizeDouble(entryPrice + (direction * settings.tp2.distancePoints * spec.point), spec.digits);
           }
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
