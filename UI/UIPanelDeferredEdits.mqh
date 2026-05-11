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

   bool                       IsDeferredRefreshEdit(const string objectName)
     {
      if(objectName == m_profileNewEdit.Name())
         return true;
      if(objectName == m_profileMagicEdit.Name())
         return true;
      if(IsStrategyDeferredEdit(objectName))
         return true;
      if(m_configRiskCreated && objectName == m_cfgRiskLotEdit.Name())
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

   void                       NormalizeStrategyDeferredEdit(const string objectName)
     {
      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         if(m_strategyPanels[sp] == NULL || !m_strategyPanels[sp].IsDeferredEdit(objectName))
            continue;
         m_strategyPanels[sp].NormalizeDeferredEdit(objectName);
        }
     }

   void                       HandleDeferredRefreshEvent(const int id,const string objectName)
     {
      HandleStrategyPanelDeferredEdit(objectName);
      if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         NormalizeStrategyDeferredEdit(objectName);
         NormalizeProtectionDeferredEdit(objectName);
        }
      RefreshConfigValidation();
      ChartRedraw();
     }

#endif
