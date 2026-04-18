#ifndef __MODULAR_EA_UI_PANEL_MQH__
#define __MODULAR_EA_UI_PANEL_MQH__

#include "../Core/Types.mqh"

class CUIPanel
  {
private:
   long   m_chartId;
   string m_prefix;
   bool   m_created;

   string Name(const string suffix) const
     {
      return m_prefix + suffix;
     }

   bool   CreateLabel(const string suffix,const int x,const int y,const string text,const color clr)
     {
      string name = Name(suffix);
      ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, 10);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
      return true;
     }

   bool   CreateButton(const string suffix,const int x,const int y,const int width,const int height,const string text,const color bgColor)
     {
      string name = Name(suffix);
      ObjectCreate(m_chartId, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrWhite);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
      return true;
     }

   bool   CreateEdit(const string suffix,const int x,const int y,const int width,const int height,const string text)
     {
      string name = Name(suffix);
      ObjectCreate(m_chartId, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrBlack);
      ObjectSetString(m_chartId, name, OBJPROP_TEXT, text);
      return true;
     }

   void   DeleteObject(const string suffix)
     {
      ObjectDelete(m_chartId, Name(suffix));
     }

public:
            CUIPanel(void)
     {
      m_chartId = 0;
      m_prefix  = "ModularEA_";
      m_created = false;
     }

   bool     Create(const long chartId,const SUIPanelSnapshot &snapshot)
     {
      m_chartId = chartId;
      m_created = true;

      ObjectCreate(m_chartId, Name("bg"), OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_XSIZE, 280);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_YSIZE, 260);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_BGCOLOR, clrDimGray);
      ObjectSetInteger(m_chartId, Name("bg"), OBJPROP_COLOR, clrGainsboro);

      CreateLabel("title", 20, 28, "ModularEA Control", clrWhite);
      CreateLabel("status", 20, 50, "", clrWhite);
      CreateLabel("counts", 20, 70, "", clrWhite);
      CreateLabel("profile_label", 20, 95, "Profile", clrWhite);
      CreateEdit("profile_edit", 20, 112, 170, 22, snapshot.activeProfileName);
      CreateButton("btn_save", 200, 112, 35, 22, "S", clrSeaGreen);
      CreateButton("btn_load", 240, 112, 35, 22, "L", clrSteelBlue);
      CreateButton("btn_run", 20, 145, 255, 24, "", clrSeaGreen);
      CreateButton("btn_ma", 20, 178, 120, 24, "", clrTeal);
      CreateButton("btn_rsi", 155, 178, 120, 24, "", clrTeal);
      CreateButton("btn_bb", 20, 208, 120, 24, "", clrTeal);
      CreateButton("btn_trend", 155, 208, 120, 24, "", clrSlateBlue);
      CreateButton("btn_rsi_filter", 20, 238, 255, 24, "", clrSlateBlue);

      Update(snapshot);
      return true;
     }

   void     Destroy(void)
     {
      if(!m_created)
         return;

      DeleteObject("bg");
      DeleteObject("title");
      DeleteObject("status");
      DeleteObject("counts");
      DeleteObject("profile_label");
      DeleteObject("profile_edit");
      DeleteObject("btn_save");
      DeleteObject("btn_load");
      DeleteObject("btn_run");
      DeleteObject("btn_ma");
      DeleteObject("btn_rsi");
      DeleteObject("btn_bb");
      DeleteObject("btn_trend");
      DeleteObject("btn_rsi_filter");
      m_created = false;
     }

   void     Update(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created)
         return;

      ObjectSetString(m_chartId, Name("status"), OBJPROP_TEXT,
                      snapshot.started ? "Status: RUNNING" : "Status: PAUSED");
      ObjectSetString(m_chartId, Name("counts"), OBJPROP_TEXT,
                      "Strategies: " + IntegerToString(snapshot.activeStrategies) +
                      " | Filters: " + IntegerToString(snapshot.activeFilters));
      ObjectSetString(m_chartId, Name("btn_run"), OBJPROP_TEXT,
                      snapshot.started ? "Pause EA" : "Start EA");
      ObjectSetInteger(m_chartId, Name("btn_run"), OBJPROP_BGCOLOR,
                       snapshot.started ? clrDarkOrange : clrSeaGreen);
      ObjectSetString(m_chartId, Name("btn_ma"), OBJPROP_TEXT,
                      "MA Cross: " + (snapshot.useMACross ? "ON" : "OFF"));
      ObjectSetString(m_chartId, Name("btn_rsi"), OBJPROP_TEXT,
                      "RSI: " + (snapshot.useRSI ? "ON" : "OFF"));
      ObjectSetString(m_chartId, Name("btn_bb"), OBJPROP_TEXT,
                      "Bollinger: " + (snapshot.useBollinger ? "ON" : "OFF"));
      ObjectSetString(m_chartId, Name("btn_trend"), OBJPROP_TEXT,
                      "Trend F: " + (snapshot.useTrendFilter ? "ON" : "OFF"));
      ObjectSetString(m_chartId, Name("btn_rsi_filter"), OBJPROP_TEXT,
                      "RSI Filter: " + (snapshot.useRSIFilter ? "ON" : "OFF"));
     }

   string   ProfileName(void) const
     {
      return ObjectGetString(m_chartId, Name("profile_edit"), OBJPROP_TEXT);
     }

   void     SetProfileName(const string profileName)
     {
      if(!m_created)
         return;
      ObjectSetString(m_chartId, Name("profile_edit"), OBJPROP_TEXT, profileName);
     }

   bool     HandleChartEvent(const int id,const string objectName,SUICommand &command)
     {
      command.type = UI_COMMAND_NONE;
      command.text = "";

      if(!m_created || id != CHARTEVENT_OBJECT_CLICK)
         return false;

      if(objectName == Name("btn_run")) command.type = UI_COMMAND_TOGGLE_RUNNING;
      else if(objectName == Name("btn_ma")) command.type = UI_COMMAND_TOGGLE_MACROSS;
      else if(objectName == Name("btn_rsi")) command.type = UI_COMMAND_TOGGLE_RSI;
      else if(objectName == Name("btn_bb")) command.type = UI_COMMAND_TOGGLE_BB;
      else if(objectName == Name("btn_trend")) command.type = UI_COMMAND_TOGGLE_TREND_FILTER;
      else if(objectName == Name("btn_rsi_filter")) command.type = UI_COMMAND_TOGGLE_RSI_FILTER;
      else if(objectName == Name("btn_save")) command.type = UI_COMMAND_SAVE_PROFILE;
      else if(objectName == Name("btn_load")) command.type = UI_COMMAND_LOAD_PROFILE;

      if(command.type == UI_COMMAND_NONE)
         return false;

      command.text = ProfileName();
      return true;
     }
  };

#endif

