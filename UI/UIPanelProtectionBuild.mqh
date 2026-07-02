#ifndef __FUSION_UI_PANEL_PROTECTION_BUILD_MQH__
#define __FUSION_UI_PANEL_PROTECTION_BUILD_MQH__

   bool                       BuildConfigProtectionPage(void)
     {
      string pageNames[FUSION_PROTECT_COUNT] = {"GERAL", "ENTRY", "SESSION", "NEWS", "DAY", "DRAWDOWN", "STREAK"};
      int tabWidth = 74;
      int tabGap = 2;
      int tabX = 18;
      for(int i = 0; i < FUSION_PROTECT_COUNT; ++i)
        {
         if(!AddButton(m_protectTabs[i], "Fusion_protect_tab_" + IntegerToString(i), tabX, 140, tabX + tabWidth, 164, pageNames[i], FUSION_CLR_PANEL))
            return false;
         tabX += tabWidth + tabGap;
        }
      if(!AddPanel(m_protectTabsSeparator,
                   "Fusion_protect_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   168,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   170,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_protectContentFrame,
                   "Fusion_protect_content_frame",
                   FUSION_PANEL_MARGIN,
                   174,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;

      if(!AddLabel(m_protectGeneralHdr, "Fusion_protect_general_hdr", 22, 188, 280, 206, "Resumo de Protecao", FUSION_CLR_VALUE, 9))
         return false;
      string generalLabels[FUSION_PROTECT_OVERVIEW_COUNT] = {"Entrada", "Sessao", "News", "DAY", "DD", "Streak"};
      int generalY = 226;
      for(int generalIndex = 0; generalIndex < FUSION_PROTECT_OVERVIEW_COUNT; ++generalIndex)
        {
         if(!AddLabel(m_protectGeneralLabels[generalIndex], "Fusion_protect_general_lbl_" + IntegerToString(generalIndex), 22, generalY, 170, generalY + 18, generalLabels[generalIndex], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_protectGeneralValues[generalIndex], "Fusion_protect_general_val_" + IntegerToString(generalIndex), 190, generalY, 520, generalY + 18, "--", FUSION_CLR_VALUE))
            return false;
         generalY += 32;
        }

      if(!AddLabel(m_protectSpreadHdr, "Fusion_protect_spread_hdr", 22, 188, 280, 206, "Protecao de Entrada", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectSpreadDesc, "Fusion_protect_spread_desc", 22, 214, 520, 232, "Regras globais aplicadas antes de enviar uma nova ordem.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectSpreadEnabledLbl, "Fusion_protect_spread_enabled_lbl", 22, 250, 160, 268, "Max Spread", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectSpreadEnabledBtn, "Fusion_protect_spread_enabled_btn", 200, 248, 290, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddEdit(m_protectSpreadLimitEdit, "Fusion_protect_spread_limit_edit", 306, 248, 416, 272, "0"))
         return false;
      if(!AddLabel(m_protectSpreadLimitLbl, "Fusion_protect_spread_limit_lbl", 424, 250, 470, 268, "pts", FUSION_CLR_LABEL))
         return false;
      if(!m_protectDirection.Create(GetPointer(this),
                                    m_chartId,
                                    m_subWindow,
                                    "Fusion_protect_direction",
                                    "Direcao",
                                    FUSION_SELECTION_TRADE_DIRECTION,
                                    22,
                                    288,
                                    170,
                                    306,
                                    200,
                                    286,
                                    340,
                                    310))
         return false;
      if(!AddLabel(m_protectEntryFoot1, "Fusion_protect_entry_foot_1", 22, 482, 520, 500, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectEntryFoot2, "Fusion_protect_entry_foot_2", 22, 506, 520, 524, "", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_protectSessionHdr, "Fusion_protect_session_hdr", 22, 188, 280, 206, "Protecao de Sessao", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectSessionDesc, "Fusion_protect_session_desc", 22, 214, 520, 232, "Controla horario de operacao do EA no mercado.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectSessionEnabledLbl, "Fusion_protect_session_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectSessionEnabledBtn, "Fusion_protect_session_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectSessionStartLbl, "Fusion_protect_session_start_lbl", 22, 288, 160, 306, "Inicio", FUSION_CLR_LABEL))
         return false;
      if(!AddTimeEdit(m_protectSessionStartHourEdit, "Fusion_protect_session_start_h", 200, 286, "09"))
         return false;
      if(!AddTimeEdit(m_protectSessionStartMinuteEdit, "Fusion_protect_session_start_m", 246, 286, "00"))
         return false;
      if(!AddLabel(m_protectSessionEndLbl, "Fusion_protect_session_end_lbl", 22, 326, 160, 344, "Fim", FUSION_CLR_LABEL))
         return false;
      if(!AddTimeEdit(m_protectSessionEndHourEdit, "Fusion_protect_session_end_h", 200, 324, "17"))
         return false;
      if(!AddTimeEdit(m_protectSessionEndMinuteEdit, "Fusion_protect_session_end_m", 246, 324, "00"))
         return false;
      if(!AddLabel(m_protectSessionCloseLbl, "Fusion_protect_session_close_lbl", 22, 364, 180, 382, "Fechar no fim", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectSessionCloseBtn, "Fusion_protect_session_close_btn", 200, 362, 310, 386, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectSessionOvernightLbl, "Fusion_protect_session_overnight_lbl", 22, 402, 180, 420, "Overnight", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectSessionOvernightBtn, "Fusion_protect_session_overnight_btn", 200, 400, 310, 424, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectSessionFoot1, "Fusion_protect_session_foot_1", 22, 456, 520, 474, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectSessionFoot2, "Fusion_protect_session_foot_2", 22, 480, 520, 498, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectSessionFoot3, "Fusion_protect_session_foot_3", 22, 504, 520, 522, "", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_protectNewsHdr, "Fusion_protect_news_hdr", 22, 188, 280, 206, "Janelas de News", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectNewsDesc, "Fusion_protect_news_desc", 22, 214, 520, 232, "Cada janela pode so bloquear entradas ou fechar posicoes abertas.", FUSION_CLR_MUTED, 8))
         return false;
      int newsY = 248;
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         string suffix = IntegerToString(newsIndex + 1);
         if(!AddLabel(m_protectNewsBlockHdr[newsIndex], "Fusion_protect_news_hdr_" + suffix, 22, newsY, 220, newsY + 18, "Janela " + suffix, FUSION_CLR_TITLE, 9))
            return false;
         if(!AddLabel(m_protectNewsEnabledLbl[newsIndex], "Fusion_protect_news_enabled_lbl_" + suffix, 22, newsY + 26, 110, newsY + 44, "Ativo", FUSION_CLR_LABEL))
            return false;
         if(!AddButton(m_protectNewsEnabledBtn[newsIndex], "Fusion_protect_news_enabled_btn_" + suffix, 110, newsY + 24, 190, newsY + 48, "OFF", FUSION_CLR_BAD))
            return false;
         if(!AddLabel(m_protectNewsStartLbl[newsIndex], "Fusion_protect_news_start_lbl_" + suffix, 206, newsY + 26, 250, newsY + 44, "Inicio", FUSION_CLR_LABEL))
            return false;
         if(!AddTimeEdit(m_protectNewsStartHourEdit[newsIndex], "Fusion_protect_news_start_h_" + suffix, 256, newsY + 24, "00"))
            return false;
         if(!AddTimeEdit(m_protectNewsStartMinuteEdit[newsIndex], "Fusion_protect_news_start_m_" + suffix, 302, newsY + 24, "00"))
            return false;
         if(!AddLabel(m_protectNewsEndLbl[newsIndex], "Fusion_protect_news_end_lbl_" + suffix, 358, newsY + 26, 390, newsY + 44, "Fim", FUSION_CLR_LABEL))
            return false;
         if(!AddTimeEdit(m_protectNewsEndHourEdit[newsIndex], "Fusion_protect_news_end_h_" + suffix, 394, newsY + 24, "00"))
            return false;
         if(!AddTimeEdit(m_protectNewsEndMinuteEdit[newsIndex], "Fusion_protect_news_end_m_" + suffix, 440, newsY + 24, "00"))
            return false;
         if(!AddLabel(m_protectNewsModeLbl[newsIndex], "Fusion_protect_news_mode_lbl_" + suffix, 22, newsY + 58, 160, newsY + 76, "Modo", FUSION_CLR_LABEL))
            return false;
         if(!AddButton(m_protectNewsModeBtn[newsIndex], "Fusion_protect_news_mode_btn_" + suffix, 110, newsY + 56, 250, newsY + 80, "BLOQUEAR", FUSION_CLR_ACTION_LOAD))
            return false;
         newsY += 106;
        }

      if(!AddLabel(m_protectDayHdr, "Fusion_protect_day_hdr", 22, 188, 280, 206, "Limites Diarios", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectDayDesc, "Fusion_protect_day_desc", 22, 214, 520, 232, "Controla trades, perda diaria e meta diaria de ganho.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDayEnabledLbl, "Fusion_protect_day_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectDayEnabledBtn, "Fusion_protect_day_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectDayTradesLbl, "Fusion_protect_day_trades_lbl", 22, 288, 180, 306, "Max Trades", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectDayTradesEdit, "Fusion_protect_day_trades_edit", 200, 286, 310, 310, "0"))
         return false;
      if(!AddLabel(m_protectDayLossLbl, "Fusion_protect_day_loss_lbl", 22, 326, 180, 344, "Max Perda", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectDayLossEdit, "Fusion_protect_day_loss_edit", 200, 324, 310, 348, "0.00"))
         return false;
      if(!AddLabel(m_protectDayGainLbl, "Fusion_protect_day_gain_lbl", 22, 364, 180, 382, "Max Ganho", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectDayGainEdit, "Fusion_protect_day_gain_edit", 200, 362, 310, 386, "0.00"))
         return false;
      if(!m_protectDayProfitAction.Create(GetPointer(this),
                                           m_chartId,
                                           m_subWindow,
                                           "Fusion_protect_day_action_",
                                           "Acao Ganho",
                                           FUSION_SELECTION_PROFIT_TARGET_ACTION,
                                           22, 402, 180, 420,
                                           200, 400, 330, 424))
         return false;
      if(!AddLabel(m_protectDayFoot1, "Fusion_protect_day_foot_1", 22, 448, 520, 466, "Campos em zero ficam sem limite.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDayFoot2, "Fusion_protect_day_foot_2", 22, 472, 520, 490, "ATIVAR DD exige DRAWDOWN ON com Max DD > 0.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDayFoot3, "Fusion_protect_day_foot_3", 22, 496, 520, 514, "Contadores e P/L bruto persistem e resetam no novo dia.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_protectDrawdownHdr, "Fusion_protect_dd_hdr", 22, 188, 280, 206, "Protecao de Drawdown (DD)", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectDrawdownDesc, "Fusion_protect_dd_desc", 22, 214, 520, 232, "Protege o lucro do dia depois que a meta diaria e atingida.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDrawdownEnabledLbl, "Fusion_protect_dd_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectDrawdownEnabledBtn, "Fusion_protect_dd_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectDrawdownValueLbl, "Fusion_protect_dd_value_lbl", 22, 288, 180, 306, "Max DD", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectDrawdownValueEdit, "Fusion_protect_dd_value_edit", 200, 286, 310, 310, "0.00"))
         return false;
      if(!m_protectDrawdownType.Create(GetPointer(this),
                                        m_chartId,
                                        m_subWindow,
                                        "Fusion_protect_dd_type_",
                                        "Tipo DD",
                                        FUSION_SELECTION_DRAWDOWN_TYPE,
                                        22, 326, 180, 344,
                                        200, 324, 330, 348))
         return false;
      if(!m_protectDrawdownPeakMode.Create(GetPointer(this),
                                            m_chartId,
                                            m_subWindow,
                                            "Fusion_protect_dd_peak_",
                                            "Base DD",
                                            FUSION_SELECTION_DRAWDOWN_PEAK_MODE,
                                            22, 364, 180, 382,
                                            200, 362, 330, 386))
         return false;
      if(!AddLabel(m_protectDrawdownPeakRuntimeLbl, "Fusion_protect_dd_runtime_peak_lbl", 22, 402, 180, 420, "Base atual", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(m_protectDrawdownPeakRuntimeValue, "Fusion_protect_dd_runtime_peak_value", 200, 402, 330, 420, "--", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDrawdownFloorLbl, "Fusion_protect_dd_floor_lbl", 22, 430, 180, 448, "Piso DD", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(m_protectDrawdownFloorValue, "Fusion_protect_dd_floor_value", 200, 430, 330, 448, "--", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDrawdownBufferLbl, "Fusion_protect_dd_buffer_lbl", 22, 458, 180, 476, "Folga DD", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(m_protectDrawdownBufferValue, "Fusion_protect_dd_buffer_value", 200, 458, 330, 476, "--", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDrawdownNote, "Fusion_protect_dd_note", 22, 492, 550, 510, "Requer DAY ON, Max Ganho > 0 e Acao ATIVAR DD.", FUSION_CLR_WARN, 8))
         return false;
      if(!AddLabel(m_protectDrawdownFoot2, "Fusion_protect_dd_foot_2", 22, 516, 550, 534, "Financeiro: valor; Percentual: % da base.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectDrawdownFoot3, "Fusion_protect_dd_foot_3", 22, 540, 550, 558, "Pico Ganho acompanha o maior P/L bruto projetado.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_protectStreakHdr, "Fusion_protect_streak_hdr", 22, 188, 280, 206, "Protecao de Streak", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectStreakDesc, "Fusion_protect_streak_desc", 22, 214, 520, 232, "Bloqueia novas entradas apos sequencias configuradas.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectStreakLossHdr, "Fusion_protect_streak_loss_hdr", 22, 250, 180, 268, "Loss Streak", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectStreakLossEnabledLbl, "Fusion_protect_streak_loss_enabled_lbl", 22, 282, 100, 300, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectStreakLossEnabledBtn, "Fusion_protect_streak_loss_enabled_btn", 112, 280, 202, 304, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectStreakLossLbl, "Fusion_protect_streak_loss_lbl", 22, 320, 100, 338, "Max Loss", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakLossEdit, "Fusion_protect_streak_loss_edit", 112, 318, 202, 342, "0"))
         return false;
      if(!m_protectStreakLossAction.Create(GetPointer(this),
                                           m_chartId,
                                           m_subWindow,
                                           "Fusion_protect_streak_loss_action",
                                           "Acao",
                                           FUSION_SELECTION_STREAK_ACTION,
                                           22,
                                           358,
                                           100,
                                           376,
                                           112,
                                           356,
                                           202,
                                           380))
         return false;
      if(!AddLabel(m_protectStreakLossPauseMinutesLbl, "Fusion_protect_streak_loss_pause_min_lbl", 22, 396, 100, 414, "Pausa min", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakLossPauseMinutesEdit, "Fusion_protect_streak_loss_pause_min_edit", 112, 394, 202, 418, "30"))
         return false;

      if(!AddLabel(m_protectStreakWinHdr, "Fusion_protect_streak_win_hdr", 298, 250, 456, 268, "Win Streak", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectStreakWinEnabledLbl, "Fusion_protect_streak_win_enabled_lbl", 298, 282, 376, 300, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectStreakWinEnabledBtn, "Fusion_protect_streak_win_enabled_btn", 388, 280, 478, 304, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectStreakWinLbl, "Fusion_protect_streak_win_lbl", 298, 320, 376, 338, "Max Win", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakWinEdit, "Fusion_protect_streak_win_edit", 388, 318, 478, 342, "0"))
         return false;
      if(!m_protectStreakWinAction.Create(GetPointer(this),
                                          m_chartId,
                                          m_subWindow,
                                          "Fusion_protect_streak_win_action",
                                          "Acao",
                                          FUSION_SELECTION_STREAK_ACTION,
                                          298,
                                          358,
                                          376,
                                          376,
                                          388,
                                          356,
                                          478,
                                          380))
         return false;
      if(!AddLabel(m_protectStreakWinPauseMinutesLbl, "Fusion_protect_streak_win_pause_min_lbl", 298, 396, 376, 414, "Pausa min", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakWinPauseMinutesEdit, "Fusion_protect_streak_win_pause_min_edit", 388, 394, 478, 418, "30"))
         return false;
      if(!AddLabel(m_protectStreakFoot1, "Fusion_protect_streak_foot_1", 22, 462, 520, 480, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectStreakFoot2, "Fusion_protect_streak_foot_2", 22, 486, 520, 504, "", FUSION_CLR_MUTED, 8))
         return false;

      return true;
     }

#endif
