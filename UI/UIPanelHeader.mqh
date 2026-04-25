#ifndef __FUSION_UI_PANEL_HEADER_MQH__
#define __FUSION_UI_PANEL_HEADER_MQH__

   CButton                    m_btnStart;
   CButton                    m_btnSave;
   CLabel                     m_activeProfile;
   CLabel                     m_lblProfile;
   CLabel                     m_lblHeader;

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
      if(!AddLabel(m_lblHeader, "Fusion_hdr", 10, 6, 330, 26, FusionHeaderTitle(), FUSION_CLR_TITLE, 10))
         return false;
      if(!AddButton(m_btnStart, "Fusion_btnStart", 350, 4, 440, 28, "INICIAR", FUSION_CLR_GOOD))
         return false;
      if(!AddButton(m_btnSave, "Fusion_btnSave", 446, 4, 530, 28, "SALVAR", FUSION_CLR_ACTION_SAVE))
         return false;
      if(!AddLabel(m_lblProfile, "Fusion_lblProfile", 10, 36, 124, 54, "Perfil carregado:", FUSION_CLR_MUTED))
         return false;
      if(!AddLabel(m_activeProfile, "Fusion_activeProfile", 126, 36, 330, 56, "--", FUSION_CLR_GOOD, 9))
         return false;
      m_activeProfile.Font("Arial Bold");
      return true;
     }

   void                       UpdateHeaderButtons(void)
     {
      if(m_snapshot.runtimeBlocked)
        {
         m_btnStart.Text("BLOQUEADO");
         FusionApplyBlockedButtonStyle(m_btnStart);
         if(m_configProtectionCreated)
            FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, false, false);
         return;
        }

      if(m_snapshot.started)
        {
         m_btnStart.Text(m_snapshot.hasPosition ? "OPERANDO" : "PAUSAR");
         if(CanPause())
            FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_WARN, true);
         else
            FusionApplyNeutralButtonStyle(m_btnStart);
         if(m_configProtectionCreated)
            FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, true, CanPause());
         return;
        }

      m_btnStart.Text("INICIAR");
      if(CanStart())
         FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnStart);

      if(m_configProtectionCreated)
         FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, false, CanStart());
     }

   void                       RefreshHeaderTheme(void)
     {
      if(!CanEditSettings() || !HasPendingChanges())
         FusionApplyNeutralButtonStyle(m_btnSave);
      else if(CanSave())
         FusionApplyActionButtonStyle(m_btnSave, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnSave);

      SyncHeaderProfile(DraftProfileName());
      UpdateHeaderButtons();
     }

#endif
