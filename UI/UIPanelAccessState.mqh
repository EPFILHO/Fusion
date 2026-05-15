   bool                       HasLocalPositionLock(const SUIPanelSnapshot &snapshot) const
     {
      return snapshot.hasPosition;
     }

   bool                       HasPeerProfileLock(const SUIPanelSnapshot &snapshot) const
     {
      return (snapshot.startBlockedReason != "" || snapshot.activeProfileBlockedReason != "");
     }

   string                     ProfileBlockStatusText(void) const
     {
      if(m_snapshot.startBlockedReason != "")
         return "Perfil em uso por outro grafico. Carregue outro.";
      if(m_snapshot.activeProfileBlockedReason != "")
         return "Perfil carregado em outro grafico. Carregue outro.";
      return "";
     }

   bool                       RuntimeEditable(const SUIPanelSnapshot &snapshot) const
     {
      return (!snapshot.started && !HasLocalPositionLock(snapshot) && !snapshot.runtimeBlocked);
     }

   bool                       RuntimeEditable(void) const
     {
      return RuntimeEditable(m_snapshot);
     }

   bool                       ActiveProfileEditable(const SUIPanelSnapshot &snapshot) const
     {
      return (RuntimeEditable(snapshot) && !HasPeerProfileLock(snapshot));
     }

   void                       ResetAccessState(SUIAccessState &access) const
     {
      access.hasLocalPositionLock = false;
      access.hasPeerProfileLock = false;
      access.profileEditMode = false;
      access.hasPendingChanges = false;
      access.configInputsValid = false;
      access.runtimeEditable = false;
      access.activeProfileEditable = false;
      access.profileLoadAllowed = false;
      access.profileAdminAllowed = false;
      access.canPause = false;
      access.canStart = false;
      access.canSave = false;
      access.canCancel = false;
     }

   SUIAccessState             BuildAccessState(const SUIPanelSnapshot &snapshot,
                                                const bool profileEditMode,
                                                const bool hasPendingChanges,
                                                const bool configInputsValid) const
     {
      SUIAccessState access;
      ResetAccessState(access);

      access.hasLocalPositionLock = HasLocalPositionLock(snapshot);
      access.hasPeerProfileLock = HasPeerProfileLock(snapshot);
      access.profileEditMode = profileEditMode;
      access.hasPendingChanges = hasPendingChanges;
      access.configInputsValid = configInputsValid;
      access.runtimeEditable = RuntimeEditable(snapshot);
      access.activeProfileEditable = access.runtimeEditable && !access.hasPeerProfileLock;
      access.canPause = (snapshot.started && !access.hasLocalPositionLock);
      access.canStart = (!profileEditMode &&
                         access.activeProfileEditable &&
                         configInputsValid &&
                         !hasPendingChanges &&
                         !snapshot.tradePermissionBlocked);
      access.canSave = (!profileEditMode && access.activeProfileEditable && configInputsValid && hasPendingChanges);
      access.canCancel = (profileEditMode || (access.runtimeEditable && hasPendingChanges));

      if(!profileEditMode && !snapshot.runtimeBlocked && !snapshot.started)
        {
         if(access.hasPeerProfileLock)
            access.profileLoadAllowed = true;
         else if(!access.hasLocalPositionLock)
            access.profileLoadAllowed = !hasPendingChanges;
        }

      access.profileAdminAllowed = (!profileEditMode && access.activeProfileEditable && !hasPendingChanges);
      return access;
     }

   SUIAccessState             CurrentAccessState(void)
     {
      return BuildAccessState(m_snapshot, ProfileEditMode(), HasPendingChanges(), m_configInputsValid);
     }

   bool                       ActiveProfileEditable(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.activeProfileEditable;
     }

   bool                       ProfileLoadAllowed(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.profileLoadAllowed;
     }

   bool                       ProfileAdminAllowed(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.profileAdminAllowed;
     }

   bool                       CanEditSettings(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.runtimeEditable;
     }

   bool                       CanEditActiveProfile(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.activeProfileEditable;
     }

   bool                       TryBeginActiveProfileEdit(const bool refreshWhenBlocked=true)
     {
      if(CanEditActiveProfile())
         return true;
      if(refreshWhenBlocked)
         RefreshTheme();
      return false;
     }

   bool                       CanPause(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.canPause;
     }

   bool                       CanStart(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.canStart;
     }

   bool                       CanSave(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.canSave;
     }

   bool                       CanCancel(void)
     {
      SUIAccessState access = CurrentAccessState();
      return access.canCancel;
     }
