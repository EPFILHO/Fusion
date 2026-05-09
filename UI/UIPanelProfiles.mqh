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

   bool                       EnsureProfilesBrowseCreated(void)
     {
      if(m_profilesBrowseCreated)
         return true;

      CFusionHitGroup *previous = PushBuildTarget(m_profilesBrowseGroup);
      bool ok = true;
      int y = 176;
      for(int i = 0; ok && i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
        {
         if(!AddButton(m_profileRows[i], "Fusion_profile_row_" + IntegerToString(i), 24, y, 330, y + 24, "", FUSION_CLR_PANEL))
            ok = false;
         y += 28;
        }

      if(ok && !AddButton(m_profileUpBtn, "Fusion_profile_up", 340, 176, 382, 202, ShortToString(0x25B2), FUSION_CLR_PANEL))
         ok = false;
      if(ok && !AddButton(m_profileDownBtn, "Fusion_profile_down", 340, 208, 382, 234, ShortToString(0x25BC), FUSION_CLR_PANEL))
         ok = false;
      if(ok && !AddButton(m_profileRefreshBtn, "Fusion_profile_refresh", 390, 176, 520, 202, "Atualizar Lista", FUSION_CLR_ACTION_LOAD))
         ok = false;
      if(ok && !AddButton(m_profileNewBtn, "Fusion_profile_new", 390, 208, 520, 234, "NOVO", FUSION_CLR_GOOD))
         ok = false;
      if(ok && !AddButton(m_profileLoadBtn, "Fusion_profile_load", 390, 240, 520, 266, "CARREGAR", FUSION_CLR_ACTION_LOAD))
         ok = false;
      if(ok && !AddButton(m_profileDuplicateBtn, "Fusion_profile_duplicate", 390, 272, 520, 298, "DUPLICAR", FUSION_CLR_ACTION_LOAD))
         ok = false;
      if(ok && !AddButton(m_profileDeleteBtn, "Fusion_profile_delete", 390, 304, 520, 330, "EXCLUIR", FUSION_CLR_BAD))
         ok = false;

      PopBuildTarget(previous);
      if(!ok)
         return false;

      m_profilesBrowseCreated = true;
      UpdateProfileListView();
      return true;
     }

   bool                       EnsureProfilesEditCreated(void)
     {
      if(m_profilesEditCreated)
         return true;

      CFusionHitGroup *previous = PushBuildTarget(m_profilesEditGroup);
      bool ok = true;
      if(!AddLabel(m_profileNewLbl, "Fusion_profile_new_lbl", 390, 236, 520, 254, "Novo nome", FUSION_CLR_LABEL, 8))
         ok = false;
      if(ok && !AddEdit(m_profileNewEdit, "Fusion_profile_new_edit", 390, 258, 520, 282, ""))
         ok = false;
      if(ok && !AddLabel(m_profileMagicLbl, "Fusion_profile_magic_lbl", 390, 292, 520, 310, "Magic", FUSION_CLR_LABEL, 8))
         ok = false;
      if(ok && !AddEdit(m_profileMagicEdit, "Fusion_profile_magic_edit", 390, 314, 520, 338, IntegerToString(m_draftSettings.magicNumber)))
         ok = false;
      if(ok && !AddButton(m_profileSaveAsBtn, "Fusion_profile_save_as", 390, 354, 520, 380, "SALVAR", FUSION_CLR_GOOD))
         ok = false;
      if(ok && !AddButton(m_profileCancelBtn, "Fusion_profile_cancel", 390, 386, 520, 412, "CANCELAR", FUSION_CLR_WARN))
         ok = false;
      PopBuildTarget(previous);
      if(!ok)
         return false;

      m_profilesEditCreated = true;
      m_profileNewEdit.Text(m_profileStore.SanitizeProfileName(m_profileEditSourceName == "" ? "" : m_profileEditSourceName));
      m_profileMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      UpdateProfileListView();
      return true;
     }

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

   void                       SetProfilesVisible(const bool visible)
     {
      if(!m_profilesTabCreated)
         return;

      bool editVisible = visible && ProfileEditMode() && m_profilesEditCreated;
      bool browseVisible = visible && !ProfileEditMode() && m_profilesBrowseCreated;

      SetVisible(m_profilesGroup, visible);
      SetVisible(m_profilesHdr, visible);
      SetVisible(m_profilesHint, visible);

      if(m_profilesBrowseCreated)
        {
         SetVisible(m_profilesBrowseGroup, browseVisible);
         SetVisible(m_profilesContentFrame, visible);
         for(int i = 0; i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
            SetVisible(m_profileRows[i], browseVisible);
         SetVisible(m_profileUpBtn, browseVisible);
         SetVisible(m_profileDownBtn, browseVisible);
         SetVisible(m_profileRefreshBtn, browseVisible);
         SetVisible(m_profileNewBtn, browseVisible);
         SetVisible(m_profileLoadBtn, browseVisible);
         SetVisible(m_profileDuplicateBtn, browseVisible);
         SetVisible(m_profileDeleteBtn, browseVisible);
        }

      if(m_profilesEditCreated)
        {
         SetVisible(m_profilesEditGroup, editVisible);
         SetVisible(m_profileNewLbl, editVisible);
         SetVisible(m_profileNewEdit, editVisible);
         SetVisible(m_profileMagicLbl, editVisible);
         SetVisible(m_profileMagicEdit, editVisible);
         SetVisible(m_profileSaveAsBtn, editVisible);
         SetVisible(m_profileCancelBtn, editVisible);
        }

      SetVisible(m_profileStatus, visible);
     }

   bool                       BuildProfilesTab(void)
     {
      if(!AddLabel(m_profilesHdr, "Fusion_profiles_hdr", 22, 118, 300, 138, "Administracao de Perfis", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_profilesHint, "Fusion_profiles_hint", 22, 142, 520, 162, "Backtest usa inputs do MT5. Nao apague o perfil default.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddPanel(m_profilesContentFrame,
                   "Fusion_profiles_content_frame",
                   FUSION_PANEL_MARGIN,
                   168,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   456,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;
      if(!AddLabel(m_profileStatus, "Fusion_profile_status", 24, 430, FUSION_PANEL_WIDTH - 18, 456, "", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddHitGroup(m_profilesBrowseGroup, "Fusion_group_profiles_browse"))
         return false;
      if(!AddHitGroup(m_profilesEditGroup, "Fusion_group_profiles_edit"))
         return false;
      if(!EnsureProfilesBrowseCreated())
         return false;
      if(!EnsureProfilesEditCreated())
         return false;

      return true;
     }

   bool                       HandleProfilesClick(const string objectName)
     {
      for(int pr = 0; pr < FUSION_PROFILE_VISIBLE_ROWS; ++pr)
        {
         if(objectName == m_profileRows[pr].Name())
           {
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
        }

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

      if(objectName == m_profileRefreshBtn.Name())
        {
         ReleaseButton(m_profileRefreshBtn);
         RefreshProfileList(true);
         SetProfileStatus("Lista de perfis atualizada.", FUSION_CLR_GOOD, true);
         return true;
        }

      if(objectName == m_profileNewBtn.Name())
        {
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

      if(objectName == m_profileLoadBtn.Name())
        {
         ReleaseButton(m_profileLoadBtn);
         string selectedProfile = SelectedProfileName();
         SUIProfileActionState profileActions = CurrentProfileActionState();
         if(!profileActions.canLoad)
           {
            if(profileActions.blockedReason != "")
               SetProfileStatus(profileActions.blockedReason, FUSION_CLR_WARN, true);
            else
               UpdateProfileListView();
            return true;
           }
         QueueProfileCommand(UI_COMMAND_LOAD_PROFILE, selectedProfile);
         return true;
        }

      if(objectName == m_profileSaveAsBtn.Name())
        {
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
            else
               UpdateProfileListView();
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

      if(objectName == m_profileDuplicateBtn.Name())
        {
         ReleaseButton(m_profileDuplicateBtn);
         SUIProfileActionState profileActions = CurrentProfileActionState();
         if(!profileActions.canDuplicate)
           {
            if(profileActions.blockedReason != "")
               SetProfileStatus(profileActions.blockedReason, FUSION_CLR_WARN, true);
            else
               UpdateProfileListView();
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

      if(objectName == m_profileCancelBtn.Name())
        {
         ReleaseButton(m_profileCancelBtn);
         SetProfileMode(FUSION_PROFILE_BROWSE);
         RestoreCommittedDraftToControls();
         RefreshConfigValidation();
         ApplyVisibility(false);
         return true;
        }

      if(objectName == m_profileDeleteBtn.Name())
        {
         ReleaseButton(m_profileDeleteBtn);
         string selectedProfile = SelectedProfileName();
         SUIProfileActionState profileActions = CurrentProfileActionState();
         if(!profileActions.canDelete)
           {
            if(profileActions.blockedReason != "")
               SetProfileStatus(profileActions.blockedReason, FUSION_CLR_WARN, true);
            else if(profileActions.selectedIsDefault)
               SetProfileStatus("O perfil default e reservado e nao deve ser apagado.", FUSION_CLR_WARN, true);
            else
               UpdateProfileListView();
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

      return false;
     }

#endif
