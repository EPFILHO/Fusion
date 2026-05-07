#ifndef __FUSION_UI_PANEL_MQH__
#define __FUSION_UI_PANEL_MQH__

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Panel.mqh>
#include "PanelUtils.mqh"
#include "HitTestGroup.mqh"
#include "../Core/Version.mqh"
#include "UIPanelTypes.mqh"
#include "Pages/StatusPage.mqh"
#include "Pages/ResultsPage.mqh"
#include "MACrossPanel.mqh"
#include "StrategyTimeframePanel.mqh"
#include "FilterTimeframePanel.mqh"
#include "../Persistence/SettingsStore.mqh"
#include "../Core/InstanceRegistry.mqh"
#include "../Core/ActiveProfileRegistry.mqh"

class CFusionPanel : public CAppDialog
  {
private:
   long                       m_chartId;
   int                        m_subWindow;
   bool                       m_created;
   bool                       m_dialogRunning;
   bool                       m_mouseOverPanel;
   bool                       m_origDragTrade;
   bool                       m_origMouseScroll;
   bool                       m_hasPendingCommand;
   bool                       m_configInputsValid;
   bool                       m_cfgRiskValid;
   bool                       m_cfgProtectionValid;
   bool                       m_cfgSystemValid;
   bool                       m_hasCommittedSettings;
   string                     m_cfgStatusText;
   color                      m_cfgStatusColor;
   CFusionHitGroup           *m_buildTarget;
   SUICommand                 m_pendingCommand;
   SUIPanelSnapshot           m_snapshot;
   SEASettings                m_committedSettings;
   SEASettings                m_draftSettings;
   ENUM_FUSION_TAB            m_activeTab;
   ENUM_FUSION_STRATEGY_PAGE  m_strategyPage;
   ENUM_FUSION_FILTER_PAGE    m_filterPage;
   ENUM_FUSION_CONFIG_PAGE    m_configPage;

   CButton                    m_tabs[FUSION_TAB_COUNT];
   CPanel                     m_tabsSeparator;
   CButton                    m_strategyTabs[FUSION_STRAT_COUNT];
   CPanel                     m_strategyTabsSeparator;
   CPanel                     m_strategyContentFrame;
   CButton                    m_filterTabs[FUSION_FILTER_COUNT];
   CPanel                     m_filterTabsSeparator;
   CPanel                     m_filterContentFrame;
   CButton                    m_configTabs[FUSION_CFG_COUNT];
   CPanel                     m_configTabsSeparator;
   CPanel                     m_configContentFrame;
   CStatusPage                m_statusPage;
   CResultsPage               m_resultsPage;
   CFusionHitGroup            m_statusGroup;
   CFusionHitGroup            m_resultsGroup;
   CFusionHitGroup            m_strategyGroup;
   CFusionHitGroup            m_filterGroup;
   CFusionHitGroup            m_profilesGroup;
   CFusionHitGroup            m_configGroup;
   CFusionHitGroup            m_strategyOverviewGroup;
   CFusionHitGroup            m_strategyPanelGroups[3];
   CFusionHitGroup            m_filterOverviewGroup;
   CFusionHitGroup            m_filterPanelGroups[2];
   CFusionHitGroup            m_profilesBrowseGroup;
   CFusionHitGroup            m_profilesEditGroup;
   CFusionHitGroup            m_configRiskGroup;
   CFusionHitGroup            m_configProtectionGroup;
   CFusionHitGroup            m_configSystemGroup;
   bool                       m_statusPageCreated;
   bool                       m_resultsPageCreated;
   bool                       m_strategyTabCreated;
   bool                       m_filterTabCreated;
   bool                       m_profilesTabCreated;
   bool                       m_configTabCreated;
   bool                       m_configRiskCreated;
   bool                       m_configProtectionCreated;
   bool                       m_configSystemCreated;

#include "UIPanelHeader.mqh"
#include "UIPanelSignalTabs.mqh"
#include "UIPanelProfiles.mqh"
#include "UIPanelProtectionTabs.mqh"

   CLabel                     m_cfgRiskHdr;
   CLabel                     m_cfgRiskLotLbl;
   CEdit                      m_cfgRiskLotEdit;

   CLabel                     m_cfgSystemHdr;
   CLabel                     m_cfgSystemMagicLbl;
   CEdit                      m_cfgSystemMagicEdit;
   CLabel                     m_cfgSystemConflictLbl;
   CButton                    m_cfgSystemConflictBtn;
   CLabel                     m_cfgStatus;

#include "UIPanelConfigValidation.mqh"
#include "UIPanelCommandQueue.mqh"
#include "UIPanelDeferredEdits.mqh"
#include "UIPanelControlHelpers.mqh"
#include "UIPanelConfigTabs.mqh"
#include "UIPanelContentLifecycle.mqh"
#include "UIPanelDraftState.mqh"
#include "UIPanelAccessState.mqh"

#include "UIPanelTabStatus.mqh"
#include "UIPanelVisibility.mqh"

   bool                       BuildTabs(void)
     {
      string names[FUSION_TAB_COUNT] = {"STATUS", "RESULTS", "STRATS", "FILTERS", "PERFIS", "CONFIG"};
      int tabWidth = 84;
      int tabGap = 2;
      int x = 18;
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(!AddButton(m_tabs[i], "Fusion_tab_" + IntegerToString(i), x, 68, x + tabWidth, 92, names[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_tabsSeparator,
                   "Fusion_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   96,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   98,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      return true;
     }

#include "UIPanelTopActions.mqh"
#include "UIPanelNavigation.mqh"

   bool                       HandlePanelClick(const string objectName)
     {
      if(HandleTopActionClick(objectName))
         return true;

      if(objectName == m_cfgSystemConflictBtn.Name())
        {
         ReleaseButton(m_cfgSystemConflictBtn);
         if(!TryBeginActiveProfileEdit())
            return true;
         m_draftSettings.conflictMode = (m_draftSettings.conflictMode == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
         RefreshConfigValidation();
         return true;
        }
      if(HandleProtectionClick(objectName))
         return true;
      if(HandleProfilesClick(objectName))
         return true;
      if(HandleSignalPanelClick(objectName))
         return true;
      if(HandleTabNavigationClick(objectName))
         return true;

      return false;
     }

protected:
   virtual bool                CreateButtonClose(void)
     {
      return true;
     }

   virtual void                OnClickButtonClose(void)
     {
      // O Fusion nao expoe botao de fechar. Se algum clique mal roteado
      // cair aqui, ignoramos em vez de remover o EA do grafico.
     }

   virtual void                Minimize(void)
     {
      if(!m_created)
         return;
      HideManagedContent();
      CAppDialog::Minimize();
      ChartRedraw();
     }

   virtual void                Maximize(void)
     {
      CAppDialog::Maximize();
      if(!m_created)
         return;

      SetShellVisible(true);
      ApplyVisibility();
      UpdateActiveTabContent(true);
      ChartRedraw();
     }

public:
                              CFusionPanel(void)
     {
      m_chartId         = 0;
      m_subWindow       = 0;
      m_created         = false;
      m_dialogRunning   = false;
      m_mouseOverPanel  = false;
      m_origDragTrade   = true;
      m_origMouseScroll = true;
      m_configInputsValid = true;
      m_cfgRiskValid = true;
      m_cfgProtectionValid = true;
      m_cfgSystemValid = true;
      m_hasCommittedSettings = false;
      m_cfgStatusText = "";
      m_cfgStatusColor = FUSION_CLR_MUTED;
      m_parentStatusText = "";
      m_parentStatusColor = FUSION_CLR_MUTED;
      m_headerButtonsReady = false;
      m_strategyStatusText = "";
      m_filterStatusText = "";
      m_strategyStatusColor = FUSION_CLR_MUTED;
      m_filterStatusColor = FUSION_CLR_MUTED;
      m_buildTarget    = NULL;
      m_activeTab       = FUSION_TAB_STATUS;
      m_strategyPage    = FUSION_STRAT_OVERVIEW;
      m_filterPage      = FUSION_FILTER_OVERVIEW;
      m_configPage      = FUSION_CFG_RISK;
      m_protectPage     = FUSION_PROTECT_GENERAL;
      m_statusPageCreated = false;
      m_resultsPageCreated = false;
      m_strategyTabCreated = false;
      m_filterTabCreated = false;
      m_profilesTabCreated = false;
      m_configTabCreated = false;
      m_configRiskCreated = false;
      m_configProtectionCreated = false;
      m_configSystemCreated = false;
      m_profileMode     = FUSION_PROFILE_BROWSE;
      for(int protectIndex = 0; protectIndex < FUSION_PROTECT_COUNT; ++protectIndex)
        {
         m_protectPageValid[protectIndex] = true;
         m_protectPageError[protectIndex] = "";
        }
      for(int strategyIndex = 0; strategyIndex < FUSION_STRAT_COUNT; ++strategyIndex)
         m_strategyPageValid[strategyIndex] = true;
      for(int filterIndex = 0; filterIndex < FUSION_FILTER_COUNT; ++filterIndex)
         m_filterPageValid[filterIndex] = true;
      m_committedProfileName = "";
      ArrayResize(m_profileNames, 0);
      m_profileCount = 0;
      m_profileOffset = 0;
      m_profileSelected = -1;
      m_profilesBrowseCreated = false;
      m_profilesEditCreated = false;
      m_profileTabValid = true;
      m_profileTabError = "";
      m_profileStatusOverride = "";
      m_profileStatusOverrideColor = FUSION_CLR_MUTED;
      m_profileStatusOverrideUntil = 0;
      m_profileEditSourceName = "";
      SetDefaultSettings(m_committedSettings);
      SetDefaultSettings(m_draftSettings);
      m_strategyOverviewCreated = false;
      m_filterOverviewCreated = false;
      for(int i = 0; i < 3; ++i)
        {
         m_strategyPanels[i] = NULL;
         m_strategyPanelCreated[i] = false;
        }
      for(int j = 0; j < 2; ++j)
        {
         m_filterPanels[j] = NULL;
         m_filterPanelCreated[j] = false;
        }
      m_snapshot.started = false;
      m_snapshot.hasPosition = false;
      m_snapshot.activeProfileName = "";
      m_snapshot.symbol = "";
      m_snapshot.timeframe = "";
      m_snapshot.symbolSpec.symbol = "";
      m_snapshot.symbolSpec.digits = 0;
      m_snapshot.symbolSpec.point = 0.0;
      m_snapshot.symbolSpec.tickSize = 0.0;
      m_snapshot.symbolSpec.tickValue = 0.0;
      m_snapshot.symbolSpec.volumeMin = 0.0;
      m_snapshot.symbolSpec.volumeMax = 0.0;
      m_snapshot.symbolSpec.volumeStep = 0.0;
      m_snapshot.symbolSpec.stopsLevel = 0;
      m_snapshot.symbolSpec.freezeLevel = 0;
      m_snapshot.symbolSpec.fillingMode = 0;
      m_snapshot.magicNumber = 0;
      m_snapshot.activeStrategies = 0;
      m_snapshot.activeFilters = 0;
      m_snapshot.conflictMode = CONFLICT_PRIORITY;
      m_snapshot.fixedLot = 0.0;
      m_snapshot.maxSpreadPoints = 0;
      m_snapshot.ownerStrategyName = "";
      m_snapshot.useMACross = false;
      m_snapshot.useRSI = false;
      m_snapshot.useBollinger = false;
      m_snapshot.useTrendFilter = false;
      m_snapshot.useRSIFilter = false;
      m_snapshot.runtimeBlocked = false;
      m_snapshot.runtimeBlockReason = "";
      m_snapshot.startBlockedReason = "";
      m_snapshot.activeProfileBlockedReason = "";
      m_snapshot.runtimeNotice = "";
      m_snapshot.dailyTradeCount = 0;
      m_snapshot.dailyClosedProfit = 0.0;
      m_snapshot.lossStreak = 0;
      m_snapshot.winStreak = 0;
      m_snapshot.drawdownProtectionActive = false;
      ClearPendingCommand();
     }

                             ~CFusionPanel(void)
     {
      Destroy(REASON_REMOVE);
     }

   bool                       AddControl(CWnd &control)
     {
      if(m_buildTarget != NULL)
         return m_buildTarget.Add(control);
      return Add(control);
     }

   bool                       CreatePanel(const long chartId,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2,const SUIPanelSnapshot &snapshot)
     {
      m_chartId   = chartId;
      m_subWindow = subwin;
      m_snapshot  = snapshot;
      ClearPendingCommand();

      if(!Create(chartId, name, subwin, x1, y1, x2, y2))
         return false;

      m_created = true;
      m_origDragTrade   = (bool)ChartGetInteger(chartId, CHART_DRAG_TRADE_LEVELS);
      m_origMouseScroll = (bool)ChartGetInteger(chartId, CHART_MOUSE_SCROLL);
      ChartSetInteger(chartId, CHART_EVENT_MOUSE_MOVE, true);

      if(!BuildHeader())      { Destroy(REASON_REMOVE); return false; }
      if(!BuildTabs())        { Destroy(REASON_REMOVE); return false; }
      if(!BuildAllContent())  { Destroy(REASON_REMOVE); return false; }
      LoadSettings(snapshot);
      Update(snapshot);
      m_headerButtonsReady = true;
      ApplyVisibility();
      return true;
     }

   bool                       StartDialog(void)
     {
      if(!CAppDialog::Run())
         return false;
      m_dialogRunning = true;
      return true;
     }

   virtual void                Destroy(const int reason=REASON_REMOVE)
     {
      if(!m_created)
         return;

      ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);

      CAppDialog::Destroy(reason);

      for(int i = 0; i < 3; ++i)
        {
         if(m_strategyPanels[i] != NULL)
           {
            delete m_strategyPanels[i];
            m_strategyPanels[i] = NULL;
           }
        }

      for(int j = 0; j < 2; ++j)
        {
         if(m_filterPanels[j] != NULL)
           {
            delete m_filterPanels[j];
            m_filterPanels[j] = NULL;
           }
        }

      m_created = false;
      m_dialogRunning = false;
     }

   void                       LoadSettings(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created)
         return;

      m_snapshot = snapshot;
      LoadSettings(snapshot.settings, snapshot.activeProfileName, snapshot.symbolSpec);
     }

   void                       LoadSettings(const SEASettings &settings,const string profileName,const SSymbolSpec &spec)
     {
      if(!m_created)
         return;

      m_snapshot.symbolSpec      = spec;
      m_snapshot.activeProfileName = profileName;
      m_snapshot.fixedLot        = settings.fixedLot;
      m_snapshot.maxSpreadPoints = settings.maxSpreadPoints;
      m_snapshot.magicNumber     = settings.magicNumber;
      m_snapshot.conflictMode    = settings.conflictMode;
      m_snapshot.useMACross      = settings.useMACross;
      m_snapshot.useRSI          = settings.useRSI;
      m_snapshot.useBollinger    = settings.useBollinger;
      m_snapshot.useTrendFilter  = settings.useTrendFilter;
      m_snapshot.useRSIFilter    = settings.useRSIFilter;

      m_committedSettings        = settings;
      m_draftSettings            = settings;
      m_committedProfileName     = profileName;
      m_hasCommittedSettings     = true;

      SyncHeaderProfile(m_committedProfileName);
      SyncDraftSettingsToControls();
      SetProfileMode(FUSION_PROFILE_BROWSE);
      if(m_profilesTabCreated)
        {
         ClearProfileStatusOverride();
         RefreshProfileList(false);
         if(m_activeTab == FUSION_TAB_PROFILES)
            SetProfilesVisible(true);
        }
      if(m_configTabCreated)
         RefreshConfigValidation();
      else
         RefreshTheme();
     }

   void                       Update(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created || m_minimized)
         return;

      bool wasEditBlocked = !ActiveProfileEditable();
      bool nowCanEditActiveProfile = ActiveProfileEditable(snapshot);
      bool runtimeStateChanged = (snapshot.started != m_snapshot.started || snapshot.hasPosition != m_snapshot.hasPosition);
      bool permissionStateChanged = runtimeStateChanged ||
                                    snapshot.runtimeBlocked != m_snapshot.runtimeBlocked ||
                                    snapshot.startBlockedReason != m_snapshot.startBlockedReason ||
                                    snapshot.activeProfileBlockedReason != m_snapshot.activeProfileBlockedReason;
      bool editBlockExited = (wasEditBlocked && nowCanEditActiveProfile && m_hasCommittedSettings);
      bool redrawNeeded = runtimeStateChanged ||
                           snapshot.runtimeBlocked != m_snapshot.runtimeBlocked ||
                           snapshot.startBlockedReason != m_snapshot.startBlockedReason ||
                           snapshot.activeProfileBlockedReason != m_snapshot.activeProfileBlockedReason ||
                           snapshot.runtimeNotice != m_snapshot.runtimeNotice ||
                           snapshot.dailyTradeCount != m_snapshot.dailyTradeCount ||
                           MathAbs(snapshot.dailyClosedProfit - m_snapshot.dailyClosedProfit) > 0.0000001 ||
                           snapshot.lossStreak != m_snapshot.lossStreak ||
                           snapshot.winStreak != m_snapshot.winStreak ||
                           snapshot.drawdownProtectionActive != m_snapshot.drawdownProtectionActive;
      m_snapshot = snapshot;
      if(editBlockExited)
         RestoreCommittedDraftToControls();
      UpdateHeaderButtons();
      UpdateActiveTabContent(permissionStateChanged || editBlockExited);
      if(redrawNeeded)
         ChartRedraw();
     }

   void                       MouseProtection(const int x,const int y)
     {
      bool inside = (x >= Left() && x <= Right() && y >= Top() && y <= Bottom());

      if(inside && !m_mouseOverPanel)
        {
         ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, false);
         ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, false);
         m_mouseOverPanel = true;
        }
      else if(!inside && m_mouseOverPanel)
        {
         ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
         ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);
         m_mouseOverPanel = false;
        }
     }

   bool                       ConsumeCommand(SUICommand &command)
     {
      if(!m_hasPendingCommand)
         return false;
      command = m_pendingCommand;
      ClearPendingCommand();
      return true;
     }

   virtual void               ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_created)
         return;

      if(id == CHARTEVENT_MOUSE_MOVE)
         MouseProtection((int)lparam, (int)dparam);

      if(m_minimized)
        {
         CAppDialog::ChartEvent(id, lparam, dparam, sparam);
         return;
        }

      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(HandlePanelClick(sparam))
           {
            ChartRedraw();
            return;
           }
        }

      CAppDialog::ChartEvent(id, lparam, dparam, sparam);

      if(IsDeferredRefreshEvent(id, sparam))
         HandleDeferredRefreshEvent(id, sparam);
     }

   virtual bool               OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      bool result = CAppDialog::OnEvent(id, lparam, dparam, sparam);
      if(!m_minimized)
        {
         if(HandleSignalPanelChange(id, sparam))
            return true;
        }
      return result;
     }
  };

#endif
