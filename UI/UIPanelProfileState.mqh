   bool                       ProfileEditMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_NEW || m_profileMode == FUSION_PROFILE_DUPLICATE);
     }

   bool                       ProfileDuplicateMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_DUPLICATE);
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

   void                       SetProfileMode(const ENUM_FUSION_PROFILE_MODE mode,const string draft="",const string sourceName="")
     {
      ClearProfileStatusOverride();
      m_profileMode = mode;
      m_profileEditSourceName = sourceName;

      if(m_profilesEditCreated)
        {
         m_profileNewEdit.Text(draft);
         m_profileMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
        }
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
