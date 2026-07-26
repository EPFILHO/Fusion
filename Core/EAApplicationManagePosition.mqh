#ifndef __FUSION_EA_APPLICATION_MANAGE_POSITION_MQH__
#define __FUSION_EA_APPLICATION_MANAGE_POSITION_MQH__

   void                    ManageOpenPosition(void)
     {
      if(!m_positionState.hasPosition)
         return;

      if(!PositionSelectByTicket(m_positionState.ticket))
        {
         m_executionService.MarkNeedsSync();
         return;
        }

      if(!RefreshTradePermissionState())
         return;

      m_positionState.volume     = PositionGetDouble(POSITION_VOLUME);
      m_positionState.stopLoss   = PositionGetDouble(POSITION_SL);
      m_positionState.takeProfit = PositionGetDouble(POSITION_TP);

      double currentPrice = (m_positionState.type == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                            : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double floatingProfit = PositionGetDouble(POSITION_PROFIT);
      ReconcileOpenPositionPartials(true, false);
      double protectionFloatingProfit = EffectiveFloatingProfit(floatingProfit);

      string forceReason = "";
      if(m_protectionManager.ShouldForceClose(m_positionState, protectionFloatingProfit, forceReason))
        {
         if(m_positionState.partialClosePending &&
            m_executionService.IsOrderActive(m_positionState.pendingPartialOrderTicket))
           {
            if(!m_pendingPartialForceCloseWaitLogged)
              {
               m_pendingPartialForceCloseWaitLogged = true;
               m_logger.Warn("PROTECT", "Saida forcada aguardando a ordem parcial ativa terminar para evitar sobre-execucao.");
              }
            return;
           }

         m_logger.Trade("PROTECT", "Forced exit: " + forceReason);
         m_executionService.ClosePosition(m_positionState, forceReason);
         return;
        }

      if(m_settings.usePartialTP && !m_positionState.partialClosePending)
        {
         if(!m_positionState.tp1Executed &&
            m_positionState.tp1Volume > 0.0 &&
            m_positionState.tp1Price > 0.0 &&
            PriceReached(m_positionState.type, currentPrice, m_positionState.tp1Price))
           {
            if(SubmitPartialClose(PARTIAL_CLOSE_TP1,
                                  m_positionState.tp1Volume,
                                  "Partial TP1",
                                  floatingProfit))
               return;
           }

         if(!m_positionState.tp2Executed &&
            m_positionState.tp2Volume > 0.0 &&
            m_positionState.tp2Price > 0.0 &&
            PriceReached(m_positionState.type, currentPrice, m_positionState.tp2Price))
           {
            if(SubmitPartialClose(PARTIAL_CLOSE_TP2,
                                  m_positionState.tp2Volume,
                                  "Partial TP2",
                                  floatingProfit))
               return;
           }
        }

      double newSL = 0.0;
      if(m_riskManager.CalculateBreakevenSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         double oldSL = m_positionState.stopLoss;
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.breakevenActive = true;
            m_logger.Trade("RISK", "Breakeven activated SL " + DoubleToString(oldSL, SymbolSpec().digits) + " -> " + DoubleToString(newSL, SymbolSpec().digits));
            PersistChartState();
           }
        }

      if(m_riskManager.CalculateTrailingSL(m_positionState, m_settings, SymbolSpec(), currentPrice, newSL))
        {
         double oldSL = m_positionState.stopLoss;
         if(m_executionService.ModifyStops(m_positionState, newSL, m_positionState.takeProfit))
           {
            m_positionState.trailingActive = true;
            m_logger.Trade("RISK", "Trailing stop updated SL " + DoubleToString(oldSL, SymbolSpec().digits) + " -> " + DoubleToString(newSL, SymbolSpec().digits));
            TryRemoveFreeFinalTakeProfit();
            PersistChartState();
           }
        }

      if(TryRemoveFreeFinalTakeProfit())
         PersistChartState();

      string ownerName = "";
      string shortName = "";
      ENUM_SIGNAL_TYPE exitSignal = m_signalManager.GetExitSignal(m_positionState.ownerStrategyId, m_positionState.type, ownerName, shortName);
      if(exitSignal != SIGNAL_NONE)
        {
         ENUM_EXIT_MODE exitMode = EXIT_TP_SL;
         bool reverseExit = (m_signalManager.GetStrategyExitMode(m_positionState.ownerStrategyId, exitMode) &&
                             exitMode == EXIT_REVERSE_SIGNAL);
         string ownerStrategyId = m_positionState.ownerStrategyId;
         string ownerStrategyName = (ownerName != "") ? ownerName : m_positionState.ownerStrategyName;

         if(m_executionService.ClosePosition(m_positionState, "Exit " + shortName))
           {
            m_logger.Trade("EXIT", "Signal exit from " + ownerName);
            if(reverseExit)
              {
               m_pendingReverseExit.Arm(exitSignal, ownerStrategyId, ownerStrategyName, shortName);
               m_runtimeNotice = "VM armada: reversao direta sem filtros/direcao; guards operacionais ativos.";
              }
           }
        }
     }

   SSymbolSpec             SymbolSpec(void) const
     {
      SSymbolSpec spec;
      m_normalizer.GetSpec(spec);
      return spec;
     }

#endif
