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
      if(ProtectionMoneyEditPending(m_protectDrawdownValueEdit, m_committedSettings.maxDrawdown))
         return true;
      if(ProtectionIntegerEditPending(m_protectStreakLossEdit, m_committedSettings.maxLossStreak))
         return true;
      if(ProtectionIntegerEditPending(m_protectStreakWinEdit, m_committedSettings.maxWinStreak))
         return true;

      return false;
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
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
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
