#ifndef __FUSION_STREAK_PROTECTION_MQH__
#define __FUSION_STREAK_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CStreakProtection : public CProtectionModuleBase
  {
private:
   int         m_lossStreak;
   int         m_winStreak;
   int         m_dayKey;
   bool        m_lossStopDayBlocked;
   bool        m_winStopDayBlocked;
   datetime    m_lossPauseUntil;
   datetime    m_winPauseUntil;

   int               PauseMinutesLeft(const datetime pauseUntil) const
     {
      int secondsLeft = (int)(pauseUntil - TimeCurrent());
      if(secondsLeft <= 0)
         return 0;
      return (secondsLeft + 59) / 60;
     }

   void              ApplyLossBlock(void)
     {
      if(m_settings.lossStreakAction == STREAK_ACTION_PAUSE && m_settings.lossStreakPauseMinutes > 0)
         m_lossPauseUntil = TimeCurrent() + (m_settings.lossStreakPauseMinutes * 60);
      else
         m_lossStopDayBlocked = true;
     }

   void              ApplyWinBlock(void)
     {
      if(m_settings.winStreakAction == STREAK_ACTION_PAUSE && m_settings.winStreakPauseMinutes > 0)
         m_winPauseUntil = TimeCurrent() + (m_settings.winStreakPauseMinutes * 60);
      else
         m_winStopDayBlocked = true;
     }

public:
                     CStreakProtection(void)
     {
      m_lossStreak = 0;
      m_winStreak = 0;
      m_dayKey = 0;
      m_lossStopDayBlocked = false;
      m_winStopDayBlocked = false;
      m_lossPauseUntil = 0;
      m_winPauseUntil = 0;
     }

   bool              Init(const SEASettings &settings)
     {
      CProtectionModuleBase::Init(settings);
      m_dayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      return true;
     }

   void              ResetDaily(void)
     {
      m_lossStreak = 0;
      m_winStreak = 0;
      m_dayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      m_lossStopDayBlocked = false;
      m_winStopDayBlocked = false;
      m_lossPauseUntil = 0;
      m_winPauseUntil = 0;
     }

   void              ExportState(SStreakRuntimeState &state) const
     {
      state.dayKey = m_dayKey;
      state.lossStreak = m_lossStreak;
      state.winStreak = m_winStreak;
      state.lossStopDayBlocked = m_lossStopDayBlocked;
      state.winStopDayBlocked = m_winStopDayBlocked;
      state.lossPauseUntil = m_lossPauseUntil;
      state.winPauseUntil = m_winPauseUntil;
     }

   void              ImportState(const SStreakRuntimeState &state)
     {
      int currentDayKey = FusionProtectionCurrentDayKey(TimeCurrent());
      if(state.dayKey != currentDayKey)
        {
         ResetDaily();
         return;
        }

      m_dayKey = state.dayKey;
      m_lossStreak = (state.lossStreak < 0) ? 0 : state.lossStreak;
      m_winStreak = (state.winStreak < 0) ? 0 : state.winStreak;
      m_lossStopDayBlocked = state.lossStopDayBlocked;
      m_winStopDayBlocked = state.winStopDayBlocked;
      m_lossPauseUntil = state.lossPauseUntil;
      m_winPauseUntil = state.winPauseUntil;
     }

   bool              CanOpen(string &reason) const
     {
      reason = "";
      if(m_lossStopDayBlocked)
        {
         reason = "Bloqueio por loss streak ate o proximo dia.";
         return false;
        }

      if(m_lossPauseUntil > TimeCurrent())
        {
         reason = StringFormat("Bloqueio por loss streak em pausa (%d min).", PauseMinutesLeft(m_lossPauseUntil));
         return false;
        }

      if(m_winStopDayBlocked)
        {
         reason = "Bloqueio por win streak ate o proximo dia.";
         return false;
        }

      if(m_winPauseUntil > TimeCurrent())
        {
         reason = StringFormat("Bloqueio por win streak em pausa (%d min).", PauseMinutesLeft(m_winPauseUntil));
         return false;
        }

      return true;
     }

   bool              IsBlocking(string &reason) const
     {
      reason = "";
      if(m_dayKey != FusionProtectionCurrentDayKey(TimeCurrent()))
         return false;

      if(m_lossStopDayBlocked)
        {
         reason = "Bloqueio por loss streak ate o proximo dia.";
         return true;
        }

      if(m_lossPauseUntil > TimeCurrent())
        {
         reason = StringFormat("Bloqueio por loss streak em pausa (%d min).", PauseMinutesLeft(m_lossPauseUntil));
         return true;
        }

      if(m_winStopDayBlocked)
        {
         reason = "Bloqueio por win streak ate o proximo dia.";
         return true;
        }

      if(m_winPauseUntil > TimeCurrent())
        {
         reason = StringFormat("Bloqueio por win streak em pausa (%d min).", PauseMinutesLeft(m_winPauseUntil));
         return true;
        }

      return false;
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

      if(m_settings.lossStreakEnabled &&
         m_settings.maxLossStreak > 0 &&
         m_lossStreak >= m_settings.maxLossStreak)
         ApplyLossBlock();
      if(m_settings.winStreakEnabled &&
         m_settings.maxWinStreak > 0 &&
         m_winStreak >= m_settings.maxWinStreak)
         ApplyWinBlock();
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
