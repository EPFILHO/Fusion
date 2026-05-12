   bool                       ProfileEditMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_NEW || m_profileMode == FUSION_PROFILE_DUPLICATE);
     }

   bool                       ProfileDuplicateMode(void)
     {
      return (m_profileMode == FUSION_PROFILE_DUPLICATE);
     }

   void                       SplitProfileStatusText(const string text,string &line1,string &line2) const
     {
      line1 = text;
      line2 = "";

      int splitAt = StringFind(text, ". ");
      if(splitAt <= 0)
         return;

      line1 = StringSubstr(text, 0, splitAt + 1);
      line2 = FusionTrimCopy(StringSubstr(text, splitAt + 2));
     }

   void                       ApplyProfileStatusLabels(const string text,const color clr)
     {
      if(!m_profilesTabCreated)
         return;

      string line1 = "";
      string line2 = "";
      SplitProfileStatusText(text, line1, line2);
      m_profileStatus.Text(line1);
      m_profileStatus.Color(clr);
      m_profileStatusDetail.Text(line2);
      m_profileStatusDetail.Color(clr);
     }

   void                       SetProfileStatus(const string text,const color clr,const bool persist=false)
     {
      uint now = GetTickCount();
      if(!persist && m_profileStatusOverrideUntil > now)
        {
         ApplyProfileStatusLabels(m_profileStatusOverride, m_profileStatusOverrideColor);
         return;
        }

      if(persist)
        {
         m_profileStatusOverride = text;
         m_profileStatusOverrideColor = clr;
         m_profileStatusOverrideUntil = now + 5000;
        }

      ApplyProfileStatusLabels(text, clr);
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
