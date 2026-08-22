#ifndef __FUSION_EA_APPLICATION_ENTRY_BLOCK_MQH__
#define __FUSION_EA_APPLICATION_ENTRY_BLOCK_MQH__

   void                    DiscardBlockedEntrySignals(const string reason)
     {
      if(!m_started || m_positionState.hasPosition)
         return;

      m_signalManager.PrimeEntryStates();
      if(ShouldLogDiscardedSignalDebug(reason))
         m_logger.Debug("SIGNAL", "Sinais descartados durante bloqueio: " + reason);
     }

   //+------------------------------------------------------------------+
   //| Handoff do estado de entrada na troca do timeframe visual.        |
   //|                                                                    |
   //| Substitui — e SOMENTE — o antigo PrimeEntryStates() que rodava     |
   //| apos REASON_CHARTCHANGE. Os outros oito chamadores do priming      |
   //| generico continuam com a semantica de sempre.                     |
   //|                                                                    |
   //| Quatro desfechos: integral, parcial, nenhuma ativa restaurada e    |
   //| fallback conservador. Em qualquer um deles a barreira do intervalo |
   //| cego e armada em TODAS as estrategias, inclusive desligadas: e ela |
   //| que impede um sinal formado enquanto o EA se reinicializava de     |
   //| virar entrada.                                                     |
   //+------------------------------------------------------------------+
   void                    RestoreEntryStateAfterChartChange(const SEntryStateSnapshot &entryState,
                                                             const string entryStateError,
                                                             const SEASettings &originSettings,
                                                             const bool originKnown,
                                                             const bool sameSymbol,
                                                             const bool wasStarted)
     {
      //--- ⚠ `CanOpen()` fica para DEPOIS do veredito preliminar. Ele nao e
      //--- consulta inocente — pode fixar limite diario, armar drawdown e
      //--- produzir diagnostico —, e arquivo antigo, bloco invalido, inelegivel
      //--- ou vencido nao merecem provocar avaliacao mutavel de protecao.
      SEntryHandoffContext context;
      context.originSettingsKnown  = originKnown;
      context.wasChartChange       = (m_chartContext.deinitReason == REASON_CHARTCHANGE);
      context.sameSymbol           = sameSymbol;
      context.wasStarted           = wasStarted;
      context.hasPositionOrPending = HasManagedOrPendingPosition();
      context.operationalBlocked   = m_runtimeBlocked;
      context.permissionBlocked    = m_tradePermissionGuard.IsBlocked();
      context.protectionBlocked    = false;
      context.now                  = TimeLocal();

      ENUM_ENTRY_HANDOFF_RESULT verdict = FusionEvaluateEntryHandoff(entryState, context);

      //--- So agora, e so se tudo o mais passou.
      string protectionReason = "";
      if(verdict == ENTRY_HANDOFF_ACCEPTED)
        {
         context.protectionBlocked = !m_protectionManager.CanOpen(_Symbol, protectionReason);
         verdict = FusionEvaluateEntryHandoff(entryState, context);
        }

      if(verdict != ENTRY_HANDOFF_ACCEPTED)
        {
         m_signalManager.PrimeEntryStates();
         m_signalManager.SuspendEntriesUntilFreshCandleVisualAll();

         string why = FusionEntryHandoffReason(verdict);
         if(entryStateError != "")
            why += " (" + entryStateError + ")";

         //--- ⚠ "bloqueio operacional, de permissao ou de protecao" nao e motivo
         //--- exato: e a categoria. Quem investiga precisa saber QUAL, e o dado
         //--- existe — so estava sendo jogado fora.
         if(verdict == ENTRY_HANDOFF_BLOCKED)
           {
            if(m_runtimeBlocked && m_runtimeBlockReason != "")
               why += " — " + m_runtimeBlockReason;
            else if(context.permissionBlocked)
               why += " — " + m_tradePermissionGuard.Notice();
            else if(context.protectionBlocked && protectionReason != "")
              {
               why += " — " + protectionReason;
               //--- O aviso ACIONAVEL da protecao vai pelo caminho de sempre,
               //--- com a mesma politica do OnTick. Publicado antes do handoff,
               //--- ele naturalmente impede o aviso generico de tomar a tela.
               ApplyProtectionNotice(protectionReason, !IsSpreadProtectionNotice(protectionReason));
              }
           }

         //--- ⚠ Posicao (ou reconciliacao) vem ANTES de qualquer outro desfecho.
         //--- Com operacao viva, o que o operador precisa saber e que o
         //--- gerenciamento continua — e isso vale mesmo quando o arquivo era
         //--- antigo e nem trazia bloco `entry.*`. A existencia da posicao JA E
         //--- o motivo esperado para nao restaurar sinais de entrada: nao ha
         //--- nada a acionar, entao nao ha aviso a dar. Falar em "estado de
         //--- entrada descartado" aqui parecia incluir a operacao ja aberta —
         //--- m_runtimeNotice e informativo e nao bloqueia o OnTick, que segue
         //--- por ManageOpenPosition(). Priming e barreira acima ficam intocados.
         if(context.hasPositionOrPending)
           {
            m_logger.Info("SIGNAL",
                          m_positionState.hasPosition
                          ? "Troca de timeframe concluida. A posicao aberta continua sendo gerenciada normalmente; nenhuma nova entrada sera aberta enquanto ela permanecer ativa."
                          : "Troca de timeframe concluida. O fechamento da posicao continua sendo conferido; novas entradas permanecem suspensas ate a conclusao.");

            if(m_settings.debugLogs)
               m_logger.Debug("SIGNAL",
                              m_positionState.hasPosition
                              ? "Novos sinais de entrada nao foram preservados porque ja havia uma posicao aberta no momento da troca de timeframe."
                              : "Novos sinais de entrada nao foram preservados porque o fechamento da posicao ainda estava em reconciliacao.");
           }
         //--- Bloco ausente numa troca visual real: houve descarte de sinais, e
         //--- isso merece registro — mas nao e anomalia, entao fica em INFO e
         //--- nao chega a tela.
         else if(verdict == ENTRY_HANDOFF_NO_BLOCK)
            m_logger.Info("SIGNAL",
                          "Troca do timeframe visual sem estado de entrada gravado; " +
                          "sinais atuais descartados e aguardando sinal novo.");
         else
           {
            m_logger.Warn("SIGNAL",
                          "Estado de entrada nao pode ser restaurado apos troca do timeframe visual; " +
                          "sinais atuais descartados por seguranca: " + why + ".");
            ApplyHandoffNotice("Sinais descartados na troca de timeframe: " + why + ".");
           }
         return;
        }

      int    activeImported = 0;
      int    activeFailed   = 0;
      string importedList   = "";
      string failedList     = "";
      string inactiveList   = "";
      m_signalManager.RestoreEntryStatesOrPrimeSafely(entryState,
                                                      originSettings,
                                                      m_settings,
                                                      activeImported,
                                                      activeFailed,
                                                      importedList,
                                                      failedList,
                                                      inactiveList);

      //--- Armada DEPOIS da importacao: importar nao pode desarmar a protecao
      //--- do intervalo cego, e a barreira nao pode apagar o estado importado.
      m_signalManager.SuspendEntriesUntilFreshCandleVisualAll();

      //--- ⚠ Estrategia DESLIGADA nao e falha. Ela e resetada por seguranca e
      //--- aparece so no debug: contar RSI e Bollinger desligados como "parcial"
      //--- fazia a configuracao mais comum — so MA ativa — anunciar restauracao
      //--- parcial em toda troca de timeframe. Aviso que aparece sempre deixa de
      //--- ser aviso.
      //--- ⚠ QUATRO desfechos, e nao tres. `activeFailed == 0` tambem e verdade
      //--- quando NAO HAVIA estrategia ativa nenhuma — e ai dizer "estrategias
      //--- ativas restauradas" seria afirmar algo que nao aconteceu. A GUI
      //--- normalmente impede esse perfil, mas arquivo antigo, input ou estado
      //--- defeituoso chegam aqui do mesmo jeito.
      if(activeImported > 0 && activeFailed == 0)
        {
         m_logger.Info("SIGNAL",
                       "Estado logico de entrada preservado apos troca do timeframe visual; " +
                       "estrategias ativas compativeis restauradas.");
        }
      else if(activeImported > 0 && activeFailed > 0)
        {
         m_logger.Warn("SIGNAL",
                       "Estado de entrada restaurado parcialmente apos troca do timeframe visual — " +
                       "restauradas: " + importedList + "; primeadas: " + failedList + ".");
         ApplyHandoffNotice("Estado de entrada restaurado parcialmente na troca de timeframe.");
        }
      else if(activeFailed > 0)
        {
         m_logger.Warn("SIGNAL",
                       "Nao foi possivel restaurar nenhuma estrategia ativa apos a troca do timeframe " +
                       "visual; sinais atuais descartados por seguranca — primeadas: " + failedList + ".");
         ApplyHandoffNotice("Sinais descartados na troca de timeframe: nao foi possivel restaurar nenhuma estrategia ativa.");
        }
      else
        {
         //--- Nenhuma estrategia ativa. Reset e barreira ja foram aplicados; nao
         //--- ha o que restaurar e nao ha alerta a dar — o proprio perfil sem
         //--- estrategia ja impede operar.
         m_logger.Info("SIGNAL",
                       "Troca de timeframe sem estrategia de entrada ativa; " +
                       "estados mantidos em espera segura.");
        }

      if(m_settings.debugLogs)
         m_logger.Debug("SIGNAL",
                        "Restauradas: " + (importedList == "" ? "nenhuma" : importedList) +
                        ". Desligadas resetadas: " + (inactiveList == "" ? "nenhuma" : inactiveList) + ".");

     }

   //--- ⚠ O aviso do handoff e o MENOS importante da fila. ApplyRuntimeNotice
   //--- apenas substitui o texto, entao aplica-lo as cegas apagaria "AutoTrading
   //--- desabilitado" — que e acionavel — por "sinais descartados", que so
   //--- informa. Se ha bloqueio de contexto ou qualquer aviso ja no ar, o
   //--- handoff fica somente no log.
   void                    ApplyHandoffNotice(const string notice)
     {
      if(m_runtimeBlocked || m_runtimeNotice != "")
         return;

      //--- Publicou de fato: so agora o handoff assume a propriedade do texto.
      m_handoffNoticeText = notice;
      ApplyRuntimeNotice(notice);
     }

   //--- Limpeza EXCLUSIVA do aviso de handoff. Fecha o caso irmao: o fallback
   //--- acontece sem posicao, publica o aviso, e uma posicao abre depois — com
   //--- posicao viva o OnTick so chama ClearProtectionNotice(), que retorna na
   //--- primeira linha quando `m_protectionNoticeActive` e falso, entao o aviso
   //--- do handoff ficava preso durante a posicao e podia permanecer inclusive
   //--- depois do fechamento.
   //---
   //--- ⚠ Zerar `m_runtimeNotice` as cegas apagaria AutoTrading, protecao ou
   //--- perfil — avisos ACIONAVEIS que podem ter substituido o handoff desde a
   //--- publicacao. Por isso a comparacao exata: se o texto ja nao e o meu, a
   //--- propriedade acabou e o handoff apenas esquece o seu, sem tocar na tela.
   void                    ClearHandoffNotice(void)
     {
      if(m_handoffNoticeText == "")
         return;

      if(m_runtimeNotice == m_handoffNoticeText)
         m_runtimeNotice = "";

      m_handoffNoticeText = "";
     }

   void                    ApplyEntryBlockNotice(const string reason)
     {
      if(reason == "")
        {
         ClearEntryBlockNotice();
         return;
        }

      bool changed = (!m_entryBlockNoticeActive || m_entryBlockNoticeReason != reason);
      m_entryBlockNoticeActive = true;
      m_entryBlockNoticeReason = reason;
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";

      if(changed)
         m_logger.Info("SIGNAL", reason);
     }

   void                    ApplyRiskStopsEntryBlockNotice(const string reason,
                                                         const string detail)
     {
      if(reason == "")
        {
         ClearEntryBlockNotice();
         return;
        }

      m_entryBlockNoticeActive = true;
      m_entryBlockNoticeReason = reason;
      m_entryBlockNoticeIsRiskStops = true;
      m_entryBlockNoticeDetail = detail;
     }

   string                  FormatDirectionBlockReason(const SSignalDecision &decision,const string reason) const
     {
      string strategyName = (decision.strategyName != "") ? decision.strategyName : decision.shortName;
      string text = "Entrada " + SignalToString(decision.signal);
      if(strategyName != "")
         text += " da " + strategyName;
      text += " bloqueada por Direcao";
      if(reason != "")
         text += ": " + reason;
      return text;
     }

   bool                    RefreshTradePermissionState(void)
     {
      bool wasBlocked = m_tradePermissionGuard.IsBlocked();
      if(m_tradePermissionGuard.Refresh(m_positionState.hasPosition))
        {
         if(wasBlocked)
           {
            m_runtimeNotice = m_protectionNoticeActive ? m_protectionNoticeReason : "";
            //--- Fronteira unica da transicao bloqueado->liberado. Sem ticks durante o
            //--- bloqueio, DiscardBlockedEntrySignals nunca rodou e o estado das
            //--- estrategias ficou parado no momento da queda: o primeiro tick de volta
            //--- encontrava um cruzamento formado no escuro e abria ordem atrasada.
            //--- Aqui, os seis chamadores desta funcao (Initialize, OnTick, OnTimer,
            //--- TryPlaceEntryDecision, ManageOpenPosition e o comando INICIAR) passam
            //--- pelo mesmo ponto, entao a regra nao precisa ser repetida em nenhum
            //--- deles.
            //---
            //--- A barreira e armada mesmo com posicao aberta e mesmo com o EA pausado:
            //--- ela so restringe ENTRADA, e o estado de saida nao e tocado. Priming e
            //--- barreira sao coisas distintas - o priming consome o [1] atual, a
            //--- barreira recusa tambem o candle que ja estava aberto na liberacao.
            m_signalManager.SuspendEntriesUntilFreshCandle();
            DiscardBlockedEntrySignals("Permissao de trading restaurada.");
           }
         return true;
        }

      m_runtimeNotice = m_tradePermissionGuard.Notice();
      if(m_started && !m_positionState.hasPosition)
        {
         // Trading permission can disappear briefly during broker reconnects.
         // Keep the EA running so it resumes automatically when permissions return.
         m_pendingReverseExit.Reset();
        }
      return false;
     }

   void                    RecordClosedStrategyBar(const string strategyId)
     {
      m_lastClosedStrategyId = strategyId;
      m_lastClosedStrategyBarTime = 0;

      if(strategyId == "")
         return;

      ENUM_TIMEFRAMES timeframe = FUSION_DEFAULT_TIMEFRAME;
      if(!m_signalManager.GetStrategyReferenceTimeframe(strategyId, timeframe))
         return;

      m_lastClosedStrategyBarTime = iTime(_Symbol, timeframe, 0);
     }

   bool                    IsReentryBlockedThisBar(const string strategyId,string &reason)
     {
      reason = "";

      if(strategyId == "" || strategyId != m_lastClosedStrategyId || m_lastClosedStrategyBarTime <= 0)
         return false;

      ENUM_TIMEFRAMES timeframe = FUSION_DEFAULT_TIMEFRAME;
      if(!m_signalManager.GetStrategyReferenceTimeframe(strategyId, timeframe))
         return false;

      datetime currentBarTime = iTime(_Symbol, timeframe, 0);
      if(currentBarTime != m_lastClosedStrategyBarTime)
         return false;

      reason = "Ja operou neste candle da estrategia - aguardando proximo.";
      return true;
     }

#endif
