#ifndef __FUSION_INDICATOR_LEGEND_OVERLAY_MQH__
#define __FUSION_INDICATOR_LEGEND_OVERLAY_MQH__

#define FUSION_LEGEND_WIDTH  230
#define FUSION_LEGEND_HEIGHT 112
#define FUSION_LEGEND_RIGHT  20
#define FUSION_LEGEND_TOP    40

class CIndicatorLegendOverlay
  {
private:
   long m_chartId;
   bool m_created;
   int  m_left;
   int  m_top;

   string ObjectName(const string role) const
     {
      return "Fusion_indicator_legend_" + role + "_" + StringFormat("%I64d", m_chartId);
     }

   bool CreateBackground(void)
     {
      string name = ObjectName("background");
      ObjectDelete(m_chartId, name);
      if(!ObjectCreate(m_chartId, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;

      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top);
      ObjectSetInteger(m_chartId, name, OBJPROP_XSIZE, FUSION_LEGEND_WIDTH);
      ObjectSetInteger(m_chartId, name, OBJPROP_YSIZE, FUSION_LEGEND_HEIGHT);
      ObjectSetInteger(m_chartId, name, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(m_chartId, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chartId, name, OBJPROP_BACK, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, name, OBJPROP_ZORDER, 100);
      return true;
     }

   bool CreateLabel(const string role,const int top,const color textColor,const int fontSize)
     {
      string name = ObjectName(role);
      ObjectDelete(m_chartId, name);
      if(!ObjectCreate(m_chartId, name, OBJ_LABEL, 0, 0, 0))
         return false;

      ObjectSetInteger(m_chartId, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left + 12);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top + top);
      ObjectSetInteger(m_chartId, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(m_chartId, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(m_chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(m_chartId, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(m_chartId, name, OBJPROP_ZORDER, 101);
      ObjectSetString(m_chartId, name, OBJPROP_FONT, "Arial");
      return true;
     }

   void PositionLabel(const string role,const int top)
     {
      string name = ObjectName(role);
      ObjectSetInteger(m_chartId, name, OBJPROP_XDISTANCE, m_left + 12);
      ObjectSetInteger(m_chartId, name, OBJPROP_YDISTANCE, m_top + top);
     }

   void Layout(void)
     {
      string background = ObjectName("background");
      ObjectSetInteger(m_chartId, background, OBJPROP_XDISTANCE, m_left);
      ObjectSetInteger(m_chartId, background, OBJPROP_YDISTANCE, m_top);
      PositionLabel("title", 8);
      PositionLabel("fast", 32);
      PositionLabel("slow", 56);
      PositionLabel("trend", 80);
     }

   void AlignUpperRight(void)
     {
      int chartWidth = (int)ChartGetInteger(m_chartId, CHART_WIDTH_IN_PIXELS);
      m_left = MathMax(0, chartWidth - FUSION_LEGEND_WIDTH - FUSION_LEGEND_RIGHT);
      m_top = FUSION_LEGEND_TOP;
      Layout();
     }

public:
          CIndicatorLegendOverlay(void)
     {
      m_chartId = 0;
      m_created = false;
      m_left = 0;
      m_top = 0;
     }

         ~CIndicatorLegendOverlay(void)
     {
      Destroy(REASON_REMOVE);
     }

   bool   IsCreated(void)
     {
      if(!m_created)
         return false;
      if(ObjectFind(m_chartId, ObjectName("background")) >= 0)
         return true;
      m_created = false;
      return false;
     }

   bool   CreateLegend(const long chartId,const int left,const int top)
     {
      m_chartId = chartId;
      m_left = left;
      m_top = top;

      if(!CreateBackground() ||
         !CreateLabel("title", 8, clrWhite, 9) ||
         !CreateLabel("fast", 32, clrLime, 8) ||
         !CreateLabel("slow", 56, clrRed, 8) ||
         !CreateLabel("trend", 80, clrMagenta, 8))
        {
         Destroy(REASON_REMOVE);
         return false;
        }

      ObjectSetString(m_chartId, ObjectName("title"), OBJPROP_TEXT, "Legenda Medias");
      m_created = true;
      AlignUpperRight();
      return true;
     }

   bool   StartDialog(void)
     {
      ChartRedraw(m_chartId);
      return m_created;
     }

   void   Update(const string fastText,
                 const string slowText,
                 const string trendText)
     {
      if(!IsCreated())
         return;
      ObjectSetString(m_chartId, ObjectName("fast"), OBJPROP_TEXT, fastText);
      ObjectSetString(m_chartId, ObjectName("slow"), OBJPROP_TEXT, slowText);
      ObjectSetString(m_chartId, ObjectName("trend"), OBJPROP_TEXT, trendText);
     }

   void   ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_created || id != CHARTEVENT_CHART_CHANGE)
         return;
      AlignUpperRight();
      ChartRedraw(m_chartId);
     }

   void   Destroy(const int reason=REASON_REMOVE)
     {
      ObjectDelete(m_chartId, ObjectName("title"));
      ObjectDelete(m_chartId, ObjectName("fast"));
      ObjectDelete(m_chartId, ObjectName("slow"));
      ObjectDelete(m_chartId, ObjectName("trend"));
      ObjectDelete(m_chartId, ObjectName("background"));
      m_created = false;
     }
  };

#endif
