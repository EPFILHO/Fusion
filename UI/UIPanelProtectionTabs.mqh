   ENUM_FUSION_PROTECT_PAGE   m_protectPage;
   CButton                    m_protectTabs[FUSION_PROTECT_COUNT];
   bool                       m_protectPageValid[FUSION_PROTECT_COUNT];
   string                     m_protectPageError[FUSION_PROTECT_COUNT];
   CPanel                     m_protectTabsSeparator;
   CPanel                     m_protectContentFrame;

   CLabel                     m_protectGeneralHdr;
   CLabel                     m_protectGeneralLabels[6];
   CLabel                     m_protectGeneralValues[6];

   CLabel                     m_protectSpreadHdr;
   CLabel                     m_protectSpreadDesc;
   CLabel                     m_protectSpreadEnabledLbl;
   CButton                    m_protectSpreadEnabledBtn;
   CLabel                     m_protectSpreadLimitLbl;
   CEdit                      m_protectSpreadLimitEdit;

   CLabel                     m_protectSessionHdr;
   CLabel                     m_protectSessionDesc;
   CLabel                     m_protectSessionEnabledLbl;
   CButton                    m_protectSessionEnabledBtn;
   CLabel                     m_protectSessionStartLbl;
   CEdit                      m_protectSessionStartHourEdit;
   CEdit                      m_protectSessionStartMinuteEdit;
   CLabel                     m_protectSessionEndLbl;
   CEdit                      m_protectSessionEndHourEdit;
   CEdit                      m_protectSessionEndMinuteEdit;
   CLabel                     m_protectSessionCloseLbl;
   CButton                    m_protectSessionCloseBtn;

   CLabel                     m_protectNewsHdr;
   CLabel                     m_protectNewsDesc;
   CLabel                     m_protectNewsBlockHdr[3];
   CLabel                     m_protectNewsEnabledLbl[3];
   CButton                    m_protectNewsEnabledBtn[3];
   CLabel                     m_protectNewsStartLbl[3];
   CEdit                      m_protectNewsStartHourEdit[3];
   CEdit                      m_protectNewsStartMinuteEdit[3];
   CLabel                     m_protectNewsEndLbl[3];
   CEdit                      m_protectNewsEndHourEdit[3];
   CEdit                      m_protectNewsEndMinuteEdit[3];
   CLabel                     m_protectNewsModeLbl[3];
   CButton                    m_protectNewsModeBtn[3];

   CLabel                     m_protectDayHdr;
   CLabel                     m_protectDayDesc;
   CLabel                     m_protectDayEnabledLbl;
   CButton                    m_protectDayEnabledBtn;
   CLabel                     m_protectDayTradesLbl;
   CEdit                      m_protectDayTradesEdit;
   CLabel                     m_protectDayLossLbl;
   CEdit                      m_protectDayLossEdit;
   CLabel                     m_protectDayGainLbl;
   CEdit                      m_protectDayGainEdit;

   CLabel                     m_protectDrawdownHdr;
   CLabel                     m_protectDrawdownDesc;
   CLabel                     m_protectDrawdownEnabledLbl;
   CButton                    m_protectDrawdownEnabledBtn;
   CLabel                     m_protectDrawdownValueLbl;
   CEdit                      m_protectDrawdownValueEdit;
   CLabel                     m_protectDrawdownNote;

   CLabel                     m_protectStreakHdr;
   CLabel                     m_protectStreakDesc;
   CLabel                     m_protectStreakEnabledLbl;
   CButton                    m_protectStreakEnabledBtn;
   CLabel                     m_protectStreakLossLbl;
   CEdit                      m_protectStreakLossEdit;
   CLabel                     m_protectStreakWinLbl;
   CEdit                      m_protectStreakWinEdit;

   string                     ProtectNewsActionText(const ENUM_NEWS_WINDOW_ACTION action) const
     {
      return (action == NEWS_ACTION_CLOSE_AND_BLOCK) ? "FECHA+BLQ" : "BLOQUEAR";
     }

   void                       ApplyProtectModeButtonStyle(CButton &button,const ENUM_NEWS_WINDOW_ACTION action,const bool editable)
     {
      button.Text(ProtectNewsActionText(action));
      if(!editable)
         FusionApplyNeutralButtonStyle(button);
      else
         FusionApplyActionButtonStyle(button, action == NEWS_ACTION_CLOSE_AND_BLOCK ? FUSION_CLR_WARN : FUSION_CLR_ACTION_LOAD, true);
     }
   bool                       ProtectSubtabHasError(const ENUM_FUSION_PROTECT_PAGE page) const
     {
      if(page == FUSION_PROTECT_GENERAL)
         return false;
      return !m_protectPageValid[(int)page];
     }

   string                     ProtectSubtabError(const ENUM_FUSION_PROTECT_PAGE page) const
     {
      return m_protectPageError[(int)page];
     }

   void                       ApplyProtectionTabStyles(void)
     {
      for(int tabIndex = 0; tabIndex < FUSION_PROTECT_COUNT; ++tabIndex)
        {
         if(tabIndex == (int)m_protectPage)
            FusionApplyPrimaryButtonStyle(m_protectTabs[tabIndex], true);
         else if(ProtectSubtabHasError((ENUM_FUSION_PROTECT_PAGE)tabIndex))
            FusionApplyActionButtonStyle(m_protectTabs[tabIndex], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_protectTabs[tabIndex], false);
        }
     }

