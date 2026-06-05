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
#include "RSIStrategyPanel.mqh"
#include "BollingerStrategyPanel.mqh"
#include "StrategyTimeframePanel.mqh"
#include "TrendFilterPanel.mqh"
#include "RSIFilterPanel.mqh"
#include "BollingerFilterPanel.mqh"
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
   bool                       m_cfgRiskLotValid;
   string                     m_cfgRiskLotError;
   bool                       m_cfgRiskSLTPValid;
   string                     m_cfgRiskSLTPError;
   bool                       m_cfgRiskPartialValid;
   string                     m_cfgRiskPartialError;
   bool                       m_cfgRiskBEValid;
   string                     m_cfgRiskBEError;
   bool                       m_cfgRiskTrailingValid;
   string                     m_cfgRiskTrailingError;
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
   CFusionHitGroup            m_strategyPanelGroups[FUSION_STRATEGY_PANEL_COUNT];
   CFusionHitGroup            m_filterOverviewGroup;
   CFusionHitGroup            m_filterPanelGroups[FUSION_FILTER_PANEL_COUNT];
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
#include "UIPanelRiskTabs.mqh"
#include "UIPanelProtectionTabs.mqh"

   CLabel                     m_cfgSystemHdr;
   CLabel                     m_cfgSystemMagicLbl;
   CEdit                      m_cfgSystemMagicEdit;
   CLabel                     m_cfgSystemConflictLbl;
   CButton                    m_cfgSystemConflictBtn;
   CLabel                     m_cfgSystemDebugLbl;
   CButton                    m_cfgSystemDebugBtn;
   CLabel                     m_cfgSystemFoot1;
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
#include "UIPanelInitialState.mqh"

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

   int                        DeleteObjectsByPrefix(const long chartId,const int subwin,const string prefix)
     {
      int deleted = 0;
      int total = ObjectsTotal(chartId, subwin);
      for(int i = total - 1; i >= 0; --i)
        {
         string objectName = ObjectName(chartId, i, subwin);
         if(StringFind(objectName, prefix) != 0)
            continue;

         if(ObjectDelete(chartId, objectName))
            deleted++;
        }
      return deleted;
     }

   bool                       IsFusionDialogCaption(const long chartId,const string objectName,string &prefix) const
     {
      prefix = "";
      int suffixStart = StringLen(objectName) - 7;
      if(suffixStart < 0 || StringSubstr(objectName, suffixStart) != "Caption")
         return false;

      string text = ObjectGetString(chartId, objectName, OBJPROP_TEXT);
      if(StringFind(text, "EP Fusion - versao ") != 0)
         return false;

      prefix = StringSubstr(objectName, 0, suffixStart);
      return (prefix != "");
     }

   void                       CleanupStaleFusionDialogs(const long chartId,const int subwin)
     {
      for(int pass = 0; pass < 16; ++pass)
        {
         string prefix = "";
         int total = ObjectsTotal(chartId, subwin);
         for(int i = total - 1; i >= 0; --i)
           {
            string objectName = ObjectName(chartId, i, subwin);
            if(IsFusionDialogCaption(chartId, objectName, prefix))
               break;
           }

         if(prefix == "")
            return;

         if(DeleteObjectsByPrefix(chartId, subwin, prefix) <= 0)
            return;
        }
     }

   bool                       HandlePanelClick(const string objectName)
     {
      if(HandleTopActionClick(objectName))
         return true;
      if(HandleConfigSystemClick(objectName))
         return true;
      if(HandleRiskClick(objectName))
         return true;
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
      CAppDialog::Minimize();
      if(m_created)
         HideManagedContent();
      ChartRedraw();
     }

   virtual void                Maximize(void)
     {
      CAppDialog::Maximize();
      if(!m_created)
        {
         ChartRedraw();
         return;
        }

      SetShellVisible(true);
      ApplyVisibility();
      UpdateActiveTabContent(true);
      ChartRedraw();
     }

