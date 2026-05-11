#ifndef __FUSION_UI_PANEL_SIGNAL_TABS_MQH__
#define __FUSION_UI_PANEL_SIGNAL_TABS_MQH__

   CLabel                     m_strategyOverviewHdr;
   CLabel                     m_strategyOverviewName[FUSION_STRATEGY_PANEL_COUNT];
   CLabel                     m_strategyOverviewState[FUSION_STRATEGY_PANEL_COUNT];
   CLabel                     m_filterOverviewHdr;
   CLabel                     m_filterOverviewName[FUSION_FILTER_PANEL_COUNT];
   CLabel                     m_filterOverviewState[FUSION_FILTER_PANEL_COUNT];
   CLabel                     m_strategyStatus;
   CLabel                     m_filterStatus;
   string                     m_strategyStatusText;
   string                     m_filterStatusText;
   color                      m_strategyStatusColor;
   color                      m_filterStatusColor;

   CStrategyPanelBase        *m_strategyPanels[FUSION_STRATEGY_PANEL_COUNT];
   CFilterPanelBase          *m_filterPanels[FUSION_FILTER_PANEL_COUNT];
   bool                       m_strategyOverviewCreated;
   bool                       m_filterOverviewCreated;
   bool                       m_strategyPanelCreated[FUSION_STRATEGY_PANEL_COUNT];
   bool                       m_filterPanelCreated[FUSION_FILTER_PANEL_COUNT];
   bool                       m_strategyPageValid[FUSION_STRAT_COUNT];
   bool                       m_filterPageValid[FUSION_FILTER_COUNT];

#include "UIPanelSignalOverview.mqh"

#include "UIPanelSignalPanels.mqh"

#include "UIPanelSignalValidation.mqh"

#include "UIPanelSignalEvents.mqh"

#include "UIPanelSignalVisibility.mqh"

#include "UIPanelSignalShell.mqh"

#endif
