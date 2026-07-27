#ifndef __FUSION_EA_APPLICATION_PROFILE_BLOCK_MQH__
#define __FUSION_EA_APPLICATION_PROFILE_BLOCK_MQH__

   void                    RefreshStartBlockReason(void)
     {
      m_startBlockedReason = "";
      if(m_settings.isTester)
         return;

      if(m_started)
         return;

      string reason = "";
      if(m_instanceRegistry.HasActiveConflict(m_settings.magicNumber, ChartID(), reason))
         m_startBlockedReason = reason + " Carregue outro perfil antes de iniciar.";
     }

   void                    RefreshActiveProfileRegistration(void)
     {
      if(m_settings.isTester || m_activeProfileName == "")
        {
         m_activeProfileRegistry.Unregister();
         return;
        }

      m_activeProfileRegistry.Register(m_activeProfileName, ChartID());
     }

   void                    RefreshActiveProfileBlockReason(void)
     {
      m_activeProfileBlockedReason = "";
      if(m_settings.isTester || m_activeProfileName == "")
         return;

      if(m_started || HasManagedOrPendingPosition())
         return;

      string reason = "";
      if(m_activeProfileRegistry.HasActiveProfilePeer(m_activeProfileName, ChartID(), reason))
         m_activeProfileBlockedReason = reason + " Carregue outro perfil salvo para continuar.";
     }

   // O arquivo do perfil pode sumir a qualquer momento por acao externa, entao a
   // checagem e refeita periodicamente. Fica aqui, e nao em BuildPanelSnapshot,
   // para nao colocar acesso a disco no caminho do tick: OnTimer chama isto a 1 Hz.
   void                    RefreshActiveProfileFileState(void)
     {
      m_activeProfileFileMissing = false;
      if(m_settings.isTester || m_activeProfileName == "")
         return;

      m_activeProfileFileMissing = !m_settingsStore.ProfileExists(m_activeProfileName);
     }

   void                    RefreshProfileBlockReasons(void)
     {
      RefreshActiveProfileRegistration();
      RefreshStartBlockReason();
      RefreshActiveProfileBlockReason();
      RefreshActiveProfileFileState();
     }

   bool                    StartBlockedByProfilePeer(void) const
     {
      return (m_startBlockedReason != "" || m_activeProfileBlockedReason != "");
     }

   bool                    ProfileBlockedByActiveProfilePeer(const string profileName,string &reason)
     {
      reason = "";
      if(m_settings.isTester || profileName == "")
         return false;

      return m_activeProfileRegistry.HasActiveProfilePeer(profileName, ChartID(), reason);
     }

   bool                    ProfileLoadBlockedByActiveProfile(const string profileName)
     {
      string reason = "";
      if(!ProfileBlockedByActiveProfilePeer(profileName, reason))
         return false;
      m_logger.Error("PROFILE", "Perfil " + profileName + " nao carregado: " + reason);
      return true;
     }

   bool                    ProfileSaveBlockedByActiveProfile(const string profileName)
     {
      string reason = "";
      if(!ProfileBlockedByActiveProfilePeer(profileName, reason))
         return false;
      m_logger.Error("PROFILE", "Perfil " + profileName + " nao salvo: " + reason);
      return true;
     }

   bool                    ProfileLoadBlockedByActiveDrawdown(const string profileName,const SEASettings &settings)
     {
      string lockReason = "";
      if(!m_protectionManager.IsDrawdownConfigLocked(lockReason))
         return false;
      if(FusionDrawdownSettingsCompatible(m_settings, settings))
         return false;

      m_logger.Warn("PROFILE", "Perfil " + profileName + ": " + FusionDrawdownProfileBlockMessage());
      return true;
     }

   bool                    ProfileLoadBlockedByActiveInstance(const string profileName,const SEASettings &settings)
     {
      if(settings.isTester)
         return false;

      string reason = "";
      if(!m_instanceRegistry.HasActiveConflict(settings.magicNumber, ChartID(), reason))
         return false;

      m_logger.Error("PROFILE", "Perfil " + profileName + " nao carregado: " + reason);
      return true;
     }

#endif
