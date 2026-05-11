#ifndef __FUSION_SESSION_PROTECTION_MQH__
#define __FUSION_SESSION_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CSessionProtection : public CProtectionModuleBase
  {
public:
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
