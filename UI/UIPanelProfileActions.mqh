   void                       ResetProfileActionState(SUIProfileActionState &state)
     {
      state.selected = false;
      state.selectedIsActive = false;
      state.selectedIsDefault = false;
      state.selectedRuntimeLocked = false;
      state.selectedActiveProfileLocked = false;
      state.canLoad = false;
      state.canDuplicate = false;
      state.canDelete = false;
      state.blockedReason = "";
     }

   bool                       ProfileRuntimeLocked(const string profileName,string &reason)
     {
      reason = "";

      if(profileName == "")
         return false;

      SEASettings selectedSettings;
      if(!m_profileStore.LoadProfile(profileName, selectedSettings))
        {
         reason = "Nao foi possivel ler o perfil selecionado. Atualize a lista.";
         return true;
        }

      CInstanceRegistry registry;
      return registry.HasActiveConflict(selectedSettings.magicNumber, m_chartId, reason);
     }

   bool                       ProfileActiveLocked(const string profileName,string &reason)
     {
      reason = "";

      if(profileName == "")
         return false;

      CActiveProfileRegistry registry;
      return registry.HasActiveProfilePeer(profileName, m_chartId, reason);
     }

   SUIProfileActionState      BuildProfileActionState(const SUIAccessState &access)
     {
      SUIProfileActionState state;
      ResetProfileActionState(state);

      string selectedProfile = SelectedProfileName();
      if(selectedProfile == "")
         return state;

      string selectedKey = m_profileStore.SanitizeProfileName(selectedProfile);
      string activeKey = m_profileStore.SanitizeProfileName(m_committedProfileName);

      state.selected = true;
      state.selectedIsActive = (selectedKey == activeKey);
      state.selectedIsDefault = IsDefaultProfileName(selectedProfile);
      string runtimeReason = "";
      string activeProfileReason = "";
      state.selectedRuntimeLocked = ProfileRuntimeLocked(selectedProfile, runtimeReason);
      state.selectedActiveProfileLocked = ProfileActiveLocked(selectedProfile, activeProfileReason);
      if(state.selectedRuntimeLocked)
         state.blockedReason = runtimeReason;
      else if(state.selectedActiveProfileLocked)
         state.blockedReason = activeProfileReason;

      bool selectedLocked = (state.selectedRuntimeLocked || state.selectedActiveProfileLocked);
      state.canLoad = (!selectedLocked && access.profileLoadAllowed);
      state.canDuplicate = (!selectedLocked && access.profileAdminAllowed);
      state.canDelete = (!selectedLocked &&
                         !state.selectedIsActive &&
                         !state.selectedIsDefault &&
                         access.profileAdminAllowed);

      return state;
     }

   SUIProfileActionState      CurrentProfileActionState(void)
     {
      SUIAccessState access = CurrentAccessState();
      return BuildProfileActionState(access);
     }

   bool                       CanStartNewProfile(void)
     {
      SUIAccessState access = CurrentAccessState();
      return (!access.profileEditMode && access.activeProfileEditable);
     }
