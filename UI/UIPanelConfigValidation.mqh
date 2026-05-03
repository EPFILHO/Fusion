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
            magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);
           }
        }

      string strategyError = "";
      string filterError = "";
      bool strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);
      bool filterValid = ValidateFilterPanels(outSettings, editable, filterError);
      m_cfgRiskValid = (outSettings.fixedLot > 0.0);
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
                                                        bool &magicValid,
                                                        int &parsedMagic,
                                                        bool &magicUnique,
                                                        string &magicConflictProfile)
     {
      lotValid = false;
      parsedLot = 0.0;
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

      if(editable)
         magicValid = ParsedConfigMagicNumber(parsedMagic);
      else
        {
         parsedMagic = m_draftSettings.magicNumber;
         magicValid = (parsedMagic > 0);
        }

      if(magicValid && editable)
         magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);
      else
         magicUnique = magicValid;
     }

   void                       ApplyConfigScalarStyles(const bool editable,
                                                      const bool lotValid,
                                                      const bool magicValid,
                                                      const bool magicUnique)
     {
      if(m_configRiskCreated)
        {
         FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, editable);
         m_cfgRiskLotLbl.Color(!editable ? FUSION_CLR_MUTED : (lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
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
                                                      const int parsedMagic)
     {
      if(!m_configInputsValid || !editable)
         return;

      outSettings.fixedLot = parsedLot;
      outSettings.magicNumber = parsedMagic;
      m_draftSettings = outSettings;
     }

   void                       SetConfigStatus(const string text,const color clr,string &outStatus)
     {
      outStatus = text;
      m_cfgStatusText = text;
      m_cfgStatusColor = clr;
      if(m_configTabCreated)
        {
         m_cfgStatus.Text(text);
         m_cfgStatus.Color(clr);
        }
     }

   void                       RestoreConfigStatus(void)
     {
      if(!m_configTabCreated)
         return;
      m_cfgStatus.Text(m_cfgStatusText);
      m_cfgStatus.Color(m_cfgStatusColor);
     }

   string                     CurrentConfigPageError(const bool lotValid,
                                                     const bool magicValid,
                                                     const bool magicUnique,
                                                     const string magicConflictProfile)
     {
      if(m_configPage == FUSION_CFG_RISK)
        {
         if(!lotValid)
            return "Lote Fixo invalido. Ajuste o volume.";
         return "";
        }

      if(m_configPage == FUSION_CFG_PROTECTION)
        {
         string protectError = ProtectSubtabError(m_protectPage);
         if(protectError != "")
            return protectError;
         return "";
        }

      if(m_configPage == FUSION_CFG_SYSTEM)
        {
         if(!magicValid)
            return "Magic invalido. Informe um numero inteiro positivo.";
         if(!magicUnique)
            return "Magic ja usado pelo perfil " + magicConflictProfile + ".";
         return "";
        }

      return "";
     }

   void                       ApplyConfigStatus(const bool configStatusValid,
                                                 const bool profileValid,
                                                 const bool lotValid,
                                                 const bool magicValid,
                                                 const bool magicUnique,
                                                 const string magicConflictProfile,
                                                 const bool dirty,
                                                 string &outStatus)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: gerenciamento ativo, edicao bloqueada.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar configuracoes.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!configStatusValid)
        {
         if(!profileValid)
            status = "Perfil invalido. Carregue ou crie outro.";
         else
           {
            status = CurrentConfigPageError(lotValid,
                                            magicValid,
                                            magicUnique,
                                            magicConflictProfile);
            if(status == "")
               status = "Corrija subaba(s) em vermelho.";
           }
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.startBlockedReason != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.activeProfileBlockedReason != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(HasProfileTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileEditMode())
        {
         status = "Conclua ou cancele PERFIS.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(dirty && m_configInputsValid)
        {
         status = "Alteracoes pendentes. Salve para aplicar no EA.";
         statusColor = FUSION_CLR_GOOD;
        }
      else if(!m_configInputsValid)
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.started)
        {
         status = "EA em execucao com configuracao salva.";
         statusColor = FUSION_CLR_WARN;
        }
      else
        {
         status = "Configuracoes OK. EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetConfigStatus(status, statusColor, outStatus);
     }

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
      int parsedMagic = 0;

      ValidateConfigScalarInputs(editable,
                                 profileForMagicCheck,
                                 lotValid,
                                 parsedLot,
                                 magicValid,
                                 parsedMagic,
                                 magicUnique,
                                 magicConflictProfile);
      ApplyConfigScalarStyles(editable, lotValid, magicValid, magicUnique);
      ValidateConfigSections(outSettings,
                             editable,
                             protectionValid,
                             protectionError,
                             strategyValid,
                             strategyError,
                             filterValid,
                             filterError);

      m_cfgRiskValid = lotValid;
      m_cfgProtectionValid = protectionValid;
      m_cfgSystemValid = (magicValid && magicUnique);
      m_configInputsValid = profileValid && lotValid && protectionValid && strategyValid && filterValid && magicValid && magicUnique;
      CommitValidConfigDraft(outSettings, editable, parsedLot, parsedMagic);
      ApplyStrategyStatus(strategyValid, strategyError);
      ApplyFilterStatus(filterValid, filterError);

      bool dirty = HasPendingChanges();
      bool configStatusValid = profileValid && lotValid && protectionValid && magicValid && magicUnique;
      ApplyConfigStatus(configStatusValid,
                        profileValid,
                        lotValid,
                        magicValid,
                        magicUnique,
                        magicConflictProfile,
                        dirty,
                        outStatus);
      return m_configInputsValid;
     }

#endif
