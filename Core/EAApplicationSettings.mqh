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
