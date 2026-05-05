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

   bool                       MagicAvailableForProfile(const int magicNumber,const string profileName,string &conflictProfile)
     {
      conflictProfile = "";
      if(magicNumber <= 0)
         return false;
      return !m_profileStore.FindProfileByMagicNumber(magicNumber, profileName, conflictProfile);
     }

   bool                       ProfileEditDraftState(string &draftName,
                                                    int &draftMagic,
                                                    bool &validName,
                                                    bool &nameAvailable,
                                                    bool &magicValid,
                                                    bool &magicAvailable,
                                                    string &magicConflictProfile,
                                                    string &error)
     {
      draftName = ProfileDraftName();
      draftMagic = 0;
      validName = !FusionIsBlank(draftName);
      nameAvailable = validName && !m_profileStore.ProfileExists(draftName);
      magicValid = ParsedProfileMagicNumber(draftMagic);
      magicAvailable = magicValid;
      magicConflictProfile = "";
      error = "";

      if(validName && magicValid)
         magicAvailable = MagicAvailableForProfile(draftMagic, "", magicConflictProfile);

      if(validName && !nameAvailable)
         error = "Nome ja existe. Escolha outro nome.";
      else if(validName && !magicValid)
         error = "Magic invalido. Informe um numero inteiro positivo.";
      else if(validName && !magicAvailable)
         error = "Magic ja usado pelo perfil " + magicConflictProfile + ".";

      return (validName && nameAvailable && magicValid && magicAvailable);
     }

   void                       RefreshProfileValidationState(void)
     {
      m_profileTabValid = true;
      m_profileTabError = "";
      if(!ProfileEditMode() || !m_profilesEditCreated)
         return;

      string draftName = "";
      int draftMagic = 0;
      bool validName = false;
      bool nameAvailable = false;
      bool magicValid = false;
      bool magicAvailable = false;
      string magicConflictProfile = "";
      string error = "";
      ProfileEditDraftState(draftName,
                            draftMagic,
                            validName,
                            nameAvailable,
                            magicValid,
                            magicAvailable,
                            magicConflictProfile,
                            error);
      if(error != "")
        {
         m_profileTabValid = false;
         m_profileTabError = error;
        }
     }

   bool                       HasProfileTabError(void) const
     {
      return !m_profileTabValid;
     }
