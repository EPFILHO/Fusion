#ifndef __FUSION_DRAWDOWN_PROTECTION_MQH__
#define __FUSION_DRAWDOWN_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CDrawdownProtection : public CProtectionModuleBase
  {
private:
   int         m_dayKey;
   bool        m_protectionActive;
   bool        m_limitReached;
   double      m_peakProjectedProfit;

   double            PeakCandidate(const double dailyClosedProfit,const double projectedProfit) const
     {
      if(m_settings.drawdownPeakMode == DD_PICO_REALIZADO)
         return dailyClosedProfit;
      return projectedProfit;
     }

   void              UpdatePeak(const double dailyClosedProfit,const double projectedProfit)
     {
      double peakCandidate = PeakCandidate(dailyClosedProfit, projectedProfit);
      if(peakCandidate > m_peakProjectedProfit)
         m_peakProjectedProfit = peakCandidate;
     }

   double            DrawdownLimit(void) const
     {
      if(m_settings.drawdownType == DD_TIPO_PERCENTUAL)
        {
         if(m_peakProjectedProfit <= 0.0)
            return 0.0;
         return (m_peakProjectedProfit * m_settings.maxDrawdown) / 100.0;
        }
      return m_settings.maxDrawdown;
     }

public:
                     CDrawdownProtection(void)
     {
      m_dayKey = 0;
      m_protectionActive = false;
      m_limitReached = false;
      m_peakProjectedProfit = 0.0;
     }

   bool              Init(const SEASettings &settings)
     {
      CProtectionModuleBase::Init(settings);
      m_dayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      return true;
     }

   void              ResetDaily(void)
     {
      m_dayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      m_protectionActive = false;
      m_limitReached = false;
      m_peakProjectedProfit = 0.0;
     }

   void              ExportState(SDrawdownRuntimeState &state) const
     {
      state.dayKey = m_dayKey;
      state.protectionActive = m_protectionActive;
      state.limitReached = m_limitReached;
      state.peakProjectedProfit = m_peakProjectedProfit;
     }

   void              ImportState(const SDrawdownRuntimeState &state)
     {
      int currentDayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      if(state.dayKey != currentDayKey)
        {
         ResetDaily();
         return;
        }

      m_dayKey = state.dayKey;
      m_protectionActive = state.protectionActive;
      m_limitReached = state.limitReached;
      m_peakProjectedProfit = state.peakProjectedProfit;
      if(m_peakProjectedProfit < 0.0)
         m_peakProjectedProfit = 0.0;
     }

   void              Activate(const double dailyClosedProfit,const double projectedProfit)
     {
      if(m_settings.profitTargetAction != PROFIT_ACTION_ATIVAR_DD ||
         !m_settings.enableDrawdown ||
         m_settings.maxDrawdown <= 0.0 ||
         m_settings.maxDailyGain <= 0.0)
         return;
      if(m_protectionActive)
        {
         UpdatePeak(dailyClosedProfit, projectedProfit);
         return;
        }

      m_protectionActive = true;
      m_peakProjectedProfit = PeakCandidate(dailyClosedProfit, projectedProfit);
      if(m_peakProjectedProfit < 0.0)
         m_peakProjectedProfit = 0.0;
     }

   bool              CanOpen(string &reason) const
     {
      reason = "";
      if(m_limitReached)
        {
         reason = "Limite de drawdown diario atingido.";
         return false;
        }

      if(!m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0)
         return true;

      return true;
     }

   bool              ShouldForceClose(const double dailyClosedProfit,const double floatingProfit,string &reason)
     {
      reason = "";
      if(m_limitReached)
        {
         reason = "Limite de drawdown diario atingido.";
         return true;
        }

      if(!m_protectionActive || !m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0)
         return false;

      double projectedProfit = dailyClosedProfit + floatingProfit;
      UpdatePeak(dailyClosedProfit, projectedProfit);

      double drawdown = m_peakProjectedProfit - projectedProfit;
      double limit = DrawdownLimit();
      if(limit <= 0.0 || drawdown < limit)
         return false;

      m_limitReached = true;
      reason = "Limite de drawdown diario atingido.";
      return true;
     }

   bool              IsProtectionActive(void) const
     {
      return m_protectionActive;
     }

   bool              IsLimitReached(void) const
     {
      return m_limitReached;
     }

   bool              IsConfigLocked(string &reason) const
     {
      reason = "";
      if(m_limitReached)
        {
         reason = "Limite de drawdown diario atingido.";
         return true;
        }

      if(m_protectionActive)
        {
         reason = "DD ativo: edicao suspensa ate o novo dia.";
         return true;
        }

      return false;
     }

   double            PeakProfit(void) const
     {
      return m_peakProjectedProfit;
     }
  };

#endif
