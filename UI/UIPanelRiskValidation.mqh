#ifndef __FUSION_UI_PANEL_RISK_VALIDATION_MQH__
#define __FUSION_UI_PANEL_RISK_VALIDATION_MQH__

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

#endif
