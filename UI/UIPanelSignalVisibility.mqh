#ifndef __FUSION_UI_PANEL_SIGNAL_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_SIGNAL_VISIBILITY_MQH__

   void                       SetStrategiesVisible(const bool visible)
     {
      SetVisible(m_strategyGroup, visible);
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         SetVisible(m_strategyTabs[i], visible);
      SetVisible(m_strategyTabsSeparator, visible);
      SetVisible(m_strategyContentFrame, visible);
      if(visible)
         RestoreStrategyStatus();
      SetVisible(m_strategyStatus, visible);

      bool overviewVisible = visible && m_strategyPage == FUSION_STRAT_OVERVIEW;
      if(overviewVisible)
         UpdateStrategyOverview();
      if(m_strategyOverviewCreated)
        {
         SetVisible(m_strategyOverviewGroup, overviewVisible);
         SetVisible(m_strategyOverviewHdr, overviewVisible);
         for(int j = 0; j < FUSION_STRATEGY_PANEL_COUNT; ++j)
           {
            SetVisible(m_strategyOverviewName[j], overviewVisible);
            SetVisible(m_strategyOverviewState[j], overviewVisible);
           }
        }

      for(int p = 0; p < FUSION_STRATEGY_PANEL_COUNT; ++p)
        {
         if(!m_strategyPanelCreated[p] || m_strategyPanels[p] == NULL)
            continue;
         if(visible && m_strategyPage == (ENUM_FUSION_STRATEGY_PAGE)(p + 1))
           {
            SetVisible(m_strategyPanelGroups[p], true);
            m_strategyPanels[p].Show();
           }
         else
           {
            m_strategyPanels[p].Hide();
            SetVisible(m_strategyPanelGroups[p], false);
           }
        }
     }

   void                       SetFiltersVisible(const bool visible)
     {
      SetVisible(m_filterGroup, visible);
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         SetVisible(m_filterTabs[i], visible);
      SetVisible(m_filterTabsSeparator, visible);
      SetVisible(m_filterContentFrame, visible);
      if(visible)
         RestoreFilterStatus();
      SetVisible(m_filterStatus, visible);

      bool overviewVisible = visible && m_filterPage == FUSION_FILTER_OVERVIEW;
      if(overviewVisible)
         UpdateFilterOverview();
      if(m_filterOverviewCreated)
        {
         SetVisible(m_filterOverviewGroup, overviewVisible);
         SetVisible(m_filterOverviewHdr, overviewVisible);
         for(int j = 0; j < FUSION_FILTER_PANEL_COUNT; ++j)
           {
            SetVisible(m_filterOverviewName[j], overviewVisible);
            SetVisible(m_filterOverviewState[j], overviewVisible);
           }
        }

      for(int p = 0; p < FUSION_FILTER_PANEL_COUNT; ++p)
        {
         if(!m_filterPanelCreated[p] || m_filterPanels[p] == NULL)
            continue;
         if(visible && m_filterPage == (ENUM_FUSION_FILTER_PAGE)(p + 1))
           {
            SetVisible(m_filterPanelGroups[p], true);
            m_filterPanels[p].Show();
           }
         else
           {
            m_filterPanels[p].Hide();
            SetVisible(m_filterPanelGroups[p], false);
           }
        }
     }

#endif
