#ifndef __FUSION_EA_APPLICATION_MODULES_MQH__
#define __FUSION_EA_APPLICATION_MODULES_MQH__

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
      // O input do usuario manda em qualquer contexto; no tester o modo visual
      // e um pre-requisito adicional, nunca um motivo para forcar o painel.
      if(!m_settings.panelEnabled)
         return false;
      return (!m_settings.isTester || IsVisualTester());
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

#endif
