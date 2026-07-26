#ifndef __FUSION_UI_PANEL_RISK_BUILD_MQH__
#define __FUSION_UI_PANEL_RISK_BUILD_MQH__

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
      if(!AddLabel(m_cfgRiskSlippageLbl, "Fusion_cfg_slippage_lbl", 22, 288, 160, 306, "Slippage (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSlippageEdit, "Fusion_cfg_slippage_edit", 200, 286, 310, 310, "20"))
         return false;
      if(!AddLabel(m_cfgRiskLotFoot1, "Fusion_cfg_risk_lot_foot_1", 22, 424, 540, 442, "Slippage e tolerancia de execucao, nao garantia de preco.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskLotFoot2, "Fusion_cfg_risk_lot_foot_2", 22, 448, 540, 466, "Use 0 para enviar sem desvio; valido de 0 a 100000 pontos.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskSLTPHdr, "Fusion_cfg_risk_sltp_hdr", 22, 188, 260, 206, "Stop Loss e Take Profit", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskSLTPDesc, "Fusion_cfg_risk_sltp_desc", 22, 214, 520, 232, "Distancias fixas aplicadas no envio da ordem.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLLbl, "Fusion_cfg_sl_lbl", 22, 250, 170, 268, "SL Fixo (pts MT5)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSLEdit, "Fusion_cfg_sl_edit", 200, 248, 310, 272, "0"))
         return false;
      if(!AddLabel(m_cfgRiskTPLbl, "Fusion_cfg_tp_lbl", 22, 288, 170, 306, "TP Fixo (pts MT5)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTPEdit, "Fusion_cfg_tp_edit", 200, 286, 310, 310, "0"))
         return false;
      if(!AddLabel(m_cfgRiskSLCompLbl, "Fusion_cfg_sl_comp_lbl", 22, 326, 190, 344, "Compensar Spread SL", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskSLCompBtn, "Fusion_cfg_sl_comp_btn", 200, 324, 310, 348, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTPCompLbl, "Fusion_cfg_tp_comp_lbl", 22, 364, 190, 382, "Compensar Spread TP", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTPCompBtn, "Fusion_cfg_tp_comp_btn", 200, 362, 310, 386, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot1, "Fusion_cfg_risk_sltp_foot_1", 22, 424, 540, 442, "Informe SL/TP em pontos do MT5; 0 desliga.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot2, "Fusion_cfg_risk_sltp_foot_2", 22, 448, 540, 466, "Use a mesma contagem exibida pela regua do grafico.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot3, "Fusion_cfg_risk_sltp_foot_3", 22, 472, 540, 490, "Spread atual: -- pts. EA valida o minimo da corretora.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskPartialHdr, "Fusion_cfg_risk_partial_hdr", 22, 188, 260, 206, "TP Parcial", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskPartialDesc, "Fusion_cfg_risk_partial_desc", 22, 214, 520, 232, "Fecha partes da posicao em alvos globais antes do TP final.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskTP1Hdr, "Fusion_cfg_risk_tp1_hdr", 22, 250, 180, 268, "TP1", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP1EnabledLbl, "Fusion_cfg_risk_tp1_enabled_lbl", 22, 280, 100, 298, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP1EnabledBtn, "Fusion_cfg_risk_tp1_enabled_btn", 112, 278, 202, 302, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP1PercentLbl, "Fusion_cfg_risk_tp1_pct_lbl", 22, 318, 100, 336, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1PercentEdit, "Fusion_cfg_risk_tp1_pct_edit", 112, 316, 202, 340, "50.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP1DistanceLbl, "Fusion_cfg_risk_tp1_dist_lbl", 22, 356, 100, 374, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1DistanceEdit, "Fusion_cfg_risk_tp1_dist_edit", 112, 354, 202, 378, "150"))
         return false;

      if(!AddLabel(m_cfgRiskTP2Hdr, "Fusion_cfg_risk_tp2_hdr", 298, 250, 456, 268, "TP2", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP2EnabledLbl, "Fusion_cfg_risk_tp2_enabled_lbl", 298, 280, 376, 298, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP2EnabledBtn, "Fusion_cfg_risk_tp2_enabled_btn", 388, 278, 478, 302, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP2PercentLbl, "Fusion_cfg_risk_tp2_pct_lbl", 298, 318, 376, 336, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2PercentEdit, "Fusion_cfg_risk_tp2_pct_edit", 388, 316, 478, 340, "25.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP2DistanceLbl, "Fusion_cfg_risk_tp2_dist_lbl", 298, 356, 376, 374, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2DistanceEdit, "Fusion_cfg_risk_tp2_dist_edit", 388, 354, 478, 378, "300"))
         return false;
      if(!AddLabel(m_cfgRiskFreeTPLbl, "Fusion_cfg_risk_free_tp_lbl", 22, 432, 110, 450, "TP Final Livre", FUSION_CLR_LABEL, 8))
         return false;
      if(!AddButton(m_cfgRiskFreeTPBtn, "Fusion_cfg_risk_free_tp_btn", 112, 430, 202, 454, "OFF", FUSION_CLR_BAD))
         return false;

      if(!AddLabel(m_cfgRiskPartialFoot1, "Fusion_cfg_risk_partial_foot_1", 22, 484, 520, 502, "TP1 ON ativa o TP parcial; TP2 depende dele.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialFoot2, "Fusion_cfg_risk_partial_foot_2", 22, 508, 520, 526, "TP Final Livre remove o TP final apos o ultimo parcial.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialFoot3, "Fusion_cfg_risk_partial_foot_3", 22, 532, 520, 550, "Requer trailing ativo; o restante passa a sair pelo trailing.", FUSION_CLR_MUTED, 8))
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
      if(!AddLabel(m_cfgRiskTrailingDesc, "Fusion_cfg_risk_trailing_desc", 22, 214, 520, 232, "Move o SL acompanhando o preco apos atingir o inicio em lucro.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskTrailingEnabledLbl, "Fusion_cfg_risk_trailing_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTrailingEnabledBtn, "Fusion_cfg_risk_trailing_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTrailingStartLbl, "Fusion_cfg_risk_trailing_start_lbl", 22, 288, 170, 306, "Inicio (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTrailingStartEdit, "Fusion_cfg_risk_trailing_start_edit", 200, 286, 310, 310, "150"))
         return false;
      if(!AddLabel(m_cfgRiskTrailingStepLbl, "Fusion_cfg_risk_trailing_step_lbl", 22, 326, 170, 344, "Passo (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTrailingStepEdit, "Fusion_cfg_risk_trailing_step_edit", 200, 324, 310, 348, "80"))
         return false;
      if(!AddLabel(m_cfgRiskTrailingFoot1, "Fusion_cfg_risk_trailing_foot_1", 22, 462, 520, 480, "Trailing apenas ajusta o SL da posicao aberta.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskTrailingFoot2, "Fusion_cfg_risk_trailing_foot_2", 22, 486, 520, 504, "Passo define a distancia entre preco atual e novo SL.", FUSION_CLR_MUTED, 8))
         return false;

      return true;
     }

#endif
