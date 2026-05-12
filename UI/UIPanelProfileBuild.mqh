#ifndef __FUSION_UI_PANEL_PROFILE_BUILD_MQH__
#define __FUSION_UI_PANEL_PROFILE_BUILD_MQH__

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
      if(!AddLabel(m_profileStatus, "Fusion_profile_status", 24, 420, FUSION_PANEL_WIDTH - 18, 438, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_profileStatusDetail, "Fusion_profile_status_detail", 24, 438, FUSION_PANEL_WIDTH - 18, 456, "", FUSION_CLR_MUTED, 8))
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
