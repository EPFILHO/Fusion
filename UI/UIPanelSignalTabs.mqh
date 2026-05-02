#ifndef __FUSION_UI_PANEL_SIGNAL_TABS_MQH__
#define __FUSION_UI_PANEL_SIGNAL_TABS_MQH__

   CLabel                     m_strategyOverviewHdr;
   CLabel                     m_strategyOverviewName[3];
   CLabel                     m_strategyOverviewState[3];
   CLabel                     m_filterOverviewHdr;
   CLabel                     m_filterOverviewName[2];
   CLabel                     m_filterOverviewState[2];
   CLabel                     m_strategyStatus;
   CLabel                     m_filterStatus;
   string                     m_strategyStatusText;
   string                     m_filterStatusText;
   color                      m_strategyStatusColor;
   color                      m_filterStatusColor;

   CStrategyPanelBase        *m_strategyPanels[3];
   CFilterPanelBase          *m_filterPanels[2];
   bool                       m_strategyOverviewCreated;
   bool                       m_filterOverviewCreated;
   bool                       m_strategyPanelCreated[3];
   bool                       m_filterPanelCreated[2];
   bool                       m_strategyPageValid[FUSION_STRAT_COUNT];
   bool                       m_filterPageValid[FUSION_FILTER_COUNT];

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

   bool                       CreateStrategyPanel(const int index)
     {
      if(index < 0 || index >= 3)
         return false;

      if(index == 0)
         m_strategyPanels[index] = new CMACrossPanel();
      else if(index == 1)
         m_strategyPanels[index] = new CStrategyTimeframePanel(FUSION_STRATEGY_PANEL_RSI,
                                                               StrategyPanelTitle(index),
                                                               StrategyPanelKey(index),
                                                               "Gera sinais de entrada e saida com base no RSI.",
                                                               StrategyPanelCommand(index),
                                                               false);
      else
         m_strategyPanels[index] = new CStrategyTimeframePanel(FUSION_STRATEGY_PANEL_BB,
                                                               StrategyPanelTitle(index),
                                                               StrategyPanelKey(index),
                                                               "Gera sinais com leitura das bandas de Bollinger.",
                                                               StrategyPanelCommand(index),
                                                               false);

      if(m_strategyPanels[index] == NULL)
         return false;

      CFusionHitGroup *previous = PushBuildTarget(m_strategyPanelGroups[index]);
      bool created = m_strategyPanels[index].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360);
      PopBuildTarget(previous);
      if(!created)
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
      return true;
     }

   bool                       CreateFilterPanel(const int index)
     {
      if(index < 0 || index >= 2)
         return false;

      if(index == 0)
         m_filterPanels[index] = new CFilterTimeframePanel(FUSION_FILTER_PANEL_TREND,
                                                           FilterPanelTitle(index),
                                                           FilterPanelKey(index),
                                                           "Valida a direcao do mercado com media movel.",
                                                           FilterPanelCommand(index));
      else
         m_filterPanels[index] = new CFilterTimeframePanel(FUSION_FILTER_PANEL_RSI,
                                                           FilterPanelTitle(index),
                                                           FilterPanelKey(index),
                                                           "Filtra sinais pela faixa operacional do RSI.",
                                                           FilterPanelCommand(index));

      if(m_filterPanels[index] == NULL)
         return false;

      CFusionHitGroup *previous = PushBuildTarget(m_filterPanelGroups[index]);
      bool created = m_filterPanels[index].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360);
      PopBuildTarget(previous);
      if(!created)
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

   bool                       HasSelectedStrategy(const SEASettings &settings) const
     {
      return (settings.useMACross || settings.useRSI || settings.useBollinger);
     }

   bool                       StrategySubtabHasError(const ENUM_FUSION_STRATEGY_PAGE page) const
     {
      return !m_strategyPageValid[(int)page];
     }

   bool                       HasStrategyTabError(void) const
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         if(!m_strategyPageValid[i])
            return true;
      return false;
     }

   void                       ApplyStrategyTabStyles(void)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(i == (int)m_strategyPage)
            FusionApplyPrimaryButtonStyle(m_strategyTabs[i], true);
         else if(StrategySubtabHasError((ENUM_FUSION_STRATEGY_PAGE)i))
            FusionApplyActionButtonStyle(m_strategyTabs[i], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_strategyTabs[i], false);
        }
     }

   bool                       FilterSubtabHasError(const ENUM_FUSION_FILTER_PAGE page) const
     {
      if(page == FUSION_FILTER_OVERVIEW)
         return false;
      return !m_filterPageValid[(int)page];
     }

   bool                       HasFilterTabError(void) const
     {
      for(int i = 1; i < FUSION_FILTER_COUNT; ++i)
         if(!m_filterPageValid[i])
            return true;
      return false;
     }

   void                       ApplyFilterTabStyles(void)
     {
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(i == (int)m_filterPage)
            FusionApplyPrimaryButtonStyle(m_filterTabs[i], true);
         else if(FilterSubtabHasError((ENUM_FUSION_FILTER_PAGE)i))
            FusionApplyActionButtonStyle(m_filterTabs[i], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_filterTabs[i], false);
        }
     }

   void                       SetStrategyStatus(const string text,const color clr)
     {
      m_strategyStatusText = text;
      m_strategyStatusColor = clr;
      if(m_strategyTabCreated)
        {
         m_strategyStatus.Text(text);
         m_strategyStatus.Color(clr);
        }
     }

   void                       SetFilterStatus(const string text,const color clr)
     {
      m_filterStatusText = text;
      m_filterStatusColor = clr;
      if(m_filterTabCreated)
        {
         m_filterStatus.Text(text);
         m_filterStatus.Color(clr);
        }
     }

   void                       RestoreStrategyStatus(void)
     {
      if(!m_strategyTabCreated)
         return;
      m_strategyStatus.Text(m_strategyStatusText);
      m_strategyStatus.Color(m_strategyStatusColor);
     }

   void                       RestoreFilterStatus(void)
     {
      if(!m_filterTabCreated)
         return;
      m_filterStatus.Text(m_filterStatusText);
      m_filterStatus.Color(m_filterStatusColor);
     }

   void                       ApplyStrategyStatus(const bool strategyValid,const string strategyError)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: estrategias somente leitura.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar estrategias.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!strategyValid)
        {
         status = (strategyError != "" ? strategyError : "Corrija os campos de estrategias.");
         statusColor = FUSION_CLR_BAD;
        }
      else if(HasConfigTabError() || HasFilterTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else
        {
         status = "Estrategia(s) selecionada(s). EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetStrategyStatus(status, statusColor);
     }

   void                       ApplyFilterStatus(const bool filterValid,const string filterError)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: filtros somente leitura.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar filtros.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!filterValid)
        {
         status = (filterError != "" ? filterError : "Corrija os campos de filtros.");
         statusColor = FUSION_CLR_BAD;
        }
      else if(HasConfigTabError() || HasStrategyTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else
        {
         status = "EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetFilterStatus(status, statusColor);
     }

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

   bool                       BuildStrategyTab(void)
     {
      string pageNames[FUSION_STRAT_COUNT] = {"GERAL", "MA", "RSI", "BB"};
      int tabWidth = 96;
      int tabGap = 4;
      int x = 18;
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(!AddButton(m_strategyTabs[i], "Fusion_strat_tab_" + IntegerToString(i), x, 104, x + tabWidth, 128, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_strategyTabsSeparator,
                   "Fusion_strat_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   132,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   134,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_strategyContentFrame,
                   "Fusion_strat_content_frame",
                   FUSION_PANEL_MARGIN,
                   138,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;
      if(!AddLabel(m_strategyStatus, "Fusion_strat_status", 290, 36, FUSION_PANEL_WIDTH - 24, 56, "", FUSION_CLR_MUTED, 8))
         return false;
      return true;
     }

   bool                       BuildFilterTab(void)
     {
      string pageNames[FUSION_FILTER_COUNT] = {"GERAL", "TREND", "RSI"};
      int tabWidth = 110;
      int tabGap = 4;
      int x = 18;
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(!AddButton(m_filterTabs[i], "Fusion_filter_tab_" + IntegerToString(i), x, 104, x + tabWidth, 128, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_filterTabsSeparator,
                   "Fusion_filter_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   132,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   134,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_filterContentFrame,
                   "Fusion_filter_content_frame",
                   FUSION_PANEL_MARGIN,
                   138,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;
      if(!AddLabel(m_filterStatus, "Fusion_filter_status", 290, 36, FUSION_PANEL_WIDTH - 24, 56, "", FUSION_CLR_MUTED, 8))
         return false;
      return true;
     }

#endif
