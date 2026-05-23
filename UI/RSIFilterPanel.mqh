#ifndef __FUSION_RSI_FILTER_PANEL_MQH__
#define __FUSION_RSI_FILTER_PANEL_MQH__

#include "FilterPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"

#define FUSION_RSI_FILTER_COMBO_ZORDER_BASE 4000
#define FUSION_RSI_FILTER_COMBO_ZORDER_STEP 10

class CRSIFilterPanel : public CFilterPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CSelectionComboField   m_mode;
   CIntegerEditField      m_period;
   CTimeframeComboField   m_timeframe;
   CIntegerEditField      m_buyMin;
   CIntegerEditField      m_sellMax;
   CSelectionComboField   m_price;
   CLabel                 m_ruleHint;
   CLabel                 m_zoneHint;
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
      long zorder = FUSION_RSI_FILTER_COMBO_ZORDER_BASE;
      m_mode.RaiseRuntimeObjects(zorder); zorder += FUSION_RSI_FILTER_COMBO_ZORDER_STEP;
      m_timeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_RSI_FILTER_COMBO_ZORDER_STEP;
      m_price.RaiseRuntimeObjects(zorder);
     }

   bool              PeriodValid(const int value) const
     {
      return (value > 0 && value <= 1000);
     }

   bool              LevelValid(const int value) const
     {
      return (value >= 0 && value <= 100);
     }

   bool              ModeValid(const ENUM_RSI_FILTER_MODE mode) const
     {
      return (mode == RSI_FILTER_ADVANCED ||
              mode == RSI_FILTER_DIRECTION ||
              mode == RSI_FILTER_NEUTRAL ||
              mode == RSI_FILTER_EXTREMES);
     }

   int               DefaultBuyLevel(const ENUM_RSI_FILTER_MODE mode) const
     {
      if(mode == RSI_FILTER_NEUTRAL)
         return 60;
      if(mode == RSI_FILTER_EXTREMES)
         return 30;
      return 50;
     }

   int               DefaultSellLevel(const ENUM_RSI_FILTER_MODE mode) const
     {
      if(mode == RSI_FILTER_NEUTRAL)
         return 40;
      if(mode == RSI_FILTER_EXTREMES)
         return 70;
      return 50;
     }

   void              ApplyModeDefaults(SEASettings &settings,const ENUM_RSI_FILTER_MODE mode) const
     {
      if(mode != RSI_FILTER_ADVANCED)
        {
         settings.rsiFilterBuyMin = DefaultBuyLevel(mode);
         settings.rsiFilterSellMax = DefaultSellLevel(mode);
        }
     }

   bool              UsesSecondLevel(const ENUM_RSI_FILTER_MODE mode) const
     {
      return (mode != RSI_FILTER_DIRECTION);
     }

   bool              LevelOrderValid(const ENUM_RSI_FILTER_MODE mode,const int buyMin,const int sellMax) const
     {
      if(mode == RSI_FILTER_NEUTRAL)
         return (sellMax < buyMin);
      if(mode == RSI_FILTER_EXTREMES)
         return (buyMin < sellMax);
      return true;
     }

   void              SyncLevelLabels(const ENUM_RSI_FILTER_MODE mode)
     {
      if(mode == RSI_FILTER_DIRECTION)
        {
         m_buyMin.SetLabelText("Linha");
         m_sellMax.SetLabelText("Nao usado");
        }
      else if(mode == RSI_FILTER_NEUTRAL)
        {
         m_buyMin.SetLabelText("Compra >=");
         m_sellMax.SetLabelText("Venda <=");
        }
      else if(mode == RSI_FILTER_EXTREMES)
        {
         m_buyMin.SetLabelText("Sobrevenda");
         m_sellMax.SetLabelText("Sobrecompra");
        }
      else
        {
         m_buyMin.SetLabelText("Min Compra");
         m_sellMax.SetLabelText("Max Venda");
        }
     }

   string            RuleHint(const SEASettings &settings) const
     {
      if(settings.rsiFilterMode == RSI_FILTER_DIRECTION)
         return "Direcao: BUY so acima da linha; SELL so abaixo.";
      if(settings.rsiFilterMode == RSI_FILTER_NEUTRAL)
         return "Neutro: bloqueia o meio; BUY so acima, SELL so abaixo.";
      if(settings.rsiFilterMode == RSI_FILTER_EXTREMES)
         return "Extremos: bloqueia qualquer entrada nas zonas extremas.";
      return "Avancado: BUY exige RSI >= Min; SELL exige RSI <= Max.";
     }

   string            DetailHint(const SEASettings &settings) const
     {
      if(settings.rsiFilterMode == RSI_FILTER_DIRECTION)
         return "Linha " + IntegerToString(settings.rsiFilterBuyMin) + ": acima favorece compra; abaixo favorece venda.";
      if(settings.rsiFilterMode == RSI_FILTER_NEUTRAL)
         return "Entre " + IntegerToString(settings.rsiFilterSellMax) + " e " +
                IntegerToString(settings.rsiFilterBuyMin) + ", os dois lados ficam bloqueados.";
      if(settings.rsiFilterMode == RSI_FILTER_EXTREMES)
         return "Bloqueia RSI <= " + IntegerToString(settings.rsiFilterBuyMin) +
                " ou >= " + IntegerToString(settings.rsiFilterSellMax) + ".";

      string buyMin = IntegerToString(settings.rsiFilterBuyMin);
      string sellMax = IntegerToString(settings.rsiFilterSellMax);
      if(settings.rsiFilterBuyMin > settings.rsiFilterSellMax)
         return "Entre " + sellMax + " e " + buyMin + ", BUY e SELL ficam bloqueados.";
      if(settings.rsiFilterBuyMin < settings.rsiFilterSellMax)
         return "Entre " + buyMin + " e " + sellMax + ", BUY e SELL podem passar.";
      return "Iguais em " + buyMin + ": BUY >= " + buyMin + "; SELL <= " + sellMax + ".";
     }

   string            NoteHint(const SEASettings &settings) const
     {
      if(settings.rsiFilterMode == RSI_FILTER_ADVANCED &&
         settings.rsiFilterBuyMin == 0 && settings.rsiFilterSellMax == 100)
         return "Observacao: 0/100 praticamente desativa o filtro.";
      if(settings.rsiFilterMode == RSI_FILTER_ADVANCED)
        {
         if(settings.rsiFilterBuyMin == settings.rsiFilterSellMax)
            return "Com niveis iguais, repete modo Direcao nesse nivel.";
         if(settings.rsiFilterBuyMin > settings.rsiFilterSellMax)
            return "Mais seletivo: cria uma faixa central bloqueada.";
         return "Mais permissivo; use com cautela.";
        }
      return "Filtro nao abre ordem; apenas aprova ou bloqueia entradas.";
     }

   bool              NoteIsWarning(const SEASettings &settings) const
     {
      return (settings.rsiFilterMode == RSI_FILTER_ADVANCED &&
              ((settings.rsiFilterBuyMin == 0 && settings.rsiFilterSellMax == 100) ||
               settings.rsiFilterBuyMin < settings.rsiFilterSellMax));
     }

   void              SyncGuidance(const SEASettings &settings,const bool editable)
     {
      color textColor = editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED;
      string note = NoteHint(settings);

      m_ruleHint.Text(RuleHint(settings));
      m_ruleHint.Color(textColor);
      m_zoneHint.Text(DetailHint(settings));
      m_zoneHint.Color(textColor);
      m_noteHint.Text(note);
      m_noteHint.Color(NoteIsWarning(settings) ? FUSION_CLR_WARN : textColor);
     }

