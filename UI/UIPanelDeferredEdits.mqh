#ifndef __FUSION_UI_PANEL_DEFERRED_EDITS_MQH__
#define __FUSION_UI_PANEL_DEFERRED_EDITS_MQH__

   bool                       IsStrategyDeferredEdit(const string objectName)
     {
      for(int strategyIndex = 0; strategyIndex < FUSION_STRATEGY_PANEL_COUNT; ++strategyIndex)
        {
         if(m_strategyPanels[strategyIndex] != NULL && m_strategyPanels[strategyIndex].IsDeferredEdit(objectName))
            return true;
        }
      return false;
     }

   bool                       IsFilterDeferredEdit(const string objectName)
     {
      for(int filterIndex = 0; filterIndex < FUSION_FILTER_PANEL_COUNT; ++filterIndex)
        {
         if(m_filterPanels[filterIndex] != NULL && m_filterPanels[filterIndex].IsDeferredEdit(objectName))
            return true;
        }
      return false;
     }

   bool                       IsDeferredRefreshEdit(const string objectName)
     {
      if(objectName == m_profileNewEdit.Name())
         return true;
      if(objectName == m_profileMagicEdit.Name())
         return true;
      if(IsStrategyDeferredEdit(objectName))
         return true;
      if(IsFilterDeferredEdit(objectName))
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskLotEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskSLEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskTPEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskTP1PercentEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskTP1DistanceEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskTP2PercentEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskTP2DistanceEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskBreakevenTriggerEdit.Name())
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskBreakevenOffsetEdit.Name())
         return true;
      if(m_configSystemCreated && objectName == m_cfgSystemMagicEdit.Name())
         return true;
      if(IsProtectionDeferredEdit(objectName))
         return true;
      return false;
     }

   bool                       IsDeferredRefreshEvent(const int id,const string objectName)
     {
      if(id != CHARTEVENT_OBJECT_ENDEDIT && id != CHARTEVENT_OBJECT_CHANGE)
         return false;
      return IsDeferredRefreshEdit(objectName);
     }

   bool                       HandleStrategyPanelDeferredEdit(const string objectName)
     {
      if(!IsStrategyDeferredEdit(objectName))
         return false;

      if(!TryBeginActiveProfileEdit(false))
        {
         SyncStrategyPanels();
         return false;
        }

      bool changed = false;
      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         if(m_strategyPanels[sp] == NULL || !m_strategyPanels[sp].IsDeferredEdit(objectName))
            continue;
         m_strategyPanels[sp].HandleChange(objectName, m_draftSettings);
         changed = true;
        }

      if(changed)
         RefreshSignalDraftViews(true, false);

      return changed;
     }

   bool                       HandleFilterPanelDeferredEdit(const string objectName)
     {
      if(!IsFilterDeferredEdit(objectName))
         return false;

      if(!TryBeginActiveProfileEdit(false))
        {
         SyncFilterPanels();
         return false;
        }

      bool changed = false;
      for(int fp = 0; fp < FUSION_FILTER_PANEL_COUNT; ++fp)
        {
         if(m_filterPanels[fp] == NULL || !m_filterPanels[fp].IsDeferredEdit(objectName))
            continue;
         m_filterPanels[fp].HandleChange(objectName, m_draftSettings);
         changed = true;
        }

      if(changed)
         RefreshSignalDraftViews(false, true);

      return changed;
     }

   void                       NormalizeStrategyDeferredEdit(const string objectName)
     {
      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         if(m_strategyPanels[sp] == NULL || !m_strategyPanels[sp].IsDeferredEdit(objectName))
            continue;
         m_strategyPanels[sp].NormalizeDeferredEdit(objectName);
        }
     }

   void                       NormalizeFilterDeferredEdit(const string objectName)
     {
      for(int fp = 0; fp < FUSION_FILTER_PANEL_COUNT; ++fp)
        {
         if(m_filterPanels[fp] == NULL || !m_filterPanels[fp].IsDeferredEdit(objectName))
            continue;
         m_filterPanels[fp].NormalizeDeferredEdit(objectName);
        }
     }

   void                       NormalizeProfileDeferredEdit(const string objectName)
     {
      if(m_profilesEditCreated && objectName == m_profileMagicEdit.Name())
         NormalizeIntegerEdit(m_profileMagicEdit, m_draftSettings.magicNumber, false, 10);
     }

   void                       NormalizeConfigDeferredEdit(const string objectName)
     {
      if(m_configRiskCreated && objectName == m_cfgRiskLotEdit.Name())
         NormalizeVolumeEdit(m_cfgRiskLotEdit, m_draftSettings.fixedLot);
      else if(m_configRiskCreated && objectName == m_cfgRiskSLEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskSLEdit, m_draftSettings.fixedSLPoints, true, 6);
      else if(m_configRiskCreated && objectName == m_cfgRiskTPEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskTPEdit, m_draftSettings.fixedTPPoints, true, 6);
      else if(m_configRiskCreated && objectName == m_cfgRiskTP1PercentEdit.Name())
         NormalizeDecimalEdit(m_cfgRiskTP1PercentEdit, m_draftSettings.tp1.percent, 2, true);
      else if(m_configRiskCreated && objectName == m_cfgRiskTP1DistanceEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskTP1DistanceEdit, m_draftSettings.tp1.distancePoints, true, 6);
      else if(m_configRiskCreated && objectName == m_cfgRiskTP2PercentEdit.Name())
         NormalizeDecimalEdit(m_cfgRiskTP2PercentEdit, m_draftSettings.tp2.percent, 2, true);
      else if(m_configRiskCreated && objectName == m_cfgRiskTP2DistanceEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskTP2DistanceEdit, m_draftSettings.tp2.distancePoints, true, 6);
      else if(m_configRiskCreated && objectName == m_cfgRiskBreakevenTriggerEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskBreakevenTriggerEdit, m_draftSettings.breakevenTriggerPoints, true, 6);
      else if(m_configRiskCreated && objectName == m_cfgRiskBreakevenOffsetEdit.Name())
         NormalizeIntegerEdit(m_cfgRiskBreakevenOffsetEdit, m_draftSettings.breakevenOffsetPoints, true, 6);
      else if(m_configSystemCreated && objectName == m_cfgSystemMagicEdit.Name())
         NormalizeIntegerEdit(m_cfgSystemMagicEdit, m_draftSettings.magicNumber, false, 10);
     }

   void                       HandleDeferredRefreshEvent(const int id,const string objectName)
     {
      HandleStrategyPanelDeferredEdit(objectName);
      HandleFilterPanelDeferredEdit(objectName);
      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         NormalizeStrategyDeferredEdit(objectName);
         NormalizeFilterDeferredEdit(objectName);
         NormalizeProtectionDeferredEdit(objectName);
         NormalizeConfigDeferredEdit(objectName);
         NormalizeProfileDeferredEdit(objectName);
        }
      RefreshConfigValidation();
      ChartRedraw();
     }

#endif
