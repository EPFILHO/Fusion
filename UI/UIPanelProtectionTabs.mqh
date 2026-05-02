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

   bool                       AddTimeEdit(CEdit &edit,const string name,const int x1,const int y1,const string value)
     {
      if(!AddEdit(edit, name, x1, y1, x1 + 40, y1 + 24, value))
         return false;
      edit.TextAlign(ALIGN_CENTER);
      return true;
     }

   bool                       IsTimeEditObject(const string objectName,int &maxValue)
     {
      maxValue = -1;
      if(m_configProtectionCreated)
        {
         if(objectName == m_protectSessionStartHourEdit.Name() ||
            objectName == m_protectSessionEndHourEdit.Name())
           {
            maxValue = 23;
            return true;
           }
         if(objectName == m_protectSessionStartMinuteEdit.Name() ||
            objectName == m_protectSessionEndMinuteEdit.Name())
           {
            maxValue = 59;
            return true;
           }

         for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
           {
            if(objectName == m_protectNewsStartHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndHourEdit[newsIndex].Name())
              {
               maxValue = 23;
               return true;
              }
            if(objectName == m_protectNewsStartMinuteEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
              {
               maxValue = 59;
               return true;
              }
           }
        }

      return false;
     }

   string                     SanitizeTimeText(const string text,const int maxValue) const
     {
      string digits = "";
      string trimmed = FusionTrimCopy(text);
      for(int i = 0; i < StringLen(trimmed); ++i)
        {
         ushort ch = StringGetCharacter(trimmed, i);
         if(ch >= '0' && ch <= '9')
            digits += StringSubstr(trimmed, i, 1);
        }

      int value = 0;
      if(digits != "")
         value = (int)StringToInteger(digits);
      if(value < 0)
         value = 0;
      if(value > maxValue)
         value = maxValue;

      return StringFormat("%02d", value);
     }

   void                       NormalizeTimeEdit(CEdit &edit,const int maxValue)
     {
      edit.Text(SanitizeTimeText(LiveEditText(edit), maxValue));
     }

   bool                       ProtectionTimeValue(const string text,const int maxValue,int &parsed) const
     {
      parsed = 0;
      if(!FusionIsIntegerText(text, true))
         return false;
      parsed = (int)StringToInteger(text);
      return (parsed >= 0 && parsed <= maxValue);
     }

   bool                       ProtectionMoneyValue(const string text,const bool allowZero,double &parsed) const
     {
      parsed = 0.0;
      if(!FusionIsDecimalText(text, allowZero))
         return false;
      parsed = StringToDouble(FusionNormalizeDecimalText(text));
      if(!allowZero && parsed <= 0.0)
         return false;
      return (parsed >= 0.0);
     }

   bool                       IsProtectionDeferredEdit(const string objectName)
     {
      if(m_configProtectionCreated)
        {
         if(objectName == m_protectSpreadLimitEdit.Name() ||
            objectName == m_protectSessionStartHourEdit.Name() ||
            objectName == m_protectSessionStartMinuteEdit.Name() ||
            objectName == m_protectSessionEndHourEdit.Name() ||
            objectName == m_protectSessionEndMinuteEdit.Name() ||
            objectName == m_protectDayTradesEdit.Name() ||
            objectName == m_protectDayLossEdit.Name() ||
            objectName == m_protectDayGainEdit.Name() ||
            objectName == m_protectDrawdownValueEdit.Name() ||
            objectName == m_protectStreakLossEdit.Name() ||
            objectName == m_protectStreakWinEdit.Name())
            return true;

         for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
           {
            if(objectName == m_protectNewsStartHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsStartMinuteEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
               return true;
           }
        }
      return false;
     }

   bool                       ProtectionIntegerEditPending(CEdit &edit,const int committedValue,const bool timeFormat=false)
     {
      string text = FusionTrimCopy(LiveEditText(edit));
      if(FusionIsIntegerText(text, true))
         return ((int)StringToInteger(text) != committedValue);

      string committedText = timeFormat ? StringFormat("%02d", committedValue) : IntegerToString(committedValue);
      return (text != committedText);
     }

   bool                       ProtectionMoneyEditPending(CEdit &edit,const double committedValue)
     {
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      if(FusionIsDecimalText(text, true))
         return (MathAbs(StringToDouble(text) - committedValue) > 0.0000001);

      return (text != FusionNormalizeDecimalText(DoubleToString(committedValue, 2)));
     }

   bool                       HasProtectionPendingChanges(void)
     {
      if(!m_configProtectionCreated)
         return false;

      if(ProtectionIntegerEditPending(m_protectSpreadLimitEdit, m_committedSettings.maxSpreadPoints))
         return true;
      if(ProtectionIntegerEditPending(m_protectSessionStartHourEdit, m_committedSettings.sessionStartHour, true))
         return true;
      if(ProtectionIntegerEditPending(m_protectSessionStartMinuteEdit, m_committedSettings.sessionStartMinute, true))
         return true;
      if(ProtectionIntegerEditPending(m_protectSessionEndHourEdit, m_committedSettings.sessionEndHour, true))
         return true;
      if(ProtectionIntegerEditPending(m_protectSessionEndMinuteEdit, m_committedSettings.sessionEndMinute, true))
         return true;

      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(ProtectionIntegerEditPending(m_protectNewsStartHourEdit[newsIndex], m_committedSettings.newsWindows[newsIndex].startHour, true))
            return true;
         if(ProtectionIntegerEditPending(m_protectNewsStartMinuteEdit[newsIndex], m_committedSettings.newsWindows[newsIndex].startMinute, true))
            return true;
         if(ProtectionIntegerEditPending(m_protectNewsEndHourEdit[newsIndex], m_committedSettings.newsWindows[newsIndex].endHour, true))
            return true;
         if(ProtectionIntegerEditPending(m_protectNewsEndMinuteEdit[newsIndex], m_committedSettings.newsWindows[newsIndex].endMinute, true))
            return true;
        }

      if(ProtectionIntegerEditPending(m_protectDayTradesEdit, m_committedSettings.maxDailyTrades))
         return true;
      if(ProtectionMoneyEditPending(m_protectDayLossEdit, m_committedSettings.maxDailyLoss))
         return true;
      if(ProtectionMoneyEditPending(m_protectDayGainEdit, m_committedSettings.maxDailyGain))
         return true;
      if(ProtectionMoneyEditPending(m_protectDrawdownValueEdit, m_committedSettings.maxDrawdown))
         return true;
      if(ProtectionIntegerEditPending(m_protectStreakLossEdit, m_committedSettings.maxLossStreak))
         return true;
      if(ProtectionIntegerEditPending(m_protectStreakWinEdit, m_committedSettings.maxWinStreak))
         return true;

      return false;
     }

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

      if(objectName == m_protectSpreadEnabledBtn.Name())
        {
         ReleaseButton(m_protectSpreadEnabledBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.enableSpreadProtection = !m_draftSettings.enableSpreadProtection;
         RefreshConfigValidation();
         return true;
        }

      if(objectName == m_protectSessionEnabledBtn.Name())
        {
         ReleaseButton(m_protectSessionEnabledBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.enableSessionFilter = !m_draftSettings.enableSessionFilter;
         RefreshConfigValidation();
         return true;
        }

      if(objectName == m_protectSessionCloseBtn.Name())
        {
         ReleaseButton(m_protectSessionCloseBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.closeOnSessionEnd = !m_draftSettings.closeOnSessionEnd;
         RefreshConfigValidation();
         return true;
        }

      if(objectName == m_protectDayEnabledBtn.Name())
        {
         ReleaseButton(m_protectDayEnabledBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.enableDailyLimits = !m_draftSettings.enableDailyLimits;
         RefreshConfigValidation();
         return true;
        }

      if(objectName == m_protectDrawdownEnabledBtn.Name())
        {
         ReleaseButton(m_protectDrawdownEnabledBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.enableDrawdown = !m_draftSettings.enableDrawdown;
         RefreshConfigValidation();
         return true;
        }

      if(objectName == m_protectStreakEnabledBtn.Name())
        {
         ReleaseButton(m_protectStreakEnabledBtn);
         if(!CanEditActiveProfile())
            return true;
         m_draftSettings.enableStreak = !m_draftSettings.enableStreak;
         RefreshConfigValidation();
         return true;
        }

      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(objectName == m_protectNewsEnabledBtn[newsIndex].Name())
           {
            ReleaseButton(m_protectNewsEnabledBtn[newsIndex]);
            if(!CanEditActiveProfile())
               return true;
            m_draftSettings.newsWindows[newsIndex].enabled = !m_draftSettings.newsWindows[newsIndex].enabled;
            RefreshConfigValidation();
            return true;
           }

         if(objectName == m_protectNewsModeBtn[newsIndex].Name())
           {
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
        }

      return false;
     }

   bool                       NormalizeProtectionDeferredEdit(const string objectName)
     {
      if(!m_configProtectionCreated)
         return false;

      int maxValue = -1;
      if(!IsTimeEditObject(objectName, maxValue))
         return false;

      if(objectName == m_protectSessionStartHourEdit.Name())
         NormalizeTimeEdit(m_protectSessionStartHourEdit, maxValue);
      else if(objectName == m_protectSessionStartMinuteEdit.Name())
         NormalizeTimeEdit(m_protectSessionStartMinuteEdit, maxValue);
      else if(objectName == m_protectSessionEndHourEdit.Name())
         NormalizeTimeEdit(m_protectSessionEndHourEdit, maxValue);
      else if(objectName == m_protectSessionEndMinuteEdit.Name())
         NormalizeTimeEdit(m_protectSessionEndMinuteEdit, maxValue);
      else
        {
         for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
           {
            if(objectName == m_protectNewsStartHourEdit[newsIndex].Name())
               NormalizeTimeEdit(m_protectNewsStartHourEdit[newsIndex], maxValue);
            else if(objectName == m_protectNewsStartMinuteEdit[newsIndex].Name())
               NormalizeTimeEdit(m_protectNewsStartMinuteEdit[newsIndex], maxValue);
            else if(objectName == m_protectNewsEndHourEdit[newsIndex].Name())
               NormalizeTimeEdit(m_protectNewsEndHourEdit[newsIndex], maxValue);
            else if(objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
               NormalizeTimeEdit(m_protectNewsEndMinuteEdit[newsIndex], maxValue);
            else
               continue;
            return true;
           }
         return false;
        }

      return true;
     }

   bool                       ValidateProtectionSettings(SEASettings &outSettings,const bool editable,string &error)
     {
      error = "";

      string spreadText = FusionTrimCopy(LiveEditText(m_protectSpreadLimitEdit));
      bool spreadValid = FusionIsIntegerText(spreadText, true) && (int)StringToInteger(spreadText) >= 0;
      int parsedSpread = spreadValid ? (int)StringToInteger(spreadText) : 0;
      if(spreadValid && outSettings.enableSpreadProtection && parsedSpread <= 0)
         spreadValid = false;
      FusionApplyEditStyle(m_protectSpreadLimitEdit, spreadValid, editable);
      m_protectSpreadLimitLbl.Color(!editable ? FUSION_CLR_MUTED : (spreadValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      string spreadError = "";
      if(!spreadValid)
         spreadError = outSettings.enableSpreadProtection ? "Max Spread deve ser > 0 quando ativo." : "Max Spread deve ser zero ou inteiro positivo.";
      outSettings.maxSpreadPoints = parsedSpread;

      int sessionStartHour = 0, sessionStartMinute = 0, sessionEndHour = 0, sessionEndMinute = 0;
      bool sessionStartHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectSessionStartHourEdit)), 23, sessionStartHour);
      bool sessionStartMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectSessionStartMinuteEdit)), 59, sessionStartMinute);
      bool sessionEndHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectSessionEndHourEdit)), 23, sessionEndHour);
      bool sessionEndMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectSessionEndMinuteEdit)), 59, sessionEndMinute);
      bool sessionOrderValid = true;
      if(sessionStartHourValid && sessionStartMinuteValid && sessionEndHourValid && sessionEndMinuteValid)
        {
         int sessionStartTotal = sessionStartHour * 60 + sessionStartMinute;
         int sessionEndTotal = sessionEndHour * 60 + sessionEndMinute;
         sessionOrderValid = (sessionEndTotal > sessionStartTotal);
        }
      bool sessionFieldsValid = sessionStartHourValid && sessionStartMinuteValid && sessionEndHourValid && sessionEndMinuteValid && sessionOrderValid;
      FusionApplyEditStyle(m_protectSessionStartHourEdit, sessionFieldsValid, editable);
      FusionApplyEditStyle(m_protectSessionStartMinuteEdit, sessionFieldsValid, editable);
      FusionApplyEditStyle(m_protectSessionEndHourEdit, sessionFieldsValid, editable);
      FusionApplyEditStyle(m_protectSessionEndMinuteEdit, sessionFieldsValid, editable);
      string sessionError = "";
      if(!sessionStartHourValid || !sessionStartMinuteValid || !sessionEndHourValid || !sessionEndMinuteValid)
         sessionError = "Horario da sessao invalido.";
      else if(!sessionOrderValid)
         sessionError = "Fim da sessao deve ser maior que o inicio.";
      outSettings.sessionStartHour = sessionStartHour;
      outSettings.sessionStartMinute = sessionStartMinute;
      outSettings.sessionEndHour = sessionEndHour;
      outSettings.sessionEndMinute = sessionEndMinute;

      bool newsValid = true;
      string newsError = "";
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         int startHour = 0, startMinute = 0, endHour = 0, endMinute = 0;
         bool startHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectNewsStartHourEdit[newsIndex])), 23, startHour);
         bool startMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectNewsStartMinuteEdit[newsIndex])), 59, startMinute);
         bool endHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectNewsEndHourEdit[newsIndex])), 23, endHour);
         bool endMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(m_protectNewsEndMinuteEdit[newsIndex])), 59, endMinute);
         bool newsOrderValid = true;
         if(startHourValid && startMinuteValid && endHourValid && endMinuteValid)
           {
            int newsStartTotal = startHour * 60 + startMinute;
            int newsEndTotal = endHour * 60 + endMinute;
            newsOrderValid = (newsEndTotal > newsStartTotal);
           }
         bool newsFieldsValid = startHourValid && startMinuteValid && endHourValid && endMinuteValid && newsOrderValid;
         FusionApplyEditStyle(m_protectNewsStartHourEdit[newsIndex], newsFieldsValid, editable);
         FusionApplyEditStyle(m_protectNewsStartMinuteEdit[newsIndex], newsFieldsValid, editable);
         FusionApplyEditStyle(m_protectNewsEndHourEdit[newsIndex], newsFieldsValid, editable);
         FusionApplyEditStyle(m_protectNewsEndMinuteEdit[newsIndex], newsFieldsValid, editable);
         newsValid = newsValid && newsFieldsValid;
         if(newsError == "" && (!startHourValid || !startMinuteValid || !endHourValid || !endMinuteValid))
            newsError = "Horario da News " + IntegerToString(newsIndex + 1) + " invalido.";
         else if(newsError == "" && !newsOrderValid)
            newsError = "Fim da News " + IntegerToString(newsIndex + 1) + " deve ser maior que o inicio.";
         outSettings.newsWindows[newsIndex].startHour = startHour;
         outSettings.newsWindows[newsIndex].startMinute = startMinute;
         outSettings.newsWindows[newsIndex].endHour = endHour;
         outSettings.newsWindows[newsIndex].endMinute = endMinute;
        }

      string dayTradesText = FusionTrimCopy(LiveEditText(m_protectDayTradesEdit));
      string dayLossText = FusionNormalizeDecimalText(LiveEditText(m_protectDayLossEdit));
      string dayGainText = FusionNormalizeDecimalText(LiveEditText(m_protectDayGainEdit));
      bool dayTradesValid = FusionIsIntegerText(dayTradesText, true) && (int)StringToInteger(dayTradesText) >= 0;
      bool dayLossValid = ProtectionMoneyValue(dayLossText, true, outSettings.maxDailyLoss);
      bool dayGainValid = ProtectionMoneyValue(dayGainText, true, outSettings.maxDailyGain);
      FusionApplyEditStyle(m_protectDayTradesEdit, dayTradesValid, editable);
      FusionApplyEditStyle(m_protectDayLossEdit, dayLossValid, editable);
      FusionApplyEditStyle(m_protectDayGainEdit, dayGainValid, editable);
      string dayError = "";
      if(!dayTradesValid)
         dayError = "Max Trades deve ser zero ou inteiro positivo.";
      else if(!dayLossValid)
         dayError = "Max Perda diario invalido.";
      else if(!dayGainValid)
         dayError = "Max Ganho diario invalido.";
      outSettings.maxDailyTrades = dayTradesValid ? (int)StringToInteger(dayTradesText) : 0;

      string ddText = FusionNormalizeDecimalText(LiveEditText(m_protectDrawdownValueEdit));
      bool ddValueValid = ProtectionMoneyValue(ddText, true, outSettings.maxDrawdown);
      if(ddValueValid && outSettings.enableDrawdown && outSettings.maxDrawdown <= 0.0)
         ddValueValid = false;
      bool ddDependencyValid = (!outSettings.enableDrawdown) ||
                               (outSettings.enableDailyLimits && outSettings.maxDailyGain > 0.0);
      FusionApplyEditStyle(m_protectDrawdownValueEdit, ddValueValid && ddDependencyValid, editable);
      m_protectDrawdownNote.Color(ddDependencyValid ? FUSION_CLR_WARN : FUSION_CLR_BAD);
      string drawdownError = "";
      if(!ddValueValid)
         drawdownError = outSettings.enableDrawdown ? "Max DD deve ser > 0 quando ativo." : "Max DD deve ser zero ou valor positivo.";
      else if(!ddDependencyValid)
         drawdownError = "Drawdown requer DAY ativo com Max Ganho > 0.";

      string streakLossText = FusionTrimCopy(LiveEditText(m_protectStreakLossEdit));
      string streakWinText = FusionTrimCopy(LiveEditText(m_protectStreakWinEdit));
      bool streakLossValid = FusionIsIntegerText(streakLossText, true) && (int)StringToInteger(streakLossText) >= 0;
      bool streakWinValid = FusionIsIntegerText(streakWinText, true) && (int)StringToInteger(streakWinText) >= 0;
      FusionApplyEditStyle(m_protectStreakLossEdit, streakLossValid, editable);
      FusionApplyEditStyle(m_protectStreakWinEdit, streakWinValid, editable);
      string streakError = "";
      if(!streakLossValid)
         streakError = "Max Loss deve ser zero ou inteiro positivo.";
      else if(!streakWinValid)
         streakError = "Max Win deve ser zero ou inteiro positivo.";
      outSettings.maxLossStreak = streakLossValid ? (int)StringToInteger(streakLossText) : 0;
      outSettings.maxWinStreak = streakWinValid ? (int)StringToInteger(streakWinText) : 0;

      m_protectPageValid[(int)FUSION_PROTECT_GENERAL] = true;
      m_protectPageValid[(int)FUSION_PROTECT_SPREAD] = spreadValid;
      m_protectPageValid[(int)FUSION_PROTECT_SESSION] = sessionFieldsValid;
      m_protectPageValid[(int)FUSION_PROTECT_NEWS] = newsValid;
      m_protectPageValid[(int)FUSION_PROTECT_DAY] = (dayTradesValid && dayLossValid && dayGainValid);
      m_protectPageValid[(int)FUSION_PROTECT_DRAWDOWN] = (ddValueValid && ddDependencyValid);
      m_protectPageValid[(int)FUSION_PROTECT_STREAK] = (streakLossValid && streakWinValid);

      m_protectPageError[(int)FUSION_PROTECT_GENERAL] = "";
      m_protectPageError[(int)FUSION_PROTECT_SPREAD] = spreadError;
      m_protectPageError[(int)FUSION_PROTECT_SESSION] = sessionError;
      m_protectPageError[(int)FUSION_PROTECT_NEWS] = newsError;
      m_protectPageError[(int)FUSION_PROTECT_DAY] = dayError;
      m_protectPageError[(int)FUSION_PROTECT_DRAWDOWN] = drawdownError;
      m_protectPageError[(int)FUSION_PROTECT_STREAK] = streakError;

      if(spreadError != "")
         error = spreadError;
      else if(sessionError != "")
         error = sessionError;
      else if(newsError != "")
         error = newsError;
      else if(dayError != "")
         error = dayError;
      else if(drawdownError != "")
         error = drawdownError;
      else if(streakError != "")
         error = streakError;

      return (error == "");
     }
