#ifndef __FUSION_UI_PANEL_PROTECTION_SYNC_MQH__
#define __FUSION_UI_PANEL_PROTECTION_SYNC_MQH__

   void                       SyncProtectionOverview(void)
     {
      string spreadText = !m_draftSettings.enableSpreadProtection ? "Spread OFF" : "Spread max " + IntegerToString(m_draftSettings.maxSpreadPoints) + " pts";
      string blockedSignalText = "Descarta sinais";
      m_protectGeneralValues[0].Text(FusionTradeDirectionName(m_draftSettings.tradeDirection) + " | " + spreadText + " | " + blockedSignalText);
      string sessionText = !m_draftSettings.enableSessionFilter ? "OFF" :
                           StringFormat("%02d:%02d - %02d:%02d",
                                        m_draftSettings.sessionStartHour,
                                        m_draftSettings.sessionStartMinute,
                                        m_draftSettings.sessionEndHour,
                                        m_draftSettings.sessionEndMinute);
      if(m_draftSettings.enableSessionFilter && m_draftSettings.sessionOvernight)
         sessionText += " +1d";
      m_protectGeneralValues[1].Text(sessionText);

      int newsEnabled = 0;
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
         if(m_draftSettings.newsWindows[newsIndex].enabled)
            newsEnabled++;
      string newsText = IntegerToString(newsEnabled) + "/" + IntegerToString(FUSION_NEWS_WINDOW_COUNT) + " janelas ativas";
      m_protectGeneralValues[2].Text(newsText);

      string dayText = !m_draftSettings.enableDailyLimits ? "OFF" :
                       (m_snapshot.dailyLimitsBlocked ? "BLOQUEADO" : "ATIVO");
      m_protectGeneralValues[3].Text(dayText);

      m_protectGeneralValues[4].Text(m_snapshot.drawdownLimitReached ? "ATINGIDO" :
                                     (m_snapshot.drawdownProtectionActive ? "ATIVO" :
                                      (!m_draftSettings.enableDrawdown ? "OFF" : "AGUARDANDO META")));

      bool streakEnabled = (m_draftSettings.lossStreakEnabled || m_draftSettings.winStreakEnabled);
      string streakText = "OFF";
      if(streakEnabled && m_snapshot.streakProtectionBlocked)
         streakText = (StringFind(m_snapshot.streakProtectionBlockReason, "em pausa") >= 0) ? "EM PAUSA" : "BLOQUEADO";
      else if(streakEnabled)
         streakText = "ATIVO";
      m_protectGeneralValues[5].Text(streakText);
     }

   void                       SyncDrawdownRuntimeMetrics(void)
     {
      m_protectDrawdownPeakRuntimeLbl.Text(m_draftSettings.drawdownPeakMode == DD_PICO_FLUTUANTE ? "Pico atual" : "Base atual");
      m_protectDrawdownBufferLbl.Text(m_snapshot.drawdownLimitReached ? "Folga atual" : "Folga DD");
      bool hasDrawdownRuntimeBase = (m_snapshot.drawdownProtectionActive ||
                                     m_snapshot.drawdownLimitReached ||
                                     m_snapshot.drawdownPeakProfit > 0.0);
      color drawdownRuntimeColor = m_snapshot.drawdownLimitReached ? FUSION_CLR_WARN : FUSION_CLR_VALUE;
      m_protectDrawdownPeakRuntimeValue.Text(hasDrawdownRuntimeBase ? DoubleToString(m_snapshot.drawdownPeakProfit, 2) : "--");
      m_protectDrawdownPeakRuntimeValue.Color(hasDrawdownRuntimeBase ? drawdownRuntimeColor : FUSION_CLR_MUTED);
      m_protectDrawdownFloorValue.Text(hasDrawdownRuntimeBase ? DoubleToString(m_snapshot.drawdownFloorProfit, 2) : "--");
      m_protectDrawdownFloorValue.Color(hasDrawdownRuntimeBase ? drawdownRuntimeColor : FUSION_CLR_MUTED);
      m_protectDrawdownBufferValue.Text(hasDrawdownRuntimeBase ? DoubleToString(m_snapshot.drawdownBufferProfit, 2) : "--");
      m_protectDrawdownBufferValue.Color(hasDrawdownRuntimeBase ? (m_snapshot.drawdownBufferProfit <= 0.0 ? FUSION_CLR_BAD : drawdownRuntimeColor) : FUSION_CLR_MUTED);
     }

   void                       SyncProtectionFooters(void)
     {
      m_protectEntryFoot1.Text("Sinais surgidos durante bloqueios sao descartados.");
      m_protectEntryFoot2.Text("Direcao nao bloqueia estrategia em VM; guards continuam ativos.");

      m_protectSessionFoot1.Text(m_draftSettings.sessionOvernight ?
                                 "Overnight ON: Inicio > Fim e cruza meia-noite." :
                                 "Overnight OFF: Fim > Inicio no mesmo dia.");
      m_protectSessionFoot2.Text(m_draftSettings.closeOnSessionEnd ?
                                 "Fechar no fim ON: fecha posicoes ao termino da sessao." :
                                 "Fechar no fim OFF: nao fecha posicoes pelo fim da sessao.");
      m_protectSessionFoot3.Text("Fora da janela, novas entradas ficam bloqueadas.");

      if(DailyConfigLocked())
        {
         m_protectDayFoot1.Text("DAY em bloqueio: edicao suspensa ate o novo dia.");
         m_protectDayFoot2.Text("Pausar o EA nao remove nem permite alterar este bloqueio.");
         m_protectDayFoot3.Text(m_snapshot.dailyLimitsBlockReason);
         m_protectDayFoot1.Color(FUSION_CLR_WARN);
         m_protectDayFoot2.Color(FUSION_CLR_WARN);
         m_protectDayFoot3.Color(FUSION_CLR_WARN);
        }
      else
        {
         m_protectDayFoot1.Text("Campos em zero ficam sem limite.");
         m_protectDayFoot2.Text("ATIVAR DD exige DRAWDOWN ON com Max DD > 0.");
         m_protectDayFoot3.Text("Contadores e P/L persistem e resetam no novo dia.");
         m_protectDayFoot1.Color(FUSION_CLR_MUTED);
         m_protectDayFoot2.Color(FUSION_CLR_MUTED);
         m_protectDayFoot3.Color(FUSION_CLR_MUTED);
        }

      if(DrawdownConfigLocked())
        {
         if(m_snapshot.drawdownLimitReached)
           {
            m_protectDrawdownNote.Text(DrawdownConfigLockMessage());
            bool hasTriggerDetails = (MathAbs(m_snapshot.drawdownTriggerProfit) > 0.0000001 ||
                                      MathAbs(m_snapshot.drawdownTriggerDrawdown) > 0.0000001 ||
                                      MathAbs(m_snapshot.drawdownTriggerBuffer) > 0.0000001);
            if(hasTriggerDetails)
              {
               m_protectDrawdownFoot2.Text(StringFormat("Gatilho: P/L projetado %.2f | DD usado %.2f",
                                                        m_snapshot.drawdownTriggerProfit,
                                                        m_snapshot.drawdownTriggerDrawdown));
               m_protectDrawdownFoot3.Text(StringFormat("Folga no gatilho %.2f; Folga atual acima vem do fechamento.",
                                                        m_snapshot.drawdownTriggerBuffer));
              }
            else
              {
               m_protectDrawdownFoot2.Text("DD atingido: detalhe do gatilho indisponivel neste estado.");
               m_protectDrawdownFoot3.Text("Folga atual acima pode vir do fechamento apos o gatilho.");
              }
           }
         else
           {
            m_protectDrawdownNote.Text("DD ativo: protecao de lucro ligada.");
            m_protectDrawdownFoot2.Text("Novas entradas seguem permitidas ate tocar o Piso DD.");
            m_protectDrawdownFoot3.Text("Edicao do DD fica suspensa ate o novo dia.");
           }
         color drawdownLockColor = m_snapshot.drawdownLimitReached ? FUSION_CLR_WARN : FUSION_CLR_MUTED;
         m_protectDrawdownNote.Color(drawdownLockColor);
         m_protectDrawdownFoot2.Color(drawdownLockColor);
         m_protectDrawdownFoot3.Color(drawdownLockColor);
        }
      else
        {
         m_protectDrawdownNote.Text("Requer DAY ON, Max Ganho > 0 e Acao ATIVAR DD.");
         m_protectDrawdownFoot2.Text("Financeiro: valor; Percentual: % da base.");
         m_protectDrawdownFoot3.Text(m_draftSettings.drawdownPeakMode == DD_PICO_FLUTUANTE ?
                                     "Pico Ganho acompanha o maior P/L projetado." :
                                     "Meta Max.Ganho usa a meta como base fixa.");
         m_protectDrawdownNote.Color(FUSION_CLR_WARN);
         m_protectDrawdownFoot2.Color(FUSION_CLR_MUTED);
         m_protectDrawdownFoot3.Color(FUSION_CLR_MUTED);
        }

      SyncDrawdownRuntimeMetrics();

      if(StreakConfigLocked())
        {
         m_protectStreakFoot1.Text("Streak em bloqueio: edicao suspensa ate liberar.");
         m_protectStreakFoot2.Text("Pausar o EA nao remove nem permite alterar este bloqueio.");
         m_protectStreakFoot1.Color(FUSION_CLR_WARN);
         m_protectStreakFoot2.Color(FUSION_CLR_WARN);
        }
      else
        {
         m_protectStreakFoot1.Text("Loss e Win sao independentes; cada lado pode ficar OFF.");
         m_protectStreakFoot2.Text("PAUSAR bloqueia por minutos; PARAR DIA libera no proximo dia.");
         m_protectStreakFoot1.Color(FUSION_CLR_MUTED);
         m_protectStreakFoot2.Color(FUSION_CLR_MUTED);
        }
     }

   void                       RefreshProtectionTheme(void)
     {
      bool editable = CanEditActiveProfile();
      bool dayEditable = (editable && !DailyConfigLocked());
      bool drawdownEditable = (editable && !DrawdownConfigLocked());
      bool streakEditable = (editable && !StreakConfigLocked());

      ApplyProtectionTabStyles();

      SyncProtectionOverview();
      SyncProtectionFooters();

      FusionApplyToggleButtonStyle(m_protectSpreadEnabledBtn, m_draftSettings.enableSpreadProtection, editable);
      SyncProtectionDirectionCombo(editable);
      FusionApplyToggleButtonStyle(m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter, editable);
      FusionApplyToggleButtonStyle(m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd, editable);
      FusionApplyToggleButtonStyle(m_protectSessionOvernightBtn, m_draftSettings.sessionOvernight, editable);

      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         FusionApplyToggleButtonStyle(m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled, editable);
         ApplyProtectModeButtonStyle(m_protectNewsModeBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].action, editable);
        }

      FusionApplyToggleButtonStyle(m_protectDayEnabledBtn, m_draftSettings.enableDailyLimits, dayEditable);
      FusionApplyToggleButtonStyle(m_protectDrawdownEnabledBtn, m_draftSettings.enableDrawdown, drawdownEditable);
      SyncProtectionDayActionCombo(dayEditable);
      SyncProtectionDrawdownCombos(drawdownEditable);
      FusionApplyToggleButtonStyle(m_protectStreakLossEnabledBtn, m_draftSettings.lossStreakEnabled, streakEditable);
      FusionApplyToggleButtonStyle(m_protectStreakWinEnabledBtn, m_draftSettings.winStreakEnabled, streakEditable);
      SyncProtectionStreakActionCombos(streakEditable);
     }

   void                       SyncProtectionControls(void)
     {
      RefreshProtectionTheme();
      FusionApplyEditStyle(m_protectSpreadLimitEdit, true, CanEditActiveProfile() && m_draftSettings.enableSpreadProtection);
      m_protectSpreadLimitEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      SyncProtectionDirectionCombo(CanEditActiveProfile());
      m_protectSessionStartHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartHour));
      m_protectSessionStartMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionStartMinute));
      m_protectSessionEndHourEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndHour));
      m_protectSessionEndMinuteEdit.Text(StringFormat("%02d", m_draftSettings.sessionEndMinute));
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         m_protectNewsStartHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startHour));
         m_protectNewsStartMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].startMinute));
         m_protectNewsEndHourEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endHour));
         m_protectNewsEndMinuteEdit[newsIndex].Text(StringFormat("%02d", m_draftSettings.newsWindows[newsIndex].endMinute));
        }
      m_protectDayTradesEdit.Text(IntegerToString(m_draftSettings.maxDailyTrades));
      m_protectDayLossEdit.Text(DoubleToString(m_draftSettings.maxDailyLoss, 2));
      m_protectDayGainEdit.Text(DoubleToString(m_draftSettings.maxDailyGain, 2));
      SyncProtectionDayActionCombo(CanEditActiveProfile() && !DailyConfigLocked());
      m_protectDrawdownValueEdit.Text(DoubleToString(m_draftSettings.maxDrawdown, 2));
      SyncProtectionDrawdownCombos(CanEditActiveProfile() && !DrawdownConfigLocked());
      m_protectStreakLossEdit.Text(IntegerToString(m_draftSettings.maxLossStreak));
      m_protectStreakLossPauseMinutesEdit.Text(IntegerToString(m_draftSettings.lossStreakPauseMinutes));
      m_protectStreakWinEdit.Text(IntegerToString(m_draftSettings.maxWinStreak));
      m_protectStreakWinPauseMinutesEdit.Text(IntegerToString(m_draftSettings.winStreakPauseMinutes));
     }

#endif
