#ifndef __FUSION_STREAK_PROTECTION_MQH__
#define __FUSION_STREAK_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"

class CStreakProtection : public CProtectionModuleBase
  {
private:
   int         m_lossStreak;
   int         m_winStreak;
   bool        m_lossStreakBlocked;
   bool        m_winStreakBlocked;

public:
                     CStreakProtection(void)
     {
      m_lossStreak = 0;
      m_winStreak = 0;
      m_lossStreakBlocked = false;
      m_winStreakBlocked = false;
     }

   void              ResetDaily(void)
     {
      m_lossStreak = 0;
      m_winStreak = 0;
      m_lossStreakBlocked = false;
      m_winStreakBlocked = false;
     }

   bool              CanOpen(string &reason) const
     {
      reason = "";
      if(!m_settings.enableStreak)
         return true;
      if(m_lossStreakBlocked)
        {
         reason = "Bloqueio por loss streak ativo.";
         return false;
        }

      if(m_winStreakBlocked)
        {
         reason = "Bloqueio por win streak ativo.";
         return false;
        }

      return true;
     }

   void              OnPositionClosed(const double totalPositionProfit)
     {
      if(totalPositionProfit > 0.0)
        {
         m_winStreak++;
         m_lossStreak = 0;
        }
      else if(totalPositionProfit < 0.0)
        {
         m_lossStreak++;
         m_winStreak = 0;
        }

      if(!m_settings.enableStreak)
         return;

      if(m_settings.maxLossStreak > 0 && m_lossStreak >= m_settings.maxLossStreak)
         m_lossStreakBlocked = true;
      if(m_settings.maxWinStreak > 0 && m_winStreak >= m_settings.maxWinStreak)
         m_winStreakBlocked = true;
     }

   int               LossStreak(void) const
     {
      return m_lossStreak;
     }

   int               WinStreak(void) const
     {
      return m_winStreak;
     }
  };

#endif
