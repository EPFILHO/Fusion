#ifndef __FUSION_UI_PANEL_PROFILES_MQH__
#define __FUSION_UI_PANEL_PROFILES_MQH__

   CSettingsStore             m_profileStore;
   string                     m_committedProfileName;
   string                     m_profileNames[];
   int                        m_profileCount;
   int                        m_profileOffset;
   int                        m_profileSelected;
   string                     m_profileStatusOverride;
   color                      m_profileStatusOverrideColor;
   uint                       m_profileStatusOverrideUntil;
   string                     m_profileEditSourceName;
   ENUM_FUSION_PROFILE_MODE   m_profileMode;
   bool                       m_profilesBrowseCreated;
   bool                       m_profilesEditCreated;
   bool                       m_profileTabValid;
   string                     m_profileTabError;

   CLabel                     m_profilesHdr;
   CLabel                     m_profilesHint;
   CPanel                     m_profilesContentFrame;
   CButton                    m_profileRows[FUSION_PROFILE_VISIBLE_ROWS];
   CButton                    m_profileUpBtn;
   CButton                    m_profileDownBtn;
   CButton                    m_profileRefreshBtn;
   CButton                    m_profileNewBtn;
   CLabel                     m_profileNewLbl;
   CEdit                      m_profileNewEdit;
   CLabel                     m_profileMagicLbl;
   CEdit                      m_profileMagicEdit;
   CButton                    m_profileLoadBtn;
   CButton                    m_profileSaveAsBtn;
   CButton                    m_profileDuplicateBtn;
   CButton                    m_profileDeleteBtn;
   CButton                    m_profileCancelBtn;
   CLabel                     m_profileStatus;

#include "UIPanelProfileState.mqh"
#include "UIPanelProfileBuild.mqh"

   string                     SelectedProfileName(void)
     {
      if(m_profileSelected < 0 || m_profileSelected >= m_profileCount)
         return "";
      return m_profileNames[m_profileSelected];
     }

   string                     DefaultProfileKey(void)
     {
      string profileName = m_draftSettings.defaultProfileName;
      if(FusionIsBlank(profileName))
         profileName = m_committedSettings.defaultProfileName;
      if(FusionIsBlank(profileName))
         profileName = "default";
      return m_profileStore.SanitizeProfileName(profileName);
     }

   bool                       IsDefaultProfileName(const string profileName)
     {
      string sanitized = m_profileStore.SanitizeProfileName(profileName);
      string defaultKey = DefaultProfileKey();
      return (sanitized != "" && defaultKey != "" && sanitized == defaultKey);
     }

#include "UIPanelProfileValidation.mqh"

#include "UIPanelProfileActions.mqh"

#include "UIPanelProfileListView.mqh"

   void                       RefreshProfileList(const bool keepSelection=true)
     {
      string previousSelection = keepSelection ? SelectedProfileName() : "";
      if(previousSelection == "")
         previousSelection = m_committedProfileName;

      m_profileStore.ListProfiles(m_profileNames);
      m_profileCount = ArraySize(m_profileNames);
      m_profileSelected = -1;

      for(int i = 0; i < m_profileCount; ++i)
        {
         if(m_profileStore.SanitizeProfileName(m_profileNames[i]) == m_profileStore.SanitizeProfileName(previousSelection))
           {
            m_profileSelected = i;
            break;
           }
        }

      if(m_profileSelected < 0 && m_profileCount > 0)
         m_profileSelected = 0;

      if(m_profilesBrowseCreated)
         UpdateProfileListView();
     }

#include "UIPanelProfileVisibility.mqh"

#include "UIPanelProfileClicks.mqh"

#endif
