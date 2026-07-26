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
            m_runtimeNotice = m_protectionNoticeActive ? m_protectionNoticeReason : "";
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
