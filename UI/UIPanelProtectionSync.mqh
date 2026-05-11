#ifndef __FUSION_UI_PANEL_PROTECTION_SYNC_MQH__
#define __FUSION_UI_PANEL_PROTECTION_SYNC_MQH__

   void                       SyncProtectionOverview(void)
     {
      m_protectGeneralValues[0].Text(!m_draftSettings.enableSpreadProtection ? "OFF" : "Max " + IntegerToString(m_draftSettings.maxSpreadPoints) + " pts");
      m_protectGeneralValues[1].Text(!m_draftSettings.enableSessionFilter ? "OFF" :
                                     StringFormat("%02d:%02d - %02d:%02d",
                                                  m_draftSettings.sessionStartHour,
                                                  m_draftSettings.sessionStartMinute,
                                                  m_draftSettings.sessionEndHour,
                                                  m_draftSettings.sessionEndMinute));

      int newsEnabled = 0;
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
         if(m_draftSettings.newsWindows[newsIndex].enabled)
            newsEnabled++;
      m_protectGeneralValues[2].Text(IntegerToString(newsEnabled) + "/" + IntegerToString(FUSION_NEWS_WINDOW_COUNT) + " janelas ativas");
      m_protectGeneralValues[3].Text(StringFormat("Trades %d | P/L %.2f", m_snapshot.dailyTradeCount, m_snapshot.dailyClosedProfit));
      m_protectGeneralValues[4].Text(!m_draftSettings.enableDrawdown ? "OFF" :
                                     (m_snapshot.drawdownProtectionActive ? "ATIVO" : "Aguardando meta"));
      m_protectGeneralValues[5].Text(StringFormat("Loss %d | Win %d", m_snapshot.lossStreak, m_snapshot.winStreak));
     }

   void                       RefreshProtectionTheme(void)
     {
      bool editable = CanEditActiveProfile();

      ApplyProtectionTabStyles();

      SyncProtectionOverview();

      FusionApplyToggleButtonStyle(m_protectSpreadEnabledBtn, m_draftSettings.enableSpreadProtection, editable);
      FusionApplyToggleButtonStyle(m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter, editable);
      FusionApplyToggleButtonStyle(m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd, editable);

      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         FusionApplyToggleButtonStyle(m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled, editable);
         ApplyProtectModeButtonStyle(m_protectNewsModeBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].action, editable);
        }

      FusionApplyToggleButtonStyle(m_protectDayEnabledBtn, m_draftSettings.enableDailyLimits, editable);
      FusionApplyToggleButtonStyle(m_protectDrawdownEnabledBtn, m_draftSettings.enableDrawdown, editable);
      FusionApplyToggleButtonStyle(m_protectStreakEnabledBtn, m_draftSettings.enableStreak, editable);
     }

   void                       SyncProtectionControls(void)
     {
      RefreshProtectionTheme();
      FusionApplyEditStyle(m_protectSpreadLimitEdit, true, CanEditActiveProfile());
      m_protectSpreadLimitEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_protectSessionStartHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartHour));
      m_protectSessionStartMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartMinute));
      m_protectSessionEndHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndHour));
      m_protectSessionEndMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndMinute));
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         m_protectNewsStartHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startHour));
         m_protectNewsStartMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startMinute));
         m_protectNewsEndHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endHour));
         m_protectNewsEndMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endMinute));
        }
      m_protectDayTradesEdit.Text(IntegerToString(m_draftSettings.maxDailyTrades));
      m_protectDayLossEdit.Text(DoubleToString(m_draftSettings.maxDailyLoss, 2));
      m_protectDayGainEdit.Text(DoubleToString(m_draftSettings.maxDailyGain, 2));
      m_protectDrawdownValueEdit.Text(DoubleToString(m_draftSettings.maxDrawdown, 2));
      m_protectStreakLossEdit.Text(IntegerToString(m_draftSettings.maxLossStreak));
      m_protectStreakWinEdit.Text(IntegerToString(m_draftSettings.maxWinStreak));
     }

#endif
