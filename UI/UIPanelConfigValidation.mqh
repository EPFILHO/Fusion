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
      bool strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);
      bool filterValid = ValidateFilterPanels(outSettings, editable, filterError);
      bool slValid = (outSettings.fixedSLPoints >= 0 && outSettings.fixedSLPoints <= 100000);
      bool tpValid = (outSettings.fixedTPPoints >= 0 && outSettings.fixedTPPoints <= 100000);
      m_cfgRiskValid = (outSettings.fixedLot > 0.0 && slValid && tpValid);
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
      else
         outStatus = (strategyError != "" ? strategyError : (filterError != "" ? filterError : "Perfil invalido."));
      return m_configInputsValid;
     }

   void                       ValidateConfigScalarInputs(const bool editable,
                                                        const string profileForMagicCheck,
                                                        bool &lotValid,
                                                        double &parsedLot,
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
                                                      const bool slValid,
                                                      const bool tpValid,
                                                      const bool magicValid,
                                                      const bool magicUnique)
     {
      if(m_configRiskCreated)
        {
         FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, editable);
         m_cfgRiskLotLbl.Color(!editable ? FUSION_CLR_MUTED : (lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         FusionApplyEditStyle(m_cfgRiskSLEdit, slValid, editable);
         m_cfgRiskSLLbl.Color(!editable ? FUSION_CLR_MUTED : (slValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         FusionApplyEditStyle(m_cfgRiskTPEdit, tpValid, editable);
         m_cfgRiskTPLbl.Color(!editable ? FUSION_CLR_MUTED : (tpValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(m_configSystemCreated)
        {
         FusionApplyEditStyle(m_cfgSystemMagicEdit, magicValid && magicUnique, editable);
         m_cfgSystemMagicLbl.Color(!editable ? FUSION_CLR_MUTED : ((magicValid && magicUnique) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
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
                                                      const int parsedSL,
                                                      const int parsedTP,
                                                      const int parsedMagic)
     {
      if(!m_configInputsValid || !editable)
         return;

      outSettings.fixedLot = parsedLot;
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
      bool slValid = false;
      bool tpValid = false;
      bool protectionValid = true;
      bool strategyValid = true;
      bool filterValid = true;
      bool magicValid = false;
      bool magicUnique = false;
      string magicConflictProfile = "";
      string protectionError = "";
      string strategyError = "";
      string filterError = "";
      double parsedLot = 0.0;
      int parsedSL = 0;
      int parsedTP = 0;
      int parsedMagic = 0;

      ValidateConfigScalarInputs(editable,
                                 profileForMagicCheck,
                                 lotValid,
                                 parsedLot,
                                 slValid,
                                 parsedSL,
                                 tpValid,
                                 parsedTP,
                                 magicValid,
                                 parsedMagic,
                                 magicUnique,
                                 magicConflictProfile);
      ApplyConfigScalarStyles(editable, lotValid, slValid, tpValid, magicValid, magicUnique);
      ValidateConfigSections(outSettings,
                             editable,
                             protectionValid,
                             protectionError,
                             strategyValid,
                             strategyError,
                             filterValid,
                             filterError);

      m_cfgRiskValid = (lotValid && slValid && tpValid);
      m_cfgProtectionValid = protectionValid;
      m_cfgSystemValid = (magicValid && magicUnique);
      m_configInputsValid = profileValid && lotValid && slValid && tpValid && protectionValid && strategyValid && filterValid && magicValid && magicUnique;
      CommitValidConfigDraft(outSettings, editable, parsedLot, parsedSL, parsedTP, parsedMagic);
      ApplyStrategyStatus(strategyValid, strategyError);
      ApplyFilterStatus(filterValid, filterError);

      bool dirty = HasPendingChanges();
      bool configStatusValid = profileValid && lotValid && slValid && tpValid && protectionValid && magicValid && magicUnique;
      ApplyConfigStatus(configStatusValid,
                        profileValid,
                        lotValid,
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
