#ifndef __FUSION_EA_APPLICATION_PROTECTION_NOTICE_MQH__
#define __FUSION_EA_APPLICATION_PROTECTION_NOTICE_MQH__

   void                    ApplyRuntimeBlock(const string reason)
     {
      m_runtimeBlocked = true;
      m_runtimeBlockReason = reason;
      m_started = false;
     }

   void                    ApplyRuntimeNotice(const string notice)
     {
      m_runtimeNotice = notice;
     }

   bool                    IsSessionProtectionNotice(const string notice) const
     {
      return (notice == "Fora da janela de sessao." || notice == "Sessao encerrada.");
     }

   bool                    IsNewsProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Janela de news ") == 0);
     }

   bool                    HasEnabledNewsWindow(const SEASettings &settings) const
     {
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
         if(settings.newsWindows[newsIndex].enabled)
            return true;
      return false;
     }

   bool                    ProtectionNoticeAllowedBySettings(const string notice,const SEASettings &settings) const
     {
      if(IsSessionProtectionNotice(notice))
         return settings.enableSessionFilter;
      if(IsNewsProtectionNotice(notice))
         return HasEnabledNewsWindow(settings);
      return true;
     }

   void                    ClearProtectionNoticeDisabledBySettings(void)
     {
      if(m_protectionNoticeActive &&
         !ProtectionNoticeAllowedBySettings(m_protectionNoticeReason, m_settings))
        {
         m_protectionNoticeActive = false;
         m_protectionNoticeReason = "";
        }

      if(m_runtimeNotice != "" &&
         !ProtectionNoticeAllowedBySettings(m_runtimeNotice, m_settings))
        {
         m_runtimeNotice = m_tradePermissionGuard.IsBlocked() ? m_tradePermissionGuard.Notice() : "";
        }
     }

   bool                    IsSpreadProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por Spread:") == 0);
     }

   bool                    IsStreakPauseProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por ") == 0 &&
              StringFind(notice, " streak em pausa (") > 0);
     }

   bool                    IsStreakProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por loss streak") == 0 ||
              StringFind(notice, "Bloqueio por win streak") == 0);
     }

   bool                    IsPersistentDailyProtectionNotice(const string notice) const
     {
      return (notice == "Limite de drawdown diario atingido." ||
              notice == "Limite diario de trades atingido." ||
              notice == "Limite diario de perda atingido." ||
              notice == "Limite diario de perda projetada atingido." ||
              notice == "Meta diaria de ganho atingida.");
     }

   int                     ProtectionWarnDayKey(void) const
     {
      return FusionProtectionCurrentDayKey();
     }

   bool                    SameStreakPauseProtectionNotice(const string previous,const string current) const
     {
      if(!IsStreakPauseProtectionNotice(previous) || !IsStreakPauseProtectionNotice(current))
         return false;

      int previousOpen = StringFind(previous, "(");
      int currentOpen = StringFind(current, "(");
      if(previousOpen <= 0 || currentOpen <= 0)
         return false;

      return (StringSubstr(previous, 0, previousOpen) == StringSubstr(current, 0, currentOpen));
     }

   int                     StreakPauseMinutesFromNotice(const string notice) const
     {
      int open = StringFind(notice, "(");
      if(open < 0)
         return 0;

      int marker = StringFind(notice, " min", open);
      if(marker <= open)
         return 0;

      return (int)StringToInteger(StringSubstr(notice, open + 1, marker - open - 1));
     }

   bool                    ShouldLogStreakPauseNotice(const string notice,const bool firstNotice) const
     {
      if(firstNotice)
         return true;

      int minutesLeft = StreakPauseMinutesFromNotice(notice);
      if(minutesLeft <= 0)
         return false;
      if(minutesLeft <= 5)
         return true;
      if(minutesLeft < 30)
         return ((minutesLeft % 10) == 0);
      return ((minutesLeft % 30) == 0);
     }

   bool                    ShouldLogProtectionNotice(const string notice,const bool firstNotice)
     {
      if(IsStreakPauseProtectionNotice(notice))
         return ShouldLogStreakPauseNotice(notice, firstNotice);

      if(IsPersistentDailyProtectionNotice(notice))
        {
         int dayKey = ProtectionWarnDayKey();
         if(m_lastPersistentProtectWarnReason == notice &&
            m_lastPersistentProtectWarnDayKey == dayKey)
            return false;

         m_lastPersistentProtectWarnReason = notice;
         m_lastPersistentProtectWarnDayKey = dayKey;
         return true;
        }

      return true;
     }

   bool                    ShouldLogDiscardedSignalDebug(const string reason)
     {
      if(reason == "")
         return false;
      if(IsStreakProtectionNotice(reason))
         return false;

      datetime now = TimeCurrent();
      if(now <= 0)
         now = TimeLocal();

      if(reason != m_lastDiscardDebugReason ||
         m_lastDiscardDebugTime <= 0 ||
         now - m_lastDiscardDebugTime >= 60)
        {
         m_lastDiscardDebugReason = reason;
         m_lastDiscardDebugTime = now;
         return true;
        }

      return false;
     }

   void                    LogProtectionNoticeCleared(const string notice)
     {
      if(IsSessionProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de sessao removido.");
         return;
        }

      if(IsNewsProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de news removido: " + notice);
         return;
        }

      if(IsStreakProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.");
         return;
        }
     }

   bool                    IsStreakReleaseNotice(const string notice) const
     {
      return (notice == "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.");
     }

   void                    ClearStreakReleaseNotice(void)
     {
      if(IsStreakReleaseNotice(m_runtimeNotice))
         m_runtimeNotice = "";
     }

   bool                    ClearProtectionNotice(const bool announceRelease=false)
     {
      if(!m_protectionNoticeActive)
         return false;

      bool releasedStreak = IsStreakProtectionNotice(m_protectionNoticeReason);
      if(announceRelease)
         LogProtectionNoticeCleared(m_protectionNoticeReason);
      m_protectionNoticeActive = false;
      m_protectionNoticeReason = "";
      if(m_tradePermissionGuard.IsBlocked())
         m_runtimeNotice = m_tradePermissionGuard.Notice();
      else if(announceRelease && releasedStreak)
         m_runtimeNotice = "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.";
      else
         m_runtimeNotice = "";
      return (announceRelease && releasedStreak);
     }

   void                    ApplyProtectionNotice(const string notice,const bool allowLog=true,const bool forceLog=false)
     {
      if(notice == "")
        {
         ClearProtectionNotice();
         return;
        }

      bool firstNotice = (!m_protectionNoticeActive ||
                          (IsStreakPauseProtectionNotice(notice) &&
                           !SameStreakPauseProtectionNotice(m_protectionNoticeReason, notice)));
      bool changed = (!m_protectionNoticeActive || m_protectionNoticeReason != notice);
      if(changed && m_protectionNoticeActive && !IsStreakProtectionNotice(m_protectionNoticeReason))
         LogProtectionNoticeCleared(m_protectionNoticeReason);

      m_protectionNoticeActive = true;
      m_protectionNoticeReason = notice;
      if(!m_tradePermissionGuard.IsBlocked())
         m_runtimeNotice = notice;

      if(allowLog && (changed || forceLog) && ShouldLogProtectionNotice(notice, firstNotice))
        {
         m_logger.Warn("PROTECT", notice);
        }
     }

   void                    ClearEntryBlockNotice(void)
     {
      if(!m_entryBlockNoticeActive)
         return;

      m_entryBlockNoticeActive = false;
      m_entryBlockNoticeReason = "";
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";
     }

   bool                    MaintainOperationalDayState(void)
     {
      if(!m_protectionManager.MaintainOperationalDay(m_positionState))
         return false;

      if(IsPersistentDailyProtectionNotice(m_protectionNoticeReason) ||
         IsStreakProtectionNotice(m_protectionNoticeReason))
         ClearProtectionNotice();
      if(IsPersistentDailyProtectionNotice(m_runtimeNotice) ||
         IsStreakProtectionNotice(m_runtimeNotice))
         m_runtimeNotice = "";

      m_lastPersistentProtectWarnReason = "";
      m_lastPersistentProtectWarnDayKey = 0;
      if(m_positionState.partialClosePending &&
         PositionSelectByTicket(m_positionState.ticket))
        {
         double currentFloating = PositionGetDouble(POSITION_PROFIT);
         m_positionState.pendingPartialPreProjectedProfit =
            m_protectionManager.DailyClosedProfit() + currentFloating;
         if(m_positionState.pendingPartialFloatingReferenceSet)
            m_positionState.pendingPartialFloatingReference = currentFloating;
        }
      if(m_started && !m_positionState.hasPosition)
         m_signalManager.PrimeEntryStates();

      m_logger.Info("PROTECT", "Novo dia operacional: estados DAY/DD/STREAK resetados.");
      PersistChartState();
      return true;
     }

#endif
