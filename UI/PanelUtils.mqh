#ifndef __FUSION_PANEL_UTILS_MQH__
#define __FUSION_PANEL_UTILS_MQH__

#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\Panel.mqh>
#include "../Core/Types.mqh"

#define FUSION_CLR_BG            C'34,40,52'
#define FUSION_CLR_PANEL         C'47,56,72'
#define FUSION_CLR_BORDER        C'83,101,133'
#define FUSION_CLR_LABEL         C'70,82,103'
#define FUSION_CLR_MUTED         C'114,125,144'
#define FUSION_CLR_VALUE         C'33,43,59'
#define FUSION_CLR_TITLE         C'26,34,48'
#define FUSION_CLR_ACCENT        C'33,150,243'
#define FUSION_CLR_ACCENT_DARK   C'19,113,188'
#define FUSION_CLR_GOOD          C'35,155,86'
#define FUSION_CLR_BAD           C'183,62,62'
#define FUSION_CLR_WARN          C'214,149,33'
#define FUSION_CLR_NAV_IDLE      C'47,56,72'
#define FUSION_CLR_NAV_ACTIVE    C'43,144,234'
#define FUSION_CLR_ACTION_SAVE   C'31,84,141'
#define FUSION_CLR_ACTION_LOAD   C'43,128,214'
#define FUSION_CLR_DISABLED      C'155,164,178'
#define FUSION_CLR_DISABLED_TXT  C'228,232,238'
#define FUSION_CLR_FIELD_BG      clrWhite
#define FUSION_CLR_FIELD_DISABLED C'220,224,230'
#define FUSION_CLR_FIELD_BORDER  C'166,181,204'
#define FUSION_CLR_FIELD_ERROR   C'255,233,233'
#define FUSION_CLR_SUBTAB_LINE   FUSION_CLR_NAV_ACTIVE
#define FUSION_CLR_FRAME_BG      clrWhite
#define FUSION_CLR_FRAME_BORDER  FUSION_CLR_NAV_ACTIVE
#define FUSION_COMBO_LIST_ZORDER_OFFSET 1000
#define FUSION_COMBO_LIST_ITEM_LIMIT    32

string FusionTimeframeName(const ENUM_TIMEFRAMES timeframe)
  {
   switch(timeframe)
     {
      case PERIOD_M1:   return "M1";
      case PERIOD_M2:   return "M2";
      case PERIOD_M3:   return "M3";
      case PERIOD_M4:   return "M4";
      case PERIOD_M5:   return "M5";
      case PERIOD_M6:   return "M6";
      case PERIOD_M10:  return "M10";
      case PERIOD_M12:  return "M12";
      case PERIOD_M15:  return "M15";
      case PERIOD_M20:  return "M20";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H2:   return "H2";
      case PERIOD_H3:   return "H3";
      case PERIOD_H4:   return "H4";
      case PERIOD_H6:   return "H6";
      case PERIOD_H8:   return "H8";
      case PERIOD_H12:  return "H12";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
     }

   return EnumToString(timeframe);
  }

int FusionTimeframeCount(void)
  {
   return 21;
  }

ENUM_TIMEFRAMES FusionTimeframeAt(const int index)
  {
   switch(index)
     {
      case 0:  return PERIOD_M1;
      case 1:  return PERIOD_M2;
      case 2:  return PERIOD_M3;
      case 3:  return PERIOD_M4;
      case 4:  return PERIOD_M5;
      case 5:  return PERIOD_M6;
      case 6:  return PERIOD_M10;
      case 7:  return PERIOD_M12;
      case 8:  return PERIOD_M15;
      case 9:  return PERIOD_M20;
      case 10: return PERIOD_M30;
      case 11: return PERIOD_H1;
      case 12: return PERIOD_H2;
      case 13: return PERIOD_H3;
      case 14: return PERIOD_H4;
      case 15: return PERIOD_H6;
      case 16: return PERIOD_H8;
      case 17: return PERIOD_H12;
      case 18: return PERIOD_D1;
      case 19: return PERIOD_W1;
      case 20: return PERIOD_MN1;
     }

   return PERIOD_M15;
  }

