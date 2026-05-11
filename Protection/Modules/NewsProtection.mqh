#ifndef __FUSION_NEWS_PROTECTION_MQH__
#define __FUSION_NEWS_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CNewsProtection : public CProtectionModuleBase
  {
private:
   bool              IsWindowActive(const int index,const datetime now) const
     {
      if(index < 0 || index >= FUSION_NEWS_WINDOW_COUNT)
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
   bool              CanOpen(string &reason) const
     {
      reason = "";
      datetime now = TimeCurrent();

      for(int index = 0; index < FUSION_NEWS_WINDOW_COUNT; ++index)
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

      for(int index = 0; index < FUSION_NEWS_WINDOW_COUNT; ++index)
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
