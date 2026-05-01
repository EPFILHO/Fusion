#ifndef __FUSION_UI_PANEL_TOP_ACTIONS_MQH__
#define __FUSION_UI_PANEL_TOP_ACTIONS_MQH__

   bool                       HandleStartActionClick(const string objectName)
     {
      if(objectName != m_btnStart.Name())
         return false;

      ReleaseButton(m_btnStart);
      if(CanPause())
         QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
      else if(CanStart())
         QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
      RefreshTheme();
      return true;
     }

   bool                       HandleSaveActionClick(const string objectName)
     {
      if(objectName != m_btnSave.Name())
         return false;

      ReleaseButton(m_btnSave);
      SEASettings pendingSettings;
      string profileName = "";
      string status = "";
      bool valid = BuildPendingSettings(pendingSettings, profileName, status);
      if(valid && CanSave())
         QueueSaveProfileCommand(profileName, pendingSettings, RELOAD_COLD);
      RefreshTheme();
      return true;
     }

   bool                       HandleCancelActionClick(const string objectName)
     {
      if(objectName != m_btnCancel.Name())
         return false;

      ReleaseButton(m_btnCancel);
      if(CanCancel())
        {
         RestoreCommittedDraftToControls();
         RefreshConfigValidation();
         if(m_profilesTabCreated && m_activeTab == FUSION_TAB_PROFILES)
            SetProfileStatus("Alteracoes descartadas. Perfil salvo restaurado.", FUSION_CLR_GOOD, true);
        }
      else
         RefreshTheme();
      return true;
     }

   bool                       HandleTopActionClick(const string objectName)
     {
      if(HandleStartActionClick(objectName))
         return true;
      if(HandleSaveActionClick(objectName))
         return true;
      if(HandleCancelActionClick(objectName))
         return true;
      return false;
     }

#endif
