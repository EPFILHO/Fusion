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
         //+---------------------------------------------------------------+
         //| Estado da posicao ATUALIZADO antes das duas guardas.            |
         //|                                                                |
         //| ⚠ `m_positionState` e cache, e pode estar atrasado: o          |
         //| OnTradeTransaction so chama MarkNeedsSync(), e quem de fato    |
         //| atualiza e o SyncPositionState() do proximo OnTick/OnTimer.    |
         //| Entre a posicao aparecer e esse proximo passo existe uma       |
         //| janela em que a guarda abaixo leria `false` com posicao viva.  |
         //| Numa fronteira que protege dinheiro nao se depende de o cache  |
         //| ja ter sido atualizado.                                        |
         //|                                                                |
         //| ANTES da guarda de reconciliacao, e nao entre as duas: este    |
         //| mesmo passo pode DESCOBRIR que uma posicao acabou de fechar e  |
         //| iniciar a reconciliacao agora — e ai e a primeira guarda que   |
         //| tem de pegar.                                                  |
         //|                                                                |
         //| Custa uma varredura de posicoes por clique em CARREGAR. Nao e  |
         //| por quadro nem por tick.                                       |
         //|                                                                |
         //| ⚠ So com o runtime livre, como os dois outros chamadores       |
         //| (OnTick e OnTimer, ambos atras de `if(m_runtimeBlocked)`).     |
         //| Bloqueado por troca de ativo do grafico, sincronizar leria as  |
         //| posicoes do simbolo ERRADO e corromperia o estado — e carregar |
         //| perfil e permitido nesse bloqueio justamente por ser a saida   |
         //| dele.                                                          |
         //+---------------------------------------------------------------+
         if(!m_runtimeBlocked)
            SyncPositionState();

         if(m_closeReconciliationPending)
           {
            m_logger.Warn("PROFILE", "Perfil nao carregado enquanto o fechamento aguarda confirmacao do historico.");
            return;
           }

         //+---------------------------------------------------------------+
         //| Posicao em gerenciamento: a carga e recusada AQUI, no motor.    |
         //|                                                                |
         //| Carregar aplica ApplySettings, que troca a configuracao ativa  |
         //| inteira. Nao mexe no volume da posicao ja aberta, mas troca o  |
         //| MAGIC — e e por ele que o EA reconhece as proprias ordens —,   |
         //| alem de protecoes, filtros e lote das proximas entradas. Fazer |
         //| isso com uma operacao em curso rompe a fronteira que todo o    |
         //| resto do EA respeita.                                          |
         //|                                                                |
         //| ⚠ Os dois paineis JA deveriam recusar, e nao recusavam num     |
         //| caso: a permissao de carga abre uma excecao para o perfil      |
         //| preso por outro grafico (escolher outro perfil e a saida do    |
         //| bloqueio), e essa excecao era avaliada ANTES da trava local.   |
         //| Com posicao aberta mais peer lock, o botao acendia nos dois    |
         //| paineis e o comando chegava ate aqui.                          |
         //|                                                                |
         //| A GUI 2.0 fechou o furo do lado dela; esta guarda existe       |
         //| porque a autoridade e o motor: ela protege tambem a 1.058 e    |
         //| qualquer caminho futuro ate o mesmo comando.                   |
         //|                                                                |
         //| Estreita de proposito. NAO foi para dentro de ApplySettings,   |
         //| que serve tambem a restauracao e ao boot — contextos com       |
         //| semantica propria, onde recusar por posicao aberta quebraria o |
         //| desfazer de uma criacao falhada. Aqui vale so para o comando   |
         //| de CARREGAR vindo da interface.                                |
         //+---------------------------------------------------------------+
         if(m_positionState.hasPosition)
           {
            m_logger.Warn("PROFILE", "Perfil nao carregado enquanto existe posicao em gerenciamento.");
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
         //--- idem para o painel: o campo do arquivo nao decide nada, e no
         //--- grafico o painel aparece de qualquer forma (ShouldShowPanel). A
         //--- linha mantem o estado coerente com o input, que e quem manda no
         //--- tester.
         loadedSettings.panelEnabled = inp_ShowPanel;
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
