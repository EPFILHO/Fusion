#ifndef __FUSION_BOLLINGER_FILTER_PANEL_MQH__
#define __FUSION_BOLLINGER_FILTER_PANEL_MQH__

#include "FilterPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"
#include "DecimalEditField.mqh"

#define FUSION_BB_FILTER_COMBO_ZORDER_BASE 4200
#define FUSION_BB_FILTER_COMBO_ZORDER_STEP 10

class CBollingerFilterPanel : public CFilterPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CSelectionComboField   m_mode;
   CIntegerEditField      m_period;
   CTimeframeComboField   m_timeframe;
   CDecimalEditField      m_deviation;
   CSelectionComboField   m_price;
   CIntegerEditField      m_minWidthPoints;
   CDecimalEditField      m_minWidthPercent;
   CLabel                 m_ruleHint;
   CLabel                 m_valueHint;
   CLabel                 m_noteHint;

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
      long zorder = FUSION_BB_FILTER_COMBO_ZORDER_BASE;
      m_mode.RaiseRuntimeObjects(zorder); zorder += FUSION_BB_FILTER_COMBO_ZORDER_STEP;
      m_timeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_BB_FILTER_COMBO_ZORDER_STEP;
      m_price.RaiseRuntimeObjects(zorder);
     }

   bool              ModeValid(const ENUM_BB_FILTER_WIDTH_MODE mode) const
     {
      return (mode == BB_FILTER_WIDTH_ABSOLUTE ||
              mode == BB_FILTER_WIDTH_RELATIVE);
     }

   bool              PeriodValid(const int value) const
     {
      return (value > 0 && value <= 1000);
     }

   bool              DeviationValid(const double value) const
     {
      return (value > 0.0 && value <= 10.0);
     }

   bool              MinPointsValid(const int value) const
     {
      return (value > 0 && value <= 100000);
     }

   bool              MinPercentValid(const double value) const
     {
      return (value > 0.0 && value <= 100.0);
     }

   string            RuleHint(const SEASettings &settings) const
     {
      if(settings.bbFilterMode == BB_FILTER_WIDTH_RELATIVE)
         return "Relativo: mede largura das bandas como % da linha media.";
      return "Absoluto: mede largura das bandas em pontos do simbolo.";
     }

   string            ValueHint(const SEASettings &settings) const
     {
      if(settings.bbFilterMode == BB_FILTER_WIDTH_RELATIVE)
         return "Bloqueia quando largura < " + DoubleToString(settings.bbFilterMinWidthPercent, 2) + "%.";
      return "Bloqueia quando largura < " + IntegerToString(settings.bbFilterMinWidthPoints) + " pts.";
     }

   void              SyncGuidance(const SEASettings &settings,const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      m_ruleHint.Text(RuleHint(settings));
      m_ruleHint.Color(textColor);
      m_valueHint.Text(ValueHint(settings));
      m_valueHint.Color(textColor);
      m_noteHint.Text("Anti-squeeze: nao abre trade; apenas bloqueia sinais.");
      m_noteHint.Color(textColor);
     }

