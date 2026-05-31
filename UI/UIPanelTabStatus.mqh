   bool                       ConfigSubtabHasError(const ENUM_FUSION_CONFIG_PAGE page) const
     {
      if(page == FUSION_CFG_RISK)
         return !m_cfgRiskValid;
      if(page == FUSION_CFG_PROTECTION)
         return !m_cfgProtectionValid;
      if(page == FUSION_CFG_SYSTEM)
         return !m_cfgSystemValid;
      return false;
     }

   bool                       HasProtectionOperationalWarning(void) const
     {
      return (m_snapshot.dailyLimitsBlocked ||
              (m_draftSettings.enableSessionFilter && m_snapshot.sessionProtectionBlocked) ||
              (HasDraftEnabledNewsWindow() && m_snapshot.newsProtectionBlocked) ||
              m_snapshot.drawdownConfigLocked ||
              m_snapshot.streakProtectionBlocked);
     }

   bool                       ConfigSubtabHasOperationalWarning(const ENUM_FUSION_CONFIG_PAGE page) const
     {
      if(page == FUSION_CFG_PROTECTION)
         return HasProtectionOperationalWarning();
      return false;
     }

   bool                       HasConfigTabOperationalWarning(void) const
     {
      return HasProtectionOperationalWarning();
     }

   bool                       HasConfigTabError(void) const
     {
      return (!m_cfgRiskValid || !m_cfgProtectionValid || !m_cfgSystemValid);
     }

   bool                       HasParentTabError(void) const
     {
      return (HasStrategyTabError() || HasFilterTabError() || HasProfileTabError() || HasConfigTabError());
     }

   bool                       UsesSharedParentStatus(void) const
     {
      return (m_activeTab == FUSION_TAB_STATUS ||
              m_activeTab == FUSION_TAB_RESULTS ||
              m_activeTab == FUSION_TAB_PROFILES);
     }

   void                       SetSharedParentStatus(const string text,const color clr)
     {
      m_parentStatusText = text;
      m_parentStatusColor = clr;
     }

   void                       ApplySharedParentStatus(void)
     {
      string profileBlockStatus = ProfileBlockStatusText();
      string tpslNotice = FusionTPSLExitZeroNotice(m_draftSettings);
      if(profileBlockStatus != "" && m_activeTab != FUSION_TAB_PROFILES)
         SetSharedParentStatus(profileBlockStatus, FUSION_CLR_WARN);
      else if(m_activeTab == FUSION_TAB_PROFILES && HasProfileTabError())
         SetSharedParentStatus(m_profileTabError, FUSION_CLR_BAD);
      else if(m_snapshot.tradePermissionBlocked)
         SetSharedParentStatus(m_snapshot.tradePermissionReason, FUSION_CLR_WARN);
      else if(m_snapshot.pendingReverseExit)
         SetSharedParentStatus("VM armada: reversao direta; guards ativos.", FUSION_CLR_WARN);
      else if(m_snapshot.dailyLimitsBlocked)
         SetSharedParentStatus(FusionTopRuntimeNoticeText(m_snapshot.dailyLimitsBlockReason), FUSION_CLR_WARN);
      else if(m_snapshot.drawdownLimitReached)
         SetSharedParentStatus(FusionTopRuntimeNoticeText(m_snapshot.drawdownConfigLockReason), FUSION_CLR_WARN);
      else if(m_draftSettings.enableSessionFilter && m_snapshot.sessionProtectionBlocked)
         SetSharedParentStatus(FusionTopRuntimeNoticeText(m_snapshot.sessionProtectionBlockReason), FUSION_CLR_WARN);
      else if(HasDraftEnabledNewsWindow() && m_snapshot.newsProtectionBlocked)
         SetSharedParentStatus(FusionTopRuntimeNoticeText(m_snapshot.newsProtectionBlockReason), FUSION_CLR_WARN);
      else if(m_snapshot.runtimeNotice != "")
         SetSharedParentStatus(FusionTopRuntimeNoticeText(m_snapshot.runtimeNotice), FUSION_CLR_WARN);
      else if(HasParentTabError())
         SetSharedParentStatus("Corrija aba(s) em vermelho.", FUSION_CLR_BAD);
      else if(ProfileEditMode())
         SetSharedParentStatus("Conclua ou cancele PERFIS.", FUSION_CLR_WARN);
      else if(tpslNotice != "")
         SetSharedParentStatus(tpslNotice, FUSION_CLR_WARN);
      else if(m_configInputsValid &&
              !m_snapshot.runtimeBlocked &&
              !m_snapshot.started &&
              !m_snapshot.hasPosition &&
              m_snapshot.startBlockedReason == "" &&
              m_snapshot.activeProfileBlockedReason == "")
         SetSharedParentStatus("EA pronto para operar.", FUSION_CLR_GOOD);
      else
         SetSharedParentStatus("", FUSION_CLR_MUTED);
     }

   void                       RefreshSharedParentStatusVisibility(void)
     {
      bool statusVisible = (UsesSharedParentStatus() && m_parentStatusText != "");
      if(statusVisible)
        {
         m_parentStatus.Text(m_parentStatusText);
         m_parentStatus.Color(m_parentStatusColor);
        }
      else
         m_parentStatus.Text("");
      SetVisible(m_parentStatus, statusVisible);
     }

   void                       RefreshSharedParentStatus(void)
     {
      ApplySharedParentStatus();
      RefreshSharedParentStatusVisibility();
     }

   void                       UpdateTabStyles(void)
     {
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(i == (int)m_activeTab)
            FusionApplyPrimaryButtonStyle(m_tabs[i], true);
         else if(i == (int)FUSION_TAB_STRATEGIES && HasStrategyTabError())
            FusionApplyActionButtonStyle(m_tabs[i], FUSION_CLR_BAD, true);
         else if(i == (int)FUSION_TAB_FILTERS && HasFilterTabError())
            FusionApplyActionButtonStyle(m_tabs[i], FUSION_CLR_BAD, true);
         else if(i == (int)FUSION_TAB_PROFILES && HasProfileTabError())
            FusionApplyActionButtonStyle(m_tabs[i], FUSION_CLR_BAD, true);
         else if(i == (int)FUSION_TAB_CONFIG && HasConfigTabError())
            FusionApplyActionButtonStyle(m_tabs[i], FUSION_CLR_BAD, true);
         else if(i == (int)FUSION_TAB_CONFIG && HasConfigTabOperationalWarning())
            FusionApplyActionButtonStyle(m_tabs[i], FUSION_CLR_WARN, true);
         else
            FusionApplyPrimaryButtonStyle(m_tabs[i], false);
        }
      if(m_strategyTabCreated)
         ApplyStrategyTabStyles();
      if(m_filterTabCreated)
         ApplyFilterTabStyles();
      if(m_configTabCreated)
        {
         for(int i = 0; i < FUSION_CFG_COUNT; ++i)
           {
            if(i == (int)m_configPage)
               FusionApplyPrimaryButtonStyle(m_configTabs[i], true);
            else if(ConfigSubtabHasError((ENUM_FUSION_CONFIG_PAGE)i))
               FusionApplyActionButtonStyle(m_configTabs[i], FUSION_CLR_BAD, true);
            else if(ConfigSubtabHasOperationalWarning((ENUM_FUSION_CONFIG_PAGE)i))
               FusionApplyActionButtonStyle(m_configTabs[i], FUSION_CLR_WARN, true);
            else
               FusionApplyPrimaryButtonStyle(m_configTabs[i], false);
           }
         if(m_configRiskCreated)
            ApplyRiskTabStyles();
         if(m_configProtectionCreated)
            ApplyProtectionTabStyles();
         if(m_configSystemCreated)
            m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
        }
     }

   bool                       RefreshConfigValidation(void)
     {
      SEASettings candidate;
      string profileName = "";
      string status = "";
      RefreshProfileValidationState();
      bool valid = BuildPendingSettings(candidate, profileName, status);
      RefreshSharedParentStatus();
      RefreshTheme();
      UpdateTabStyles();
      return valid;
     }
