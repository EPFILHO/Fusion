#ifndef __FUSION_FILTER_TIMEFRAME_PANEL_MQH__
#define __FUSION_FILTER_TIMEFRAME_PANEL_MQH__

#include "FilterPanelBase.mqh"
#include "TimeframeComboField.mqh"

enum ENUM_FUSION_FILTER_PANEL_KIND
  {
   FUSION_FILTER_PANEL_TREND = 0,
   FUSION_FILTER_PANEL_RSI
  };

class CFilterTimeframePanel : public CFilterPanelBase
  {
private:
   ENUM_FUSION_FILTER_PANEL_KIND m_kind;
   string                        m_title;
   string                        m_buttonName;
   string                        m_descriptionText;
   ENUM_UI_COMMAND               m_toggleCommand;
   CLabel                        m_header;
   CLabel                        m_description;
   CButton                       m_toggle;
   CTimeframeComboField          m_timeframe;

   bool              IsEnabled(const SEASettings &settings) const
     {
      if(m_toggleCommand == UI_COMMAND_TOGGLE_TREND_FILTER)
         return settings.useTrendFilter;
      return settings.useRSIFilter;
     }

   ENUM_TIMEFRAMES   SelectedTimeframe(const SEASettings &settings) const
     {
      if(m_kind == FUSION_FILTER_PANEL_TREND)
         return settings.trendMATimeframe;
      return settings.rsiFilterTimeframe;
     }

public:
                     CFilterTimeframePanel(const ENUM_FUSION_FILTER_PANEL_KIND kind,
                                           const string title,
                                           const string buttonName,
                                           const string descriptionText,
                                           const ENUM_UI_COMMAND toggleCommand)
     {
      m_kind            = kind;
      m_title           = title;
      m_buttonName      = buttonName;
      m_descriptionText = descriptionText;
      m_toggleCommand   = toggleCommand;
     }

   string            GetTitle(void) const { return m_title; }
   string            GetButtonName(void) const { return m_buttonName; }

   bool              Create(CFusionPanel *parent,const long chartId,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      string prefix = "Fusion_Filter_" + m_buttonName + "_";
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

      if(!m_timeframe.Create(parent,
                             chartId,
                             subwin,
                             prefix + "tf",
                             "Timeframe",
                             x1 + 134,
                             y1 + 60,
                             x1 + 236,
                             y1 + 78,
                             x1 + 244,
                             y1 + 56,
                             x1 + 374,
                             y1 + 80))
         return false;

      Hide();
      return true;
     }

   void              Show(void)
     {
      m_header.Show();
      m_description.Show();
      m_toggle.Show();
      m_timeframe.Show();
     }

   void              Hide(void)
     {
      m_header.Hide();
      m_description.Hide();
      m_toggle.Hide();
      m_timeframe.Hide();
     }

   void              Sync(const SEASettings &settings,const bool editable)
     {
      FusionApplyToggleButtonStyle(m_toggle, IsEnabled(settings), editable);
      m_description.Color(editable ? FUSION_CLR_MUTED : FUSION_CLR_DISABLED);
      m_timeframe.Sync(SelectedTimeframe(settings), editable);
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
      if(!m_timeframe.Matches(objectName))
         return false;

      ENUM_TIMEFRAMES timeframe = m_timeframe.Value();

      if(m_kind == FUSION_FILTER_PANEL_TREND)
        {
         if(settings.trendMATimeframe == timeframe)
            return false;
         settings.trendMATimeframe = timeframe;
         return true;
        }

      if(settings.rsiFilterTimeframe == timeframe)
         return false;
      settings.rsiFilterTimeframe = timeframe;
      return true;
     }

   bool              Validate(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";
      return true;
     }
  };

#endif
