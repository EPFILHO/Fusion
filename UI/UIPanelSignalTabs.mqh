#ifndef __FUSION_UI_PANEL_SIGNAL_TABS_MQH__
#define __FUSION_UI_PANEL_SIGNAL_TABS_MQH__

   CLabel                     m_strategyOverviewHdr;
   CLabel                     m_strategyOverviewName[3];
   CLabel                     m_strategyOverviewState[3];
   CLabel                     m_filterOverviewHdr;
   CLabel                     m_filterOverviewName[2];
   CLabel                     m_filterOverviewState[2];

   CStrategyPanelBase        *m_strategyPanels[3];
   CFilterPanelBase          *m_filterPanels[2];
   bool                       m_strategyOverviewCreated;
   bool                       m_filterOverviewCreated;
   bool                       m_strategyPanelCreated[3];
   bool                       m_filterPanelCreated[2];

   string                     StrategyDisplayName(const int index) const
     {
      if(index == 0)
         return "MA Cross";
      if(index == 1)
         return "RSI";
      return "Bollinger";
     }

   string                     StrategyPanelTitle(const int index) const
     {
      return StrategyDisplayName(index);
     }

   string                     StrategyPanelKey(const int index) const
     {
      if(index == 0)
         return "ma";
      if(index == 1)
         return "rsi";
      return "bb";
     }

   ENUM_UI_COMMAND            StrategyPanelCommand(const int index) const
     {
      if(index == 0)
         return UI_COMMAND_TOGGLE_MACROSS;
      if(index == 1)
         return UI_COMMAND_TOGGLE_RSI;
      return UI_COMMAND_TOGGLE_BB;
     }

   string                     FilterDisplayName(const int index) const
     {
      if(index == 0)
         return "Trend";
      return "RSI";
     }

   string                     FilterPanelTitle(const int index) const
     {
      if(index == 0)
         return "Trend Filter";
      return "RSI Filter";
     }

   string                     FilterPanelKey(const int index) const
     {
      if(index == 0)
         return "trend";
      return "rsi";
     }

   ENUM_UI_COMMAND            FilterPanelCommand(const int index) const
     {
      if(index == 0)
         return UI_COMMAND_TOGGLE_TREND_FILTER;
      return UI_COMMAND_TOGGLE_RSI_FILTER;
     }

   bool                       CreateStrategyOverview(void)
     {
      if(!AddLabel(m_strategyOverviewHdr, "Fusion_strat_overview_hdr", 22, 156, 260, 176, "Visao Geral das Estrategias", FUSION_CLR_VALUE, 9))
         return false;

      int y = 194;
      for(int i = 0; i < 3; ++i)
        {
         if(!AddLabel(m_strategyOverviewName[i], "Fusion_strat_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_strategyOverviewState[i], "Fusion_strat_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 34;
        }

      return true;
     }

   bool                       EnsureStrategyOverviewCreated(void)
     {
      if(m_strategyOverviewCreated)
         return true;
      if(!CreateStrategyOverview())
         return false;
      m_strategyOverviewCreated = true;
      UpdateStrategyOverview();
      return RebindControlIdsIfRunning();
     }

   bool                       CreateFilterOverview(void)
     {
      if(!AddLabel(m_filterOverviewHdr, "Fusion_filter_overview_hdr", 22, 156, 260, 176, "Visao Geral dos Filtros", FUSION_CLR_VALUE, 9))
         return false;

      int y = 194;
      for(int i = 0; i < 2; ++i)
        {
         if(!AddLabel(m_filterOverviewName[i], "Fusion_filter_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_filterOverviewState[i], "Fusion_filter_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 34;
        }

      return true;
     }

   bool                       EnsureFilterOverviewCreated(void)
     {
      if(m_filterOverviewCreated)
         return true;
      if(!CreateFilterOverview())
         return false;
      m_filterOverviewCreated = true;
      UpdateFilterOverview();
      return RebindControlIdsIfRunning();
     }

   bool                       CreateStrategyPanel(const int index)
     {
      if(index < 0 || index >= 3)
         return false;

      m_strategyPanels[index] = new CStrategyTogglePanel(StrategyPanelTitle(index), StrategyPanelKey(index), StrategyPanelCommand(index));
      if(m_strategyPanels[index] == NULL)
         return false;

      if(!m_strategyPanels[index].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
         return false;

      return true;
     }

   bool                       EnsureStrategyPanelCreated(const int index)
     {
      if(index < 0 || index >= 3)
         return false;
      if(m_strategyPanelCreated[index])
         return true;
      if(!CreateStrategyPanel(index))
         return false;
      m_strategyPanelCreated[index] = true;
      if(m_strategyPanels[index] != NULL)
         m_strategyPanels[index].Sync(m_draftSettings, CanEditSettings());
      return RebindControlIdsIfRunning();
     }

   bool                       CreateFilterPanel(const int index)
     {
      if(index < 0 || index >= 2)
         return false;

      m_filterPanels[index] = new CFilterTogglePanel(FilterPanelTitle(index), FilterPanelKey(index), FilterPanelCommand(index));
      if(m_filterPanels[index] == NULL)
         return false;

      if(!m_filterPanels[index].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
         return false;

      return true;
     }

   bool                       EnsureFilterPanelCreated(const int index)
     {
      if(index < 0 || index >= 2)
         return false;
      if(m_filterPanelCreated[index])
         return true;
      if(!CreateFilterPanel(index))
         return false;
      m_filterPanelCreated[index] = true;
      if(m_filterPanels[index] != NULL)
         m_filterPanels[index].Sync(m_draftSettings, CanEditSettings());
      return RebindControlIdsIfRunning();
     }

   bool                       EnsureActiveStrategyContentCreated(void)
     {
      if(m_strategyPage == FUSION_STRAT_OVERVIEW)
         return EnsureStrategyOverviewCreated();
      return EnsureStrategyPanelCreated((int)m_strategyPage - 1);
     }

   bool                       EnsureActiveFilterContentCreated(void)
     {
      if(m_filterPage == FUSION_FILTER_OVERVIEW)
         return EnsureFilterOverviewCreated();
      return EnsureFilterPanelCreated((int)m_filterPage - 1);
     }

   void                       UpdateStrategyOverview(void)
     {
      if(!m_strategyOverviewCreated)
         return;

      bool strategyStates[3] = {m_draftSettings.useMACross, m_draftSettings.useRSI, m_draftSettings.useBollinger};
      for(int i = 0; i < 3; ++i)
        {
         m_strategyOverviewName[i].Text(StrategyDisplayName(i));
         FusionApplyStateLabel(m_strategyOverviewState[i], strategyStates[i], "ATIVO", "OFF");
        }
     }

   void                       UpdateFilterOverview(void)
     {
      if(!m_filterOverviewCreated)
         return;

      bool filterStates[2] = {m_draftSettings.useTrendFilter, m_draftSettings.useRSIFilter};
      for(int i = 0; i < 2; ++i)
        {
         m_filterOverviewName[i].Text(FilterDisplayName(i));
         FusionApplyStateLabel(m_filterOverviewState[i], filterStates[i], "ATIVO", "OFF");
        }
     }

   void                       UpdateOverviews(void)
     {
      UpdateStrategyOverview();
      UpdateFilterOverview();
     }

   void                       SetStrategiesVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         SetVisible(m_strategyTabs[i], visible);

      if(visible)
         EnsureActiveStrategyContentCreated();

      bool overviewVisible = visible && m_strategyPage == FUSION_STRAT_OVERVIEW;
      if(overviewVisible)
         UpdateStrategyOverview();
      if(m_strategyOverviewCreated)
        {
         SetVisible(m_strategyOverviewHdr, overviewVisible);
         for(int j = 0; j < 3; ++j)
           {
            SetVisible(m_strategyOverviewName[j], overviewVisible);
            SetVisible(m_strategyOverviewState[j], overviewVisible);
           }
        }

      for(int p = 0; p < 3; ++p)
        {
         if(!m_strategyPanelCreated[p] || m_strategyPanels[p] == NULL)
            continue;
         if(visible && m_strategyPage == (ENUM_FUSION_STRATEGY_PAGE)(p + 1))
            m_strategyPanels[p].Show();
         else
            m_strategyPanels[p].Hide();
        }
     }

   void                       SetFiltersVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         SetVisible(m_filterTabs[i], visible);

      if(visible)
         EnsureActiveFilterContentCreated();

      bool overviewVisible = visible && m_filterPage == FUSION_FILTER_OVERVIEW;
      if(overviewVisible)
         UpdateFilterOverview();
      if(m_filterOverviewCreated)
        {
         SetVisible(m_filterOverviewHdr, overviewVisible);
         for(int j = 0; j < 2; ++j)
           {
            SetVisible(m_filterOverviewName[j], overviewVisible);
            SetVisible(m_filterOverviewState[j], overviewVisible);
           }
        }

      for(int p = 0; p < 2; ++p)
        {
         if(!m_filterPanelCreated[p] || m_filterPanels[p] == NULL)
            continue;
         if(visible && m_filterPage == (ENUM_FUSION_FILTER_PAGE)(p + 1))
            m_filterPanels[p].Show();
         else
            m_filterPanels[p].Hide();
        }
     }

   bool                       BuildStrategyTab(void)
     {
      string pageNames[FUSION_STRAT_COUNT] = {"GERAL", "MA", "RSI", "BB"};
      int x = 18;
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(!AddButton(m_strategyTabs[i], "Fusion_strat_tab_" + IntegerToString(i), x, 110, x + 96, 134, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 100;
        }
      return true;
     }

   bool                       BuildFilterTab(void)
     {
      string pageNames[FUSION_FILTER_COUNT] = {"GERAL", "TREND", "RSI"};
      int x = 18;
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(!AddButton(m_filterTabs[i], "Fusion_filter_tab_" + IntegerToString(i), x, 110, x + 110, 134, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 114;
        }
      return true;
     }

#endif
