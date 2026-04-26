#ifndef __FUSION_DRAWDOWN_PROTECTION_MQH__
#define __FUSION_DRAWDOWN_PROTECTION_MQH__

#include "../../Core/Types.mqh"

class CDrawdownProtection
  {
private:
   SEASettings m_settings;
   bool        m_protectionActive;
   bool        m_limitReached;
   double      m_peakProjectedProfit;

public:
                     CDrawdownProtection(void)
     {
      SetDefaultSettings(m_settings);
      m_protectionActive = false;
      m_limitReached = false;
      m_peakProjectedProfit = 0.0;
     }

   bool              Init(const SEASettings &settings)
     {
      m_settings = settings;
      return true;
     }

   bool              Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      m_settings = settings;
      return (scope == RELOAD_HOT || scope == RELOAD_WARM || scope == RELOAD_COLD);
     }

   void              ResetDaily(void)
     {
      m_protectionActive = false;
      m_limitReached = false;
      m_peakProjectedProfit = 0.0;
     }

   void              Activate(const double projectedProfit)
     {
      if(!m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0 || m_settings.maxDailyGain <= 0.0)
         return;
      if(m_protectionActive)
        {
         if(projectedProfit > m_peakProjectedProfit)
            m_peakProjectedProfit = projectedProfit;
         return;
        }

      m_protectionActive = true;
      m_peakProjectedProfit = projectedProfit;
     }

   bool              CanOpen(string &reason) const
     {
      reason = "";
      if(!m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0)
         return true;
      if(!m_limitReached)
         return true;

      reason = "Limite de drawdown diario atingido.";
      return false;
     }

   bool              ShouldForceClose(const double dailyClosedProfit,const double floatingProfit,string &reason)
     {
      reason = "";
      if(!m_protectionActive || m_limitReached || !m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0)
         return false;

      double projectedProfit = dailyClosedProfit + floatingProfit;
      if(projectedProfit > m_peakProjectedProfit)
         m_peakProjectedProfit = projectedProfit;

      double drawdown = m_peakProjectedProfit - projectedProfit;
      if(drawdown < m_settings.maxDrawdown)
         return false;

      m_limitReached = true;
      reason = "Limite de drawdown diario atingido.";
      return true;
     }

   bool              IsProtectionActive(void) const
     {
      return (m_settings.enableDrawdown && m_protectionActive);
     }

   bool              IsLimitReached(void) const
     {
      return m_limitReached;
     }
  };

#endif
