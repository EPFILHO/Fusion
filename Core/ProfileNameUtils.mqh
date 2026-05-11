#ifndef __FUSION_PROFILE_NAME_UTILS_MQH__
#define __FUSION_PROFILE_NAME_UTILS_MQH__

string FusionSanitizeProfileName(const string value)
  {
   string safe = value;
   string invalid = "\\/:*?\"<>| ";
   for(int i = 0; i < StringLen(invalid); ++i)
     {
      string token = StringSubstr(invalid, i, 1);
      StringReplace(safe, token, "_");
     }
   return safe;
  }

#endif
