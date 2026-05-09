#ifndef __FUSION_UI_PANEL_SIGNAL_OVERVIEW_MQH__
#define __FUSION_UI_PANEL_SIGNAL_OVERVIEW_MQH__

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
      CFusionHitGroup *previous = PushBuildTarget(m_strategyOverviewGroup);
      bool ok = true;
      if(!AddLabel(m_strategyOverviewHdr, "Fusion_strat_overview_hdr", 22, 156, 260, 176, "Visao Geral das Estrategias", FUSION_CLR_VALUE, 9))
         ok = false;

      int y = 194;
      for(int i = 0; ok && i < 3; ++i)
        {
         if(!AddLabel(m_strategyOverviewName[i], "Fusion_strat_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            ok = false;
         if(!AddLabel(m_strategyOverviewState[i], "Fusion_strat_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            ok = false;
         y += 34;
        }

      PopBuildTarget(previous);
      return ok;
     }

   bool                       EnsureStrategyOverviewCreated(void)
     {
      if(m_strategyOverviewCreated)
         return true;
      if(!CreateStrategyOverview())
         return false;
      m_strategyOverviewCreated = true;
      UpdateStrategyOverview();
      return true;
     }

   bool                       CreateFilterOverview(void)
     {
      CFusionHitGroup *previous = PushBuildTarget(m_filterOverviewGroup);
      bool ok = true;
      if(!AddLabel(m_filterOverviewHdr, "Fusion_filter_overview_hdr", 22, 156, 260, 176, "Visao Geral dos Filtros", FUSION_CLR_VALUE, 9))
         ok = false;

      int y = 194;
      for(int i = 0; ok && i < 2; ++i)
        {
         if(!AddLabel(m_filterOverviewName[i], "Fusion_filter_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            ok = false;
         if(!AddLabel(m_filterOverviewState[i], "Fusion_filter_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            ok = false;
         y += 34;
        }

      PopBuildTarget(previous);
      return ok;
     }

   bool                       EnsureFilterOverviewCreated(void)
     {
      if(m_filterOverviewCreated)
         return true;
      if(!CreateFilterOverview())
         return false;
      m_filterOverviewCreated = true;
      UpdateFilterOverview();
      return true;
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

#endif
