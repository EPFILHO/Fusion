#ifndef __FUSION_APPLICATION_MQH__
#define __FUSION_APPLICATION_MQH__

#include "Inputs.mqh"
#include "Logger.mqh"
#include "TradePermissionGuard.mqh"
#include "PendingReverseExit.mqh"
#include "InstanceRegistry.mqh"
#include "ActiveProfileRegistry.mqh"
#include "../Signals/SignalManager.mqh"
#include "../Signals/Resolvers/PriorityConflictResolver.mqh"
#include "../Signals/Resolvers/CancelConflictResolver.mqh"
#include "../Strategies/Implementations/MACrossStrategy.mqh"
#include "../Strategies/Implementations/RSIStrategy.mqh"
#include "../Strategies/Implementations/BollingerStrategy.mqh"
#include "../Filters/Implementations/TrendFilter.mqh"
#include "../Filters/Implementations/RSIFilter.mqh"
#include "../Filters/Implementations/BollingerFilter.mqh"
#include "../Risk/RiskManager.mqh"
#include "../Protection/ProtectionManager.mqh"
#include "../Normalization/SymbolNormalizer.mqh"
#include "../Execution/ExecutionService.mqh"
#include "../Persistence/SettingsStore.mqh"
#include "../UI/UIPanel.mqh"
#include "../UI/ChartIndicatorVisualizer.mqh"

