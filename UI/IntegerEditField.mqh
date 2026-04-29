#ifndef __FUSION_INTEGER_EDIT_FIELD_MQH__
#define __FUSION_INTEGER_EDIT_FIELD_MQH__

#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include "PanelUtils.mqh"

class CFusionPanel;

class CIntegerEditField
  {
private:
   bool      m_created;
   long      m_chartId;
   CLabel    m_label;
   CEdit     m_edit;

   string            LiveText(void) const
     {
      string name = m_edit.Name();
      if(name != "" && ObjectFind(m_chartId, name) >= 0)
         return ObjectGetString(m_chartId, name, OBJPROP_TEXT);
      return m_edit.Text();
     }

public:
                     CIntegerEditField(void)
     {
      m_created = false;
      m_chartId = 0;
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
                            const int editX1,
                            const int editY1,
                            const int editX2,
                            const int editY2,
                            const int value)
     {
      m_chartId = chartId;

      if(!m_label.Create(chartId, namePrefix + "Lbl", subwin, labelX1, labelY1, labelX2, labelY2))
         return false;
      m_label.Text(labelText);
      m_label.Color(FUSION_CLR_LABEL);
      m_label.FontSize(8);
      if(!parent.AddControl(m_label))
         return false;

      if(!m_edit.Create(chartId, namePrefix + "Edit", subwin, editX1, editY1, editX2, editY2))
         return false;
      m_edit.Text(IntegerToString(value));
      m_edit.TextAlign(ALIGN_CENTER);
      FusionApplyEditStyle(m_edit, true, true);
      if(!parent.AddControl(m_edit))
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
      m_edit.Show();
     }

   void              Hide(void)
     {
      if(!m_created)
         return;
      m_label.Hide();
      m_edit.Hide();
     }

   void              Sync(const int value,const bool editable,const bool valid)
     {
      if(!m_created)
         return;
      string target = IntegerToString(value);
      if(LiveText() != target)
         m_edit.Text(target);
      FusionApplyLabelEnabled(m_label, editable);
      FusionApplyEditStyle(m_edit, valid, editable);
     }

   bool              Matches(const string objectName) const
     {
      return (m_created && objectName == m_edit.Name());
     }

   void              SanitizeDigits(const int maxDigits)
     {
      string trimmed = FusionTrimCopy(LiveText());
      string digits = "";
      for(int i = 0; i < StringLen(trimmed); ++i)
        {
         ushort ch = StringGetCharacter(trimmed, i);
         if(ch < '0' || ch > '9')
            continue;
         if(StringLen(digits) >= maxDigits)
            break;
         digits += StringSubstr(trimmed, i, 1);
        }

      if(digits == "")
         digits = "0";

      m_edit.Text(digits);
     }

   int               Value(void) const
     {
      string text = FusionTrimCopy(LiveText());
      if(!FusionIsIntegerText(text, true))
         return 0;
      return (int)StringToInteger(text);
     }

   void              SetValid(const bool valid,const bool editable)
     {
      FusionApplyLabelEnabled(m_label, editable);
      FusionApplyEditStyle(m_edit, valid, editable);
     }
  };

#endif
