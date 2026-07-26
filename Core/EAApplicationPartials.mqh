#ifndef __FUSION_EA_APPLICATION_PARTIALS_MQH__
#define __FUSION_EA_APPLICATION_PARTIALS_MQH__

   void                    ResetCloseReconciliation(void)
     {
      m_closeReconciliationPending = false;
      ResetPositionRuntimeState(m_closeReconciliationState);
      m_nextCloseReconciliationAttempt = 0;
      m_closeReconciliationAttempts = 0;
      m_closeReconciliationWaitLogged = false;
     }

   double                  PositionVolumeTolerance(void) const
     {
      double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      return MathMax(volumeStep * 0.1, 0.00000001);
     }

   string                  PartialLevelName(const ENUM_PARTIAL_CLOSE_LEVEL level) const
     {
      if(level == PARTIAL_CLOSE_TP1)
         return "TP1";
      if(level == PARTIAL_CLOSE_TP2)
         return "TP2";
      return "parcial";
     }

   void                    ClearPendingPartialClose(SPositionRuntimeState &state)
     {
      state.partialClosePending = false;
      state.pendingPartialLevel = PARTIAL_CLOSE_NONE;
      state.pendingPartialInitialVolume = 0.0;
      state.pendingPartialRequestedVolume = 0.0;
      state.pendingPartialBaselineExitVolume = 0.0;
      state.pendingPartialPreProjectedProfit = 0.0;
      state.pendingPartialFloatingReferenceSet = false;
      state.pendingPartialFloatingReference = 0.0;
      state.pendingPartialOrderTicket = 0;
      state.pendingPartialDealTicket = 0;
      state.pendingPartialRetcode = 0;
      state.pendingPartialSince = 0;
      m_pendingPartialForceCloseWaitLogged = false;
     }

   double                  EffectiveProjectedProfit(const double floatingProfit) const
     {
      if(m_positionState.partialClosePending &&
         m_positionState.pendingPartialFloatingReferenceSet)
         return m_positionState.pendingPartialPreProjectedProfit +
                (floatingProfit - m_positionState.pendingPartialFloatingReference);

      return m_protectionManager.DailyClosedProfit() + floatingProfit;
     }

   double                  EffectiveFloatingProfit(const double floatingProfit) const
     {
      return EffectiveProjectedProfit(floatingProfit) - m_protectionManager.DailyClosedProfit();
     }

   void                    UpdateLivePanelIfDue(void)
     {
      uint now = GetTickCount();
      if(m_lastLivePanelRefreshTick != 0 && now - m_lastLivePanelRefreshTick < 200)
         return;
      m_lastLivePanelRefreshTick = now;
      UpdatePanelIfVisible();
     }

   bool                    ReconcileOpenPositionPartials(const bool applyDailyDelta,
                                                          const bool forceHistoryRead)
     {
      if(!m_positionState.hasPosition || m_positionState.positionId == 0)
         return false;
      if(!m_positionState.partialClosePending && !forceHistoryRead)
         return false;
      if(m_positionState.ticket == 0 || !PositionSelectByTicket(m_positionState.ticket))
         return false;

      SClosedTradeSummary summary;
      if(!m_executionService.TryGetPositionTradeSummary(m_positionState.positionId, summary))
         return false;
      if(summary.complete)
         return false;

      bool changed = false;
      double previousRealized = m_positionState.realizedPartialProfit;
      double realizedDelta = summary.totalProfit - previousRealized;
      if(MathAbs(realizedDelta) > 0.0000001)
        {
         m_positionState.realizedPartialProfit = summary.totalProfit;
         changed = true;

         int exitDayKey = FusionProtectionCurrentDayKey(summary.lastExitTime);
         int currentDayKey = FusionProtectionCurrentDayKey();
         if(applyDailyDelta && summary.lastExitTime > 0 && exitDayKey == currentDayKey)
            m_protectionManager.OnPartialRealized(realizedDelta);
         else if(applyDailyDelta && summary.lastExitTime > 0 && exitDayKey != currentDayKey)
            m_logger.Info("PARTIAL", "Parcial reconciliada pertence a outro dia operacional; DAY/DD atuais nao foram alterados.");

         m_logger.Info("PARTIAL", "P/L bruto realizado de parciais reconciliado: " +
                       DoubleToString(previousRealized, 2) + " -> " +
                       DoubleToString(summary.totalProfit, 2) + ".");
        }

      if(m_positionState.partialClosePending)
        {
         double tolerance = PositionVolumeTolerance();
         double newExitVolume = summary.exitVolume - m_positionState.pendingPartialBaselineExitVolume;
         bool newExitObserved = (newExitVolume > tolerance);
         if(m_positionState.pendingPartialOrderTicket == 0)
           {
            ulong recoveredOrder = m_executionService.FindActivePositionOrder(m_positionState.positionId);
            if(recoveredOrder > 0)
              {
               m_positionState.pendingPartialOrderTicket = recoveredOrder;
               changed = true;
               m_logger.Info("PARTIAL", "Ordem parcial ativa recuperada apos restauracao do estado.");
              }
           }
         bool orderActive = m_executionService.IsOrderActive(m_positionState.pendingPartialOrderTicket);
         bool exitConfirmed = (newExitObserved && !orderActive);

         if(exitConfirmed)
           {
            ENUM_PARTIAL_CLOSE_LEVEL level = m_positionState.pendingPartialLevel;
            double requestedVolume = m_positionState.pendingPartialRequestedVolume;
            if(level == PARTIAL_CLOSE_TP1)
               m_positionState.tp1Executed = true;
            else if(level == PARTIAL_CLOSE_TP2)
               m_positionState.tp2Executed = true;

            ClearPendingPartialClose(m_positionState);
            changed = true;
            m_logger.Trade("PARTIAL", PartialLevelName(level) +
                           " confirmado pelo historico. Volume executado: " +
                           DoubleToString(newExitVolume, 8) + "/" +
                           DoubleToString(requestedVolume, 8) + ".");
            TryRemoveFreeFinalTakeProfit();
           }
         else
           {
            if(PositionSelectByTicket(m_positionState.ticket))
               m_positionState.volume = PositionGetDouble(POSITION_VOLUME);
            bool volumeReduced = (m_positionState.volume + tolerance <
                                  m_positionState.pendingPartialInitialVolume);
            if(volumeReduced &&
               (!m_positionState.pendingPartialFloatingReferenceSet ||
                newExitObserved))
              {
               if(PositionSelectByTicket(m_positionState.ticket))
                 {
                  double currentFloating = PositionGetDouble(POSITION_PROFIT);
                  // Sem deal, preserve a base pre-envio e acompanhe apenas o volume restante.
                  if(newExitObserved)
                     m_positionState.pendingPartialPreProjectedProfit =
                        m_protectionManager.DailyClosedProfit() + currentFloating;
                  m_positionState.pendingPartialFloatingReference = currentFloating;
                  m_positionState.pendingPartialFloatingReferenceSet = true;
                  changed = true;
                 }
              }

            datetime now = FusionProtectionReliableTime();
            bool terminalWithoutFill = m_executionService.IsHistoricalOrderTerminalWithoutFill(
                                          m_positionState.pendingPartialOrderTicket);
            bool submissionNotRecorded = (m_positionState.pendingPartialOrderTicket == 0 &&
                                          m_positionState.pendingPartialDealTicket == 0 &&
                                          m_positionState.pendingPartialRetcode == 0);
            bool indeterminateWithoutTicket =
               (m_positionState.pendingPartialOrderTicket == 0 &&
                m_positionState.pendingPartialDealTicket == 0 &&
                (m_positionState.pendingPartialRetcode == TRADE_RETCODE_TIMEOUT ||
                 m_positionState.pendingPartialRetcode == TRADE_RETCODE_CONNECTION));
            bool connected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
            bool safeToRelease = (terminalWithoutFill &&
                                  now - m_positionState.pendingPartialSince >= 2) ||
                                 (submissionNotRecorded &&
                                  now - m_positionState.pendingPartialSince >= 5) ||
                                 (indeterminateWithoutTicket &&
                                  now - m_positionState.pendingPartialSince >= 5);
            if(!volumeReduced && connected && safeToRelease &&
               m_positionState.pendingPartialSince > 0 &&
               !orderActive)
              {
               string levelName = PartialLevelName(m_positionState.pendingPartialLevel);
               ClearPendingPartialClose(m_positionState);
               changed = true;
               m_logger.Warn("PARTIAL", levelName +
                             " terminou sem deal confirmado; nova tentativa sera permitida.");
              }
           }
        }

      if(changed)
         PersistChartState();
      return changed;
     }

   bool                    SubmitPartialClose(const ENUM_PARTIAL_CLOSE_LEVEL level,
                                              const double volume,
                                              const string reason,
                                              const double floatingProfit)
     {
      SClosedTradeSummary baseline;
      if(!m_executionService.TryGetPositionTradeSummary(m_positionState.positionId, baseline))
        {
         datetime now = FusionProtectionReliableTime();
         if(m_lastPartialBaselineWarning == 0 || now - m_lastPartialBaselineWarning >= 60)
           {
            m_lastPartialBaselineWarning = now;
            m_logger.Warn("PARTIAL", PartialLevelName(level) +
                          " adiado: historico da posicao indisponivel para criar uma linha de base segura.");
           }
         return false;
        }

      m_positionState.partialClosePending = true;
      m_positionState.pendingPartialLevel = level;
      m_positionState.pendingPartialInitialVolume = m_positionState.volume;
      m_positionState.pendingPartialRequestedVolume = volume;
      m_positionState.pendingPartialBaselineExitVolume = baseline.exitVolume;
      m_positionState.pendingPartialPreProjectedProfit =
         m_protectionManager.DailyClosedProfit() + floatingProfit;
      m_positionState.pendingPartialFloatingReferenceSet = false;
      m_positionState.pendingPartialFloatingReference = 0.0;
      m_positionState.pendingPartialOrderTicket = 0;
      m_positionState.pendingPartialDealTicket = 0;
      m_positionState.pendingPartialRetcode = 0;
      m_positionState.pendingPartialSince = FusionProtectionReliableTime();
      m_pendingPartialForceCloseWaitLogged = false;

      if(!PersistChartState())
        {
         ClearPendingPartialClose(m_positionState);
         m_logger.Error("PARTIAL", PartialLevelName(level) +
                        " nao foi enviado porque a intencao nao pode ser persistida com seguranca.");
         return false;
        }

      ulong orderTicket = 0;
      ulong dealTicket = 0;
      uint retcode = 0;
      if(!m_executionService.PartialClose(m_positionState,
                                          volume,
                                          reason,
                                          orderTicket,
                                          dealTicket,
                                          retcode))
        {
         ClearPendingPartialClose(m_positionState);
         PersistChartState();
         return false;
        }

      m_positionState.pendingPartialOrderTicket = orderTicket;
      m_positionState.pendingPartialDealTicket = dealTicket;
      m_positionState.pendingPartialRetcode = retcode;

      m_logger.Trade("PARTIAL", PartialLevelName(level) +
                     " solicitado; aguardando deal confirmado antes de atualizar DAY/DD.");
      PersistChartState();
      ReconcileOpenPositionPartials(true, false);
      return true;
     }

   void                    ResetDailyHistoryAudit(void)
     {
      m_dailyHistoryAuditPending = false;
      m_nextDailyHistoryAuditAttempt = 0;
      m_dailyHistoryAuditWaitLogged = false;
     }

   string                  DailyHistoryAuditNotice(void) const
     {
      return "Aguardando conferencia do historico diario.";
     }

   void                    ApplyDailyHistoryAuditBlock(void)
     {
      ApplyEntryBlockNotice(DailyHistoryAuditNotice());
     }

   void                    ClearDailyHistoryAuditBlock(void)
     {
      if(m_entryBlockNoticeActive &&
         m_entryBlockNoticeReason == DailyHistoryAuditNotice())
         ClearEntryBlockNotice();
     }

#endif