bool FusionPopulateTimeframeCombo(CComboBox &combo)
  {
   combo.ListViewItems(10);
   for(int i = 0; i < FusionTimeframeCount(); ++i)
     {
      ENUM_TIMEFRAMES timeframe = FusionTimeframeAt(i);
      if(!combo.AddItem(FusionTimeframeName(timeframe), (long)timeframe))
         return false;
     }

   return true;
  }

string FusionMAMethodName(const ENUM_MA_METHOD method)
  {
   switch(method)
     {
      case MODE_SMA:  return "SMA";
      case MODE_EMA:  return "EMA";
      case MODE_SMMA: return "SMMA";
      case MODE_LWMA: return "LWMA";
     }
   return "EMA";
  }

bool FusionPopulateMAMethodCombo(CComboBox &combo)
  {
   combo.ListViewItems(6);
   if(!combo.AddItem(FusionMAMethodName(MODE_SMA), (long)MODE_SMA))
      return false;
   if(!combo.AddItem(FusionMAMethodName(MODE_EMA), (long)MODE_EMA))
      return false;
   if(!combo.AddItem(FusionMAMethodName(MODE_SMMA), (long)MODE_SMMA))
      return false;
   if(!combo.AddItem(FusionMAMethodName(MODE_LWMA), (long)MODE_LWMA))
      return false;
   return true;
  }

string FusionAppliedPriceName(const ENUM_APPLIED_PRICE price)
  {
   switch(price)
     {
      case PRICE_CLOSE:    return "Close";
      case PRICE_OPEN:     return "Open";
      case PRICE_HIGH:     return "High";
      case PRICE_LOW:      return "Low";
      case PRICE_MEDIAN:   return "Median";
      case PRICE_TYPICAL:  return "Typical";
      case PRICE_WEIGHTED: return "Weighted";
     }
   return "Close";
  }

bool FusionPopulateAppliedPriceCombo(CComboBox &combo)
  {
   combo.ListViewItems(8);
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_CLOSE), (long)PRICE_CLOSE))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_OPEN), (long)PRICE_OPEN))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_HIGH), (long)PRICE_HIGH))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_LOW), (long)PRICE_LOW))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_MEDIAN), (long)PRICE_MEDIAN))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_TYPICAL), (long)PRICE_TYPICAL))
      return false;
   if(!combo.AddItem(FusionAppliedPriceName(PRICE_WEIGHTED), (long)PRICE_WEIGHTED))
      return false;
   return true;
  }

string FusionEntryModeName(const ENUM_ENTRY_MODE mode)
  {
   return (mode == ENTRY_2ND_CANDLE) ? "2o candle (E2C)" : "1o candle apos cruz.";
  }

bool FusionPopulateEntryModeCombo(CComboBox &combo)
  {
   combo.ListViewItems(4);
   if(!combo.AddItem(FusionEntryModeName(ENTRY_NEXT_CANDLE), (long)ENTRY_NEXT_CANDLE))
      return false;
   if(!combo.AddItem(FusionEntryModeName(ENTRY_2ND_CANDLE), (long)ENTRY_2ND_CANDLE))
      return false;
   return true;
  }

string FusionExitModeName(const ENUM_EXIT_MODE mode)
  {
   return (mode == EXIT_TP_SL) ? "TP/SL" : "Cruz. oposto";
  }

bool FusionPopulateExitModeCombo(CComboBox &combo)
  {
   combo.ListViewItems(4);
   if(!combo.AddItem(FusionExitModeName(EXIT_TP_SL), (long)EXIT_TP_SL))
      return false;
   if(!combo.AddItem(FusionExitModeName(EXIT_OPPOSITE_SIGNAL), (long)EXIT_OPPOSITE_SIGNAL))
      return false;
   return true;
  }

string FusionConflictText(const ENUM_CONFLICT_RESOLUTION mode)
  {
   return (mode == CONFLICT_PRIORITY) ? "PRIORITY" : "CANCEL";
  }