class CFusionApplication
  {
private:
   SEASettings             m_settings;
   CLogger                 m_logger;
   CSignalManager          m_signalManager;
   CPriorityConflictResolver m_priorityResolver;
   CCancelConflictResolver m_cancelResolver;
   CMACrossStrategy        m_maStrategy;
   CRSIStrategy            m_rsiStrategy;
   CBollingerStrategy      m_bbStrategy;
   CTrendFilter            m_trendFilter;
   CRSIFilter              m_rsiFilter;
   CBollingerFilter        m_bbFilter;
   CRiskManager            m_riskManager;
   CProtectionManager      m_protectionManager;
   CSymbolNormalizer       m_normalizer;
   CExecutionService       m_executionService;
   CSettingsStore          m_settingsStore;
   CInstanceRegistry       m_instanceRegistry;
   CActiveProfileRegistry  m_activeProfileRegistry;
   CTradePermissionGuard   m_tradePermissionGuard;
   CPendingReverseExit     m_pendingReverseExit;
   CChartIndicatorVisualizer m_chartIndicators;
   CFusionPanel            m_panel;
   SPositionRuntimeState   m_positionState;
   SChartStateContext      m_chartContext;
   string                  m_activeProfileName;
   bool                    m_started;
   bool                    m_modulesRegistered;
   datetime                m_lastNettingWarning;
   bool                    m_runtimeBlocked;
   string                  m_runtimeBlockReason;
   string                  m_startBlockedReason;
   string                  m_activeProfileBlockedReason;
   string                  m_runtimeNotice;
   bool                    m_protectionNoticeActive;
   string                  m_protectionNoticeReason;
   bool                    m_entryBlockNoticeActive;
   string                  m_entryBlockNoticeReason;
   bool                    m_entryBlockNoticeIsRiskStops;
   string                  m_entryBlockNoticeDetail;
   string                  m_lastClosedStrategyId;
   datetime                m_lastClosedStrategyBarTime;
   string                  m_lastDiscardDebugReason;
   datetime                m_lastDiscardDebugTime;
   string                  m_lastPersistentProtectWarnReason;
   int                     m_lastPersistentProtectWarnDayKey;
   bool                    m_closeReconciliationPending;
   SPositionRuntimeState   m_closeReconciliationState;
   datetime                m_nextCloseReconciliationAttempt;
   int                     m_closeReconciliationAttempts;
   bool                    m_closeReconciliationWaitLogged;
   bool                    m_dailyHistoryAuditPending;
   datetime                m_nextDailyHistoryAuditAttempt;
   bool                    m_dailyHistoryAuditWaitLogged;
   bool                    m_pendingPartialForceCloseWaitLogged;
   datetime                m_lastPartialBaselineWarning;
   uint                    m_lastLivePanelRefreshTick;

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

   bool                    HasManagedOrPendingPosition(void) const
     {
      return (m_positionState.hasPosition || m_closeReconciliationPending);
     }

   void                    ResetTransientRuntimeState(void)
     {
      m_runtimeBlocked      = false;
      m_runtimeBlockReason  = "";
      m_startBlockedReason  = "";
      m_activeProfileBlockedReason = "";
      m_runtimeNotice       = "";
      m_protectionNoticeActive = false;
      m_protectionNoticeReason = "";
      m_entryBlockNoticeActive = false;
      m_entryBlockNoticeReason = "";
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";
      m_lastDiscardDebugReason = "";
      m_lastDiscardDebugTime = 0;
      m_lastPersistentProtectWarnReason = "";
      m_lastPersistentProtectWarnDayKey = 0;
      m_pendingPartialForceCloseWaitLogged = false;
      m_lastPartialBaselineWarning = 0;
      m_lastLivePanelRefreshTick = 0;
     }

   SChartStateContext      CurrentChartContext(void) const
     {
      SChartStateContext context;
      context.chartId   = (ulong)ChartID();
      context.symbol    = _Symbol;
      context.timeframe = EnumToString((ENUM_TIMEFRAMES)Period());
      context.periodValue = (int)Period();
      context.deinitReason = -1;
      context.discardedUnsavedDraft = false;
      return context;
     }

   bool                    RegisterRunningInstance(void)
     {
      if(m_settings.isTester)
         return true;

      string reason = "";
      if(m_instanceRegistry.Register(_Symbol, m_settings.magicNumber, ChartID(), reason))
         return true;

      m_startBlockedReason = reason + " Carregue outro perfil antes de iniciar.";
      m_logger.Error("INSTANCE", reason);
      return false;
     }

   void                    ReleaseRunningInstance(void)
     {
      if(!m_settings.isTester)
         m_instanceRegistry.Unregister();
     }

   bool                    IsNettingAccount(void) const
     {
      ENUM_ACCOUNT_MARGIN_MODE mode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
      return (mode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
     }

   bool                    HasForeignNettingPosition(string &reason) const
     {
      reason = "";
      if(!IsNettingAccount())
         return false;

      for(int i = PositionsTotal() - 1; i >= 0; --i)
        {
         if(PositionGetSymbol(i) != _Symbol)
            continue;

         int positionMagic = (int)PositionGetInteger(POSITION_MAGIC);
         if(positionMagic == m_settings.magicNumber)
            continue;

         reason = "Conta netting/exchange: existe posicao em " + _Symbol +
                  " com Magic " + IntegerToString(positionMagic) +
                  " fora do perfil atual.";
         return true;
        }

      return false;
     }

   void                    LogNettingWarning(const string reason)
     {
      datetime now = TimeCurrent();
      if(now - m_lastNettingWarning < 60)
         return;

      m_logger.Warn("NETTING", reason);
      m_lastNettingWarning = now;
     }

   bool                    CanPersistProfile(const string profileName,const SEASettings &settings) const
     {
      string conflictProfile = "";
      if(!m_settingsStore.FindProfileByMagicNumber(settings.magicNumber, profileName, conflictProfile))
         return true;

      m_logger.Error("PROFILE", "Magic " + IntegerToString(settings.magicNumber) +
                              " ja esta em uso pelo perfil " + conflictProfile + ".");
      return false;
     }

   void                    ConfigureResolver(void)
     {
      if(m_settings.conflictMode == CONFLICT_PRIORITY)
         m_signalManager.SetResolver(&m_priorityResolver);
      else
         m_signalManager.SetResolver(&m_cancelResolver);
     }

   bool                    IsVisualTester(void) const
     {
      return (bool)MQLInfoInteger(MQL_VISUAL_MODE);
     }

   bool                    ShouldShowPanel(void) const
     {
      if(m_settings.isTester)
         return IsVisualTester();
      return m_settings.panelEnabled;
     }

   void                    UpdatePanelIfVisible(void)
     {
      if(ShouldShowPanel())
         m_panel.Update(BuildPanelSnapshot());
     }

   void                    ReloadPanelSettingsIfVisible(void)
     {
      if(!ShouldShowPanel())
         return;

      m_panel.LoadSettings(m_settings, m_activeProfileName, SymbolSpec());
      m_panel.Update(BuildPanelSnapshot());
     }

   void                    RegisterModules(void)
     {
      if(m_modulesRegistered)
         return;

      m_signalManager.AddStrategy(&m_maStrategy);
      m_signalManager.AddStrategy(&m_rsiStrategy);
      m_signalManager.AddStrategy(&m_bbStrategy);
      m_signalManager.AddFilter(&m_trendFilter);
      m_signalManager.AddFilter(&m_rsiFilter);
      m_signalManager.AddFilter(&m_bbFilter);
      m_modulesRegistered = true;
     }

   string                  ShortTimeframeName(const ENUM_TIMEFRAMES timeframe) const
     {
      string name = EnumToString(timeframe);
      const string prefix = "PERIOD_";
      if(StringFind(name, prefix) == 0)
         return StringSubstr(name, StringLen(prefix));
      return name;
     }

   string                  OperationalTimeframesSummary(void) const
     {
      string summary = "";

      if(m_settings.useMACross)
        {
         string fastTimeframe = ShortTimeframeName(m_settings.maFastTimeframe);
         string slowTimeframe = ShortTimeframeName(m_settings.maSlowTimeframe);
         summary = "MA " + fastTimeframe;
         if(slowTimeframe != fastTimeframe)
            summary += "/" + slowTimeframe;
        }

      if(m_settings.useRSI)
        {
         if(summary != "")
            summary += " | ";
         summary += "RSI " + ShortTimeframeName(m_settings.rsiTimeframe);
        }

      if(m_settings.useBollinger)
        {
         if(summary != "")
            summary += " | ";
         summary += "BB " + ShortTimeframeName(m_settings.bbTimeframe);
        }

      return (summary == "" ? "--" : summary);
     }

   void                    RecoverLegacyDailyOutcomeCounts(SDailyLimitsRuntimeState &dailyState,
                                                            const SStreakRuntimeState &streakState) const
     {
      if(dailyState.outcomeCountsKnown)
         return;

      if(dailyState.dailyTradeCount <= 0)
        {
         dailyState.dailyLossCount = 0;
         dailyState.dailyWinCount = 0;
         dailyState.dailyBreakevenCount = 0;
         dailyState.outcomeCountsKnown = true;
         return;
        }

      if(dailyState.dayKey != streakState.dayKey ||
         streakState.lossStreak < 0 ||
         streakState.winStreak < 0 ||
         streakState.lossStreak + streakState.winStreak != dailyState.dailyTradeCount)
         return;

      dailyState.dailyLossCount = streakState.lossStreak;
      dailyState.dailyWinCount = streakState.winStreak;
      dailyState.dailyBreakevenCount = 0;
      dailyState.outcomeCountsKnown = true;
     }

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

   void                    ApplyRuntimeBlock(const string reason)
     {
      m_runtimeBlocked = true;
      m_runtimeBlockReason = reason;
      m_started = false;
     }

   void                    ApplyRuntimeNotice(const string notice)
     {
      m_runtimeNotice = notice;
     }

   bool                    IsSessionProtectionNotice(const string notice) const
     {
      return (notice == "Fora da janela de sessao." || notice == "Sessao encerrada.");
     }

   bool                    IsNewsProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Janela de news ") == 0);
     }

   bool                    HasEnabledNewsWindow(const SEASettings &settings) const
     {
      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
         if(settings.newsWindows[newsIndex].enabled)
            return true;
      return false;
     }

   bool                    ProtectionNoticeAllowedBySettings(const string notice,const SEASettings &settings) const
     {
      if(IsSessionProtectionNotice(notice))
         return settings.enableSessionFilter;
      if(IsNewsProtectionNotice(notice))
         return HasEnabledNewsWindow(settings);
      return true;
     }

   void                    ClearProtectionNoticeDisabledBySettings(void)
     {
      if(m_protectionNoticeActive &&
         !ProtectionNoticeAllowedBySettings(m_protectionNoticeReason, m_settings))
        {
         m_protectionNoticeActive = false;
         m_protectionNoticeReason = "";
        }

      if(m_runtimeNotice != "" &&
         !ProtectionNoticeAllowedBySettings(m_runtimeNotice, m_settings))
        {
         m_runtimeNotice = m_tradePermissionGuard.IsBlocked() ? m_tradePermissionGuard.Notice() : "";
        }
     }

   bool                    IsSpreadProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por Spread:") == 0);
     }

   bool                    IsStreakPauseProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por ") == 0 &&
              StringFind(notice, " streak em pausa (") > 0);
     }

   bool                    IsStreakProtectionNotice(const string notice) const
     {
      return (StringFind(notice, "Bloqueio por loss streak") == 0 ||
              StringFind(notice, "Bloqueio por win streak") == 0);
     }

   bool                    IsPersistentDailyProtectionNotice(const string notice) const
     {
      return (notice == "Limite de drawdown diario atingido." ||
              notice == "Limite diario de trades atingido." ||
              notice == "Limite diario de perda atingido." ||
              notice == "Limite diario de perda projetada atingido." ||
              notice == "Meta diaria de ganho atingida.");
     }

   int                     ProtectionWarnDayKey(void) const
     {
      return FusionProtectionCurrentDayKey();
     }

   bool                    SameStreakPauseProtectionNotice(const string previous,const string current) const
     {
      if(!IsStreakPauseProtectionNotice(previous) || !IsStreakPauseProtectionNotice(current))
         return false;

      int previousOpen = StringFind(previous, "(");
      int currentOpen = StringFind(current, "(");
      if(previousOpen <= 0 || currentOpen <= 0)
         return false;

      return (StringSubstr(previous, 0, previousOpen) == StringSubstr(current, 0, currentOpen));
     }

   int                     StreakPauseMinutesFromNotice(const string notice) const
     {
      int open = StringFind(notice, "(");
      if(open < 0)
         return 0;

      int marker = StringFind(notice, " min", open);
      if(marker <= open)
         return 0;

      return (int)StringToInteger(StringSubstr(notice, open + 1, marker - open - 1));
     }

   bool                    ShouldLogStreakPauseNotice(const string notice,const bool firstNotice) const
     {
      if(firstNotice)
         return true;

      int minutesLeft = StreakPauseMinutesFromNotice(notice);
      if(minutesLeft <= 0)
         return false;
      if(minutesLeft <= 5)
         return true;
      if(minutesLeft < 30)
         return ((minutesLeft % 10) == 0);
      return ((minutesLeft % 30) == 0);
     }

   bool                    ShouldLogProtectionNotice(const string notice,const bool firstNotice)
     {
      if(IsStreakPauseProtectionNotice(notice))
         return ShouldLogStreakPauseNotice(notice, firstNotice);

      if(IsPersistentDailyProtectionNotice(notice))
        {
         int dayKey = ProtectionWarnDayKey();
         if(m_lastPersistentProtectWarnReason == notice &&
            m_lastPersistentProtectWarnDayKey == dayKey)
            return false;

         m_lastPersistentProtectWarnReason = notice;
         m_lastPersistentProtectWarnDayKey = dayKey;
         return true;
        }

      return true;
     }

   bool                    ShouldLogDiscardedSignalDebug(const string reason)
     {
      if(reason == "")
         return false;
      if(IsStreakProtectionNotice(reason))
         return false;

      datetime now = TimeCurrent();
      if(now <= 0)
         now = TimeLocal();

      if(reason != m_lastDiscardDebugReason ||
         m_lastDiscardDebugTime <= 0 ||
         now - m_lastDiscardDebugTime >= 60)
        {
         m_lastDiscardDebugReason = reason;
         m_lastDiscardDebugTime = now;
         return true;
        }

      return false;
     }

   void                    LogProtectionNoticeCleared(const string notice)
     {
      if(IsSessionProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de sessao removido.");
         return;
        }

      if(IsNewsProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de news removido: " + notice);
         return;
        }

      if(IsStreakProtectionNotice(notice))
        {
         m_logger.Info("PROTECT", "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.");
         return;
        }
     }

   bool                    IsStreakReleaseNotice(const string notice) const
     {
      return (notice == "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.");
     }

   void                    ClearStreakReleaseNotice(void)
     {
      if(IsStreakReleaseNotice(m_runtimeNotice))
         m_runtimeNotice = "";
     }

   bool                    ClearProtectionNotice(const bool announceRelease=false)
     {
      if(!m_protectionNoticeActive)
         return false;

      bool releasedStreak = IsStreakProtectionNotice(m_protectionNoticeReason);
      if(announceRelease)
         LogProtectionNoticeCleared(m_protectionNoticeReason);
      m_protectionNoticeActive = false;
      m_protectionNoticeReason = "";
      if(m_tradePermissionGuard.IsBlocked())
         m_runtimeNotice = m_tradePermissionGuard.Notice();
      else if(announceRelease && releasedStreak)
         m_runtimeNotice = "Bloqueio de streak liberado. EA aguarda novo sinal de entrada.";
      else
         m_runtimeNotice = "";
      return (announceRelease && releasedStreak);
     }

   void                    ApplyProtectionNotice(const string notice,const bool allowLog=true,const bool forceLog=false)
     {
      if(notice == "")
        {
         ClearProtectionNotice();
         return;
        }

      bool firstNotice = (!m_protectionNoticeActive ||
                          (IsStreakPauseProtectionNotice(notice) &&
                           !SameStreakPauseProtectionNotice(m_protectionNoticeReason, notice)));
      bool changed = (!m_protectionNoticeActive || m_protectionNoticeReason != notice);
      if(changed && m_protectionNoticeActive && !IsStreakProtectionNotice(m_protectionNoticeReason))
         LogProtectionNoticeCleared(m_protectionNoticeReason);

      m_protectionNoticeActive = true;
      m_protectionNoticeReason = notice;
      if(!m_tradePermissionGuard.IsBlocked())
         m_runtimeNotice = notice;

      if(allowLog && (changed || forceLog) && ShouldLogProtectionNotice(notice, firstNotice))
        {
         m_logger.Warn("PROTECT", notice);
        }
     }

   void                    ClearEntryBlockNotice(void)
     {
      if(!m_entryBlockNoticeActive)
         return;

      m_entryBlockNoticeActive = false;
      m_entryBlockNoticeReason = "";
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";
     }

   bool                    MaintainOperationalDayState(void)
     {
      if(!m_protectionManager.MaintainOperationalDay(m_positionState))
         return false;

      if(IsPersistentDailyProtectionNotice(m_protectionNoticeReason) ||
         IsStreakProtectionNotice(m_protectionNoticeReason))
         ClearProtectionNotice();
      if(IsPersistentDailyProtectionNotice(m_runtimeNotice) ||
         IsStreakProtectionNotice(m_runtimeNotice))
         m_runtimeNotice = "";

      m_lastPersistentProtectWarnReason = "";
      m_lastPersistentProtectWarnDayKey = 0;
      if(m_positionState.partialClosePending &&
         PositionSelectByTicket(m_positionState.ticket))
        {
         double currentFloating = PositionGetDouble(POSITION_PROFIT);
         m_positionState.pendingPartialPreProjectedProfit =
            m_protectionManager.DailyClosedProfit() + currentFloating;
         if(m_positionState.pendingPartialFloatingReferenceSet)
            m_positionState.pendingPartialFloatingReference = currentFloating;
        }
      if(m_started && !m_positionState.hasPosition)
         m_signalManager.PrimeEntryStates();

      m_logger.Info("PROTECT", "Novo dia operacional: estados DAY/DD/STREAK resetados.");
      PersistChartState();
      return true;
     }

   void                    DiscardBlockedEntrySignals(const string reason)
     {
      if(!m_started || m_positionState.hasPosition)
         return;

      m_signalManager.PrimeEntryStates();
      if(ShouldLogDiscardedSignalDebug(reason))
         m_logger.Debug("SIGNAL", "Sinais descartados durante bloqueio: " + reason);
     }

   void                    ApplyEntryBlockNotice(const string reason)
     {
      if(reason == "")
        {
         ClearEntryBlockNotice();
         return;
        }

      bool changed = (!m_entryBlockNoticeActive || m_entryBlockNoticeReason != reason);
      m_entryBlockNoticeActive = true;
      m_entryBlockNoticeReason = reason;
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";

      if(changed)
         m_logger.Info("SIGNAL", reason);
     }

   void                    ApplyRiskStopsEntryBlockNotice(const string reason,
                                                         const string detail)
     {
      if(reason == "")
        {
         ClearEntryBlockNotice();
         return;
        }

      m_entryBlockNoticeActive = true;
      m_entryBlockNoticeReason = reason;
      m_entryBlockNoticeIsRiskStops = true;
      m_entryBlockNoticeDetail = detail;
     }

   string                  FormatDirectionBlockReason(const SSignalDecision &decision,const string reason) const
     {
      string strategyName = (decision.strategyName != "") ? decision.strategyName : decision.shortName;
      string text = "Entrada " + SignalToString(decision.signal);
      if(strategyName != "")
         text += " da " + strategyName;
      text += " bloqueada por Direcao";
      if(reason != "")
         text += ": " + reason;
      return text;
     }

   bool                    RefreshTradePermissionState(void)
     {
      bool wasBlocked = m_tradePermissionGuard.IsBlocked();
      if(m_tradePermissionGuard.Refresh(m_positionState.hasPosition))
        {
         if(wasBlocked)
            m_runtimeNotice = m_protectionNoticeActive ? m_protectionNoticeReason : "";
         return true;
        }

      m_runtimeNotice = m_tradePermissionGuard.Notice();
      if(m_started && !m_positionState.hasPosition)
        {
         // Trading permission can disappear briefly during broker reconnects.
         // Keep the EA running so it resumes automatically when permissions return.
         m_pendingReverseExit.Reset();
        }
      return false;
     }

   void                    RecordClosedStrategyBar(const string strategyId)
     {
      m_lastClosedStrategyId = strategyId;
      m_lastClosedStrategyBarTime = 0;

      if(strategyId == "")
         return;

      ENUM_TIMEFRAMES timeframe = FUSION_DEFAULT_TIMEFRAME;
      if(!m_signalManager.GetStrategyReferenceTimeframe(strategyId, timeframe))
         return;

      m_lastClosedStrategyBarTime = iTime(_Symbol, timeframe, 0);
     }

   bool                    IsReentryBlockedThisBar(const string strategyId,string &reason)
     {
      reason = "";

      if(strategyId == "" || strategyId != m_lastClosedStrategyId || m_lastClosedStrategyBarTime <= 0)
         return false;

      ENUM_TIMEFRAMES timeframe = FUSION_DEFAULT_TIMEFRAME;
      if(!m_signalManager.GetStrategyReferenceTimeframe(strategyId, timeframe))
         return false;

      datetime currentBarTime = iTime(_Symbol, timeframe, 0);
      if(currentBarTime != m_lastClosedStrategyBarTime)
         return false;

      reason = "Ja operou neste candle da estrategia - aguardando proximo.";
      return true;
     }

   void                    RefreshStartBlockReason(void)
     {
      m_startBlockedReason = "";
      if(m_settings.isTester)
         return;

      if(m_started)
         return;

      string reason = "";
      if(m_instanceRegistry.HasActiveConflict(m_settings.magicNumber, ChartID(), reason))
         m_startBlockedReason = reason + " Carregue outro perfil antes de iniciar.";
     }

   void                    RefreshActiveProfileRegistration(void)
     {
      if(m_settings.isTester || m_activeProfileName == "")
        {
         m_activeProfileRegistry.Unregister();
         return;
        }

      m_activeProfileRegistry.Register(m_activeProfileName, ChartID());
     }

   void                    RefreshActiveProfileBlockReason(void)
     {
      m_activeProfileBlockedReason = "";
      if(m_settings.isTester || m_activeProfileName == "")
         return;

      if(m_started || HasManagedOrPendingPosition())
         return;

      string reason = "";
      if(m_activeProfileRegistry.HasActiveProfilePeer(m_activeProfileName, ChartID(), reason))
         m_activeProfileBlockedReason = reason + " Carregue outro perfil salvo para continuar.";
     }

   void                    RefreshProfileBlockReasons(void)
     {
      RefreshActiveProfileRegistration();
      RefreshStartBlockReason();
      RefreshActiveProfileBlockReason();
     }

   bool                    StartBlockedByProfilePeer(void) const
     {
      return (m_startBlockedReason != "" || m_activeProfileBlockedReason != "");
     }

   bool                    ProfileBlockedByActiveProfilePeer(const string profileName,string &reason)
     {
      reason = "";
      if(m_settings.isTester || profileName == "")
         return false;

      return m_activeProfileRegistry.HasActiveProfilePeer(profileName, ChartID(), reason);
     }

   bool                    ProfileLoadBlockedByActiveProfile(const string profileName)
     {
      string reason = "";
      if(!ProfileBlockedByActiveProfilePeer(profileName, reason))
         return false;
      m_logger.Error("PROFILE", "Perfil " + profileName + " nao carregado: " + reason);
      return true;
     }

   bool                    ProfileSaveBlockedByActiveProfile(const string profileName)
     {
      string reason = "";
      if(!ProfileBlockedByActiveProfilePeer(profileName, reason))
         return false;
      m_logger.Error("PROFILE", "Perfil " + profileName + " nao salvo: " + reason);
      return true;
     }

   bool                    ProfileLoadBlockedByActiveDrawdown(const string profileName,const SEASettings &settings)
     {
      string lockReason = "";
      if(!m_protectionManager.IsDrawdownConfigLocked(lockReason))
         return false;
      if(FusionDrawdownSettingsCompatible(m_settings, settings))
         return false;

      m_logger.Warn("PROFILE", "Perfil " + profileName + ": " + FusionDrawdownProfileBlockMessage());
      return true;
     }

   bool                    ProfileLoadBlockedByActiveInstance(const string profileName,const SEASettings &settings)
     {
      if(settings.isTester)
         return false;

      string reason = "";
      if(!m_instanceRegistry.HasActiveConflict(settings.magicNumber, ChartID(), reason))
         return false;

      m_logger.Error("PROFILE", "Perfil " + profileName + " nao carregado: " + reason);
      return true;
     }

   ENUM_TIMEFRAMES         OperationalFallbackTimeframe(void) const
     {
      if(m_chartContext.periodValue > 0)
         return (ENUM_TIMEFRAMES)m_chartContext.periodValue;
      return FUSION_DEFAULT_TIMEFRAME;
     }

   bool                    TryLoadProfileFromDisk(const string profileName,
                                                  const ENUM_TIMEFRAMES fallbackTimeframe,
                                                  SEASettings &settingsOut)
     {
      if(m_settings.isTester || profileName == "")
         return false;

      SEASettings loadedSettings;
      if(!m_settingsStore.LoadProfile(profileName, loadedSettings))
         return false;

      loadedSettings.isTester = m_settings.isTester;
      ResolveOperationalTimeframes(loadedSettings, fallbackTimeframe);
      settingsOut = loadedSettings;
      return true;
     }

   bool                    ShouldRestoreSavedState(const SChartStateContext &restoredContext) const
     {
      if(restoredContext.deinitReason == REASON_CHARTCLOSE)
         return false;

      if(restoredContext.symbol != "" && restoredContext.symbol != _Symbol &&
         restoredContext.deinitReason != REASON_CHARTCHANGE)
         return false;

      return true;
     }

   bool                    ApplySettings(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      SEASettings resolvedSettings = settings;
      ResolveOperationalTimeframes(resolvedSettings, OperationalFallbackTimeframe());
      bool identityChanged = (m_settings.magicNumber != resolvedSettings.magicNumber);
      if(identityChanged)
        {
         string drawdownLockReason = "";
         if(m_protectionManager.IsDrawdownConfigLocked(drawdownLockReason))
           {
            m_logger.Warn("PROFILE", "Magic nao alterado enquanto o DD diario esta ativo.");
            return false;
           }
        }

      m_settings = resolvedSettings;
      ConfigureResolver();
      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_executionService.Reload(m_settings);
      if(identityChanged)
        {
         m_protectionManager.Init(&m_logger, m_settings);
         m_protectionManager.ResetForIdentityChange(m_positionState);
        }
      else
         m_protectionManager.Reload(m_settings, scope);
      ClearProtectionNoticeDisabledBySettings();
      ClearEntryBlockNotice();
      bool signalsReloaded = m_signalManager.ReloadAll(m_settings, scope);
      m_chartIndicators.Sync(m_settings);
      if(identityChanged)
        {
         ResetDailyHistoryAudit();
         m_dailyHistoryAuditPending = !m_settings.isTester;
         if(m_dailyHistoryAuditPending)
            ApplyDailyHistoryAuditBlock();
        }
      return signalsReloaded;
     }

   bool                    PriceReached(const ENUM_POSITION_TYPE type,const double currentPrice,const double targetPrice) const
     {
      if(targetPrice <= 0.0)
         return false;

      if(type == POSITION_TYPE_BUY)
         return currentPrice >= targetPrice;
      return currentPrice <= targetPrice;
     }

   bool                    TryPlaceEntryDecision(const SSignalDecision &decision,
                                                 const bool checkReentryBlock,
                                                 const bool bypassDirectionBlock)
     {
      if(decision.signal == SIGNAL_NONE)
         return false;

      if(!RefreshTradePermissionState())
        {
         ClearEntryBlockNotice();
         DiscardBlockedEntrySignals(m_tradePermissionGuard.Notice());
         return false;
        }

      string blockReason = "";
      if(!m_protectionManager.CanOpen(_Symbol, blockReason))
        {
         ClearEntryBlockNotice();
         ApplyProtectionNotice(blockReason, true, IsSpreadProtectionNotice(blockReason));
         DiscardBlockedEntrySignals(blockReason);
         return false;
        }

      if(ClearProtectionNotice(true))
        {
         m_signalManager.PrimeEntryStates();
         return false;
        }

      if(checkReentryBlock)
        {
         string reentryReason = "";
         if(IsReentryBlockedThisBar(decision.strategyId, reentryReason))
            {
             ClearEntryBlockNotice();
             DiscardBlockedEntrySignals(reentryReason);
             m_logger.Debug("BLOCKER", reentryReason);
             return false;
            }
        }

      if(!bypassDirectionBlock && !m_protectionManager.IsDirectionAllowed(decision.signal, blockReason))
        {
         ApplyEntryBlockNotice(FormatDirectionBlockReason(decision, blockReason));
         DiscardBlockedEntrySignals(blockReason);
         return false;
        }

      ClearEntryBlockNotice();

      double entryPrice = (decision.signal == SIGNAL_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                          : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      SRiskPlan plan;
      string runtimeStopsError = "";
      string runtimeStopsDetail = "";
      if(!m_riskManager.BuildEntryPlan(decision.signal, m_settings, SymbolSpec(), entryPrice, plan,
                                       runtimeStopsError, runtimeStopsDetail))
        {
         if(runtimeStopsError != "")
            ApplyRiskStopsEntryBlockNotice(runtimeStopsError, runtimeStopsDetail);
         return false;
        }

      if(m_executionService.PlaceEntry(decision.signal, plan, decision, m_positionState))
        {
         ClearStreakReleaseNotice();
         PersistChartState();
         return true;
        }

      return false;
     }

   void                    RefreshProtectionNoticeNow(const bool discardExistingSignals)
     {
      MaintainOperationalDayState();

      string blockReason = "";
      if(m_protectionManager.CanOpen(_Symbol, blockReason))
        {
         bool releasedStreak = ClearProtectionNotice(true);
         if(releasedStreak && discardExistingSignals)
            m_signalManager.PrimeEntryStates();
         return;
        }

      ApplyProtectionNotice(blockReason, !IsSpreadProtectionNotice(blockReason));
      if(discardExistingSignals)
         DiscardBlockedEntrySignals(blockReason);
     }

   void                    TryPlacePendingReverseExit(void)
     {
      SSignalDecision decision;
      if(!m_pendingReverseExit.TakeDecision(decision))
         return;

      m_runtimeNotice = "";

      if(!m_started)
         return;

      string blockReason = "";
      if(!m_settings.isTester)
         m_instanceRegistry.Refresh();

      if(HasForeignNettingPosition(blockReason))
        {
         LogNettingWarning(blockReason);
         return;
        }

      TryPlaceEntryDecision(decision, false, true);
     }

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

   void                    ManageOpenPosition(void)
     {
      if(!m_positionState.hasPosition)
         return;

      if(!PositionSelectByTicket(m_positionState.ticket))
        {
         m_executionService.MarkNeedsSync();
         return;
        }

      if(!RefreshTradePermissionState())
         return;

      m_positionState.volume     = PositionGetDouble(POSITION_VOLUME);
      m_positionState.stopLoss   = PositionGetDouble(POSITION_SL);
      m_positionState.takeProfit = PositionGetDouble(POSITION_TP);

      double currentPrice = (m_positionState.type == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                            : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double floatingProfit = PositionGetDouble(POSITION_PROFIT);
      ReconcileOpenPositionPartials(true, false);
      double protectionFloatingProfit = EffectiveFloatingProfit(floatingProfit);

      string forceReason = "";
      if(m_protectionManager.ShouldForceClose(m_positionState, protectionFloatingProfit, forceReason))
        {
         if(m_positionState.partialClosePending &&
            m_executionService.IsOrderActive(m_positionState.pendingPartialOrderTicket))
           {
            if(!m_pendingPartialForceCloseWaitLogged)
              {
               m_pendingPartialForceCloseWaitLogged = true;
               m_logger.Warn("PROTECT", "Saida forcada aguardando a ordem parcial ativa terminar para evitar sobre-execucao.");
              }
            return;
           }

         m_logger.Trade("PROTECT", "Forced exit: " + forceReason);
         m_executionService.ClosePosition(m_positionState, forceReason);
         return;
        }

      if(m_settings.usePartialTP && !m_positionState.partialClosePending)
        {
         if(!m_positionState.tp1Executed &&
            m_positionState.tp1Volume > 0.0 &&
            m_positionState.tp1Price > 0.0 &&
            PriceReached(m_positionState.type, currentPrice, m_positionState.tp1Price))
           {
            if(SubmitPartialClose(PARTIAL_CLOSE_TP1,
                                  m_positionState.tp1Volume,
                                  "Partial TP1",
                                  floatingProfit))
               return;
           }

         if(!m_positionState.tp2Executed &&
            m_positionState.tp2Volume > 0.0 &&
            m_positionState.tp2Price > 0.0 &&
            PriceReached(m_positionState.type, currentPrice, m_positionState.tp2Price))
           {
            if(SubmitPartialClose(PARTIAL_CLOSE_TP2,
                                  m_positionState.tp2Volume,
                                  "Partial TP2",
                                  floatingProfit))
               return;
           }
        }

      double newSL = 0.0;
      if(m_riskManager.CalculateBreakevenSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         double oldSL = m_positionState.stopLoss;
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.breakevenActive = true;
            m_logger.Trade("RISK", "Breakeven activated SL " + DoubleToString(oldSL, SymbolSpec().digits) + " -> " + DoubleToString(newSL, SymbolSpec().digits));
            PersistChartState();
           }
        }

      if(m_riskManager.CalculateTrailingSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         double oldSL = m_positionState.stopLoss;
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.trailingActive = true;
            m_logger.Trade("RISK", "Trailing stop updated SL " + DoubleToString(oldSL, SymbolSpec().digits) + " -> " + DoubleToString(newSL, SymbolSpec().digits));
            TryRemoveFreeFinalTakeProfit();
            PersistChartState();
           }
        }

      if(TryRemoveFreeFinalTakeProfit())
         PersistChartState();

      string ownerName = "";
      string shortName = "";
      ENUM_SIGNAL_TYPE exitSignal = m_signalManager.GetExitSignal(m_positionState.ownerStrategyId, m_positionState.type, ownerName, shortName);
      if(exitSignal != SIGNAL_NONE)
        {
         ENUM_EXIT_MODE exitMode = EXIT_TP_SL;
         bool reverseExit = (m_signalManager.GetStrategyExitMode(m_positionState.ownerStrategyId, exitMode) &&
                             exitMode == EXIT_REVERSE_SIGNAL);
         string ownerStrategyId = m_positionState.ownerStrategyId;
         string ownerStrategyName = (ownerName != "") ? ownerName : m_positionState.ownerStrategyName;

         if(m_executionService.ClosePosition(m_positionState, "Exit " + shortName))
           {
            m_logger.Trade("EXIT", "Signal exit from " + ownerName);
            if(reverseExit)
              {
               m_pendingReverseExit.Arm(exitSignal, ownerStrategyId, ownerStrategyName, shortName);
               m_runtimeNotice = "VM armada: reversao direta sem filtros/direcao; guards operacionais ativos.";
              }
           }
        }
     }

   SSymbolSpec             SymbolSpec(void) const
     {
      SSymbolSpec spec;
      m_normalizer.GetSpec(spec);
      return spec;
     }

   void                    HandleUICommand(const SUICommand &command)
     {
      if(command.type == UI_COMMAND_NONE)
         return;

      if(command.type == UI_COMMAND_TOGGLE_RUNNING)
        {
         if(m_runtimeBlocked)
            return;
         RefreshProfileBlockReasons();

         if(m_started)
           {
            if(HasManagedOrPendingPosition())
               return;
            m_started = false;
            ClearEntryBlockNotice();
            ReleaseRunningInstance();
            m_logger.Info("UI", "EA pausado pelo painel.");
           }
         else
           {
            if(m_closeReconciliationPending)
               return;
            if(m_dailyHistoryAuditPending && !TryAuditDailyHistory(true))
              {
               UpdatePanelIfVisible();
               return;
              }
            if(!RefreshTradePermissionState())
              {
               UpdatePanelIfVisible();
               return;
              }
            if(StartBlockedByProfilePeer())
              {
               UpdatePanelIfVisible();
               return;
              }
            if(!RegisterRunningInstance())
               return;
            m_signalManager.PrimeEntryStates();
            ClearEntryBlockNotice();
            m_started = true;
            RefreshProtectionNoticeNow(false);
            m_logger.Info("UI", "EA iniciado pelo painel.");
            }
         RefreshProfileBlockReasons();
         UpdatePanelIfVisible();
         PersistChartState();
         return;
        }

      if(command.type == UI_COMMAND_SAVE_PROFILE)
        {
         if(m_closeReconciliationPending)
           {
            m_logger.Warn("PROFILE", "Perfil nao salvo enquanto o fechamento aguarda confirmacao do historico.");
            return;
           }

         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;

         SEASettings settingsToSave = m_settings;
         if(command.hasSettings)
            settingsToSave = command.settings;
         settingsToSave.isTester = m_settings.isTester;
         ResolveOperationalTimeframes(settingsToSave, OperationalFallbackTimeframe());

         if(ProfileSaveBlockedByActiveProfile(profileName))
            return;

         if(!CanPersistProfile(profileName, settingsToSave))
            return;

         if(!ApplySettings(settingsToSave, command.reloadScope))
            return;

         if(m_settingsStore.SaveProfile(profileName, m_settings))
            m_activeProfileName = profileName;
         RefreshProfileBlockReasons();

         ReloadPanelSettingsIfVisible();

         PersistChartState();
         return;
        }

      if(command.type == UI_COMMAND_LOAD_PROFILE)
        {
         if(m_closeReconciliationPending)
           {
            m_logger.Warn("PROFILE", "Perfil nao carregado enquanto o fechamento aguarda confirmacao do historico.");
            return;
           }

         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;

         SEASettings loadedSettings;
         if(!m_settingsStore.LoadProfile(profileName, loadedSettings))
           {
            m_logger.Warn("PROFILE", "Perfil " + profileName + " nao carregado: arquivo ausente, invalido ou incompleto. Configuracao atual preservada.");
            return;
           }

         loadedSettings.isTester = m_settings.isTester;
         ResolveOperationalTimeframes(loadedSettings, OperationalFallbackTimeframe());
         if(ProfileLoadBlockedByActiveDrawdown(profileName, loadedSettings))
            return;
         if(ProfileLoadBlockedByActiveProfile(profileName))
            return;
         if(ProfileLoadBlockedByActiveInstance(profileName, loadedSettings))
            return;
         if(!ApplySettings(loadedSettings, RELOAD_COLD))
            return;
         m_activeProfileName = profileName;
         RefreshProfileBlockReasons();

         ReloadPanelSettingsIfVisible();

         PersistChartState();
         return;
        }
     }

   public:
                     CFusionApplication(void)
     {
      SetDefaultSettings(m_settings);
      ResetPositionRuntimeState(m_positionState);
      ResetCloseReconciliation();
      ResetDailyHistoryAudit();
      m_chartContext.chartId = 0;
      m_chartContext.symbol = "";
      m_chartContext.timeframe = "";
      m_chartContext.periodValue = 0;
      m_chartContext.deinitReason = -1;
      m_chartContext.discardedUnsavedDraft = false;
      m_activeProfileName   = "default";
      m_started             = false;
      m_modulesRegistered   = false;
      m_lastNettingWarning  = 0;
      m_lastClosedStrategyId   = "";
      m_lastClosedStrategyBarTime = 0;
      ResetTransientRuntimeState();
      m_pendingReverseExit.Reset();
     }

   bool              Initialize(void)
     {
      uint initStartTick = GetTickCount();
      FillSettingsFromInputs(m_settings);
      m_settings.isTester = (bool)MQLInfoInteger(MQL_TESTER);
      m_chartContext = CurrentChartContext();
      ResolveOperationalTimeframes(m_settings, OperationalFallbackTimeframe());
      m_activeProfileName = m_settings.defaultProfileName;
      m_started = m_settings.isTester;
      ResetTransientRuntimeState();
      ResetCloseReconciliation();
      ResetDailyHistoryAudit();
      m_dailyHistoryAuditPending = !m_settings.isTester;

      if(!m_settings.isTester &&
         m_settings.defaultProfileName != "" &&
         !m_settingsStore.ProfileExists(m_settings.defaultProfileName))
        {
         SEASettings defaultSettings = m_settings;
         ResolveOperationalTimeframes(defaultSettings, OperationalFallbackTimeframe());
         if(m_settingsStore.SaveProfile(m_settings.defaultProfileName, defaultSettings))
            m_runtimeNotice = "Perfil " + m_settings.defaultProfileName + " criado automaticamente a partir dos inputs.";
        }

      bool defaultProfileLoaded = false;
      SEASettings bootSettings = m_settings;
      if(TryLoadProfileFromDisk(m_settings.defaultProfileName, OperationalFallbackTimeframe(), bootSettings))
        {
         m_settings = bootSettings;
         m_activeProfileName = m_settings.defaultProfileName;
         defaultProfileLoaded = true;
        }

      SEASettings restoredSettings = m_settings;
      SChartStateContext restoredContext = m_chartContext;
      string restoredProfile = "";
      bool restoredStarted = false;
      bool restoredStateApplied = false;
      bool restoredRunningAfterChartChange = false;
      SPositionRuntimeState restoredState;
      SStreakRuntimeState restoredStreakState;
      SDailyLimitsRuntimeState restoredDailyState;
      SDrawdownRuntimeState restoredDrawdownState;
      ResetPositionRuntimeState(restoredState);
      ResetStreakRuntimeState(restoredStreakState);
      ResetDailyLimitsRuntimeState(restoredDailyState);
      ResetDrawdownRuntimeState(restoredDrawdownState);

      if(m_settingsStore.LoadChartState(m_chartContext.chartId,
                                        restoredContext,
                                        restoredProfile,
                                        restoredStarted,
                                        restoredSettings,
                                        restoredState,
                                        restoredStreakState,
                                        restoredDailyState,
                                        restoredDrawdownState))
        {
         if(ShouldRestoreSavedState(restoredContext))
           {
            restoredStateApplied = true;
            restoredSettings.isTester = m_settings.isTester;
            ENUM_TIMEFRAMES restoreFallback = (restoredContext.periodValue > 0)
                                              ? (ENUM_TIMEFRAMES)restoredContext.periodValue
                                              : OperationalFallbackTimeframe();
            ResolveOperationalTimeframes(restoredSettings, restoreFallback);
            string restoredActiveProfile = (restoredProfile == "") ? restoredSettings.defaultProfileName : restoredProfile;
            bool restoredDrawdownLocked = (restoredDrawdownState.dayKey == FusionProtectionCurrentDayKey() &&
                                           (restoredDrawdownState.protectionActive || restoredDrawdownState.limitReached));
            if(!restoredState.hasPosition && !restoredDrawdownLocked)
              {
               SEASettings canonicalProfileSettings;
               if(TryLoadProfileFromDisk(restoredActiveProfile, restoreFallback, canonicalProfileSettings))
                  restoredSettings = canonicalProfileSettings;
              }
            m_settings = restoredSettings;
            if(restoredContext.symbol != "")
               m_chartContext.symbol = restoredContext.symbol;
            if(restoredContext.timeframe != "")
               m_chartContext.timeframe = restoredContext.timeframe;
            if(restoredContext.periodValue > 0)
               m_chartContext.periodValue = restoredContext.periodValue;
            m_chartContext.deinitReason = restoredContext.deinitReason;
            m_activeProfileName = restoredActiveProfile;
            m_positionState = restoredState;

            if(restoredContext.symbol != "" && restoredContext.symbol != _Symbol)
              {
               ApplyRuntimeBlock("Ativo do grafico mudou. Volte para " + restoredContext.symbol + ". Nao troque o ativo com o EA anexado. Isso pode causar prejuizo financeiro.");
              }
            else
              {
               // Troca de timeframe deve preservar o estado operacional; outros restores em real/demo exigem clique manual.
               m_started = (m_settings.isTester || (restoredContext.deinitReason == REASON_CHARTCHANGE && restoredStarted));
               restoredRunningAfterChartChange = (!m_settings.isTester &&
                                                  m_started &&
                                                  restoredContext.deinitReason == REASON_CHARTCHANGE);
              }
           }
         }

      if(restoredStateApplied &&
         restoredContext.deinitReason == REASON_CHARTCHANGE &&
         restoredContext.discardedUnsavedDraft)
         ApplyRuntimeNotice("Alteracoes nao salvas foram descartadas na troca de timeframe.");

      if(!restoredStateApplied && !defaultProfileLoaded && !m_settings.isTester && !m_runtimeBlocked && m_runtimeNotice == "")
        {
         string profileIssue = m_settingsStore.ProfileExists(m_settings.defaultProfileName)
                               ? "esta invalido ou incompleto"
                               : "nao foi encontrado";
         ApplyRuntimeNotice("Perfil " + m_settings.defaultProfileName + " " + profileIssue + ". O Fusion manteve os inputs atuais ate voce carregar ou salvar um perfil.");
        }
      RefreshProfileBlockReasons();
      uint restoreDoneTick = GetTickCount();

      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_chartIndicators.Init(&m_logger, ChartID());
      m_tradePermissionGuard.Init(&m_logger, m_settings.isTester);
      m_normalizer.Init(&m_logger, _Symbol);
      m_riskManager.Init(&m_logger);
      m_protectionManager.Init(&m_logger, m_settings);
      if(restoredStateApplied)
        {
         RecoverLegacyDailyOutcomeCounts(restoredDailyState, restoredStreakState);
         m_protectionManager.ImportStreakState(restoredStreakState);
         m_protectionManager.ImportDailyLimitsState(restoredDailyState);
         m_protectionManager.ImportDrawdownState(restoredDrawdownState);
        }
      m_executionService.Init(&m_logger, &m_normalizer, _Symbol, m_settings);

      RegisterModules();
      ConfigureResolver();

      if(!m_signalManager.Initialize(&m_logger, _Symbol, m_settings))
         return false;
      m_chartIndicators.Sync(m_settings);
      uint signalDoneTick = GetTickCount();

      if(!m_runtimeBlocked)
        {
         SPositionRuntimeState stateBeforeSync = m_positionState;
         bool positionSynced = m_executionService.SyncPosition(m_positionState);
         if(positionSynced && m_positionState.hasPosition)
            m_logger.Info("SYNC", "Posicao aberta detectada e ressincronizada.");
         else if(stateBeforeSync.hasPosition)
            BeginCloseReconciliation(stateBeforeSync, true);
         if(!m_closeReconciliationPending)
            TryAuditDailyHistory(true);
        }

      if(restoredRunningAfterChartChange && !HasManagedOrPendingPosition())
        {
         m_signalManager.PrimeEntryStates();
         m_logger.Info("SIGNAL", "Sinais existentes descartados apos troca de timeframe; aguardando novo sinal.");
        }

      if(!m_runtimeBlocked)
         RefreshTradePermissionState();

      if(m_runtimeBlocked)
         m_logger.Warn("CONTEXT", m_runtimeBlockReason);
      else if(m_runtimeNotice != "" && !m_tradePermissionGuard.IsBlocked())
         m_logger.Warn("CONTEXT", m_runtimeNotice);

      if(!m_runtimeBlocked && (m_started || HasManagedOrPendingPosition()) && !RegisterRunningInstance())
         m_started = false;

      if(ShouldShowPanel())
        {
         int x1 = FUSION_PANEL_LEFT;

         if(!m_panel.CreatePanel(ChartID(),
                                  FusionDialogProgramName(),
                                  0,
                                 x1,
                                 FUSION_PANEL_TOP,
                                 x1 + FUSION_PANEL_WIDTH,
                                 FUSION_PANEL_TOP + FUSION_PANEL_HEIGHT,
                                 BuildPanelSnapshot()))
           {
           m_logger.Error("UI", "Failed to create Fusion panel");
           return false;
          }

         if(!m_panel.StartDialog())
           {
            m_logger.Error("UI", "Failed to run Fusion panel");
            m_panel.Destroy(REASON_REMOVE);
            return false;
           }
        }
      uint uiDoneTick = GetTickCount();

      m_logger.Debug("INIT",
                     "Restore=" + IntegerToString((int)(restoreDoneTick - initStartTick)) +
                     "ms Signals=" + IntegerToString((int)(signalDoneTick - restoreDoneTick)) +
                     "ms UI=" + IntegerToString((int)(uiDoneTick - signalDoneTick)) +
                     "ms Total=" + IntegerToString((int)(uiDoneTick - initStartTick)) + "ms");

      EventSetTimer(1);
      return true;
     }

   void              Shutdown(const int reason)
     {
      EventKillTimer();
      PersistChartState(reason);
      ReleaseRunningInstance();
      m_activeProfileRegistry.Unregister();
      m_chartIndicators.Shutdown(reason);
      m_panel.Destroy(reason);
      m_signalManager.Shutdown();
     }

   void              OnTick(void)
     {
      if(m_runtimeBlocked)
         return;

      SyncPositionState();
      MaintainOperationalDayState();

      if(m_closeReconciliationPending)
         return;
      TryAuditDailyHistory(false);
      if(m_dailyHistoryAuditPending)
        {
         DiscardBlockedEntrySignals(DailyHistoryAuditNotice());
         return;
        }

      if(!RefreshTradePermissionState())
        {
         DiscardBlockedEntrySignals(m_tradePermissionGuard.Notice());
         return;
        }

      if(m_positionState.hasPosition)
        {
         ClearProtectionNotice();
         ManageOpenPosition();
         UpdateLivePanelIfDue();
         return;
        }

      if(m_pendingReverseExit.HasPending())
        {
         TryPlacePendingReverseExit();
         return;
        }

      if(!m_started)
        {
         ClearProtectionNotice();
         ClearEntryBlockNotice();
         return;
        }

      string blockReason = "";
      if(!m_settings.isTester)
         m_instanceRegistry.Refresh();

      if(HasForeignNettingPosition(blockReason))
        {
         ClearProtectionNotice();
         ClearEntryBlockNotice();
         DiscardBlockedEntrySignals(blockReason);
         LogNettingWarning(blockReason);
         return;
        }

      if(!m_protectionManager.CanOpen(_Symbol, blockReason))
        {
         ClearEntryBlockNotice();
         ApplyProtectionNotice(blockReason, !IsSpreadProtectionNotice(blockReason));
         DiscardBlockedEntrySignals(blockReason);
         return;
        }

      if(ClearProtectionNotice(true))
        {
         ClearEntryBlockNotice();
         m_signalManager.PrimeEntryStates();
         return;
        }

      SSignalDecision decision;
      ResetSignalDecision(decision);
      if(!m_signalManager.GetEntryDecision(decision))
        {
         if(decision.blockedBy != "")
           {
            ApplyEntryBlockNotice(decision.blockedBy);
            DiscardBlockedEntrySignals(decision.blockedBy);
           }
         return;
        }

      TryPlaceEntryDecision(decision, true, false);
     }

   void              OnTimer(void)
     {
      if(!m_runtimeBlocked)
        {
         SyncPositionState();
         MaintainOperationalDayState();
         if(m_positionState.hasPosition)
            ReconcileOpenPositionPartials(true, false);
         if(!m_closeReconciliationPending)
            TryAuditDailyHistory(false);
        }

      if((m_started || HasManagedOrPendingPosition()) && !m_settings.isTester)
         m_instanceRegistry.Refresh();

      RefreshTradePermissionState();
      RefreshProfileBlockReasons();

      UpdatePanelIfVisible();
      m_chartIndicators.Sync(m_settings);
     }

   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      m_chartIndicators.OnChartEvent(id, lparam, dparam, sparam);
      if(!ShouldShowPanel())
         return;

      m_panel.ChartEvent(id, lparam, dparam, sparam);

      SUICommand command;
      while(m_panel.ConsumeCommand(command))
         HandleUICommand(command);
     }

   void              OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
     {
      if(m_runtimeBlocked)
         return;
      m_executionService.MarkNeedsSync();
      if(m_positionState.hasPosition)
         ReconcileOpenPositionPartials(true,
                                       trans.type == TRADE_TRANSACTION_DEAL_ADD);
      if(m_closeReconciliationPending)
         m_nextCloseReconciliationAttempt = 0;
      UpdatePanelIfVisible();
     }
  };

#endif
