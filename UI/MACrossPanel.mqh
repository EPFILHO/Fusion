#ifndef __FUSION_MACROSS_PANEL_MQH__
#define __FUSION_MACROSS_PANEL_MQH__

#include "StrategyPanelBase.mqh"
#include "TimeframeComboField.mqh"
#include "SelectionComboField.mqh"
#include "IntegerEditField.mqh"

#define FUSION_MA_COMBO_ZORDER_BASE 3200
#define FUSION_MA_COMBO_ZORDER_STEP 10

class CMACrossPanel : public CStrategyPanelBase
  {
private:
   CLabel                 m_header;
   CLabel                 m_description;
   CButton                m_toggle;
   CLabel                 m_fastHeader;
   CLabel                 m_slowHeader;
   CIntegerEditField      m_fastPeriod;
   CTimeframeComboField   m_fastTimeframe;
   CSelectionComboField   m_fastMethod;
   CSelectionComboField   m_fastPrice;
   CIntegerEditField      m_slowPeriod;
   CTimeframeComboField   m_slowTimeframe;
   CSelectionComboField   m_slowMethod;
   CSelectionComboField   m_slowPrice;
   CSelectionComboField   m_entryMode;
   CSelectionComboField   m_exitMode;

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
      long zorder = FUSION_MA_COMBO_ZORDER_BASE;
      m_fastTimeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_fastMethod.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_fastPrice.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_slowTimeframe.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_slowMethod.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_slowPrice.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_entryMode.RaiseRuntimeObjects(zorder); zorder += FUSION_MA_COMBO_ZORDER_STEP;
      m_exitMode.RaiseRuntimeObjects(zorder);
     }

