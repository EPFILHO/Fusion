#ifndef __FUSION_STRATEGY_TOGGLE_PANEL_MQH__
#define __FUSION_STRATEGY_TOGGLE_PANEL_MQH__

#include "StrategyPanelBase.mqh"

class CStrategyTogglePanel : public CStrategyPanelBase
  {
private:
   string           m_title;
   string           m_buttonName;
   ENUM_UI_COMMAND  m_toggleCommand;
   CLabel           m_header;
   CLabel           m_description;
   CButton          m_toggle;
   CLabel           m_magicLabel;
   CEdit            m_magicEdit;
   bool             m_magicConflict;

   string           LiveEditText(CEdit &edit)
     {
      string name = edit.Name();
      if(name != "" && ObjectFind(0, name) >= 0)
         return ObjectGetString(0, name, OBJPROP_TEXT);
      return edit.Text();
     }

   int              SettingsMagic(const SEASettings &settings) const
     {
      if(m_toggleCommand == UI_COMMAND_TOGGLE_MACROSS)
         return settings.maCrossMagicNumber;
      if(m_toggleCommand == UI_COMMAND_TOGGLE_RSI)
         return settings.rsiMagicNumber;
      if(m_toggleCommand == UI_COMMAND_TOGGLE_BB)
         return settings.bbMagicNumber;
      return settings.magicNumber;
     }

   void             SetSettingsMagic(SEASettings &settings,const int magicNumber)
     {
      if(m_toggleCommand == UI_COMMAND_TOGGLE_MACROSS)
         settings.maCrossMagicNumber = magicNumber;
      else if(m_toggleCommand == UI_COMMAND_TOGGLE_RSI)
         settings.rsiMagicNumber = magicNumber;
      else if(m_toggleCommand == UI_COMMAND_TOGGLE_BB)
         settings.bbMagicNumber = magicNumber;
     }

   bool             ParseMagic(int &magicNumber)
     {
      string text = FusionTrimCopy(LiveEditText(m_magicEdit));
      if(!FusionIsIntegerText(text, false))
        {
         magicNumber = 0;
         return false;
        }

      magicNumber = (int)StringToInteger(text);
      return (magicNumber > 0);
     }

   void             RefreshMagicStyle(const bool editable)
     {
      int magicNumber = 0;
      bool valid = ParseMagic(magicNumber) && !m_magicConflict;
      FusionApplyEditStyle(m_magicEdit, valid, editable);
      m_magicLabel.Color(!editable ? FUSION_CLR_MUTED : (valid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
     }

public:
                     CStrategyTogglePanel(const string title,const string buttonName,const ENUM_UI_COMMAND toggleCommand)
     {
      m_title         = title;
      m_buttonName    = buttonName;
      m_toggleCommand = toggleCommand;
      m_magicConflict = false;
     }

   string            GetTitle(void) const { return m_title; }
   string            GetButtonName(void) const { return m_buttonName; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Strategy_" + m_buttonName + "_";
      if(!m_header.Create(chartId, prefix + "hdr", subwin, x1, y1, x2, y1 + 18))
         return false;
      m_header.Text(m_title);
      m_header.Color(FUSION_CLR_TITLE);
      m_header.FontSize(10);
      if(!parent.AddControl(m_header))
         return false;

      if(!m_description.Create(chartId, prefix + "desc", subwin, x1, y1 + 24, x2, y1 + 44))
         return false;
      m_description.Text("Hot reload dedicado para esta estrategia.");
      m_description.Color(FUSION_CLR_MUTED);
      m_description.FontSize(8);
      if(!parent.AddControl(m_description))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_magicLabel.Create(chartId, prefix + "magic_lbl", subwin, x1, y1 + 98, x1 + 90, y1 + 116))
         return false;
      m_magicLabel.Text("Magic");
      m_magicLabel.Color(FUSION_CLR_LABEL);
      m_magicLabel.FontSize(8);
      if(!parent.AddControl(m_magicLabel))
         return false;

      if(!m_magicEdit.Create(chartId, prefix + "magic_edit", subwin, x1 + 96, y1 + 94, x1 + 236, y1 + 118))
         return false;
      m_magicEdit.Text("0");
      FusionApplyEditStyle(m_magicEdit, true);
      if(!parent.AddControl(m_magicEdit))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_magicLabel.Show();
      m_magicEdit.Show();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_magicLabel.Hide();
      m_magicEdit.Hide();
     }

   virtual void      LoadSettings(const SEASettings &settings) override
     {
      m_magicConflict = false;
      m_magicEdit.Text(IntegerToString(SettingsMagic(settings)));
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      bool enabled = false;
      if(m_toggleCommand == UI_COMMAND_TOGGLE_MACROSS)
         enabled = settings.useMACross;
      else if(m_toggleCommand == UI_COMMAND_TOGGLE_RSI)
         enabled = settings.useRSI;
      else if(m_toggleCommand == UI_COMMAND_TOGGLE_BB)
         enabled = settings.useBollinger;
      FusionApplyToggleButtonStyle(m_toggle, enabled, editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);
      RefreshMagicStyle(editable);
     }

   virtual bool      ApplyInputs(SEASettings &settings) override
     {
      int magicNumber = 0;
      bool valid = ParseMagic(magicNumber);
      if(valid)
         SetSettingsMagic(settings, magicNumber);
      RefreshMagicStyle(true);
      return valid;
     }

   virtual bool      HasPendingChanges(const SEASettings &settings) override
     {
      int magicNumber = 0;
      if(!ParseMagic(magicNumber))
         return true;
      return (magicNumber != SettingsMagic(settings));
     }

   virtual void      SetMagicConflict(const bool conflict,const bool editable) override
     {
      m_magicConflict = conflict;
      RefreshMagicStyle(editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = m_toggleCommand;
      return true;
     }
  };

#endif
