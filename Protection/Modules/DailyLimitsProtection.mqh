#ifndef __FUSION_DAILY_LIMITS_PROTECTION_MQH__
#define __FUSION_DAILY_LIMITS_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CDailyLimitsProtection : public CProtectionModuleBase
  {
private:
   int         m_dayKey;
   int         m_dailyTradeCount;
   double      m_dailyClosedProfit;
   bool        m_tradesLimitReached;
   bool        m_lossLimitReached;
   bool        m_gainLimitReached;

   bool              UsesDrawdownActivation(void) const
     {
      return (m_settings.profitTargetAction == PROFIT_ACTION_ATIVAR_DD &&
              m_settings.enableDrawdown &&
              m_settings.maxDrawdown > 0.0 &&
              m_settings.maxDailyGain > 0.0);
     }

   void              ResetDailyState(void)
     {
      m_dailyTradeCount = 0;
      m_dailyClosedProfit = 0.0;
      m_tradesLimitReached = false;
      m_lossLimitReached = false;
      m_gainLimitReached = false;
     }

   bool              CurrentBlockReason(string &reason) const
     {
      reason = "";
      if(m_lossLimitReached)
        {
         reason = "Limite diario de perda atingido.";
         return true;
        }

      if(m_gainLimitReached)
        {
         reason = "Meta diaria de ganho atingida.";
         return true;
        }

      if(m_tradesLimitReached)
        {
         reason = "Limite diario de trades atingido.";
         return true;
        }

      return false;
     }

   void              UpdateLatchedLimits(void)
     {
      if(!m_settings.enableDailyLimits)
         return;

      if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
         m_tradesLimitReached = true;

      if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
         m_lossLimitReached = true;

      if(m_settings.maxDailyGain > 0.0 &&
         m_dailyClosedProfit >= m_settings.maxDailyGain &&
         !UsesDrawdownActivation())
         m_gainLimitReached = true;
     }

public:
                     CDailyLimitsProtection(void)
     {
      m_dayKey = 0;
      ResetDailyState();
     }

   bool              Init(const SEASettings &settings)
     {
      CProtectionModuleBase::Init(settings);
      m_dayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      return true;
     }

   bool              ResetIfNewDay(void)
     {
      int currentKey = FusionProtectionCurrentDayKey(TimeCurrent());
      if(currentKey == m_dayKey)
         return false;

      m_dayKey = currentKey;
      ResetDailyState();
      return true;
     }

   void              ExportState(SDailyLimitsRuntimeState &state) const
     {
      state.dayKey = m_dayKey;
      state.dailyTradeCount = m_dailyTradeCount;
      state.dailyClosedProfit = m_dailyClosedProfit;
      state.tradesLimitReached = m_tradesLimitReached;
      state.lossLimitReached = m_lossLimitReached;
      state.gainLimitReached = m_gainLimitReached;
     }

   void              ImportState(const SDailyLimitsRuntimeState &state)
     {
      int currentDayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      if(state.dayKey != currentDayKey)
        {
         m_dayKey = currentDayKey;
         ResetDailyState();
         return;
        }

      m_dayKey = state.dayKey;
      m_dailyTradeCount = (state.dailyTradeCount < 0) ? 0 : state.dailyTradeCount;
      m_dailyClosedProfit = state.dailyClosedProfit;
      m_tradesLimitReached = state.tradesLimitReached;
      m_lossLimitReached = state.lossLimitReached;
      m_gainLimitReached = state.gainLimitReached;
      UpdateLatchedLimits();
     }

   bool              CanOpen(string &reason,bool &activateDrawdown)
     {
      reason = "";
      activateDrawdown = false;

      if(CurrentBlockReason(reason))
         return false;

      if(!m_settings.enableDailyLimits)
         return true;

      if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
        {
         m_tradesLimitReached = true;
         reason = "Limite diario de trades atingido.";
         return false;
        }

      if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
        {
         m_lossLimitReached = true;
         reason = "Limite diario de perda atingido.";
         return false;
        }

      if(m_settings.maxDailyGain > 0.0 && m_dailyClosedProfit >= m_settings.maxDailyGain)
        {
         if(UsesDrawdownActivation())
           {
            activateDrawdown = true;
            return true;
           }

         reason = "Meta diaria de ganho atingida.";
         m_gainLimitReached = true;
         return false;
        }

      return true;
     }

   bool              ShouldForceClose(const double floatingProfit,string &reason,bool &activateDrawdown,double &projectedProfit)
     {
      reason = "";
      activateDrawdown = false;
      projectedProfit = m_dailyClosedProfit + floatingProfit;

      if(CurrentBlockReason(reason))
         return false;

      if(!m_settings.enableDailyLimits)
         return false;

      if(m_settings.maxDailyLoss > 0.0 && projectedProfit <= -m_settings.maxDailyLoss)
        {
         m_lossLimitReached = true;
         reason = "Limite diario de perda projetada atingido.";
         return true;
        }

      if(m_settings.maxDailyGain > 0.0 && projectedProfit >= m_settings.maxDailyGain)
        {
         if(UsesDrawdownActivation())
           {
            activateDrawdown = true;
            return false;
           }

         reason = "Meta diaria de ganho atingida.";
         m_gainLimitReached = true;
         return true;
        }

      return false;
     }

   void              OnPartialRealized(const double profit)
     {
      m_dailyClosedProfit += profit;
      UpdateLatchedLimits();
     }

   void              OnPositionClosed(const double totalPositionProfit,const double realizedPartialProfit)
     {
      double finalPortion = totalPositionProfit - realizedPartialProfit;
      m_dailyClosedProfit += finalPortion;
      m_dailyTradeCount++;
      UpdateLatchedLimits();
     }

   int               DailyTradeCount(void) const
     {
      return m_dailyTradeCount;
     }

   double            DailyClosedProfit(void) const
     {
      return m_dailyClosedProfit;
     }

   bool              IsBlocking(string &reason) const
     {
      int currentDayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      if(currentDayKey != m_dayKey)
        {
         reason = "";
         return false;
        }

      return CurrentBlockReason(reason);
     }
  };

#endif
