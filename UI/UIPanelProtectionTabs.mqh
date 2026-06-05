   ENUM_FUSION_PROTECT_PAGE   m_protectPage;
   CButton                    m_protectTabs[FUSION_PROTECT_COUNT];
   bool                       m_protectPageValid[FUSION_PROTECT_COUNT];
   string                     m_protectPageError[FUSION_PROTECT_COUNT];
   CPanel                     m_protectTabsSeparator;
   CPanel                     m_protectContentFrame;

   CLabel                     m_protectGeneralHdr;
   CLabel                     m_protectGeneralLabels[FUSION_PROTECT_OVERVIEW_COUNT];
   CLabel                     m_protectGeneralValues[FUSION_PROTECT_OVERVIEW_COUNT];

   CLabel                     m_protectSpreadHdr;
   CLabel                     m_protectSpreadDesc;
   CLabel                     m_protectSpreadEnabledLbl;
   CButton                    m_protectSpreadEnabledBtn;
   CLabel                     m_protectSpreadLimitLbl;
   CEdit                      m_protectSpreadLimitEdit;
   CSelectionComboField       m_protectDirection;
   CLabel                     m_protectEntryFoot1;
   CLabel                     m_protectEntryFoot2;

   CLabel                     m_protectSessionHdr;
   CLabel                     m_protectSessionDesc;
   CLabel                     m_protectSessionEnabledLbl;
   CButton                    m_protectSessionEnabledBtn;
   CLabel                     m_protectSessionStartLbl;
   CEdit                      m_protectSessionStartHourEdit;
   CEdit                      m_protectSessionStartMinuteEdit;
   CLabel                     m_protectSessionEndLbl;
   CEdit                      m_protectSessionEndHourEdit;
   CEdit                      m_protectSessionEndMinuteEdit;
   CLabel                     m_protectSessionCloseLbl;
   CButton                    m_protectSessionCloseBtn;
   CLabel                     m_protectSessionOvernightLbl;
   CButton                    m_protectSessionOvernightBtn;
   CLabel                     m_protectSessionFoot1;
   CLabel                     m_protectSessionFoot2;
   CLabel                     m_protectSessionFoot3;

   CLabel                     m_protectNewsHdr;
   CLabel                     m_protectNewsDesc;
   CLabel                     m_protectNewsBlockHdr[FUSION_NEWS_WINDOW_COUNT];
   CLabel                     m_protectNewsEnabledLbl[FUSION_NEWS_WINDOW_COUNT];
   CButton                    m_protectNewsEnabledBtn[FUSION_NEWS_WINDOW_COUNT];
   CLabel                     m_protectNewsStartLbl[FUSION_NEWS_WINDOW_COUNT];
   CEdit                      m_protectNewsStartHourEdit[FUSION_NEWS_WINDOW_COUNT];
   CEdit                      m_protectNewsStartMinuteEdit[FUSION_NEWS_WINDOW_COUNT];
   CLabel                     m_protectNewsEndLbl[FUSION_NEWS_WINDOW_COUNT];
   CEdit                      m_protectNewsEndHourEdit[FUSION_NEWS_WINDOW_COUNT];
   CEdit                      m_protectNewsEndMinuteEdit[FUSION_NEWS_WINDOW_COUNT];
   CLabel                     m_protectNewsModeLbl[FUSION_NEWS_WINDOW_COUNT];
   CButton                    m_protectNewsModeBtn[FUSION_NEWS_WINDOW_COUNT];

   CLabel                     m_protectDayHdr;
   CLabel                     m_protectDayDesc;
   CLabel                     m_protectDayEnabledLbl;
   CButton                    m_protectDayEnabledBtn;
   CLabel                     m_protectDayTradesLbl;
   CEdit                      m_protectDayTradesEdit;
   CLabel                     m_protectDayLossLbl;
   CEdit                      m_protectDayLossEdit;
   CLabel                     m_protectDayGainLbl;
   CEdit                      m_protectDayGainEdit;
   CSelectionComboField       m_protectDayProfitAction;
   CLabel                     m_protectDayFoot1;
   CLabel                     m_protectDayFoot2;
   CLabel                     m_protectDayFoot3;

   CLabel                     m_protectDrawdownHdr;
   CLabel                     m_protectDrawdownDesc;
   CLabel                     m_protectDrawdownEnabledLbl;
   CButton                    m_protectDrawdownEnabledBtn;
   CLabel                     m_protectDrawdownValueLbl;
   CEdit                      m_protectDrawdownValueEdit;
   CSelectionComboField       m_protectDrawdownType;
   CSelectionComboField       m_protectDrawdownPeakMode;
   CLabel                     m_protectDrawdownPeakRuntimeLbl;
   CLabel                     m_protectDrawdownPeakRuntimeValue;
   CLabel                     m_protectDrawdownFloorLbl;
   CLabel                     m_protectDrawdownFloorValue;
   CLabel                     m_protectDrawdownBufferLbl;
   CLabel                     m_protectDrawdownBufferValue;
   CLabel                     m_protectDrawdownNote;
   CLabel                     m_protectDrawdownFoot2;
   CLabel                     m_protectDrawdownFoot3;

   CLabel                     m_protectStreakHdr;
   CLabel                     m_protectStreakDesc;
   CLabel                     m_protectStreakLossHdr;
   CLabel                     m_protectStreakLossEnabledLbl;
   CButton                    m_protectStreakLossEnabledBtn;
   CLabel                     m_protectStreakLossLbl;
   CEdit                      m_protectStreakLossEdit;
   CSelectionComboField       m_protectStreakLossAction;
   CLabel                     m_protectStreakLossPauseMinutesLbl;
   CEdit                      m_protectStreakLossPauseMinutesEdit;
   CLabel                     m_protectStreakWinHdr;
   CLabel                     m_protectStreakWinEnabledLbl;
   CButton                    m_protectStreakWinEnabledBtn;
   CLabel                     m_protectStreakWinLbl;
   CEdit                      m_protectStreakWinEdit;
   CSelectionComboField       m_protectStreakWinAction;
   CLabel                     m_protectStreakWinPauseMinutesLbl;
   CEdit                      m_protectStreakWinPauseMinutesEdit;
   CLabel                     m_protectStreakFoot1;
   CLabel                     m_protectStreakFoot2;

   string                     ProtectNewsActionText(const ENUM_NEWS_WINDOW_ACTION action) const
     {
      return (action == NEWS_ACTION_CLOSE_AND_BLOCK) ? "FECHA+BLQ" : "BLOQUEAR";
     }

   void                       ApplyProtectModeButtonStyle(CButton &button,const ENUM_NEWS_WINDOW_ACTION action,const bool editable)
     {
      button.Text(ProtectNewsActionText(action));
      if(!editable)
         FusionApplyNeutralButtonStyle(button);
      else
         FusionApplyActionButtonStyle(button, action == NEWS_ACTION_CLOSE_AND_BLOCK ? FUSION_CLR_WARN : FUSION_CLR_ACTION_LOAD, true);
     }

   bool                       ProtectSubtabHasError(const ENUM_FUSION_PROTECT_PAGE page) const
     {
      if(page == FUSION_PROTECT_GENERAL)
         return false;
      return !m_protectPageValid[(int)page];
     }

   bool                       ProtectSubtabHasOperationalWarning(const ENUM_FUSION_PROTECT_PAGE page) const
     {
      if(page == FUSION_PROTECT_SESSION)
         return (m_draftSettings.enableSessionFilter && m_snapshot.sessionProtectionBlocked);
      if(page == FUSION_PROTECT_NEWS)
        {
         bool hasEnabledNewsWindow = false;
         for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
           {
            if(m_draftSettings.newsWindows[newsIndex].enabled)
              {
               hasEnabledNewsWindow = true;
               break;
              }
           }
         return (hasEnabledNewsWindow && m_snapshot.newsProtectionBlocked);
        }
      if(page == FUSION_PROTECT_DAY)
         return m_snapshot.dailyLimitsBlocked;
      if(page == FUSION_PROTECT_DRAWDOWN)
         return m_snapshot.drawdownLimitReached;
      if(page == FUSION_PROTECT_STREAK)
         return m_snapshot.streakProtectionBlocked;
      return false;
     }

   string                     ProtectSubtabError(const ENUM_FUSION_PROTECT_PAGE page) const
     {
      return m_protectPageError[(int)page];
     }

   void                       ApplyProtectionTabStyles(void)
     {
      for(int tabIndex = 0; tabIndex < FUSION_PROTECT_COUNT; ++tabIndex)
        {
         if(tabIndex == (int)m_protectPage)
            FusionApplyPrimaryButtonStyle(m_protectTabs[tabIndex], true);
         else if(ProtectSubtabHasError((ENUM_FUSION_PROTECT_PAGE)tabIndex))
            FusionApplyActionButtonStyle(m_protectTabs[tabIndex], FUSION_CLR_BAD, true);
         else if(ProtectSubtabHasOperationalWarning((ENUM_FUSION_PROTECT_PAGE)tabIndex))
            FusionApplyActionButtonStyle(m_protectTabs[tabIndex], FUSION_CLR_WARN, true);
         else
            FusionApplyPrimaryButtonStyle(m_protectTabs[tabIndex], false);
        }
     }

   void                       SyncProtectionDirectionCombo(const bool editable)
     {
      m_protectDirection.Sync((long)m_draftSettings.tradeDirection, editable);
      m_protectDirection.RaiseRuntimeObjects(3900);
     }

   void                       SyncProtectionStreakActionCombos(const bool editable)
     {
      m_protectStreakLossAction.Sync((long)m_draftSettings.lossStreakAction, editable && m_draftSettings.lossStreakEnabled);
      m_protectStreakWinAction.Sync((long)m_draftSettings.winStreakAction, editable && m_draftSettings.winStreakEnabled);
      m_protectStreakLossAction.RaiseRuntimeObjects(3910);
      m_protectStreakWinAction.RaiseRuntimeObjects(3920);
     }

   void                       SyncProtectionDayActionCombo(const bool editable)
     {
      m_protectDayProfitAction.Sync((long)m_draftSettings.profitTargetAction, editable && m_draftSettings.enableDailyLimits);
      m_protectDayProfitAction.RaiseRuntimeObjects(3905);
     }

   void                       SyncProtectionDrawdownCombos(const bool editable)
     {
      m_protectDrawdownType.Sync((long)m_draftSettings.drawdownType, editable && m_draftSettings.enableDrawdown);
      m_protectDrawdownPeakMode.Sync((long)m_draftSettings.drawdownPeakMode, editable && m_draftSettings.enableDrawdown);
      m_protectDrawdownType.RaiseRuntimeObjects(3908);
      m_protectDrawdownPeakMode.RaiseRuntimeObjects(3909);
     }

