#ifndef __FUSION_SESSION_PROTECTION_MQH__
#define __FUSION_SESSION_PROTECTION_MQH__

#include "../../Core/Types.mqh"
#include "ProtectionTimeUtils.mqh"

class CSessionProtection
  {
private:
   SEASettings m_settings;

public:
                     CSessionProtection(void)
     {
      SetDefaultSettings(m_settings);
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

   bool              IsInsideSession(const datetime now) const
     {
      if(!m_settings.enableSessionFilter)
         return true;

      return FusionProtectionIsInsideClockWindow(m_settings.sessionStartHour,
                                                 m_settings.sessionStartMinute,
                                                 m_settings.sessionEndHour,
                                                 m_settings.sessionEndMinute,
                                                 now);
     }

   bool              CanOpen(string &reason) const
     {
      reason = "";
      if(IsInsideSession(TimeCurrent()))
         return true;

      reason = "Fora da janela de sessao.";
      return false;
     }

   bool              ShouldForceClose(string &reason) const
     {
      reason = "";
      if(!m_settings.enableSessionFilter || !m_settings.closeOnSessionEnd)
         return false;
      if(IsInsideSession(TimeCurrent()))
         return false;

      reason = "Sessao encerrada.";
      return true;
     }
  };

#endif
