#ifndef __FUSION_UI_PANEL_RISK_INPUTS_MQH__
#define __FUSION_UI_PANEL_RISK_INPUTS_MQH__

   bool                       HandleRiskBooleanToggle(const string objectName,CButton &button,bool &target,const bool enabled)
     {
      if(objectName != button.Name())
         return false;

      ReleaseButton(button);
      if(!CanEditActiveProfile() || !enabled)
         return true;

      target = !target;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskTP1Toggle(const string objectName)
     {
      if(objectName != m_cfgRiskTP1EnabledBtn.Name())
         return false;

      ReleaseButton(m_cfgRiskTP1EnabledBtn);
      if(!CanEditActiveProfile())
         return true;

      m_draftSettings.tp1.enabled = !m_draftSettings.tp1.enabled;
      if(!m_draftSettings.tp1.enabled)
        {
         m_draftSettings.tp2.enabled = false;
         m_draftSettings.freeFinalTP = false;
        }
      m_draftSettings.usePartialTP = m_draftSettings.tp1.enabled;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskTP2Toggle(const string objectName)
     {
      if(objectName != m_cfgRiskTP2EnabledBtn.Name())
         return false;

      ReleaseButton(m_cfgRiskTP2EnabledBtn);
      if(!CanEditActiveProfile() || !m_draftSettings.tp1.enabled)
         return true;

      m_draftSettings.tp2.enabled = !m_draftSettings.tp2.enabled;
      m_draftSettings.usePartialTP = m_draftSettings.tp1.enabled;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskFreeTPToggle(const string objectName)
     {
      if(objectName != m_cfgRiskFreeTPBtn.Name())
         return false;

      ReleaseButton(m_cfgRiskFreeTPBtn);
      if(!CanEditActiveProfile() || !m_draftSettings.tp1.enabled)
         return true;

      m_draftSettings.freeFinalTP = !m_draftSettings.freeFinalTP;
      m_draftSettings.usePartialTP = m_draftSettings.tp1.enabled;
      RefreshConfigValidation();
      return true;
     }

   bool                       HandleRiskToggleClick(const string objectName)
     {
      if(!m_configRiskCreated)
         return false;

      if(HandleRiskTP1Toggle(objectName))
         return true;
      if(HandleRiskTP2Toggle(objectName))
         return true;
      if(HandleRiskFreeTPToggle(objectName))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskSLCompBtn, m_draftSettings.compensateSLSpread, true))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskTPCompBtn, m_draftSettings.compensateTPSpread, true))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskBreakevenEnabledBtn, m_draftSettings.useBreakeven, true))
         return true;
      if(HandleRiskBooleanToggle(objectName, m_cfgRiskTrailingEnabledBtn, m_draftSettings.useTrailing, true))
         return true;
      return false;
     }

   bool                       HandleRiskClick(const string objectName)
     {
      if(HandleRiskPageClick(objectName))
         return true;
      if(HandleRiskToggleClick(objectName))
         return true;
      return false;
     }

   bool                       HandleRiskPageClick(const string objectName)
     {
      if(!m_configRiskCreated)
         return false;

      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
        {
         if(objectName != m_riskTabs[tabIndex].Name())
            continue;

         ReleaseButton(m_riskTabs[tabIndex]);
         ResetDialogMouseRouting();
         m_riskPage = (ENUM_FUSION_RISK_PAGE)tabIndex;
         ApplyVisibility(false);
         RefreshConfigValidation();
         return true;
        }

      return false;
     }

#endif
