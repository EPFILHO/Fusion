#ifndef __FUSION_UI_PANEL_DRAFT_STATE_MQH__
#define __FUSION_UI_PANEL_DRAFT_STATE_MQH__

   bool                       ParsedProfileMagicNumber(int &magicNumber)
     {
      magicNumber = 0;
      if(!m_profilesEditCreated)
         return false;

      string profileMagicText = FusionTrimCopy(LiveEditText(m_profileMagicEdit));
      if(!FusionIsIntegerText(profileMagicText, false))
         return false;

      magicNumber = (int)StringToInteger(profileMagicText);
      return (magicNumber > 0);
     }

   bool                       ParsedConfigMagicNumber(int &magicNumber)
     {
      magicNumber = 0;
      if(!m_configSystemCreated)
        {
         magicNumber = m_draftSettings.magicNumber;
         return (magicNumber > 0);
        }
      string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
      if(!FusionIsIntegerText(magicText, false))
         return false;

      magicNumber = (int)StringToInteger(magicText);
      return (magicNumber > 0);
     }

   void                       ToggleDraftFlag(const ENUM_UI_COMMAND type)
     {
      if(type == UI_COMMAND_TOGGLE_MACROSS)
         m_draftSettings.useMACross = !m_draftSettings.useMACross;
      else if(type == UI_COMMAND_TOGGLE_RSI)
         m_draftSettings.useRSI = !m_draftSettings.useRSI;
      else if(type == UI_COMMAND_TOGGLE_BB)
         m_draftSettings.useBollinger = !m_draftSettings.useBollinger;
      else if(type == UI_COMMAND_TOGGLE_TREND_FILTER)
         m_draftSettings.useTrendFilter = !m_draftSettings.useTrendFilter;
      else if(type == UI_COMMAND_TOGGLE_RSI_FILTER)
         m_draftSettings.useRSIFilter = !m_draftSettings.useRSIFilter;
     }

   string                     DraftProfileName(void)
     {
      return FusionTrimCopy(m_committedProfileName);
     }

   string                     CommittedLotText(void)
     {
      return FusionNormalizeDecimalText(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
     }

   void                       SyncDraftSettingsToControls(void)
     {
      if(m_configRiskCreated)
         m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      if(m_configProtectionCreated)
         SyncProtectionControls();
      if(m_configSystemCreated)
        {
         m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
         m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
        }
      if(m_profilesEditCreated)
         m_profileMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      RefreshSignalDraftViews(true, true);
      if(m_profilesTabCreated)
         UpdateProfileListView();
     }

   void                       RestoreCommittedDraftToControls(void)
     {
      m_draftSettings = m_committedSettings;
      SyncDraftSettingsToControls();
     }

   bool                       HasPendingChanges(void)
     {
      if(!m_hasCommittedSettings)
         return false;

      if(m_configRiskCreated)
        {
         string lotText = FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit));
         if(FusionIsDecimalText(lotText, false))
           {
            if(MathAbs(StringToDouble(lotText) - m_committedSettings.fixedLot) > 0.0000001)
               return true;
           }
         else if(lotText != CommittedLotText())
            return true;
        }
      else
        {
         if(MathAbs(m_draftSettings.fixedLot - m_committedSettings.fixedLot) > 0.0000001)
            return true;
        }

      if(m_configSystemCreated)
        {
         string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
         if(FusionIsIntegerText(magicText, false))
           {
            if((int)StringToInteger(magicText) != m_committedSettings.magicNumber)
               return true;
           }
         else if(magicText != IntegerToString(m_committedSettings.magicNumber))
            return true;
        }
      else if(m_draftSettings.magicNumber != m_committedSettings.magicNumber)
         return true;

      if(m_draftSettings.conflictMode != m_committedSettings.conflictMode)
         return true;
      if(m_draftSettings.useMACross != m_committedSettings.useMACross)
         return true;
      if(m_draftSettings.useRSI != m_committedSettings.useRSI)
         return true;
      if(m_draftSettings.useBollinger != m_committedSettings.useBollinger)
         return true;
      if(m_draftSettings.useTrendFilter != m_committedSettings.useTrendFilter)
         return true;
      if(m_draftSettings.useRSIFilter != m_committedSettings.useRSIFilter)
         return true;
      if(HasProtectionPendingChanges())
         return true;
      if(m_draftSettings.maFastTimeframe != m_committedSettings.maFastTimeframe)
         return true;
      if(m_draftSettings.maSlowTimeframe != m_committedSettings.maSlowTimeframe)
         return true;
      if(m_draftSettings.maFastPeriod != m_committedSettings.maFastPeriod)
         return true;
      if(m_draftSettings.maSlowPeriod != m_committedSettings.maSlowPeriod)
         return true;
      if(m_draftSettings.maFastMethod != m_committedSettings.maFastMethod)
         return true;
      if(m_draftSettings.maSlowMethod != m_committedSettings.maSlowMethod)
         return true;
      if(m_draftSettings.maFastPrice != m_committedSettings.maFastPrice)
         return true;
      if(m_draftSettings.maSlowPrice != m_committedSettings.maSlowPrice)
         return true;
      if(m_draftSettings.maEntryMode != m_committedSettings.maEntryMode)
         return true;
      if(m_draftSettings.maExitMode != m_committedSettings.maExitMode)
         return true;
      if(m_draftSettings.rsiTimeframe != m_committedSettings.rsiTimeframe)
         return true;
      if(m_draftSettings.bbTimeframe != m_committedSettings.bbTimeframe)
         return true;
      if(m_draftSettings.trendMATimeframe != m_committedSettings.trendMATimeframe)
         return true;
      if(m_draftSettings.rsiFilterTimeframe != m_committedSettings.rsiFilterTimeframe)
         return true;
      if(m_draftSettings.enableSpreadProtection != m_committedSettings.enableSpreadProtection)
         return true;
      if(m_draftSettings.maxSpreadPoints != m_committedSettings.maxSpreadPoints)
         return true;
      if(m_draftSettings.enableSessionFilter != m_committedSettings.enableSessionFilter)
         return true;
      if(m_draftSettings.sessionStartHour != m_committedSettings.sessionStartHour ||
         m_draftSettings.sessionStartMinute != m_committedSettings.sessionStartMinute ||
         m_draftSettings.sessionEndHour != m_committedSettings.sessionEndHour ||
         m_draftSettings.sessionEndMinute != m_committedSettings.sessionEndMinute)
         return true;
      if(m_draftSettings.closeOnSessionEnd != m_committedSettings.closeOnSessionEnd)
         return true;
      if(m_draftSettings.enableDailyLimits != m_committedSettings.enableDailyLimits)
         return true;
      if(m_draftSettings.maxDailyTrades != m_committedSettings.maxDailyTrades)
         return true;
      if(MathAbs(m_draftSettings.maxDailyLoss - m_committedSettings.maxDailyLoss) > 0.0000001)
         return true;
      if(MathAbs(m_draftSettings.maxDailyGain - m_committedSettings.maxDailyGain) > 0.0000001)
         return true;
      if(m_draftSettings.enableDrawdown != m_committedSettings.enableDrawdown)
         return true;
      if(MathAbs(m_draftSettings.maxDrawdown - m_committedSettings.maxDrawdown) > 0.0000001)
         return true;
      if(m_draftSettings.enableStreak != m_committedSettings.enableStreak)
         return true;
      if(m_draftSettings.maxLossStreak != m_committedSettings.maxLossStreak)
         return true;
      if(m_draftSettings.maxWinStreak != m_committedSettings.maxWinStreak)
         return true;
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(m_draftSettings.newsWindows[newsIndex].enabled != m_committedSettings.newsWindows[newsIndex].enabled)
            return true;
         if(m_draftSettings.newsWindows[newsIndex].startHour != m_committedSettings.newsWindows[newsIndex].startHour ||
            m_draftSettings.newsWindows[newsIndex].startMinute != m_committedSettings.newsWindows[newsIndex].startMinute ||
            m_draftSettings.newsWindows[newsIndex].endHour != m_committedSettings.newsWindows[newsIndex].endHour ||
            m_draftSettings.newsWindows[newsIndex].endMinute != m_committedSettings.newsWindows[newsIndex].endMinute ||
            m_draftSettings.newsWindows[newsIndex].action != m_committedSettings.newsWindows[newsIndex].action)
            return true;
        }

      return false;
     }

#endif
