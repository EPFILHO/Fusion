#ifndef __FUSION_STRATEGY_TIMEFRAME_PANEL_MQH__
#define __FUSION_STRATEGY_TIMEFRAME_PANEL_MQH__

#include "StrategyPanelBase.mqh"
#include "TimeframeComboField.mqh"

enum ENUM_FUSION_STRATEGY_PANEL_KIND
  {
   FUSION_STRATEGY_PANEL_MA = 0,
   FUSION_STRATEGY_PANEL_RSI,
   FUSION_STRATEGY_PANEL_BB
  };

class CStrategyTimeframePanel : public CStrategyPanelBase
  {
private:
   ENUM_FUSION_STRATEGY_PANEL_KIND m_kind;
   string                          m_title;
   string                          m_buttonName;
   string                          m_descriptionText;
   ENUM_UI_COMMAND                 m_toggleCommand;
   bool                            m_hasSecondaryTimeframe;
   CLabel                          m_header;
   CLabel                          m_description;
   CButton                         m_toggle;
   CTimeframeComboField            m_primaryTimeframe;
   CTimeframeComboField            m_secondaryTimeframe;

   bool              IsEnabled(const SEASettings &settings) const
     {
      if(m_toggleCommand == UI_COMMAND_TOGGLE_MACROSS)
         return settings.useMACross;
      if(m_toggleCommand == UI_COMMAND_TOGGLE_RSI)
         return settings.useRSI;
      return settings.useBollinger;
     }

   ENUM_TIMEFRAMES   PrimaryTimeframe(const SEASettings &settings) const
     {
      if(m_kind == FUSION_STRATEGY_PANEL_MA)
         return settings.maFastTimeframe;
      if(m_kind == FUSION_STRATEGY_PANEL_RSI)
         return settings.rsiTimeframe;
      return settings.bbTimeframe;
     }

   ENUM_TIMEFRAMES   SecondaryTimeframe(const SEASettings &settings) const
     {
      if(m_kind == FUSION_STRATEGY_PANEL_MA)
         return settings.maSlowTimeframe;
      return PERIOD_CURRENT;
     }

public:
                     CStrategyTimeframePanel(const ENUM_FUSION_STRATEGY_PANEL_KIND kind,
                                             const string title,
                                             const string buttonName,
                                             const string descriptionText,
                                             const ENUM_UI_COMMAND toggleCommand,
                                             const bool hasSecondaryTimeframe)
     {
      m_kind                  = kind;
      m_title                 = title;
      m_buttonName            = buttonName;
      m_descriptionText       = descriptionText;
      m_toggleCommand         = toggleCommand;
      m_hasSecondaryTimeframe = hasSecondaryTimeframe;
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
      m_description.Text(m_descriptionText);
      m_description.Color(FUSION_CLR_MUTED);
      m_description.FontSize(8);
      if(!parent.AddControl(m_description))
         return false;

      if(!m_toggle.Create(chartId, prefix + "toggle", subwin, x1, y1 + 56, x1 + 110, y1 + 80))
         return false;
      FusionApplyToggleButtonStyle(m_toggle, false);
      if(!parent.AddControl(m_toggle))
         return false;

      if(!m_primaryTimeframe.Create(parent,
                                    chartId,
                                    subwin,
                                    prefix + "primaryTf",
                                    m_hasSecondaryTimeframe ? "TF Rapido" : "Timeframe",
                                    x1 + 134,
                                    y1 + 60,
                                    x1 + 236,
                                    y1 + 78,
                                    x1 + 244,
                                    y1 + 56,
                                    x1 + 374,
                                    y1 + 80))
         return false;

      if(m_hasSecondaryTimeframe)
        {
         if(!m_secondaryTimeframe.Create(parent,
                                         chartId,
                                         subwin,
                                         prefix + "secondaryTf",
                                         "TF Lento",
                                         x1 + 134,
                                         y1 + 98,
                                         x1 + 236,
                                         y1 + 116,
                                         x1 + 244,
                                         y1 + 94,
                                         x1 + 374,
                                         y1 + 118))
            return false;
        }

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_primaryTimeframe.Show();
      if(m_hasSecondaryTimeframe)
         m_secondaryTimeframe.Show();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_primaryTimeframe.Hide();
      if(m_hasSecondaryTimeframe)
         m_secondaryTimeframe.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, IsEnabled(settings), editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);
      m_primaryTimeframe.Sync(PrimaryTimeframe(settings), editable);
      if(m_hasSecondaryTimeframe)
         m_secondaryTimeframe.Sync(SecondaryTimeframe(settings), editable);
     }

   bool              HandleClick(const string objectName,SUICommand &command)
     {
      if(objectName != m_toggle.Name())
         return false;
      command.type = m_toggleCommand;
      return true;
     }

   bool              HandleChange(const string objectName,SEASettings &settings)
     {
      if(m_primaryTimeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES timeframe = m_primaryTimeframe.Value();
         if(timeframe == PERIOD_CURRENT)
            return false;

         if(m_kind == FUSION_STRATEGY_PANEL_MA)
           {
            if(settings.maFastTimeframe == timeframe)
               return false;
            settings.maFastTimeframe = timeframe;
            return true;
           }
         if(m_kind == FUSION_STRATEGY_PANEL_RSI)
           {
            if(settings.rsiTimeframe == timeframe)
               return false;
            settings.rsiTimeframe = timeframe;
            return true;
           }
         if(settings.bbTimeframe == timeframe)
            return false;
         settings.bbTimeframe = timeframe;
         return true;
        }

      if(m_hasSecondaryTimeframe && m_secondaryTimeframe.Matches(objectName))
        {
         ENUM_TIMEFRAMES timeframe = m_secondaryTimeframe.Value();
         if(timeframe == PERIOD_CURRENT || settings.maSlowTimeframe == timeframe)
            return false;
         settings.maSlowTimeframe = timeframe;
         return true;
        }

      return false;
     }
  };

#endif
