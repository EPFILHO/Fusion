   ENUM_FUSION_PROTECT_PAGE   m_protectPage;
   CButton                    m_protectTabs[FUSION_PROTECT_COUNT];
   bool                       m_protectPageValid[FUSION_PROTECT_COUNT];
   string                     m_protectPageError[FUSION_PROTECT_COUNT];
   CPanel                     m_protectTabsSeparator;
   CPanel                     m_protectContentFrame;

   CLabel                     m_protectGeneralHdr;
   CLabel                     m_protectGeneralLabels[6];
   CLabel                     m_protectGeneralValues[6];

   CLabel                     m_protectSpreadHdr;
   CLabel                     m_protectSpreadDesc;
   CLabel                     m_protectSpreadEnabledLbl;
   CButton                    m_protectSpreadEnabledBtn;
   CLabel                     m_protectSpreadLimitLbl;
   CEdit                      m_protectSpreadLimitEdit;

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

   CLabel                     m_protectNewsHdr;
   CLabel                     m_protectNewsDesc;
   CLabel                     m_protectNewsBlockHdr[3];
   CLabel                     m_protectNewsEnabledLbl[3];
   CButton                    m_protectNewsEnabledBtn[3];
   CLabel                     m_protectNewsStartLbl[3];
   CEdit                      m_protectNewsStartHourEdit[3];
   CEdit                      m_protectNewsStartMinuteEdit[3];
   CLabel                     m_protectNewsEndLbl[3];
   CEdit                      m_protectNewsEndHourEdit[3];
   CEdit                      m_protectNewsEndMinuteEdit[3];
   CLabel                     m_protectNewsModeLbl[3];
   CButton                    m_protectNewsModeBtn[3];

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

   CLabel                     m_protectDrawdownHdr;
   CLabel                     m_protectDrawdownDesc;
   CLabel                     m_protectDrawdownEnabledLbl;
   CButton                    m_protectDrawdownEnabledBtn;
   CLabel                     m_protectDrawdownValueLbl;
   CEdit                      m_protectDrawdownValueEdit;
   CLabel                     m_protectDrawdownNote;

   CLabel                     m_protectStreakHdr;
   CLabel                     m_protectStreakDesc;
   CLabel                     m_protectStreakEnabledLbl;
   CButton                    m_protectStreakEnabledBtn;
   CLabel                     m_protectStreakLossLbl;
   CEdit                      m_protectStreakLossEdit;
   CLabel                     m_protectStreakWinLbl;
   CEdit                      m_protectStreakWinEdit;

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
         else
            FusionApplyPrimaryButtonStyle(m_protectTabs[tabIndex], false);
        }
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

   bool                       HandleProtectionClick(const string objectName)
     {
      if(!m_configProtectionCreated)
         return false;

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

      if(HandleProtectionBooleanToggle(objectName, m_protectSpreadEnabledBtn, m_draftSettings.enableSpreadProtection))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionEnabledBtn, m_draftSettings.enableSessionFilter))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectSessionCloseBtn, m_draftSettings.closeOnSessionEnd))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectDayEnabledBtn, m_draftSettings.enableDailyLimits))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectDrawdownEnabledBtn, m_draftSettings.enableDrawdown))
         return true;

      if(HandleProtectionBooleanToggle(objectName, m_protectStreakEnabledBtn, m_draftSettings.enableStreak))
         return true;

      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(HandleProtectionBooleanToggle(objectName, m_protectNewsEnabledBtn[newsIndex], m_draftSettings.newsWindows[newsIndex].enabled))
            return true;

         if(HandleProtectionNewsModeToggle(objectName, newsIndex))
            return true;
        }

      return false;
     }
