#ifndef __FUSION_UI_PANEL_CONFIG_TABS_MQH__
#define __FUSION_UI_PANEL_CONFIG_TABS_MQH__

   bool                       BuildConfigTab(void)
     {
      string pageNames[FUSION_CFG_COUNT] = {"RISK", "PROTECT", "SYSTEM"};
      int tabWidth = 120;
      int tabGap = 4;
      int x = 18;
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
        {
         if(!AddButton(m_configTabs[i], "Fusion_cfg_tab_" + IntegerToString(i), x, 104, x + tabWidth, 128, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_configTabsSeparator,
                   "Fusion_cfg_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   132,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   134,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_configContentFrame,
                   "Fusion_cfg_content_frame",
                   FUSION_PANEL_MARGIN,
                   138,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;
      if(!AddLabel(m_cfgStatus, "Fusion_cfg_status", 290, 36, FUSION_PANEL_WIDTH - 24, 56, "", FUSION_CLR_MUTED, 8))
         return false;
      return true;
     }

   bool                       BuildConfigRiskPage(void)
     {
      if(!AddLabel(m_cfgRiskHdr, "Fusion_cfg_risk_hdr", 22, 160, 260, 180, "Risco Base", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 198, 160, 216, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 200, 196, 310, 220, "0.10"))
         return false;
      if(!AddLabel(m_cfgRiskSLLbl, "Fusion_cfg_sl_lbl", 22, 236, 170, 254, "SL Fixo (0=off)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSLEdit, "Fusion_cfg_sl_edit", 200, 234, 310, 258, "0"))
         return false;
      if(!AddLabel(m_cfgRiskTPLbl, "Fusion_cfg_tp_lbl", 22, 274, 170, 292, "TP Fixo (0=off)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTPEdit, "Fusion_cfg_tp_edit", 200, 272, 310, 296, "0"))
         return false;
      return true;
     }

   bool                       EnsureConfigRiskPageCreated(void)
     {
      if(m_configRiskCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configRiskGroup);
      if(!BuildConfigRiskPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configRiskCreated = true;
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSLEdit.Text(IntegerToString(m_draftSettings.fixedSLPoints));
      m_cfgRiskTPEdit.Text(IntegerToString(m_draftSettings.fixedTPPoints));
      return true;
     }

   bool                       BuildConfigSystemPage(void)
     {
      if(!AddLabel(m_cfgSystemHdr, "Fusion_cfg_system_hdr", 22, 160, 300, 180, "Sistema e Persistencia", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgSystemMagicLbl, "Fusion_cfg_magic_lbl", 22, 198, 170, 216, "Magic", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgSystemMagicEdit, "Fusion_cfg_magic_edit", 200, 196, 340, 220, "0"))
         return false;
      if(!AddLabel(m_cfgSystemConflictLbl, "Fusion_cfg_conflict_lbl", 22, 236, 170, 254, "Resolver", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemConflictBtn, "Fusion_cfg_conflict_btn", 200, 234, 340, 258, "PRIORITY", FUSION_CLR_PANEL))
         return false;
      return true;
     }

   bool                       EnsureConfigSystemPageCreated(void)
     {
      if(m_configSystemCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configSystemGroup);
      if(!BuildConfigSystemPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configSystemCreated = true;
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
      return true;
     }

   bool                       HandleConfigSystemConflictClick(const string objectName)
     {
      if(!m_configSystemCreated || objectName != m_cfgSystemConflictBtn.Name())
         return false;

      ReleaseButton(m_cfgSystemConflictBtn);
      if(!TryBeginActiveProfileEdit())
         return true;

      m_draftSettings.conflictMode = (m_draftSettings.conflictMode == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
      RefreshConfigValidation();
      return true;
     }

   bool                       EnsureConfigTabCreated(void)
     {
      if(m_configTabCreated)
         return true;
      if(!AddHitGroup(m_configGroup, "Fusion_group_config"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_configGroup);
      if(!BuildConfigTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_configRiskGroup, "Fusion_group_config_risk") ||
         !AddHitGroup(m_configProtectionGroup, "Fusion_group_config_protection") ||
         !AddHitGroup(m_configSystemGroup, "Fusion_group_config_system"))
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigRiskPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigProtectionPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigSystemPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configTabCreated = true;
      SyncDraftSettingsToControls();
      UpdateConfigReadOnly();
      RefreshConfigValidation();
      return true;
     }

#endif
