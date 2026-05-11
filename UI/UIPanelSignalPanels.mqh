#ifndef __FUSION_UI_PANEL_SIGNAL_PANELS_MQH__
#define __FUSION_UI_PANEL_SIGNAL_PANELS_MQH__

   bool                       CreateStrategyPanel(const int index)
     {
      if(index < 0 || index >= FUSION_STRATEGY_PANEL_COUNT)
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
      if(index < 0 || index >= FUSION_STRATEGY_PANEL_COUNT)
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
      if(index < 0 || index >= FUSION_FILTER_PANEL_COUNT)
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
      if(index < 0 || index >= FUSION_FILTER_PANEL_COUNT)
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

#endif
