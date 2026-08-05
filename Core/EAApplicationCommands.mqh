#ifndef __FUSION_EA_APPLICATION_COMMANDS_MQH__
#define __FUSION_EA_APPLICATION_COMMANDS_MQH__

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

      //+---------------------------------------------------------------+
      //| Desfazer: volta a configuracao que este grafico ja usava.      |
      //|                                                                |
      //| Nao troca de perfil, nao grava e nao mexe em m_activeProfileName|
      //| — por isso nao passa pelas recusas de CARGA. Elas existem para  |
      //| impedir que o grafico ADOTE outra identidade no meio de uma     |
      //| operacao; aqui a identidade que volta e a dele.                 |
      //|                                                                |
      //| A reconciliacao pendente CONTINUA barrando: ali o EA aguarda o  |
      //| historico confirmar um fechamento, e mexer na configuracao      |
      //| durante isso e inseguro por outro motivo, que este comando nao  |
      //| resolve.                                                        |
      //|                                                                |
      //| Preferir as configuracoes recebidas ao arquivo e o que torna o  |
      //| desfazer GARANTIDO: quem chama guardou o estado anterior em     |
      //| memoria antes de arriscar a operacao, e o arquivo do perfil     |
      //| ativo pode ser exatamente o que sumiu ou nao abre.              |
      //+---------------------------------------------------------------+
      if(command.type == UI_COMMAND_RESTORE_ACTIVE_PROFILE)
        {
         if(m_closeReconciliationPending)
           {
            m_logger.Warn("PROFILE", "Configuracao nao restaurada enquanto o fechamento aguarda confirmacao do historico.");
            return;
           }

         SEASettings restoreSettings = m_settings;
         if(command.hasSettings)
            restoreSettings = command.settings;
         else
           {
            string sourceProfile = (command.text == "") ? m_activeProfileName : command.text;
            if(!m_settingsStore.LoadProfile(sourceProfile, restoreSettings))
              {
               m_logger.Warn("PROFILE", "Configuracao nao restaurada: perfil " + sourceProfile +
                             " nao pode ser lido e nenhum estado anterior foi informado.");
               return;
              }
           }

         restoreSettings.isTester = m_settings.isTester;
         ResolveOperationalTimeframes(restoreSettings, OperationalFallbackTimeframe());
         if(!ApplySettings(restoreSettings, RELOAD_COLD))
            return;

         m_logger.Info("PROFILE", "Configuracao anterior restaurada no perfil " + m_activeProfileName + ".");
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
         //--- mesma razao do boot: diagnostico e de sessao, nao do perfil
         loadedSettings.debugLogs = inp_EnableDebugLogs;
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
         // Se o EA estava bloqueado por nao conseguir carregar o perfil do grafico,
         // escolher um perfil aqui resolve a causa e libera a operacao. Outros
         // bloqueios (troca de ativo, por exemplo) nao sao afetados.
         if(m_runtimeBlockedByChartProfile)
           {
            m_runtimeBlocked = false;
            m_runtimeBlockReason = "";
            m_runtimeBlockedByChartProfile = false;
            m_logger.Info("PROFILE", "Perfil " + profileName + " escolhido pelo painel; bloqueio por perfil ausente liberado.");
           }
         m_logger.Info("PROFILE", "Perfil " + profileName + " carregado pelo painel (Magic " +
                       IntegerToString(m_settings.magicNumber) + ", lote " +
                       DoubleToString(m_settings.fixedLot, 2) + ").");
         RefreshProfileBlockReasons();

         ReloadPanelSettingsIfVisible();

         PersistChartState();
         return;
        }
     }

#endif
