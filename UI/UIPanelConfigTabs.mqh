#ifndef __FUSION_UI_PANEL_CONFIG_TABS_MQH__
#define __FUSION_UI_PANEL_CONFIG_TABS_MQH__

   bool                       BuildConfigTab(void)
     {
      string pageNames[FUSION_CFG_COUNT] = {"RISK", "PROTECT", "SYSTEM", "VISUAL"};
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
      if(!AddLabel(m_cfgSystemDebugLbl, "Fusion_cfg_debug_lbl", 22, 274, 170, 292, "Logs Debug", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemDebugBtn, "Fusion_cfg_debug_btn", 200, 272, 310, 296, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgSystemFoot1, "Fusion_cfg_system_foot_1", 22, 330, 560, 348, "PRIORIDADE: em sinais opostos, o maior numero vence.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot2, "Fusion_cfg_system_foot_2", 22, 352, 560, 370, "CANCELAR: sinais opostos cancelam a entrada.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot4, "Fusion_cfg_system_foot_4", 22, 390, 560, 408, "Debug ON mostra logs detalhados; use apenas para diagnostico.", FUSION_CLR_MUTED, 8))
         return false;
      return true;
     }

   bool                       BuildConfigVisualPage(void)
     {
      if(!AddLabel(m_cfgVisualHdr, "Fusion_cfg_visual_hdr", 22, 160, 300, 180, "Indicadores Visuais", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgSystemIndicatorsLbl, "Fusion_cfg_indicators_lbl", 22, 198, 180, 216, "Indicadores no Grafico", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemIndicatorsBtn, "Fusion_cfg_indicators_btn", 200, 196, 310, 220, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddPanel(m_cfgSystemColorsFrame, "Fusion_cfg_colors_frame", 200, 234, 514, 472, FUSION_CLR_FRAME_BG, FUSION_CLR_FIELD_BORDER))
         return false;
      if(!AddLabel(m_cfgSystemColorsLbl, "Fusion_cfg_colors_lbl", 214, 246, 300, 264, "Indicador", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgVisualColorHdr, "Fusion_cfg_visual_color_hdr", 314, 246, 360, 264, "Cor", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgVisualStyleHdr, "Fusion_cfg_visual_style_hdr", 374, 246, 490, 264, "Linha", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgSystemFastColorLbl, "Fusion_cfg_fast_color_lbl", 214, 276, 300, 300, "MA Rapida", FUSION_CLR_LABEL) ||
         !AddButton(m_cfgSystemFastColorBtn, "Fusion_cfg_fast_color_btn", 318, 276, 346, 300, "", clrLime) ||
         !AddButton(m_cfgVisualFastStyleBtn, "Fusion_cfg_fast_style_btn", 374, 276, 494, 300, "CHEIA", FUSION_CLR_PANEL))
         return false;
      if(!AddLabel(m_cfgSystemSlowColorLbl, "Fusion_cfg_slow_color_lbl", 214, 314, 300, 338, "MA Lenta", FUSION_CLR_LABEL) ||
         !AddButton(m_cfgSystemSlowColorBtn, "Fusion_cfg_slow_color_btn", 318, 314, 346, 338, "", clrRed) ||
         !AddButton(m_cfgVisualSlowStyleBtn, "Fusion_cfg_slow_style_btn", 374, 314, 494, 338, "CHEIA", FUSION_CLR_PANEL))
         return false;
      if(!AddLabel(m_cfgSystemTrendColorLbl, "Fusion_cfg_trend_color_lbl", 214, 352, 300, 376, "Trend M1", FUSION_CLR_LABEL) ||
         !AddButton(m_cfgSystemTrendColorBtn, "Fusion_cfg_trend_color_btn", 318, 352, 346, 376, "", clrMagenta) ||
         !AddButton(m_cfgVisualTrendStyleBtn, "Fusion_cfg_trend_style_btn", 374, 352, 494, 376, "CHEIA", FUSION_CLR_PANEL))
         return false;
      if(!AddLabel(m_cfgSystemTrend2ColorLbl, "Fusion_cfg_trend2_color_lbl", 214, 390, 300, 414, "Trend M2", FUSION_CLR_LABEL) ||
         !AddButton(m_cfgSystemTrend2ColorBtn, "Fusion_cfg_trend2_color_btn", 318, 390, 346, 414, "", clrOrange) ||
         !AddButton(m_cfgVisualTrend2StyleBtn, "Fusion_cfg_trend2_style_btn", 374, 390, 494, 414, "CHEIA", FUSION_CLR_PANEL))
         return false;
      if(!AddLabel(m_cfgSystemBBColorLbl, "Fusion_cfg_bb_color_lbl", 214, 428, 300, 452, "Bandas", FUSION_CLR_LABEL) ||
         !AddButton(m_cfgSystemBBColorBtn, "Fusion_cfg_bb_color_btn", 318, 428, 346, 452, "", clrDodgerBlue) ||
         !AddButton(m_cfgVisualBBStyleBtn, "Fusion_cfg_bb_style_btn", 374, 428, 494, 452, "CHEIA", FUSION_CLR_PANEL))
         return false;

      if(!AddLabel(m_cfgSystemFootColors, "Fusion_cfg_system_foot_colors", 22, 492, 560, 510, "Clique na cor ou no estilo para alternar.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgSystemFoot3, "Fusion_cfg_system_foot_3", 22, 514, 560, 532, "Indicadores visuais permanecem isolados do motor operacional.", FUSION_CLR_MUTED, 8))
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
      FusionApplyToggleButtonStyle(m_cfgSystemDebugBtn, m_draftSettings.debugLogs, CanEditActiveProfile());
      return true;
     }

   bool                       EnsureConfigVisualPageCreated(void)
     {
      if(m_configVisualCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configVisualGroup);
      if(!BuildConfigVisualPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configVisualCreated = true;
      FusionApplyToggleButtonStyle(m_cfgSystemIndicatorsBtn, m_draftSettings.showChartIndicators, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemFastColorBtn, m_draftSettings.visualMAFastColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemSlowColorBtn, m_draftSettings.visualMASlowColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemTrendColorBtn, m_draftSettings.visualMATrendColor, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemTrend2ColorBtn, m_draftSettings.visualMATrend2Color, CanEditActiveProfile());
      FusionApplyColorSwatchStyle(m_cfgSystemBBColorBtn, m_draftSettings.visualBBColor, CanEditActiveProfile());
      FusionApplyVisualStyleButton(m_cfgVisualFastStyleBtn, m_draftSettings.visualMAFastStyle, CanEditActiveProfile());
      FusionApplyVisualStyleButton(m_cfgVisualSlowStyleBtn, m_draftSettings.visualMASlowStyle, CanEditActiveProfile());
      FusionApplyVisualStyleButton(m_cfgVisualTrendStyleBtn, m_draftSettings.visualMATrendStyle, CanEditActiveProfile());
      FusionApplyVisualStyleButton(m_cfgVisualTrend2StyleBtn, m_draftSettings.visualMATrend2Style, CanEditActiveProfile());
      FusionApplyVisualStyleButton(m_cfgVisualBBStyleBtn, m_draftSettings.visualBBStyle, CanEditActiveProfile());
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
      if(!m_configVisualCreated || objectName != m_cfgSystemIndicatorsBtn.Name())
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
      if(!m_configVisualCreated)
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
      else if(objectName == m_cfgSystemTrend2ColorBtn.Name())
        {
         ReleaseButton(m_cfgSystemTrend2ColorBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMATrend2Color = FusionNextVisualColor(m_draftSettings.visualMATrend2Color);
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

   bool                       HandleConfigVisualStyleClick(const string objectName)
     {
      if(!m_configVisualCreated)
         return false;

      if(objectName == m_cfgVisualFastStyleBtn.Name())
        {
         ReleaseButton(m_cfgVisualFastStyleBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMAFastStyle = FusionNextVisualStyle(m_draftSettings.visualMAFastStyle);
        }
      else if(objectName == m_cfgVisualSlowStyleBtn.Name())
        {
         ReleaseButton(m_cfgVisualSlowStyleBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMASlowStyle = FusionNextVisualStyle(m_draftSettings.visualMASlowStyle);
        }
      else if(objectName == m_cfgVisualTrendStyleBtn.Name())
        {
         ReleaseButton(m_cfgVisualTrendStyleBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMATrendStyle = FusionNextVisualStyle(m_draftSettings.visualMATrendStyle);
        }
      else if(objectName == m_cfgVisualTrend2StyleBtn.Name())
        {
         ReleaseButton(m_cfgVisualTrend2StyleBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualMATrend2Style = FusionNextVisualStyle(m_draftSettings.visualMATrend2Style);
        }
      else if(objectName == m_cfgVisualBBStyleBtn.Name())
        {
         ReleaseButton(m_cfgVisualBBStyleBtn);
         if(CanEditActiveProfile())
            m_draftSettings.visualBBStyle = FusionNextVisualStyle(m_draftSettings.visualBBStyle);
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
      if(HandleConfigSystemDebugClick(objectName))
         return true;
      return false;
     }

   bool                       HandleConfigVisualClick(const string objectName)
     {
      if(HandleConfigSystemIndicatorsClick(objectName))
         return true;
      if(HandleConfigSystemColorClick(objectName))
         return true;
      if(HandleConfigVisualStyleClick(objectName))
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
         !AddHitGroup(m_configSystemGroup, "Fusion_group_config_system") ||
         !AddHitGroup(m_configVisualGroup, "Fusion_group_config_visual"))
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
      if(!EnsureConfigVisualPageCreated())
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