public:
   string            GetTitle(void) const { return "RSI Filter"; }
   string            GetButtonName(void) const { return "rsi"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Filter_rsi_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "RSI Filter", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Filtra entradas por faixa operacional do RSI.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_mode.Create(parent, chartId, subwin, prefix + "mode", "Modo", FUSION_SELECTION_RSI_FILTER_MODE, x1 + 206, y1 + 60, x1 + 280, y1 + 78, x1 + 292, y1 + 56, x1 + 432, y1 + 80))
         return false;

      if(!m_period.Create(parent, chartId, subwin, prefix + "period", "Periodo", x1, y1 + 112, x1 + 88, y1 + 130, x1 + 92, y1 + 108, x1 + 192, y1 + 132, 14))
         return false;

      if(!m_timeframe.Create(parent, chartId, subwin, prefix + "tf", "Timeframe", x1 + 206, y1 + 112, x1 + 280, y1 + 130, x1 + 292, y1 + 108, x1 + 392, y1 + 132))
         return false;
      if(!m_price.Create(parent, chartId, subwin, prefix + "price", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1, y1 + 184, x1 + 88, y1 + 202, x1 + 92, y1 + 180, x1 + 192, y1 + 204))
         return false;

      if(!m_buyMin.Create(parent, chartId, subwin, prefix + "buy_min", "Min Compra", x1, y1 + 148, x1 + 88, y1 + 166, x1 + 92, y1 + 144, x1 + 192, y1 + 168, 50))
         return false;
      if(!m_sellMax.Create(parent, chartId, subwin, prefix + "sell_max", "Max Venda", x1 + 206, y1 + 148, x1 + 280, y1 + 166, x1 + 292, y1 + 144, x1 + 392, y1 + 168, 50))
         return false;

      if(!AddText(parent, m_ruleHint, prefix + "rule_hint", chartId, subwin, x1, y1 + 232, x2, y1 + 250, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_zoneHint, prefix + "zone_hint", chartId, subwin, x1, y1 + 254, x2, y1 + 272, "", FUSION_CLR_MUTED, 8))
         return false;
      if(!AddText(parent, m_noteHint, prefix + "note_hint", chartId, subwin, x1, y1 + 276, x2, y1 + 294, "", FUSION_CLR_WARN, 8))
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
      m_price.Show();
      m_buyMin.Show();
      m_sellMax.Show();
      m_ruleHint.Show();
      m_zoneHint.Show();
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
      m_price.Hide();
      m_buyMin.Hide();
      m_sellMax.Hide();
      m_ruleHint.Hide();
      m_zoneHint.Hide();
      m_noteHint.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.useRSIFilter, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);

      SyncLevelLabels(settings.rsiFilterMode);

      bool modeValid = ModeValid(settings.rsiFilterMode);
      bool periodValid = PeriodValid(settings.rsiFilterPeriod);
      bool buyValid = LevelValid(settings.rsiFilterBuyMin);
      bool sellValid = UsesSecondLevel(settings.rsiFilterMode) ? LevelValid(settings.rsiFilterSellMax) : true;
      bool orderValid = modeValid && LevelOrderValid(settings.rsiFilterMode, settings.rsiFilterBuyMin, settings.rsiFilterSellMax);

      m_mode.Sync((long)settings.rsiFilterMode, editable);
      m_period.Sync(settings.rsiFilterPeriod, editable, periodValid);
      m_timeframe.Sync(settings.rsiFilterTimeframe, editable);
      m_price.Sync((long)settings.rsiFilterPrice, editable);
      m_buyMin.Sync(settings.rsiFilterBuyMin, editable, buyValid && orderValid);
      int sellDisplay = (settings.rsiFilterMode == RSI_FILTER_DIRECTION) ? settings.rsiFilterBuyMin : settings.rsiFilterSellMax;
      m_sellMax.Sync(sellDisplay, editable && UsesSecondLevel(settings.rsiFilterMode), sellValid && orderValid);
      SyncGuidance(settings, editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_RSI_FILTER;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_mode.Matches(objectName))
        {
         ENUM_RSI_FILTER_MODE value = (ENUM_RSI_FILTER_MODE)m_mode.Value();
         bool changed = (settings.rsiFilterMode != value);
         settings.rsiFilterMode = value;
         if(changed)
            ApplyModeDefaults(settings, value);
         SyncLevelLabels(value);
         m_buyMin.SetValue(settings.rsiFilterBuyMin);
         m_sellMax.SetValue(settings.rsiFilterSellMax);
         SyncGuidance(settings, true);
         return true;
        }
      if(m_timeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_timeframe.Value();
         if(settings.rsiFilterTimeframe == value)
            return false;
         settings.rsiFilterTimeframe = value;
         return true;
        }
      if(m_price.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_price.Value();
         if(settings.rsiFilterPrice == value)
            return false;
         settings.rsiFilterPrice = value;
         return true;
        }
      if(m_period.Matches(objectName))
        {
         int value = m_period.Value();
         if(settings.rsiFilterPeriod == value)
            return false;
         settings.rsiFilterPeriod = value;
         return true;
        }
      if(m_buyMin.Matches(objectName))
        {
         int value = m_buyMin.Value();
         if(settings.rsiFilterBuyMin == value)
            return false;
         settings.rsiFilterBuyMin = value;
         if(settings.rsiFilterMode == RSI_FILTER_DIRECTION)
            settings.rsiFilterSellMax = value;
         return true;
        }
      if(m_sellMax.Matches(objectName))
        {
         int value = m_sellMax.Value();
         if(settings.rsiFilterSellMax == value)
            return false;
         settings.rsiFilterSellMax = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_period.Matches(objectName) ||
             m_buyMin.Matches(objectName) ||
             m_sellMax.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      ENUM_RSI_FILTER_MODE mode = (ENUM_RSI_FILTER_MODE)m_mode.Value();
      if(!ModeValid(mode))
         mode = RSI_FILTER_ADVANCED;

      if(m_period.Matches(objectName))
         m_period.SanitizeRange(14, 1, 1000, 4);
      else if(m_buyMin.Matches(objectName))
         m_buyMin.SanitizeRange(DefaultBuyLevel(mode), 0, 100, 3);
      else if(m_sellMax.Matches(objectName))
         m_sellMax.SanitizeRange(DefaultSellLevel(mode), 0, 100, 3);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      if(editable)
        {
         candidate.rsiFilterMode = (ENUM_RSI_FILTER_MODE)m_mode.Value();
         candidate.rsiFilterPeriod = m_period.Value();
         candidate.rsiFilterTimeframe = m_timeframe.Value();
         candidate.rsiFilterPrice = (ENUM_APPLIED_PRICE)m_price.Value();
         candidate.rsiFilterBuyMin = m_buyMin.Value();
         candidate.rsiFilterSellMax = m_sellMax.Value();
         if(candidate.rsiFilterMode == RSI_FILTER_DIRECTION)
            candidate.rsiFilterSellMax = candidate.rsiFilterBuyMin;
        }

      bool modeValid = ModeValid(candidate.rsiFilterMode);
      bool periodValid = PeriodValid(candidate.rsiFilterPeriod);
      bool buyValid = LevelValid(candidate.rsiFilterBuyMin);
      bool sellValid = UsesSecondLevel(candidate.rsiFilterMode) ? LevelValid(candidate.rsiFilterSellMax) : true;
      bool orderValid = modeValid && LevelOrderValid(candidate.rsiFilterMode, candidate.rsiFilterBuyMin, candidate.rsiFilterSellMax);

      m_period.SetValid(periodValid, editable);
      m_buyMin.SetValid(buyValid && orderValid, editable);
      m_sellMax.SetValid(sellValid && orderValid, editable && UsesSecondLevel(candidate.rsiFilterMode));

      if(!modeValid || !periodValid || !buyValid || !sellValid || !orderValid)
        {
         if(!modeValid)
            error = "RSI Filter: modo invalido.";
         else if(!periodValid)
            error = "RSI Filter: periodo 1..1000.";
         else if(!buyValid || !sellValid)
            error = "RSI Filter: niveis 0..100.";
         else if(candidate.rsiFilterMode == RSI_FILTER_NEUTRAL)
            error = "RSI: venda < compra.";
         else
            error = "RSI: sobrevenda < sobrecompra.";
         return false;
        }

      return true;
     }
  };

#endif
