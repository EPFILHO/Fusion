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
         magicValid = ParsedDraftMagicNumber(parsedMagic);
         if(magicValid)
           {
            outSettings.magicNumber = parsedMagic;
            magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);
           }
        }

      string strategyError = "";
      bool strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);
      m_cfgRiskValid = (outSettings.fixedLot > 0.0);
      m_cfgProtectionValid = true;
      m_cfgSystemValid = (magicValid && magicUnique && outSettings.magicNumber > 0);
      m_configInputsValid = (profileValid &&
                             m_cfgRiskValid &&
                             magicValid &&
                             magicUnique &&
                             outSettings.magicNumber > 0 &&
                             strategyValid);
      if(m_configInputsValid && editable)
         m_draftSettings = outSettings;

      if(m_configInputsValid)
         outStatus = "Configuracao pronta.";
      else if(!magicValid)
         outStatus = "Magic invalido. Informe um numero inteiro positivo.";
      else if(!magicUnique)
         outStatus = "Magic ja usado pelo perfil " + magicConflictProfile + ".";
      else
         outStatus = (strategyError != "" ? strategyError : "Perfil invalido.");
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
         magicValid = ParsedDraftMagicNumber(parsedMagic);
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
                                                     string &strategyError)
     {
      protectionValid = true;
      protectionError = "";
      strategyValid = true;
      strategyError = "";

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

   void                       ApplyConfigStatus(const bool configInputsValid,
                                                 const bool profileValid,
                                                 const bool lotValid,
                                                 const bool magicValid,
                                                 const bool magicUnique,
                                                 const string magicConflictProfile,
                                                 const string protectionError,
                                                 const string strategyError,
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
      else if(!configInputsValid)
        {
         if(!profileValid)
            status = "Perfil invalido. Carregue ou crie outro.";
         else if(!lotValid)
            status = "Lote Fixo invalido. Ajuste o volume.";
         else if(protectionError != "")
            status = protectionError;
         else if(!magicValid)
            status = "Magic invalido. Informe um numero inteiro positivo.";
         else if(!magicUnique)
            status = "Magic ja usado pelo perfil " + magicConflictProfile + ".";
         else if(strategyError != "")
            status = strategyError;
         else
            status = "Corrija os campos em rosa antes de salvar.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.startBlockedReason != "")
        {
         status = "Perfil em uso por outra instancia. Carregue outro.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.activeProfileBlockedReason != "")
        {
         status = "Perfil carregado em outra instancia. Carregue outro.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(dirty)
        {
         status = "Alteracoes pendentes. Salve para aplicar no EA.";
         statusColor = FUSION_CLR_GOOD;
        }
      else if(m_snapshot.started)
        {
         status = "EA em execucao com configuracao salva.";
         statusColor = FUSION_CLR_WARN;
        }
      else
        {
         status = "Configuracao salva e pronta para iniciar.";
         statusColor = FUSION_CLR_MUTED;
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
      bool magicValid = false;
      bool magicUnique = false;
      string magicConflictProfile = "";
      string protectionError = "";
      string strategyError = "";
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
                             strategyError);

      m_cfgRiskValid = lotValid;
      m_cfgProtectionValid = protectionValid;
      m_cfgSystemValid = (magicValid && magicUnique);
      m_configInputsValid = profileValid && lotValid && protectionValid && strategyValid && magicValid && magicUnique;
      CommitValidConfigDraft(outSettings, editable, parsedLot, parsedMagic);

      bool dirty = HasPendingChanges();
      ApplyConfigStatus(m_configInputsValid,
                        profileValid,
                        lotValid,
                        magicValid,
                        magicUnique,
                        magicConflictProfile,
                        protectionError,
                        strategyError,
                        dirty,
                        outStatus);
      return m_configInputsValid;
     }

#endif
