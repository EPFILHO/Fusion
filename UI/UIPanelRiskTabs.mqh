   ENUM_FUSION_RISK_PAGE      m_riskPage;
   CButton                    m_riskTabs[FUSION_RISK_COUNT];
   CPanel                     m_riskTabsSeparator;
   CPanel                     m_riskContentFrame;

   CLabel                     m_cfgRiskLotHdr;
   CLabel                     m_cfgRiskLotDesc;
   CLabel                     m_cfgRiskLotLbl;
   CEdit                      m_cfgRiskLotEdit;

   CLabel                     m_cfgRiskSLTPHdr;
   CLabel                     m_cfgRiskSLTPDesc;
   CLabel                     m_cfgRiskSLLbl;
   CEdit                      m_cfgRiskSLEdit;
   CLabel                     m_cfgRiskTPLbl;
   CEdit                      m_cfgRiskTPEdit;

   CLabel                     m_cfgRiskPartialHdr;
   CLabel                     m_cfgRiskPartialDesc;
   CLabel                     m_cfgRiskPartialEnabledLbl;
   CButton                    m_cfgRiskPartialEnabledBtn;
   CLabel                     m_cfgRiskTP1Hdr;
   CLabel                     m_cfgRiskTP1EnabledLbl;
   CButton                    m_cfgRiskTP1EnabledBtn;
   CLabel                     m_cfgRiskTP1PercentLbl;
   CEdit                      m_cfgRiskTP1PercentEdit;
   CLabel                     m_cfgRiskTP1DistanceLbl;
   CEdit                      m_cfgRiskTP1DistanceEdit;
   CLabel                     m_cfgRiskTP2Hdr;
   CLabel                     m_cfgRiskTP2EnabledLbl;
   CButton                    m_cfgRiskTP2EnabledBtn;
   CLabel                     m_cfgRiskTP2PercentLbl;
   CEdit                      m_cfgRiskTP2PercentEdit;
   CLabel                     m_cfgRiskTP2DistanceLbl;
   CEdit                      m_cfgRiskTP2DistanceEdit;
   CLabel                     m_cfgRiskPartialFoot1;
   CLabel                     m_cfgRiskPartialFoot2;
   CLabel                     m_cfgRiskBreakevenHdr;
   CLabel                     m_cfgRiskBreakevenDesc;
   CLabel                     m_cfgRiskBreakevenEnabledLbl;
   CButton                    m_cfgRiskBreakevenEnabledBtn;
   CLabel                     m_cfgRiskBreakevenTriggerLbl;
   CEdit                      m_cfgRiskBreakevenTriggerEdit;
   CLabel                     m_cfgRiskBreakevenOffsetLbl;
   CEdit                      m_cfgRiskBreakevenOffsetEdit;
   CLabel                     m_cfgRiskBreakevenFoot1;
   CLabel                     m_cfgRiskBreakevenFoot2;
   CLabel                     m_cfgRiskTrailingHdr;
   CLabel                     m_cfgRiskTrailingDesc;

   bool                       RiskSubtabHasError(const ENUM_FUSION_RISK_PAGE page) const
     {
      if(page == FUSION_RISK_LOT)
         return !m_cfgRiskLotValid;
      if(page == FUSION_RISK_SLTP)
         return !m_cfgRiskSLTPValid;
      if(page == FUSION_RISK_PARTIAL)
         return !m_cfgRiskPartialValid;
      if(page == FUSION_RISK_BREAKEVEN)
         return !m_cfgRiskBEValid;
      return false;
     }

   bool                       RiskDecimalEditValue(CEdit &edit,double &value)
     {
      value = 0.0;
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      if(!FusionIsDecimalText(text, true))
         return false;
      value = StringToDouble(text);
      return (value >= 0.0);
     }

   bool                       RiskIntegerEditValue(CEdit &edit,int &value)
     {
      value = 0;
      string text = FusionTrimCopy(LiveEditText(edit));
      if(!FusionIsIntegerText(text, true))
         return false;
      value = (int)StringToInteger(text);
      return (value >= 0);
     }

   bool                       ValidateRiskPartialSettings(SEASettings &settings,const bool editable,string &error)
     {
      error = "";

      double tp1Percent = settings.tp1.percent;
      double tp2Percent = settings.tp2.percent;
      int tp1Distance = settings.tp1.distancePoints;
      int tp2Distance = settings.tp2.distancePoints;
      bool tp1PercentParsed = true;
      bool tp2PercentParsed = true;
      bool tp1DistanceParsed = true;
      bool tp2DistanceParsed = true;

      if(editable && m_configRiskCreated)
        {
         tp1PercentParsed = RiskDecimalEditValue(m_cfgRiskTP1PercentEdit, tp1Percent);
         tp2PercentParsed = RiskDecimalEditValue(m_cfgRiskTP2PercentEdit, tp2Percent);
         tp1DistanceParsed = RiskIntegerEditValue(m_cfgRiskTP1DistanceEdit, tp1Distance);
         tp2DistanceParsed = RiskIntegerEditValue(m_cfgRiskTP2DistanceEdit, tp2Distance);
         if(tp1PercentParsed)
            settings.tp1.percent = tp1Percent;
         if(tp2PercentParsed)
            settings.tp2.percent = tp2Percent;
         if(tp1DistanceParsed)
            settings.tp1.distancePoints = tp1Distance;
         if(tp2DistanceParsed)
            settings.tp2.distancePoints = tp2Distance;
        }

      bool tp1Active = (settings.usePartialTP && settings.tp1.enabled);
      bool tp2Active = (settings.usePartialTP && settings.tp2.enabled);
      bool hasTarget = (!settings.usePartialTP || tp1Active || tp2Active);
      bool tp1PercentValid = (!tp1Active || (tp1PercentParsed && tp1Percent > 0.0 && tp1Percent <= 100.0));
      bool tp2PercentValid = (!tp2Active || (tp2PercentParsed && tp2Percent > 0.0 && tp2Percent <= 100.0));
      bool tp1DistanceValid = (!tp1Active || (tp1DistanceParsed && tp1Distance > 0));
      bool tp2DistanceValid = (!tp2Active || (tp2DistanceParsed && tp2Distance > 0));
      double activePercent = (tp1Active ? tp1Percent : 0.0) + (tp2Active ? tp2Percent : 0.0);
      bool totalPercentValid = (!settings.usePartialTP || activePercent <= 100.0 + 0.0000001);

      bool valid = (hasTarget && tp1PercentValid && tp2PercentValid &&
                    tp1DistanceValid && tp2DistanceValid && totalPercentValid);

      if(m_configRiskCreated)
        {
         bool partialEditable = (editable && settings.usePartialTP);
         FusionApplyToggleButtonStyle(m_cfgRiskPartialEnabledBtn, settings.usePartialTP, editable);
         FusionApplyToggleButtonStyle(m_cfgRiskTP1EnabledBtn, settings.tp1.enabled, partialEditable);
         FusionApplyToggleButtonStyle(m_cfgRiskTP2EnabledBtn, settings.tp2.enabled, partialEditable);
         FusionApplyEditStyle(m_cfgRiskTP1PercentEdit, tp1PercentValid && totalPercentValid, partialEditable && settings.tp1.enabled);
         FusionApplyEditStyle(m_cfgRiskTP1DistanceEdit, tp1DistanceValid, partialEditable && settings.tp1.enabled);
         FusionApplyEditStyle(m_cfgRiskTP2PercentEdit, tp2PercentValid && totalPercentValid, partialEditable && settings.tp2.enabled);
         FusionApplyEditStyle(m_cfgRiskTP2DistanceEdit, tp2DistanceValid, partialEditable && settings.tp2.enabled);
         m_cfgRiskPartialEnabledLbl.Color(!editable ? FUSION_CLR_MUTED : (valid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP1EnabledLbl.Color(!partialEditable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgRiskTP2EnabledLbl.Color(!partialEditable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgRiskTP1PercentLbl.Color(!partialEditable || !settings.tp1.enabled ? FUSION_CLR_MUTED : ((tp1PercentValid && totalPercentValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP1DistanceLbl.Color(!partialEditable || !settings.tp1.enabled ? FUSION_CLR_MUTED : (tp1DistanceValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP2PercentLbl.Color(!partialEditable || !settings.tp2.enabled ? FUSION_CLR_MUTED : ((tp2PercentValid && totalPercentValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP2DistanceLbl.Color(!partialEditable || !settings.tp2.enabled ? FUSION_CLR_MUTED : (tp2DistanceValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(valid)
         return true;

      if(!hasTarget)
         error = "TP Parcial exige TP1 ou TP2 ativo.";
      else if(!tp1PercentValid)
         error = "TP1 % deve ser maior que 0 e ate 100.";
      else if(!tp2PercentValid)
         error = "TP2 % deve ser maior que 0 e ate 100.";
      else if(!tp1DistanceValid)
         error = "TP1 Dist deve ser maior que 0.";
      else if(!tp2DistanceValid)
         error = "TP2 Dist deve ser maior que 0.";
      else if(!totalPercentValid)
         error = "Soma de TP1 % e TP2 % deve ser ate 100.";
      else
         error = "Corrija o TP Parcial.";

      return false;
     }

   bool                       ValidateRiskBreakevenSettings(SEASettings &settings,const bool editable,string &error)
     {
      error = "";

      int triggerPoints = settings.breakevenTriggerPoints;
      int offsetPoints = settings.breakevenOffsetPoints;
      bool triggerParsed = true;
      bool offsetParsed = true;

      if(editable && m_configRiskCreated)
        {
         triggerParsed = RiskIntegerEditValue(m_cfgRiskBreakevenTriggerEdit, triggerPoints);
         offsetParsed = RiskIntegerEditValue(m_cfgRiskBreakevenOffsetEdit, offsetPoints);
         if(triggerParsed)
            settings.breakevenTriggerPoints = triggerPoints;
         if(offsetParsed)
            settings.breakevenOffsetPoints = offsetPoints;
        }

      bool triggerValid = (!settings.useBreakeven || (triggerParsed && triggerPoints > 0 && triggerPoints <= 100000));
      bool offsetValid = (!settings.useBreakeven || (offsetParsed && offsetPoints >= 0 && offsetPoints <= 100000));
      bool orderValid = (!settings.useBreakeven || !triggerValid || !offsetValid || offsetPoints <= triggerPoints);
      bool valid = (triggerValid && offsetValid && orderValid);

      if(m_configRiskCreated)
        {
         bool beEditable = (editable && settings.useBreakeven);
         FusionApplyToggleButtonStyle(m_cfgRiskBreakevenEnabledBtn, settings.useBreakeven, editable);
         FusionApplyEditStyle(m_cfgRiskBreakevenTriggerEdit, triggerValid && orderValid, beEditable);
         FusionApplyEditStyle(m_cfgRiskBreakevenOffsetEdit, offsetValid && orderValid, beEditable);
         m_cfgRiskBreakevenEnabledLbl.Color(!editable ? FUSION_CLR_MUTED : (valid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskBreakevenTriggerLbl.Color(!beEditable ? FUSION_CLR_MUTED : ((triggerValid && orderValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskBreakevenOffsetLbl.Color(!beEditable ? FUSION_CLR_MUTED : ((offsetValid && orderValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(valid)
         return true;

      if(!triggerValid)
         error = "BE Gatilho deve ser maior que 0 e ate 100000.";
      else if(!offsetValid)
         error = "BE Offset deve ficar entre 0 e 100000.";
      else if(!orderValid)
         error = "BE Offset nao pode ser maior que o gatilho.";
      else
         error = "Corrija o Breakeven.";

      return false;
     }

   void                       SyncRiskControls(void)
     {
      if(!m_configRiskCreated)
         return;

      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSLEdit.Text(IntegerToString(m_draftSettings.fixedSLPoints));
      m_cfgRiskTPEdit.Text(IntegerToString(m_draftSettings.fixedTPPoints));
      m_cfgRiskTP1PercentEdit.Text(DoubleToString(m_draftSettings.tp1.percent, 2));
      m_cfgRiskTP1DistanceEdit.Text(IntegerToString(m_draftSettings.tp1.distancePoints));
      m_cfgRiskTP2PercentEdit.Text(DoubleToString(m_draftSettings.tp2.percent, 2));
      m_cfgRiskTP2DistanceEdit.Text(IntegerToString(m_draftSettings.tp2.distancePoints));
      m_cfgRiskBreakevenTriggerEdit.Text(IntegerToString(m_draftSettings.breakevenTriggerPoints));
      m_cfgRiskBreakevenOffsetEdit.Text(IntegerToString(m_draftSettings.breakevenOffsetPoints));
     }

   void                       ApplyRiskTabStyles(void)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
        {
         if(tabIndex == (int)m_riskPage)
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], true);
         else if(RiskSubtabHasError((ENUM_FUSION_RISK_PAGE)tabIndex))
            FusionApplyActionButtonStyle(m_riskTabs[tabIndex], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], false);
        }
     }

   bool                       BuildConfigRiskPage(void)
     {
      string pageNames[FUSION_RISK_COUNT] = {"LOTE", "SL/TP", "TP PARCIAL", "BREAKEVEN", "TRAILING"};
      int tabWidth = 104;
      int tabGap = 2;
      int tabX = 18;
      for(int i = 0; i < FUSION_RISK_COUNT; ++i)
        {
         if(!AddButton(m_riskTabs[i], "Fusion_risk_tab_" + IntegerToString(i), tabX, 140, tabX + tabWidth, 164, pageNames[i], FUSION_CLR_PANEL))
            return false;
         tabX += tabWidth + tabGap;
        }
      if(!AddPanel(m_riskTabsSeparator,
                   "Fusion_risk_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   168,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   170,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_riskContentFrame,
                   "Fusion_risk_content_frame",
                   FUSION_PANEL_MARGIN,
                   174,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;

      if(!AddLabel(m_cfgRiskLotHdr, "Fusion_cfg_risk_lot_hdr", 22, 188, 260, 206, "Tamanho do Lote", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotDesc, "Fusion_cfg_risk_lot_desc", 22, 214, 520, 232, "Define o volume base usado nas novas entradas.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 250, 160, 268, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 200, 248, 310, 272, "0.10"))
         return false;

      if(!AddLabel(m_cfgRiskSLTPHdr, "Fusion_cfg_risk_sltp_hdr", 22, 188, 260, 206, "Stop Loss e Take Profit", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskSLTPDesc, "Fusion_cfg_risk_sltp_desc", 22, 214, 520, 232, "Distancias fixas aplicadas no envio da ordem.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLLbl, "Fusion_cfg_sl_lbl", 22, 250, 170, 268, "SL Fixo (0=off)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSLEdit, "Fusion_cfg_sl_edit", 200, 248, 310, 272, "0"))
         return false;
      if(!AddLabel(m_cfgRiskTPLbl, "Fusion_cfg_tp_lbl", 22, 288, 170, 306, "TP Fixo (0=off)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTPEdit, "Fusion_cfg_tp_edit", 200, 286, 310, 310, "0"))
         return false;

      if(!AddLabel(m_cfgRiskPartialHdr, "Fusion_cfg_risk_partial_hdr", 22, 188, 260, 206, "TP Parcial", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskPartialDesc, "Fusion_cfg_risk_partial_desc", 22, 214, 520, 232, "Fecha partes da posicao em alvos globais antes do TP final.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialEnabledLbl, "Fusion_cfg_risk_partial_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskPartialEnabledBtn, "Fusion_cfg_risk_partial_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;

      if(!AddLabel(m_cfgRiskTP1Hdr, "Fusion_cfg_risk_tp1_hdr", 22, 292, 180, 310, "TP1", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP1EnabledLbl, "Fusion_cfg_risk_tp1_enabled_lbl", 22, 322, 100, 340, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP1EnabledBtn, "Fusion_cfg_risk_tp1_enabled_btn", 112, 320, 202, 344, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP1PercentLbl, "Fusion_cfg_risk_tp1_pct_lbl", 22, 360, 100, 378, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1PercentEdit, "Fusion_cfg_risk_tp1_pct_edit", 112, 358, 202, 382, "50.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP1DistanceLbl, "Fusion_cfg_risk_tp1_dist_lbl", 22, 398, 100, 416, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1DistanceEdit, "Fusion_cfg_risk_tp1_dist_edit", 112, 396, 202, 420, "150"))
         return false;

      if(!AddLabel(m_cfgRiskTP2Hdr, "Fusion_cfg_risk_tp2_hdr", 298, 292, 456, 310, "TP2", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP2EnabledLbl, "Fusion_cfg_risk_tp2_enabled_lbl", 298, 322, 376, 340, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP2EnabledBtn, "Fusion_cfg_risk_tp2_enabled_btn", 388, 320, 478, 344, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP2PercentLbl, "Fusion_cfg_risk_tp2_pct_lbl", 298, 360, 376, 378, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2PercentEdit, "Fusion_cfg_risk_tp2_pct_edit", 388, 358, 478, 382, "25.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP2DistanceLbl, "Fusion_cfg_risk_tp2_dist_lbl", 298, 398, 376, 416, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2DistanceEdit, "Fusion_cfg_risk_tp2_dist_edit", 388, 396, 478, 420, "300"))
         return false;

      if(!AddLabel(m_cfgRiskPartialFoot1, "Fusion_cfg_risk_partial_foot_1", 22, 462, 520, 480, "TP Parcial nao abre trade; apenas gerencia posicao aberta.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialFoot2, "Fusion_cfg_risk_partial_foot_2", 22, 486, 520, 504, "A soma dos percentuais ativos deve ficar ate 100%.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskBreakevenHdr, "Fusion_cfg_risk_be_hdr", 22, 188, 260, 206, "Breakeven", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenDesc, "Fusion_cfg_risk_be_desc", 22, 214, 520, 232, "Ajusta o SL apos a posicao atingir o gatilho em lucro.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenEnabledLbl, "Fusion_cfg_risk_be_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskBreakevenEnabledBtn, "Fusion_cfg_risk_be_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenTriggerLbl, "Fusion_cfg_risk_be_trigger_lbl", 22, 288, 170, 306, "Gatilho (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskBreakevenTriggerEdit, "Fusion_cfg_risk_be_trigger_edit", 200, 286, 310, 310, "120"))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenOffsetLbl, "Fusion_cfg_risk_be_offset_lbl", 22, 326, 170, 344, "Offset (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskBreakevenOffsetEdit, "Fusion_cfg_risk_be_offset_edit", 200, 324, 310, 348, "10"))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenFoot1, "Fusion_cfg_risk_be_foot_1", 22, 462, 520, 480, "BE apenas ajusta o SL da posicao aberta.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenFoot2, "Fusion_cfg_risk_be_foot_2", 22, 486, 520, 504, "Offset 0 move o SL para a entrada; offset maior protege lucro.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskTrailingHdr, "Fusion_cfg_risk_trailing_hdr", 22, 188, 260, 206, "Trailing", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTrailingDesc, "Fusion_cfg_risk_trailing_desc", 22, 214, 520, 232, "Proxima fatia: inicio e passo em pontos.", FUSION_CLR_MUTED, 8))
         return false;

      return true;
     }

   void                       SetRiskLotVisible(const bool visible)
     {
      SetVisible(m_cfgRiskLotHdr, visible);
      SetVisible(m_cfgRiskLotDesc, visible);
      SetVisible(m_cfgRiskLotLbl, visible);
      SetVisible(m_cfgRiskLotEdit, visible);
     }

   void                       SetRiskSLTPVisible(const bool visible)
     {
      SetVisible(m_cfgRiskSLTPHdr, visible);
      SetVisible(m_cfgRiskSLTPDesc, visible);
      SetVisible(m_cfgRiskSLLbl, visible);
      SetVisible(m_cfgRiskSLEdit, visible);
      SetVisible(m_cfgRiskTPLbl, visible);
      SetVisible(m_cfgRiskTPEdit, visible);
     }

   void                       SetRiskPartialVisible(const bool visible)
     {
      SetVisible(m_cfgRiskPartialHdr, visible);
      SetVisible(m_cfgRiskPartialDesc, visible);
      SetVisible(m_cfgRiskPartialEnabledLbl, visible);
      SetVisible(m_cfgRiskPartialEnabledBtn, visible);
      SetVisible(m_cfgRiskTP1Hdr, visible);
      SetVisible(m_cfgRiskTP1EnabledLbl, visible);
      SetVisible(m_cfgRiskTP1EnabledBtn, visible);
      SetVisible(m_cfgRiskTP1PercentLbl, visible);
      SetVisible(m_cfgRiskTP1PercentEdit, visible);
      SetVisible(m_cfgRiskTP1DistanceLbl, visible);
      SetVisible(m_cfgRiskTP1DistanceEdit, visible);
      SetVisible(m_cfgRiskTP2Hdr, visible);
      SetVisible(m_cfgRiskTP2EnabledLbl, visible);
      SetVisible(m_cfgRiskTP2EnabledBtn, visible);
      SetVisible(m_cfgRiskTP2PercentLbl, visible);
      SetVisible(m_cfgRiskTP2PercentEdit, visible);
      SetVisible(m_cfgRiskTP2DistanceLbl, visible);
      SetVisible(m_cfgRiskTP2DistanceEdit, visible);
      SetVisible(m_cfgRiskPartialFoot1, visible);
      SetVisible(m_cfgRiskPartialFoot2, visible);
     }

   void                       SetRiskBreakevenVisible(const bool visible)
     {
      SetVisible(m_cfgRiskBreakevenHdr, visible);
      SetVisible(m_cfgRiskBreakevenDesc, visible);
      SetVisible(m_cfgRiskBreakevenEnabledLbl, visible);
      SetVisible(m_cfgRiskBreakevenEnabledBtn, visible);
      SetVisible(m_cfgRiskBreakevenTriggerLbl, visible);
      SetVisible(m_cfgRiskBreakevenTriggerEdit, visible);
      SetVisible(m_cfgRiskBreakevenOffsetLbl, visible);
      SetVisible(m_cfgRiskBreakevenOffsetEdit, visible);
      SetVisible(m_cfgRiskBreakevenFoot1, visible);
      SetVisible(m_cfgRiskBreakevenFoot2, visible);
     }

   void                       SetRiskTrailingVisible(const bool visible)
     {
      SetVisible(m_cfgRiskTrailingHdr, visible);
      SetVisible(m_cfgRiskTrailingDesc, visible);
     }

   void                       SetAllRiskPagesVisible(const bool visible)
     {
      SetRiskLotVisible(visible);
      SetRiskSLTPVisible(visible);
      SetRiskPartialVisible(visible);
      SetRiskBreakevenVisible(visible);
      SetRiskTrailingVisible(visible);
     }

   void                       SetActiveRiskPageVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      if(page == FUSION_RISK_LOT)
         SetRiskLotVisible(visible);
      else if(page == FUSION_RISK_SLTP)
         SetRiskSLTPVisible(visible);
      else if(page == FUSION_RISK_PARTIAL)
         SetRiskPartialVisible(visible);
      else if(page == FUSION_RISK_BREAKEVEN)
         SetRiskBreakevenVisible(visible);
      else if(page == FUSION_RISK_TRAILING)
         SetRiskTrailingVisible(visible);
     }

   void                       SetRiskControlsVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
         SetVisible(m_riskTabs[tabIndex], visible);
      SetVisible(m_riskTabsSeparator, visible);
      SetVisible(m_riskContentFrame, visible);

      SetAllRiskPagesVisible(false);

      if(visible)
         SetActiveRiskPageVisible(page, true);
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
      SetRiskControlsVisible(m_riskPage, false);
      SyncRiskControls();
      return true;
     }

   bool                       HandleRiskBooleanToggle(const string objectName,CButton &button,bool &target,const bool enabled)
     {
      if(objectName != button.Name())
         return false;

      ReleaseButton(button);
      if(!CanEditActiveProfile() || !enabled)
         return true;

      target = !target;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskPartialToggle(const string objectName)
     {
      if(objectName != m_cfgRiskPartialEnabledBtn.Name())
         return false;

      ReleaseButton(m_cfgRiskPartialEnabledBtn);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.usePartialTP = !m_draftSettings.usePartialTP;
      if(m_draftSettings.usePartialTP && !m_draftSettings.tp1.enabled && !m_draftSettings.tp2.enabled)
         m_draftSettings.tp1.enabled = true;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskToggleClick(const string objectName)
     {
      if(!m_configRiskCreated)
         return false;

      if(HandleRiskPartialToggle(objectName))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskTP1EnabledBtn, m_draftSettings.tp1.enabled, m_draftSettings.usePartialTP))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskTP2EnabledBtn, m_draftSettings.tp2.enabled, m_draftSettings.usePartialTP))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskBreakevenEnabledBtn, m_draftSettings.useBreakeven, true))
         return true;
      return false;
     }

   bool                       HandleRiskClick(const string objectName)
     {
      if(HandleRiskPageClick(objectName))
         return true;
      if(HandleRiskToggleClick(objectName))
         return true;
      return false;
     }

   bool                       HandleRiskPageClick(const string objectName)
     {
      if(!m_configRiskCreated)
         return false;

      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
        {
         if(objectName != m_riskTabs[tabIndex].Name())
            continue;

         ReleaseButton(m_riskTabs[tabIndex]);
         ResetDialogMouseRouting();
         m_riskPage = (ENUM_FUSION_RISK_PAGE)tabIndex;
         ApplyVisibility(false);
         RefreshConfigValidation();
         return true;
        }

      return false;
     }
