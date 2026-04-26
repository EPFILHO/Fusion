#ifndef __FUSION_PROTECTION_MANAGER_MQH__
#define __FUSION_PROTECTION_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "Modules/SpreadProtection.mqh"
#include "Modules/SessionProtection.mqh"
#include "Modules/NewsProtection.mqh"
#include "Modules/DailyLimitsProtection.mqh"
#include "Modules/DrawdownProtection.mqh"
#include "Modules/StreakProtection.mqh"
#include "Modules/ProtectionTimeUtils.mqh"

class CProtectionManager
  {
private:
   CLogger                 *m_logger;
   SEASettings              m_settings;
   CSpreadProtection        m_spreadProtection;
   CSessionProtection       m_sessionProtection;
   CNewsProtection          m_newsProtection;
   CDailyLimitsProtection   m_dailyLimitsProtection;
   CDrawdownProtection      m_drawdownProtection;
   CStreakProtection        m_streakProtection;

   void              ResetIfNewDay(SPositionRuntimeState &state)
     {
      if(!m_dailyLimitsProtection.ResetIfNewDay())
         return;

      m_streakProtection.ResetDaily();
      m_drawdownProtection.ResetDaily();
      state.dayPeakProjectedProfit = 0.0;
     }

   void              TryActivateDrawdown(const double projectedProfit,SPositionRuntimeState &state)
     {
      m_drawdownProtection.Activate(projectedProfit);
      if(m_drawdownProtection.IsProtectionActive())
         state.dayPeakProjectedProfit = projectedProfit;
     }

public:
                     CProtectionManager(void)
     {
      m_logger = NULL;
      SetDefaultSettings(m_settings);
     }

   bool              Init(CLogger *logger,const SEASettings &settings)
     {
      m_logger = logger;
      m_settings = settings;
      m_spreadProtection.Init(settings);
      m_sessionProtection.Init(settings);
      m_newsProtection.Init(settings);
      m_dailyLimitsProtection.Init(settings);
      m_drawdownProtection.Init(settings);
      m_streakProtection.Init(settings);
      return true;
     }

   bool              Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      m_settings = settings;
      m_spreadProtection.Reload(settings, scope);
      m_sessionProtection.Reload(settings, scope);
      m_newsProtection.Reload(settings, scope);
      m_dailyLimitsProtection.Reload(settings, scope);
      m_drawdownProtection.Reload(settings, scope);
      m_streakProtection.Reload(settings, scope);
      return (scope == RELOAD_HOT || scope == RELOAD_WARM || scope == RELOAD_COLD);
     }

   bool              IsDirectionAllowed(const ENUM_SIGNAL_TYPE signal,string &reason) const
     {
      reason = "";
      if(signal == SIGNAL_NONE)
         return true;

      if(signal == SIGNAL_BUY && m_settings.tradeDirection == DIRECTION_SELL_ONLY)
        {
         reason = "BUY bloqueado pela direcao.";
         return false;
        }

      if(signal == SIGNAL_SELL && m_settings.tradeDirection == DIRECTION_BUY_ONLY)
        {
         reason = "SELL bloqueado pela direcao.";
         return false;
        }

      return true;
     }

   bool              CanOpen(const string symbol,string &reason)
     {
      SPositionRuntimeState emptyState;
      ResetPositionRuntimeState(emptyState);
      ResetIfNewDay(emptyState);
      reason = "";

      if(!m_streakProtection.CanOpen(reason))
         return false;
      if(!m_sessionProtection.CanOpen(reason))
         return false;
      if(!m_newsProtection.CanOpen(reason))
         return false;
      if(!m_spreadProtection.CanOpen(symbol, reason))
         return false;

      bool activateDrawdown = false;
      if(!m_dailyLimitsProtection.CanOpen(reason, activateDrawdown))
         return false;
      if(activateDrawdown)
         m_drawdownProtection.Activate(m_dailyLimitsProtection.DailyClosedProfit());

      if(!m_drawdownProtection.CanOpen(reason))
         return false;

      return true;
     }

   bool              ShouldForceClose(SPositionRuntimeState &state,const double floatingProfit,string &reason)
     {
      reason = "";
      ResetIfNewDay(state);

      bool activateDrawdown = false;
      double projectedProfit = 0.0;
      if(m_dailyLimitsProtection.ShouldForceClose(floatingProfit, reason, activateDrawdown, projectedProfit))
         return true;
      if(activateDrawdown)
         TryActivateDrawdown(projectedProfit, state);

      if(m_drawdownProtection.ShouldForceClose(m_dailyLimitsProtection.DailyClosedProfit(), floatingProfit, reason))
         return true;

      if(m_sessionProtection.ShouldForceClose(reason))
         return true;

      if(m_newsProtection.ShouldForceClose(reason))
         return true;

      return false;
     }

   void              OnPartialRealized(const double profit)
     {
      m_dailyLimitsProtection.OnPartialRealized(profit);
     }

   void              OnPositionClosed(const double totalPositionProfit,const double realizedPartialProfit)
     {
      m_dailyLimitsProtection.OnPositionClosed(totalPositionProfit, realizedPartialProfit);
      m_streakProtection.OnPositionClosed(totalPositionProfit);
     }

   int               DailyTradeCount(void) const
     {
      return m_dailyLimitsProtection.DailyTradeCount();
     }

   double            DailyClosedProfit(void) const
     {
      return m_dailyLimitsProtection.DailyClosedProfit();
     }

   int               LossStreak(void) const
     {
      return m_streakProtection.LossStreak();
     }

   int               WinStreak(void) const
     {
      return m_streakProtection.WinStreak();
     }

   bool              IsDrawdownProtectionActive(void) const
     {
      return m_drawdownProtection.IsProtectionActive();
     }
  };

#endif
