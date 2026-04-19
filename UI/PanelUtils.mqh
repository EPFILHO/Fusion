#ifndef __FUSION_PANEL_UTILS_MQH__
#define __FUSION_PANEL_UTILS_MQH__

#include <Controls\Button.mqh>
#include "../Core/Types.mqh"

#define FUSION_CLR_BG            C'34,40,52'
#define FUSION_CLR_PANEL         C'47,56,72'
#define FUSION_CLR_BORDER        C'83,101,133'
#define FUSION_CLR_LABEL         C'226,231,238'
#define FUSION_CLR_MUTED         C'163,174,189'
#define FUSION_CLR_VALUE         C'245,247,250'
#define FUSION_CLR_ACCENT        C'33,150,243'
#define FUSION_CLR_ACCENT_DARK   C'19,113,188'
#define FUSION_CLR_GOOD          C'35,155,86'
#define FUSION_CLR_BAD           C'183,62,62'
#define FUSION_CLR_WARN          C'214,149,33'

string FusionTimeframeName(const ENUM_TIMEFRAMES timeframe)
  {
   return EnumToString(timeframe);
  }

string FusionConflictText(const ENUM_CONFLICT_RESOLUTION mode)
  {
   return (mode == CONFLICT_PRIORITY) ? "PRIORITY" : "CANCEL";
  }

void FusionApplyPrimaryButtonStyle(CButton &button,const bool active)
  {
   button.Color(clrWhite);
   button.ColorBackground(active ? FUSION_CLR_ACCENT : FUSION_CLR_PANEL);
  }

void FusionApplyToggleButtonStyle(CButton &button,const bool enabled)
  {
   button.Text(enabled ? "ON" : "OFF");
   button.Color(clrWhite);
   button.ColorBackground(enabled ? FUSION_CLR_GOOD : FUSION_CLR_BAD);
  }

#endif
