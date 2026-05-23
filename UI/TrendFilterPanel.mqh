#ifndef __FUSION_TREND_FILTER_PANEL_MQH__
#define __FUSION_TREND_FILTER_PANEL_MQH__

#include "FilterPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"

#define FUSION_TREND_FILTER_COMBO_ZORDER_BASE 3800
#define FUSION_TREND_FILTER_COMBO_ZORDER_STEP 10

class CTrendFilterPanel : public CFilterPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CIntegerEditField      m_period;
   CTimeframeComboField   m_timeframe;
   CSelectionComboField   m_method;
   CSelectionComboField   m_price;
   CLabel                 m_ruleHint;
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
      long zorder = FUSION_TREND_FILTER_COMBO_ZORDER_BASE;
      m_timeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_TREND_FILTER_COMBO_ZORDER_STEP;
      m_method.RaiseRuntimeObjects(zorder); zorder += FUSION_TREND_FILTER_COMBO_ZORDER_STEP;
      m_price.RaiseRuntimeObjects(zorder);
     }

   bool              PeriodValid(const int value) const
     {
      return (value > 0 && value <= 1000);
     }

   void              SyncGuidance(const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      m_ruleHint.Text("Filtro: BUY so acima da MA; SELL so abaixo da MA.");
      m_ruleHint.Color(textColor);
      m_noteHint.Text("Nao abre ordem; apenas bloqueia sinais contra o vies.");
      m_noteHint.Color(textColor);
     }

public:
   string            GetTitle(void) const { return "Trend Filter"; }
   string            GetButtonName(void) const { return "trend"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Filter_trend_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "Trend Filter", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Filtra sinais pela posicao do preco em relacao a uma media.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_period.Create(parent, chartId, subwin, prefix + "period", "Periodo", x1 + 206, y1 + 60, x1 + 280, y1 + 78, x1 + 292, y1 + 56, x1 + 392, y1 + 80, 50))
         return false;

      if(!m_timeframe.Create(parent, chartId, subwin, prefix + "tf", "Timeframe", x1, y1 + 112, x1 + 88, y1 + 130, x1 + 92, y1 + 108, x1 + 192, y1 + 132))
         return false;
      if(!m_method.Create(parent, chartId, subwin, prefix + "method", "Metodo", FUSION_SELECTION_MA_METHOD, x1 + 206, y1 + 112, x1 + 280, y1 + 130, x1 + 292, y1 + 108, x1 + 392, y1 + 132))
         return false;
      if(!m_price.Create(parent, chartId, subwin, prefix + "price", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1, y1 + 148, x1 + 88, y1 + 166, x1 + 92, y1 + 144, x1 + 192, y1 + 168))
         return false;

      if(!AddText(parent, m_ruleHint, prefix + "rule_hint", chartId, subwin, x1, y1 + 216, x2, y1 + 234, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_noteHint, prefix + "note_hint", chartId, subwin, x1, y1 + 238, x2, y1 + 256, "", FUSION_CLR_MUTED, 8))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_period.Show();
      m_timeframe.Show();
      m_method.Show();
      m_price.Show();
      m_ruleHint.Show();
      m_noteHint.Show();

      RaiseCombos();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_period.Hide();
      m_timeframe.Hide();
      m_method.Hide();
      m_price.Hide();
      m_ruleHint.Hide();
      m_noteHint.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.useTrendFilter, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);

      bool periodValid = PeriodValid(settings.trendMAPeriod);
      m_period.Sync(settings.trendMAPeriod, editable, periodValid);
      m_timeframe.Sync(settings.trendMATimeframe, editable);
      m_method.Sync((long)settings.trendMAMethod, editable);
      m_price.Sync((long)settings.trendMAPrice, editable);
      SyncGuidance(editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_TREND_FILTER;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_timeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_timeframe.Value();
         if(settings.trendMATimeframe == value)
            return false;
         settings.trendMATimeframe = value;
         return true;
        }
      if(m_method.Matches(objectName))
        {
         ENUM_MA_METHOD value = (ENUM_MA_METHOD)m_method.Value();
         if(settings.trendMAMethod == value)
            return false;
         settings.trendMAMethod = value;
         return true;
        }
      if(m_price.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_price.Value();
         if(settings.trendMAPrice == value)
            return false;
         settings.trendMAPrice = value;
         return true;
        }
      if(m_period.Matches(objectName))
        {
         int value = m_period.Value();
         if(settings.trendMAPeriod == value)
            return false;
         settings.trendMAPeriod = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_period.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_period.Matches(objectName))
         m_period.SanitizeDigits(4);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      if(editable)
        {
         candidate.trendMAPeriod = m_period.Value();
         candidate.trendMATimeframe = m_timeframe.Value();
         candidate.trendMAMethod = (ENUM_MA_METHOD)m_method.Value();
         candidate.trendMAPrice = (ENUM_APPLIED_PRICE)m_price.Value();
        }

      bool periodValid = PeriodValid(candidate.trendMAPeriod);
      m_period.SetValid(periodValid, editable);

      if(!periodValid)
        {
         error = "Trend Filter: periodo da MA deve ser 1 a 1000.";
         return false;
        }

      return true;
     }
  };

#endif
