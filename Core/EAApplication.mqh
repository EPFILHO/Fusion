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

#include "EAApplicationPartials.mqh"
#include "EAApplicationInstanceGuard.mqh"
#include "EAApplicationModules.mqh"
#include "EAApplicationSnapshot.mqh"
#include "EAApplicationProtectionNotice.mqh"
#include "EAApplicationEntryBlock.mqh"
#include "EAApplicationProfileBlock.mqh"
#include "EAApplicationSettings.mqh"
#include "EAApplicationEntry.mqh"
#include "EAApplicationPositionSync.mqh"
#include "EAApplicationManagePosition.mqh"
#include "EAApplicationCommands.mqh"

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
      string chartStateLoadError = "";

      if(m_settingsStore.LoadChartState(m_chartContext.chartId,
                                        restoredContext,
                                        restoredProfile,
                                        restoredStarted,
                                        restoredSettings,
                                        restoredState,
                                        restoredStreakState,
                                        restoredDailyState,
                                        restoredDrawdownState,
                                        chartStateLoadError))
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
      else if(chartStateLoadError != "" && !m_settings.isTester)
         ApplyRuntimeNotice("Estado operacional salvo rejeitado: " + chartStateLoadError +
                            ". O Fusion manteve o boot seguro e vai ressincronizar posicao e historico.");

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
