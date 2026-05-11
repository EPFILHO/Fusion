#ifndef __FUSION_UI_PANEL_CONTENT_LIFECYCLE_MQH__
#define __FUSION_UI_PANEL_CONTENT_LIFECYCLE_MQH__

   bool                       EnsureStatusPageCreated(void)
     {
      if(m_statusPageCreated)
         return true;
      if(!AddHitGroup(m_statusGroup, "Fusion_group_status"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_statusGroup);
      bool created = m_statusPage.Create(GetPointer(this), m_chartId, m_subWindow);
      PopBuildTarget(previous);
      if(!created)
         return false;
      m_statusPageCreated = true;
      return true;
     }

   bool                       EnsureResultsPageCreated(void)
     {
      if(m_resultsPageCreated)
         return true;
      if(!AddHitGroup(m_resultsGroup, "Fusion_group_results"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_resultsGroup);
      bool created = m_resultsPage.Create(GetPointer(this), m_chartId, m_subWindow);
      PopBuildTarget(previous);
      if(!created)
         return false;
      m_resultsPageCreated = true;
      return true;
     }

   bool                       EnsureStrategyTabCreated(void)
     {
      if(m_strategyTabCreated)
         return true;
      if(!AddHitGroup(m_strategyGroup, "Fusion_group_strategy"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_strategyGroup);
      if(!BuildStrategyTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_strategyOverviewGroup, "Fusion_group_strategy_overview"))
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int groupIndex = 0; groupIndex < FUSION_STRATEGY_PANEL_COUNT; ++groupIndex)
        {
         if(!AddHitGroup(m_strategyPanelGroups[groupIndex], "Fusion_group_strategy_panel_" + IntegerToString(groupIndex)))
           {
            PopBuildTarget(previous);
            return false;
           }
        }
      if(!EnsureStrategyOverviewCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int strategyIndex = 0; strategyIndex < FUSION_STRATEGY_PANEL_COUNT; ++strategyIndex)
         if(!EnsureStrategyPanelCreated(strategyIndex))
           {
            PopBuildTarget(previous);
            return false;
           }
      PopBuildTarget(previous);
      m_strategyTabCreated = true;
      RefreshSignalDraftViews(true, false);
      return true;
     }

   bool                       EnsureFilterTabCreated(void)
     {
      if(m_filterTabCreated)
         return true;
      if(!AddHitGroup(m_filterGroup, "Fusion_group_filter"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_filterGroup);
      if(!BuildFilterTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_filterOverviewGroup, "Fusion_group_filter_overview"))
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int groupIndex = 0; groupIndex < FUSION_FILTER_PANEL_COUNT; ++groupIndex)
        {
         if(!AddHitGroup(m_filterPanelGroups[groupIndex], "Fusion_group_filter_panel_" + IntegerToString(groupIndex)))
           {
            PopBuildTarget(previous);
            return false;
           }
        }
      if(!EnsureFilterOverviewCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int filterIndex = 0; filterIndex < FUSION_FILTER_PANEL_COUNT; ++filterIndex)
         if(!EnsureFilterPanelCreated(filterIndex))
           {
            PopBuildTarget(previous);
            return false;
           }
      PopBuildTarget(previous);
      m_filterTabCreated = true;
      RefreshSignalDraftViews(false, true);
      return true;
     }

   bool                       EnsureProfilesTabCreated(void)
     {
      if(m_profilesTabCreated)
         return true;
      if(!AddHitGroup(m_profilesGroup, "Fusion_group_profiles"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_profilesGroup);
      if(!BuildProfilesTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_profilesTabCreated = true;
      RefreshProfileList(false);
      return true;
     }

   bool                       BuildAllContent(void)
     {
      if(!EnsureStatusPageCreated())
         return false;
      if(!EnsureResultsPageCreated())
         return false;
      if(!EnsureStrategyTabCreated())
         return false;
      if(!EnsureFilterTabCreated())
         return false;
      if(!EnsureProfilesTabCreated())
         return false;
      if(!EnsureConfigTabCreated())
         return false;
      return true;
     }

#endif
