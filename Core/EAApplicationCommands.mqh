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
