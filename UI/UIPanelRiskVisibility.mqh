#ifndef __FUSION_UI_PANEL_RISK_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_RISK_VISIBILITY_MQH__

   void                       SetRiskLotVisible(const bool visible)
     {
      SetVisible(m_cfgRiskLotHdr, visible);
      SetVisible(m_cfgRiskLotDesc, visible);
      SetVisible(m_cfgRiskLotLbl, visible);
      SetVisible(m_cfgRiskLotEdit, visible);
      SetVisible(m_cfgRiskSlippageLbl, visible);
      SetVisible(m_cfgRiskSlippageEdit, visible);
      SetVisible(m_cfgRiskLotFoot1, visible);
      SetVisible(m_cfgRiskLotFoot2, visible);
     }

   void                       SetRiskSLTPVisible(const bool visible)
     {
      SetVisible(m_cfgRiskSLTPHdr, visible);
      SetVisible(m_cfgRiskSLTPDesc, visible);
      SetVisible(m_cfgRiskSLLbl, visible);
      SetVisible(m_cfgRiskSLEdit, visible);
      SetVisible(m_cfgRiskTPLbl, visible);
      SetVisible(m_cfgRiskTPEdit, visible);
      SetVisible(m_cfgRiskSLCompLbl, visible);
      SetVisible(m_cfgRiskSLCompBtn, visible);
      SetVisible(m_cfgRiskTPCompLbl, visible);
      SetVisible(m_cfgRiskTPCompBtn, visible);
      SetVisible(m_cfgRiskSLTPFoot1, visible);
      SetVisible(m_cfgRiskSLTPFoot2, visible);
      SetVisible(m_cfgRiskSLTPFoot3, visible);
     }

   void                       SetRiskPartialVisible(const bool visible)
     {
      SetVisible(m_cfgRiskPartialHdr, visible);
      SetVisible(m_cfgRiskPartialDesc, visible);
      SetVisible(m_cfgRiskTP1Hdr, visible);
      SetVisible(m_cfgRiskTP1EnabledLbl, visible);
      SetVisible(m_cfgRiskTP1EnabledBtn, visible);
      SetVisible(m_cfgRiskTP1PercentLbl, visible);
      SetVisible(m_cfgRiskTP1PercentEdit, visible);
      SetVisible(m_cfgRiskTP1DistanceLbl, visible);
      SetVisible(m_cfgRiskTP1DistanceEdit, visible);
      SetVisible(m_cfgRiskTP2Hdr, visible);
      SetVisible(m_cfgRiskTP2EnabledLbl, visible);
      SetVisible(m_cfgRiskTP2EnabledBtn, visible);
      SetVisible(m_cfgRiskTP2PercentLbl, visible);
      SetVisible(m_cfgRiskTP2PercentEdit, visible);
      SetVisible(m_cfgRiskTP2DistanceLbl, visible);
      SetVisible(m_cfgRiskTP2DistanceEdit, visible);
      SetVisible(m_cfgRiskFreeTPLbl, visible);
      SetVisible(m_cfgRiskFreeTPBtn, visible);
      SetVisible(m_cfgRiskPartialFoot1, visible);
      SetVisible(m_cfgRiskPartialFoot2, visible);
      SetVisible(m_cfgRiskPartialFoot3, visible);
     }

   void                       SetRiskBreakevenVisible(const bool visible)
     {
      SetVisible(m_cfgRiskBreakevenHdr, visible);
      SetVisible(m_cfgRiskBreakevenDesc, visible);
      SetVisible(m_cfgRiskBreakevenEnabledLbl, visible);
      SetVisible(m_cfgRiskBreakevenEnabledBtn, visible);
      SetVisible(m_cfgRiskBreakevenTriggerLbl, visible);
      SetVisible(m_cfgRiskBreakevenTriggerEdit, visible);
      SetVisible(m_cfgRiskBreakevenOffsetLbl, visible);
      SetVisible(m_cfgRiskBreakevenOffsetEdit, visible);
      SetVisible(m_cfgRiskBreakevenFoot1, visible);
      SetVisible(m_cfgRiskBreakevenFoot2, visible);
     }

   void                       SetRiskTrailingVisible(const bool visible)
     {
      SetVisible(m_cfgRiskTrailingHdr, visible);
      SetVisible(m_cfgRiskTrailingDesc, visible);
      SetVisible(m_cfgRiskTrailingEnabledLbl, visible);
      SetVisible(m_cfgRiskTrailingEnabledBtn, visible);
      SetVisible(m_cfgRiskTrailingStartLbl, visible);
      SetVisible(m_cfgRiskTrailingStartEdit, visible);
      SetVisible(m_cfgRiskTrailingStepLbl, visible);
      SetVisible(m_cfgRiskTrailingStepEdit, visible);
      SetVisible(m_cfgRiskTrailingFoot1, visible);
      SetVisible(m_cfgRiskTrailingFoot2, visible);
     }

   void                       SetAllRiskPagesVisible(const bool visible)
     {
      SetRiskLotVisible(visible);
      SetRiskSLTPVisible(visible);
      SetRiskPartialVisible(visible);
      SetRiskBreakevenVisible(visible);
      SetRiskTrailingVisible(visible);
     }

   void                       SetActiveRiskPageVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      if(page == FUSION_RISK_LOT)
         SetRiskLotVisible(visible);
      else if(page == FUSION_RISK_SLTP)
         SetRiskSLTPVisible(visible);
      else if(page == FUSION_RISK_PARTIAL)
         SetRiskPartialVisible(visible);
      else if(page == FUSION_RISK_BREAKEVEN)
         SetRiskBreakevenVisible(visible);
      else if(page == FUSION_RISK_TRAILING)
         SetRiskTrailingVisible(visible);
     }

   void                       SetRiskControlsVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
         SetVisible(m_riskTabs[tabIndex], visible);
      SetVisible(m_riskTabsSeparator, visible);
      SetVisible(m_riskContentFrame, visible);

      SetAllRiskPagesVisible(false);

      if(visible)
         SetActiveRiskPageVisible(page, true);
     }

   bool                       EnsureConfigRiskPageCreated(void)
     {
      if(m_configRiskCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configRiskGroup);
      if(!BuildConfigRiskPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configRiskCreated = true;
      SetRiskControlsVisible(m_riskPage, false);
      SyncRiskControls();
      return true;
     }

#endif
