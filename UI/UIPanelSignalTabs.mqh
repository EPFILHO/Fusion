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

#include "UIPanelSignalOverview.mqh"

#include "UIPanelSignalPanels.mqh"

#include "UIPanelSignalValidation.mqh"

#include "UIPanelSignalEvents.mqh"

#include "UIPanelSignalVisibility.mqh"

#include "UIPanelSignalShell.mqh"

#endif
