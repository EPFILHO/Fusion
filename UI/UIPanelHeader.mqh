#ifndef __FUSION_UI_PANEL_HEADER_MQH__
#define __FUSION_UI_PANEL_HEADER_MQH__

   CButton                    m_btnStart;
   CButton                    m_btnSave;
   CButton                    m_btnCancel;
   CLabel                     m_activeProfile;
   CLabel                     m_lblProfile;
   CLabel                     m_lblHeader;
   CLabel                     m_parentStatus;
   string                     m_parentStatusText;
   color                      m_parentStatusColor;

   void                       SyncHeaderProfile(const string profileName)
     {
      if(FusionIsBlank(profileName))
        {
         m_activeProfile.Text("--");
         m_activeProfile.Color(FUSION_CLR_BAD);
         return;
        }

      m_activeProfile.Text(profileName);
      m_activeProfile.Color(FUSION_CLR_GOOD);
     }

   bool                       BuildHeader(void)
     {
      int right = FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN;
      int cancelWidth = 94;
      int saveWidth = 84;
      int startWidth = 90;
      int gap = 6;
      int cancelX2 = right;
      int cancelX1 = cancelX2 - cancelWidth;
      int saveX2 = cancelX1 - gap;
      int saveX1 = saveX2 - saveWidth;
      int startX2 = saveX1 - gap;
      int startX1 = startX2 - startWidth;

      if(!AddLabel(m_lblHeader, "Fusion_hdr", 10, 6, startX1 - 12, 26, FusionHeaderTitle(), FUSION_CLR_TITLE, 10))
         return false;
      if(!AddButton(m_btnStart, "Fusion_btnStart", startX1, 4, startX2, 28, "INICIAR", FUSION_CLR_GOOD))
         return false;
      if(!AddButton(m_btnSave, "Fusion_btnSave", saveX1, 4, saveX2, 28, "SALVAR", FUSION_CLR_DISABLED))
         return false;
      FusionApplyNeutralButtonStyle(m_btnSave);
      if(!AddButton(m_btnCancel, "Fusion_btnCancel", cancelX1, 4, cancelX2, 28, "CANCELAR", FUSION_CLR_DISABLED))
         return false;
      FusionApplyNeutralButtonStyle(m_btnCancel);
      if(!AddLabel(m_lblProfile, "Fusion_lblProfile", 10, 36, 124, 54, "Perfil carregado:", FUSION_CLR_MUTED))
         return false;
      if(!AddLabel(m_activeProfile, "Fusion_activeProfile", 126, 36, right - 12, 56, "--", FUSION_CLR_GOOD, 9))
         return false;
      m_activeProfile.Font("Arial Bold");
      if(!AddLabel(m_parentStatus, "Fusion_parent_status", 290, 36, right - 14, 56, "", FUSION_CLR_MUTED, 8))
         return false;
      m_parentStatus.Hide();
      return true;
     }

   void                       UpdateHeaderButtons(void)
     {
      SUIAccessState access = CurrentAccessState();
      if(m_snapshot.runtimeBlocked)
        {
         m_btnStart.Text("BLOQUEADO");
         FusionApplyBlockedButtonStyle(m_btnStart);
         return;
        }

      if(m_snapshot.started)
        {
         m_btnStart.Text(m_snapshot.hasPosition ? "OPERANDO" : "PAUSAR");
         if(access.canPause)
            FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_WARN, true);
         else
            FusionApplyNeutralButtonStyle(m_btnStart);
         return;
        }

      m_btnStart.Text("INICIAR");
      if(access.canStart)
         FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnStart);
     }

   void                       RefreshHeaderTheme(void)
     {
      SUIAccessState access = CurrentAccessState();
      if(!access.runtimeEditable || !access.hasPendingChanges)
         FusionApplyNeutralButtonStyle(m_btnSave);
      else if(access.canSave)
         FusionApplyActionButtonStyle(m_btnSave, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnSave);

      if(access.canCancel)
         FusionApplyActionButtonStyle(m_btnCancel, FUSION_CLR_WARN, true);
      else
         FusionApplyNeutralButtonStyle(m_btnCancel);

      SyncHeaderProfile(DraftProfileName());
      UpdateHeaderButtons();
     }

#endif
