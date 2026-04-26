#ifndef __FUSION_NEWS_PROTECTION_MQH__
#define __FUSION_NEWS_PROTECTION_MQH__

#include "../../Core/Types.mqh"
#include "ProtectionTimeUtils.mqh"

class CNewsProtection
  {
private:
   SEASettings m_settings;

   bool              IsWindowActive(const int index,const datetime now) const
     {
      if(index < 0 || index >= 3)
         return false;
      if(!m_settings.newsWindows[index].enabled)
         return false;

      return FusionProtectionIsInsideClockWindow(m_settings.newsWindows[index].startHour,
                                                 m_settings.newsWindows[index].startMinute,
                                                 m_settings.newsWindows[index].endHour,
                                                 m_settings.newsWindows[index].endMinute,
                                                 now);
     }

public:
                     CNewsProtection(void)
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

   bool              CanOpen(string &reason) const
     {
      reason = "";
      datetime now = TimeCurrent();

      for(int index = 0; index < 3; ++index)
        {
         if(!IsWindowActive(index, now))
            continue;

         reason = "Janela de news " + IntegerToString(index + 1) + " ativa.";
         return false;
        }

      return true;
     }

   bool              ShouldForceClose(string &reason) const
     {
      reason = "";
      datetime now = TimeCurrent();

      for(int index = 0; index < 3; ++index)
        {
         if(!IsWindowActive(index, now))
            continue;
         if(m_settings.newsWindows[index].action != NEWS_ACTION_CLOSE_AND_BLOCK)
            continue;

         reason = "Janela de news " + IntegerToString(index + 1) + " configurada para fechar posicoes.";
         return true;
        }

      return false;
     }
  };

#endif
