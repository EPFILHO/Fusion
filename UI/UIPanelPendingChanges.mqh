#ifndef __FUSION_UI_PANEL_PENDING_CHANGES_MQH__
#define __FUSION_UI_PANEL_PENDING_CHANGES_MQH__

   string                     CommittedLotText(void)
     {
      return FusionNormalizeDecimalText(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
     }

   bool                       HasRiskPendingChanges(void)
     {
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

      return false;
     }

   bool                       HasSystemPendingChanges(void)
     {
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

      return (m_draftSettings.conflictMode != m_committedSettings.conflictMode);
     }

   bool                       HasSignalTogglePendingChanges(void)
     {
      if(m_draftSettings.useMACross != m_committedSettings.useMACross)
         return true;
      if(m_draftSettings.useRSI != m_committedSettings.useRSI)
         return true;
      if(m_draftSettings.useBollinger != m_committedSettings.useBollinger)
         return true;
      if(m_draftSettings.useTrendFilter != m_committedSettings.useTrendFilter)
         return true;
      return (m_draftSettings.useRSIFilter != m_committedSettings.useRSIFilter);
     }

   bool                       HasSignalParameterPendingChanges(void)
     {
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
      return (m_draftSettings.rsiFilterTimeframe != m_committedSettings.rsiFilterTimeframe);
     }

   bool                       HasNewsWindowPendingChanges(const int newsIndex)
     {
      if(m_draftSettings.newsWindows[newsIndex].enabled != m_committedSettings.newsWindows[newsIndex].enabled)
         return true;
      return (m_draftSettings.newsWindows[newsIndex].startHour != m_committedSettings.newsWindows[newsIndex].startHour ||
              m_draftSettings.newsWindows[newsIndex].startMinute != m_committedSettings.newsWindows[newsIndex].startMinute ||
              m_draftSettings.newsWindows[newsIndex].endHour != m_committedSettings.newsWindows[newsIndex].endHour ||
              m_draftSettings.newsWindows[newsIndex].endMinute != m_committedSettings.newsWindows[newsIndex].endMinute ||
              m_draftSettings.newsWindows[newsIndex].action != m_committedSettings.newsWindows[newsIndex].action);
     }

   bool                       HasProtectionSettingPendingChanges(void)
     {
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
         if(HasNewsWindowPendingChanges(newsIndex))
            return true;

      return false;
     }

   bool                       HasPendingChanges(void)
     {
      if(!m_hasCommittedSettings)
         return false;

      if(HasRiskPendingChanges())
         return true;
      if(HasSystemPendingChanges())
         return true;
      if(HasSignalTogglePendingChanges())
         return true;
      if(HasProtectionPendingChanges())
         return true;
      if(HasSignalParameterPendingChanges())
         return true;
      return HasProtectionSettingPendingChanges();
     }

#endif
