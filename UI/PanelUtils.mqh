#ifndef __FUSION_PANEL_UTILS_MQH__
#define __FUSION_PANEL_UTILS_MQH__

#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
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
#define FUSION_CLR_FIELD_BORDER  C'166,181,204'
#define FUSION_CLR_FIELD_ERROR   C'255,233,233'

string FusionTimeframeName(const ENUM_TIMEFRAMES timeframe)
  {
   return EnumToString(timeframe);
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

void FusionApplyToggleButtonStyle(CButton &button,const bool enabled)
  {
   button.Text(enabled ? "ON" : "OFF");
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
   edit.Color(clrBlack);
   edit.ColorBackground(valid ? FUSION_CLR_FIELD_BG : FUSION_CLR_FIELD_ERROR);
   edit.ColorBorder(valid ? FUSION_CLR_FIELD_BORDER : FUSION_CLR_BAD);
  }

void FusionApplyLabelEnabled(CLabel &label,const bool enabled)
  {
   label.Color(enabled ? FUSION_CLR_LABEL : FUSION_CLR_MUTED);
  }

#endif
