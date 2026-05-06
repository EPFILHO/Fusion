#ifndef __FUSION_UI_PANEL_TOP_ACTIONS_MQH__
#define __FUSION_UI_PANEL_TOP_ACTIONS_MQH__

   bool                       HandleStartActionClick(const string objectName)
     {
      if(objectName != m_btnStart.Name())
         return false;

      ReleaseButton(m_btnStart);
      SUIAccessState access = CurrentAccessState();
      if(access.canPause || access.canStart)
         QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
      else
         return true;
      RefreshTheme();
      return true;
     }

   bool                       HandleSaveActionClick(const string objectName)
     {
      if(objectName != m_btnSave.Name())
         return false;

      ReleaseButton(m_btnSave);
      SUIAccessState access = CurrentAccessState();
      if(!access.canSave)
         return true;

      SEASettings pendingSettings;
      string profileName = "";
      string status = "";
      bool valid = BuildPendingSettings(pendingSettings, profileName, status);
      if(valid)
         QueueSaveProfileCommand(profileName, pendingSettings, RELOAD_COLD);
      RefreshTheme();
      return true;
     }

   bool                       HandleCancelActionClick(const string objectName)
     {
      if(objectName != m_btnCancel.Name())
         return false;

      ReleaseButton(m_btnCancel);
      SUIAccessState access = CurrentAccessState();
      if(access.canCancel)
        {
         RestoreCommittedDraftToControls();
         RefreshConfigValidation();
         if(m_profilesTabCreated && m_activeTab == FUSION_TAB_PROFILES)
            SetProfileStatus("Alteracoes descartadas. Perfil salvo restaurado.", FUSION_CLR_GOOD, true);
        }
      else
         return true;
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
