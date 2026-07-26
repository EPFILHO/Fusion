#ifndef __FUSION_UI_PANEL_RISK_SYNC_MQH__
#define __FUSION_UI_PANEL_RISK_SYNC_MQH__

   void                       SyncRiskControls(void)
     {
      if(!m_configRiskCreated)
         return;

      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSlippageEdit.Text(IntegerToString(m_draftSettings.slippagePoints));
      m_cfgRiskSLEdit.Text(IntegerToString(m_draftSettings.fixedSLPoints));
      m_cfgRiskTPEdit.Text(IntegerToString(m_draftSettings.fixedTPPoints));
      m_cfgRiskTP1PercentEdit.Text(DoubleToString(m_draftSettings.tp1.percent, 2));
      m_cfgRiskTP1DistanceEdit.Text(IntegerToString(m_draftSettings.tp1.distancePoints));
      m_cfgRiskTP2PercentEdit.Text(DoubleToString(m_draftSettings.tp2.percent, 2));
      m_cfgRiskTP2DistanceEdit.Text(IntegerToString(m_draftSettings.tp2.distancePoints));
      m_cfgRiskBreakevenTriggerEdit.Text(IntegerToString(m_draftSettings.breakevenTriggerPoints));
      m_cfgRiskBreakevenOffsetEdit.Text(IntegerToString(m_draftSettings.breakevenOffsetPoints));
      m_cfgRiskTrailingStartEdit.Text(IntegerToString(m_draftSettings.trailingStartPoints));
      m_cfgRiskTrailingStepEdit.Text(IntegerToString(m_draftSettings.trailingStepPoints));
     }

   void                       ApplyRiskTabStyles(void)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
        {
         ENUM_FUSION_RISK_PAGE page = (ENUM_FUSION_RISK_PAGE)tabIndex;
         bool runtimeStopsError = (page == FUSION_RISK_SLTP &&
                                   m_snapshot.entryBlockIsRiskStops);
         if(runtimeStopsError)
            FusionApplyActionButtonStyle(m_riskTabs[tabIndex], FUSION_CLR_BAD, true);
         else if(tabIndex == (int)m_riskPage)
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], true);
         else if(RiskSubtabHasError(page))
            FusionApplyActionButtonStyle(m_riskTabs[tabIndex], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], false);
        }
     }

#endif
