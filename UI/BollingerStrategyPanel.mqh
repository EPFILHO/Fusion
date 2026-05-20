#ifndef __FUSION_BOLLINGER_STRATEGY_PANEL_MQH__
#define __FUSION_BOLLINGER_STRATEGY_PANEL_MQH__

#include "StrategyPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"
#include "DecimalEditField.mqh"

#define FUSION_BB_COMBO_ZORDER_BASE 3600
#define FUSION_BB_COMBO_ZORDER_STEP 10

class CBollingerStrategyPanel : public CStrategyPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CIntegerEditField      m_priority;
   CIntegerEditField      m_period;
   CTimeframeComboField   m_timeframe;
   CDecimalEditField      m_deviation;
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
      long zorder = FUSION_BB_COMBO_ZORDER_BASE;
      m_timeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_BB_COMBO_ZORDER_STEP;
      m_price.RaiseRuntimeObjects(zorder); zorder += FUSION_BB_COMBO_ZORDER_STEP;
      m_mode.RaiseRuntimeObjects(zorder); zorder += FUSION_BB_COMBO_ZORDER_STEP;
      m_exitMode.RaiseRuntimeObjects(zorder);
     }

   bool              PeriodValid(const int value) const
     {
      return (value > 0 && value <= 1000);
     }

   bool              DeviationValid(const double value) const
     {
      return (value > 0.0 && value <= 10.0);
     }

   string            EntryHint(const ENUM_BB_SIGNAL_MODE mode) const
     {
      switch(mode)
        {
         case BB_SIGNAL_REBOUND:
            return "Entrada: toca/fura por pavio e fecha dentro (BUY inf/SELL sup).";
         case BB_SIGNAL_BREAKOUT:
            return "Entrada: BUY fecha acima da superior; SELL abaixo da inferior.";
         default:
            return "Entrada FFFD: anterior fecha fora; ultimo fecha dentro.";
        }
     }

   string            ExitHint(const ENUM_EXIT_MODE exitMode) const
     {
      switch(exitMode)
        {
         case EXIT_TP_SL:
            return "Saida: somente pelo TP/SL configurado.";
         case EXIT_REVERSE_SIGNAL:
            return "VM: fecha e vira quando surgir sinal contrario da Bollinger.";
         default:
            return "Saida: fecha quando surgir sinal contrario da Bollinger.";
        }
     }

   string            RiskHint(const ENUM_BB_SIGNAL_MODE mode,const ENUM_EXIT_MODE exitMode) const
     {
      if(mode == BB_SIGNAL_BREAKOUT && exitMode == EXIT_REVERSE_SIGNAL)
         return "Agressivo: repete enquanto fechar fora; VM aumenta giro.";
      if(mode == BB_SIGNAL_BREAKOUT)
         return "Agressivo: pode repetir entrada enquanto fechar fora.";
      if(exitMode == EXIT_REVERSE_SIGNAL)
         return "Use com cautela; reversao imediata aumenta o giro.";
      return "Reversao por bandas pede filtro de tendencia.";
     }

   void              SyncGuidance(const SEASettings &settings,const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      string risk = RiskHint(settings.bbMode, settings.bbExitMode);

      m_entryHint.Text(EntryHint(settings.bbMode));
      m_entryHint.Color(textColor);
      m_exitHint.Text(ExitHint(settings.bbExitMode));
      m_exitHint.Color(textColor);
      m_riskHint.Text(risk);
      m_riskHint.Color((risk == "") ? textColor : FUSION_CLR_WARN);
     }

