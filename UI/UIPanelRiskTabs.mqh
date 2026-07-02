   ENUM_FUSION_RISK_PAGE      m_riskPage;
   CButton                    m_riskTabs[FUSION_RISK_COUNT];
   CPanel                     m_riskTabsSeparator;
   CPanel                     m_riskContentFrame;

   CLabel                     m_cfgRiskLotHdr;
   CLabel                     m_cfgRiskLotDesc;
   CLabel                     m_cfgRiskLotLbl;
   CEdit                      m_cfgRiskLotEdit;
   CLabel                     m_cfgRiskSlippageLbl;
   CEdit                      m_cfgRiskSlippageEdit;
   CLabel                     m_cfgRiskLotFoot1;
   CLabel                     m_cfgRiskLotFoot2;

   CLabel                     m_cfgRiskSLTPHdr;
   CLabel                     m_cfgRiskSLTPDesc;
   CLabel                     m_cfgRiskSLLbl;
   CEdit                      m_cfgRiskSLEdit;
   CLabel                     m_cfgRiskTPLbl;
   CEdit                      m_cfgRiskTPEdit;
   CLabel                     m_cfgRiskSLCompLbl;
   CButton                    m_cfgRiskSLCompBtn;
   CLabel                     m_cfgRiskTPCompLbl;
   CButton                    m_cfgRiskTPCompBtn;
   CLabel                     m_cfgRiskSLTPFoot1;
   CLabel                     m_cfgRiskSLTPFoot2;
   CLabel                     m_cfgRiskSLTPFoot3;

   CLabel                     m_cfgRiskPartialHdr;
   CLabel                     m_cfgRiskPartialDesc;
   CLabel                     m_cfgRiskTP1Hdr;
   CLabel                     m_cfgRiskTP1EnabledLbl;
   CButton                    m_cfgRiskTP1EnabledBtn;
   CLabel                     m_cfgRiskTP1PercentLbl;
   CEdit                      m_cfgRiskTP1PercentEdit;
   CLabel                     m_cfgRiskTP1DistanceLbl;
   CEdit                      m_cfgRiskTP1DistanceEdit;
   CLabel                     m_cfgRiskTP2Hdr;
   CLabel                     m_cfgRiskTP2EnabledLbl;
   CButton                    m_cfgRiskTP2EnabledBtn;
   CLabel                     m_cfgRiskTP2PercentLbl;
   CEdit                      m_cfgRiskTP2PercentEdit;
   CLabel                     m_cfgRiskTP2DistanceLbl;
   CEdit                      m_cfgRiskTP2DistanceEdit;
   CLabel                     m_cfgRiskFreeTPLbl;
   CButton                    m_cfgRiskFreeTPBtn;
   CLabel                     m_cfgRiskPartialFoot1;
   CLabel                     m_cfgRiskPartialFoot2;
   CLabel                     m_cfgRiskPartialFoot3;
   CLabel                     m_cfgRiskBreakevenHdr;
   CLabel                     m_cfgRiskBreakevenDesc;
   CLabel                     m_cfgRiskBreakevenEnabledLbl;
   CButton                    m_cfgRiskBreakevenEnabledBtn;
   CLabel                     m_cfgRiskBreakevenTriggerLbl;
   CEdit                      m_cfgRiskBreakevenTriggerEdit;
   CLabel                     m_cfgRiskBreakevenOffsetLbl;
   CEdit                      m_cfgRiskBreakevenOffsetEdit;
   CLabel                     m_cfgRiskBreakevenFoot1;
   CLabel                     m_cfgRiskBreakevenFoot2;
   CLabel                     m_cfgRiskTrailingHdr;
   CLabel                     m_cfgRiskTrailingDesc;
   CLabel                     m_cfgRiskTrailingEnabledLbl;
   CButton                    m_cfgRiskTrailingEnabledBtn;
   CLabel                     m_cfgRiskTrailingStartLbl;
   CEdit                      m_cfgRiskTrailingStartEdit;
   CLabel                     m_cfgRiskTrailingStepLbl;
   CEdit                      m_cfgRiskTrailingStepEdit;
   CLabel                     m_cfgRiskTrailingFoot1;
   CLabel                     m_cfgRiskTrailingFoot2;

   bool                       RiskSubtabHasError(const ENUM_FUSION_RISK_PAGE page) const
     {
      if(page == FUSION_RISK_LOT)
         return !m_cfgRiskLotValid;
      if(page == FUSION_RISK_SLTP)
         return (!m_cfgRiskSLTPValid || m_snapshot.entryBlockIsRiskStops);
      if(page == FUSION_RISK_PARTIAL)
         return !m_cfgRiskPartialValid;
      if(page == FUSION_RISK_BREAKEVEN)
         return !m_cfgRiskBEValid;
      if(page == FUSION_RISK_TRAILING)
         return !m_cfgRiskTrailingValid;
      return false;
     }

   bool                       RiskDecimalEditValue(CEdit &edit,double &value)
     {
      value = 0.0;
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      if(!FusionIsDecimalText(text, true))
         return false;
      value = StringToDouble(text);
      return (value >= 0.0);
     }

   bool                       RiskIntegerEditValue(CEdit &edit,int &value)
     {
      value = 0;
      string text = FusionTrimCopy(LiveEditText(edit));
      if(!FusionIsIntegerText(text, true))
         return false;
      value = (int)StringToInteger(text);
      return (value >= 0);
     }

   void                       ApplyRiskLotFooter(const bool lotValid,const bool slippageValid,const bool editable)
     {
      if(!m_configRiskCreated)
         return;

      if(!lotValid)
        {
         m_cfgRiskLotFoot1.Text("Lote Fixo invalido para o ativo atual.");
         m_cfgRiskLotFoot1.Color(FUSION_CLR_BAD);
        }
      else if(!slippageValid)
        {
         m_cfgRiskLotFoot1.Text("Slippage invalido. Use 0 a 100000 pontos.");
         m_cfgRiskLotFoot1.Color(FUSION_CLR_BAD);
        }
      else
        {
         m_cfgRiskLotFoot1.Text("Slippage e tolerancia de execucao, nao garantia de preco.");
         m_cfgRiskLotFoot1.Color(FUSION_CLR_MUTED);
        }

      m_cfgRiskLotFoot2.Text("Use 0 para enviar sem desvio; valido de 0 a 100000 pontos.");
      m_cfgRiskLotFoot2.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED_TXT);
     }

   bool                       RiskDistanceMeetsStopsLevel(const int points) const
     {
      if(points <= 0)
         return true;

      int stopsLevel = m_snapshot.symbolSpec.stopsLevel;
      if(stopsLevel <= 0)
         return true;

      return (points >= stopsLevel);
     }

   string                     CurrentSpreadPointsText(void) const
     {
      if(m_snapshot.symbolSpec.symbol == "" || m_snapshot.symbolSpec.point <= 0.0)
         return "--";

      MqlTick tick;
      if(!SymbolInfoTick(m_snapshot.symbolSpec.symbol, tick) ||
         tick.bid <= 0.0 || tick.ask <= 0.0 || tick.ask < tick.bid)
         return "--";

      long spreadPoints = (long)MathRound((tick.ask - tick.bid) / m_snapshot.symbolSpec.point);
      return StringFormat("%I64d", spreadPoints);
     }

   void                       ApplyRiskSLTPFooter(const SEASettings &settings,const bool valid,const string error)
     {
      if(!m_configRiskCreated)
         return;

      if(m_snapshot.entryBlockIsRiskStops)
        {
         m_cfgRiskSLTPFoot1.Text(m_snapshot.entryBlockReason);
         m_cfgRiskSLTPFoot1.Color(FUSION_CLR_BAD);
         m_cfgRiskSLTPFoot2.Text(m_snapshot.entryBlockDetail);
         m_cfgRiskSLTPFoot2.Color(FUSION_CLR_BAD);
         m_cfgRiskSLTPFoot3.Text("Ajuste distancia/compensacao ou use 0 para desligar.");
         m_cfgRiskSLTPFoot3.Color(FUSION_CLR_BAD);
         return;
        }

      if(!valid && error != "")
        {
         m_cfgRiskSLTPFoot1.Text(error);
         m_cfgRiskSLTPFoot1.Color(FUSION_CLR_BAD);
        }
      else if(settings.fixedSLPoints <= 0)
        {
         m_cfgRiskSLTPFoot1.Text("ATENCAO: operar sem SL e ARRISCADO.");
         m_cfgRiskSLTPFoot1.Color(FUSION_CLR_BAD);
        }
      else
        {
         m_cfgRiskSLTPFoot1.Text("Informe SL/TP em pontos do MT5; 0 desliga.");
         m_cfgRiskSLTPFoot1.Color(FUSION_CLR_MUTED);
        }

      m_cfgRiskSLTPFoot2.Text("Use a mesma contagem exibida pela regua do grafico.");
      m_cfgRiskSLTPFoot2.Color(FUSION_CLR_MUTED);
      string spreadPrefix = "Spread atual: " + CurrentSpreadPointsText() + " pts. ";
      if(settings.compensateSLSpread && settings.compensateTPSpread)
         m_cfgRiskSLTPFoot3.Text(spreadPrefix + "SL soma; TP subtrai.");
      else if(settings.compensateSLSpread)
         m_cfgRiskSLTPFoot3.Text(spreadPrefix + "SL ON soma; risco aumenta.");
      else if(settings.compensateTPSpread)
         m_cfgRiskSLTPFoot3.Text(spreadPrefix + "TP ON subtrai; alvo diminui.");
      else
         m_cfgRiskSLTPFoot3.Text(spreadPrefix + "EA valida o minimo da corretora.");
      m_cfgRiskSLTPFoot3.Color(FUSION_CLR_MUTED);
     }

   bool                       ValidateRiskSLTPSettings(const SEASettings &settings,
                                                       const bool slBaseValid,
                                                       const int slPoints,
                                                       const bool tpBaseValid,
                                                       const int tpPoints,
                                                       const bool editable,
                                                       string &error)
     {
      error = "";

      bool slStopsValid = (slBaseValid && RiskDistanceMeetsStopsLevel(slPoints));
      bool tpStopsValid = (tpBaseValid && RiskDistanceMeetsStopsLevel(tpPoints));
      bool slValid = (slBaseValid && slStopsValid);
      bool tpValid = (tpBaseValid && tpStopsValid);
      bool valid = (slValid && tpValid);

      if(!slBaseValid)
         error = "SL Fixo invalido. Use 0 a 100000 pontos.";
      else if(!tpBaseValid)
         error = "TP Fixo invalido. Use 0 a 100000 pontos.";
      else if(!slStopsValid)
         error = "SL Fixo abaixo do minimo do ativo: " + IntegerToString(m_snapshot.symbolSpec.stopsLevel) + " pts.";
      else if(!tpStopsValid)
         error = "TP Fixo abaixo do minimo do ativo: " + IntegerToString(m_snapshot.symbolSpec.stopsLevel) + " pts.";

      if(m_configRiskCreated)
        {
         FusionApplyEditStyle(m_cfgRiskSLEdit, slValid, editable);
         FusionApplyEditStyle(m_cfgRiskTPEdit, tpValid, editable);
         FusionApplyToggleButtonStyle(m_cfgRiskSLCompBtn, settings.compensateSLSpread, editable);
         FusionApplyToggleButtonStyle(m_cfgRiskTPCompBtn, settings.compensateTPSpread, editable);
         m_cfgRiskSLLbl.Color(!editable ? FUSION_CLR_MUTED : (slValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTPLbl.Color(!editable ? FUSION_CLR_MUTED : (tpValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskSLCompLbl.Color(!editable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgRiskTPCompLbl.Color(!editable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         ApplyRiskSLTPFooter(settings, valid, error);
        }

      return valid;
     }

   double                     RiskNormalizeVolumeToSpec(const double volume,const SSymbolSpec &spec) const
     {
      if(spec.volumeStep <= 0.0)
         return volume;

      double normalized = MathRound(volume / spec.volumeStep) * spec.volumeStep;
      normalized = MathMax(spec.volumeMin, normalized);
      normalized = MathMin(spec.volumeMax, normalized);

      double temp = spec.volumeStep;
      int digits = 0;
      while(digits < 8 && MathAbs(temp - MathRound(temp)) > 0.0000001)
        {
         temp *= 10.0;
         digits++;
        }

      return NormalizeDouble(normalized, digits);
     }

   bool                       RiskPartialVolumePlanValid(const double fixedLot,
                                                         const bool tp1Active,
                                                         const double tp1Percent,
                                                         const bool tp2Active,
                                                         const double tp2Percent,
                                                         string &volumeError) const
     {
      volumeError = "";
      if(!tp1Active)
         return true;

      SSymbolSpec spec = m_snapshot.symbolSpec;
      if(spec.volumeMin <= 0.0 || spec.volumeStep <= 0.0 || spec.volumeMax <= 0.0)
        {
         volumeError = "Especificacao de lote do ativo indisponivel.";
         return false;
        }

      double entryVolume = RiskNormalizeVolumeToSpec(fixedLot, spec);
      if(entryVolume < spec.volumeMin || entryVolume > spec.volumeMax)
        {
         volumeError = "Lote invalido para validar TP Parcial.";
         return false;
        }

      double tp1Volume = RiskNormalizeVolumeToSpec(entryVolume * (tp1Percent / 100.0), spec);
      if(tp1Volume < spec.volumeMin || tp1Volume + 0.0000001 >= entryVolume)
        {
         volumeError = "TP1 precisa fechar lote parcial valido e deixar saldo.";
         return false;
        }

      double reserved = tp1Volume;
      if(tp2Active)
        {
         double tp2Volume = RiskNormalizeVolumeToSpec(entryVolume * (tp2Percent / 100.0), spec);
         if(tp2Volume < spec.volumeMin)
           {
            volumeError = "TP2 precisa fechar lote parcial valido.";
            return false;
           }
         reserved += tp2Volume;
        }

      if((entryVolume - reserved) + 0.0000001 < spec.volumeMin)
        {
         volumeError = "TP parcial precisa deixar lote minimo aberto.";
         return false;
        }

      return true;
     }

   void                       ApplyRiskPartialFooter(const SEASettings &settings,
                                                     const bool tp1Active,
                                                     const bool tp2Active,
                                                     const double tp1Percent,
                                                     const double tp2Percent,
                                                     const bool percentValuesValid,
                                                     const bool partialVolumeValid,
                                                     const string volumeError,
                                                     const bool freeTPRequiresBase)
     {
      if(!m_configRiskCreated)
         return;

      if(!tp1Active)
        {
         m_cfgRiskPartialFoot1.Text("TP1 ON ativa o TP parcial; TP2 depende dele.");
         m_cfgRiskPartialFoot2.Text("Volumes sao ajustados ao lote minimo e passo do ativo.");
         m_cfgRiskPartialFoot3.Text("Ative TP1 para ver o plano real de volumes.");
         m_cfgRiskPartialFoot1.Color(FUSION_CLR_MUTED);
         m_cfgRiskPartialFoot2.Color(FUSION_CLR_MUTED);
         m_cfgRiskPartialFoot3.Color(FUSION_CLR_MUTED);
         return;
        }

      if(!percentValuesValid)
        {
         m_cfgRiskPartialFoot1.Text("Informe percentuais validos para calcular o plano real.");
         m_cfgRiskPartialFoot2.Text("Volumes sao ajustados ao lote minimo e passo do ativo.");
         m_cfgRiskPartialFoot3.Text("Ajuste os % ate o plano ficar valido.");
         m_cfgRiskPartialFoot1.Color(FUSION_CLR_BAD);
         m_cfgRiskPartialFoot2.Color(FUSION_CLR_MUTED);
         m_cfgRiskPartialFoot3.Color(FUSION_CLR_MUTED);
         return;
        }

      SSymbolSpec spec = m_snapshot.symbolSpec;
      if(spec.volumeMin <= 0.0 || spec.volumeStep <= 0.0 || spec.volumeMax <= 0.0)
        {
         m_cfgRiskPartialFoot1.Text("Especificacao de lote do ativo indisponivel.");
         m_cfgRiskPartialFoot2.Text("Nao foi possivel calcular o plano real.");
         m_cfgRiskPartialFoot3.Text("Confirme se o ativo esta sincronizado no MT5.");
         m_cfgRiskPartialFoot1.Color(FUSION_CLR_BAD);
         m_cfgRiskPartialFoot2.Color(FUSION_CLR_MUTED);
         m_cfgRiskPartialFoot3.Color(FUSION_CLR_MUTED);
         return;
        }

      double entryVolume = RiskNormalizeVolumeToSpec(settings.fixedLot, spec);
      double tp1Volume = RiskNormalizeVolumeToSpec(entryVolume * (tp1Percent / 100.0), spec);
      double tp2Volume = tp2Active ? RiskNormalizeVolumeToSpec(entryVolume * (tp2Percent / 100.0), spec) : 0.0;
      double remaining = entryVolume - tp1Volume - tp2Volume;

      string planText = "Plano real: TP1 " + FusionFormatVolume(tp1Volume, spec);
      if(tp2Active)
         planText += " | TP2 " + FusionFormatVolume(tp2Volume, spec);
      planText += " | resta " + FusionFormatVolume(remaining, spec) + ".";

      m_cfgRiskPartialFoot1.Text(planText);
      m_cfgRiskPartialFoot2.Text("Min " + FusionFormatVolume(spec.volumeMin, spec) +
                                 " | passo " + FusionFormatVolume(spec.volumeStep, spec) +
                                 " | lote base " + FusionFormatVolume(entryVolume, spec) + ".");
      if(settings.freeFinalTP)
         m_cfgRiskPartialFoot3.Text(freeTPRequiresBase ? "TP Final Livre: restante sai pelo trailing." : "TP Final Livre exige trailing ativo.");
      else if(!partialVolumeValid && volumeError != "")
         m_cfgRiskPartialFoot3.Text(volumeError);
      else
         m_cfgRiskPartialFoot3.Text("Ajuste os % ate o plano real ficar valido.");

      m_cfgRiskPartialFoot1.Color(partialVolumeValid ? FUSION_CLR_MUTED : FUSION_CLR_BAD);
      m_cfgRiskPartialFoot2.Color(FUSION_CLR_MUTED);
      m_cfgRiskPartialFoot3.Color((partialVolumeValid && freeTPRequiresBase) ? FUSION_CLR_MUTED : FUSION_CLR_BAD);
     }

   bool                       ValidateRiskPartialSettings(SEASettings &settings,const bool editable,string &error)
     {
      error = "";

      double tp1Percent = settings.tp1.percent;
      double tp2Percent = settings.tp2.percent;
      int tp1Distance = settings.tp1.distancePoints;
      int tp2Distance = settings.tp2.distancePoints;
      bool tp1PercentParsed = true;
      bool tp2PercentParsed = true;
      bool tp1DistanceParsed = true;
      bool tp2DistanceParsed = true;

      if(editable && m_configRiskCreated)
        {
         tp1PercentParsed = RiskDecimalEditValue(m_cfgRiskTP1PercentEdit, tp1Percent);
         tp2PercentParsed = RiskDecimalEditValue(m_cfgRiskTP2PercentEdit, tp2Percent);
         tp1DistanceParsed = RiskIntegerEditValue(m_cfgRiskTP1DistanceEdit, tp1Distance);
         tp2DistanceParsed = RiskIntegerEditValue(m_cfgRiskTP2DistanceEdit, tp2Distance);
         if(tp1PercentParsed)
            settings.tp1.percent = tp1Percent;
         if(tp2PercentParsed)
            settings.tp2.percent = tp2Percent;
         if(tp1DistanceParsed)
            settings.tp1.distancePoints = tp1Distance;
         if(tp2DistanceParsed)
            settings.tp2.distancePoints = tp2Distance;
        }

      if(!settings.tp1.enabled)
        {
         settings.tp2.enabled = false;
         settings.freeFinalTP = false;
        }
      settings.usePartialTP = settings.tp1.enabled;

      bool partialActive = settings.usePartialTP;
      bool tp1Active = settings.tp1.enabled;
      bool tp2Active = (settings.tp1.enabled && settings.tp2.enabled);
      bool tp1PercentValid = (!tp1Active || (tp1PercentParsed && tp1Percent > 0.0 && tp1Percent <= 100.0));
      bool tp2PercentValid = (!tp2Active || (tp2PercentParsed && tp2Percent > 0.0 && tp2Percent <= 100.0));
      bool tp1DistanceValid = (!tp1Active || (tp1DistanceParsed && tp1Distance > 0));
      bool tp2DistanceValid = (!tp2Active || (tp2DistanceParsed && tp2Distance > 0));
      double activePercent = (tp1Active ? tp1Percent : 0.0) + (tp2Active ? tp2Percent : 0.0);
      bool totalPercentValid = (!partialActive || activePercent <= 100.0 + 0.0000001);
      bool freeTPRequiresBase = (!partialActive || !settings.freeFinalTP ||
                                 (tp1Active && settings.useTrailing));
      string volumeError = "";
      bool partialVolumeValid = RiskPartialVolumePlanValid(settings.fixedLot,
                                                           tp1Active,
                                                           tp1Percent,
                                                           tp2Active,
                                                           tp2Percent,
                                                           volumeError);
      bool percentValuesValid = (tp1PercentParsed && (!tp2Active || tp2PercentParsed));

      bool valid = (tp1PercentValid && tp2PercentValid &&
                    tp1DistanceValid && tp2DistanceValid && totalPercentValid &&
                    freeTPRequiresBase && partialVolumeValid);

      if(m_configRiskCreated)
        {
         bool tp1Editable = editable;
         bool tp2Editable = (editable && settings.tp1.enabled);
         bool freeTPEditable = (editable && settings.tp1.enabled);
         FusionApplyToggleButtonStyle(m_cfgRiskTP1EnabledBtn, settings.tp1.enabled, tp1Editable);
         FusionApplyToggleButtonStyle(m_cfgRiskTP2EnabledBtn, settings.tp2.enabled, tp2Editable);
         FusionApplyToggleButtonStyle(m_cfgRiskFreeTPBtn, settings.freeFinalTP, freeTPEditable);
         FusionApplyEditStyle(m_cfgRiskTP1PercentEdit, tp1PercentValid && totalPercentValid && partialVolumeValid, tp1Editable && tp1Active);
         FusionApplyEditStyle(m_cfgRiskTP1DistanceEdit, tp1DistanceValid, tp1Editable && tp1Active);
         FusionApplyEditStyle(m_cfgRiskTP2PercentEdit, tp2PercentValid && totalPercentValid && partialVolumeValid, tp2Editable && tp2Active);
         FusionApplyEditStyle(m_cfgRiskTP2DistanceEdit, tp2DistanceValid, tp2Editable && tp2Active);
         m_cfgRiskTP1EnabledLbl.Color(!tp1Editable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgRiskTP2EnabledLbl.Color(!tp2Editable ? FUSION_CLR_MUTED : FUSION_CLR_LABEL);
         m_cfgRiskTP1PercentLbl.Color(!tp1Editable || !tp1Active ? FUSION_CLR_MUTED : ((tp1PercentValid && totalPercentValid && partialVolumeValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP1DistanceLbl.Color(!tp1Editable || !tp1Active ? FUSION_CLR_MUTED : (tp1DistanceValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP2PercentLbl.Color(!tp2Editable || !tp2Active ? FUSION_CLR_MUTED : ((tp2PercentValid && totalPercentValid && partialVolumeValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTP2DistanceLbl.Color(!tp2Editable || !tp2Active ? FUSION_CLR_MUTED : (tp2DistanceValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskFreeTPLbl.Color(!freeTPEditable ? FUSION_CLR_MUTED : (freeTPRequiresBase ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         ApplyRiskPartialFooter(settings,
                                tp1Active,
                                tp2Active,
                                tp1Percent,
                                tp2Percent,
                                percentValuesValid,
                                partialVolumeValid,
                                volumeError,
                                freeTPRequiresBase);
        }

      if(valid)
         return true;

      if(!tp1PercentValid)
         error = "TP1 % deve ser maior que 0 e ate 100.";
      else if(!tp2PercentValid)
         error = "TP2 % deve ser maior que 0 e ate 100.";
      else if(!tp1DistanceValid)
         error = "TP1 Dist deve ser maior que 0.";
      else if(!tp2DistanceValid)
         error = "TP2 Dist deve ser maior que 0.";
      else if(!totalPercentValid)
         error = "Soma de TP1 % e TP2 % deve ser ate 100.";
      else if(!freeTPRequiresBase)
         error = "TP Final Livre exige TP1 e Trailing ativos.";
      else if(!partialVolumeValid)
         error = volumeError;
      else
         error = "Corrija o TP Parcial.";

      return false;
     }

   bool                       ValidateRiskBreakevenSettings(SEASettings &settings,const bool editable,string &error)
     {
      error = "";

      int triggerPoints = settings.breakevenTriggerPoints;
      int offsetPoints = settings.breakevenOffsetPoints;
      bool triggerParsed = true;
      bool offsetParsed = true;

      if(editable && m_configRiskCreated)
        {
         triggerParsed = RiskIntegerEditValue(m_cfgRiskBreakevenTriggerEdit, triggerPoints);
         offsetParsed = RiskIntegerEditValue(m_cfgRiskBreakevenOffsetEdit, offsetPoints);
         if(triggerParsed)
            settings.breakevenTriggerPoints = triggerPoints;
         if(offsetParsed)
            settings.breakevenOffsetPoints = offsetPoints;
        }

      bool triggerValid = (!settings.useBreakeven || (triggerParsed && triggerPoints > 0 && triggerPoints <= 100000));
      bool offsetValid = (!settings.useBreakeven || (offsetParsed && offsetPoints >= 0 && offsetPoints <= 100000));
      bool orderValid = (!settings.useBreakeven || !triggerValid || !offsetValid || offsetPoints <= triggerPoints);
      bool valid = (triggerValid && offsetValid && orderValid);

      if(m_configRiskCreated)
        {
         bool beEditable = (editable && settings.useBreakeven);
         FusionApplyToggleButtonStyle(m_cfgRiskBreakevenEnabledBtn, settings.useBreakeven, editable);
         FusionApplyEditStyle(m_cfgRiskBreakevenTriggerEdit, triggerValid && orderValid, beEditable);
         FusionApplyEditStyle(m_cfgRiskBreakevenOffsetEdit, offsetValid && orderValid, beEditable);
         m_cfgRiskBreakevenEnabledLbl.Color(!editable ? FUSION_CLR_MUTED : (valid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskBreakevenTriggerLbl.Color(!beEditable ? FUSION_CLR_MUTED : ((triggerValid && orderValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskBreakevenOffsetLbl.Color(!beEditable ? FUSION_CLR_MUTED : ((offsetValid && orderValid) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(valid)
         return true;

      if(!triggerValid)
         error = "BE Gatilho deve ser maior que 0 e ate 100000.";
      else if(!offsetValid)
         error = "BE Offset deve ficar entre 0 e 100000.";
      else if(!orderValid)
         error = "BE Offset nao pode ser maior que o gatilho.";
      else
         error = "Corrija o Breakeven.";

      return false;
     }

   bool                       ValidateRiskTrailingSettings(SEASettings &settings,const bool editable,string &error)
     {
      error = "";

      int startPoints = settings.trailingStartPoints;
      int stepPoints = settings.trailingStepPoints;
      bool startParsed = true;
      bool stepParsed = true;

      if(editable && m_configRiskCreated)
        {
         startParsed = RiskIntegerEditValue(m_cfgRiskTrailingStartEdit, startPoints);
         stepParsed = RiskIntegerEditValue(m_cfgRiskTrailingStepEdit, stepPoints);
         if(startParsed)
            settings.trailingStartPoints = startPoints;
         if(stepParsed)
            settings.trailingStepPoints = stepPoints;
        }

      bool startValid = (!settings.useTrailing || (startParsed && startPoints > 0 && startPoints <= 100000));
      bool stepValid = (!settings.useTrailing || (stepParsed && stepPoints > 0 && stepPoints <= 100000));
      bool valid = (startValid && stepValid);

      if(m_configRiskCreated)
        {
         bool trailingEditable = (editable && settings.useTrailing);
         FusionApplyToggleButtonStyle(m_cfgRiskTrailingEnabledBtn, settings.useTrailing, editable);
         FusionApplyEditStyle(m_cfgRiskTrailingStartEdit, startValid, trailingEditable);
         FusionApplyEditStyle(m_cfgRiskTrailingStepEdit, stepValid, trailingEditable);
         m_cfgRiskTrailingEnabledLbl.Color(!editable ? FUSION_CLR_MUTED : (valid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTrailingStartLbl.Color(!trailingEditable ? FUSION_CLR_MUTED : (startValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
         m_cfgRiskTrailingStepLbl.Color(!trailingEditable ? FUSION_CLR_MUTED : (stepValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
        }

      if(valid)
         return true;

      if(!startValid)
         error = "Trailing Inicio deve ser maior que 0 e ate 100000.";
      else if(!stepValid)
         error = "Trailing Passo deve ser maior que 0 e ate 100000.";
      else
         error = "Corrija o Trailing.";

      return false;
     }

   void                       SyncRiskControls(void)
     {
      if(!m_configRiskCreated)
         return;

      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSlippageEdit.Text(IntegerToString(m_draftSettings.slippagePoints));
      m_cfgRiskSLEdit.Text(IntegerToString(m_draftSettings.fixedSLPoints));
      m_cfgRiskTPEdit.Text(IntegerToString(m_draftSettings.fixedTPPoints));
      m_cfgRiskTP1PercentEdit.Text(DoubleToString(m_draftSettings.tp1.percent, 2));
      m_cfgRiskTP1DistanceEdit.Text(IntegerToString(m_draftSettings.tp1.distancePoints));
      m_cfgRiskTP2PercentEdit.Text(DoubleToString(m_draftSettings.tp2.percent, 2));
      m_cfgRiskTP2DistanceEdit.Text(IntegerToString(m_draftSettings.tp2.distancePoints));
      m_cfgRiskBreakevenTriggerEdit.Text(IntegerToString(m_draftSettings.breakevenTriggerPoints));
      m_cfgRiskBreakevenOffsetEdit.Text(IntegerToString(m_draftSettings.breakevenOffsetPoints));
      m_cfgRiskTrailingStartEdit.Text(IntegerToString(m_draftSettings.trailingStartPoints));
      m_cfgRiskTrailingStepEdit.Text(IntegerToString(m_draftSettings.trailingStepPoints));
     }

   void                       ApplyRiskTabStyles(void)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
        {
         ENUM_FUSION_RISK_PAGE page = (ENUM_FUSION_RISK_PAGE)tabIndex;
         bool runtimeStopsError = (page == FUSION_RISK_SLTP &&
                                   m_snapshot.entryBlockIsRiskStops);
         if(runtimeStopsError)
            FusionApplyActionButtonStyle(m_riskTabs[tabIndex], FUSION_CLR_BAD, true);
         else if(tabIndex == (int)m_riskPage)
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], true);
         else if(RiskSubtabHasError(page))
            FusionApplyActionButtonStyle(m_riskTabs[tabIndex], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_riskTabs[tabIndex], false);
        }
     }

   bool                       BuildConfigRiskPage(void)
     {
      string pageNames[FUSION_RISK_COUNT] = {"LOTE", "SL/TP", "TP PARCIAL", "BREAKEVEN", "TRAILING"};
      int tabWidth = 104;
      int tabGap = 2;
      int tabX = 18;
      for(int i = 0; i < FUSION_RISK_COUNT; ++i)
        {
         if(!AddButton(m_riskTabs[i], "Fusion_risk_tab_" + IntegerToString(i), tabX, 140, tabX + tabWidth, 164, pageNames[i], FUSION_CLR_PANEL))
            return false;
         tabX += tabWidth + tabGap;
        }
      if(!AddPanel(m_riskTabsSeparator,
                   "Fusion_risk_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   168,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   170,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_riskContentFrame,
                   "Fusion_risk_content_frame",
                   FUSION_PANEL_MARGIN,
                   174,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;

      if(!AddLabel(m_cfgRiskLotHdr, "Fusion_cfg_risk_lot_hdr", 22, 188, 260, 206, "Tamanho do Lote", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotDesc, "Fusion_cfg_risk_lot_desc", 22, 214, 520, 232, "Define o volume base usado nas novas entradas.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 250, 160, 268, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 200, 248, 310, 272, "0.10"))
         return false;
      if(!AddLabel(m_cfgRiskSlippageLbl, "Fusion_cfg_slippage_lbl", 22, 288, 160, 306, "Slippage (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSlippageEdit, "Fusion_cfg_slippage_edit", 200, 286, 310, 310, "20"))
         return false;
      if(!AddLabel(m_cfgRiskLotFoot1, "Fusion_cfg_risk_lot_foot_1", 22, 424, 540, 442, "Slippage e tolerancia de execucao, nao garantia de preco.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskLotFoot2, "Fusion_cfg_risk_lot_foot_2", 22, 448, 540, 466, "Use 0 para enviar sem desvio; valido de 0 a 100000 pontos.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskSLTPHdr, "Fusion_cfg_risk_sltp_hdr", 22, 188, 260, 206, "Stop Loss e Take Profit", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskSLTPDesc, "Fusion_cfg_risk_sltp_desc", 22, 214, 520, 232, "Distancias fixas aplicadas no envio da ordem.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLLbl, "Fusion_cfg_sl_lbl", 22, 250, 170, 268, "SL Fixo (pts MT5)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSLEdit, "Fusion_cfg_sl_edit", 200, 248, 310, 272, "0"))
         return false;
      if(!AddLabel(m_cfgRiskTPLbl, "Fusion_cfg_tp_lbl", 22, 288, 170, 306, "TP Fixo (pts MT5)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTPEdit, "Fusion_cfg_tp_edit", 200, 286, 310, 310, "0"))
         return false;
      if(!AddLabel(m_cfgRiskSLCompLbl, "Fusion_cfg_sl_comp_lbl", 22, 326, 190, 344, "Compensar Spread SL", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskSLCompBtn, "Fusion_cfg_sl_comp_btn", 200, 324, 310, 348, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTPCompLbl, "Fusion_cfg_tp_comp_lbl", 22, 364, 190, 382, "Compensar Spread TP", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTPCompBtn, "Fusion_cfg_tp_comp_btn", 200, 362, 310, 386, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot1, "Fusion_cfg_risk_sltp_foot_1", 22, 424, 540, 442, "Informe SL/TP em pontos do MT5; 0 desliga.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot2, "Fusion_cfg_risk_sltp_foot_2", 22, 448, 540, 466, "Use a mesma contagem exibida pela regua do grafico.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskSLTPFoot3, "Fusion_cfg_risk_sltp_foot_3", 22, 472, 540, 490, "Spread atual: -- pts. EA valida o minimo da corretora.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskPartialHdr, "Fusion_cfg_risk_partial_hdr", 22, 188, 260, 206, "TP Parcial", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskPartialDesc, "Fusion_cfg_risk_partial_desc", 22, 214, 520, 232, "Fecha partes da posicao em alvos globais antes do TP final.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskTP1Hdr, "Fusion_cfg_risk_tp1_hdr", 22, 250, 180, 268, "TP1", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP1EnabledLbl, "Fusion_cfg_risk_tp1_enabled_lbl", 22, 280, 100, 298, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP1EnabledBtn, "Fusion_cfg_risk_tp1_enabled_btn", 112, 278, 202, 302, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP1PercentLbl, "Fusion_cfg_risk_tp1_pct_lbl", 22, 318, 100, 336, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1PercentEdit, "Fusion_cfg_risk_tp1_pct_edit", 112, 316, 202, 340, "50.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP1DistanceLbl, "Fusion_cfg_risk_tp1_dist_lbl", 22, 356, 100, 374, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP1DistanceEdit, "Fusion_cfg_risk_tp1_dist_edit", 112, 354, 202, 378, "150"))
         return false;

      if(!AddLabel(m_cfgRiskTP2Hdr, "Fusion_cfg_risk_tp2_hdr", 298, 250, 456, 268, "TP2", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTP2EnabledLbl, "Fusion_cfg_risk_tp2_enabled_lbl", 298, 280, 376, 298, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTP2EnabledBtn, "Fusion_cfg_risk_tp2_enabled_btn", 388, 278, 478, 302, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTP2PercentLbl, "Fusion_cfg_risk_tp2_pct_lbl", 298, 318, 376, 336, "Volume %", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2PercentEdit, "Fusion_cfg_risk_tp2_pct_edit", 388, 316, 478, 340, "25.00"))
         return false;
      if(!AddLabel(m_cfgRiskTP2DistanceLbl, "Fusion_cfg_risk_tp2_dist_lbl", 298, 356, 376, 374, "Dist pts", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTP2DistanceEdit, "Fusion_cfg_risk_tp2_dist_edit", 388, 354, 478, 378, "300"))
         return false;
      if(!AddLabel(m_cfgRiskFreeTPLbl, "Fusion_cfg_risk_free_tp_lbl", 22, 432, 110, 450, "TP Final Livre", FUSION_CLR_LABEL, 8))
         return false;
      if(!AddButton(m_cfgRiskFreeTPBtn, "Fusion_cfg_risk_free_tp_btn", 112, 430, 202, 454, "OFF", FUSION_CLR_BAD))
         return false;

      if(!AddLabel(m_cfgRiskPartialFoot1, "Fusion_cfg_risk_partial_foot_1", 22, 484, 520, 502, "TP1 ON ativa o TP parcial; TP2 depende dele.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialFoot2, "Fusion_cfg_risk_partial_foot_2", 22, 508, 520, 526, "TP Final Livre remove o TP final apos o ultimo parcial.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskPartialFoot3, "Fusion_cfg_risk_partial_foot_3", 22, 532, 520, 550, "Requer trailing ativo; o restante passa a sair pelo trailing.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskBreakevenHdr, "Fusion_cfg_risk_be_hdr", 22, 188, 260, 206, "Breakeven", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenDesc, "Fusion_cfg_risk_be_desc", 22, 214, 520, 232, "Ajusta o SL apos a posicao atingir o gatilho em lucro.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenEnabledLbl, "Fusion_cfg_risk_be_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskBreakevenEnabledBtn, "Fusion_cfg_risk_be_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenTriggerLbl, "Fusion_cfg_risk_be_trigger_lbl", 22, 288, 170, 306, "Gatilho (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskBreakevenTriggerEdit, "Fusion_cfg_risk_be_trigger_edit", 200, 286, 310, 310, "120"))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenOffsetLbl, "Fusion_cfg_risk_be_offset_lbl", 22, 326, 170, 344, "Offset (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskBreakevenOffsetEdit, "Fusion_cfg_risk_be_offset_edit", 200, 324, 310, 348, "10"))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenFoot1, "Fusion_cfg_risk_be_foot_1", 22, 462, 520, 480, "BE apenas ajusta o SL da posicao aberta.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskBreakevenFoot2, "Fusion_cfg_risk_be_foot_2", 22, 486, 520, 504, "Offset 0 move o SL para a entrada; offset maior protege lucro.", FUSION_CLR_MUTED, 8))
         return false;

      if(!AddLabel(m_cfgRiskTrailingHdr, "Fusion_cfg_risk_trailing_hdr", 22, 188, 260, 206, "Trailing", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskTrailingDesc, "Fusion_cfg_risk_trailing_desc", 22, 214, 520, 232, "Move o SL acompanhando o preco apos atingir o inicio em lucro.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskTrailingEnabledLbl, "Fusion_cfg_risk_trailing_enabled_lbl", 22, 250, 160, 268, "Ativo", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgRiskTrailingEnabledBtn, "Fusion_cfg_risk_trailing_enabled_btn", 200, 248, 310, 272, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgRiskTrailingStartLbl, "Fusion_cfg_risk_trailing_start_lbl", 22, 288, 170, 306, "Inicio (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTrailingStartEdit, "Fusion_cfg_risk_trailing_start_edit", 200, 286, 310, 310, "150"))
         return false;
      if(!AddLabel(m_cfgRiskTrailingStepLbl, "Fusion_cfg_risk_trailing_step_lbl", 22, 326, 170, 344, "Passo (pts)", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskTrailingStepEdit, "Fusion_cfg_risk_trailing_step_edit", 200, 324, 310, 348, "80"))
         return false;
      if(!AddLabel(m_cfgRiskTrailingFoot1, "Fusion_cfg_risk_trailing_foot_1", 22, 462, 520, 480, "Trailing apenas ajusta o SL da posicao aberta.", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddLabel(m_cfgRiskTrailingFoot2, "Fusion_cfg_risk_trailing_foot_2", 22, 486, 520, 504, "Passo define a distancia entre preco atual e novo SL.", FUSION_CLR_MUTED, 8))
         return false;

      return true;
     }

   void                       SetRiskLotVisible(const bool visible)
     {
      SetVisible(m_cfgRiskLotHdr, visible);
      SetVisible(m_cfgRiskLotDesc, visible);
      SetVisible(m_cfgRiskLotLbl, visible);
      SetVisible(m_cfgRiskLotEdit, visible);
      SetVisible(m_cfgRiskSlippageLbl, visible);
      SetVisible(m_cfgRiskSlippageEdit, visible);
      SetVisible(m_cfgRiskLotFoot1, visible);
      SetVisible(m_cfgRiskLotFoot2, visible);
     }

   void                       SetRiskSLTPVisible(const bool visible)
     {
      SetVisible(m_cfgRiskSLTPHdr, visible);
      SetVisible(m_cfgRiskSLTPDesc, visible);
      SetVisible(m_cfgRiskSLLbl, visible);
      SetVisible(m_cfgRiskSLEdit, visible);
      SetVisible(m_cfgRiskTPLbl, visible);
      SetVisible(m_cfgRiskTPEdit, visible);
      SetVisible(m_cfgRiskSLCompLbl, visible);
      SetVisible(m_cfgRiskSLCompBtn, visible);
      SetVisible(m_cfgRiskTPCompLbl, visible);
      SetVisible(m_cfgRiskTPCompBtn, visible);
      SetVisible(m_cfgRiskSLTPFoot1, visible);
      SetVisible(m_cfgRiskSLTPFoot2, visible);
      SetVisible(m_cfgRiskSLTPFoot3, visible);
     }

   void                       SetRiskPartialVisible(const bool visible)
     {
      SetVisible(m_cfgRiskPartialHdr, visible);
      SetVisible(m_cfgRiskPartialDesc, visible);
      SetVisible(m_cfgRiskTP1Hdr, visible);
      SetVisible(m_cfgRiskTP1EnabledLbl, visible);
      SetVisible(m_cfgRiskTP1EnabledBtn, visible);
      SetVisible(m_cfgRiskTP1PercentLbl, visible);
      SetVisible(m_cfgRiskTP1PercentEdit, visible);
      SetVisible(m_cfgRiskTP1DistanceLbl, visible);
      SetVisible(m_cfgRiskTP1DistanceEdit, visible);
      SetVisible(m_cfgRiskTP2Hdr, visible);
      SetVisible(m_cfgRiskTP2EnabledLbl, visible);
      SetVisible(m_cfgRiskTP2EnabledBtn, visible);
      SetVisible(m_cfgRiskTP2PercentLbl, visible);
      SetVisible(m_cfgRiskTP2PercentEdit, visible);
      SetVisible(m_cfgRiskTP2DistanceLbl, visible);
      SetVisible(m_cfgRiskTP2DistanceEdit, visible);
      SetVisible(m_cfgRiskFreeTPLbl, visible);
      SetVisible(m_cfgRiskFreeTPBtn, visible);
      SetVisible(m_cfgRiskPartialFoot1, visible);
      SetVisible(m_cfgRiskPartialFoot2, visible);
      SetVisible(m_cfgRiskPartialFoot3, visible);
     }

   void                       SetRiskBreakevenVisible(const bool visible)
     {
      SetVisible(m_cfgRiskBreakevenHdr, visible);
      SetVisible(m_cfgRiskBreakevenDesc, visible);
      SetVisible(m_cfgRiskBreakevenEnabledLbl, visible);
      SetVisible(m_cfgRiskBreakevenEnabledBtn, visible);
      SetVisible(m_cfgRiskBreakevenTriggerLbl, visible);
      SetVisible(m_cfgRiskBreakevenTriggerEdit, visible);
      SetVisible(m_cfgRiskBreakevenOffsetLbl, visible);
      SetVisible(m_cfgRiskBreakevenOffsetEdit, visible);
      SetVisible(m_cfgRiskBreakevenFoot1, visible);
      SetVisible(m_cfgRiskBreakevenFoot2, visible);
     }

   void                       SetRiskTrailingVisible(const bool visible)
     {
      SetVisible(m_cfgRiskTrailingHdr, visible);
      SetVisible(m_cfgRiskTrailingDesc, visible);
      SetVisible(m_cfgRiskTrailingEnabledLbl, visible);
      SetVisible(m_cfgRiskTrailingEnabledBtn, visible);
      SetVisible(m_cfgRiskTrailingStartLbl, visible);
      SetVisible(m_cfgRiskTrailingStartEdit, visible);
      SetVisible(m_cfgRiskTrailingStepLbl, visible);
      SetVisible(m_cfgRiskTrailingStepEdit, visible);
      SetVisible(m_cfgRiskTrailingFoot1, visible);
      SetVisible(m_cfgRiskTrailingFoot2, visible);
     }

   void                       SetAllRiskPagesVisible(const bool visible)
     {
      SetRiskLotVisible(visible);
      SetRiskSLTPVisible(visible);
      SetRiskPartialVisible(visible);
      SetRiskBreakevenVisible(visible);
      SetRiskTrailingVisible(visible);
     }

   void                       SetActiveRiskPageVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      if(page == FUSION_RISK_LOT)
         SetRiskLotVisible(visible);
      else if(page == FUSION_RISK_SLTP)
         SetRiskSLTPVisible(visible);
      else if(page == FUSION_RISK_PARTIAL)
         SetRiskPartialVisible(visible);
      else if(page == FUSION_RISK_BREAKEVEN)
         SetRiskBreakevenVisible(visible);
      else if(page == FUSION_RISK_TRAILING)
         SetRiskTrailingVisible(visible);
     }

   void                       SetRiskControlsVisible(const ENUM_FUSION_RISK_PAGE page,const bool visible)
     {
      for(int tabIndex = 0; tabIndex < FUSION_RISK_COUNT; ++tabIndex)
         SetVisible(m_riskTabs[tabIndex], visible);
      SetVisible(m_riskTabsSeparator, visible);
      SetVisible(m_riskContentFrame, visible);

      SetAllRiskPagesVisible(false);

      if(visible)
         SetActiveRiskPageVisible(page, true);
     }

   bool                       EnsureConfigRiskPageCreated(void)
     {
      if(m_configRiskCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configRiskGroup);
      if(!BuildConfigRiskPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configRiskCreated = true;
      SetRiskControlsVisible(m_riskPage, false);
      SyncRiskControls();
      return true;
     }

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
