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
   CButton                    m_profileLoadBtn;
   CButton                    m_profileSaveAsBtn;
   CButton                    m_profileDuplicateBtn;
   CButton                    m_profileDeleteBtn;
   CButton                    m_profileCancelBtn;
   CLabel                     m_profileStatus;

   bool                       ProfileEditMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_NEW || m_profileMode == FUSION_PROFILE_DUPLICATE);
     }

   bool                       ProfileDuplicateMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_DUPLICATE);
     }

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
      if(ok && !AddButton(m_profileSaveAsBtn, "Fusion_profile_save_as", 390, 298, 520, 324, "SALVAR", FUSION_CLR_GOOD))
         ok = false;
      if(ok && !AddButton(m_profileCancelBtn, "Fusion_profile_cancel", 390, 330, 520, 356, "CANCELAR", FUSION_CLR_WARN))
         ok = false;
      PopBuildTarget(previous);
      if(!ok)
         return false;

      m_profilesEditCreated = true;
      m_profileNewEdit.Text(m_profileStore.SanitizeProfileName(m_profileEditSourceName == "" ? "" : m_profileEditSourceName));
      UpdateProfileListView();
      return true;
     }

   void                       SetProfileMode(const ENUM_FUSION_PROFILE_MODE mode,const string draft="",const string sourceName="")
     {
      m_profileMode = mode;
      m_profileEditSourceName = sourceName;

      if(m_profilesEditCreated)
         m_profileNewEdit.Text(draft);
     }

   string                     SuggestedDuplicateName(const string sourceName)
     {
      string baseName = m_profileStore.SanitizeProfileName(sourceName);
      if(FusionIsBlank(baseName))
         baseName = "perfil";

      string candidate = baseName + "_copy";
      if(!m_profileStore.ProfileExists(candidate))
         return candidate;

      for(int i = 2; i < 1000; ++i)
        {
         candidate = baseName + "_copy_" + IntegerToString(i);
         if(!m_profileStore.ProfileExists(candidate))
            return candidate;
        }

      return baseName + "_copy_" + IntegerToString((int)GetTickCount());
     }

   string                     ProfileDraftName(void)
     {
      if(!m_profilesEditCreated)
         return "";
      return m_profileStore.SanitizeProfileName(FusionTrimCopy(LiveEditText(m_profileNewEdit)));
     }

   bool                       HasValidProfileDraftName(void)
     {
      return !FusionIsBlank(ProfileDraftName());
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

   bool                       MagicAvailableForProfile(const int magicNumber,const string profileName,string &conflictProfile)
     {
      conflictProfile = "";
      if(magicNumber <= 0)
         return false;
      return !m_profileStore.FindProfileByMagicNumber(magicNumber, profileName, conflictProfile);
     }

   bool                       CanStartNewProfile(void)
     {
      return (!ProfileEditMode() && CanEditActiveProfile());
     }

   bool                       CanStartDuplicateProfile(void)
     {
      return (CanAdminProfiles() && SelectedProfileName() != "");
     }

   void                       SetProfileStatus(const string text,const color clr,const bool persist=false)
     {
      uint now = GetTickCount();
      if(!persist && m_profileStatusOverrideUntil > now)
        {
         if(m_profilesTabCreated)
           {
            m_profileStatus.Text(m_profileStatusOverride);
            m_profileStatus.Color(m_profileStatusOverrideColor);
           }
         return;
        }

      if(persist)
        {
         m_profileStatusOverride = text;
         m_profileStatusOverrideColor = clr;
         m_profileStatusOverrideUntil = now + 5000;
        }

      if(m_profilesTabCreated)
        {
         m_profileStatus.Text(text);
         m_profileStatus.Color(clr);
        }
     }

   void                       ClearProfileStatusOverride(void)
     {
      m_profileStatusOverride = "";
      m_profileStatusOverrideColor = FUSION_CLR_MUTED;
      m_profileStatusOverrideUntil = 0;
     }

   void                       EnsureProfileSelectionVisible(void)
     {
      if(m_profileSelected < 0)
        {
         m_profileOffset = 0;
         return;
        }

      if(m_profileSelected < m_profileOffset)
         m_profileOffset = m_profileSelected;

      if(m_profileSelected >= m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS)
         m_profileOffset = m_profileSelected - FUSION_PROFILE_VISIBLE_ROWS + 1;

      int maxOffset = m_profileCount - FUSION_PROFILE_VISIBLE_ROWS;
      if(maxOffset < 0)
         maxOffset = 0;
      if(m_profileOffset > maxOffset)
         m_profileOffset = maxOffset;
      if(m_profileOffset < 0)
         m_profileOffset = 0;
     }

   void                       UpdateProfileListView(void)
     {
      if(!m_profilesTabCreated || !m_profilesBrowseCreated)
         return;

      EnsureProfileSelectionVisible();

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

      bool validName = HasValidProfileDraftName();
      bool selected = (SelectedProfileName() != "");
      bool selectedIsActive = (m_profileStore.SanitizeProfileName(SelectedProfileName()) == activeKey);
      bool selectedIsDefault = IsDefaultProfileName(SelectedProfileName());
      bool draftExists = (m_profilesEditCreated && validName && m_profileStore.ProfileExists(ProfileDraftName()));
      bool editMode = ProfileEditMode();
      bool duplicateMode = ProfileDuplicateMode();
      int draftMagic = 0;
      string magicConflictProfile = "";
      bool magicAvailableForDraft = true;
      if(editMode && validName && ParsedDraftMagicNumber(draftMagic))
         magicAvailableForDraft = MagicAvailableForProfile(draftMagic, ProfileDraftName(), magicConflictProfile);

      if(m_profilesEditCreated)
        {
         m_profileNewLbl.Text(duplicateMode ? "Duplicar como" : "Novo perfil");
         m_profileSaveAsBtn.Text(duplicateMode ? "SALVAR COPIA" : "SALVAR");
         FusionApplyEditStyle(m_profileNewEdit, true, editMode && CanEditActiveProfile());
         m_profileNewLbl.Color((editMode && CanEditActiveProfile()) ? FUSION_CLR_LABEL : FUSION_CLR_MUTED);
      }

      if(CanStartNewProfile())
         FusionApplyActionButtonStyle(m_profileNewBtn, FUSION_CLR_GOOD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileNewBtn);

      if(CanLoad() && selected && !editMode)
         FusionApplyActionButtonStyle(m_profileLoadBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileLoadBtn);

      if(m_profilesEditCreated)
        {
         if(editMode && CanEditActiveProfile() && m_configInputsValid && validName && !draftExists && magicAvailableForDraft)
            FusionApplyActionButtonStyle(m_profileSaveAsBtn, FUSION_CLR_GOOD, true);
         else
            FusionApplyNeutralButtonStyle(m_profileSaveAsBtn);
        }

      if(CanStartDuplicateProfile())
         FusionApplyActionButtonStyle(m_profileDuplicateBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDuplicateBtn);

      if(CanAdminProfiles() && selected && !editMode && !selectedIsActive && !selectedIsDefault)
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

      if(!CanEditSettings())
         SetProfileStatus("Perfis bloqueados enquanto o EA roda ou gerencia posicao.", FUSION_CLR_WARN);
      else if(m_snapshot.startBlockedReason != "")
         SetProfileStatus("Perfil em uso por outra instancia: carregue outro perfil salvo para continuar.", FUSION_CLR_WARN);
      else if(editMode && !validName)
         SetProfileStatus((duplicateMode ? "Duplicar: " : "Novo perfil: ") + "informe um nome e clique SALVAR.", FUSION_CLR_MUTED);
      else if(editMode && draftExists)
         SetProfileStatus("Nome ja existe. Escolha outro nome ou cancele.", FUSION_CLR_WARN);
      else if(editMode && !magicAvailableForDraft)
         SetProfileStatus("Magic ja usado pelo perfil " + magicConflictProfile + ".", FUSION_CLR_WARN);
      else if(editMode && duplicateMode)
         SetProfileStatus("Copia de " + m_profileEditSourceName + " como " + ProfileDraftName() + ". Altere o Magic se necessario e salve.", FUSION_CLR_MUTED);
      else if(editMode)
         SetProfileStatus("Novo perfil: " + ProfileDraftName() + ". Clique SALVAR para criar.", FUSION_CLR_MUTED);
      else if(m_profileCount == 0)
         SetProfileStatus("Nenhum perfil salvo ainda. Clique NOVO para criar.", FUSION_CLR_MUTED);
      else if(HasPendingChanges())
         SetProfileStatus("Alteracoes pendentes: use SALVAR no perfil atual ou NOVO para criar outro.", FUSION_CLR_WARN);
      else if(selected && selectedIsActive && selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Perfil reservado: nao apague o perfil default.", FUSION_CLR_MUTED);
      else if(selected && selectedIsActive)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + " [ATIVO]. Use NOVO ou selecione outro perfil.", FUSION_CLR_MUTED);
      else if(selected && selectedIsDefault)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Perfil reservado: nao apague o perfil default.", FUSION_CLR_WARN);
      else if(selected)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Use Carregar, Duplicar, Novo ou Excluir.", FUSION_CLR_MUTED);
      else
         SetProfileStatus("Selecione um perfil ou clique NOVO para criar.", FUSION_CLR_MUTED);
     }

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
      if(!AddLabel(m_profileStatus, "Fusion_profile_status", 24, 430, 520, 456, "", FUSION_CLR_MUTED, 8))
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

#endif