public:
   string            GetTitle(void) const { return "Bollinger"; }
   string            GetButtonName(void) const { return "bb"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Strategy_bb_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "Bollinger", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Sinais: FFFD, Toque/Rejeicao ou Rompimento.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_priority.Create(parent, chartId, subwin, prefix + "priority", "Prioridade", x1 + 206, y1 + 60, x1 + 280, y1 + 78, x1 + 292, y1 + 56, x1 + 392, y1 + 80, 6))
         return false;

      if(!m_period.Create(parent, chartId, subwin, prefix + "period", "Periodo", x1, y1 + 112, x1 + 88, y1 + 130, x1 + 92, y1 + 108, x1 + 192, y1 + 132, 20))
         return false;
      if(!m_timeframe.Create(parent, chartId, subwin, prefix + "tf", "Timeframe", x1 + 206, y1 + 112, x1 + 280, y1 + 130, x1 + 292, y1 + 108, x1 + 392, y1 + 132))
         return false;

      if(!m_deviation.Create(parent, chartId, subwin, prefix + "deviation", "Desvio", x1, y1 + 148, x1 + 88, y1 + 166, x1 + 92, y1 + 144, x1 + 192, y1 + 168, 2.0, 2))
         return false;
      if(!m_price.Create(parent, chartId, subwin, prefix + "price", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1 + 206, y1 + 148, x1 + 280, y1 + 166, x1 + 292, y1 + 144, x1 + 392, y1 + 168))
         return false;

      if(!m_mode.Create(parent, chartId, subwin, prefix + "mode", "Modo", FUSION_SELECTION_BB_MODE, x1, y1 + 196, x1 + 88, y1 + 214, x1 + 92, y1 + 192, x1 + 232, y1 + 216))
         return false;
      if(!m_exitMode.Create(parent, chartId, subwin, prefix + "exit", "Saida", FUSION_SELECTION_EXIT_MODE, x1 + 252, y1 + 196, x1 + 286, y1 + 214, x1 + 292, y1 + 192, x1 + 432, y1 + 216))
         return false;

      if(!AddText(parent, m_entryHint, prefix + "entry_hint", chartId, subwin, x1, y1 + 246, x2, y1 + 264, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_exitHint, prefix + "exit_hint", chartId, subwin, x1, y1 + 268, x2, y1 + 286, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_riskHint, prefix + "risk_hint", chartId, subwin, x1, y1 + 290, x2, y1 + 308, "", FUSION_CLR_WARN, 8))
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
      m_deviation.Show();
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
      m_deviation.Hide();
      m_price.Hide();
      m_mode.Hide();
      m_exitMode.Hide();
      m_entryHint.Hide();
      m_exitHint.Hide();
      m_riskHint.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.useBollinger, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);

      bool priorityValid = (settings.bbPriority >= 0 && settings.bbPriority <= 1000);
      bool periodValid = PeriodValid(settings.bbPeriod);
      bool deviationValid = DeviationValid(settings.bbDeviation);

      m_priority.Sync(settings.bbPriority, editable, priorityValid);
      m_period.Sync(settings.bbPeriod, editable, periodValid);
      m_timeframe.Sync(settings.bbTimeframe, editable);
      m_deviation.Sync(settings.bbDeviation, editable, deviationValid);
      m_price.Sync((long)settings.bbPrice, editable);
      m_mode.Sync((long)settings.bbMode, editable);
      m_exitMode.Sync((long)settings.bbExitMode, editable);
      SyncGuidance(settings, editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_BB;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_timeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_timeframe.Value();
         if(settings.bbTimeframe == value)
            return false;
         settings.bbTimeframe = value;
         return true;
        }
      if(m_price.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_price.Value();
         if(settings.bbPrice == value)
            return false;
         settings.bbPrice = value;
         return true;
        }
      if(m_mode.Matches(objectName))
        {
         ENUM_BB_SIGNAL_MODE value = (ENUM_BB_SIGNAL_MODE)m_mode.Value();
         if(settings.bbMode == value)
            return false;
         settings.bbMode = value;
         return true;
        }
      if(m_exitMode.Matches(objectName))
        {
         ENUM_EXIT_MODE value = (ENUM_EXIT_MODE)m_exitMode.Value();
         if(settings.bbExitMode == value)
            return false;
         settings.bbExitMode = value;
         return true;
        }
      if(m_priority.Matches(objectName))
        {
         int value = m_priority.Value();
         if(settings.bbPriority == value)
            return false;
         settings.bbPriority = value;
         return true;
        }
      if(m_period.Matches(objectName))
        {
         int value = m_period.Value();
         if(settings.bbPeriod == value)
            return false;
         settings.bbPeriod = value;
         return true;
        }
      if(m_deviation.Matches(objectName))
        {
         double value = m_deviation.Value();
         if(MathAbs(settings.bbDeviation - value) <= 0.0000001)
            return false;
         settings.bbDeviation = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_priority.Matches(objectName) ||
             m_period.Matches(objectName) ||
             m_deviation.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_priority.Matches(objectName))
         m_priority.SanitizeDigits(4);
      else if(m_period.Matches(objectName))
         m_period.SanitizeDigits(4);
      else if(m_deviation.Matches(objectName))
         m_deviation.SanitizeDecimal(2, 2);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      if(editable)
        {
         candidate.bbPriority = m_priority.Value();
         candidate.bbPeriod = m_period.Value();
         candidate.bbTimeframe = m_timeframe.Value();
         candidate.bbDeviation = m_deviation.Value();
         candidate.bbPrice = (ENUM_APPLIED_PRICE)m_price.Value();
         candidate.bbMode = (ENUM_BB_SIGNAL_MODE)m_mode.Value();
         candidate.bbExitMode = (ENUM_EXIT_MODE)m_exitMode.Value();
        }

      bool priorityValid = (candidate.bbPriority >= 0 && candidate.bbPriority <= 1000);
      bool periodValid = PeriodValid(candidate.bbPeriod);
      bool deviationValid = DeviationValid(candidate.bbDeviation);

      m_priority.SetValid(priorityValid, editable);
      m_period.SetValid(periodValid, editable);
      m_deviation.SetValid(deviationValid, editable);

      if(!priorityValid || !periodValid || !deviationValid)
        {
         if(!priorityValid)
            error = "Bollinger: prioridade deve ser 0 a 1000.";
         else if(!periodValid)
            error = "Bollinger: periodo deve ser 1 a 1000.";
         else
            error = "Bollinger: desvio deve ser maior que 0 e ate 10.";
         return false;
        }

      return true;
     }
  };

#endif
