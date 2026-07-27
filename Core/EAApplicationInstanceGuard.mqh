#ifndef __FUSION_EA_APPLICATION_INSTANCE_GUARD_MQH__
#define __FUSION_EA_APPLICATION_INSTANCE_GUARD_MQH__

   bool                    HasManagedOrPendingPosition(void) const
     {
      return (m_positionState.hasPosition || m_closeReconciliationPending);
     }

   void                    ResetTransientRuntimeState(void)
     {
      m_runtimeBlocked      = false;
      m_runtimeBlockReason  = "";
      m_runtimeBlockedByChartProfile = false;
      m_activeProfileFileMissing = false;
      m_startBlockedReason  = "";
      m_activeProfileBlockedReason = "";
      m_runtimeNotice       = "";
      m_protectionNoticeActive = false;
      m_protectionNoticeReason = "";
      m_entryBlockNoticeActive = false;
      m_entryBlockNoticeReason = "";
      m_entryBlockNoticeIsRiskStops = false;
      m_entryBlockNoticeDetail = "";
      m_lastDiscardDebugReason = "";
      m_lastDiscardDebugTime = 0;
      m_lastPersistentProtectWarnReason = "";
      m_lastPersistentProtectWarnDayKey = 0;
      m_pendingPartialForceCloseWaitLogged = false;
      m_lastPartialBaselineWarning = 0;
      m_lastLivePanelRefreshTick = 0;
     }

   SChartStateContext      CurrentChartContext(void) const
     {
      SChartStateContext context;
      context.chartId   = (ulong)ChartID();
      context.symbol    = _Symbol;
      context.timeframe = EnumToString((ENUM_TIMEFRAMES)Period());
      context.periodValue = (int)Period();
      context.deinitReason = -1;
      context.discardedUnsavedDraft = false;
      return context;
     }

   bool                    RegisterRunningInstance(void)
     {
      if(m_settings.isTester)
         return true;

      string reason = "";
      if(m_instanceRegistry.Register(_Symbol, m_settings.magicNumber, ChartID(), reason))
         return true;

      m_startBlockedReason = reason + " Carregue outro perfil antes de iniciar.";
      m_logger.Error("INSTANCE", reason);
      return false;
     }

   void                    ReleaseRunningInstance(void)
     {
      if(!m_settings.isTester)
         m_instanceRegistry.Unregister();
     }

   bool                    IsNettingAccount(void) const
     {
      ENUM_ACCOUNT_MARGIN_MODE mode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
      return (mode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
     }

   bool                    HasForeignNettingPosition(string &reason) const
     {
      reason = "";
      if(!IsNettingAccount())
         return false;

      for(int i = PositionsTotal() - 1; i >= 0; --i)
        {
         if(PositionGetSymbol(i) != _Symbol)
            continue;

         int positionMagic = (int)PositionGetInteger(POSITION_MAGIC);
         if(positionMagic == m_settings.magicNumber)
            continue;

         reason = "Conta netting/exchange: existe posicao em " + _Symbol +
                  " com Magic " + IntegerToString(positionMagic) +
                  " fora do perfil atual.";
         return true;
        }

      return false;
     }

   void                    LogNettingWarning(const string reason)
     {
      datetime now = TimeCurrent();
      if(now - m_lastNettingWarning < 60)
         return;

      m_logger.Warn("NETTING", reason);
      m_lastNettingWarning = now;
     }

   bool                    CanPersistProfile(const string profileName,const SEASettings &settings) const
     {
      string conflictProfile = "";
      if(!m_settingsStore.FindProfileByMagicNumber(settings.magicNumber, profileName, conflictProfile))
         return true;

      m_logger.Error("PROFILE", "Magic " + IntegerToString(settings.magicNumber) +
                              " ja esta em uso pelo perfil " + conflictProfile + ".");
      return false;
     }

#endif
