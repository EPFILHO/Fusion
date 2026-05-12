#ifndef __FUSION_UI_PANEL_PROFILE_CLICKS_MQH__
#define __FUSION_UI_PANEL_PROFILE_CLICKS_MQH__

   void                       RefreshBlockedProfileAction(const SUIProfileActionState &profileActions,const bool defaultReserved=false)
     {
      if(profileActions.blockedReason != "")
         SetProfileStatus(profileActions.blockedReason, FUSION_CLR_WARN, true);
      else if(defaultReserved && profileActions.selectedIsDefault)
         SetProfileStatus("O perfil default e reservado e nao deve ser apagado.", FUSION_CLR_WARN, true);
      else
         UpdateProfileListView();
     }

   bool                       HandleProfileRowClick(const string objectName)
     {
      for(int pr = 0; pr < FUSION_PROFILE_VISIBLE_ROWS; ++pr)
        {
         if(objectName != m_profileRows[pr].Name())
            continue;

         ReleaseButton(m_profileRows[pr]);
         if(ProfileEditMode())
            return true;

         int idx = m_profileOffset + pr;
         if(idx >= 0 && idx < m_profileCount)
           {
            m_profileSelected = idx;
            SetProfileMode(FUSION_PROFILE_BROWSE);
            UpdateProfileListView();
           }
         return true;
        }
      return false;
     }

   bool                       HandleProfileScrollClick(const string objectName)
     {
      if(objectName == m_profileUpBtn.Name())
        {
         ReleaseButton(m_profileUpBtn);
         if(m_profileOffset <= 0)
            return true;
         m_profileOffset--;
         UpdateProfileListView(false);
         return true;
        }

      if(objectName == m_profileDownBtn.Name())
        {
         ReleaseButton(m_profileDownBtn);
         if(m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS >= m_profileCount)
            return true;
         m_profileOffset++;
         UpdateProfileListView(false);
         return true;
        }

      return false;
     }

   bool                       HandleProfileRefreshClick(const string objectName)
     {
      if(objectName != m_profileRefreshBtn.Name())
         return false;

      ReleaseButton(m_profileRefreshBtn);
      RefreshProfileList(true);
      SetProfileStatus("Lista de perfis atualizada.", FUSION_CLR_GOOD, true);
      return true;
     }

   bool                       HandleProfileNewClick(const string objectName)
     {
      if(objectName != m_profileNewBtn.Name())
         return false;

      ReleaseButton(m_profileNewBtn);
      if(CanStartNewProfile())
        {
         SetProfileMode(FUSION_PROFILE_NEW);
         RefreshConfigValidation();
         ApplyVisibility(false);
        }
      else
         UpdateProfileListView();
      return true;
     }

   bool                       HandleProfileLoadClick(const string objectName)
     {
      if(objectName != m_profileLoadBtn.Name())
         return false;

      ReleaseButton(m_profileLoadBtn);
      string selectedProfile = SelectedProfileName();
      SUIProfileActionState profileActions = CurrentProfileActionState();
      if(!profileActions.canLoad)
        {
         RefreshBlockedProfileAction(profileActions);
         return true;
        }
      QueueProfileCommand(UI_COMMAND_LOAD_PROFILE, selectedProfile);
      return true;
     }

   bool                       HandleProfileSaveAsClick(const string objectName)
     {
      if(objectName != m_profileSaveAsBtn.Name())
         return false;

      ReleaseButton(m_profileSaveAsBtn);
      string newProfileName = ProfileDraftName();
      if(!ProfileEditMode())
        {
         UpdateProfileListView();
         return true;
        }

      int draftMagic = 0;
      string draftName = "";
      string magicConflictProfile = "";
      string profileDraftError = "";
      bool validName = false;
      bool nameAvailable = false;
      bool draftMagicValid = false;
      bool magicAvailableForDraft = false;
      bool profileDraftReady = ProfileEditDraftState(draftName,
                                                     draftMagic,
                                                     validName,
                                                     nameAvailable,
                                                     draftMagicValid,
                                                     magicAvailableForDraft,
                                                     magicConflictProfile,
                                                     profileDraftError);
      RefreshProfileValidationState();
      if(!profileDraftReady)
        {
         if(profileDraftError != "")
            SetProfileStatus(profileDraftError, FUSION_CLR_BAD, true);
         RefreshConfigValidation();
         return true;
        }

      SEASettings pendingSettings;
      string ignoredProfile = "";
      string status = "";
      bool valid = BuildPendingSettings(pendingSettings, ignoredProfile, status);
      pendingSettings.magicNumber = draftMagic;
      if(ActiveProfileEditable() && valid && newProfileName != "")
        {
         QueueSaveProfileCommand(newProfileName, pendingSettings, RELOAD_COLD);
         SetProfileStatus("Solicitado salvamento do perfil " + newProfileName + ".", FUSION_CLR_GOOD, true);
        }
      else
        {
         if(status != "")
            SetProfileStatus(status, FUSION_CLR_BAD, true);
         else
            UpdateProfileListView();
        }
      return true;
     }

   bool                       HandleProfileDuplicateClick(const string objectName)
     {
      if(objectName != m_profileDuplicateBtn.Name())
         return false;

      ReleaseButton(m_profileDuplicateBtn);
      SUIProfileActionState profileActions = CurrentProfileActionState();
      if(!profileActions.canDuplicate)
        {
         RefreshBlockedProfileAction(profileActions);
         return true;
        }
      string selectedProfile = SelectedProfileName();
      SEASettings sourceSettings;
      if(m_profileStore.LoadProfile(selectedProfile, sourceSettings))
        {
         m_draftSettings = sourceSettings;
         SetProfileMode(FUSION_PROFILE_DUPLICATE, SuggestedDuplicateName(selectedProfile), selectedProfile);
         SyncDraftSettingsToControls();
         RefreshConfigValidation();
         ApplyVisibility(false);
         SetProfileStatus("Duplicando " + selectedProfile + ". Informe nome e Magic unico antes de salvar.", FUSION_CLR_WARN, true);
        }
      else
         SetProfileStatus("Nao foi possivel ler o perfil selecionado.", FUSION_CLR_BAD, true);
      return true;
     }

   bool                       HandleProfileCancelClick(const string objectName)
     {
      if(objectName != m_profileCancelBtn.Name())
         return false;

      ReleaseButton(m_profileCancelBtn);
      CancelProfileEditMode();
      return true;
     }

   void                       CancelProfileEditMode(void)
     {
      SetProfileMode(FUSION_PROFILE_BROWSE);
      RestoreCommittedDraftToControls();
      RefreshConfigValidation();
      ApplyVisibility(false);
     }

   bool                       HandleProfileDeleteClick(const string objectName)
     {
      if(objectName != m_profileDeleteBtn.Name())
         return false;

      ReleaseButton(m_profileDeleteBtn);
      string selectedProfile = SelectedProfileName();
      SUIProfileActionState profileActions = CurrentProfileActionState();
      if(!profileActions.canDelete)
        {
         RefreshBlockedProfileAction(profileActions, true);
         return true;
        }
      if(m_profileStore.DeleteProfile(selectedProfile))
        {
         RefreshProfileList(false);
         SetProfileStatus("Perfil excluido: " + selectedProfile + ".", FUSION_CLR_GOOD, true);
        }
      else
         SetProfileStatus("Nao foi possivel excluir o perfil.", FUSION_CLR_BAD, true);
      return true;
     }

   bool                       HandleProfilesClick(const string objectName)
     {
      if(HandleProfileRowClick(objectName))
         return true;
      if(HandleProfileScrollClick(objectName))
         return true;
      if(HandleProfileRefreshClick(objectName))
         return true;
      if(HandleProfileNewClick(objectName))
         return true;
      if(HandleProfileLoadClick(objectName))
         return true;
      if(HandleProfileSaveAsClick(objectName))
         return true;
      if(HandleProfileDuplicateClick(objectName))
         return true;
      if(HandleProfileCancelClick(objectName))
         return true;
      if(HandleProfileDeleteClick(objectName))
         return true;
      return false;
     }

#endif
