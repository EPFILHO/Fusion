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
   CLabel                 m_dualLabel;
   CButton                m_dualToggle;
   CIntegerEditField      m_sellPeriod;
   CTimeframeComboField   m_sellTimeframe;
   CSelectionComboField   m_sellMethod;
   CSelectionComboField   m_sellPrice;
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
      m_price.RaiseRuntimeObjects(zorder); zorder += FUSION_TREND_FILTER_COMBO_ZORDER_STEP;
      m_sellTimeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_TREND_FILTER_COMBO_ZORDER_STEP;
      m_sellMethod.RaiseRuntimeObjects(zorder); zorder += FUSION_TREND_FILTER_COMBO_ZORDER_STEP;
      m_sellPrice.RaiseRuntimeObjects(zorder);
     }

   bool              PeriodValid(const int value) const
     {
      return (value > 0 && value <= 1000);
     }

   void              SyncGuidance(const SEASettings &settings,const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      m_ruleHint.Text(settings.trendDualBarrierEnabled
                      ? "BUY: acima da MA principal. SELL: abaixo da MA de venda."
                      : "Filtro: BUY so acima da MA; SELL so abaixo da MA.");
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
                  "Filtra sinais pela posicao do preco em relacao a uma ou duas medias.", FUSION_CLR_MUTED, 8))
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

      if(!AddText(parent, m_dualLabel, prefix + "dual_lbl", chartId, subwin, x1, y1 + 196, x1 + 88, y1 + 214, "Duas MAs", FUSION_CLR_LABEL, 8))
         return false;
      if(!m_dualToggle.Create(chartId, prefix + "dual_toggle", subwin, x1 + 92, y1 + 192, x1 + 192, y1 + 216))
         return false;
      FusionApplyToggleButtonStyle(m_dualToggle, false);
      if(!parent.AddControl(m_dualToggle))
         return false;
      if(!m_sellPeriod.Create(parent, chartId, subwin, prefix + "sell_period", "Venda Per.", x1 + 206, y1 + 196, x1 + 280, y1 + 214, x1 + 292, y1 + 192, x1 + 392, y1 + 216, 21))
         return false;
      if(!m_sellTimeframe.Create(parent, chartId, subwin, prefix + "sell_tf", "Venda TF", x1, y1 + 236, x1 + 88, y1 + 254, x1 + 92, y1 + 232, x1 + 192, y1 + 256))
         return false;
      if(!m_sellMethod.Create(parent, chartId, subwin, prefix + "sell_method", "Venda Met.", FUSION_SELECTION_MA_METHOD, x1 + 206, y1 + 236, x1 + 280, y1 + 254, x1 + 292, y1 + 232, x1 + 392, y1 + 256))
         return false;
      if(!m_sellPrice.Create(parent, chartId, subwin, prefix + "sell_price", "Venda Preco", FUSION_SELECTION_APPLIED_PRICE, x1, y1 + 276, x1 + 88, y1 + 294, x1 + 92, y1 + 272, x1 + 192, y1 + 296))
         return false;

      if(!AddText(parent, m_ruleHint, prefix + "rule_hint", chartId, subwin, x1, y1 + 320, x2, y1 + 338, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_noteHint, prefix + "note_hint", chartId, subwin, x1, y1 + 342, x2, y1 + 360, "", FUSION_CLR_MUTED, 8))
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
      m_dualLabel.Show();
      m_dualToggle.Show();
      m_sellPeriod.Show();
      m_sellTimeframe.Show();
      m_sellMethod.Show();
      m_sellPrice.Show();
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
      m_dualLabel.Hide();
      m_dualToggle.Hide();
      m_sellPeriod.Hide();
      m_sellTimeframe.Hide();
      m_sellMethod.Hide();
      m_sellPrice.Hide();
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
      FusionApplyToggleButtonStyle(m_dualToggle, settings.trendDualBarrierEnabled, editable);
      m_dualLabel.Color(editable ? FUSION_CLR_LABEL : FUSION_CLR_DISABLED);
      bool sellPeriodValid = PeriodValid(settings.trendSellMAPeriod);
      bool dualEditable = (editable && settings.trendDualBarrierEnabled);
      m_sellPeriod.Sync(settings.trendSellMAPeriod, dualEditable, sellPeriodValid);
      m_sellTimeframe.Sync(settings.trendSellMATimeframe, dualEditable);
      m_sellMethod.Sync((long)settings.trendSellMAMethod, dualEditable);
      m_sellPrice.Sync((long)settings.trendSellMAPrice, dualEditable);
      SyncGuidance(settings, editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName == m_toggle.Name())
        {
         command.type = UI_COMMAND_TOGGLE_TREND_FILTER;
         return true;
        }
      if(objectName == m_dualToggle.Name())
        {
         command.type = UI_COMMAND_TOGGLE_TREND_DUAL_BARRIER;
         return true;
        }
      return false;
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
      if(m_sellTimeframe.Matches(objectName))
        {
         settings.trendSellMATimeframe = m_sellTimeframe.Value();
         return true;
        }
      if(m_sellMethod.Matches(objectName))
        {
         settings.trendSellMAMethod = (ENUM_MA_METHOD)m_sellMethod.Value();
         return true;
        }
      if(m_sellPrice.Matches(objectName))
        {
         settings.trendSellMAPrice = (ENUM_APPLIED_PRICE)m_sellPrice.Value();
         return true;
        }
      if(m_sellPeriod.Matches(objectName))
        {
         settings.trendSellMAPeriod = m_sellPeriod.Value();
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_period.Matches(objectName) || m_sellPeriod.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_period.Matches(objectName))
         m_period.SanitizeDigits(4);
      else if(m_sellPeriod.Matches(objectName))
         m_sellPeriod.SanitizeDigits(4);
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
         candidate.trendSellMAPeriod = m_sellPeriod.Value();
         candidate.trendSellMATimeframe = m_sellTimeframe.Value();
         candidate.trendSellMAMethod = (ENUM_MA_METHOD)m_sellMethod.Value();
         candidate.trendSellMAPrice = (ENUM_APPLIED_PRICE)m_sellPrice.Value();
        }

      bool periodValid = PeriodValid(candidate.trendMAPeriod);
      bool sellPeriodValid = PeriodValid(candidate.trendSellMAPeriod);
      m_period.SetValid(periodValid, editable);
      m_sellPeriod.SetValid(!candidate.trendDualBarrierEnabled || sellPeriodValid,
                            editable && candidate.trendDualBarrierEnabled);

      if(!periodValid || (candidate.trendDualBarrierEnabled && !sellPeriodValid))
        {
         error = !periodValid
                 ? "Trend Filter: periodo da MA deve ser 1 a 1000."
                 : "Trend Filter: periodo da MA de venda deve ser 1 a 1000.";
         return false;
        }

      return true;
     }
  };

#endif