public:
                              CFusionPanel(void)
     {
      ResetPanelInitialState();
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
      CleanupStaleFusionDialogs(chartId, subwin);

      if(!Create(chartId, name, subwin, x1, y1, x2, y2))
         return false;
      Caption(FusionWindowTitle());

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

      for(int i = 0; i < FUSION_STRATEGY_PANEL_COUNT; ++i)
        {
         if(m_strategyPanels[i] != NULL)
           {
            delete m_strategyPanels[i];
            m_strategyPanels[i] = NULL;
           }
        }

      for(int j = 0; j < FUSION_FILTER_PANEL_COUNT; ++j)
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

      m_snapshot.settings        = settings;
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
      m_snapshot.bbFilterEnabled = settings.bbFilterEnabled;
      if(!settings.enableSessionFilter)
        {
         m_snapshot.sessionProtectionBlocked = false;
         m_snapshot.sessionProtectionBlockReason = "";
        }

      bool hasEnabledNewsWindow = false;
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         if(settings.newsWindows[newsIndex].enabled)
           {
            hasEnabledNewsWindow = true;
            break;
           }
        }
      if(!hasEnabledNewsWindow)
        {
         m_snapshot.newsProtectionBlocked = false;
         m_snapshot.newsProtectionBlockReason = "";
        }

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
      if(!m_created)
         return;
      if(m_minimized)
        {
         bool wasEditBlocked = !ActiveProfileEditable();
         bool nowCanEditActiveProfile = ActiveProfileEditable(snapshot);
         m_snapshot = snapshot;
         if(wasEditBlocked && nowCanEditActiveProfile && m_hasCommittedSettings)
            RestoreCommittedDraftToControls();
         return;
        }

      bool wasEditBlocked = !ActiveProfileEditable();
      bool nowCanEditActiveProfile = ActiveProfileEditable(snapshot);
      bool runtimeStateChanged = (snapshot.started != m_snapshot.started || snapshot.hasPosition != m_snapshot.hasPosition);
      bool noticeStateChanged = (snapshot.runtimeNotice != m_snapshot.runtimeNotice ||
                                 snapshot.entryBlockReason != m_snapshot.entryBlockReason);
      bool streakStateChanged = (snapshot.streakProtectionBlocked != m_snapshot.streakProtectionBlocked ||
                                 snapshot.streakProtectionBlockReason != m_snapshot.streakProtectionBlockReason);
      bool dailyStateChanged = (snapshot.dailyLimitsBlocked != m_snapshot.dailyLimitsBlocked ||
                                snapshot.dailyLimitsBlockReason != m_snapshot.dailyLimitsBlockReason);
      bool sessionStateChanged = (snapshot.sessionProtectionBlocked != m_snapshot.sessionProtectionBlocked ||
                                  snapshot.sessionProtectionBlockReason != m_snapshot.sessionProtectionBlockReason);
      bool newsStateChanged = (snapshot.newsProtectionBlocked != m_snapshot.newsProtectionBlocked ||
                               snapshot.newsProtectionBlockReason != m_snapshot.newsProtectionBlockReason);
      bool drawdownStateChanged = (snapshot.drawdownProtectionActive != m_snapshot.drawdownProtectionActive ||
                                   snapshot.drawdownLimitReached != m_snapshot.drawdownLimitReached ||
                                   snapshot.drawdownConfigLocked != m_snapshot.drawdownConfigLocked ||
                                   snapshot.drawdownConfigLockReason != m_snapshot.drawdownConfigLockReason);
      bool drawdownRuntimeValuesChanged = (MathAbs(snapshot.drawdownPeakProfit - m_snapshot.drawdownPeakProfit) > 0.0000001 ||
                                           MathAbs(snapshot.drawdownFloorProfit - m_snapshot.drawdownFloorProfit) > 0.0000001 ||
                                           MathAbs(snapshot.drawdownBufferProfit - m_snapshot.drawdownBufferProfit) > 0.0000001 ||
                                           MathAbs(snapshot.drawdownTriggerProfit - m_snapshot.drawdownTriggerProfit) > 0.0000001 ||
                                           MathAbs(snapshot.drawdownTriggerDrawdown - m_snapshot.drawdownTriggerDrawdown) > 0.0000001 ||
                                           MathAbs(snapshot.drawdownTriggerBuffer - m_snapshot.drawdownTriggerBuffer) > 0.0000001);
      bool permissionStateChanged = runtimeStateChanged ||
                                    snapshot.runtimeBlocked != m_snapshot.runtimeBlocked ||
                                     snapshot.startBlockedReason != m_snapshot.startBlockedReason ||
                                     snapshot.activeProfileBlockedReason != m_snapshot.activeProfileBlockedReason ||
                                     snapshot.pendingReverseExit != m_snapshot.pendingReverseExit ||
                                     snapshot.tradePermissionBlocked != m_snapshot.tradePermissionBlocked ||
                                     snapshot.tradePermissionReason != m_snapshot.tradePermissionReason;
      bool editBlockExited = (wasEditBlocked && nowCanEditActiveProfile && m_hasCommittedSettings);
      bool redrawNeeded = runtimeStateChanged ||
                           snapshot.runtimeBlocked != m_snapshot.runtimeBlocked ||
                           snapshot.startBlockedReason != m_snapshot.startBlockedReason ||
                           snapshot.activeProfileBlockedReason != m_snapshot.activeProfileBlockedReason ||
                            snapshot.runtimeNotice != m_snapshot.runtimeNotice ||
                            snapshot.entryBlockReason != m_snapshot.entryBlockReason ||
                            snapshot.pendingReverseExit != m_snapshot.pendingReverseExit ||
                            snapshot.tradePermissionBlocked != m_snapshot.tradePermissionBlocked ||
                           snapshot.tradePermissionReason != m_snapshot.tradePermissionReason ||
                           snapshot.dailyTradeCount != m_snapshot.dailyTradeCount ||
                           MathAbs(snapshot.dailyClosedProfit - m_snapshot.dailyClosedProfit) > 0.0000001 ||
                           dailyStateChanged ||
                           sessionStateChanged ||
                           newsStateChanged ||
                           snapshot.lossStreak != m_snapshot.lossStreak ||
                           snapshot.winStreak != m_snapshot.winStreak ||
                           streakStateChanged ||
                           drawdownStateChanged ||
                           drawdownRuntimeValuesChanged;
      bool activeContentNeedsRefresh = (permissionStateChanged ||
                                        noticeStateChanged ||
                                        streakStateChanged ||
                                        dailyStateChanged ||
                                        sessionStateChanged ||
                                        newsStateChanged ||
                                        drawdownStateChanged ||
                                        editBlockExited);
      bool drawdownRuntimeOnlyChanged = (drawdownRuntimeValuesChanged &&
                                         !activeContentNeedsRefresh &&
                                         snapshot.dailyTradeCount == m_snapshot.dailyTradeCount &&
                                         MathAbs(snapshot.dailyClosedProfit - m_snapshot.dailyClosedProfit) <= 0.0000001 &&
                                         snapshot.lossStreak == m_snapshot.lossStreak &&
                                         snapshot.winStreak == m_snapshot.winStreak);
      bool protectionPageVisible = (m_configProtectionCreated && IsConfigPageVisible(FUSION_CFG_PROTECTION));
      bool drawdownPageVisible = (protectionPageVisible && m_protectPage == FUSION_PROTECT_DRAWDOWN);
      m_snapshot = snapshot;
      if(editBlockExited)
         RestoreCommittedDraftToControls();
      UpdateHeaderButtons();
      if(drawdownRuntimeOnlyChanged && protectionPageVisible)
        {
         if(drawdownPageVisible)
            SyncDrawdownRuntimeMetrics();
        }
      else
         UpdateActiveTabContent(activeContentNeedsRefresh);
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
         if(HandleProtectionChange(id, sparam))
            return true;
         if(HandleSignalPanelChange(id, sparam))
            return true;
        }
      return result;
     }
  };

#endif
