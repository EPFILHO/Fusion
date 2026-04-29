#ifndef __FUSION_SELECTION_COMBO_FIELD_MQH__
#define __FUSION_SELECTION_COMBO_FIELD_MQH__

#include <Controls\Label.mqh>
#include <Controls\ComboBox.mqh>
#include "PanelUtils.mqh"

class CFusionPanel;

enum ENUM_FUSION_SELECTION_COMBO_KIND
  {
   FUSION_SELECTION_MA_METHOD = 0,
   FUSION_SELECTION_APPLIED_PRICE,
   FUSION_SELECTION_ENTRY_MODE,
   FUSION_SELECTION_EXIT_MODE
  };

class CSelectionComboField
  {
private:
   bool                            m_created;
   long                            m_chartId;
   ENUM_FUSION_SELECTION_COMBO_KIND m_kind;
   CLabel                          m_label;
   CComboBox                       m_combo;

   bool              Populate(void)
     {
      if(m_kind == FUSION_SELECTION_MA_METHOD)
         return FusionPopulateMAMethodCombo(m_combo);
      if(m_kind == FUSION_SELECTION_APPLIED_PRICE)
         return FusionPopulateAppliedPriceCombo(m_combo);
      if(m_kind == FUSION_SELECTION_ENTRY_MODE)
         return FusionPopulateEntryModeCombo(m_combo);
      return FusionPopulateExitModeCombo(m_combo);
     }

public:
                     CSelectionComboField(void)
     {
      m_created = false;
      m_chartId = 0;
      m_kind = FUSION_SELECTION_MA_METHOD;
     }

   bool              Create(CFusionPanel *parent,
                            const long chartId,
                            const int subwin,
                            const string namePrefix,
                            const string labelText,
                            const ENUM_FUSION_SELECTION_COMBO_KIND kind,
                            const int labelX1,
                            const int labelY1,
                            const int labelX2,
                            const int labelY2,
                            const int comboX1,
                            const int comboY1,
                            const int comboX2,
                            const int comboY2)
     {
      m_chartId = chartId;
      m_kind = kind;

      if(!m_label.Create(chartId, namePrefix + "Lbl", subwin, labelX1, labelY1, labelX2, labelY2))
         return false;
      m_label.Text(labelText);
      m_label.Color(FUSION_CLR_LABEL);
      m_label.FontSize(8);
      if(!parent.AddControl(m_label))
         return false;

      if(!m_combo.Create(chartId, namePrefix + "Combo", subwin, comboX1, comboY1, comboX2, comboY2))
         return false;
      if(!Populate())
         return false;
      if(!parent.AddControl(m_combo))
         return false;

      m_created = true;
      Hide();
      return true;
     }

   void              Show(void)
     {
      if(!m_created)
         return;
      m_label.Show();
      m_combo.Show();
      FusionResetComboRuntimeObjects(m_chartId, m_combo.Name());
     }

   void              CloseDropdown(void)
     {
      if(!m_created)
         return;

      long outsideX = -100000;
      double outsideY = -100000.0;
      string empty = "";
      m_combo.OnEvent(CHARTEVENT_CLICK, outsideX, outsideY, empty);
      FusionResetComboRuntimeObjects(m_chartId, m_combo.Name());
     }

   void              Hide(void)
     {
      if(!m_created)
         return;
      CloseDropdown();
      m_label.Hide();
      m_combo.Hide();
      FusionResetComboRuntimeObjects(m_chartId, m_combo.Name());
     }

   void              RaiseRuntimeObjects(const long zorder)
     {
      if(!m_created)
         return;
      FusionRaiseComboRuntimeObjects(m_chartId, m_combo.Name(), zorder);
     }

   void              Sync(const long selectedValue,const bool editable)
     {
      if(!m_created)
         return;

      if(m_combo.Value() != selectedValue)
         m_combo.SelectByValue(selectedValue);

      FusionApplyLabelEnabled(m_label, editable);
     }

   bool              Matches(const string objectName) const
     {
      return (m_created && objectName == m_combo.Name());
     }

   long              Value(void)
     {
      return m_combo.Value();
     }
  };

#endif
