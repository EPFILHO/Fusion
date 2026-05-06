#ifndef __FUSION_UI_PANEL_NAVIGATION_MQH__
#define __FUSION_UI_PANEL_NAVIGATION_MQH__

   bool                       HandleMainTabNavigationClick(const string objectName)
     {
      for(int t = 0; t < FUSION_TAB_COUNT; ++t)
        {
         if(objectName != m_tabs[t].Name())
            continue;

         ReleaseButton(m_tabs[t]);
         ResetDialogMouseRouting();
         m_activeTab = (ENUM_FUSION_TAB)t;
         ApplyVisibility(m_activeTab != FUSION_TAB_CONFIG);
         UpdateActiveTabContent(true);
         return true;
        }
      return false;
     }

   bool                       HandleStrategyTabNavigationClick(const string objectName)
     {
      for(int s = 0; s < FUSION_STRAT_COUNT; ++s)
        {
         if(objectName != m_strategyTabs[s].Name())
            continue;

         ReleaseButton(m_strategyTabs[s]);
         ResetDialogMouseRouting();
         m_strategyPage = (ENUM_FUSION_STRATEGY_PAGE)s;
         ApplyVisibility();
         return true;
        }
      return false;
     }

   bool                       HandleFilterTabNavigationClick(const string objectName)
     {
      for(int f = 0; f < FUSION_FILTER_COUNT; ++f)
        {
         if(objectName != m_filterTabs[f].Name())
            continue;

         ReleaseButton(m_filterTabs[f]);
         ResetDialogMouseRouting();
         m_filterPage = (ENUM_FUSION_FILTER_PAGE)f;
         ApplyVisibility();
         return true;
        }
      return false;
     }

   bool                       HandleConfigTabNavigationClick(const string objectName)
     {
      for(int c = 0; c < FUSION_CFG_COUNT; ++c)
        {
         if(objectName != m_configTabs[c].Name())
            continue;

         ReleaseButton(m_configTabs[c]);
         ResetDialogMouseRouting();
         m_configPage = (ENUM_FUSION_CONFIG_PAGE)c;
         ApplyVisibility(false);
         RefreshConfigValidation();
         return true;
        }
      return false;
     }

   bool                       HandleTabNavigationClick(const string objectName)
     {
      if(HandleMainTabNavigationClick(objectName))
         return true;
      if(HandleStrategyTabNavigationClick(objectName))
         return true;
      if(HandleFilterTabNavigationClick(objectName))
         return true;
      if(HandleConfigTabNavigationClick(objectName))
         return true;
      return false;
     }

#endif
