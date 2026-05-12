#ifndef __FUSION_UI_PANEL_INITIAL_STATE_MQH__
#define __FUSION_UI_PANEL_INITIAL_STATE_MQH__

   void                       ResetPanelSnapshotState(void)
     {
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
     }

   void                       ResetPanelValidationState(void)
     {
      m_configInputsValid = true;
      m_cfgRiskValid = true;
      m_cfgProtectionValid = true;
      m_cfgSystemValid = true;
      m_cfgStatusText = "";
      m_cfgStatusColor = FUSION_CLR_MUTED;
      m_parentStatusText = "";
      m_parentStatusColor = FUSION_CLR_MUTED;
      m_strategyStatusText = "";
      m_filterStatusText = "";
      m_strategyStatusColor = FUSION_CLR_MUTED;
      m_filterStatusColor = FUSION_CLR_MUTED;

      for(int protectIndex = 0; protectIndex < FUSION_PROTECT_COUNT; ++protectIndex)
        {
         m_protectPageValid[protectIndex] = true;
         m_protectPageError[protectIndex] = "";
        }

      for(int strategyIndex = 0; strategyIndex < FUSION_STRAT_COUNT; ++strategyIndex)
         m_strategyPageValid[strategyIndex] = true;

      for(int filterIndex = 0; filterIndex < FUSION_FILTER_COUNT; ++filterIndex)
         m_filterPageValid[filterIndex] = true;

      m_profileTabValid = true;
      m_profileTabError = "";
     }

   void                       ResetPanelProfileState(void)
     {
      m_profileMode = FUSION_PROFILE_BROWSE;
      m_committedProfileName = "";
      ArrayResize(m_profileNames, 0);
      m_profileCount = 0;
      m_profileOffset = 0;
      m_profileSelected = -1;
      m_profileStatusOverride = "";
      m_profileStatusOverrideColor = FUSION_CLR_MUTED;
      m_profileStatusOverrideUntil = 0;
      m_profileEditSourceName = "";
     }

   void                       ResetPanelSignalState(void)
     {
      m_strategyOverviewCreated = false;
      m_filterOverviewCreated = false;

      for(int i = 0; i < FUSION_STRATEGY_PANEL_COUNT; ++i)
        {
         m_strategyPanels[i] = NULL;
         m_strategyPanelCreated[i] = false;
        }

      for(int j = 0; j < FUSION_FILTER_PANEL_COUNT; ++j)
        {
         m_filterPanels[j] = NULL;
         m_filterPanelCreated[j] = false;
        }
     }

   void                       ResetPanelInitialState(void)
     {
      m_chartId = 0;
      m_subWindow = 0;
      m_created = false;
      m_dialogRunning = false;
      m_mouseOverPanel = false;
      m_origDragTrade = true;
      m_origMouseScroll = true;
      m_hasCommittedSettings = false;
      m_headerButtonsReady = false;
      m_buildTarget = NULL;
      m_activeTab = FUSION_TAB_STATUS;
      m_strategyPage = FUSION_STRAT_OVERVIEW;
      m_filterPage = FUSION_FILTER_OVERVIEW;
      m_configPage = FUSION_CFG_RISK;
      m_protectPage = FUSION_PROTECT_GENERAL;
      m_statusPageCreated = false;
      m_resultsPageCreated = false;
      m_strategyTabCreated = false;
      m_filterTabCreated = false;
      m_profilesTabCreated = false;
      m_configTabCreated = false;
      m_configRiskCreated = false;
      m_configProtectionCreated = false;
      m_configSystemCreated = false;
      m_profilesBrowseCreated = false;
      m_profilesEditCreated = false;
      SetDefaultSettings(m_committedSettings);
      SetDefaultSettings(m_draftSettings);
      ResetPanelValidationState();
      ResetPanelProfileState();
      ResetPanelSignalState();
      ResetPanelSnapshotState();
      ClearPendingCommand();
     }

#endif