#include "UIPanelProtectionInputs.mqh"
#include "UIPanelProtectionValidation.mqh"

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

   void                       SetProtectionControlsVisible(const ENUM_FUSION_PROTECT_PAGE page,const bool visible)
     {
      bool showGeneral = visible && page == FUSION_PROTECT_GENERAL;
      SetVisible(m_protectTabsSeparator, visible);
      SetVisible(m_protectContentFrame, visible);
      SetVisible(m_protectGeneralHdr, showGeneral);
      for(int generalIndex = 0; generalIndex < 6; ++generalIndex)
        {
         SetVisible(m_protectGeneralLabels[generalIndex], showGeneral);
         SetVisible(m_protectGeneralValues[generalIndex], showGeneral);
        }

      bool showSpread = visible && page == FUSION_PROTECT_SPREAD;
      SetVisible(m_protectSpreadHdr, showSpread);
      SetVisible(m_protectSpreadDesc, showSpread);
      SetVisible(m_protectSpreadEnabledLbl, showSpread);
      SetVisible(m_protectSpreadEnabledBtn, showSpread);
      SetVisible(m_protectSpreadLimitLbl, showSpread);
      SetVisible(m_protectSpreadLimitEdit, showSpread);

      bool showSession = visible && page == FUSION_PROTECT_SESSION;
      SetVisible(m_protectSessionHdr, showSession);
      SetVisible(m_protectSessionDesc, showSession);
      SetVisible(m_protectSessionEnabledLbl, showSession);
      SetVisible(m_protectSessionEnabledBtn, showSession);
      SetVisible(m_protectSessionStartLbl, showSession);
      SetVisible(m_protectSessionStartHourEdit, showSession);
      SetVisible(m_protectSessionStartMinuteEdit, showSession);
      SetVisible(m_protectSessionEndLbl, showSession);
      SetVisible(m_protectSessionEndHourEdit, showSession);
      SetVisible(m_protectSessionEndMinuteEdit, showSession);
      SetVisible(m_protectSessionCloseLbl, showSession);
      SetVisible(m_protectSessionCloseBtn, showSession);

      bool showNews = visible && page == FUSION_PROTECT_NEWS;
      SetVisible(m_protectNewsHdr, showNews);
      SetVisible(m_protectNewsDesc, showNews);
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         SetVisible(m_protectNewsBlockHdr[newsIndex], showNews);
         SetVisible(m_protectNewsEnabledLbl[newsIndex], showNews);
         SetVisible(m_protectNewsEnabledBtn[newsIndex], showNews);
         SetVisible(m_protectNewsStartLbl[newsIndex], showNews);
         SetVisible(m_protectNewsStartHourEdit[newsIndex], showNews);
         SetVisible(m_protectNewsStartMinuteEdit[newsIndex], showNews);
         SetVisible(m_protectNewsEndLbl[newsIndex], showNews);
         SetVisible(m_protectNewsEndHourEdit[newsIndex], showNews);
         SetVisible(m_protectNewsEndMinuteEdit[newsIndex], showNews);
         SetVisible(m_protectNewsModeLbl[newsIndex], showNews);
         SetVisible(m_protectNewsModeBtn[newsIndex], showNews);
        }

      bool showDay = visible && page == FUSION_PROTECT_DAY;
      SetVisible(m_protectDayHdr, showDay);
      SetVisible(m_protectDayDesc, showDay);
      SetVisible(m_protectDayEnabledLbl, showDay);
      SetVisible(m_protectDayEnabledBtn, showDay);
      SetVisible(m_protectDayTradesLbl, showDay);
      SetVisible(m_protectDayTradesEdit, showDay);
      SetVisible(m_protectDayLossLbl, showDay);
      SetVisible(m_protectDayLossEdit, showDay);
      SetVisible(m_protectDayGainLbl, showDay);
      SetVisible(m_protectDayGainEdit, showDay);

      bool showDrawdown = visible && page == FUSION_PROTECT_DRAWDOWN;
      SetVisible(m_protectDrawdownHdr, showDrawdown);
      SetVisible(m_protectDrawdownDesc, showDrawdown);
      SetVisible(m_protectDrawdownEnabledLbl, showDrawdown);
      SetVisible(m_protectDrawdownEnabledBtn, showDrawdown);
      SetVisible(m_protectDrawdownValueLbl, showDrawdown);
      SetVisible(m_protectDrawdownValueEdit, showDrawdown);
      SetVisible(m_protectDrawdownNote, showDrawdown);

      bool showStreak = visible && page == FUSION_PROTECT_STREAK;
      SetVisible(m_protectStreakHdr, showStreak);
      SetVisible(m_protectStreakDesc, showStreak);
      SetVisible(m_protectStreakEnabledLbl, showStreak);
      SetVisible(m_protectStreakEnabledBtn, showStreak);
      SetVisible(m_protectStreakLossLbl, showStreak);
      SetVisible(m_protectStreakLossEdit, showStreak);
      SetVisible(m_protectStreakWinLbl, showStreak);
      SetVisible(m_protectStreakWinEdit, showStreak);
     }

   void                       SyncProtectionOverview(void)
     {
      m_protectGeneralValues[0].Text(!m_draftSettings.enableSpreadProtection ? "OFF" : "Max " + IntegerToString(m_draftSettings.maxSpreadPoints) + " pts");
      m_protectGeneralValues[1].Text(!m_draftSettings.enableSessionFilter ? "OFF" :
                                     StringFormat("%02d:%02d - %02d:%02d",
                                                  m_draftSettings.sessionStartHour,
                                                  m_draftSettings.sessionStartMinute,
                                                  m_draftSettings.sessionEndHour,
                                                  m_draftSettings.sessionEndMinute));

      int newsEnabled = 0;
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
         if(m_draftSettings.newsWindows[newsIndex].enabled)
            newsEnabled++;
      m_protectGeneralValues[2].Text(IntegerToString(newsEnabled) + "/3 janelas ativas");
      m_protectGeneralValues[3].Text(StringFormat("Trades %d | P/L %.2f", m_snapshot.dailyTradeCount, m_snapshot.dailyClosedProfit));
      m_protectGeneralValues[4].Text(!m_draftSettings.enableDrawdown ? "OFF" :
                                     (m_snapshot.drawdownProtectionActive ? "ATIVO" : "Aguardando meta"));
      m_protectGeneralValues[5].Text(StringFormat("Loss %d | Win %d", m_snapshot.lossStreak, m_snapshot.winStreak));
     }

   void                       RefreshProtectionTheme(void)
     {
      bool editable = CanEditActiveProfile();

      ApplyProtectionTabStyles();

      SyncProtectionOverview();

      FusionApplyToggleButtonStyle(m_protectSpreadEnabledBtn, m_draftSettings.enableSpreadProtection, editable);
      FusionApplyToggleButtonStyle(m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter, editable);
      FusionApplyToggleButtonStyle(m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd, editable);

      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         FusionApplyToggleButtonStyle(m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled, editable);
         ApplyProtectModeButtonStyle(m_protectNewsModeBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].action, editable);
        }

      FusionApplyToggleButtonStyle(m_protectDayEnabledBtn, m_draftSettings.enableDailyLimits, editable);
      FusionApplyToggleButtonStyle(m_protectDrawdownEnabledBtn, m_draftSettings.enableDrawdown, editable);
      FusionApplyToggleButtonStyle(m_protectStreakEnabledBtn, m_draftSettings.enableStreak, editable);
     }

   void                       SyncProtectionControls(void)
     {
      RefreshProtectionTheme();
      FusionApplyEditStyle(m_protectSpreadLimitEdit, true, CanEditActiveProfile());
      m_protectSpreadLimitEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_protectSessionStartHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartHour));
      m_protectSessionStartMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartMinute));
      m_protectSessionEndHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndHour));
      m_protectSessionEndMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndMinute));
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         m_protectNewsStartHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startHour));
         m_protectNewsStartMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startMinute));
         m_protectNewsEndHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endHour));
         m_protectNewsEndMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endMinute));
        }
      m_protectDayTradesEdit.Text(IntegerToString(m_draftSettings.maxDailyTrades));
      m_protectDayLossEdit.Text(DoubleToString(m_draftSettings.maxDailyLoss, 2));
      m_protectDayGainEdit.Text(DoubleToString(m_draftSettings.maxDailyGain, 2));
      m_protectDrawdownValueEdit.Text(DoubleToString(m_draftSettings.maxDrawdown, 2));
      m_protectStreakLossEdit.Text(IntegerToString(m_draftSettings.maxLossStreak));
      m_protectStreakWinEdit.Text(IntegerToString(m_draftSettings.maxWinStreak));
     }

   bool                       EnsureConfigProtectionPageCreated(void)
     {
      if(m_configProtectionCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configProtectionGroup);
      if(!BuildConfigProtectionPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configProtectionCreated = true;
      SetProtectionControlsVisible(m_protectPage, false);
      SyncProtectionControls();
      return true;
     }

   bool                       HandleProtectionBooleanToggle(const string objectName,CButton &button,bool &target)
     {
      if(objectName != button.Name())
         return false;

      ReleaseButton(button);
      if(!CanEditActiveProfile())
         return true;

      target = !target;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionNewsModeToggle(const string objectName,const int newsIndex)
     {
      if(objectName != m_protectNewsModeBtn[newsIndex].Name())
         return false;

      ReleaseButton(m_protectNewsModeBtn[newsIndex]);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.newsWindows[newsIndex].action =
         (m_draftSettings.newsWindows[newsIndex].action == NEWS_ACTION_BLOCK_ENTRIES)
         ? NEWS_ACTION_CLOSE_AND_BLOCK
         : NEWS_ACTION_BLOCK_ENTRIES;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionClick(const string objectName)
     {
      if(!m_configProtectionCreated)
         return false;

      for(int tabIndex = 0; tabIndex < FUSION_PROTECT_COUNT; ++tabIndex)
        {
         if(objectName != m_protectTabs[tabIndex].Name())
            continue;

         ReleaseButton(m_protectTabs[tabIndex]);
         ResetDialogMouseRouting();
         m_protectPage = (ENUM_FUSION_PROTECT_PAGE)tabIndex;
         ApplyVisibility(false);
         RefreshConfigValidation();
         return true;
        }

      if(HandleProtectionBooleanToggle(objectName, m_protectSpreadEnabledBtn, m_draftSettings.enableSpreadProtection))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectDayEnabledBtn, m_draftSettings.enableDailyLimits))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectDrawdownEnabledBtn, m_draftSettings.enableDrawdown))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectStreakEnabledBtn, m_draftSettings.enableStreak))
         return true;

      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(HandleProtectionBooleanToggle(objectName, m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled))
            return true;

         if(HandleProtectionNewsModeToggle(objectName, newsIndex))
            return true;
        }

      return false;
     }
