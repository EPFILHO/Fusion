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

   void                       UpdateProfileListView(const bool keepSelectionVisible=true)
     {
      if(!m_profilesTabCreated || !m_profilesBrowseCreated)
         return;

      if(keepSelectionVisible)
         EnsureProfileSelectionVisible();
      else
         ClampProfileOffset();

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

      SUIAccessState access = CurrentAccessState();
      SUIProfileActionState profileActions = BuildProfileActionState(access);
      bool selected = profileActions.selected;
      bool selectedIsActive = profileActions.selectedIsActive;
      bool selectedIsDefault = profileActions.selectedIsDefault;
      bool selectedRuntimeLocked = profileActions.selectedRuntimeLocked;
      bool selectedActiveProfileLocked = profileActions.selectedActiveProfileLocked;
      bool editMode = ProfileEditMode();
      bool duplicateMode = ProfileDuplicateMode();
      int draftMagic = 0;
      string draftName = "";
      string magicConflictProfile = "";
      string profileDraftError = "";
      bool validName = false;
      bool nameAvailable = false;
      bool draftMagicValid = false;
      bool magicAvailableForDraft = false;
      bool profileDraftReady = false;
      if(editMode)
         profileDraftReady = ProfileEditDraftState(draftName,
                                                   draftMagic,
                                                   validName,
                                                   nameAvailable,
                                                   draftMagicValid,
                                                   magicAvailableForDraft,
                                                   magicConflictProfile,
                                                   profileDraftError);
      else
        {
         validName = HasValidProfileDraftName();
         nameAvailable = true;
         draftMagicValid = true;
         magicAvailableForDraft = true;
        }
      RefreshProfileValidationState();

      if(m_profilesEditCreated)
        {
         m_profileNewLbl.Text(duplicateMode ? "Duplicar como" : "Novo perfil");
         m_profileMagicLbl.Text("Magic");
         m_profileSaveAsBtn.Text(duplicateMode ? "SALVAR COPIA" : "SALVAR");
         bool nameStyleValid = (!editMode || !validName || nameAvailable);
         FusionApplyEditStyle(m_profileNewEdit, nameStyleValid, editMode && access.activeProfileEditable);
         FusionApplyEditStyle(m_profileMagicEdit, draftMagicValid && magicAvailableForDraft, editMode && access.activeProfileEditable);
         m_profileNewLbl.Color(!editMode || !access.activeProfileEditable ? FUSION_CLR_MUTED : (nameStyleValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_profileMagicLbl.Color(!editMode || !access.activeProfileEditable ? FUSION_CLR_MUTED : ((draftMagicValid && magicAvailableForDraft) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

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
         if(editMode && access.activeProfileEditable && access.configInputsValid && profileDraftReady)
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
         if(editMode)
            FusionApplyActionButtonStyle(m_profileCancelBtn, FUSION_CLR_WARN, true);
         else
            FusionApplyNeutralButtonStyle(m_profileCancelBtn);
        }

      if(!access.runtimeEditable)
         SetProfileStatus("Perfis bloqueados enquanto o EA roda/gerencia posicao.", FUSION_CLR_WARN);
      else if(editMode && !validName)
         SetProfileStatus((duplicateMode ? "Duplicar: " : "Novo perfil: ") + "informe um nome e clique SALVAR.", FUSION_CLR_MUTED);
      else if(editMode && !nameAvailable)
         SetProfileStatus(profileDraftError, FUSION_CLR_WARN);
      else if(editMode && !draftMagicValid)
         SetProfileStatus(profileDraftError, FUSION_CLR_WARN);
      else if(editMode && !magicAvailableForDraft)
         SetProfileStatus(profileDraftError, FUSION_CLR_WARN);
      else if(editMode && duplicateMode)
         SetProfileStatus("Copia: " + draftName + ". Ajuste Magic e salve.", FUSION_CLR_MUTED);
      else if(editMode)
         SetProfileStatus("Novo perfil: " + draftName + ". Clique SALVAR para criar.", FUSION_CLR_MUTED);
      else if(m_profileCount == 0)
         SetProfileStatus("Nenhum perfil salvo ainda. Clique NOVO para criar.", FUSION_CLR_MUTED);
      else if(access.hasPendingChanges)
         SetProfileStatus("Alteracoes pendentes. Use SALVAR ou crie NOVO perfil.", FUSION_CLR_WARN);
      else if(selected && selectedIsActive && m_snapshot.startBlockedReason != "")
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Magic em uso em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(selected && selectedIsActive && m_snapshot.activeProfileBlockedReason != "")
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Perfil carregado em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(selected && selectedIsActive && selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Default reservado.", FUSION_CLR_MUTED);
      else if(selected && selectedIsActive)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Use NOVO ou selecione outro.", FUSION_CLR_MUTED);
      else if(selected && selectedRuntimeLocked)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Magic em uso em outro grafico.", FUSION_CLR_WARN);
      else if(selected && selectedActiveProfileLocked)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Perfil carregado em outro grafico.", FUSION_CLR_WARN);
      else if(selected && selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Default reservado.", FUSION_CLR_WARN);
      else if(selected)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Use Carregar, Duplicar, Novo ou Excluir.", FUSION_CLR_MUTED);
      else if(m_snapshot.startBlockedReason != "")
         SetProfileStatus("Perfil em uso em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else if(m_snapshot.activeProfileBlockedReason != "")
         SetProfileStatus("Perfil carregado em outro grafico. Carregue outro perfil.", FUSION_CLR_WARN);
      else
         SetProfileStatus("Selecione um perfil ou clique NOVO para criar.", FUSION_CLR_MUTED);
     }

#endif
