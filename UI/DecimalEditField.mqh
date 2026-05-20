#ifndef __FUSION_DECIMAL_EDIT_FIELD_MQH__
#define __FUSION_DECIMAL_EDIT_FIELD_MQH__

#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include "PanelUtils.mqh"

class CFusionPanel;

class CDecimalEditField
  {
private:
   bool      m_created;
   long      m_chartId;
   int       m_digits;
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
                     CDecimalEditField(void)
     {
      m_created = false;
      m_chartId = 0;
      m_digits = 2;
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
                            const double value,
                            const int digits)
     {
      m_chartId = chartId;
      m_digits = digits;

      if(!m_label.Create(chartId, namePrefix + "Lbl", subwin, labelX1, labelY1, labelX2, labelY2))
         return false;
      m_label.Text(labelText);
      m_label.Color(FUSION_CLR_LABEL);
      m_label.FontSize(8);
      if(!parent.AddControl(m_label))
         return false;

      if(!m_edit.Create(chartId, namePrefix + "Edit", subwin, editX1, editY1, editX2, editY2))
         return false;
      m_edit.Text(DoubleToString(value, m_digits));
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

   void              Sync(const double value,const bool editable,const bool valid)
     {
      if(!m_created)
         return;

      string target = DoubleToString(value, m_digits);
      if(FusionNormalizeDecimalText(LiveText()) != FusionNormalizeDecimalText(target))
         m_edit.Text(target);
      FusionApplyLabelEnabled(m_label, editable);
      FusionApplyEditStyle(m_edit, valid, editable);
     }

   bool              Matches(const string objectName) const
     {
      return (m_created && objectName == m_edit.Name());
     }

   void              SanitizeDecimal(const int maxIntegerDigits,const int maxDecimalDigits)
     {
      string source = FusionNormalizeDecimalText(LiveText());
      string clean = "";
      bool hasSeparator = false;
      int integerDigits = 0;
      int decimalDigits = 0;

      for(int i = 0; i < StringLen(source); ++i)
        {
         ushort ch = StringGetCharacter(source, i);
         if(ch == '+')
            continue;
         if(ch == '.' && !hasSeparator)
           {
            if(clean == "")
               clean = "0";
            clean += ".";
            hasSeparator = true;
            continue;
           }
         if(ch < '0' || ch > '9')
            continue;

         if(hasSeparator)
           {
            if(decimalDigits >= maxDecimalDigits)
               continue;
            decimalDigits++;
           }
         else
           {
            if(integerDigits >= maxIntegerDigits)
               continue;
            integerDigits++;
           }

         clean += StringSubstr(source, i, 1);
        }

      if(clean == "" || clean == ".")
         clean = "0";

      if(FusionIsDecimalText(clean, true))
         m_edit.Text(DoubleToString(StringToDouble(clean), m_digits));
      else
         m_edit.Text(clean);
     }

   double            Value(void) const
     {
      string text = FusionNormalizeDecimalText(LiveText());
      if(!FusionIsDecimalText(text, true))
         return 0.0;
      return StringToDouble(text);
     }

   void              SetValid(const bool valid,const bool editable)
     {
      FusionApplyLabelEnabled(m_label, editable);
      FusionApplyEditStyle(m_edit, valid, editable);
     }
  };

#endif
