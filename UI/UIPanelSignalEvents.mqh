#ifndef __FUSION_UI_PANEL_SIGNAL_EVENTS_MQH__
#define __FUSION_UI_PANEL_SIGNAL_EVENTS_MQH__

   void                       SyncStrategyPanels(void)
     {
      for(int i = 0; i < FUSION_STRATEGY_PANEL_COUNT; ++i)
         if(m_strategyPanels[i] != NULL)
             m_strategyPanels[i].Sync(m_draftSettings, CanEditActiveProfile());
     }

   void                       SyncFilterPanels(void)
     {
      for(int j = 0; j < FUSION_FILTER_PANEL_COUNT; ++j)
         if(m_filterPanels[j] != NULL)
             m_filterPanels[j].Sync(m_draftSettings, CanEditActiveProfile());
     }

   void                       RefreshSignalDraftViews(const bool syncStrategies,const bool syncFilters)
     {
      if(m_strategyTabCreated || m_filterTabCreated)
         UpdateOverviews();
      if(syncStrategies && m_strategyTabCreated)
         SyncStrategyPanels();
      if(syncFilters && m_filterTabCreated)
         SyncFilterPanels();
     }

   bool                       HandleSignalPanelClick(const string objectName)
     {
      SUICommand tempCommand;
      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_strategyPanels[sp].HandleClick(objectName, tempCommand))
           {
            if(!TryBeginActiveProfileEdit())
               return true;
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            RefreshSignalDraftViews(true, false);
            return true;
           }
        }

      for(int fp = 0; fp < FUSION_FILTER_PANEL_COUNT; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_filterPanels[fp].HandleClick(objectName, tempCommand))
           {
            if(!TryBeginActiveProfileEdit())
               return true;
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, true);
            return true;
           }
        }

      return false;
     }

   bool                       HandleSignalPanelChange(const int id,const string objectName)
     {
      if(id != CHARTEVENT_CUSTOM + ON_CHANGE)
         return false;

      if(!TryBeginActiveProfileEdit())
         return false;

      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         if(m_strategyPanels[sp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, false);
            return true;
           }
        }

      for(int fp = 0; fp < FUSION_FILTER_PANEL_COUNT; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         if(m_filterPanels[fp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, true);
            return true;
           }
        }

      return false;
     }

#endif
