#ifndef __FUSION_UI_PANEL_PROFILE_LIST_VIEW_MQH__
#define __FUSION_UI_PANEL_PROFILE_LIST_VIEW_MQH__

   void                       ClampProfileOffset(void)
     {
      int maxOffset = m_profileCount - FUSION_PROFILE_VISIBLE_ROWS;
      if(maxOffset < 0)
         maxOffset = 0;

      if(m_profileOffset > maxOffset)
         m_profileOffset = maxOffset;
      if(m_profileOffset < 0)
         m_profileOffset = 0;
     }

   void                       EnsureProfileSelectionVisible(void)
     {
      if(m_profileSelected < 0)
        {
         ClampProfileOffset();
         return;
        }

      if(m_profileSelected < m_profileOffset)
         m_profileOffset = m_profileSelected;

      if(m_profileSelected >= m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS)
         m_profileOffset = m_profileSelected - FUSION_PROFILE_VISIBLE_ROWS + 1;

      ClampProfileOffset();
     }

   void                       UpdateProfileRows(void)
     {
      string activeName = m_committedProfileName;
      string activeKey = m_profileStore.SanitizeProfileName(activeName);
      for(int i = 0; i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
        {
         int idx = m_profileOffset + i;
         if(idx >= 0 && idx < m_profileCount)
           {
            string rowText = m_profileNames[idx];
            string rowKey = m_profileStore.SanitizeProfileName(m_profileNames[idx]);
            if(rowKey == activeKey)
               rowText += "  [ATIVO]";
            m_profileRows[i].Text(rowText);

            if(idx == m_profileSelected)
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_NAV_ACTIVE, true);
            else if(rowKey == activeKey)
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_GOOD, true);
            else
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_NAV_IDLE, true);
           }
         else
           {
            m_profileRows[i].Text("");
            FusionApplyNeutralButtonStyle(m_profileRows[i]);
           }
        }

      if(m_profileOffset > 0)
         FusionApplyActionButtonStyle(m_profileUpBtn, FUSION_CLR_NAV_IDLE, true);
      else
         FusionApplyNeutralButtonStyle(m_profileUpBtn);

      if(m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS < m_profileCount)
         FusionApplyActionButtonStyle(m_profileDownBtn, FUSION_CLR_NAV_IDLE, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDownBtn);

      FusionApplyActionButtonStyle(m_profileRefreshBtn, FUSION_CLR_ACTION_LOAD, true);
     }

   void                       BuildProfileEditDraftViewState(SUIProfileEditDraftState &draftState)
     {
      draftState.editMode = ProfileEditMode();
      draftState.duplicateMode = ProfileDuplicateMode();
      draftState.validName = false;
      draftState.nameAvailable = false;
      draftState.magicValid = false;
      draftState.magicAvailable = false;
      draftState.ready = false;
      draftState.draftMagic = 0;
      draftState.draftName = "";
      draftState.magicConflictProfile = "";
      draftState.error = "";

      if(draftState.editMode)
         draftState.ready = ProfileEditDraftState(draftState.draftName,
                                                  draftState.draftMagic,
                                                  draftState.validName,
                                                  draftState.nameAvailable,
                                                  draftState.magicValid,
                                                  draftState.magicAvailable,
                                                  draftState.magicConflictProfile,
                                                  draftState.error);
      else
        {
         draftState.validName = HasValidProfileDraftName();
         draftState.nameAvailable = true;
         draftState.magicValid = true;
         draftState.magicAvailable = true;
        }
     }

   void                       UpdateProfileEditControls(const SUIAccessState &access,const SUIProfileEditDraftState &draftState)
     {
      if(m_profilesEditCreated)
        {
         m_profileNewLbl.Text(draftState.duplicateMode ? "Duplicar como" : "Novo perfil");
         m_profileMagicLbl.Text("Magic");
         m_profileSaveAsBtn.Text(draftState.duplicateMode ? "SALVAR COPIA" : "SALVAR");
         bool nameStyleValid = (!draftState.editMode || !draftState.validName || draftState.nameAvailable);
         FusionApplyEditStyle(m_profileNewEdit, nameStyleValid, draftState.editMode && access.activeProfileEditable);
         FusionApplyEditStyle(m_profileMagicEdit, draftState.magicValid && draftState.magicAvailable, draftState.editMode && access.activeProfileEditable);
         m_profileNewLbl.Color(!draftState.editMode || !access.activeProfileEditable ? FUSION_CLR_MUTED : (nameStyleValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_profileMagicLbl.Color(!draftState.editMode || !access.activeProfileEditable ? FUSION_CLR_MUTED : ((draftState.magicValid && draftState.magicAvailable) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }
     }

   void                       UpdateProfileActionButtons(const SUIAccessState &access,
                                                         const SUIProfileActionState &profileActions,
                                                         const SUIProfileEditDraftState &draftState)
     {
      if(!access.profileEditMode && access.activeProfileEditable)
         FusionApplyActionButtonStyle(m_profileNewBtn, FUSION_CLR_GOOD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileNewBtn);

      if(profileActions.canLoad)
         FusionApplyActionButtonStyle(m_profileLoadBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileLoadBtn);

      if(m_profilesEditCreated)
        {
         if(draftState.editMode && access.activeProfileEditable && access.configInputsValid && draftState.ready)
            FusionApplyActionButtonStyle(m_profileSaveAsBtn, FUSION_CLR_GOOD, true);
         else
            FusionApplyNeutralButtonStyle(m_profileSaveAsBtn);
        }

      if(profileActions.canDuplicate)
         FusionApplyActionButtonStyle(m_profileDuplicateBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDuplicateBtn);

      if(profileActions.canDelete)
         FusionApplyActionButtonStyle(m_profileDeleteBtn, FUSION_CLR_BAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDeleteBtn);

      if(m_profilesEditCreated)
        {
         if(draftState.editMode)
            FusionApplyActionButtonStyle(m_profileCancelBtn, FUSION_CLR_WARN, true);
         else
            FusionApplyNeutralButtonStyle(m_profileCancelBtn);
        }
     }

   void                       UpdateProfileStatusMessage(const SUIAccessState &access,
                                                         const SUIProfileActionState &profileActions,
                                                         const SUIProfileEditDraftState &draftState)
     {
      if(!access.runtimeEditable)
         SetProfileStatus("Perfis bloqueados enquanto o EA roda/gerencia posicao.", FUSION_CLR_WARN);
      else if(draftState.editMode && !draftState.validName)
         SetProfileStatus((draftState.duplicateMode ? "Duplicar: " : "Novo perfil: ") + "informe um nome e clique SALVAR.", FUSION_CLR_MUTED);
      else if(draftState.editMode && !draftState.nameAvailable)
         SetProfileStatus(draftState.error, FUSION_CLR_WARN);
      else if(draftState.editMode && !draftState.magicValid)
         SetProfileStatus(draftState.error, FUSION_CLR_WARN);
      else if(draftState.editMode && !draftState.magicAvailable)
         SetProfileStatus(draftState.error, FUSION_CLR_WARN);
      else if(draftState.editMode && draftState.duplicateMode)
         SetProfileStatus("Copia: " + draftState.draftName + ". Ajuste Magic e salve.", FUSION_CLR_MUTED);
      else if(draftState.editMode)
         SetProfileStatus("Novo perfil: " + draftState.draftName + ". Clique SALVAR para criar.", FUSION_CLR_MUTED);
      else if(m_profileCount == 0)
         SetProfileStatus("Nenhum perfil salvo ainda. Clique NOVO para criar.", FUSION_CLR_MUTED);
      else if(access.hasPendingChanges)
         SetProfileStatus("Alteracoes pendentes. Use SALVAR ou crie NOVO perfil.", FUSION_CLR_WARN);
      else if(profileActions.selected && profileActions.selectedIsActive && m_snapshot.startBlockedReason != "")
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Magic em uso em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(profileActions.selected && profileActions.selectedIsActive && m_snapshot.activeProfileBlockedReason != "")
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Perfil carregado em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(profileActions.selected && profileActions.selectedIsActive && profileActions.selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Default reservado.", FUSION_CLR_MUTED);
      else if(profileActions.selected && profileActions.selectedIsActive)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Use NOVO ou selecione outro.", FUSION_CLR_MUTED);
      else if(profileActions.selected && profileActions.selectedRuntimeLocked)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Magic em uso em outro grafico.", FUSION_CLR_WARN);
      else if(profileActions.selected && profileActions.selectedActiveProfileLocked)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Perfil carregado em outro grafico.", FUSION_CLR_WARN);
      else if(profileActions.selected && profileActions.selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Default reservado.", FUSION_CLR_WARN);
      else if(profileActions.selected)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Use Carregar, Duplicar, Novo ou Excluir.", FUSION_CLR_MUTED);
      else if(m_snapshot.startBlockedReason != "")
         SetProfileStatus("Perfil em uso em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(m_snapshot.activeProfileBlockedReason != "")
         SetProfileStatus("Perfil carregado em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else
         SetProfileStatus("Selecione um perfil ou clique NOVO para criar.", FUSION_CLR_MUTED);
     }

   void                       UpdateProfileListView(const bool keepSelectionVisible=true)
     {
      if(!m_profilesTabCreated || !m_profilesBrowseCreated)
         return;

      if(keepSelectionVisible)
         EnsureProfileSelectionVisible();
      else
         ClampProfileOffset();

      UpdateProfileRows();

      SUIAccessState access = CurrentAccessState();
      SUIProfileActionState profileActions = BuildProfileActionState(access);
      SUIProfileEditDraftState draftState;
      BuildProfileEditDraftViewState(draftState);
      RefreshProfileValidationState();

      UpdateProfileEditControls(access, draftState);
      UpdateProfileActionButtons(access, profileActions, draftState);
      UpdateProfileStatusMessage(access, profileActions, draftState);
     }

#endif
