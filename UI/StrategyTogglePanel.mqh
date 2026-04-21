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

public:
                     CStrategyTogglePanel(const string title,const string buttonName,const ENUM_UI_COMMAND toggleCommand)
     {
      m_title         = title;
      m_buttonName    = buttonName;
      m_toggleCommand = toggleCommand;
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

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
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
