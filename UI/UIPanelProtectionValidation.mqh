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

   bool                       StreakConfigLocked(void) const
     {
      return m_snapshot.streakProtectionBlocked;
     }

   string                     StreakConfigLockMessage(void) const
     {
      if(m_snapshot.streakProtectionBlockReason != "")
         return "Streak em bloqueio: edicao suspensa ate liberar.";
      return "Streak em bloqueio: edicao suspensa ate liberar.";
     }

   bool                       DailyConfigLocked(void) const
     {
      return m_snapshot.dailyLimitsBlocked;
     }

   string                     DailyConfigLockMessage(void) const
     {
      return "DAY em bloqueio: edicao suspensa ate o novo dia.";
     }

   bool                       HasDayPendingChanges(void)
     {
      if(m_draftSettings.enableDailyLimits != m_committedSettings.enableDailyLimits)
         return true;
      if(m_draftSettings.profitTargetAction != m_committedSettings.profitTargetAction)
         return true;

      if(m_configProtectionCreated)
        {
         if(ProtectionIntegerEditPending(m_protectDayTradesEdit, m_committedSettings.maxDailyTrades))
            return true;
         if(ProtectionMoneyEditPending(m_protectDayLossEdit, m_committedSettings.maxDailyLoss))
            return true;
         if(ProtectionMoneyEditPending(m_protectDayGainEdit, m_committedSettings.maxDailyGain))
            return true;
         return false;
        }

      if(m_draftSettings.maxDailyTrades != m_committedSettings.maxDailyTrades)
         return true;
      if(MathAbs(m_draftSettings.maxDailyLoss - m_committedSettings.maxDailyLoss) > 0.0000001)
         return true;
      if(MathAbs(m_draftSettings.maxDailyGain - m_committedSettings.maxDailyGain) > 0.0000001)
         return true;

      return false;
     }

   bool                       DrawdownConfigLocked(void) const
     {
      return m_snapshot.drawdownConfigLocked;
     }

   string                     DrawdownConfigLockMessage(void) const
     {
      if(m_snapshot.drawdownConfigLockReason != "")
         return m_snapshot.drawdownConfigLockReason;
      return "DD ativo: protecao de lucro ligada; novas entradas permitidas.";
     }

   bool                       HasDrawdownPendingChanges(void)
     {
      if(m_draftSettings.enableDrawdown != m_committedSettings.enableDrawdown)
         return true;
      if(m_draftSettings.drawdownType != m_committedSettings.drawdownType)
         return true;
      if(m_draftSettings.drawdownPeakMode != m_committedSettings.drawdownPeakMode)
         return true;

      if(m_configProtectionCreated)
         return ProtectionMoneyEditPending(m_protectDrawdownValueEdit, m_committedSettings.maxDrawdown);

      return (MathAbs(m_draftSettings.maxDrawdown - m_committedSettings.maxDrawdown) > 0.0000001);
     }

   bool                       HasStreakPendingChanges(void)
     {
      if(m_draftSettings.lossStreakEnabled != m_committedSettings.lossStreakEnabled)
         return true;
      if(m_draftSettings.lossStreakAction != m_committedSettings.lossStreakAction)
         return true;
      if(m_draftSettings.winStreakEnabled != m_committedSettings.winStreakEnabled)
         return true;
      if(m_draftSettings.winStreakAction != m_committedSettings.winStreakAction)
         return true;

      if(m_configProtectionCreated)
        {
         if(ProtectionIntegerEditPending(m_protectStreakLossEdit, m_committedSettings.maxLossStreak))
            return true;
         if(ProtectionIntegerEditPending(m_protectStreakLossPauseMinutesEdit, m_committedSettings.lossStreakPauseMinutes))
            return true;
         if(ProtectionIntegerEditPending(m_protectStreakWinEdit, m_committedSettings.maxWinStreak))
            return true;
         if(ProtectionIntegerEditPending(m_protectStreakWinPauseMinutesEdit, m_committedSettings.winStreakPauseMinutes))
            return true;
         return false;
        }

      if(m_draftSettings.maxLossStreak != m_committedSettings.maxLossStreak)
         return true;
      if(m_draftSettings.lossStreakPauseMinutes != m_committedSettings.lossStreakPauseMinutes)
         return true;
      if(m_draftSettings.maxWinStreak != m_committedSettings.maxWinStreak)
         return true;
      if(m_draftSettings.winStreakPauseMinutes != m_committedSettings.winStreakPauseMinutes)
         return true;

      return false;
     }

   bool                       ValidateProtectionTimeWindow(CEdit &startHourEdit,
                                                           CEdit &startMinuteEdit,
                                                           CEdit &endHourEdit,
                                                           CEdit &endMinuteEdit,
                                                           const bool editable,
                                                           const bool required,
                                                           const bool overnightAllowed,
                                                           const string invalidError,
                                                           const string orderError,
                                                           int &startHour,
                                                           int &startMinute,
                                                           int &endHour,
                                                           int &endMinute,
                                                           string &error)
     {
      error = "";
      startHour = 0;
      startMinute = 0;
      endHour = 0;
      endMinute = 0;

      bool startHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(startHourEdit)), 23, startHour);
      bool startMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(startMinuteEdit)), 59, startMinute);
      bool endHourValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(endHourEdit)), 23, endHour);
      bool endMinuteValid = ProtectionTimeValue(FusionTrimCopy(LiveEditText(endMinuteEdit)), 59, endMinute);
      bool orderValid = true;

      if(startHourValid && startMinuteValid && endHourValid && endMinuteValid)
        {
         int startTotal = startHour * 60 + startMinute;
         int endTotal = endHour * 60 + endMinute;
         if(required)
            orderValid = overnightAllowed ? (startTotal > endTotal) : (endTotal > startTotal);
        }

      bool fieldsValid = startHourValid && startMinuteValid && endHourValid && endMinuteValid && orderValid;
      FusionApplyEditStyle(startHourEdit, fieldsValid, editable);
      FusionApplyEditStyle(startMinuteEdit, fieldsValid, editable);
      FusionApplyEditStyle(endHourEdit, fieldsValid, editable);
      FusionApplyEditStyle(endMinuteEdit, fieldsValid, editable);

      if(!startHourValid || !startMinuteValid || !endHourValid || !endMinuteValid)
         error = invalidError;
      else if(!orderValid)
         error = orderError;

      return fieldsValid;
     }

   bool                       HasProtectionPendingChanges(void)
     {
      if(!m_configProtectionCreated)
         return false;

      if(m_draftSettings.tradeDirection != m_committedSettings.tradeDirection)
         return true;
      if(m_draftSettings.sessionOvernight != m_committedSettings.sessionOvernight)
         return true;
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

      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
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
      if(m_draftSettings.profitTargetAction != m_committedSettings.profitTargetAction)
         return true;
      if(ProtectionMoneyEditPending(m_protectDrawdownValueEdit, m_committedSettings.maxDrawdown))
         return true;
      if(m_draftSettings.drawdownType != m_committedSettings.drawdownType)
         return true;
      if(m_draftSettings.drawdownPeakMode != m_committedSettings.drawdownPeakMode)
         return true;
      if(HasStreakPendingChanges())
         return true;

      return false;
     }

   bool                       ValidateProtectionSettings(SEASettings &outSettings,const bool editable,string &error)
     {
      error = "";

      string spreadText = FusionTrimCopy(LiveEditText(m_protectSpreadLimitEdit));
      outSettings.tradeDirection = (ENUM_TRADE_DIRECTION)m_protectDirection.Value();
      bool spreadValid = FusionIsIntegerText(spreadText, true) && (int)StringToInteger(spreadText) >= 0;
      int parsedSpread = spreadValid ? (int)StringToInteger(spreadText) : 0;
      if(spreadValid && outSettings.enableSpreadProtection && parsedSpread <= 0)
         spreadValid = false;
      FusionApplyEditStyle(m_protectSpreadLimitEdit, spreadValid, editable && outSettings.enableSpreadProtection);
      m_protectSpreadEnabledLbl.Color(!editable ? FUSION_CLR_MUTED : (spreadValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectSpreadLimitLbl.Color(!editable || !outSettings.enableSpreadProtection ? FUSION_CLR_MUTED : (spreadValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      string spreadError = "";
      if(!spreadValid)
         spreadError = outSettings.enableSpreadProtection ? "Max Spread deve ser > 0 quando ativo." : "Max Spread deve ser zero ou inteiro positivo.";
      outSettings.maxSpreadPoints = outSettings.enableSpreadProtection ? parsedSpread : 0;

      int sessionStartHour = 0, sessionStartMinute = 0, sessionEndHour = 0, sessionEndMinute = 0;
      string sessionError = "";
      bool sessionFieldsValid = ValidateProtectionTimeWindow(m_protectSessionStartHourEdit,
                                                             m_protectSessionStartMinuteEdit,
                                                             m_protectSessionEndHourEdit,
                                                             m_protectSessionEndMinuteEdit,
                                                             editable,
                                                             outSettings.enableSessionFilter,
                                                             outSettings.sessionOvernight,
                                                             "Horario da sessao invalido.",
                                                             "Sessao: ajuste Inicio/Fim para o modo Overnight.",
                                                             sessionStartHour,
                                                             sessionStartMinute,
                                                             sessionEndHour,
                                                             sessionEndMinute,
                                                             sessionError);
      outSettings.sessionStartHour = sessionStartHour;
      outSettings.sessionStartMinute = sessionStartMinute;
      outSettings.sessionEndHour = sessionEndHour;
      outSettings.sessionEndMinute = sessionEndMinute;

      bool newsValid = true;
      string newsError = "";
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         int startHour = 0, startMinute = 0, endHour = 0, endMinute = 0;
         string currentNewsError = "";
         bool newsFieldsValid = ValidateProtectionTimeWindow(m_protectNewsStartHourEdit[newsIndex],
                                                             m_protectNewsStartMinuteEdit[newsIndex],
                                                             m_protectNewsEndHourEdit[newsIndex],
                                                             m_protectNewsEndMinuteEdit[newsIndex],
                                                             editable,
                                                             outSettings.newsWindows[newsIndex].enabled,
                                                             false,
                                                             "Horario da News " + IntegerToString(newsIndex + 1) + " invalido.",
                                                             "News " + IntegerToString(newsIndex + 1) + ": Fim deve ser maior que Inicio.",
                                                             startHour,
                                                             startMinute,
                                                             endHour,
                                                             endMinute,
                                                             currentNewsError);
         newsValid = newsValid && newsFieldsValid;
         if(newsError == "" && currentNewsError != "")
            newsError = currentNewsError;
         outSettings.newsWindows[newsIndex].startHour = startHour;
         outSettings.newsWindows[newsIndex].startMinute = startMinute;
         outSettings.newsWindows[newsIndex].endHour = endHour;
         outSettings.newsWindows[newsIndex].endMinute = endMinute;
        }

      string dayTradesText = FusionTrimCopy(LiveEditText(m_protectDayTradesEdit));
      string dayLossText = FusionNormalizeDecimalText(LiveEditText(m_protectDayLossEdit));
      string dayGainText = FusionNormalizeDecimalText(LiveEditText(m_protectDayGainEdit));
      outSettings.profitTargetAction = (ENUM_PROFIT_TARGET_ACTION)m_protectDayProfitAction.Value();
      bool dayTradesValid = FusionIsIntegerText(dayTradesText, true) && (int)StringToInteger(dayTradesText) >= 0;
      bool dayLossValid = ProtectionMoneyValue(dayLossText, true, outSettings.maxDailyLoss);
      bool dayGainValid = ProtectionMoneyValue(dayGainText, true, outSettings.maxDailyGain);
      bool ddNeedsDailyGain = (outSettings.enableDrawdown &&
                               outSettings.enableDailyLimits &&
                               outSettings.profitTargetAction == PROFIT_ACTION_ATIVAR_DD);
      bool dayGainRequirementValid = (!ddNeedsDailyGain || outSettings.maxDailyGain > 0.0);
      bool dayLocked = DailyConfigLocked();
      bool dayEditAllowed = (editable && !dayLocked);
      FusionApplyEditStyle(m_protectDayTradesEdit, dayTradesValid, dayEditAllowed);
      FusionApplyEditStyle(m_protectDayLossEdit, dayLossValid, dayEditAllowed);
      FusionApplyEditStyle(m_protectDayGainEdit, dayGainValid && dayGainRequirementValid, dayEditAllowed);
      m_protectDayEnabledLbl.Color(!dayEditAllowed ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
      m_protectDayTradesLbl.Color(!dayEditAllowed ? FUSION_CLR_MUTED : (dayTradesValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectDayLossLbl.Color(!dayEditAllowed ? FUSION_CLR_MUTED : (dayLossValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectDayGainLbl.Color(!dayEditAllowed ? FUSION_CLR_MUTED : ((dayGainValid && dayGainRequirementValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      string dayError = "";
      if(dayLocked && HasDayPendingChanges())
         dayError = DailyConfigLockMessage();
      else if(!dayTradesValid)
         dayError = "Max Trades deve ser zero ou inteiro positivo.";
      else if(!dayLossValid)
         dayError = "Max Perda diario invalido.";
      else if(!dayGainValid)
         dayError = "Max Ganho diario invalido.";
      else if(!dayGainRequirementValid)
         dayError = "DD ON exige Max Ganho > 0 no DAY.";
      outSettings.maxDailyTrades = dayTradesValid ? (int)StringToInteger(dayTradesText) : 0;

      string ddText = FusionNormalizeDecimalText(LiveEditText(m_protectDrawdownValueEdit));
      outSettings.drawdownType = (ENUM_DRAWDOWN_TYPE)m_protectDrawdownType.Value();
      outSettings.drawdownPeakMode = (ENUM_DRAWDOWN_PEAK_MODE)m_protectDrawdownPeakMode.Value();
      bool ddValueValid = ProtectionMoneyValue(ddText, true, outSettings.maxDrawdown);
      if(ddValueValid && outSettings.enableDrawdown && outSettings.maxDrawdown <= 0.0)
         ddValueValid = false;
      if(ddValueValid &&
         outSettings.enableDrawdown &&
         outSettings.drawdownType == DD_TIPO_PERCENTUAL &&
         outSettings.maxDrawdown > 100.0)
         ddValueValid = false;
      bool dayRequestsDrawdown = (outSettings.enableDailyLimits &&
                                  outSettings.profitTargetAction == PROFIT_ACTION_ATIVAR_DD);
      bool profitActionValid = (!dayRequestsDrawdown ||
                                (outSettings.enableDrawdown && outSettings.maxDrawdown > 0.0));
      bool ddDependencyValid = (!outSettings.enableDrawdown) ||
                               (outSettings.enableDailyLimits &&
                                outSettings.maxDailyGain > 0.0 &&
                                outSettings.profitTargetAction == PROFIT_ACTION_ATIVAR_DD);
      bool drawdownLocked = DrawdownConfigLocked();
      bool drawdownEditAllowed = (editable && !drawdownLocked);
      FusionApplyEditStyle(m_protectDrawdownValueEdit, ddValueValid && ddDependencyValid, drawdownEditAllowed);
      m_protectDrawdownType.Sync((long)outSettings.drawdownType, drawdownEditAllowed && outSettings.enableDrawdown);
      m_protectDrawdownPeakMode.Sync((long)outSettings.drawdownPeakMode, drawdownEditAllowed && outSettings.enableDrawdown);
      m_protectDrawdownType.RaiseRuntimeObjects(3908);
      m_protectDrawdownPeakMode.RaiseRuntimeObjects(3909);
      m_protectDrawdownNote.Color(drawdownLocked ? (m_snapshot.drawdownLimitReached ? FUSION_CLR_WARN : FUSION_CLR_MUTED) :
                                    (ddDependencyValid ? FUSION_CLR_WARN : FUSION_CLR_BAD));
      string drawdownError = "";
      if(!profitActionValid && dayError == "")
         dayError = "ATIVAR DD requer DD ON com Max DD > 0.";
      if(drawdownLocked && HasDrawdownPendingChanges())
         drawdownError = DrawdownConfigLockMessage();
      else if(!ddValueValid)
         drawdownError = (outSettings.enableDrawdown && outSettings.drawdownType == DD_TIPO_PERCENTUAL) ?
                         "Max DD percentual deve ser > 0 e <= 100." :
                         (outSettings.enableDrawdown ? "Max DD deve ser > 0 quando ativo." : "Max DD deve ser zero ou valor positivo.");
      else if(!profitActionValid)
         drawdownError = "ATIVAR DD requer DD ON com Max DD > 0.";
      else if(!ddDependencyValid)
         drawdownError = "DD requer DAY ON, Max Ganho > 0 e ATIVAR DD.";

      string streakLossText = FusionTrimCopy(LiveEditText(m_protectStreakLossEdit));
      string streakWinText = FusionTrimCopy(LiveEditText(m_protectStreakWinEdit));
      string streakLossPauseText = FusionTrimCopy(LiveEditText(m_protectStreakLossPauseMinutesEdit));
      string streakWinPauseText = FusionTrimCopy(LiveEditText(m_protectStreakWinPauseMinutesEdit));
      bool rawLossParsed = FusionIsIntegerText(streakLossText, true) && (int)StringToInteger(streakLossText) >= 0;
      bool rawWinParsed = FusionIsIntegerText(streakWinText, true) && (int)StringToInteger(streakWinText) >= 0;
      bool rawLossPauseParsed = FusionIsIntegerText(streakLossPauseText, true) && (int)StringToInteger(streakLossPauseText) >= 0;
      bool rawWinPauseParsed = FusionIsIntegerText(streakWinPauseText, true) && (int)StringToInteger(streakWinPauseText) >= 0;
      int parsedLossStreak = rawLossParsed ? (int)StringToInteger(streakLossText) : 0;
      int parsedWinStreak = rawWinParsed ? (int)StringToInteger(streakWinText) : 0;
      int parsedLossPause = rawLossPauseParsed ? (int)StringToInteger(streakLossPauseText) : 0;
      int parsedWinPause = rawWinPauseParsed ? (int)StringToInteger(streakWinPauseText) : 0;
      bool streakLossParsed = (!outSettings.lossStreakEnabled || rawLossParsed);
      bool streakWinParsed = (!outSettings.winStreakEnabled || rawWinParsed);
      bool lossLimitValid = streakLossParsed && (!outSettings.lossStreakEnabled || parsedLossStreak > 0);
      bool winLimitValid = streakWinParsed && (!outSettings.winStreakEnabled || parsedWinStreak > 0);
      bool lossPauseRequired = (outSettings.lossStreakEnabled && outSettings.lossStreakAction == STREAK_ACTION_PAUSE);
      bool winPauseRequired = (outSettings.winStreakEnabled && outSettings.winStreakAction == STREAK_ACTION_PAUSE);
      bool streakLossPauseParsed = (!lossPauseRequired || rawLossPauseParsed);
      bool streakWinPauseParsed = (!winPauseRequired || rawWinPauseParsed);
      bool lossPauseValid = streakLossPauseParsed && (!lossPauseRequired || parsedLossPause > 0);
      bool winPauseValid = streakWinPauseParsed && (!winPauseRequired || parsedWinPause > 0);
      bool streakLocked = StreakConfigLocked();
      bool streakEditAllowed = (editable && !streakLocked);
      bool lossEditable = (streakEditAllowed && outSettings.lossStreakEnabled);
      bool winEditable = (streakEditAllowed && outSettings.winStreakEnabled);
      FusionApplyEditStyle(m_protectStreakLossEdit, lossLimitValid, lossEditable);
      FusionApplyEditStyle(m_protectStreakLossPauseMinutesEdit,
                           lossPauseValid,
                           lossEditable && outSettings.lossStreakAction == STREAK_ACTION_PAUSE);
      FusionApplyEditStyle(m_protectStreakWinEdit, winLimitValid, winEditable);
      FusionApplyEditStyle(m_protectStreakWinPauseMinutesEdit,
                           winPauseValid,
                           winEditable && outSettings.winStreakAction == STREAK_ACTION_PAUSE);
      m_protectStreakLossAction.Sync((long)outSettings.lossStreakAction, lossEditable);
      m_protectStreakWinAction.Sync((long)outSettings.winStreakAction, winEditable);
      m_protectStreakLossAction.RaiseRuntimeObjects(3910);
      m_protectStreakWinAction.RaiseRuntimeObjects(3920);
      m_protectStreakLossHdr.Color(!streakEditAllowed ? FUSION_CLR_MUTED : ((lossLimitValid && lossPauseValid) ? FUSION_CLR_VALUE : FUSION_CLR_BAD));
      m_protectStreakWinHdr.Color(!streakEditAllowed ? FUSION_CLR_MUTED : ((winLimitValid && winPauseValid) ? FUSION_CLR_VALUE : FUSION_CLR_BAD));
      m_protectStreakLossEnabledLbl.Color(!streakEditAllowed ? FUSION_CLR_MUTED : ((lossLimitValid && lossPauseValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectStreakWinEnabledLbl.Color(!streakEditAllowed ? FUSION_CLR_MUTED : ((winLimitValid && winPauseValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectStreakLossLbl.Color(!lossEditable ? FUSION_CLR_MUTED : (lossLimitValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectStreakWinLbl.Color(!winEditable ? FUSION_CLR_MUTED : (winLimitValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectStreakLossPauseMinutesLbl.Color(!(lossEditable && outSettings.lossStreakAction == STREAK_ACTION_PAUSE) ? FUSION_CLR_MUTED : (lossPauseValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_protectStreakWinPauseMinutesLbl.Color(!(winEditable && outSettings.winStreakAction == STREAK_ACTION_PAUSE) ? FUSION_CLR_MUTED : (winPauseValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      string streakError = "";
      if(streakLocked && HasStreakPendingChanges())
         streakError = StreakConfigLockMessage();
      else if(!streakLossParsed)
         streakError = "Max Loss deve ser zero ou inteiro positivo.";
      else if(outSettings.lossStreakEnabled && parsedLossStreak <= 0)
         streakError = "Loss Streak ON requer Max Loss maior que 0.";
      else if(!streakLossPauseParsed)
         streakError = "Pausa Loss deve ser zero ou inteiro positivo.";
      else if(lossPauseRequired && parsedLossPause <= 0)
         streakError = "Pausa Loss deve ser maior que 0 quando acao for PAUSAR.";
      else if(!streakWinParsed)
         streakError = "Max Win deve ser zero ou inteiro positivo.";
      else if(outSettings.winStreakEnabled && parsedWinStreak <= 0)
         streakError = "Win Streak ON requer Max Win maior que 0.";
      else if(!streakWinPauseParsed)
         streakError = "Pausa Win deve ser zero ou inteiro positivo.";
      else if(winPauseRequired && parsedWinPause <= 0)
         streakError = "Pausa Win deve ser maior que 0 quando acao for PAUSAR.";
      outSettings.maxLossStreak = parsedLossStreak;
      outSettings.lossStreakPauseMinutes = parsedLossPause;
      outSettings.maxWinStreak = parsedWinStreak;
      outSettings.winStreakPauseMinutes = parsedWinPause;

      m_protectPageValid[(int)FUSION_PROTECT_GENERAL] = true;
      m_protectPageValid[(int)FUSION_PROTECT_SPREAD] = spreadValid;
      m_protectPageValid[(int)FUSION_PROTECT_SESSION] = sessionFieldsValid;
      m_protectPageValid[(int)FUSION_PROTECT_NEWS] = newsValid;
      m_protectPageValid[(int)FUSION_PROTECT_DAY] = (dayTradesValid && dayLossValid && dayGainValid && dayGainRequirementValid && profitActionValid && dayError == "");
      m_protectPageValid[(int)FUSION_PROTECT_DRAWDOWN] = (ddValueValid && ddDependencyValid && profitActionValid && drawdownError == "");
      m_protectPageValid[(int)FUSION_PROTECT_STREAK] = (lossLimitValid && winLimitValid && lossPauseValid && winPauseValid && streakError == "");

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
