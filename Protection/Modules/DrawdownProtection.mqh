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
   double      m_triggerProjectedProfit;
   double      m_triggerDrawdownAmount;
   double      m_triggerBufferProfit;

   double            PeakCandidate(const double dailyClosedProfit,const double projectedProfit) const
     {
      if(m_settings.drawdownPeakMode == DD_PICO_REALIZADO)
         return m_settings.maxDailyGain;
      return projectedProfit;
     }

   void              UpdatePeak(const double dailyClosedProfit,const double projectedProfit)
     {
      double peakCandidate = PeakCandidate(dailyClosedProfit, projectedProfit);
      if(m_settings.drawdownPeakMode == DD_PICO_REALIZADO)
        {
         m_peakProjectedProfit = peakCandidate;
         return;
        }
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

   bool              RuntimeActive(void) const
     {
      return (m_protectionActive || m_limitReached);
     }

   double            FloorProfit(void) const
     {
      if(!RuntimeActive())
         return 0.0;

      double limit = DrawdownLimit();
      if(limit <= 0.0)
         return 0.0;

      return m_peakProjectedProfit - limit;
     }

   bool              LimitBreached(const double projectedProfit) const
     {
      if(!RuntimeActive())
         return false;

      double limit = DrawdownLimit();
      if(limit <= 0.0)
         return false;

      return (m_peakProjectedProfit - projectedProfit >= limit);
     }

   void              ClearTrigger(void)
     {
      m_triggerProjectedProfit = 0.0;
      m_triggerDrawdownAmount = 0.0;
      m_triggerBufferProfit = 0.0;
     }

   void              CaptureTrigger(const double projectedProfit)
     {
      double floorProfit = FloorProfit();
      m_triggerProjectedProfit = projectedProfit;
      m_triggerDrawdownAmount = m_peakProjectedProfit - projectedProfit;
      m_triggerBufferProfit = projectedProfit - floorProfit;
     }

public:
                     CDrawdownProtection(void)
     {
      m_dayKey = 0;
      m_protectionActive = false;
      m_limitReached = false;
      m_peakProjectedProfit = 0.0;
      ClearTrigger();
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
      ClearTrigger();
     }

   void              ExportState(SDrawdownRuntimeState &state) const
     {
      state.dayKey = m_dayKey;
      state.protectionActive = m_protectionActive;
      state.limitReached = m_limitReached;
      state.peakProjectedProfit = m_peakProjectedProfit;
      state.triggerProjectedProfit = m_triggerProjectedProfit;
      state.triggerDrawdownAmount = m_triggerDrawdownAmount;
      state.triggerBufferProfit = m_triggerBufferProfit;
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
      m_triggerProjectedProfit = state.triggerProjectedProfit;
      m_triggerDrawdownAmount = state.triggerDrawdownAmount;
      m_triggerBufferProfit = state.triggerBufferProfit;
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

      if(!LimitBreached(projectedProfit))
         return false;

      CaptureTrigger(projectedProfit);
      m_limitReached = true;
      reason = "Limite de drawdown diario atingido.";
      return true;
     }

   bool              UpdateAfterProjectedProfit(const double projectedProfit)
     {
      if(!m_protectionActive || !m_settings.enableDrawdown || m_settings.maxDrawdown <= 0.0)
         return false;

      UpdatePeak(projectedProfit, projectedProfit);
      if(!LimitBreached(projectedProfit))
         return false;

      if(!m_limitReached)
         CaptureTrigger(projectedProfit);
      m_limitReached = true;
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
         reason = "DD ativo: protecao de lucro ligada; novas entradas permitidas.";
         return true;
        }

      return false;
     }

   double            PeakProfit(void) const
     {
      return m_peakProjectedProfit;
     }

   double            DrawdownFloorProfit(void) const
     {
      return FloorProfit();
     }

   double            DrawdownBufferProfit(const double projectedProfit) const
     {
      if(!RuntimeActive())
         return 0.0;

      return projectedProfit - FloorProfit();
     }

   double            TriggerProfit(void) const
     {
      return m_triggerProjectedProfit;
     }

   double            TriggerDrawdown(void) const
     {
      return m_triggerDrawdownAmount;
     }

   double            TriggerBuffer(void) const
     {
      return m_triggerBufferProfit;
     }
  };

#endif
