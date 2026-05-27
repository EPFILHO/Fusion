#ifndef __FUSION_UI_PANEL_PENDING_CHANGES_MQH__
#define __FUSION_UI_PANEL_PENDING_CHANGES_MQH__

   string                     CommittedLotText(void)
     {
      return FusionNormalizeDecimalText(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
     }

   bool                       RiskIntegerPending(CEdit &edit,const int committedValue)
     {
      string text = FusionTrimCopy(LiveEditText(edit));
      if(FusionIsIntegerText(text, true))
         return ((int)StringToInteger(text) != committedValue);
      return (text != IntegerToString(committedValue));
     }

   bool                       RiskDecimalPending(CEdit &edit,const double committedValue,const int digits)
     {
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      if(FusionIsDecimalText(text, true))
         return (MathAbs(StringToDouble(text) - committedValue) > 0.0000001);
      return (text != FusionNormalizeDecimalText(DoubleToString(committedValue, digits)));
     }

   bool                       HasRiskPendingChanges(void)
     {
      if(m_draftSettings.usePartialTP != m_committedSettings.usePartialTP)
         return true;
      if(m_draftSettings.freeFinalTP != m_committedSettings.freeFinalTP)
         return true;
      if(m_draftSettings.tp1.enabled != m_committedSettings.tp1.enabled)
         return true;
      if(m_draftSettings.tp2.enabled != m_committedSettings.tp2.enabled)
         return true;
      if(m_draftSettings.useBreakeven != m_committedSettings.useBreakeven)
         return true;
      if(m_draftSettings.useTrailing != m_committedSettings.useTrailing)
         return true;

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

         if(RiskIntegerPending(m_cfgRiskSLEdit, m_committedSettings.fixedSLPoints))
            return true;
         if(RiskIntegerPending(m_cfgRiskTPEdit, m_committedSettings.fixedTPPoints))
            return true;
         if(RiskDecimalPending(m_cfgRiskTP1PercentEdit, m_committedSettings.tp1.percent, 2))
            return true;
         if(RiskIntegerPending(m_cfgRiskTP1DistanceEdit, m_committedSettings.tp1.distancePoints))
            return true;
         if(RiskDecimalPending(m_cfgRiskTP2PercentEdit, m_committedSettings.tp2.percent, 2))
            return true;
         if(RiskIntegerPending(m_cfgRiskTP2DistanceEdit, m_committedSettings.tp2.distancePoints))
            return true;
         if(RiskIntegerPending(m_cfgRiskBreakevenTriggerEdit, m_committedSettings.breakevenTriggerPoints))
            return true;
         if(RiskIntegerPending(m_cfgRiskBreakevenOffsetEdit, m_committedSettings.breakevenOffsetPoints))
            return true;
         if(RiskIntegerPending(m_cfgRiskTrailingStartEdit, m_committedSettings.trailingStartPoints))
            return true;
         if(RiskIntegerPending(m_cfgRiskTrailingStepEdit, m_committedSettings.trailingStepPoints))
            return true;
        }
      else
        {
         if(MathAbs(m_draftSettings.fixedLot - m_committedSettings.fixedLot) > 0.0000001)
            return true;
         if(m_draftSettings.fixedSLPoints != m_committedSettings.fixedSLPoints)
            return true;
         if(m_draftSettings.fixedTPPoints != m_committedSettings.fixedTPPoints)
            return true;
         if(MathAbs(m_draftSettings.tp1.percent - m_committedSettings.tp1.percent) > 0.0000001)
            return true;
         if(m_draftSettings.tp1.distancePoints != m_committedSettings.tp1.distancePoints)
            return true;
         if(MathAbs(m_draftSettings.tp2.percent - m_committedSettings.tp2.percent) > 0.0000001)
            return true;
         if(m_draftSettings.tp2.distancePoints != m_committedSettings.tp2.distancePoints)
            return true;
         if(m_draftSettings.breakevenTriggerPoints != m_committedSettings.breakevenTriggerPoints)
            return true;
         if(m_draftSettings.breakevenOffsetPoints != m_committedSettings.breakevenOffsetPoints)
            return true;
         if(m_draftSettings.trailingStartPoints != m_committedSettings.trailingStartPoints)
            return true;
         if(m_draftSettings.trailingStepPoints != m_committedSettings.trailingStepPoints)
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

      if(m_draftSettings.conflictMode != m_committedSettings.conflictMode)
         return true;
      return (m_draftSettings.debugLogs != m_committedSettings.debugLogs);
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
      if(m_draftSettings.useRSIFilter != m_committedSettings.useRSIFilter)
         return true;
      return (m_draftSettings.bbFilterEnabled != m_committedSettings.bbFilterEnabled);
     }

   bool                       HasSignalParameterPendingChanges(void)
     {
      if(m_draftSettings.maFastTimeframe != m_committedSettings.maFastTimeframe)
         return true;
      if(m_draftSettings.maSlowTimeframe != m_committedSettings.maSlowTimeframe)
         return true;
      if(m_draftSettings.maCrossPriority != m_committedSettings.maCrossPriority)
         return true;
      if(m_draftSettings.maFastPeriod != m_committedSettings.maFastPeriod)
         return true;
      if(m_draftSettings.maSlowPeriod != m_committedSettings.maSlowPeriod)
         return true;
      if(m_draftSettings.maMinDistancePoints != m_committedSettings.maMinDistancePoints)
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
      if(m_draftSettings.rsiPriority != m_committedSettings.rsiPriority)
         return true;
      if(m_draftSettings.rsiPeriod != m_committedSettings.rsiPeriod)
         return true;
      if(m_draftSettings.rsiOversold != m_committedSettings.rsiOversold)
         return true;
      if(m_draftSettings.rsiOverbought != m_committedSettings.rsiOverbought)
         return true;
      if(m_draftSettings.rsiMiddle != m_committedSettings.rsiMiddle)
         return true;
      if(m_draftSettings.rsiMode != m_committedSettings.rsiMode)
         return true;
      if(m_draftSettings.rsiPrice != m_committedSettings.rsiPrice)
         return true;
      if(m_draftSettings.rsiExitMode != m_committedSettings.rsiExitMode)
         return true;
      if(m_draftSettings.bbPriority != m_committedSettings.bbPriority)
         return true;
      if(m_draftSettings.bbPeriod != m_committedSettings.bbPeriod)
         return true;
      if(m_draftSettings.bbTimeframe != m_committedSettings.bbTimeframe)
         return true;
      if(MathAbs(m_draftSettings.bbDeviation - m_committedSettings.bbDeviation) > 0.0000001)
         return true;
      if(m_draftSettings.bbPrice != m_committedSettings.bbPrice)
         return true;
      if(m_draftSettings.bbMode != m_committedSettings.bbMode)
         return true;
      if(m_draftSettings.bbExitMode != m_committedSettings.bbExitMode)
         return true;
      if(m_draftSettings.trendMAPeriod != m_committedSettings.trendMAPeriod)
         return true;
      if(m_draftSettings.trendMATimeframe != m_committedSettings.trendMATimeframe)
         return true;
      if(m_draftSettings.trendMAMethod != m_committedSettings.trendMAMethod)
         return true;
      if(m_draftSettings.trendMAPrice != m_committedSettings.trendMAPrice)
         return true;
      if(m_draftSettings.rsiFilterMode != m_committedSettings.rsiFilterMode)
         return true;
      if(m_draftSettings.rsiFilterPeriod != m_committedSettings.rsiFilterPeriod)
         return true;
      if(m_draftSettings.rsiFilterTimeframe != m_committedSettings.rsiFilterTimeframe)
         return true;
      if(m_draftSettings.rsiFilterBuyMin != m_committedSettings.rsiFilterBuyMin)
         return true;
      if(m_draftSettings.rsiFilterSellMax != m_committedSettings.rsiFilterSellMax)
         return true;
      if(m_draftSettings.rsiFilterPrice != m_committedSettings.rsiFilterPrice)
         return true;
      if(m_draftSettings.bbFilterMode != m_committedSettings.bbFilterMode)
         return true;
      if(m_draftSettings.bbFilterPeriod != m_committedSettings.bbFilterPeriod)
         return true;
      if(m_draftSettings.bbFilterTimeframe != m_committedSettings.bbFilterTimeframe)
         return true;
      if(MathAbs(m_draftSettings.bbFilterDeviation - m_committedSettings.bbFilterDeviation) > 0.0000001)
         return true;
      if(m_draftSettings.bbFilterPrice != m_committedSettings.bbFilterPrice)
         return true;
      if(m_draftSettings.bbFilterMinWidthPoints != m_committedSettings.bbFilterMinWidthPoints)
         return true;
      return (MathAbs(m_draftSettings.bbFilterMinWidthPercent - m_committedSettings.bbFilterMinWidthPercent) > 0.0000001);
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
      if(m_draftSettings.tradeDirection != m_committedSettings.tradeDirection)
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
      if(m_draftSettings.sessionOvernight != m_committedSettings.sessionOvernight)
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
      if(m_draftSettings.lossStreakEnabled != m_committedSettings.lossStreakEnabled)
         return true;
      if(m_draftSettings.maxLossStreak != m_committedSettings.maxLossStreak)
         return true;
      if(m_draftSettings.lossStreakAction != m_committedSettings.lossStreakAction)
         return true;
      if(m_draftSettings.lossStreakPauseMinutes != m_committedSettings.lossStreakPauseMinutes)
         return true;
      if(m_draftSettings.winStreakEnabled != m_committedSettings.winStreakEnabled)
         return true;
      if(m_draftSettings.maxWinStreak != m_committedSettings.maxWinStreak)
         return true;
      if(m_draftSettings.winStreakAction != m_committedSettings.winStreakAction)
         return true;
      if(m_draftSettings.winStreakPauseMinutes != m_committedSettings.winStreakPauseMinutes)
         return true;

      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
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
