#ifndef __FUSION_EA_APPLICATION_SETTINGS_MQH__
#define __FUSION_EA_APPLICATION_SETTINGS_MQH__

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
      //--- debugLogs nao pertence ao perfil: e diagnostico de sessao, decidido
      //--- pelo input. Sem esta linha o carregamento traria o valor padrao
      //--- (falso) do SetDefaultSettings e apagaria a escolha do input.
      loadedSettings.debugLogs = inp_EnableDebugLogs;
      //--- panelEnabled tambem nao pertence ao perfil: exibir a GUI nao e
      //--- caracteristica da estrategia. Ele so decide alguma coisa no Strategy
      //--- Tester — no grafico ShouldShowPanel ignora o campo e o painel sempre
      //--- aparece. A linha existe para o input mandar la, e para o estado nao
      //--- carregar um valor de arquivo que ninguem mais consulta.
      loadedSettings.panelEnabled = inp_ShowPanel;
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
      //--- Fronteira de aplicacao: qualquer caminho que ative configuracoes
      //--- passa por aqui, inclusive o SALVAR do painel. Forcar o input aqui
      //--- garante que nenhum rascunho de GUI consiga contrariar o diagnostico
      //--- escolhido para a sessao.
      resolvedSettings.debugLogs = inp_EnableDebugLogs;
      //+---------------------------------------------------------------+
      //| panelEnabled: o perfil nunca decide isto. O input decide, e so  |
      //| no Strategy Tester — no grafico o painel aparece SEMPRE, e      |
      //| quem quer espaco minimiza (ver ShouldShowPanel).                |
      //|                                                                |
      //| ⚠ A politica mudou por causa de um estado SEM SAIDA pela        |
      //| interface, e a historia vale porque explica as duas metades.    |
      //| O campo e gravado no perfil e o perfil vencia o input no boot;  |
      //| numa instalacao nova, o Initialize cria o `default.cfg` a partir |
      //| dos inputs, entao com inp_ShowPanel=false no primeiro anexo o    |
      //| perfil nascia com panelEnabled=0 e o painel nunca mais aparecia  |
      //| — nem pondo o input em true. Para religar a GUI seria preciso a  |
      //| GUI, e a GUI e o unico lugar de onde se opera o EA.              |
      //|                                                                |
      //| Daí as duas decisoes: no grafico o painel deixou de ser          |
      //| opcional, e esta linha garante que, no tester, quem manda e o    |
      //| input — mesmo que exista um perfil na sandbox de arquivos de la. |
      //|                                                                |
      //| O campo continua no arquivo, para nao mexer no schema (e o       |
      //| FUSION_SETTINGS_SCHEMA_LINE_COUNT ja custou um incidente).       |
      //+---------------------------------------------------------------+
      resolvedSettings.panelEnabled = inp_ShowPanel;
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

#endif
