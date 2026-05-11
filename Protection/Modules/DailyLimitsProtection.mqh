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

   bool              UsesDrawdownActivation(void) const
     {
      return (m_settings.enableDrawdown && m_settings.maxDrawdown > 0.0 && m_settings.maxDailyGain > 0.0);
     }

public:
                     CDailyLimitsProtection(void)
     {
      m_dayKey = 0;
      m_dailyTradeCount = 0;
      m_dailyClosedProfit = 0.0;
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
      m_dailyTradeCount = 0;
      m_dailyClosedProfit = 0.0;
      return true;
     }

   bool              CanOpen(string &reason,bool &activateDrawdown) const
     {
      reason = "";
      activateDrawdown = false;

      if(!m_settings.enableDailyLimits)
         return true;

      if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
        {
         reason = "Limite diario de trades atingido.";
         return false;
        }

      if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
        {
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
         return false;
        }

      return true;
     }

   bool              ShouldForceClose(const double floatingProfit,string &reason,bool &activateDrawdown,double &projectedProfit) const
     {
      reason = "";
      activateDrawdown = false;
      projectedProfit = m_dailyClosedProfit + floatingProfit;

      if(!m_settings.enableDailyLimits)
         return false;

      if(m_settings.maxDailyLoss > 0.0 && projectedProfit <= -m_settings.maxDailyLoss)
        {
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
         return true;
        }

      return false;
     }

   void              OnPartialRealized(const double profit)
     {
      m_dailyClosedProfit += profit;
     }

   void              OnPositionClosed(const double totalPositionProfit,const double realizedPartialProfit)
     {
      double finalPortion = totalPositionProfit - realizedPartialProfit;
      m_dailyClosedProfit += finalPortion;
      m_dailyTradeCount++;
     }

   int               DailyTradeCount(void) const
     {
      return m_dailyTradeCount;
     }

   double            DailyClosedProfit(void) const
     {
      return m_dailyClosedProfit;
     }
  };

#endif
