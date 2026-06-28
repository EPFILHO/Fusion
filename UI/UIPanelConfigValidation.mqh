#ifndef __FUSION_UI_PANEL_CONFIG_VALIDATION_MQH__
#define __FUSION_UI_PANEL_CONFIG_VALIDATION_MQH__

   void                       ValidateProtectionStyleOnly(const SEASettings &baseSettings)
     {
      SEASettings styleSettings = baseSettings;
      string ignoredError = "";
      ValidateProtectionSettings(styleSettings, false, ignoredError);
     }

   void                       ValidateStrategyPanelsStyleOnly(const SEASettings &baseSettings)
     {
      SEASettings styleSettings = baseSettings;
      string ignoredError = "";
      ValidateStrategyPanels(styleSettings, false, ignoredError);
     }

   void                       ValidateFilterPanelsStyleOnly(const SEASettings &baseSettings)
     {
      SEASettings styleSettings = baseSettings;
      string ignoredError = "";
      ValidateFilterPanels(styleSettings, false, ignoredError);
     }

   bool                       BuildPendingSettingsWithoutConfigTab(SEASettings &outSettings,
                                                                   const bool profileValid,
                                                                   const bool editable,
                                                                   const string profileForMagicCheck,
                                                                   string &outStatus)
     {
      outSettings.slippagePoints = m_draftSettings.slippagePoints;
      outSettings.fixedLot = m_draftSettings.fixedLot;
      outSettings.fixedSLPoints = m_draftSettings.fixedSLPoints;
      outSettings.fixedTPPoints = m_draftSettings.fixedTPPoints;
      outSettings.magicNumber = m_draftSettings.magicNumber;

      int parsedMagic = outSettings.magicNumber;
      bool magicValid = true;
      bool magicUnique = true;
      string magicConflictProfile = "";
      if(editable)
        {
         magicValid = ParsedConfigMagicNumber(parsedMagic);
         if(magicValid)
           {
            outSettings.magicNumber = parsedMagic;
            if(ProfileEditMode())
               magicUnique = true;
            else
               magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);
           }
        }

      string strategyError = "";
      string filterError = "";
      string sltpError = "";
      string partialError = "";
      string beError = "";
      string trailingError = "";
      bool strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);
      bool filterValid = ValidateFilterPanels(outSettings, editable, filterError);
      bool slValid = (outSettings.fixedSLPoints >= 0 && outSettings.fixedSLPoints <= 100000);
      bool tpValid = (outSettings.fixedTPPoints >= 0 && outSettings.fixedTPPoints <= 100000);
      bool slippageValid = (outSettings.slippagePoints >= 0 && outSettings.slippagePoints <= 100000);
      bool sltpValid = ValidateRiskSLTPSettings(outSettings,
                                                slValid,
                                                outSettings.fixedSLPoints,
                                                tpValid,
                                                outSettings.fixedTPPoints,
                                                editable,
                                                sltpError);
      bool partialValid = ValidateRiskPartialSettings(outSettings, editable, partialError);
      bool beValid = ValidateRiskBreakevenSettings(outSettings, editable, beError);
      bool trailingValid = ValidateRiskTrailingSettings(outSettings, editable, trailingError);
      m_cfgRiskLotValid = (outSettings.fixedLot > 0.0 && slippageValid);
      m_cfgRiskLotError = !slippageValid ? "Slippage invalido. Use 0 a 100000 pontos." : "";
      m_cfgRiskSLTPValid = sltpValid;
      m_cfgRiskSLTPError = sltpError;
      m_cfgRiskPartialValid = partialValid;
      m_cfgRiskPartialError = partialError;
      m_cfgRiskBEValid = beValid;
      m_cfgRiskBEError = beError;
      m_cfgRiskTrailingValid = trailingValid;
      m_cfgRiskTrailingError = trailingError;
      m_cfgRiskValid = (outSettings.fixedLot > 0.0 && slippageValid && sltpValid && partialValid && beValid && trailingValid);
      m_cfgProtectionValid = true;
      m_cfgSystemValid = (magicValid && magicUnique && outSettings.magicNumber > 0);
      m_configInputsValid = (profileValid &&
                             m_cfgRiskValid &&
                             magicValid &&
                             magicUnique &&
                             outSettings.magicNumber > 0 &&
                             strategyValid &&
                             filterValid);
      ApplyStrategyStatus(strategyValid, strategyError);
      ApplyFilterStatus(filterValid, filterError);
      if(m_configInputsValid && editable)
         m_draftSettings = outSettings;

      if(m_configInputsValid)
         outStatus = "Configuracao pronta.";
      else if(!magicValid)
         outStatus = "Magic invalido. Informe um numero inteiro positivo.";
      else if(!magicUnique)
         outStatus = "Magic ja usado pelo perfil " + magicConflictProfile + ".";
      else if(!sltpValid)
         outStatus = sltpError;
      else if(!slippageValid)
         outStatus = m_cfgRiskLotError;
      else if(!partialValid)
         outStatus = partialError;
      else if(!beValid)
         outStatus = beError;
      else if(!trailingValid)
         outStatus = trailingError;
      else
         outStatus = (strategyError != "" ? strategyError : (filterError != "" ? filterError : "Perfil invalido."));
      return m_configInputsValid;
     }

   void                       ValidateConfigScalarInputs(const bool editable,
                                                        const string profileForMagicCheck,
                                                        bool &lotValid,
                                                        double &parsedLot,
                                                        bool &slippageValid,
                                                        int &parsedSlippage,
                                                        bool &slValid,
                                                        int &parsedSL,
                                                        bool &tpValid,
                                                        int &parsedTP,
                                                        bool &magicValid,
                                                        int &parsedMagic,
                                                        bool &magicUnique,
                                                        string &magicConflictProfile)
     {
      lotValid = false;
      parsedLot = 0.0;
      slippageValid = false;
      parsedSlippage = 0;
      slValid = false;
      parsedSL = 0;
      tpValid = false;
      parsedTP = 0;
      magicValid = false;
      parsedMagic = 0;
      magicUnique = false;
      magicConflictProfile = "";

      string lotText = (editable && m_configRiskCreated) ? FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit))
                                                         : FusionNormalizeDecimalText(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      if(FusionIsDecimalText(lotText, false))
        {
         parsedLot = StringToDouble(lotText);
         lotValid = (parsedLot > 0.0);
         if(lotValid && m_snapshot.symbolSpec.volumeMin > 0.0)
            lotValid = (parsedLot >= (m_snapshot.symbolSpec.volumeMin - 0.0000001));
         if(lotValid && m_snapshot.symbolSpec.volumeMax > 0.0)
            lotValid = (parsedLot <= (m_snapshot.symbolSpec.volumeMax + 0.0000001));
         if(lotValid)
            lotValid = FusionIsVolumeAligned(parsedLot, m_snapshot.symbolSpec);
        }

      string slippageText = (editable && m_configRiskCreated) ? FusionTrimCopy(LiveEditText(m_cfgRiskSlippageEdit))
                                                              : IntegerToString(m_draftSettings.slippagePoints);
      if(FusionIsIntegerText(slippageText, true))
        {
         parsedSlippage = (int)StringToInteger(slippageText);
         slippageValid = (parsedSlippage >= 0 && parsedSlippage <= 100000);
        }

      string slText = (editable && m_configRiskCreated) ? FusionTrimCopy(LiveEditText(m_cfgRiskSLEdit))
                                                        : IntegerToString(m_draftSettings.fixedSLPoints);
      if(FusionIsIntegerText(slText, true))
        {
         parsedSL = (int)StringToInteger(slText);
         slValid = (parsedSL >= 0 && parsedSL <= 100000);
        }

      string tpText = (editable && m_configRiskCreated) ? FusionTrimCopy(LiveEditText(m_cfgRiskTPEdit))
                                                        : IntegerToString(m_draftSettings.fixedTPPoints);
      if(FusionIsIntegerText(tpText, true))
        {
         parsedTP = (int)StringToInteger(tpText);
         tpValid = (parsedTP >= 0 && parsedTP <= 100000);
        }

      if(editable)
         magicValid = ParsedConfigMagicNumber(parsedMagic);
      else
        {
         parsedMagic = m_draftSettings.magicNumber;
         magicValid = (parsedMagic > 0);
        }

      if(magicValid && editable)
        {
         if(ProfileEditMode())
            magicUnique = true;
         else
            magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);
        }
      else
         magicUnique = magicValid;
     }

   void                       ApplyConfigScalarStyles(const bool editable,
                                                      const bool lotValid,
                                                      const bool slippageValid,
                                                      const bool slValid,
                                                      const bool tpValid,
                                                      const bool magicValid,
                                                      const bool magicUnique)
     {
      if(m_configRiskCreated)
        {
         FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, editable);
         m_cfgRiskLotLbl.Color(!editable ? FUSION_CLR_MUTED : (lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         FusionApplyEditStyle(m_cfgRiskSlippageEdit, slippageValid, editable);
         m_cfgRiskSlippageLbl.Color(!editable ? FUSION_CLR_MUTED : (slippageValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         ApplyRiskLotFooter(lotValid, slippageValid, editable);
         FusionApplyEditStyle(m_cfgRiskSLEdit, slValid, editable);
         m_cfgRiskSLLbl.Color(!editable ? FUSION_CLR_MUTED : (slValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         FusionApplyEditStyle(m_cfgRiskTPEdit, tpValid, editable);
         m_cfgRiskTPLbl.Color(!editable ? FUSION_CLR_MUTED : (tpValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(m_configSystemCreated)
        {
         FusionApplyEditStyle(m_cfgSystemMagicEdit, magicValid && magicUnique, editable);
         m_cfgSystemMagicLbl.Color(!editable ? FUSION_CLR_MUTED : ((magicValid && magicUnique) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         FusionApplyToggleButtonStyle(m_cfgSystemDebugBtn, m_draftSettings.debugLogs, editable);
         m_cfgSystemDebugLbl.Color(!editable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgSystemFoot1.Color(FUSION_CLR_MUTED);
         m_cfgSystemFoot2.Color(FUSION_CLR_MUTED);
         m_cfgSystemFoot3.Color(FUSION_CLR_MUTED);
        }
     }

   void                       ValidateConfigSections(SEASettings &outSettings,
                                                     const bool editable,
                                                     bool &protectionValid,
                                                     string &protectionError,
                                                     bool &strategyValid,
                                                     string &strategyError,
                                                     bool &filterValid,
                                                     string &filterError)
     {
      protectionValid = true;
      protectionError = "";
      strategyValid = true;
      strategyError = "";
      filterValid = true;
      filterError = "";

      if(m_configProtectionCreated)
        {
         if(editable)
            protectionValid = ValidateProtectionSettings(outSettings, editable, protectionError);
         else
            ValidateProtectionStyleOnly(outSettings);
        }

      if(editable)
         strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);
      else
         ValidateStrategyPanelsStyleOnly(outSettings);

      if(editable)
         filterValid = ValidateFilterPanels(outSettings, editable, filterError);
      else
         ValidateFilterPanelsStyleOnly(outSettings);
     }

   void                       CommitValidConfigDraft(SEASettings &outSettings,
                                                      const bool editable,
                                                      const double parsedLot,
                                                      const int parsedSlippage,
                                                      const int parsedSL,
                                                      const int parsedTP,
                                                      const int parsedMagic)
     {
      if(!m_configInputsValid || !editable)
         return;

      outSettings.fixedLot = parsedLot;
      outSettings.slippagePoints = parsedSlippage;
      outSettings.fixedSLPoints = parsedSL;
      outSettings.fixedTPPoints = parsedTP;
      outSettings.magicNumber = parsedMagic;
      m_draftSettings = outSettings;
     }

#include "UIPanelConfigStatus.mqh"

   bool                       BuildPendingSettings(SEASettings &outSettings,string &outProfileName,string &outStatus,const string targetProfileName="")
     {
      outSettings = m_draftSettings;
      outProfileName = DraftProfileName();
      string profileForMagicCheck = (targetProfileName == "") ? outProfileName : targetProfileName;

      bool profileValid = !FusionIsBlank(outProfileName);
      bool editable = CanEditActiveProfile();
      SyncHeaderProfile(profileValid ? outProfileName : "");

      if(!m_configTabCreated)
         return BuildPendingSettingsWithoutConfigTab(outSettings, profileValid, editable, profileForMagicCheck, outStatus);

      bool lotValid = false;
      bool slippageValid = false;
      bool slValid = false;
      bool tpValid = false;
      bool protectionValid = true;
      bool strategyValid = true;
      bool filterValid = true;
      bool partialValid = true;
      bool beValid = true;
      bool trailingValid = true;
      bool magicValid = false;
      bool magicUnique = false;
      string magicConflictProfile = "";
      string protectionError = "";
      string strategyError = "";
      string filterError = "";
      string sltpError = "";
      string partialError = "";
      string beError = "";
      string trailingError = "";
      double parsedLot = 0.0;
      int parsedSlippage = 0;
      int parsedSL = 0;
      int parsedTP = 0;
      int parsedMagic = 0;

      ValidateConfigScalarInputs(editable,
                                 profileForMagicCheck,
                                 lotValid,
                                 parsedLot,
                                 slippageValid,
                                 parsedSlippage,
                                 slValid,
                                 parsedSL,
                                 tpValid,
                                 parsedTP,
                                 magicValid,
                                 parsedMagic,
                                 magicUnique,
                                 magicConflictProfile);
      ApplyConfigScalarStyles(editable, lotValid, slippageValid, slValid, tpValid, magicValid, magicUnique);
      if(lotValid)
         outSettings.fixedLot = parsedLot;
      if(slippageValid)
         outSettings.slippagePoints = parsedSlippage;
      if(slValid)
         outSettings.fixedSLPoints = parsedSL;
      if(tpValid)
         outSettings.fixedTPPoints = parsedTP;
      if(magicValid)
         outSettings.magicNumber = parsedMagic;
      bool sltpValid = ValidateRiskSLTPSettings(outSettings,
                                                slValid,
                                                parsedSL,
                                                tpValid,
                                                parsedTP,
                                                editable,
                                                sltpError);
      ValidateConfigSections(outSettings,
                             editable,
                             protectionValid,
                             protectionError,
                             strategyValid,
                             strategyError,
                             filterValid,
                             filterError);
      partialValid = ValidateRiskPartialSettings(outSettings, editable, partialError);
      beValid = ValidateRiskBreakevenSettings(outSettings, editable, beError);
      trailingValid = ValidateRiskTrailingSettings(outSettings, editable, trailingError);

      m_cfgRiskValid = (lotValid && slippageValid && sltpValid && partialValid && beValid && trailingValid);
      m_cfgRiskLotValid = (lotValid && slippageValid);
      m_cfgRiskLotError = !slippageValid ? "Slippage invalido. Use 0 a 100000 pontos." : "";
      m_cfgRiskSLTPValid = sltpValid;
      m_cfgRiskSLTPError = sltpError;
      m_cfgRiskPartialValid = partialValid;
      m_cfgRiskPartialError = partialError;
      m_cfgRiskBEValid = beValid;
      m_cfgRiskBEError = beError;
      m_cfgRiskTrailingValid = trailingValid;
      m_cfgRiskTrailingError = trailingError;
      m_cfgProtectionValid = protectionValid;
      m_cfgSystemValid = (magicValid && magicUnique);
      m_configInputsValid = profileValid && lotValid && slippageValid && sltpValid && partialValid && beValid && trailingValid && protectionValid && strategyValid && filterValid && magicValid && magicUnique;
      CommitValidConfigDraft(outSettings, editable, parsedLot, parsedSlippage, parsedSL, parsedTP, parsedMagic);
      ApplyStrategyStatus(strategyValid, strategyError);
      ApplyFilterStatus(filterValid, filterError);

      bool dirty = HasPendingChanges();
      bool configStatusValid = profileValid && lotValid && slippageValid && sltpValid && partialValid && beValid && trailingValid && protectionValid && magicValid && magicUnique;
      ApplyConfigStatus(configStatusValid,
                        profileValid,
                        lotValid,
                        slippageValid,
                        slValid,
                        tpValid,
                        magicValid,
                        magicUnique,
                        magicConflictProfile,
                        dirty,
                        outStatus);
      return m_configInputsValid;
     }

#endif