string FusionTrimCopy(const string text)
  {
   int start = 0;
   int end = StringLen(text) - 1;

   while(start <= end)
     {
      ushort ch = StringGetCharacter(text, start);
      if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
         break;
      start++;
     }

   while(end >= start)
     {
      ushort ch = StringGetCharacter(text, end);
      if(ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
         break;
      end--;
     }

   if(end < start)
      return "";
   return StringSubstr(text, start, end - start + 1);
  }

bool FusionIsBlank(const string text)
  {
   return FusionTrimCopy(text) == "";
  }

bool FusionIsIntegerText(const string text,const bool allowZero=true)
  {
   string trimmed = FusionTrimCopy(text);
   if(trimmed == "")
      return false;

   int start = 0;
   if(StringGetCharacter(trimmed, 0) == '+')
      start = 1;
   else if(StringGetCharacter(trimmed, 0) == '-')
      return false;

   if(start >= StringLen(trimmed))
      return false;

   for(int i = start; i < StringLen(trimmed); ++i)
     {
      ushort ch = StringGetCharacter(trimmed, i);
      if(ch < '0' || ch > '9')
         return false;
     }

   if(!allowZero && StringToInteger(trimmed) == 0)
      return false;
   return true;
  }

string FusionNormalizeDecimalText(const string text)
  {
   string normalized = FusionTrimCopy(text);
   StringReplace(normalized, ",", ".");
   return normalized;
  }

int FusionVolumeDigits(const double step)
  {
   double value = step;
   int digits = 0;

   while(digits < 8 && MathAbs(value - MathRound(value)) > 0.0000001)
     {
      value *= 10.0;
      digits++;
     }

   return digits;
  }

bool FusionIsVolumeAligned(const double volume,const SSymbolSpec &spec)
  {
   if(spec.volumeStep <= 0.0)
      return true;

   double steps = volume / spec.volumeStep;
   return MathAbs(steps - MathRound(steps)) <= 0.0000001;
  }

string FusionFormatVolume(const double volume,const SSymbolSpec &spec)
  {
   int digits = FusionVolumeDigits(spec.volumeStep);
   if(digits < 2)
      digits = 2;
   return DoubleToString(volume, digits);
  }

bool FusionIsDecimalText(const string text,const bool allowZero=true)
  {
   string trimmed = FusionNormalizeDecimalText(text);
   if(trimmed == "")
      return false;

   bool hasSeparator = false;
   int start = 0;
   if(StringGetCharacter(trimmed, 0) == '+')
      start = 1;
   else if(StringGetCharacter(trimmed, 0) == '-')
      return false;

   if(start >= StringLen(trimmed))
      return false;

   for(int i = start; i < StringLen(trimmed); ++i)
     {
      ushort ch = StringGetCharacter(trimmed, i);
      if(ch == '.' || ch == ',')
        {
         if(hasSeparator)
            return false;
         hasSeparator = true;
         continue;
        }
      if(ch < '0' || ch > '9')
         return false;
     }

   double value = StringToDouble(trimmed);
   if(!allowZero && value <= 0.0)
      return false;
   return true;
  }

void FusionApplyActionButtonStyle(CButton &button,const color bg,const bool enabled=true)
  {
   button.Color(enabled ? clrWhite : FUSION_CLR_DISABLED_TXT);
   button.ColorBackground(enabled ? bg : FUSION_CLR_DISABLED);
  }

void FusionApplyNeutralButtonStyle(CButton &button)
  {
   FusionApplyActionButtonStyle(button, FUSION_CLR_DISABLED, false);
  }

void FusionApplyBlockedButtonStyle(CButton &button)
  {
   FusionApplyActionButtonStyle(button, FUSION_CLR_BAD, true);
  }

void FusionApplyPrimaryButtonStyle(CButton &button,const bool active)
  {
   FusionApplyActionButtonStyle(button, active ? FUSION_CLR_NAV_ACTIVE : FUSION_CLR_NAV_IDLE, true);
  }

void FusionApplyToggleButtonStyle(CButton &button,const bool enabled,const bool editable=true)
  {
   button.Text(enabled ? "ON" : "OFF");
   if(!editable)
      FusionApplyNeutralButtonStyle(button);
   else
      FusionApplyActionButtonStyle(button, enabled ? FUSION_CLR_GOOD : FUSION_CLR_BAD, true);
  }

void FusionApplyStateLabel(CLabel &label,const bool enabled,const string enabledText,const string disabledText)
  {
   label.Text(enabled ? enabledText : disabledText);
   label.Color(enabled ? FUSION_CLR_GOOD : FUSION_CLR_BAD);
   label.FontSize(9);
  }

void FusionApplyEditStyle(CEdit &edit,const bool valid,const bool enabled=true)
  {
   edit.ReadOnly(!enabled);
   if(!enabled)
     {
      edit.Color(FUSION_CLR_MUTED);
      edit.ColorBackground(FUSION_CLR_FIELD_DISABLED);
      edit.ColorBorder(FUSION_CLR_DISABLED);
      return;
     }

   edit.Color(clrBlack);
   edit.ColorBackground(valid ? FUSION_CLR_FIELD_BG : FUSION_CLR_FIELD_ERROR);
   edit.ColorBorder(valid ? FUSION_CLR_FIELD_BORDER : FUSION_CLR_BAD);
  }

void FusionApplyLabelEnabled(CLabel &label,const bool enabled)
  {
   label.Color(enabled ? FUSION_CLR_LABEL : FUSION_CLR_MUTED);
  }

void FusionSetObjectTimeframesIfExists(const long chartId,const string name,const long timeframes)
  {
   if(name == "" || ObjectFind(chartId, name) < 0)
      return;
   ObjectSetInteger(chartId, name, OBJPROP_TIMEFRAMES, timeframes);
  }

void FusionSetObjectZOrderIfExists(const long chartId,const string name,const long zorder)
  {
   if(name == "" || ObjectFind(chartId, name) < 0)
      return;
   ObjectSetInteger(chartId, name, OBJPROP_ZORDER, zorder);
  }

void FusionResetComboRuntimeObjects(const long chartId,const string comboName)
  {
   if(comboName == "")
      return;

   if(ObjectFind(chartId, comboName + "Drop") >= 0)
      ObjectSetInteger(chartId, comboName + "Drop", OBJPROP_STATE, false);

   FusionSetObjectTimeframesIfExists(chartId, comboName + "List", OBJ_NO_PERIODS);
   FusionSetObjectTimeframesIfExists(chartId, comboName + "ListBack", OBJ_NO_PERIODS);
   FusionSetObjectTimeframesIfExists(chartId, comboName + "ListVScroll", OBJ_NO_PERIODS);
   FusionSetObjectTimeframesIfExists(chartId, comboName + "ListHScroll", OBJ_NO_PERIODS);
   for(int i = 0; i < FUSION_COMBO_LIST_ITEM_LIMIT; ++i)
      FusionSetObjectTimeframesIfExists(chartId, comboName + "ListItem" + IntegerToString(i), OBJ_NO_PERIODS);
  }

void FusionRaiseComboRuntimeObjects(const long chartId,const string comboName,const long zorder)
  {
   if(comboName == "")
      return;

   FusionSetObjectZOrderIfExists(chartId, comboName + "Edit", zorder);
   FusionSetObjectZOrderIfExists(chartId, comboName + "Drop", zorder + 1);

   long listZOrder = zorder + FUSION_COMBO_LIST_ZORDER_OFFSET;
   FusionSetObjectZOrderIfExists(chartId, comboName + "List", listZOrder);
   FusionSetObjectZOrderIfExists(chartId, comboName + "ListBack", listZOrder);
   FusionSetObjectZOrderIfExists(chartId, comboName + "ListVScroll", listZOrder + 2);
   FusionSetObjectZOrderIfExists(chartId, comboName + "ListHScroll", listZOrder + 2);
   for(int i = 0; i < FUSION_COMBO_LIST_ITEM_LIMIT; ++i)
      FusionSetObjectZOrderIfExists(chartId, comboName + "ListItem" + IntegerToString(i), listZOrder + 1);
  }

#endif
