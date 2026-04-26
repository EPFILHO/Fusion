#ifndef __FUSION_PROTECTION_TIME_UTILS_MQH__
#define __FUSION_PROTECTION_TIME_UTILS_MQH__

int FusionProtectionCurrentDayKey(const datetime value)
  {
   MqlDateTime parts;
   TimeToStruct(value, parts);
   return (parts.year * 1000) + parts.day_of_year;
  }

bool FusionProtectionIsInsideClockWindow(const int startHour,
                                         const int startMinute,
                                         const int endHour,
                                         const int endMinute,
                                         const datetime now)
  {
   MqlDateTime parts;
   TimeToStruct(now, parts);

   int currentMinutes = (parts.hour * 60) + parts.min;
   int startMinutes   = (startHour * 60) + startMinute;
   int endMinutes     = (endHour * 60) + endMinute;

   if(startMinutes <= endMinutes)
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);

   return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
  }

#endif
