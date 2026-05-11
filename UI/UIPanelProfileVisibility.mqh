#ifndef __FUSION_UI_PANEL_PROFILE_VISIBILITY_MQH__
#define __FUSION_UI_PANEL_PROFILE_VISIBILITY_MQH__

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
         SetVisible(m_profileMagicLbl, editVisible);
         SetVisible(m_profileMagicEdit, editVisible);
         SetVisible(m_profileSaveAsBtn, editVisible);
         SetVisible(m_profileCancelBtn, editVisible);
        }

      SetVisible(m_profileStatus, visible);
     }

#endif