public:
   string            GetTitle(void) const { return "MA Cross"; }
   string            GetButtonName(void) const { return "ma"; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Strategy_ma_";
      if(!AddText(parent, m_header, prefix + "hdr", chartId, subwin, x1, y1, x2, y1 + 18, "MA Cross", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddText(parent, m_description, prefix + "desc", chartId, subwin, x1, y1 + 24, x2, y1 + 44,
                  "Cruza medias rapida e lenta com parametros independentes.", FUSION_CLR_MUTED, 8))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!AddText(parent, m_fastHeader, prefix + "fastHdr", chartId, subwin, x1 + 136, y1 + 58, x1 + 340, y1 + 76, "Media Rapida", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddText(parent, m_slowHeader, prefix + "slowHdr", chartId, subwin, x1 + 136, y1 + 166, x1 + 340, y1 + 184, "Media Lenta", FUSION_CLR_VALUE, 9))
         return false;

      if(!m_fastPeriod.Create(parent, chartId, subwin, prefix + "fastPeriod", "Periodo", x1, y1 + 96, x1 + 88, y1 + 114, x1 + 92, y1 + 92, x1 + 166, y1 + 116, 9))
         return false;
      if(!m_fastTimeframe.Create(parent, chartId, subwin, prefix + "fastTf", "Timeframe", x1 + 188, y1 + 96, x1 + 294, y1 + 114, x1 + 300, y1 + 92, x1 + 430, y1 + 116))
         return false;
      if(!m_fastMethod.Create(parent, chartId, subwin, prefix + "fastMethod", "Tipo", FUSION_SELECTION_MA_METHOD, x1, y1 + 132, x1 + 88, y1 + 150, x1 + 92, y1 + 128, x1 + 166, y1 + 152))
         return false;
      if(!m_fastPrice.Create(parent, chartId, subwin, prefix + "fastPrice", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1 + 188, y1 + 132, x1 + 294, y1 + 150, x1 + 300, y1 + 128, x1 + 430, y1 + 152))
         return false;

      if(!m_slowPeriod.Create(parent, chartId, subwin, prefix + "slowPeriod", "Periodo", x1, y1 + 204, x1 + 88, y1 + 222, x1 + 92, y1 + 200, x1 + 166, y1 + 224, 21))
         return false;
      if(!m_slowTimeframe.Create(parent, chartId, subwin, prefix + "slowTf", "Timeframe", x1 + 188, y1 + 204, x1 + 294, y1 + 222, x1 + 300, y1 + 200, x1 + 430, y1 + 224))
         return false;
      if(!m_slowMethod.Create(parent, chartId, subwin, prefix + "slowMethod", "Tipo", FUSION_SELECTION_MA_METHOD, x1, y1 + 240, x1 + 88, y1 + 258, x1 + 92, y1 + 236, x1 + 166, y1 + 260))
         return false;
      if(!m_slowPrice.Create(parent, chartId, subwin, prefix + "slowPrice", "Preco", FUSION_SELECTION_APPLIED_PRICE, x1 + 188, y1 + 240, x1 + 294, y1 + 258, x1 + 300, y1 + 236, x1 + 430, y1 + 260))
         return false;

      if(!m_entryMode.Create(parent, chartId, subwin, prefix + "entry", "Entrada", FUSION_SELECTION_ENTRY_MODE, x1, y1 + 300, x1 + 88, y1 + 318, x1 + 92, y1 + 296, x1 + 248, y1 + 320))
         return false;
      if(!m_exitMode.Create(parent, chartId, subwin, prefix + "exit", "Saida", FUSION_SELECTION_EXIT_MODE, x1 + 270, y1 + 300, x1 + 342, y1 + 318, x1 + 346, y1 + 296, x1 + 478, y1 + 320))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_fastHeader.Show();
      m_slowHeader.Show();
      m_fastPeriod.Show();
      m_fastTimeframe.Show();
      m_fastMethod.Show();
      m_fastPrice.Show();
      m_slowPeriod.Show();
      m_slowTimeframe.Show();
      m_slowMethod.Show();
      m_slowPrice.Show();
      m_entryMode.Show();
      m_exitMode.Show();

      RaiseCombos();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_fastHeader.Hide();
      m_slowHeader.Hide();
      m_fastPeriod.Hide();
      m_fastTimeframe.Hide();
      m_fastMethod.Hide();
      m_fastPrice.Hide();
      m_slowPeriod.Hide();
      m_slowTimeframe.Hide();
      m_slowMethod.Hide();
      m_slowPrice.Hide();
      m_entryMode.Hide();
      m_exitMode.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, settings.useMACross, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);
      FusionApplyLabelEnabled(m_fastHeader, editable);
      FusionApplyLabelEnabled(m_slowHeader, editable);

      m_fastPeriod.Sync(settings.maFastPeriod, editable, true);
      m_fastTimeframe.Sync(settings.maFastTimeframe, editable);
      m_fastMethod.Sync((long)settings.maFastMethod, editable);
      m_fastPrice.Sync((long)settings.maFastPrice, editable);

      m_slowPeriod.Sync(settings.maSlowPeriod, editable, true);
      m_slowTimeframe.Sync(settings.maSlowTimeframe, editable);
      m_slowMethod.Sync((long)settings.maSlowMethod, editable);
      m_slowPrice.Sync((long)settings.maSlowPrice, editable);

      m_entryMode.Sync((long)settings.maEntryMode, editable);
      m_exitMode.Sync((long)settings.maExitMode, editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = UI_COMMAND_TOGGLE_MACROSS;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_fastTimeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_fastTimeframe.Value();
         if(settings.maFastTimeframe == value)
            return false;
         settings.maFastTimeframe = value;
         return true;
        }
      if(m_slowTimeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES value = m_slowTimeframe.Value();
         if(settings.maSlowTimeframe == value)
            return false;
         settings.maSlowTimeframe = value;
         return true;
        }
      if(m_fastMethod.Matches(objectName))
        {
         ENUM_MA_METHOD value = (ENUM_MA_METHOD)m_fastMethod.Value();
         if(settings.maFastMethod == value)
            return false;
         settings.maFastMethod = value;
         return true;
        }
      if(m_slowMethod.Matches(objectName))
        {
         ENUM_MA_METHOD value = (ENUM_MA_METHOD)m_slowMethod.Value();
         if(settings.maSlowMethod == value)
            return false;
         settings.maSlowMethod = value;
         return true;
        }
      if(m_fastPrice.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_fastPrice.Value();
         if(settings.maFastPrice == value)
            return false;
         settings.maFastPrice = value;
         return true;
        }
      if(m_slowPrice.Matches(objectName))
        {
         ENUM_APPLIED_PRICE value = (ENUM_APPLIED_PRICE)m_slowPrice.Value();
         if(settings.maSlowPrice == value)
            return false;
         settings.maSlowPrice = value;
         return true;
        }
      if(m_entryMode.Matches(objectName))
        {
         ENUM_ENTRY_MODE value = (ENUM_ENTRY_MODE)m_entryMode.Value();
         if(settings.maEntryMode == value)
            return false;
         settings.maEntryMode = value;
         return true;
        }
      if(m_exitMode.Matches(objectName))
        {
         ENUM_EXIT_MODE value = (ENUM_EXIT_MODE)m_exitMode.Value();
         if(settings.maExitMode == value)
            return false;
         settings.maExitMode = value;
         return true;
        }
      if(m_fastPeriod.Matches(objectName))
        {
         int value = m_fastPeriod.Value();
         if(settings.maFastPeriod == value)
            return false;
         settings.maFastPeriod = value;
         return true;
        }
      if(m_slowPeriod.Matches(objectName))
        {
         int value = m_slowPeriod.Value();
         if(settings.maSlowPeriod == value)
            return false;
         settings.maSlowPeriod = value;
         return true;
        }
      return false;
     }

   bool              IsDeferredEdit(const string objectName) const
     {
      return m_fastPeriod.Matches(objectName) || m_slowPeriod.Matches(objectName);
     }

   void              NormalizeDeferredEdit(const string objectName)
     {
      if(m_fastPeriod.Matches(objectName))
         m_fastPeriod.SanitizeDigits(4);
      else if(m_slowPeriod.Matches(objectName))
         m_slowPeriod.SanitizeDigits(4);
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";

      candidate.maFastPeriod = m_fastPeriod.Value();
      candidate.maSlowPeriod = m_slowPeriod.Value();

      bool fastValid = (candidate.maFastPeriod > 0 && candidate.maFastPeriod <= 1000);
      bool slowValid = (candidate.maSlowPeriod > 0 && candidate.maSlowPeriod <= 1000);
      bool orderValid = (fastValid && slowValid && candidate.maFastPeriod < candidate.maSlowPeriod);

      m_fastPeriod.SetValid(fastValid && orderValid, editable);
      m_slowPeriod.SetValid(slowValid && orderValid, editable);

      if(!fastValid || !slowValid || !orderValid)
        {
         error = "Parametros da estrategia MA invalidos.";
         return false;
        }

      return true;
     }
  };

#endif
