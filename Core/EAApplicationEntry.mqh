#ifndef __FUSION_EA_APPLICATION_ENTRY_MQH__
#define __FUSION_EA_APPLICATION_ENTRY_MQH__

   bool                    PriceReached(const ENUM_POSITION_TYPE type,const double currentPrice,const double targetPrice) const
     {
      if(targetPrice <= 0.0)
         return false;

      if(type == POSITION_TYPE_BUY)
         return currentPrice >= targetPrice;
      return currentPrice <= targetPrice;
     }

   bool                    TryPlaceEntryDecision(const SSignalDecision &decision,
                                                 const bool checkReentryBlock,
                                                 const bool bypassDirectionBlock)
     {
      if(decision.signal == SIGNAL_NONE)
         return false;

      if(!RefreshTradePermissionState())
        {
         ClearEntryBlockNotice();
         DiscardBlockedEntrySignals(m_tradePermissionGuard.Notice());
         return false;
        }

      string blockReason = "";
      if(!m_protectionManager.CanOpen(_Symbol, blockReason))
        {
         ClearEntryBlockNotice();
         ApplyProtectionNotice(blockReason, true, IsSpreadProtectionNotice(blockReason));
         DiscardBlockedEntrySignals(blockReason);
         return false;
        }

      if(ClearProtectionNotice(true))
        {
         m_signalManager.PrimeEntryStates();
         return false;
        }

      if(checkReentryBlock)
        {
         string reentryReason = "";
         if(IsReentryBlockedThisBar(decision.strategyId, reentryReason))
            {
             ClearEntryBlockNotice();
             DiscardBlockedEntrySignals(reentryReason);
             m_logger.Debug("BLOCKER", reentryReason);
             return false;
            }
        }

      if(!bypassDirectionBlock && !m_protectionManager.IsDirectionAllowed(decision.signal, blockReason))
        {
         ApplyEntryBlockNotice(FormatDirectionBlockReason(decision, blockReason));
         DiscardBlockedEntrySignals(blockReason);
         return false;
        }

      ClearEntryBlockNotice();

      double entryPrice = (decision.signal == SIGNAL_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                          : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      SRiskPlan plan;
      string runtimeStopsError = "";
      string runtimeStopsDetail = "";
      if(!m_riskManager.BuildEntryPlan(decision.signal, m_settings, SymbolSpec(), entryPrice, plan,
                                       runtimeStopsError, runtimeStopsDetail))
        {
         if(runtimeStopsError != "")
            ApplyRiskStopsEntryBlockNotice(runtimeStopsError, runtimeStopsDetail);
         return false;
        }

      if(m_executionService.PlaceEntry(decision.signal, plan, decision, m_positionState))
        {
         ClearStreakReleaseNotice();
         PersistChartState();
         return true;
        }

      return false;
     }

   void                    RefreshProtectionNoticeNow(const bool discardExistingSignals)
     {
      MaintainOperationalDayState();

      string blockReason = "";
      if(m_protectionManager.CanOpen(_Symbol, blockReason))
        {
         bool releasedStreak = ClearProtectionNotice(true);
         if(releasedStreak && discardExistingSignals)
            m_signalManager.PrimeEntryStates();
         return;
        }

      ApplyProtectionNotice(blockReason, !IsSpreadProtectionNotice(blockReason));
      if(discardExistingSignals)
         DiscardBlockedEntrySignals(blockReason);
     }

   void                    TryPlacePendingReverseExit(void)
     {
      SSignalDecision decision;
      if(!m_pendingReverseExit.TakeDecision(decision))
         return;

      m_runtimeNotice = "";

      if(!m_started)
         return;

      string blockReason = "";
      if(!m_settings.isTester)
         m_instanceRegistry.Refresh();

      if(HasForeignNettingPosition(blockReason))
        {
         LogNettingWarning(blockReason);
         return;
        }

      TryPlaceEntryDecision(decision, false, true);
     }

#endif
