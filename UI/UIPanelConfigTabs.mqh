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

   bool                       BuildConfigSystemPage(void)
     {
      if(!AddLabel(m_cfgSystemHdr, "Fusion_cfg_system_hdr", 22, 160, 300, 180, "Sistema e Persistencia", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgSystemMagicLbl, "Fusion_cfg_magic_lbl", 22, 198, 170, 216, "Magic Number do EA", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgSystemMagicEdit, "Fusion_cfg_magic_edit", 200, 196, 340, 220, "0"))
         return false;
      if(!AddLabel(m_cfgSystemConflictLbl, "Fusion_cfg_conflict_lbl", 22, 236, 170, 254, "Resolver Conflito", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemConflictBtn, "Fusion_cfg_conflict_btn", 200, 234, 340, 258, "PRIORIDADE", FUSION_CLR_PANEL))
         return false;
      if(!AddLabel(m_cfgSystemIndicatorsLbl, "Fusion_cfg_indicators_lbl", 22, 274, 180, 292, "Indicadores no Grafico", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemIndicatorsBtn, "Fusion_cfg_indicators_btn", 200, 272, 310, 296, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgSystemColorsLbl, "Fusion_cfg_colors_lbl", 22, 312, 190, 330, "Cores dos Indicadores", FUSION_CLR_LABEL))
         return false;
      if(!AddPanel(m_cfgSystemColorsFrame, "Fusion_cfg_colors_frame", 200, 306, 506, 400, FUSION_CLR_FRAME_BG, FUSION_CLR_FIELD_BORDER))
         return false;
      if(!AddLabel(m_cfgSystemFastColorLbl, "Fusion_cfg_fast_color_lbl", 212, 320, 282, 344, "MA Rapida", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemFastColorBtn, "Fusion_cfg_fast_color_btn", 286, 320, 310, 344, "", clrLime))
         return false;
      if(!AddLabel(m_cfgSystemSlowColorLbl, "Fusion_cfg_slow_color_lbl", 354, 320, 424, 344, "MA Lenta", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemSlowColorBtn, "Fusion_cfg_slow_color_btn", 428, 320, 452, 344, "", clrRed))
         return false;
      if(!AddLabel(m_cfgSystemTrendColorLbl, "Fusion_cfg_trend_color_lbl", 212, 362, 282, 386, "Trend", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemTrendColorBtn, "Fusion_cfg_trend_color_btn", 286, 362, 310, 386, "", clrMagenta))
         return false;
      if(!AddLabel(m_cfgSystemBBColorLbl, "Fusion_cfg_bb_color_lbl", 354, 362, 424, 386, "Bandas", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemBBColorBtn, "Fusion_cfg_bb_color_btn", 428, 362, 452, 386, "", clrDodgerBlue))
         return false;
      ObjectSetString(m_chartId, m_cfgSystemFastColorBtn.Name(), OBJPROP_TOOLTIP, "Cor da MA Rapida");
      ObjectSetString(m_chartId, m_cfgSystemSlowColorBtn.Name(), OBJPROP_TOOLTIP, "Cor da MA Lenta");
      ObjectSetString(m_chartId, m_cfgSystemTrendColorBtn.Name(), OBJPROP_TOOLTIP, "Cor da MA Trend");
      ObjectSetString(m_chartId, m_cfgSystemBBColorBtn.Name(), OBJPROP_TOOLTIP, "Cor do Bollinger");
      if(!AddLabel(m_cfgSystemDebugLbl, "Fusion_cfg_debug_lbl", 22, 412, 170, 430, "Logs Debug", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemDebugBtn, "Fusion_cfg_debug_btn", 200, 410, 310, 434, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgSystemFootColors, "Fusion_cfg_system_foot_colors", 22, 448, 560, 466, "Para mudar a cor, clique no quadrado do indicador.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot1, "Fusion_cfg_system_foot_1", 22, 470, 560, 488, "PRIORIDADE: em sinais opostos, o maior numero vence.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot2, "Fusion_cfg_system_foot_2", 22, 492, 560, 510, "CANCELAR: sinais opostos cancelam a entrada.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot3, "Fusion_cfg_system_foot_3", 22, 514, 560, 532, "MAs seguem o TF rapido; RSI/BB exigem o TF configurado.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot4, "Fusion_cfg_system_foot_4", 22, 536, 560, 554, "Debug ON mostra logs detalhados; use apenas para diagnostico.", FUSION_CLR_MUTED, 8))
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
      FusionApplyToggleButtonStyle(m_cfgSystemIndicatorsBtn, m_draftSettings.showChartIndicators, CanEditActiveProfile());
      FusionApplyToggleButtonStyle(m_cfgSystemDebugBtn, m_draftSettings.debugLogs, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemFastColorBtn, m_draftSettings.visualMAFastColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemSlowColorBtn, m_draftSettings.visualMASlowColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemTrendColorBtn, m_draftSettings.visualMATrendColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemBBColorBtn, m_draftSettings.visualBBColor, CanEditActiveProfile());
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

   bool                       HandleConfigSystemDebugClick(const string objectName)
     {
      if(!m_configSystemCreated || objectName != m_cfgSystemDebugBtn.Name())
         return false;

      ReleaseButton(m_cfgSystemDebugBtn);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.debugLogs = !m_draftSettings.debugLogs;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleConfigSystemIndicatorsClick(const string objectName)
     {
      if(!m_configSystemCreated || objectName != m_cfgSystemIndicatorsBtn.Name())
         return false;

      ReleaseButton(m_cfgSystemIndicatorsBtn);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.showChartIndicators = !m_draftSettings.showChartIndicators;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleConfigSystemColorClick(const string objectName)
     {
      if(!m_configSystemCreated)
         return false;

      if(objectName == m_cfgSystemFastColorBtn.Name())
        {
         ReleaseButton(m_cfgSystemFastColorBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMAFastColor = FusionNextVisualColor(m_draftSettings.visualMAFastColor);
        }
      else if(objectName == m_cfgSystemSlowColorBtn.Name())
        {
         ReleaseButton(m_cfgSystemSlowColorBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMASlowColor = FusionNextVisualColor(m_draftSettings.visualMASlowColor);
        }
      else if(objectName == m_cfgSystemTrendColorBtn.Name())
        {
         ReleaseButton(m_cfgSystemTrendColorBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMATrendColor = FusionNextVisualColor(m_draftSettings.visualMATrendColor);
        }
      else if(objectName == m_cfgSystemBBColorBtn.Name())
        {
         ReleaseButton(m_cfgSystemBBColorBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualBBColor = FusionNextVisualColor(m_draftSettings.visualBBColor);
        }
      else
         return false;

      RefreshConfigValidation();
      return true;
     }

   bool                       HandleConfigSystemClick(const string objectName)
     {
      if(HandleConfigSystemConflictClick(objectName))
         return true;
      if(HandleConfigSystemIndicatorsClick(objectName))
         return true;
      if(HandleConfigSystemColorClick(objectName))
         return true;
      if(HandleConfigSystemDebugClick(objectName))
         return true;
      return false;
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
