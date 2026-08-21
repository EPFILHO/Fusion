#ifndef __FUSION_APPLICATION_MQH__
#define __FUSION_APPLICATION_MQH__

#include "Inputs.mqh"
#include "SettingsNotices.mqh"
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
//+------------------------------------------------------------------+
//| FASE 4 — o painel em canvas e o unico que existe.                 |
//|                                                                   |
//| Ate a Fase 3 este ponto era um #ifdef FUSION_USE_CANVAS_PANEL     |
//| escolhendo entre CFusionCanvasPanel e o CFusionPanel classico, e  |
//| havia dois .ex5 do mesmo EA para compara-los lado a lado. O       |
//| painel classico foi REMOVIDO; com uma implementacao so, o         |
//| interruptor nao tem mais o que escolher e some junto — que era    |
//| exatamente o combinado ao adotar troca em tempo de compilacao,    |
//| em vez de uma indirecao que sobreviveria a transicao sem uso.     |
//|                                                                   |
//| A fronteira de 8 metodos (secao 5 do plano) continua valendo: e   |
//| tudo o que o EA usa do painel, e e o que manteria o custo de      |
//| trocar de implementacao baixo, se um dia for preciso de novo.     |
//|                                                                   |
//| Reverter para o painel classico deixou de ser trocar o EA do      |
//| grafico e passou a ser operacao de Git: a branch gui-2.0 tem o    |
//| checkpoint 5f9524a publicado em origin, o ultimo commit em que    |
//| os dois paineis coexistem.                                        |
//+------------------------------------------------------------------+
#include "../UI/Canvas/CanvasPanel.mqh"
#define FUSION_PANEL_CLASS CFusionCanvasPanel
#define FUSION_PANEL_BUILD_NAME "canvas (GUI 2.0)"
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
   FUSION_PANEL_CLASS      m_panel;
   SPositionRuntimeState   m_positionState;
   SChartStateContext      m_chartContext;
   string                  m_activeProfileName;
   bool                    m_activeProfileFileMissing;
   bool                    m_started;
   bool                    m_modulesRegistered;
   datetime                m_lastNettingWarning;
   bool                    m_runtimeBlocked;
   string                  m_runtimeBlockReason;
   bool                    m_runtimeBlockedByChartProfile;
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

      // O logger so e inicializado depois que o perfil resolve, porque depende do
      // Magic. Guardamos aqui como o perfil foi decidido para registrar em seguida:
      // adotar um perfil diferente do que o grafico usava muda lote e Magic, e nunca
      // deve acontecer sem rastro.
      string profileResolution = "";
      bool   profileResolutionIsWarning = false;
      bool   chartStateDiscarded = false;

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
         if(!ShouldRestoreSavedState(restoredContext))
            chartStateDiscarded = true;

         if(ShouldRestoreSavedState(restoredContext))
           {
            restoredStateApplied = true;
            restoredSettings.isTester = m_settings.isTester;
            //--- Mesma razao do isTester acima: diagnostico e da sessao. Com
            //--- posicao aberta ou DD travado o perfil canonico nao e
            //--- recarregado, entao sem esta linha o valor viria do estado
            //--- gravado — que ja nao guarda debugLogs — e cairia no default.
            restoredSettings.debugLogs = inp_EnableDebugLogs;
            //--- Idem para o painel. Com posicao aberta ou DD travado este
            //--- caminho nao recarrega o perfil canonico, e sem a linha o valor
            //--- viria do estado gravado. No grafico isso ja nao mudaria nada
            //--- — o painel aparece de qualquer forma —, mas mantem o estado
            //--- coerente com o input, que e quem decide no tester.
            restoredSettings.panelEnabled = inp_ShowPanel;
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

      // O estado de runtime pode ser descartado com seguranca, mas a identidade do
      // perfil nao: adotar outro perfil muda lote e Magic. Se o grafico usava um
      // perfil e ele ainda existe, ele prevalece sobre o perfil de inicializacao.
      bool profileRecoveredFromChart = false;
      if(!m_settings.isTester &&
         !restoredStateApplied &&
         restoredProfile != "" &&
         restoredProfile != m_activeProfileName)
        {
         SEASettings chartProfileSettings;
         if(TryLoadProfileFromDisk(restoredProfile, OperationalFallbackTimeframe(), chartProfileSettings))
           {
            m_settings = chartProfileSettings;
            m_activeProfileName = restoredProfile;
            profileRecoveredFromChart = true;
           }
         else
           {
            // O aviso do painel corta em 174 caracteres. A instrucao acionavel
            // vem primeiro; o porque completo esta em docs/DECISIONS.md (20).
            ApplyRuntimeBlock("Perfil " + restoredProfile +
                              " do grafico nao pode ser carregado. Carregue um perfil na aba PERFIS para liberar a operacao. Assumir outro mudaria lote e Magic.");
            m_runtimeBlockedByChartProfile = true;
           }
        }

      if(!m_settings.isTester)
        {
         string activeNow = "Perfil ativo: " + m_activeProfileName +
                            " (Magic " + IntegerToString(m_settings.magicNumber) +
                            ", lote " + DoubleToString(m_settings.fixedLot, 2) + ").";
         string discardCause = "";
         if(chartStateLoadError != "")
            discardCause = "estado salvo rejeitado (" + chartStateLoadError + ")";
         else if(chartStateDiscarded)
            discardCause = "estado salvo descartado por contexto (deinit " +
                           IntegerToString(restoredContext.deinitReason) + ")";

         if(restoredStateApplied)
            profileResolution = "Perfil restaurado do estado do grafico. " + activeNow;
         else if(m_runtimeBlocked && restoredProfile != "")
           {
            profileResolution = "Perfil " + restoredProfile + " do grafico nao pode ser carregado; " +
                                discardCause + ". EA bloqueado sem assumir outro perfil.";
            profileResolutionIsWarning = true;
           }
         else if(profileRecoveredFromChart)
           {
            // O runtime foi descartado, mas a identidade do perfil sobreviveu: o EA
            // segue no perfil do grafico, com o lote e o Magic corretos.
            profileResolution = "Runtime descartado (" + discardCause +
                                "), perfil do grafico preservado. " + activeNow;
            profileResolutionIsWarning = true;
           }
         else if(discardCause != "")
           {
            profileResolution = "Estado do grafico nao aplicado: " + discardCause + ". " + activeNow;
            profileResolutionIsWarning = true;
           }
         else if(defaultProfileLoaded)
            profileResolution = "Sem estado salvo para este grafico. " + activeNow;
         else
           {
            profileResolution = "Nenhum perfil carregado do disco; operando com os inputs. " + activeNow;
            profileResolutionIsWarning = true;
           }
        }

      RefreshProfileBlockReasons();
      uint restoreDoneTick = GetTickCount();

      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      if(profileResolution != "")
        {
         if(profileResolutionIsWarning)
            m_logger.Warn("PROFILE", profileResolution);
         else
            m_logger.Info("PROFILE", profileResolution);
        }
      m_chartIndicators.Init(&m_logger, ChartID(), m_settings.isTester);
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
      // Um aviso de contexto nao deve depender do AutoTrading estar ligado: a troca de
      // conta desliga o AutoTrading e era justamente ai que a mensagem se perdia.
      else if(m_runtimeNotice != "")
         m_logger.Warn("CONTEXT", m_runtimeNotice);

      if(!m_runtimeBlocked && (m_started || HasManagedOrPendingPosition()) && !RegisterRunningInstance())
         m_started = false;

      if(ShouldShowPanel())
        {
         // Qual painel este binario tem dentro. Info, e nao Debug, de proposito.
         // Nasceu na Fase 3, quando havia dois .ex5 e testar o errado era risco
         // real; com a Fase 4 sobrou um so, mas a licao 4 da secao 8 do plano
         // ("conferir o binario deployado antes de interpretar um teste")
         // continua valendo por si - um .ex5 desatualizado ja invalidou uma
         // rodada inteira. Uma linha por inicializacao responde que build esta
         // no ar sem precisar abrir o log de debug.
         m_logger.Info("UI", "Painel: " + FUSION_PANEL_BUILD_NAME);

         //--- So a POSICAO inicial: o painel decide a propria largura e altura
         //--- (FCV_PANEL_W e DecidePanelHeight), e depois do primeiro arrasto
         //--- quem manda aqui e o estado salvo do grafico.
         if(!m_panel.CreatePanel(ChartID(),
                                 FCV_PANEL_X,
                                 FCV_PANEL_Y,
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
      //--- A legenda e criada aqui dentro, quando os indicadores ligam. Este e
      //--- o ponto que entrega a zona proibida a uma legenda recem-nascida, sem
      //--- depender de o usuario mexer o mouse antes.
      SyncLegendExclusion();
     }

   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      //--- Este e o unico nivel que enxerga painel e legenda ao mesmo tempo, e
      //--- por isso a coordenacao mora aqui. Publicada ANTES do teste de
      //--- pressao: a legenda precisa saber onde o painel esta agora, nao onde
      //--- estava no evento anterior.
      SyncLegendExclusion();

      //--- ⚠ O gesto tem UM dono. A legenda dos indicadores faz hit-test manual
      //--- por coordenada, entao ZORDER nao separa nada: sem este consumo, o
      //--- mesmo CHARTEVENT_MOUSE_MOVE chegava a ela E ao painel, e com a
      //--- legenda parada sobre o painel os dois se moviam juntos. Tambem e o
      //--- que evita os dois disputarem CHART_MOUSE_SCROLL.
      //---
      //--- Nao ha decisao operacional aqui: e despacho de evento de interface.
      if(m_chartIndicators.OnChartEvent(id, lparam, dparam, sparam))
         return;

      if(!ShouldShowPanel())
         return;

      m_panel.ChartEvent(id, lparam, dparam, sparam);

      //--- De novo depois do painel: o evento pode te-lo movido, minimizado,
      //--- restaurado ou fechado.
      SyncLegendExclusion();

      SUICommand command;
      while(m_panel.ConsumeCommand(command))
         HandleUICommand(command);
     }

   //--- Retangulo interativo do painel -> legenda. Somente interface.
   void              SyncLegendExclusion(void)
     {
      int left = 0, top = 0, right = 0, bottom = 0;
      bool valid = (ShouldShowPanel() &&
                    m_panel.GetInteractiveRect(left, top, right, bottom));
      m_chartIndicators.SetPanelExclusion(valid, left, top, right, bottom);
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
