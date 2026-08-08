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
      //--- panelEnabled tambem nao pertence ao perfil, e pelo mesmo motivo:
      //--- mostrar ou nao a GUI e preferencia de quem opera AQUELE grafico, e
      //--- nao caracteristica da estrategia — dois graficos com o mesmo perfil
      //--- podem querer coisas diferentes. Ver a nota completa em ApplySettings.
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
      //| panelEnabled: o INPUT manda, sempre.                           |
      //|                                                                |
      //| ShouldShowPanel() ja documenta que "o input do usuario manda em |
      //| qualquer contexto" — e o comportamento nao cumpria o proprio    |
      //| contrato, porque o campo e gravado no perfil e o perfil vencia  |
      //| o input no boot.                                                |
      //|                                                                |
      //| ⚠ Nao era so incomodo: era um estado SEM SAIDA pela interface.  |
      //| Numa instalacao nova, o Initialize cria o `default.cfg` a partir |
      //| dos inputs quando o arquivo nao existe. Com inp_ShowPanel=false  |
      //| nesse primeiro anexo, o perfil nascia com panelEnabled=0 — e     |
      //| dali em diante o painel nunca mais aparecia para aquele perfil,  |
      //| nem pondo o input em true. Para religar a GUI seria preciso a    |
      //| GUI. Sobrava editar o .cfg a mao. E a licao 2 da secao 8 no caso |
      //| extremo em que o bloqueio E a interface.                         |
      //|                                                                |
      //| O campo continua no arquivo, para nao mexer no schema (e o       |
      //| FUSION_SETTINGS_SCHEMA_LINE_COUNT ja custou um incidente). Ele   |
      //| simplesmente deixa de ter autoridade, como o isTester.           |
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