public:
   string            GetTitle(void) const { return "Bollinger Filter"; }
   string            GetButtonName(void) const { return "bb"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Filter_bb_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "Bollinger Filter", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Bloqueia entradas quando as bandas estao estreitas.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_mode.Create(parent, chartId, subwin, prefix + "mode", "Modo", FUSION_SELECTION_BB_FILTER_MODE, x1 + 206, y1 + 60, x1 + 280, y1 + 78, x1 + 292, y1 + 56, x1 + 432, y1 + 80))
         return false;

      if(!m_period.Create(parent, chartId, subwin, prefix + "period", "Periodo", x1, y1 + 112, x1 + 88, y1 + 130, x1 + 92, y1 + 108, x1 + 192, y1 + 132, 20))
         return false;
      if(!m_timeframe.Create(parent, chartId, subwin, prefix + "tf", "Timeframe", x1 + 206, y1 + 112, x1 + 280, y1 + 130, x1 + 292, y1 + 108, x1 + 392, y1 + 132))
         return false;

      if(!m_deviation.Create(parent, chartId, subwin, prefix + "deviation", "Desvio", x1, y1 + 148, x1 + 88, y1 + 166, x1 + 92, y1 + 144, x1 + 192, y1 + 168, 2.0, 2))
         return false;
      if(!m_price.Create(parent, chartId, subwin, prefix + "price", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1 + 206, y1 + 148, x1 + 280, y1 + 166, x1 + 292, y1 + 144, x1 + 392, y1 + 168))
         return false;

      if(!m_minWidthPoints.Create(parent, chartId, subwin, prefix + "min_pts", "Min Pts", x1, y1 + 196, x1 + 88, y1 + 214, x1 + 92, y1 + 192, x1 + 192, y1 + 216, 100))
         return false;
      if(!m_minWidthPercent.Create(parent, chartId, subwin, prefix + "min_pct", "Min %", x1 + 206, y1 + 196, x1 + 280, y1 + 214, x1 + 292, y1 + 192, x1 + 392, y1 + 216, 0.20, 2))
         return false;

      if(!AddText(parent, m_ruleHint, prefix + "rule_hint", chartId, subwin, x1, y1 + 246, x2, y1 + 264, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_valueHint, prefix + "value_hint", chartId, subwin, x1, y1 + 268, x2, y1 + 286, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_noteHint, prefix + "note_hint", chartId, subwin, x1, y1 + 290, x2, y1 + 308, "", FUSION_CLR_MUTED, 8))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_mode.Show();
      m_period.Show();
      m_timeframe.Show();
      m_deviation.Show();
      m_price.Show();
      m_minWidthPoints.Show();
      m_minWidthPercent.Show();
      m_ruleHint.Show();
      m_valueHint.Show();
      m_noteHint.Show();

      RaiseCombos();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_mode.Hide();
      m_period.Hide();
      m_timeframe.Hide();
      m_deviation.Hide();
      m_price.Hide();
      m_minWidthPoints.Hide();
      m_minWidthPercent.Hide();
      m_ruleHint.Hide();
      m_valueHint.Hide();
      m_noteHint.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.bbFilterEnabled, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);

      bool modeValid = ModeValid(settings.bbFilterMode);
      bool periodValid = PeriodValid(settings.bbFilterPeriod);
      bool deviationValid = DeviationValid(settings.bbFilterDeviation);
      bool pointsValid = MinPointsValid(settings.bbFilterMinWidthPoints);
      bool percentValid = MinPercentValid(settings.bbFilterMinWidthPercent);
      bool absoluteMode = (settings.bbFilterMode == BB_FILTER_WIDTH_ABSOLUTE);
      bool relativeMode = (settings.bbFilterMode == BB_FILTER_WIDTH_RELATIVE);

      m_mode.Sync((long)settings.bbFilterMode, editable);
      m_period.Sync(settings.bbFilterPeriod, editable, periodValid);
      m_timeframe.Sync(settings.bbFilterTimeframe, editable);
      m_deviation.Sync(settings.bbFilterDeviation, editable, deviationValid);
      m_price.Sync((long)settings.bbFilterPrice, editable);
      m_minWidthPoints.Sync(settings.bbFilterMinWidthPoints, editable && absoluteMode, !absoluteMode || pointsValid);
      m_minWidthPercent.Sync(settings.bbFilterMinWidthPercent, editable && relativeMode, !relativeMode || percentValid);
      SyncGuidance(settings, editable && modeValid);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_BB_FILTER;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_mode.Matches(objectName))
        {
         ENUM_BB_FILTER_WIDTH_MODE value = (ENUM_BB_FILTER_WIDTH_MODE)m_mode.Value();
         if(settings.bbFilterMode == value)
            return false;
         settings.bbFilterMode = value;
         SyncGuidance(settings, true);
         return true;
        }
      if(m_timeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_timeframe.Value();
         if(settings.bbFilterTimeframe == value)
            return false;
         settings.bbFilterTimeframe = value;
         return true;
        }
      if(m_price.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_price.Value();
         if(settings.bbFilterPrice == value)
            return false;
         settings.bbFilterPrice = value;
         return true;
        }
      if(m_period.Matches(objectName))
        {
         int value = m_period.Value();
         if(settings.bbFilterPeriod == value)
            return false;
         settings.bbFilterPeriod = value;
         return true;
        }
      if(m_deviation.Matches(objectName))
        {
         double value = m_deviation.Value();
         if(MathAbs(settings.bbFilterDeviation - value) <= 0.0000001)
            return false;
         settings.bbFilterDeviation = value;
         return true;
        }
      if(m_minWidthPoints.Matches(objectName))
        {
         int value = m_minWidthPoints.Value();
         if(settings.bbFilterMinWidthPoints == value)
            return false;
         settings.bbFilterMinWidthPoints = value;
         return true;
        }
      if(m_minWidthPercent.Matches(objectName))
        {
         double value = m_minWidthPercent.Value();
         if(MathAbs(settings.bbFilterMinWidthPercent - value) <= 0.0000001)
            return false;
         settings.bbFilterMinWidthPercent = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_period.Matches(objectName) ||
             m_deviation.Matches(objectName) ||
             m_minWidthPoints.Matches(objectName) ||
             m_minWidthPercent.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_period.Matches(objectName))
         m_period.SanitizeRange(20, 1, 1000, 4);
      else if(m_deviation.Matches(objectName))
         m_deviation.SanitizeDecimal(2, 2);
      else if(m_minWidthPoints.Matches(objectName))
         m_minWidthPoints.SanitizeRange(100, 1, 100000, 6);
      else if(m_minWidthPercent.Matches(objectName))
         m_minWidthPercent.SanitizeDecimal(3, 2);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      if(editable)
        {
         candidate.bbFilterMode = (ENUM_BB_FILTER_WIDTH_MODE)m_mode.Value();
         candidate.bbFilterPeriod = m_period.Value();
         candidate.bbFilterTimeframe = m_timeframe.Value();
         candidate.bbFilterDeviation = m_deviation.Value();
         candidate.bbFilterPrice = (ENUM_APPLIED_PRICE)m_price.Value();
         candidate.bbFilterMinWidthPoints = m_minWidthPoints.Value();
         candidate.bbFilterMinWidthPercent = m_minWidthPercent.Value();
        }

      bool modeValid = ModeValid(candidate.bbFilterMode);
      bool periodValid = PeriodValid(candidate.bbFilterPeriod);
      bool deviationValid = DeviationValid(candidate.bbFilterDeviation);
      bool absoluteMode = (candidate.bbFilterMode == BB_FILTER_WIDTH_ABSOLUTE);
      bool relativeMode = (candidate.bbFilterMode == BB_FILTER_WIDTH_RELATIVE);
      bool pointsValid = !absoluteMode || MinPointsValid(candidate.bbFilterMinWidthPoints);
      bool percentValid = !relativeMode || MinPercentValid(candidate.bbFilterMinWidthPercent);

      m_period.SetValid(periodValid, editable);
      m_deviation.SetValid(deviationValid, editable);
      m_minWidthPoints.SetValid(pointsValid, editable && absoluteMode);
      m_minWidthPercent.SetValid(percentValid, editable && relativeMode);

      if(!modeValid || !periodValid || !deviationValid || !pointsValid || !percentValid)
        {
         if(!modeValid)
            error = "BB Filter: modo invalido.";
         else if(!periodValid)
            error = "BB Filter: periodo deve ser 1 a 1000.";
         else if(!deviationValid)
            error = "BB Filter: desvio deve ser maior que 0 e ate 10.";
         else if(!pointsValid)
            error = "BB Filter: largura minima em pontos deve ser 1 a 100000.";
         else
            error = "BB Filter: largura relativa deve ser maior que 0 e ate 100%.";
         return false;
        }

      return true;
     }
  };

#endif
