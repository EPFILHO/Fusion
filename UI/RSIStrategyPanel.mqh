#ifndef __FUSION_RSI_STRATEGY_PANEL_MQH__
#define __FUSION_RSI_STRATEGY_PANEL_MQH__

#include "StrategyPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"

#define FUSION_RSI_COMBO_ZORDER_BASE 3400
#define FUSION_RSI_COMBO_ZORDER_STEP 10

class CRSIStrategyPanel : public CStrategyPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CIntegerEditField      m_priority;
   CIntegerEditField      m_period;
   CTimeframeComboField   m_timeframe;
   CIntegerEditField      m_oversold;
   CIntegerEditField      m_overbought;
   CIntegerEditField      m_middle;
   CSelectionComboField   m_price;
   CSelectionComboField   m_mode;
   CSelectionComboField   m_exitMode;
   CLabel                 m_entryHint;
   CLabel                 m_exitHint;
   CLabel                 m_riskHint;

   bool              AddText(CFusionPanel *parent,CLabel &label,const string name,const long chartId,const int subwin,
                             const int x1,const int y1,const int x2,const int y2,const string text,const color clr,const int size=8)
     {
      if(!label.Create(chartId, name, subwin, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return parent.AddControl(label);
     }

   void              RaiseCombos(void)
     {
      long zorder = FUSION_RSI_COMBO_ZORDER_BASE;
      m_timeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_RSI_COMBO_ZORDER_STEP;
      m_price.RaiseRuntimeObjects(zorder); zorder += FUSION_RSI_COMBO_ZORDER_STEP;
      m_mode.RaiseRuntimeObjects(zorder); zorder += FUSION_RSI_COMBO_ZORDER_STEP;
      m_exitMode.RaiseRuntimeObjects(zorder);
     }

   bool              IsLevelInRange(const int value) const
     {
      return (value >= 0 && value <= 100);
     }

   bool              UsesZoneLevels(const ENUM_RSI_SIGNAL_MODE mode) const
     {
      return (mode == RSI_SIGNAL_CROSSOVER || mode == RSI_SIGNAL_ZONE);
     }

   bool              UsesMiddleLevel(const ENUM_RSI_SIGNAL_MODE mode,const ENUM_RSI_EXIT_MODE exitMode) const
     {
      return (mode == RSI_SIGNAL_MIDDLE || exitMode == RSI_EXIT_MIDDLE_TARGET);
     }

   bool              InvalidMiddleExitCombo(const ENUM_RSI_SIGNAL_MODE mode,const ENUM_RSI_EXIT_MODE exitMode) const
     {
      return (mode == RSI_SIGNAL_MIDDLE && exitMode == RSI_EXIT_MIDDLE_TARGET);
     }

   bool              MiddleTargetOrderValid(const SEASettings &settings) const
     {
      if(settings.rsiExitMode != RSI_EXIT_MIDDLE_TARGET || !UsesZoneLevels(settings.rsiMode))
         return true;
      return (settings.rsiOversold < settings.rsiMiddle &&
              settings.rsiMiddle < settings.rsiOverbought);
     }

   bool              ZoneLevelsValid(const SEASettings &settings) const
     {
      return (IsLevelInRange(settings.rsiOversold) &&
              IsLevelInRange(settings.rsiOverbought) &&
              settings.rsiOversold < settings.rsiOverbought);
     }

   string            EntryHint(const ENUM_RSI_SIGNAL_MODE mode) const
     {
      switch(mode)
        {
         case RSI_SIGNAL_ZONE:
            return "Entrada: BUY dentro da sobrevenda; SELL dentro da sobrecompra.";
         case RSI_SIGNAL_MIDDLE:
            return "Entrada: BUY cruzando a media para cima; SELL para baixo.";
         default:
            return "Entrada: BUY ao sair da sobrevenda; SELL ao sair da sobrecompra.";
        }
     }

   string            ExitHint(const ENUM_RSI_SIGNAL_MODE signalMode,const ENUM_RSI_EXIT_MODE exitMode) const
     {
      switch(exitMode)
        {
         case RSI_EXIT_TP_SL:
            return "Saida: somente pelo TP/SL configurado.";
         case RSI_EXIT_REVERSE_SIGNAL:
            if(signalMode == RSI_SIGNAL_CROSSOVER)
               return "VM: fecha e vira so ao sair da zona oposta.";
            if(signalMode == RSI_SIGNAL_ZONE)
               return "VM: fecha e vira ao entrar no extremo contrario.";
            return "VM: fecha e vira no cruzamento contrario da media.";
         case RSI_EXIT_MIDDLE_TARGET:
            return "Saida: fecha quando RSI tocar/cruzar a linha media.";
         default:
            if(signalMode == RSI_SIGNAL_CROSSOVER)
               return "Saida: fecha so ao sair da zona oposta.";
            if(signalMode == RSI_SIGNAL_ZONE)
               return "Saida: fecha ao entrar no extremo contrario.";
            return "Saida: fecha no cruzamento contrario da media.";
        }
     }

   string            RiskHint(const ENUM_RSI_SIGNAL_MODE mode,const ENUM_RSI_EXIT_MODE exitMode) const
     {
      if(InvalidMiddleExitCombo(mode, exitMode))
         return "Bloqueado: entrada e saida usam a mesma linha.";
      if(mode == RSI_SIGNAL_CROSSOVER &&
         (exitMode == RSI_EXIT_OPPOSITE_SIGNAL || exitMode == RSI_EXIT_REVERSE_SIGNAL))
         return "Observacao: espera o ciclo ate a zona oposta.";
      if(mode == RSI_SIGNAL_ZONE && exitMode == RSI_EXIT_REVERSE_SIGNAL)
         return "Use com cautela; modo agressivo e reversao imediata.";
      if(mode == RSI_SIGNAL_ZONE)
         return "Use com cautela; considere filtro de tendencia.";
      if(exitMode == RSI_EXIT_REVERSE_SIGNAL)
         return "Use com cautela; reversao imediata aumenta o giro.";
      return "";
     }

   void              SyncGuidance(const SEASettings &settings,const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      string risk = RiskHint(settings.rsiMode, settings.rsiExitMode);

      m_entryHint.Text(EntryHint(settings.rsiMode));
      m_entryHint.Color(textColor);
      m_exitHint.Text(ExitHint(settings.rsiMode, settings.rsiExitMode));
      m_exitHint.Color(textColor);
      m_riskHint.Text(risk);
      m_riskHint.Color((risk == "") ? textColor : FUSION_CLR_WARN);
     }

public:
   string            GetTitle(void) const { return "RSI"; }
   string            GetButtonName(void) const { return "rsi"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Strategy_rsi_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "RSI", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Sinais: Saida da Zona, Dentro da Zona ou Cruz. Media.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_priority.Create(parent, chartId, subwin, prefix + "priority", "Prioridade", x1 + 206, y1 + 60, x1 + 280, y1 + 78, x1 + 292, y1 + 56, x1 + 392, y1 + 80, 8))
         return false;

      if(!m_period.Create(parent, chartId, subwin, prefix + "period", "Periodo", x1, y1 + 112, x1 + 88, y1 + 130, x1 + 92, y1 + 108, x1 + 192, y1 + 132, 14))
         return false;
      if(!m_timeframe.Create(parent, chartId, subwin, prefix + "tf", "Timeframe", x1 + 206, y1 + 112, x1 + 280, y1 + 130, x1 + 292, y1 + 108, x1 + 392, y1 + 132))
         return false;

      if(!m_oversold.Create(parent, chartId, subwin, prefix + "oversold", "Sobrevenda", x1, y1 + 148, x1 + 88, y1 + 166, x1 + 92, y1 + 144, x1 + 192, y1 + 168, 30))
         return false;
      if(!m_overbought.Create(parent, chartId, subwin, prefix + "overbought", "Sobrecompra", x1 + 206, y1 + 148, x1 + 280, y1 + 166, x1 + 292, y1 + 144, x1 + 392, y1 + 168, 70))
         return false;

      if(!m_middle.Create(parent, chartId, subwin, prefix + "middle", "Linha media", x1, y1 + 184, x1 + 88, y1 + 202, x1 + 92, y1 + 180, x1 + 192, y1 + 204, 50))
         return false;
      if(!m_price.Create(parent, chartId, subwin, prefix + "price", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1 + 206, y1 + 184, x1 + 280, y1 + 202, x1 + 292, y1 + 180, x1 + 392, y1 + 204))
         return false;

      if(!m_mode.Create(parent, chartId, subwin, prefix + "mode", "Modo", FUSION_SELECTION_RSI_MODE, x1, y1 + 232, x1 + 88, y1 + 250, x1 + 92, y1 + 228, x1 + 232, y1 + 252))
         return false;
      if(!m_exitMode.Create(parent, chartId, subwin, prefix + "exit", "Saida", FUSION_SELECTION_RSI_EXIT_MODE, x1 + 252, y1 + 232, x1 + 286, y1 + 250, x1 + 292, y1 + 228, x1 + 432, y1 + 252))
         return false;

      if(!AddText(parent, m_entryHint, prefix + "entry_hint", chartId, subwin, x1, y1 + 282, x2, y1 + 300, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_exitHint, prefix + "exit_hint", chartId, subwin, x1, y1 + 304, x2, y1 + 322, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_riskHint, prefix + "risk_hint", chartId, subwin, x1, y1 + 326, x2, y1 + 344, "", FUSION_CLR_WARN, 8))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_priority.Show();
      m_period.Show();
      m_timeframe.Show();
      m_oversold.Show();
      m_overbought.Show();
      m_middle.Show();
      m_price.Show();
      m_mode.Show();
      m_exitMode.Show();
      m_entryHint.Show();
      m_exitHint.Show();
      m_riskHint.Show();

      RaiseCombos();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_priority.Hide();
      m_period.Hide();
      m_timeframe.Hide();
      m_oversold.Hide();
      m_overbought.Hide();
      m_middle.Hide();
      m_price.Hide();
      m_mode.Hide();
      m_exitMode.Hide();
      m_entryHint.Hide();
      m_exitHint.Hide();
      m_riskHint.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.useRSI, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);

      bool priorityValid = (settings.rsiPriority >= 0 && settings.rsiPriority <= 1000);
      bool periodValid = (settings.rsiPeriod > 0 && settings.rsiPeriod <= 1000);
      bool zoneMode = UsesZoneLevels(settings.rsiMode);
      bool middleMode = UsesMiddleLevel(settings.rsiMode, settings.rsiExitMode);
      bool zoneLevelsValid = ZoneLevelsValid(settings);
      bool middleValid = IsLevelInRange(settings.rsiMiddle);
      bool middleTargetOrderValid = MiddleTargetOrderValid(settings);

      m_priority.Sync(settings.rsiPriority, editable, priorityValid);
      m_period.Sync(settings.rsiPeriod, editable, periodValid);
      m_timeframe.Sync(settings.rsiTimeframe, editable);
      m_oversold.Sync(settings.rsiOversold, editable && zoneMode, zoneLevelsValid && middleTargetOrderValid);
      m_overbought.Sync(settings.rsiOverbought, editable && zoneMode, zoneLevelsValid && middleTargetOrderValid);
      m_middle.Sync(settings.rsiMiddle, editable && middleMode, middleValid && middleTargetOrderValid);
      m_price.Sync((long)settings.rsiPrice, editable);
      m_mode.Sync((long)settings.rsiMode, editable);
      m_exitMode.Sync((long)settings.rsiExitMode, editable);
      SyncGuidance(settings, editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_RSI;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_timeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_timeframe.Value();
         if(settings.rsiTimeframe == value)
            return false;
         settings.rsiTimeframe = value;
         return true;
        }
      if(m_price.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_price.Value();
         if(settings.rsiPrice == value)
            return false;
         settings.rsiPrice = value;
         return true;
        }
      if(m_mode.Matches(objectName))
        {
         ENUM_RSI_SIGNAL_MODE value = (ENUM_RSI_SIGNAL_MODE)m_mode.Value();
         if(settings.rsiMode == value)
            return false;
         settings.rsiMode = value;
         return true;
        }
      if(m_exitMode.Matches(objectName))
        {
         ENUM_RSI_EXIT_MODE value = (ENUM_RSI_EXIT_MODE)m_exitMode.Value();
         if(settings.rsiExitMode == value)
            return false;
         settings.rsiExitMode = value;
         return true;
        }
      if(m_priority.Matches(objectName))
        {
         int value = m_priority.Value();
         if(settings.rsiPriority == value)
            return false;
         settings.rsiPriority = value;
         return true;
        }
      if(m_period.Matches(objectName))
        {
         int value = m_period.Value();
         if(settings.rsiPeriod == value)
            return false;
         settings.rsiPeriod = value;
         return true;
        }
      if(m_oversold.Matches(objectName))
        {
         int value = m_oversold.Value();
         if(settings.rsiOversold == value)
            return false;
         settings.rsiOversold = value;
         return true;
        }
      if(m_overbought.Matches(objectName))
        {
         int value = m_overbought.Value();
         if(settings.rsiOverbought == value)
            return false;
         settings.rsiOverbought = value;
         return true;
        }
      if(m_middle.Matches(objectName))
        {
         int value = m_middle.Value();
         if(settings.rsiMiddle == value)
            return false;
         settings.rsiMiddle = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_priority.Matches(objectName) ||
             m_period.Matches(objectName) ||
             m_oversold.Matches(objectName) ||
             m_overbought.Matches(objectName) ||
             m_middle.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_priority.Matches(objectName))
         m_priority.SanitizeDigits(4);
      else if(m_period.Matches(objectName))
         m_period.SanitizeDigits(4);
      else if(m_oversold.Matches(objectName))
         m_oversold.SanitizeDigits(3);
      else if(m_overbought.Matches(objectName))
         m_overbought.SanitizeDigits(3);
      else if(m_middle.Matches(objectName))
         m_middle.SanitizeDigits(3);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      if(editable)
        {
         candidate.rsiPriority = m_priority.Value();
         candidate.rsiPeriod = m_period.Value();
         candidate.rsiTimeframe = m_timeframe.Value();
         candidate.rsiOversold = m_oversold.Value();
         candidate.rsiOverbought = m_overbought.Value();
         candidate.rsiMiddle = m_middle.Value();
         candidate.rsiPrice = (ENUM_APPLIED_PRICE)m_price.Value();
         candidate.rsiMode = (ENUM_RSI_SIGNAL_MODE)m_mode.Value();
         candidate.rsiExitMode = (ENUM_RSI_EXIT_MODE)m_exitMode.Value();
        }

      bool priorityValid = (candidate.rsiPriority >= 0 && candidate.rsiPriority <= 1000);
      bool periodValid = (candidate.rsiPeriod > 0 && candidate.rsiPeriod <= 1000);
      bool zoneMode = UsesZoneLevels(candidate.rsiMode);
      bool middleMode = UsesMiddleLevel(candidate.rsiMode, candidate.rsiExitMode);
      bool oversoldInRange = IsLevelInRange(candidate.rsiOversold);
      bool overboughtInRange = IsLevelInRange(candidate.rsiOverbought);
      bool zoneOrderValid = (candidate.rsiOversold < candidate.rsiOverbought);
      bool zoneLevelsValid = (!zoneMode || (oversoldInRange && overboughtInRange && zoneOrderValid));
      bool middleValid = (!middleMode || IsLevelInRange(candidate.rsiMiddle));
      bool middleTargetOrderValid = MiddleTargetOrderValid(candidate);
      bool middleExitComboValid = !InvalidMiddleExitCombo(candidate.rsiMode, candidate.rsiExitMode);

      m_priority.SetValid(priorityValid, editable);
      m_period.SetValid(periodValid, editable);
      m_oversold.SetValid(zoneLevelsValid && middleTargetOrderValid, editable && zoneMode);
      m_overbought.SetValid(zoneLevelsValid && middleTargetOrderValid, editable && zoneMode);
      m_middle.SetValid(middleValid && middleTargetOrderValid, editable && middleMode);

      if(!priorityValid || !periodValid || !zoneLevelsValid || !middleValid || !middleTargetOrderValid || !middleExitComboValid)
        {
         if(!priorityValid)
            error = "RSI: prioridade deve ser 0 a 1000.";
         else if(!periodValid)
            error = "RSI: periodo deve ser 1 a 1000.";
         else if(zoneMode && (!oversoldInRange || !overboughtInRange))
            error = "RSI: niveis devem ser 0 a 100.";
         else if(zoneMode && !zoneOrderValid)
            error = "RSI: sobrevenda < sobrecompra.";
         else if(!middleValid)
            error = "RSI: linha media deve ser 0 a 100.";
         else if(!middleTargetOrderValid)
            error = "RSI: use sobrevenda < media < sobrecompra.";
         else
            error = "RSI: entrada/saida Cruz. Media invalidas.";
         return false;
        }

      return true;
     }
  };

#endif
