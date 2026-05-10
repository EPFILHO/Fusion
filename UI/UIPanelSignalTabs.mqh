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

   void                       SyncStrategyPanels(void)
     {
      for(int i = 0; i < 3; ++i)
         if(m_strategyPanels[i] != NULL)
             m_strategyPanels[i].Sync(m_draftSettings, CanEditActiveProfile());
     }

   void                       SyncFilterPanels(void)
     {
      for(int j = 0; j < 2; ++j)
         if(m_filterPanels[j] != NULL)
             m_filterPanels[j].Sync(m_draftSettings, CanEditActiveProfile());
     }

   void                       RefreshSignalDraftViews(const bool syncStrategies,const bool syncFilters)
     {
      if(m_strategyTabCreated || m_filterTabCreated)
         UpdateOverviews();
      if(syncStrategies && m_strategyTabCreated)
         SyncStrategyPanels();
      if(syncFilters && m_filterTabCreated)
         SyncFilterPanels();
     }

   bool                       HandleSignalPanelClick(const string objectName)
     {
      SUICommand tempCommand;
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_strategyPanels[sp].HandleClick(objectName, tempCommand))
           {
            if(!TryBeginActiveProfileEdit())
               return true;
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            RefreshSignalDraftViews(true, false);
            return true;
           }
        }

      for(int fp = 0; fp < 2; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_filterPanels[fp].HandleClick(objectName, tempCommand))
           {
            if(!TryBeginActiveProfileEdit())
               return true;
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, true);
            return true;
           }
        }

      return false;
     }

   bool                       HandleSignalPanelChange(const int id,const string objectName)
     {
      if(id != CHARTEVENT_CUSTOM + ON_CHANGE)
         return false;

      if(!TryBeginActiveProfileEdit())
         return false;

      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         if(m_strategyPanels[sp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, false);
            return true;
           }
        }

      for(int fp = 0; fp < 2; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         if(m_filterPanels[fp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            RefreshSignalDraftViews(false, true);
            return true;
           }
        }

      return false;
     }

#include "UIPanelSignalVisibility.mqh"

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
