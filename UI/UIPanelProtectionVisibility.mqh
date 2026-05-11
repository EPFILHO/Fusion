#ifndef __FUSION_UI_PANEL_PROTECTION_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_PROTECTION_VISIBILITY_MQH__

   void                       SetProtectionControlsVisible(const ENUM_FUSION_PROTECT_PAGE page,const bool visible)
     {
      bool showGeneral = visible && page == FUSION_PROTECT_GENERAL;
      SetVisible(m_protectTabsSeparator, visible);
      SetVisible(m_protectContentFrame, visible);
      SetVisible(m_protectGeneralHdr, showGeneral);
      for(int generalIndex = 0; generalIndex < FUSION_PROTECT_OVERVIEW_COUNT; ++generalIndex)
        {
         SetVisible(m_protectGeneralLabels[generalIndex], showGeneral);
         SetVisible(m_protectGeneralValues[generalIndex], showGeneral);
        }

      bool showSpread = visible && page == FUSION_PROTECT_SPREAD;
      SetVisible(m_protectSpreadHdr, showSpread);
      SetVisible(m_protectSpreadDesc, showSpread);
      SetVisible(m_protectSpreadEnabledLbl, showSpread);
      SetVisible(m_protectSpreadEnabledBtn, showSpread);
      SetVisible(m_protectSpreadLimitLbl, showSpread);
      SetVisible(m_protectSpreadLimitEdit, showSpread);

      bool showSession = visible && page == FUSION_PROTECT_SESSION;
      SetVisible(m_protectSessionHdr, showSession);
      SetVisible(m_protectSessionDesc, showSession);
      SetVisible(m_protectSessionEnabledLbl, showSession);
      SetVisible(m_protectSessionEnabledBtn, showSession);
      SetVisible(m_protectSessionStartLbl, showSession);
      SetVisible(m_protectSessionStartHourEdit, showSession);
      SetVisible(m_protectSessionStartMinuteEdit, showSession);
      SetVisible(m_protectSessionEndLbl, showSession);
      SetVisible(m_protectSessionEndHourEdit, showSession);
      SetVisible(m_protectSessionEndMinuteEdit, showSession);
      SetVisible(m_protectSessionCloseLbl, showSession);
      SetVisible(m_protectSessionCloseBtn, showSession);

      bool showNews = visible && page == FUSION_PROTECT_NEWS;
      SetVisible(m_protectNewsHdr, showNews);
      SetVisible(m_protectNewsDesc, showNews);
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         SetVisible(m_protectNewsBlockHdr[newsIndex], showNews);
         SetVisible(m_protectNewsEnabledLbl[newsIndex], showNews);
         SetVisible(m_protectNewsEnabledBtn[newsIndex], showNews);
         SetVisible(m_protectNewsStartLbl[newsIndex], showNews);
         SetVisible(m_protectNewsStartHourEdit[newsIndex], showNews);
         SetVisible(m_protectNewsStartMinuteEdit[newsIndex], showNews);
         SetVisible(m_protectNewsEndLbl[newsIndex], showNews);
         SetVisible(m_protectNewsEndHourEdit[newsIndex], showNews);
         SetVisible(m_protectNewsEndMinuteEdit[newsIndex], showNews);
         SetVisible(m_protectNewsModeLbl[newsIndex], showNews);
         SetVisible(m_protectNewsModeBtn[newsIndex], showNews);
        }

      bool showDay = visible && page == FUSION_PROTECT_DAY;
      SetVisible(m_protectDayHdr, showDay);
      SetVisible(m_protectDayDesc, showDay);
      SetVisible(m_protectDayEnabledLbl, showDay);
      SetVisible(m_protectDayEnabledBtn, showDay);
      SetVisible(m_protectDayTradesLbl, showDay);
      SetVisible(m_protectDayTradesEdit, showDay);
      SetVisible(m_protectDayLossLbl, showDay);
      SetVisible(m_protectDayLossEdit, showDay);
      SetVisible(m_protectDayGainLbl, showDay);
      SetVisible(m_protectDayGainEdit, showDay);

      bool showDrawdown = visible && page == FUSION_PROTECT_DRAWDOWN;
      SetVisible(m_protectDrawdownHdr, showDrawdown);
      SetVisible(m_protectDrawdownDesc, showDrawdown);
      SetVisible(m_protectDrawdownEnabledLbl, showDrawdown);
      SetVisible(m_protectDrawdownEnabledBtn, showDrawdown);
      SetVisible(m_protectDrawdownValueLbl, showDrawdown);
      SetVisible(m_protectDrawdownValueEdit, showDrawdown);
      SetVisible(m_protectDrawdownNote, showDrawdown);

      bool showStreak = visible && page == FUSION_PROTECT_STREAK;
      SetVisible(m_protectStreakHdr, showStreak);
      SetVisible(m_protectStreakDesc, showStreak);
      SetVisible(m_protectStreakEnabledLbl, showStreak);
      SetVisible(m_protectStreakEnabledBtn, showStreak);
      SetVisible(m_protectStreakLossLbl, showStreak);
      SetVisible(m_protectStreakLossEdit, showStreak);
      SetVisible(m_protectStreakWinLbl, showStreak);
      SetVisible(m_protectStreakWinEdit, showStreak);
     }

#endif
