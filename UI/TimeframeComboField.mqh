#ifndef __FUSION_TIMEFRAME_COMBO_FIELD_MQH__
#define __FUSION_TIMEFRAME_COMBO_FIELD_MQH__

#include <Controls\Label.mqh>
#include <Controls\ComboBox.mqh>
#include "PanelUtils.mqh"

class CFusionPanel;

class CTimeframeComboField
  {
private:
   bool      m_created;
   CLabel    m_label;
   CComboBox m_combo;

public:
                     CTimeframeComboField(void)
     {
      m_created = false;
     }

   bool              Create(CFusionPanel *parent,
                            const long chartId,
                            const int subwin,
                            const string namePrefix,
                            const string labelText,
                            const int labelX1,
                            const int labelY1,
                            const int labelX2,
                            const int labelY2,
                            const int comboX1,
                            const int comboY1,
                            const int comboX2,
                            const int comboY2)
     {
      if(!m_label.Create(chartId, namePrefix + "Lbl", subwin, labelX1, labelY1, labelX2, labelY2))
         return false;
      m_label.Text(labelText);
      m_label.Color(FUSION_CLR_LABEL);
      m_label.FontSize(8);
      if(!parent.AddControl(m_label))
         return false;

      if(!m_combo.Create(chartId, namePrefix + "Combo", subwin, comboX1, comboY1, comboX2, comboY2))
         return false;
      if(!FusionPopulateTimeframeCombo(m_combo))
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
     }

   void              Hide(void)
     {
      if(!m_created)
         return;
      m_label.Hide();
      m_combo.Hide();
     }

   void              Sync(const ENUM_TIMEFRAMES timeframe,const bool editable)
     {
      if(!m_created)
         return;

      long targetValue = (long)timeframe;
      if(targetValue <= 0)
         targetValue = (long)FUSION_DEFAULT_TIMEFRAME;

      if(m_combo.Value() != targetValue)
         m_combo.SelectByValue(targetValue);

      FusionApplyLabelEnabled(m_label, editable);
      if(editable)
         m_combo.Enable();
      else
         m_combo.Disable();
     }

   bool              Matches(const string objectName) const
     {
      return (m_created && objectName == m_combo.Name());
     }

   ENUM_TIMEFRAMES   Value(void)
     {
      long value = m_combo.Value();
      if(value <= 0)
         return FUSION_DEFAULT_TIMEFRAME;
      return (ENUM_TIMEFRAMES)value;
     }
  };

#endif
