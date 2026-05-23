#ifndef __FUSION_UI_PANEL_PROTECTION_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_PROTECTION_VISIBILITY_MQH__

   void                       SetProtectionGeneralVisible(const bool visible)
     {
      SetVisible(m_protectGeneralHdr, visible);
      for(int generalIndex = 0; generalIndex < FUSION_PROTECT_OVERVIEW_COUNT; ++generalIndex)
        {
         SetVisible(m_protectGeneralLabels[generalIndex], visible);
         SetVisible(m_protectGeneralValues[generalIndex], visible);
        }
     }

   void                       SetProtectionEntryVisible(const bool visible)
     {
      SetVisible(m_protectSpreadHdr, visible);
      SetVisible(m_protectSpreadDesc, visible);
      SetVisible(m_protectSpreadEnabledLbl, visible);
      SetVisible(m_protectSpreadEnabledBtn, visible);
      SetVisible(m_protectSpreadLimitLbl, visible);
      SetVisible(m_protectSpreadLimitEdit, visible);
      if(visible)
         m_protectDirection.Show();
      else
         m_protectDirection.Hide();
     }

   void                       SetProtectionSessionVisible(const bool visible)
     {
      SetVisible(m_protectSessionHdr, visible);
      SetVisible(m_protectSessionDesc, visible);
      SetVisible(m_protectSessionEnabledLbl, visible);
      SetVisible(m_protectSessionEnabledBtn, visible);
      SetVisible(m_protectSessionStartLbl, visible);
      SetVisible(m_protectSessionStartHourEdit, visible);
      SetVisible(m_protectSessionStartMinuteEdit, visible);
      SetVisible(m_protectSessionEndLbl, visible);
      SetVisible(m_protectSessionEndHourEdit, visible);
      SetVisible(m_protectSessionEndMinuteEdit, visible);
      SetVisible(m_protectSessionCloseLbl, visible);
      SetVisible(m_protectSessionCloseBtn, visible);
     }

   void                       SetProtectionNewsVisible(const bool visible)
     {
      SetVisible(m_protectNewsHdr, visible);
      SetVisible(m_protectNewsDesc, visible);
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         SetVisible(m_protectNewsBlockHdr[newsIndex], visible);
         SetVisible(m_protectNewsEnabledLbl[newsIndex], visible);
         SetVisible(m_protectNewsEnabledBtn[newsIndex], visible);
         SetVisible(m_protectNewsStartLbl[newsIndex], visible);
         SetVisible(m_protectNewsStartHourEdit[newsIndex], visible);
         SetVisible(m_protectNewsStartMinuteEdit[newsIndex], visible);
         SetVisible(m_protectNewsEndLbl[newsIndex], visible);
         SetVisible(m_protectNewsEndHourEdit[newsIndex], visible);
         SetVisible(m_protectNewsEndMinuteEdit[newsIndex], visible);
         SetVisible(m_protectNewsModeLbl[newsIndex], visible);
         SetVisible(m_protectNewsModeBtn[newsIndex], visible);
        }
     }

   void                       SetProtectionDayVisible(const bool visible)
     {
      SetVisible(m_protectDayHdr, visible);
      SetVisible(m_protectDayDesc, visible);
      SetVisible(m_protectDayEnabledLbl, visible);
      SetVisible(m_protectDayEnabledBtn, visible);
      SetVisible(m_protectDayTradesLbl, visible);
      SetVisible(m_protectDayTradesEdit, visible);
      SetVisible(m_protectDayLossLbl, visible);
      SetVisible(m_protectDayLossEdit, visible);
      SetVisible(m_protectDayGainLbl, visible);
      SetVisible(m_protectDayGainEdit, visible);
     }

   void                       SetProtectionDrawdownVisible(const bool visible)
     {
      SetVisible(m_protectDrawdownHdr, visible);
      SetVisible(m_protectDrawdownDesc, visible);
      SetVisible(m_protectDrawdownEnabledLbl, visible);
      SetVisible(m_protectDrawdownEnabledBtn, visible);
      SetVisible(m_protectDrawdownValueLbl, visible);
      SetVisible(m_protectDrawdownValueEdit, visible);
      SetVisible(m_protectDrawdownNote, visible);
     }

   void                       SetProtectionStreakVisible(const bool visible)
     {
      SetVisible(m_protectStreakHdr, visible);
      SetVisible(m_protectStreakDesc, visible);
      SetVisible(m_protectStreakEnabledLbl, visible);
      SetVisible(m_protectStreakEnabledBtn, visible);
      SetVisible(m_protectStreakLossLbl, visible);
      SetVisible(m_protectStreakLossEdit, visible);
      SetVisible(m_protectStreakWinLbl, visible);
      SetVisible(m_protectStreakWinEdit, visible);
     }

   void                       SetAllProtectionPagesVisible(const bool visible)
     {
      SetProtectionGeneralVisible(visible);
      SetProtectionEntryVisible(visible);
      SetProtectionSessionVisible(visible);
      SetProtectionNewsVisible(visible);
      SetProtectionDayVisible(visible);
      SetProtectionDrawdownVisible(visible);
      SetProtectionStreakVisible(visible);
     }

   void                       SetActiveProtectionPageVisible(const ENUM_FUSION_PROTECT_PAGE page,const bool visible)
     {
      if(page == FUSION_PROTECT_GENERAL)
         SetProtectionGeneralVisible(visible);
      else if(page == FUSION_PROTECT_SPREAD)
         SetProtectionEntryVisible(visible);
      else if(page == FUSION_PROTECT_SESSION)
         SetProtectionSessionVisible(visible);
      else if(page == FUSION_PROTECT_NEWS)
         SetProtectionNewsVisible(visible);
      else if(page == FUSION_PROTECT_DAY)
         SetProtectionDayVisible(visible);
      else if(page == FUSION_PROTECT_DRAWDOWN)
         SetProtectionDrawdownVisible(visible);
      else if(page == FUSION_PROTECT_STREAK)
         SetProtectionStreakVisible(visible);
     }

   void                       SetProtectionControlsVisible(const ENUM_FUSION_PROTECT_PAGE page,const bool visible)
     {
      SetVisible(m_protectTabsSeparator, visible);
      SetVisible(m_protectContentFrame, visible);

      SetAllProtectionPagesVisible(false);

      if(visible)
         SetActiveProtectionPageVisible(page, true);
     }

#endif