#include "UIPanelProtectionInputs.mqh"
#include "UIPanelProtectionValidation.mqh"
#include "UIPanelProtectionBuild.mqh"

#include "UIPanelProtectionVisibility.mqh"
#include "UIPanelProtectionSync.mqh"

   bool                       EnsureConfigProtectionPageCreated(void)
     {
      if(m_configProtectionCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configProtectionGroup);
      if(!BuildConfigProtectionPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configProtectionCreated = true;
      SetProtectionControlsVisible(m_protectPage, false);
      SyncProtectionControls();
      return true;
     }

   bool                       HandleProtectionBooleanToggle(const string objectName,CButton &button,bool &target)
     {
      if(objectName != button.Name())
         return false;

      ReleaseButton(button);
      if(!CanEditActiveProfile())
         return true;

      target = !target;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionNewsModeToggle(const string objectName,const int newsIndex)
     {
      if(objectName != m_protectNewsModeBtn[newsIndex].Name())
         return false;

      ReleaseButton(m_protectNewsModeBtn[newsIndex]);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.newsWindows[newsIndex].action =
         (m_draftSettings.newsWindows[newsIndex].action == NEWS_ACTION_BLOCK_ENTRIES)
         ? NEWS_ACTION_CLOSE_AND_BLOCK
         : NEWS_ACTION_BLOCK_ENTRIES;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionSpreadToggle(const string objectName)
     {
      if(objectName != m_protectSpreadEnabledBtn.Name())
         return false;

      ReleaseButton(m_protectSpreadEnabledBtn);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.enableSpreadProtection = !m_draftSettings.enableSpreadProtection;
      if(m_draftSettings.enableSpreadProtection)
        {
         if(m_draftSettings.maxSpreadPoints <= 0)
            m_draftSettings.maxSpreadPoints = 1;
        }
      else
         m_draftSettings.maxSpreadPoints = 0;

      m_protectSpreadLimitEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionDayToggle(const string objectName)
     {
      if(objectName != m_protectDayEnabledBtn.Name())
         return false;

      ReleaseButton(m_protectDayEnabledBtn);
      if(!CanEditActiveProfile() || DailyConfigLocked())
        {
         RefreshConfigValidation();
         return true;
        }

      m_draftSettings.enableDailyLimits = !m_draftSettings.enableDailyLimits;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionDrawdownToggle(const string objectName)
     {
      if(objectName != m_protectDrawdownEnabledBtn.Name())
         return false;

      ReleaseButton(m_protectDrawdownEnabledBtn);
      if(!CanEditActiveProfile() || DrawdownConfigLocked())
        {
         RefreshConfigValidation();
         return true;
        }

      m_draftSettings.enableDrawdown = !m_draftSettings.enableDrawdown;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleProtectionDirectionChange(const string objectName)
     {
      if(!m_protectDirection.Matches(objectName))
         return false;

      if(!TryBeginActiveProfileEdit())
        {
         SyncProtectionDirectionCombo(false);
         return true;
        }

      m_draftSettings.tradeDirection = (ENUM_TRADE_DIRECTION)m_protectDirection.Value();
      RefreshConfigValidation();
      SyncProtectionDirectionCombo(CanEditActiveProfile());
      return true;
     }

   bool                       HandleProtectionStreakActionChange(const string objectName)
     {
      if(m_protectStreakLossAction.Matches(objectName))
        {
         if(!TryBeginActiveProfileEdit() || StreakConfigLocked() || !m_draftSettings.lossStreakEnabled)
           {
            SyncProtectionStreakActionCombos(CanEditActiveProfile() && !StreakConfigLocked());
            return true;
           }

         m_draftSettings.lossStreakAction = (ENUM_STREAK_ACTION)m_protectStreakLossAction.Value();
         RefreshConfigValidation();
         SyncProtectionStreakActionCombos(CanEditActiveProfile() && !StreakConfigLocked());
         return true;
        }

      if(m_protectStreakWinAction.Matches(objectName))
        {
         if(!TryBeginActiveProfileEdit() || StreakConfigLocked() || !m_draftSettings.winStreakEnabled)
           {
            SyncProtectionStreakActionCombos(CanEditActiveProfile() && !StreakConfigLocked());
            return true;
           }

         m_draftSettings.winStreakAction = (ENUM_STREAK_ACTION)m_protectStreakWinAction.Value();
         RefreshConfigValidation();
         SyncProtectionStreakActionCombos(CanEditActiveProfile() && !StreakConfigLocked());
         return true;
        }

      return false;
     }

   bool                       HandleProtectionDayActionChange(const string objectName)
     {
      if(!m_protectDayProfitAction.Matches(objectName))
         return false;

      if(!TryBeginActiveProfileEdit() || DailyConfigLocked() || !m_draftSettings.enableDailyLimits)
        {
         SyncProtectionDayActionCombo(CanEditActiveProfile() && !DailyConfigLocked());
         return true;
        }

      m_draftSettings.profitTargetAction = (ENUM_PROFIT_TARGET_ACTION)m_protectDayProfitAction.Value();
      RefreshConfigValidation();
      SyncProtectionDayActionCombo(CanEditActiveProfile() && !DailyConfigLocked());
      return true;
     }

   bool                       HandleProtectionDrawdownComboChange(const string objectName)
     {
      if(m_protectDrawdownType.Matches(objectName))
        {
         if(!TryBeginActiveProfileEdit() || DrawdownConfigLocked() || !m_draftSettings.enableDrawdown)
           {
            SyncProtectionDrawdownCombos(CanEditActiveProfile() && !DrawdownConfigLocked());
            return true;
           }

         m_draftSettings.drawdownType = (ENUM_DRAWDOWN_TYPE)m_protectDrawdownType.Value();
         RefreshConfigValidation();
         SyncProtectionDrawdownCombos(CanEditActiveProfile() && !DrawdownConfigLocked());
         return true;
        }

      if(m_protectDrawdownPeakMode.Matches(objectName))
        {
         if(!TryBeginActiveProfileEdit() || DrawdownConfigLocked() || !m_draftSettings.enableDrawdown)
           {
            SyncProtectionDrawdownCombos(CanEditActiveProfile() && !DrawdownConfigLocked());
            return true;
           }

         m_draftSettings.drawdownPeakMode = (ENUM_DRAWDOWN_PEAK_MODE)m_protectDrawdownPeakMode.Value();
         RefreshConfigValidation();
         SyncProtectionDrawdownCombos(CanEditActiveProfile() && !DrawdownConfigLocked());
         return true;
        }

      return false;
     }

   bool                       HandleProtectionChange(const int id,const string objectName)
     {
      if(id != CHARTEVENT_CUSTOM + ON_CHANGE || !m_configProtectionCreated)
         return false;
      if(HandleProtectionDirectionChange(objectName))
         return true;
      if(HandleProtectionDayActionChange(objectName))
         return true;
      if(HandleProtectionDrawdownComboChange(objectName))
         return true;
      if(HandleProtectionStreakActionChange(objectName))
         return true;
      return false;
     }

   bool                       HandleProtectionPageClick(const string objectName)
     {
      for(int tabIndex = 0; tabIndex < FUSION_PROTECT_COUNT; ++tabIndex)
        {
         if(objectName != m_protectTabs[tabIndex].Name())
            continue;

         ReleaseButton(m_protectTabs[tabIndex]);
         ResetDialogMouseRouting();
         m_protectPage = (ENUM_FUSION_PROTECT_PAGE)tabIndex;
         ApplyVisibility(false);
         RefreshConfigValidation();
         return true;
        }

      return false;
     }

   bool                       HandleProtectionToggleClick(const string objectName)
     {
      if(HandleProtectionSpreadToggle(objectName))
         return true;

      if(HandleProtectionDayToggle(objectName))
         return true;

      if(HandleProtectionDrawdownToggle(objectName))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionOvernightBtn, m_draftSettings.sessionOvernight))
         return true;

      if(StreakConfigLocked() &&
         (objectName == m_protectStreakLossEnabledBtn.Name() ||
          objectName == m_protectStreakWinEnabledBtn.Name()))
        {
         if(objectName == m_protectStreakLossEnabledBtn.Name())
            ReleaseButton(m_protectStreakLossEnabledBtn);
         else
            ReleaseButton(m_protectStreakWinEnabledBtn);
         RefreshConfigValidation();
         return true;
        }

      if(HandleProtectionBooleanToggle(objectName, m_protectStreakLossEnabledBtn, m_draftSettings.lossStreakEnabled))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectStreakWinEnabledBtn, m_draftSettings.winStreakEnabled))
         return true;

      for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
        {
         if(HandleProtectionBooleanToggle(objectName, m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled))
            return true;

         if(HandleProtectionNewsModeToggle(objectName, newsIndex))
            return true;

        }

      return false;
     }

   bool                       HandleProtectionClick(const string objectName)
     {
      if(!m_configProtectionCreated)
         return false;

      if(HandleProtectionPageClick(objectName))
         return true;

      if(HandleProtectionToggleClick(objectName))
         return true;

      return false;
     }
