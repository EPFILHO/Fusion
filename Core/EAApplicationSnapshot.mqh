#ifndef __FUSION_EA_APPLICATION_SNAPSHOT_MQH__
#define __FUSION_EA_APPLICATION_SNAPSHOT_MQH__

   SUIPanelSnapshot        BuildPanelSnapshot(void) const
     {
      SUIPanelSnapshot snapshot;
      snapshot.settings         = m_settings;
      snapshot.started          = m_started;
      snapshot.hasPosition      = HasManagedOrPendingPosition();
      snapshot.activeProfileName= m_activeProfileName;
      snapshot.symbol           = (m_chartContext.symbol == "" ? _Symbol : m_chartContext.symbol);
      snapshot.timeframe        = OperationalTimeframesSummary();
      snapshot.symbolSpec       = SymbolSpec();
      snapshot.magicNumber      = m_settings.magicNumber;
      snapshot.activeStrategies = m_signalManager.ActiveStrategyCount();
      snapshot.activeFilters    = m_signalManager.ActiveFilterCount();
      snapshot.conflictMode     = m_settings.conflictMode;
      snapshot.fixedLot         = m_settings.fixedLot;
      snapshot.maxSpreadPoints  = m_settings.maxSpreadPoints;
      snapshot.ownerStrategyName= m_closeReconciliationPending
                                  ? m_closeReconciliationState.ownerStrategyName
                                  : m_positionState.ownerStrategyName;
      snapshot.useMACross       = m_settings.useMACross;
      snapshot.useRSI           = m_settings.useRSI;
      snapshot.useBollinger     = m_settings.useBollinger;
      snapshot.useTrendFilter   = m_settings.useTrendFilter;
      snapshot.useRSIFilter     = m_settings.useRSIFilter;
      snapshot.bbFilterEnabled  = m_settings.bbFilterEnabled;
      snapshot.runtimeBlocked   = m_runtimeBlocked;
      snapshot.runtimeBlockReason = m_runtimeBlockReason;
      snapshot.startBlockedReason = m_startBlockedReason;
      snapshot.activeProfileBlockedReason = m_activeProfileBlockedReason;
      snapshot.runtimeNotice    = m_runtimeNotice;
      snapshot.entryBlockReason = m_entryBlockNoticeActive ? m_entryBlockNoticeReason : "";
      snapshot.entryBlockIsRiskStops = (m_entryBlockNoticeActive &&
                                        m_entryBlockNoticeIsRiskStops);
      snapshot.entryBlockDetail = snapshot.entryBlockIsRiskStops
                                  ? m_entryBlockNoticeDetail : "";
      snapshot.pendingReverseExit = m_pendingReverseExit.HasPending();
      snapshot.tradePermissionBlocked = m_tradePermissionGuard.IsBlocked();
      snapshot.tradePermissionReason = m_tradePermissionGuard.Notice();
      snapshot.dailyTradeCount  = m_protectionManager.DailyTradeCount();
      snapshot.dailyLossCount   = m_protectionManager.DailyLossCount();
      snapshot.dailyWinCount    = m_protectionManager.DailyWinCount();
      snapshot.dailyBreakevenCount = m_protectionManager.DailyBreakevenCount();
      snapshot.dailyOutcomeCountsKnown = m_protectionManager.DailyOutcomeCountsKnown();
      snapshot.dailyClosedProfit = m_protectionManager.DailyClosedProfit();
      double snapshotFloatingProfit = 0.0;
      if(m_positionState.hasPosition && PositionSelectByTicket(m_positionState.ticket))
         snapshotFloatingProfit = PositionGetDouble(POSITION_PROFIT);
      double snapshotProjectedProfit = EffectiveProjectedProfit(snapshotFloatingProfit);
      snapshot.dailyFloatingProfit = snapshotFloatingProfit;
      snapshot.dailyProjectedProfit = snapshotProjectedProfit;
      snapshot.partialReconciliationPending = m_positionState.partialClosePending;
      string dailyBlockReason = "";
      snapshot.dailyLimitsBlocked = m_protectionManager.IsDailyLimitsBlocked(dailyBlockReason);
      snapshot.dailyLimitsBlockReason = dailyBlockReason;
      string sessionBlockReason = "";
      snapshot.sessionProtectionBlocked = false;
      snapshot.sessionProtectionBlockReason = "";
      if(m_settings.enableSessionFilter)
        {
         snapshot.sessionProtectionBlocked = m_protectionManager.IsSessionProtectionBlocked(sessionBlockReason);
         snapshot.sessionProtectionBlockReason = sessionBlockReason;
        }
      string newsBlockReason = "";
      snapshot.newsProtectionBlocked = false;
      snapshot.newsProtectionBlockReason = "";
      if(HasEnabledNewsWindow(m_settings))
        {
         snapshot.newsProtectionBlocked = m_protectionManager.IsNewsProtectionBlocked(newsBlockReason);
         snapshot.newsProtectionBlockReason = newsBlockReason;
        }
      snapshot.lossStreak       = m_protectionManager.LossStreak();
      snapshot.winStreak        = m_protectionManager.WinStreak();
      string streakBlockReason = "";
      snapshot.streakProtectionBlocked = m_protectionManager.IsStreakProtectionBlocked(streakBlockReason);
      snapshot.streakProtectionBlockReason = streakBlockReason;
      string drawdownLockReason = "";
      snapshot.drawdownProtectionActive = m_protectionManager.IsDrawdownProtectionActive();
      snapshot.drawdownLimitReached = m_protectionManager.IsDrawdownLimitReached();
      snapshot.drawdownConfigLocked = m_protectionManager.IsDrawdownConfigLocked(drawdownLockReason);
      snapshot.drawdownConfigLockReason = drawdownLockReason;
      snapshot.drawdownPeakProfit = m_protectionManager.DrawdownPeakProfit();
      snapshot.drawdownFloorProfit = m_protectionManager.DrawdownFloorProfit();
      snapshot.drawdownBufferProfit = m_protectionManager.DrawdownBufferProfit(snapshotProjectedProfit);
      snapshot.drawdownTriggerProfit = m_protectionManager.DrawdownTriggerProfit();
      snapshot.drawdownTriggerDrawdown = m_protectionManager.DrawdownTriggerDrawdown();
      snapshot.drawdownTriggerBuffer = m_protectionManager.DrawdownTriggerBuffer();
      return snapshot;
     }

   bool                    PersistChartState(void)
     {
      return PersistChartState(-1);
     }

   bool                    PersistChartState(const int deinitReason)
     {
      if(m_settings.isTester)
         return true;

      SChartStateContext context = CurrentChartContext();
      context.deinitReason = deinitReason;
      context.discardedUnsavedDraft = (deinitReason == REASON_CHARTCHANGE &&
                                       m_panel.HasUnsavedDraftChanges());
      if(m_chartContext.chartId != 0)
        {
         context.chartId = m_chartContext.chartId;
         if(m_runtimeBlocked && m_chartContext.symbol != "")
            context.symbol = m_chartContext.symbol;
         if(m_runtimeBlocked && m_chartContext.timeframe != "")
            context.timeframe = m_chartContext.timeframe;
         if(m_runtimeBlocked && m_chartContext.periodValue > 0)
            context.periodValue = m_chartContext.periodValue;
        }

      SStreakRuntimeState streakState;
      SDailyLimitsRuntimeState dailyState;
      SDrawdownRuntimeState drawdownState;
      ResetStreakRuntimeState(streakState);
      ResetDailyLimitsRuntimeState(dailyState);
      ResetDrawdownRuntimeState(drawdownState);
      m_protectionManager.ExportStreakState(streakState);
      m_protectionManager.ExportDailyLimitsState(dailyState);
      m_protectionManager.ExportDrawdownState(drawdownState);
      SPositionRuntimeState stateToPersist = m_closeReconciliationPending
                                             ? m_closeReconciliationState
                                             : m_positionState;
      bool saved = m_settingsStore.SaveChartState(context,
                                                   m_activeProfileName,
                                                   m_started,
                                                   m_settings,
                                                   stateToPersist,
                                                   streakState,
                                                   dailyState,
                                                   drawdownState);
      if(!saved)
         m_logger.Error("PERSIST", "Falha ao salvar o estado operacional do grafico.");
      return saved;
     }

#endif
