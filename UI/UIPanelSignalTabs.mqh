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

   void                       UpdateOverviews(void)
     {
      string strategyNames[3] = {"MA Cross", "RSI", "Bollinger"};
      bool strategyStates[3] = {m_draftSettings.useMACross, m_draftSettings.useRSI, m_draftSettings.useBollinger};
      for(int i = 0; i < 3; ++i)
        {
         m_strategyOverviewName[i].Text(strategyNames[i]);
         FusionApplyStateLabel(m_strategyOverviewState[i], strategyStates[i], "ATIVO", "OFF");
        }

      string filterNames[2] = {"Trend", "RSI"};
      bool filterStates[2] = {m_draftSettings.useTrendFilter, m_draftSettings.useRSIFilter};
      for(int j = 0; j < 2; ++j)
        {
         m_filterOverviewName[j].Text(filterNames[j]);
         FusionApplyStateLabel(m_filterOverviewState[j], filterStates[j], "ATIVO", "OFF");
        }
     }

   void                       SetStrategiesVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         SetVisible(m_strategyTabs[i], visible);

      bool overviewVisible = visible && m_strategyPage == FUSION_STRAT_OVERVIEW;
      SetVisible(m_strategyOverviewHdr, overviewVisible);
      for(int j = 0; j < 3; ++j)
        {
         SetVisible(m_strategyOverviewName[j], overviewVisible);
         SetVisible(m_strategyOverviewState[j], overviewVisible);
        }

      for(int p = 0; p < 3; ++p)
        {
         if(m_strategyPanels[p] == NULL)
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

      bool overviewVisible = visible && m_filterPage == FUSION_FILTER_OVERVIEW;
      SetVisible(m_filterOverviewHdr, overviewVisible);
      for(int j = 0; j < 2; ++j)
        {
         SetVisible(m_filterOverviewName[j], overviewVisible);
         SetVisible(m_filterOverviewState[j], overviewVisible);
        }

      for(int p = 0; p < 2; ++p)
        {
         if(m_filterPanels[p] == NULL)
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

      m_strategyPanels[0] = new CStrategyTogglePanel("MA Cross", "ma", UI_COMMAND_TOGGLE_MACROSS);
      m_strategyPanels[1] = new CStrategyTogglePanel("RSI", "rsi", UI_COMMAND_TOGGLE_RSI);
      m_strategyPanels[2] = new CStrategyTogglePanel("Bollinger", "bb", UI_COMMAND_TOGGLE_BB);

      for(int p = 0; p < 3; ++p)
        {
         if(m_strategyPanels[p] == NULL)
            return false;
         if(!m_strategyPanels[p].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
            return false;
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

      m_filterPanels[0] = new CFilterTogglePanel("Trend Filter", "trend", UI_COMMAND_TOGGLE_TREND_FILTER);
      m_filterPanels[1] = new CFilterTogglePanel("RSI Filter", "rsi", UI_COMMAND_TOGGLE_RSI_FILTER);

      for(int p = 0; p < 2; ++p)
        {
         if(m_filterPanels[p] == NULL)
            return false;
         if(!m_filterPanels[p].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
            return false;
        }
      return true;
     }

#endif
