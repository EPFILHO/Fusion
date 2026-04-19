#ifndef __MODULAR_EA_APPLICATION_MQH__
#define __MODULAR_EA_APPLICATION_MQH__

#include "Inputs.mqh"
#include "Logger.mqh"
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
   CFusionPanel            m_panel;
   SPositionRuntimeState   m_positionState;
   string                  m_activeProfileName;
   bool                    m_started;
   bool                    m_modulesRegistered;

   string                  ChartStateKey(void) const
     {
      return _Symbol + "_" + IntegerToString((int)Period()) + "_" + IntegerToString(m_settings.magicNumber);
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
      snapshot.started          = m_started;
      snapshot.hasPosition      = m_positionState.hasPosition;
      snapshot.activeProfileName= m_activeProfileName;
      snapshot.symbol           = _Symbol;
      snapshot.timeframe        = EnumToString((ENUM_TIMEFRAMES)Period());
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
      return snapshot;
     }

   void                    PersistChartState(void)
     {
      if(!m_settings.autoSaveChartState || m_settings.isTester)
         return;

      m_settingsStore.SaveChartState(ChartStateKey(), m_activeProfileName, m_started, m_settings, m_positionState);
     }

   bool                    ApplySettings(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      m_settings = settings;
      ConfigureResolver();
      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_executionService.Reload(m_settings);
      m_protectionManager.Reload(m_settings, scope);
      if(!m_signalManager.ReloadAll(m_settings, scope))
         return false;

      if(m_settings.panelEnabled && !m_settings.isTester)
        {
         m_panel.LoadSettings(m_settings);
         m_panel.Update(BuildPanelSnapshot());
        }

      PersistChartState();
      return true;
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
         m_started = !m_started;
         m_panel.Update(BuildPanelSnapshot());
         PersistChartState();
         return;
        }

      if(command.type == UI_COMMAND_TOGGLE_MACROSS)
         m_settings.useMACross = !m_settings.useMACross;
      else if(command.type == UI_COMMAND_TOGGLE_RSI)
         m_settings.useRSI = !m_settings.useRSI;
      else if(command.type == UI_COMMAND_TOGGLE_BB)
         m_settings.useBollinger = !m_settings.useBollinger;
      else if(command.type == UI_COMMAND_TOGGLE_TREND_FILTER)
         m_settings.useTrendFilter = !m_settings.useTrendFilter;
      else if(command.type == UI_COMMAND_TOGGLE_RSI_FILTER)
         m_settings.useRSIFilter = !m_settings.useRSIFilter;
      else if(command.type == UI_COMMAND_SAVE_PROFILE)
        {
         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;
         if(m_settingsStore.SaveProfile(profileName, m_settings))
            m_activeProfileName = profileName;
         m_panel.SetProfileName(m_activeProfileName);
         m_panel.Update(BuildPanelSnapshot());
         PersistChartState();
         return;
        }
      else if(command.type == UI_COMMAND_LOAD_PROFILE)
        {
         string profileName = (command.text == "") ? m_activeProfileName : command.text;
         if(profileName == "")
            profileName = m_settings.defaultProfileName;

         SEASettings loadedSettings;
         if(m_settingsStore.LoadProfile(profileName, loadedSettings))
           {
            loadedSettings.isTester = m_settings.isTester;
            ApplySettings(loadedSettings, RELOAD_COLD);
            m_activeProfileName = profileName;
            m_panel.SetProfileName(m_activeProfileName);
            m_panel.LoadSettings(m_settings);
            m_panel.Update(BuildPanelSnapshot());
            PersistChartState();
           }
         return;
        }
      else if(command.type == UI_COMMAND_APPLY_SETTINGS)
        {
         SEASettings updated = m_settings;
         updated.fixedLot = m_panel.EditedFixedLot();
         updated.maxSpreadPoints = m_panel.EditedMaxSpread();
         updated.magicNumber = m_panel.EditedMagicNumber();
         updated.conflictMode = m_panel.EditedConflictMode();
         ApplySettings(updated, command.reloadScope);
         m_panel.LoadSettings(m_settings);
         m_panel.Update(BuildPanelSnapshot());
         PersistChartState();
         return;
        }

      ApplySettings(m_settings, RELOAD_HOT);
     }

public:
                     CFusionApplication(void)
     {
      SetDefaultSettings(m_settings);
      ResetPositionRuntimeState(m_positionState);
      m_activeProfileName   = "default";
      m_started             = false;
      m_modulesRegistered   = false;
     }

   bool              Initialize(void)
     {
      FillSettingsFromInputs(m_settings);
      m_settings.isTester = (bool)MQLInfoInteger(MQL_TESTER);
      m_activeProfileName = m_settings.defaultProfileName;
      m_started = m_settings.isTester;

      SEASettings restoredSettings = m_settings;
      string restoredProfile = "";
      bool restoredStarted = false;
      SPositionRuntimeState restoredState;
      ResetPositionRuntimeState(restoredState);

      if(m_settings.autoRestoreChartState &&
         m_settingsStore.LoadChartState(ChartStateKey(), restoredProfile, restoredStarted, restoredSettings, restoredState))
        {
         restoredSettings.isTester = m_settings.isTester;
         m_settings = restoredSettings;
         m_activeProfileName = (restoredProfile == "") ? m_settings.defaultProfileName : restoredProfile;
         m_started = m_settings.isTester ? true : restoredStarted;
         m_positionState = restoredState;
        }

      m_logger.Init(m_settings.debugLogs, _Symbol, m_settings.magicNumber, m_settings.isTester);
      m_normalizer.Init(&m_logger, _Symbol);
      m_riskManager.Init(&m_logger);
      m_protectionManager.Init(&m_logger, m_settings);
      m_executionService.Init(&m_logger, &m_normalizer, _Symbol, m_settings);

      RegisterModules();
      ConfigureResolver();

      if(!m_signalManager.Initialize(&m_logger, _Symbol, (ENUM_TIMEFRAMES)Period(), m_settings))
         return false;

      m_executionService.SyncPosition(m_positionState);

      if(m_settings.panelEnabled && !m_settings.isTester)
        {
         int chartWidth = (int)ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS);
         int x1 = chartWidth - FUSION_PANEL_WIDTH - 10;
         if(x1 < 10)
            x1 = 10;

         if(!m_panel.CreatePanel(ChartID(),
                                 "Fusion",
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

         m_panel.LoadSettings(m_settings);
         if(!m_panel.Run())
           {
            m_logger.Error("UI", "Failed to run Fusion panel");
            m_panel.Destroy(REASON_REMOVE);
            return false;
           }
        }

      EventSetTimer(1);
      return true;
     }

   void              Shutdown(const int reason)
     {
      EventKillTimer();
      PersistChartState();
      m_panel.Destroy(reason);
      m_signalManager.Shutdown();
     }

   void              OnTick(void)
     {
      SyncPositionState();

      if(m_positionState.hasPosition)
        {
         ManageOpenPosition();
         return;
        }

      if(!m_started)
         return;

      string blockReason = "";
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
      m_executionService.MarkNeedsSync();
     }
  };

#endif
