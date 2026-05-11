#ifndef __FUSION_UI_PANEL_PROTECTION_INPUTS_MQH__
#define __FUSION_UI_PANEL_PROTECTION_INPUTS_MQH__

   bool                       AddTimeEdit(CEdit &edit,const string name,const int x1,const int y1,const string value)
     {
      if(!AddEdit(edit, name, x1, y1, x1 + 40, y1 + 24, value))
         return false;
      edit.TextAlign(ALIGN_CENTER);
      return true;
     }

   bool                       IsTimeEditObject(const string objectName,int &maxValue)
     {
      maxValue = -1;
      if(m_configProtectionCreated)
        {
         if(objectName == m_protectSessionStartHourEdit.Name() ||
            objectName == m_protectSessionEndHourEdit.Name())
           {
            maxValue = 23;
            return true;
           }
         if(objectName == m_protectSessionStartMinuteEdit.Name() ||
            objectName == m_protectSessionEndMinuteEdit.Name())
           {
            maxValue = 59;
            return true;
           }

         for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
           {
            if(objectName == m_protectNewsStartHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndHourEdit[newsIndex].Name())
              {
               maxValue = 23;
               return true;
              }
            if(objectName == m_protectNewsStartMinuteEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
              {
               maxValue = 59;
               return true;
              }
           }
        }

      return false;
     }

   string                     SanitizeTimeText(const string text,const int maxValue) const
     {
      string digits = "";
      string trimmed = FusionTrimCopy(text);
      for(int i = 0; i < StringLen(trimmed); ++i)
        {
         ushort ch = StringGetCharacter(trimmed, i);
         if(ch >= '0' && ch <= '9')
            digits += StringSubstr(trimmed, i, 1);
        }

      int value = 0;
      if(digits != "")
         value = (int)StringToInteger(digits);
      if(value < 0)
         value = 0;
      if(value > maxValue)
         value = maxValue;

      return StringFormat("%02d", value);
     }

   void                       NormalizeTimeEdit(CEdit &edit,const int maxValue)
     {
      edit.Text(SanitizeTimeText(LiveEditText(edit), maxValue));
     }

   string                     SanitizeIntegerText(const string text,const int fallback,const bool allowZero=true,const int maxDigits=0) const
     {
      string trimmed = FusionTrimCopy(text);
      string digits = "";
      for(int i = 0; i < StringLen(trimmed); ++i)
        {
         ushort ch = StringGetCharacter(trimmed, i);
         if(ch < '0' || ch > '9')
            continue;
         if(maxDigits > 0 && StringLen(digits) >= maxDigits)
            break;
         digits += StringSubstr(trimmed, i, 1);
        }

      if(digits == "")
         return IntegerToString(fallback);

      int value = (int)StringToInteger(digits);
      if(!allowZero && value <= 0)
         value = fallback;
      return IntegerToString(value);
     }

   void                       NormalizeIntegerEdit(CEdit &edit,const int fallback,const bool allowZero=true,const int maxDigits=0)
     {
      edit.Text(SanitizeIntegerText(LiveEditText(edit), fallback, allowZero, maxDigits));
     }

   void                       NormalizeDecimalEdit(CEdit &edit,const double fallback,const int digits,const bool allowZero=true)
     {
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      double value = fallback;
      if(FusionIsDecimalText(text, allowZero))
        {
         value = StringToDouble(text);
         if(!allowZero && value <= 0.0)
            value = fallback;
        }
      edit.Text(DoubleToString(value, digits));
     }

   void                       NormalizeVolumeEdit(CEdit &edit,const double fallback)
     {
      string text = FusionNormalizeDecimalText(LiveEditText(edit));
      double value = fallback;
      if(FusionIsDecimalText(text, false))
        {
         value = StringToDouble(text);
         if(value <= 0.0)
            value = fallback;
        }
      edit.Text(FusionFormatVolume(value, m_snapshot.symbolSpec));
     }

   bool                       ProtectionTimeValue(const string text,const int maxValue,int &parsed) const
     {
      parsed = 0;
      if(!FusionIsIntegerText(text, true))
         return false;
      parsed = (int)StringToInteger(text);
      return (parsed >= 0 && parsed <= maxValue);
     }

   bool                       ProtectionMoneyValue(const string text,const bool allowZero,double &parsed) const
     {
      parsed = 0.0;
      if(!FusionIsDecimalText(text, allowZero))
         return false;
      parsed = StringToDouble(FusionNormalizeDecimalText(text));
      if(!allowZero && parsed <= 0.0)
         return false;
      return (parsed >= 0.0);
     }

   bool                       IsProtectionDeferredEdit(const string objectName)
     {
      if(m_configProtectionCreated)
        {
         if(objectName == m_protectSpreadLimitEdit.Name() ||
            objectName == m_protectSessionStartHourEdit.Name() ||
            objectName == m_protectSessionStartMinuteEdit.Name() ||
            objectName == m_protectSessionEndHourEdit.Name() ||
            objectName == m_protectSessionEndMinuteEdit.Name() ||
            objectName == m_protectDayTradesEdit.Name() ||
            objectName == m_protectDayLossEdit.Name() ||
            objectName == m_protectDayGainEdit.Name() ||
            objectName == m_protectDrawdownValueEdit.Name() ||
            objectName == m_protectStreakLossEdit.Name() ||
            objectName == m_protectStreakWinEdit.Name())
            return true;

         for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
           {
            if(objectName == m_protectNewsStartHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsStartMinuteEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndHourEdit[newsIndex].Name() ||
               objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
               return true;
           }
        }
      return false;
     }

   bool                       NormalizeProtectionDeferredEdit(const string objectName)
     {
      if(!m_configProtectionCreated)
         return false;

      int maxValue = -1;
      if(IsTimeEditObject(objectName, maxValue))
        {
         if(objectName == m_protectSessionStartHourEdit.Name())
            NormalizeTimeEdit(m_protectSessionStartHourEdit, maxValue);
         else if(objectName == m_protectSessionStartMinuteEdit.Name())
            NormalizeTimeEdit(m_protectSessionStartMinuteEdit, maxValue);
         else if(objectName == m_protectSessionEndHourEdit.Name())
            NormalizeTimeEdit(m_protectSessionEndHourEdit, maxValue);
         else if(objectName == m_protectSessionEndMinuteEdit.Name())
            NormalizeTimeEdit(m_protectSessionEndMinuteEdit, maxValue);
         else
           {
            for(int newsIndex = 0; newsIndex < FUSION_NEWS_WINDOW_COUNT; ++newsIndex)
              {
               if(objectName == m_protectNewsStartHourEdit[newsIndex].Name())
                  NormalizeTimeEdit(m_protectNewsStartHourEdit[newsIndex], maxValue);
               else if(objectName == m_protectNewsStartMinuteEdit[newsIndex].Name())
                  NormalizeTimeEdit(m_protectNewsStartMinuteEdit[newsIndex], maxValue);
               else if(objectName == m_protectNewsEndHourEdit[newsIndex].Name())
                  NormalizeTimeEdit(m_protectNewsEndHourEdit[newsIndex], maxValue);
               else if(objectName == m_protectNewsEndMinuteEdit[newsIndex].Name())
                  NormalizeTimeEdit(m_protectNewsEndMinuteEdit[newsIndex], maxValue);
               else
                  continue;
               return true;
              }
            return false;
           }

         return true;
        }

      if(objectName == m_protectSpreadLimitEdit.Name())
        {
         NormalizeIntegerEdit(m_protectSpreadLimitEdit, m_draftSettings.maxSpreadPoints, true);
         return true;
        }
      if(objectName == m_protectDayTradesEdit.Name())
        {
         NormalizeIntegerEdit(m_protectDayTradesEdit, m_draftSettings.maxDailyTrades, true);
         return true;
        }
      if(objectName == m_protectDayLossEdit.Name())
        {
         NormalizeDecimalEdit(m_protectDayLossEdit, m_draftSettings.maxDailyLoss, 2, true);
         return true;
        }
      if(objectName == m_protectDayGainEdit.Name())
        {
         NormalizeDecimalEdit(m_protectDayGainEdit, m_draftSettings.maxDailyGain, 2, true);
         return true;
        }
      if(objectName == m_protectDrawdownValueEdit.Name())
        {
         NormalizeDecimalEdit(m_protectDrawdownValueEdit, m_draftSettings.maxDrawdown, 2, true);
         return true;
        }
      if(objectName == m_protectStreakLossEdit.Name())
        {
         NormalizeIntegerEdit(m_protectStreakLossEdit, m_draftSettings.maxLossStreak, true);
         return true;
        }
      if(objectName == m_protectStreakWinEdit.Name())
        {
         NormalizeIntegerEdit(m_protectStreakWinEdit, m_draftSettings.maxWinStreak, true);
         return true;
        }

      return false;
     }

#endif
