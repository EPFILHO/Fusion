#ifndef __FUSION_EA_APPLICATION_POSITION_SYNC_MQH__
#define __FUSION_EA_APPLICATION_POSITION_SYNC_MQH__

   void                    SyncPositionState(void)
     {
      if(m_closeReconciliationPending)
        {
         m_positionState = m_closeReconciliationState;
         bool positionRestored = m_executionService.SyncPosition(m_positionState);
         if(positionRestored &&
            m_positionState.positionId == m_closeReconciliationState.positionId)
           {
            m_logger.Info("CLOSE_SYNC", "Posicao reapareceu durante a reconciliacao; fechamento pendente cancelado.");
            ResetCloseReconciliation();
            ClearEntryBlockNotice();
            PersistChartState();
            return;
           }

         TryReconcileClosedPosition(false);
         return;
        }

      SPositionRuntimeState previous = m_positionState;
      m_executionService.SyncPosition(m_positionState);

      if(m_positionState.hasPosition)
         ClearStreakReleaseNotice();

      if(previous.hasPosition && !m_positionState.hasPosition)
         BeginCloseReconciliation(previous, false);
     }

   void                    BeginCloseReconciliation(const SPositionRuntimeState &closedState,const bool restored)
     {
      if(closedState.positionId == 0)
        {
         m_logger.Error("CLOSE_SYNC", "Posicao desapareceu sem identificador para reconciliar o historico.");
         return;
        }

      m_closeReconciliationPending = true;
      m_closeReconciliationState = closedState;
      m_nextCloseReconciliationAttempt = 0;
      m_closeReconciliationAttempts = 0;
      m_closeReconciliationWaitLogged = false;
      ResetPositionRuntimeState(m_positionState);

      RecordClosedStrategyBar(closedState.ownerStrategyId);
      // Consume signals accumulated while the position was open; pending reverse is stored separately.
      m_signalManager.PrimeEntryStates();
      ApplyEntryBlockNotice("Fechamento aguardando confirmacao completa do historico.");
      PersistChartState();

      if(restored)
         m_logger.Info("CLOSE_SYNC", "Fechamento pendente restaurado; conferindo o historico.");
      TryReconcileClosedPosition(true);
     }

   bool                    TryReconcileClosedPosition(const bool forceAttempt)
     {
      if(!m_closeReconciliationPending)
         return true;

      datetime now = FusionProtectionReliableTime();
      if(!forceAttempt && now < m_nextCloseReconciliationAttempt)
         return false;

      m_closeReconciliationAttempts++;
      int retrySeconds = (m_closeReconciliationAttempts <= 1) ? 1
                         : ((m_closeReconciliationAttempts <= 3) ? 2 : 5);
      m_nextCloseReconciliationAttempt = now + retrySeconds;

      SClosedTradeSummary summary;
      bool historyFound = m_executionService.GetClosedTradeSummary(m_closeReconciliationState.positionId, summary);
      if(!historyFound || !summary.complete)
        {
         if(!m_closeReconciliationWaitLogged)
           {
            string progress = (summary.entryVolume > 0.0)
                              ? StringFormat(" Volume de saida %.4f/%.4f.", summary.exitVolume, summary.entryVolume)
                              : "";
            m_logger.Info("CLOSE_SYNC", "Fechamento detectado; aguardando historico completo." + progress);
            m_closeReconciliationWaitLogged = true;
           }
         return false;
        }

      int closeDayKey = FusionProtectionCurrentDayKey(summary.lastExitTime);
      int currentDayKey = FusionProtectionCurrentDayKey();
      if(closeDayKey == currentDayKey)
         m_protectionManager.OnPositionClosed(summary.totalProfit,
                                              m_closeReconciliationState.realizedPartialProfit);
      else
        {
         m_pendingReverseExit.Reset();
         m_logger.Info("CLOSE_SYNC", "Fechamento reconciliado pertence a outro dia operacional; DAY/DD/STREAK atuais nao foram alterados.");
        }

      m_logger.Trade("CLOSE", "Posicao fechada. P/L bruto: " + DoubleToString(summary.totalProfit, 2));
      ResetCloseReconciliation();
      ResetPositionRuntimeState(m_positionState);
      ClearEntryBlockNotice();
      m_signalManager.PrimeEntryStates();
      PersistChartState();
      if(!m_started)
         ReleaseRunningInstance();
      return true;
     }

   bool                    TryAuditDailyHistory(const bool forceAttempt)
     {
      if(!m_dailyHistoryAuditPending || m_settings.isTester)
         return true;
      if(m_closeReconciliationPending)
         return false;

      datetime now = FusionProtectionReliableTime();
      if(!forceAttempt && now < m_nextDailyHistoryAuditAttempt)
         return false;
      m_nextDailyHistoryAuditAttempt = now + 5;

      if(!TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         ApplyDailyHistoryAuditBlock();
         if(!m_dailyHistoryAuditWaitLogged)
           {
            m_logger.Info("HISTORY", "Aguardando conexao para conferir o historico diario.");
            m_dailyHistoryAuditWaitLogged = true;
           }
         return false;
        }

      MqlDateTime dayParts;
      if(!TimeToStruct(now, dayParts))
        {
         ApplyDailyHistoryAuditBlock();
         return false;
        }
      dayParts.hour = 0;
      dayParts.min = 0;
      dayParts.sec = 0;
      datetime dayStart = StructToTime(dayParts);

      SDailyHistorySummary historySummary;
      if(!m_executionService.GetDailyHistorySummary(dayStart,
                                                    now,
                                                    FusionProtectionCurrentDayKey(now),
                                                    historySummary) ||
         !historySummary.complete)
        {
         ApplyDailyHistoryAuditBlock();
         if(!m_dailyHistoryAuditWaitLogged)
           {
            m_logger.Info("HISTORY", "Historico diario ainda incompleto; nova conferencia sera feita automaticamente.");
            m_dailyHistoryAuditWaitLogged = true;
           }
         return false;
        }

      SDailyLimitsRuntimeState dailyState;
      ResetDailyLimitsRuntimeState(dailyState);
      m_protectionManager.ExportDailyLimitsState(dailyState);
      double previousProfit = dailyState.dailyClosedProfit;
      int previousTrades = dailyState.dailyTradeCount;
      int previousLossStreak = m_protectionManager.LossStreak();
      int previousWinStreak = m_protectionManager.WinStreak();

      bool persistedHasActivity = (previousTrades > 0 ||
                                   MathAbs(previousProfit) > 0.005 ||
                                   previousLossStreak > 0 ||
                                   previousWinStreak > 0);
      bool historyHasActivity = (historySummary.tradeCount > 0 ||
                                 MathAbs(historySummary.closedProfit) > 0.005);
      if((persistedHasActivity && !historyHasActivity) ||
         historySummary.tradeCount < previousTrades)
        {
         ApplyDailyHistoryAuditBlock();
         if(!m_dailyHistoryAuditWaitLogged)
           {
            m_logger.Info("HISTORY", "Historico contradiz o estado salvo; aguardando nova conferencia.");
            m_dailyHistoryAuditWaitLogged = true;
           }
         return false;
        }

      bool changed = (MathAbs(previousProfit - historySummary.closedProfit) > 0.005 ||
                      previousTrades != historySummary.tradeCount ||
                      dailyState.dailyLossCount != historySummary.lossCount ||
                      dailyState.dailyWinCount != historySummary.winCount ||
                      dailyState.dailyBreakevenCount != historySummary.breakevenCount ||
                      !dailyState.outcomeCountsKnown ||
                      previousLossStreak != historySummary.lossStreak ||
                      previousWinStreak != historySummary.winStreak);

      dailyState.dayKey = historySummary.dayKey;
      dailyState.dailyClosedProfit = historySummary.closedProfit;
      dailyState.dailyTradeCount = historySummary.tradeCount;
      dailyState.dailyLossCount = historySummary.lossCount;
      dailyState.dailyWinCount = historySummary.winCount;
      dailyState.dailyBreakevenCount = historySummary.breakevenCount;
      dailyState.outcomeCountsKnown = true;
      m_protectionManager.ImportDailyLimitsState(dailyState);
      m_protectionManager.ReconcileStreakCounts(historySummary.lossStreak,
                                                 historySummary.winStreak);
      m_protectionManager.ReconcileDrawdownProfit(historySummary.closedProfit);
      ReconcileOpenPositionPartials(false, true);

      m_dailyHistoryAuditPending = false;
      m_nextDailyHistoryAuditAttempt = 0;
      ClearDailyHistoryAuditBlock();
      if(changed)
        {
         m_logger.Info("HISTORY",
                       "Historico diario reconciliado: P/L bruto " +
                       DoubleToString(previousProfit, 2) + " -> " +
                       DoubleToString(historySummary.closedProfit, 2) +
                       "; trades " + IntegerToString(previousTrades) + " -> " +
                       IntegerToString(historySummary.tradeCount) + ".");
         PersistChartState();
        }
      return true;
     }

   bool                    LastActivePartialTPExecuted(void) const
     {
      if(!m_settings.usePartialTP || !m_positionState.tp1Executed)
         return false;
      if(m_positionState.tp2Volume > 0.0 && m_positionState.tp2Price > 0.0)
         return m_positionState.tp2Executed;
      return true;
     }

   bool                    TryRemoveFreeFinalTakeProfit(void)
     {
      if(!m_settings.usePartialTP || !m_settings.freeFinalTP || !m_settings.useTrailing)
         return false;
      if(!LastActivePartialTPExecuted() || !m_positionState.trailingActive)
         return false;
      if(m_positionState.takeProfit <= 0.0)
         return false;

      double oldTP = m_positionState.takeProfit;
      if(m_executionService.ModifyStops(m_positionState, m_positionState.stopLoss, 0.0))
        {
         int digits = SymbolSpec().digits;
         m_logger.Trade("RISK", "TP Final Livre ativado apos parcial. TP final removido " + DoubleToString(oldTP, digits) + " -> 0");
         return true;
        }

      if(!m_executionService.LastModifySkippedByFreeze() &&
         !m_executionService.LastModifySkippedByStopsLevel())
         m_logger.Warn("RISK", "TP Final Livre: falha ao remover TP final apos parcial.");
      return false;
     }

#endif
