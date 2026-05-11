#ifndef __FUSION_UI_PANEL_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_VISIBILITY_MQH__

   bool                       IsConfigPageVisible(const ENUM_FUSION_CONFIG_PAGE page) const
     {
      return (m_activeTab == FUSION_TAB_CONFIG && m_configPage == page);
     }

   void                       RefreshTheme(void)
     {
      RefreshHeaderTheme();
      if(m_configProtectionCreated && IsConfigPageVisible(FUSION_CFG_PROTECTION))
         RefreshProtectionTheme();
      if(m_configSystemCreated && IsConfigPageVisible(FUSION_CFG_SYSTEM))
        {
         if(CanEditActiveProfile())
            FusionApplyActionButtonStyle(m_cfgSystemConflictBtn, FUSION_CLR_NAV_IDLE, true);
         else
            FusionApplyNeutralButtonStyle(m_cfgSystemConflictBtn);
        }
      if(m_activeTab == FUSION_TAB_PROFILES)
         UpdateProfileListView();
     }

   void                       UpdateActiveTabContent(const bool runtimeStateChanged)
     {
      if(m_activeTab == FUSION_TAB_STATUS)
        {
         if(m_statusPageCreated)
            m_statusPage.Update(m_snapshot);
        }
      else if(m_activeTab == FUSION_TAB_RESULTS)
        {
         if(m_resultsPageCreated)
            m_resultsPage.Update(m_snapshot, m_committedSettings, m_committedProfileName);
        }
      else if(m_activeTab == FUSION_TAB_STRATEGIES)
        {
         if(m_strategyTabCreated)
            UpdateOverviews();
         if(runtimeStateChanged && m_strategyTabCreated)
            SyncStrategyPanels();
        }
      else if(m_activeTab == FUSION_TAB_FILTERS)
        {
         if(m_filterTabCreated)
            UpdateOverviews();
         if(runtimeStateChanged && m_filterTabCreated)
            SyncFilterPanels();
        }
      else if(m_activeTab == FUSION_TAB_PROFILES)
        {
         if(runtimeStateChanged && m_profilesTabCreated)
            UpdateProfileListView();
        }
      else if(m_activeTab == FUSION_TAB_CONFIG)
        {
         if(m_configTabCreated)
            UpdateConfigReadOnly();
         if(runtimeStateChanged && m_configTabCreated)
            RefreshConfigValidation();
        }
     }

   void                       UpdateConfigReadOnly(void)
     {
      if(m_configProtectionCreated && IsConfigPageVisible(FUSION_CFG_PROTECTION))
         RefreshProtectionTheme();
     }

   void                       SetConfigVisible(const bool visible)
     {
      if(!m_configTabCreated)
         return;

      SetVisible(m_configGroup, visible);
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
         SetVisible(m_configTabs[i], visible);
      SetVisible(m_configTabsSeparator, visible);
      SetVisible(m_configContentFrame, visible && m_configPage != FUSION_CFG_PROTECTION);

      bool riskVisible = visible && m_configPage == FUSION_CFG_RISK;
      bool protectionVisible = visible && m_configPage == FUSION_CFG_PROTECTION;
      bool systemVisible = visible && m_configPage == FUSION_CFG_SYSTEM;

      if(m_configRiskCreated)
        {
         SetVisible(m_configRiskGroup, riskVisible);
         SetVisible(m_cfgRiskHdr, riskVisible);
         SetVisible(m_cfgRiskLotLbl, riskVisible);
         SetVisible(m_cfgRiskLotEdit, riskVisible);
        }

      if(m_configProtectionCreated)
        {
         SetVisible(m_configProtectionGroup, protectionVisible);
         for(int p = 0; p < FUSION_PROTECT_COUNT; ++p)
            SetVisible(m_protectTabs[p], protectionVisible);
         SetProtectionControlsVisible(m_protectPage, protectionVisible);
        }

      if(m_configSystemCreated)
        {
         SetVisible(m_configSystemGroup, systemVisible);
         SetVisible(m_cfgSystemHdr, systemVisible);
         SetVisible(m_cfgSystemMagicLbl, systemVisible);
         SetVisible(m_cfgSystemMagicEdit, systemVisible);
         SetVisible(m_cfgSystemConflictLbl, systemVisible);
         SetVisible(m_cfgSystemConflictBtn, systemVisible);
        }
      if(visible)
         RestoreConfigStatus();
      SetVisible(m_cfgStatus, visible);
     }

   void                       SetShellVisible(const bool visible)
     {
      SetVisible(m_lblHeader, visible);
      SetVisible(m_btnStart, visible);
      SetVisible(m_btnSave, visible);
      SetVisible(m_btnCancel, visible);
      SetVisible(m_lblProfile, visible);
      SetVisible(m_activeProfile, visible);
      if(!visible)
         SetVisible(m_parentStatus, false);
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
         SetVisible(m_tabs[i], visible);
      SetVisible(m_tabsSeparator, visible);
     }

   void                       ResetDialogMouseRouting(void)
     {
      long dialogId = Id();
      string dialogName = Name();

      CAppDialog::ChartEvent(CHARTEVENT_CUSTOM + ON_MOUSE_FOCUS_SET, dialogId, 0.0, dialogName);
      CAppDialog::ChartEvent(CHARTEVENT_CUSTOM + ON_BRING_TO_TOP, dialogId, 0.0, dialogName);
     }

   void                       HideManagedContent(void)
     {
      SetShellVisible(false);
      if(m_statusPageCreated)
        {
         SetVisible(m_statusGroup, false);
         m_statusPage.SetVisible(false);
        }
      if(m_resultsPageCreated)
        {
         SetVisible(m_resultsGroup, false);
         m_resultsPage.SetVisible(false);
        }
      if(m_strategyTabCreated)
         SetStrategiesVisible(false);
      if(m_filterTabCreated)
         SetFiltersVisible(false);
      if(m_profilesTabCreated)
         SetProfilesVisible(false);
      SetConfigVisible(false);
     }

   void                       ApplyVisibility(const bool refreshTheme=true)
     {
      if(m_statusPageCreated)
        {
         bool statusVisible = (m_activeTab == FUSION_TAB_STATUS);
         SetVisible(m_statusGroup, statusVisible);
         m_statusPage.SetVisible(statusVisible);
        }
      if(m_resultsPageCreated)
        {
         bool resultsVisible = (m_activeTab == FUSION_TAB_RESULTS);
         SetVisible(m_resultsGroup, resultsVisible);
         m_resultsPage.SetVisible(resultsVisible);
        }
      if(m_strategyTabCreated)
         SetStrategiesVisible(m_activeTab == FUSION_TAB_STRATEGIES);
      if(m_filterTabCreated)
         SetFiltersVisible(m_activeTab == FUSION_TAB_FILTERS);
      if(m_profilesTabCreated)
         SetProfilesVisible(m_activeTab == FUSION_TAB_PROFILES);
      SetConfigVisible(m_activeTab == FUSION_TAB_CONFIG);
      ApplySharedParentStatus();
      RefreshSharedParentStatusVisibility();
      if(refreshTheme)
         RefreshTheme();
      UpdateTabStyles();
     }

#endif
