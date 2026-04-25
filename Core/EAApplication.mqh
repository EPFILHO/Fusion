#ifndef __FUSION_APPLICATION_MQH__
#define __FUSION_APPLICATION_MQH__

#include "Inputs.mqh"
#include "Logger.mqh"
#include "InstanceRegistry.mqh"
#include "../Signals/SignalManager.mqh"
#include "../Signals/Resolvers/PriorityConflictResolver.mqh"
#include "../Signals/Resolvers/CancelConflictResolver.mqh"
#include "../Strategies/Implementations/MACrossStrategy.mqh"
#include "../Strategies/Implementations/RSIStrategy.mqh"
#include "../Strategies/Implementations/BollingerStrategy.mqh"
#include "../Filters/Implementations/TrendFilter.mqh"
#include "../Filters/Implementations/RSIFilter.mqh"
#include "../Risk/RiskManager.mqh"
#include "../Protection/ProtectionManager.mqh"
#include "../Normalization/SymbolNormalizer.mqh"
#include "../Execution/ExecutionService.mqh"
#include "../Persistence/SettingsStore.mqh"
#include "../UI/UIPanel.mqh"

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
   CRiskManager            m_riskManager;
   CProtectionManager      m_protectionManager;
   CSymbolNormalizer       m_normalizer;
   CExecutionService       m_executionService;
   CSettingsStore          m_settingsStore;
   CInstanceRegistry       m_instanceRegistry;
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
   string                  m_runtimeNotice;

   SChartStateContext      CurrentChartContext(void) const
     {
      SChartStateContext context;
      context.chartId   = (ulong)ChartID();
      context.symbol    = _Symbol;
      context.timeframe = EnumToString((ENUM_TIMEFRAMES)Period());
      context.periodValue = (int)Period();
      context.deinitReason = -1;
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

   void                    RegisterModules(void)
     {
      if(m_modulesRegistered)
         return;

      m_signalManager.AddStrategy(&m_maStrategy);
      m_signalManager.AddStrategy(&m_rsiStrategy);
      m_signalManager.AddStrategy(&m_bbStrategy);
      m_signalManager.AddFilter(&m_trendFilter);
      m_signalManager.AddFilter(&m_rsiFilter);
      m_modulesRegistered = true;
     }

   SUIPanelSnapshot        BuildPanelSnapshot(void) const
     {
      SUIPanelSnapshot snapshot;
      snapshot.settings         = m_settings;
      snapshot.started          = m_started;
      snapshot.hasPosition      = m_positionState.hasPosition;
      snapshot.activeProfileName= m_activeProfileName;
      snapshot.symbol           = _Symbol;
      snapshot.timeframe        = EnumToString((ENUM_TIMEFRAMES)Period());
      snapshot.symbolSpec       = SymbolSpec();
      snapshot.magicNumber      = m_settings.magicNumber;
      snapshot.activeStrategies = m_signalManager.ActiveStrategyCount();
      snapshot.activeFilters    = m_signalManager.ActiveFilterCount();
      snapshot.conflictMode     = m_settings.conflictMode;
      snapshot.fixedLot         = m_settings.fixedLot;
      snapshot.maxSpreadPoints  = m_settings.maxSpreadPoints;
      snapshot.ownerStrategyName= m_positionState.ownerStrategyName;
      snapshot.useMACross       = m_settings.useMACross;
      snapshot.useRSI           = m_settings.useRSI;
      snapshot.useBollinger     = m_settings.useBollinger;
      snapshot.useTrendFilter   = m_settings.useTrendFilter;
      snapshot.useRSIFilter     = m_settings.useRSIFilter;
      snapshot.runtimeBlocked   = m_runtimeBlocked;
      snapshot.runtimeBlockReason = m_runtimeBlockReason;
      snapshot.startBlockedReason = m_startBlockedReason;
      snapshot.runtimeNotice    = m_runtimeNotice;
      return snapshot;
     }

   void                    PersistChartState(void)
     {
      PersistChartState(-1);
     }

   void                    PersistChartState(const int deinitReason)
     {
      if(!m_settings.autoSaveChartState || m_settings.isTester)
         return;

      SChartStateContext context = CurrentChartContext();
      context.deinitReason = deinitReason;
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

      m_settingsStore.SaveChartState(context, m_activeProfileName, m_started, m_settings, m_positionState);
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

   void                    RefreshStartBlockReason(void)
     {
      m_startBlockedReason = "";
      if(m_settings.isTester)
         return;

      if(m_started || m_positionState.hasPosition)
         return;

      string reason = "";
      if(m_instanceRegistry.HasActiveConflict(m_settings.magicNumber, ChartID(), reason))
         m_startBlockedReason = reason + " Carregue outro perfil antes de iniciar.";
     }

   ENUM_TIMEFRAMES         OperationalFallbackTimeframe(void) const
     {
      if(m_chartContext.periodValue > 0)
         return (ENUM_TIMEFRAMES)m_chartContext.periodValue;
      return FUSION_DEFAULT_TIMEFRAME;
     }

   bool                    TryLoadProfileForBoot(const string profileName,SEASettings &settingsOut)
     {
      if(m_settings.isTester || profileName == "")
         return false;

      SEASettings loadedSettings;
      if(!m_settingsStore.LoadProfile(profileName, loadedSettings))
         return false;

      loadedSettings.isTester = m_settings.isTester;
      ResolveOperationalTimeframes(loadedSettings, OperationalFallbackTimeframe());
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
      m_settings = resolvedSettings;
      ConfigureResolver();
      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_executionService.Reload(m_settings);
      m_protectionManager.Reload(m_settings, scope);
      return m_signalManager.ReloadAll(m_settings, scope);
     }

   bool                    PriceReached(const ENUM_POSITION_TYPE type,const double currentPrice,const double targetPrice) const
     {
      if(targetPrice <= 0.0)
         return false;

      if(type == POSITION_TYPE_BUY)
         return currentPrice >= targetPrice;
      return currentPrice <= targetPrice;
     }

   void                    SyncPositionState(void)
     {
      SPositionRuntimeState previous = m_positionState;
      m_executionService.SyncPosition(m_positionState);

      if(previous.hasPosition && !m_positionState.hasPosition)
        {
         SClosedTradeSummary summary;
         if(m_executionService.GetClosedTradeSummary(previous.positionId, summary))
           {
            m_protectionManager.OnPositionClosed(summary.totalProfit, previous.realizedPartialProfit);
            m_logger.Trade("CLOSE", "Position closed. Total profit: " + DoubleToString(summary.totalProfit, 2));
         }

         ResetPositionRuntimeState(m_positionState);
         PersistChartState();
         if(!m_started)
            ReleaseRunningInstance();
        }
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

      m_positionState.volume     = PositionGetDouble(POSITION_VOLUME);
      m_positionState.stopLoss   = PositionGetDouble(POSITION_SL);
      m_positionState.takeProfit = PositionGetDouble(POSITION_TP);

      double currentPrice = (m_positionState.type == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                            : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double floatingProfit = PositionGetDouble(POSITION_PROFIT);

      string forceReason = "";
      if(m_protectionManager.ShouldForceClose(m_positionState, floatingProfit, forceReason))
        {
         m_logger.Trade("PROTECT", "Forced exit: " + forceReason);
         m_executionService.ClosePosition(m_positionState, forceReason);
         return;
        }

      if(m_settings.usePartialTP)
        {
         double partialProfit = 0.0;
         if(!m_positionState.tp1Executed && PriceReached(m_positionState.type, currentPrice, m_positionState.tp1Price))
           {
            if(m_executionService.PartialClose(m_positionState, m_positionState.tp1Volume, "Partial TP1", partialProfit))
              {
               m_positionState.tp1Executed = true;
               m_positionState.realizedPartialProfit += partialProfit;
               m_protectionManager.OnPartialRealized(partialProfit);
               m_logger.Trade("PARTIAL", "TP1 executed");
               PersistChartState();
               return;
              }
           }

         if(!m_positionState.tp2Executed && PriceReached(m_positionState.type, currentPrice, m_positionState.tp2Price))
           {
            if(m_executionService.PartialClose(m_positionState, m_positionState.tp2Volume, "Partial TP2", partialProfit))
              {
               m_positionState.tp2Executed = true;
               m_positionState.realizedPartialProfit += partialProfit;
               m_protectionManager.OnPartialRealized(partialProfit);
               m_logger.Trade("PARTIAL", "TP2 executed");
               PersistChartState();
               return;
              }
           }
        }

      double newSL = 0.0;
      if(m_riskManager.CalculateBreakevenSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.breakevenActive = true;
            m_logger.Trade("RISK", "Breakeven activated");
            PersistChartState();
           }
        }

      if(m_riskManager.CalculateTrailingSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.trailingActive = true;
            m_logger.Trade("RISK", "Trailing stop updated");
            PersistChartState();
           }
        }

      string ownerName = "";
      string shortName = "";
      ENUM_SIGNAL_TYPE exitSignal = m_signalManager.GetExitSignal(m_positionState.ownerStrategyId, m_positionState.type, ownerName, shortName);
      if(exitSignal != SIGNAL_NONE)
        {
         m_executionService.ClosePosition(m_positionState, "Exit " + shortName);
         m_logger.Trade("EXIT", "Signal exit from " + ownerName);
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
         RefreshStartBlockReason();

         if(m_started)
           {
            if(m_positionState.hasPosition)
               return;
            m_started = false;
            ReleaseRunningInstance();
           }
         else
           {
            if(m_startBlockedReason != "")
              {
               if(m_settings.panelEnabled && !m_settings.isTester)
                  m_panel.Update(BuildPanelSnapshot());
               return;
              }
            if(!RegisterRunningInstance())
               return;
            m_started = true;
           }
         RefreshStartBlockReason();
         m_panel.Update(BuildPanelSnapshot());
         PersistChartState();
         return;
        }

      if(command.type == UI_COMMAND_SAVE_PROFILE)
        {
         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;

         SEASettings settingsToSave = m_settings;
         if(command.hasSettings)
            settingsToSave = command.settings;
         settingsToSave.isTester = m_settings.isTester;
         ResolveOperationalTimeframes(settingsToSave, OperationalFallbackTimeframe());

         if(!CanPersistProfile(profileName, settingsToSave))
            return;

         if(!ApplySettings(settingsToSave, command.reloadScope))
            return;

         if(m_settingsStore.SaveProfile(profileName, m_settings))
            m_activeProfileName = profileName;
         RefreshStartBlockReason();

         if(m_settings.panelEnabled && !m_settings.isTester)
           {
            m_panel.LoadSettings(m_settings, m_activeProfileName, SymbolSpec());
            m_panel.Update(BuildPanelSnapshot());
           }

         PersistChartState();
         return;
        }

      if(command.type == UI_COMMAND_LOAD_PROFILE)
        {
         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;

         SEASettings loadedSettings;
         if(m_settingsStore.LoadProfile(profileName, loadedSettings))
           {
            loadedSettings.isTester = m_settings.isTester;
            ResolveOperationalTimeframes(loadedSettings, OperationalFallbackTimeframe());
            if(!ApplySettings(loadedSettings, RELOAD_COLD))
               return;
            m_activeProfileName = profileName;
            RefreshStartBlockReason();

            if(m_settings.panelEnabled && !m_settings.isTester)
              {
               m_panel.LoadSettings(m_settings, m_activeProfileName, SymbolSpec());
               m_panel.Update(BuildPanelSnapshot());
              }

            PersistChartState();
           }
         return;
        }
     }

   public:
                     CFusionApplication(void)
     {
      SetDefaultSettings(m_settings);
      ResetPositionRuntimeState(m_positionState);
      m_chartContext.chartId = 0;
      m_chartContext.symbol = "";
      m_chartContext.timeframe = "";
      m_chartContext.periodValue = 0;
      m_chartContext.deinitReason = -1;
      m_activeProfileName   = "default";
      m_started             = false;
      m_modulesRegistered   = false;
      m_lastNettingWarning  = 0;
      m_runtimeBlocked      = false;
      m_runtimeBlockReason  = "";
      m_startBlockedReason  = "";
      m_runtimeNotice       = "";
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
      m_runtimeBlocked = false;
      m_runtimeBlockReason = "";
      m_startBlockedReason = "";
      m_runtimeNotice = "";

      bool defaultProfileLoaded = false;
      SEASettings bootSettings = m_settings;
      if(TryLoadProfileForBoot(m_settings.defaultProfileName, bootSettings))
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
      SPositionRuntimeState restoredState;
      ResetPositionRuntimeState(restoredState);

      if(m_settings.autoRestoreChartState &&
         m_settingsStore.LoadChartState(m_chartContext.chartId, restoredContext, restoredProfile, restoredStarted, restoredSettings, restoredState))
        {
         if(ShouldRestoreSavedState(restoredContext))
           {
            restoredStateApplied = true;
            restoredSettings.isTester = m_settings.isTester;
            ENUM_TIMEFRAMES restoreFallback = (restoredContext.periodValue > 0)
                                              ? (ENUM_TIMEFRAMES)restoredContext.periodValue
                                              : OperationalFallbackTimeframe();
            ResolveOperationalTimeframes(restoredSettings, restoreFallback);
            m_settings = restoredSettings;
            if(restoredContext.symbol != "")
               m_chartContext.symbol = restoredContext.symbol;
            if(restoredContext.timeframe != "")
               m_chartContext.timeframe = restoredContext.timeframe;
            if(restoredContext.periodValue > 0)
               m_chartContext.periodValue = restoredContext.periodValue;
            m_chartContext.deinitReason = restoredContext.deinitReason;
            m_activeProfileName = (restoredProfile == "") ? m_settings.defaultProfileName : restoredProfile;
            m_positionState = restoredState;

            if(restoredContext.symbol != "" && restoredContext.symbol != _Symbol)
              {
               ApplyRuntimeBlock("Ativo do grafico mudou. Volte para " + restoredContext.symbol + ". Nao troque o ativo com o EA anexado. Isso pode causar prejuizo financeiro.");
              }
            else
              {
               // Regra de seguranca: em grafico real/demo o start exige clique manual.
               m_started = m_settings.isTester;
              }
           }
        }

      if(!restoredStateApplied && !defaultProfileLoaded && !m_settings.isTester && !m_runtimeBlocked && m_runtimeNotice == "")
         ApplyRuntimeNotice("Perfil " + m_settings.defaultProfileName + " nao foi encontrado. O Fusion manteve os inputs atuais ate voce carregar ou salvar um perfil.");
      RefreshStartBlockReason();
      uint restoreDoneTick = GetTickCount();

      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_normalizer.Init(&m_logger, _Symbol);
      m_riskManager.Init(&m_logger);
      m_protectionManager.Init(&m_logger, m_settings);
      m_executionService.Init(&m_logger, &m_normalizer, _Symbol, m_settings);

      RegisterModules();
      ConfigureResolver();

      if(!m_signalManager.Initialize(&m_logger, _Symbol, m_settings))
         return false;
      uint signalDoneTick = GetTickCount();

      if(!m_runtimeBlocked)
         m_executionService.SyncPosition(m_positionState);

      if(m_runtimeBlocked)
         m_logger.Warn("CONTEXT", m_runtimeBlockReason);
      else if(m_runtimeNotice != "")
         m_logger.Warn("CONTEXT", m_runtimeNotice);

      if(!m_runtimeBlocked && (m_started || m_positionState.hasPosition) && !RegisterRunningInstance())
         m_started = false;

      if(m_settings.panelEnabled && !m_settings.isTester)
        {
         int chartWidth = (int)ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS);
         int x1 = chartWidth - FUSION_PANEL_WIDTH - 10;
         if(x1 < 10)
            x1 = 10;

         if(!m_panel.CreatePanel(ChartID(),
                                  FusionWindowTitle(),
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
      m_panel.Destroy(reason);
      m_signalManager.Shutdown();
     }

   void              OnTick(void)
     {
      if(m_runtimeBlocked)
         return;

      SyncPositionState();

      if(m_positionState.hasPosition)
        {
         ManageOpenPosition();
         return;
        }

      if(!m_started)
         return;

      string blockReason = "";
      if(!m_settings.isTester)
         m_instanceRegistry.Refresh();

      if(HasForeignNettingPosition(blockReason))
        {
         datetime now = TimeCurrent();
         if(now - m_lastNettingWarning >= 60)
           {
            m_logger.Warn("NETTING", blockReason);
            m_lastNettingWarning = now;
           }
         return;
        }

      if(!m_protectionManager.CanOpen(_Symbol, blockReason))
         return;

      SSignalDecision decision;
      ResetSignalDecision(decision);
      if(!m_signalManager.GetEntryDecision(decision))
         return;

      if(decision.signal == SIGNAL_NONE)
         return;

      if(!m_protectionManager.IsDirectionAllowed(decision.signal, blockReason))
         return;

      double entryPrice = (decision.signal == SIGNAL_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                          : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      SRiskPlan plan;
      if(!m_riskManager.BuildEntryPlan(decision.signal, m_settings, SymbolSpec(), entryPrice, plan))
         return;

      if(m_executionService.PlaceEntry(decision.signal, plan, decision, m_positionState))
         PersistChartState();
     }

   void              OnTimer(void)
     {
      if((m_started || m_positionState.hasPosition) && !m_settings.isTester)
         m_instanceRegistry.Refresh();

      RefreshStartBlockReason();

      if(m_settings.panelEnabled && !m_settings.isTester)
         m_panel.Update(BuildPanelSnapshot());
     }

   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_settings.panelEnabled || m_settings.isTester)
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
     }
  };

#endif
