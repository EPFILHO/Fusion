#ifndef __FUSION_UI_PANEL_PROTECTION_BUILD_MQH__
#define __FUSION_UI_PANEL_PROTECTION_BUILD_MQH__

   bool                       BuildConfigProtectionPage(void)
     {
      string pageNames[FUSION_PROTECT_COUNT] = {"GERAL", "SPREAD", "SESSION", "NEWS", "DAY", "DRAWDOWN", "STREAK"};
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
      string generalLabels[6] = {"Spread", "Session", "News", "Day", "Drawdown", "Streak"};
      int generalY = 226;
      for(int generalIndex = 0; generalIndex < 6; ++generalIndex)
        {
         if(!AddLabel(m_protectGeneralLabels[generalIndex], "Fusion_protect_general_lbl_" + IntegerToString(generalIndex), 22, generalY, 170, generalY + 18, generalLabels[generalIndex], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_protectGeneralValues[generalIndex], "Fusion_protect_general_val_" + IntegerToString(generalIndex), 190, generalY, 520, generalY + 18, "--", FUSION_CLR_VALUE))
            return false;
         generalY += 32;
        }

      if(!AddLabel(m_protectSpreadHdr, "Fusion_protect_spread_hdr", 22, 188, 280, 206, "Protecao de Spread", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectSpreadDesc, "Fusion_protect_spread_desc", 22, 214, 520, 232, "Bloqueia novas entradas quando o spread passar do limite.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectSpreadEnabledLbl, "Fusion_protect_spread_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectSpreadEnabledBtn, "Fusion_protect_spread_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectSpreadLimitLbl, "Fusion_protect_spread_limit_lbl", 22, 288, 170, 306, "Max Spread", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectSpreadLimitEdit, "Fusion_protect_spread_limit_edit", 200, 286, 310, 310, "0"))
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

      if(!AddLabel(m_protectNewsHdr, "Fusion_protect_news_hdr", 22, 188, 280, 206, "Janelas de News", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectNewsDesc, "Fusion_protect_news_desc", 22, 214, 520, 232, "Cada janela pode so bloquear entradas ou fechar posicoes abertas.", FUSION_CLR_MUTED, 8))
         return false;
      int newsY = 248;
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
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

      if(!AddLabel(m_protectDrawdownHdr, "Fusion_protect_dd_hdr", 22, 188, 280, 206, "Protecao de Drawdown", FUSION_CLR_VALUE, 9))
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
      if(!AddLabel(m_protectDrawdownNote, "Fusion_protect_dd_note", 22, 330, 520, 366, "Requer DAY ativo com Max Ganho > 0.", FUSION_CLR_WARN, 8))
         return false;

      if(!AddLabel(m_protectStreakHdr, "Fusion_protect_streak_hdr", 22, 188, 280, 206, "Protecao de Streak", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_protectStreakDesc, "Fusion_protect_streak_desc", 22, 214, 520, 232, "Bloqueia novas entradas apos sequencias configuradas.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_protectStreakEnabledLbl, "Fusion_protect_streak_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_protectStreakEnabledBtn, "Fusion_protect_streak_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_protectStreakLossLbl, "Fusion_protect_streak_loss_lbl", 22, 288, 180, 306, "Max Loss", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakLossEdit, "Fusion_protect_streak_loss_edit", 200, 286, 310, 310, "0"))
         return false;
      if(!AddLabel(m_protectStreakWinLbl, "Fusion_protect_streak_win_lbl", 22, 326, 180, 344, "Max Win", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_protectStreakWinEdit, "Fusion_protect_streak_win_edit", 200, 324, 310, 348, "0"))
         return false;

      return true;
     }

#endif
