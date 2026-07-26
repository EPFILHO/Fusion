#ifndef __FUSION_PROFILE_STORE_MQH__
#define __FUSION_PROFILE_STORE_MQH__

#include "../../Core/Types.mqh"
#include "../../Core/ProfileNameUtils.mqh"
#include "SettingsFileUtils.mqh"
#include "ProfileSettingsSerializer.mqh"

bool FusionProfileExists(const string profileName)
  {
   FusionSettingsEnsureFolders();
   string fileName = FusionProfileFileName(profileName);
   return FileIsExist(fileName);
  }

bool FusionFindProfileByMagicNumber(const int magicNumber,const string exceptProfileName,string &foundProfileName)
  {
   foundProfileName = "";
   if(magicNumber <= 0)
      return false;

   string profiles[];
   if(!FusionListProfiles(profiles))
      return false;

   string exceptSafe = FusionSanitizeProfileName(exceptProfileName);
   for(int i = 0; i < ArraySize(profiles); ++i)
     {
      if(FusionSanitizeProfileName(profiles[i]) == exceptSafe)
         continue;

      SEASettings settings;
      if(!FusionLoadProfile(profiles[i], settings))
         continue;

      if(settings.magicNumber == magicNumber)
        {
         foundProfileName = profiles[i];
         return true;
        }
     }

   return false;
  }

bool FusionListProfiles(string &profiles[])
  {
   FusionSettingsEnsureFolders();
   ArrayResize(profiles, 0);

   string fileName = "";
   long handle = FileFindFirst(FusionProfilesFolderRelative() + "\\*.cfg", fileName);
   if(handle == INVALID_HANDLE)
      return true;

   do
     {
      string profileName = fileName;
      int slash = StringFind(profileName, "\\");
      while(slash >= 0)
        {
         profileName = StringSubstr(profileName, slash + 1);
         slash = StringFind(profileName, "\\");
        }

      int len = StringLen(profileName);
      if(len > 4 && StringSubstr(profileName, len - 4) == ".cfg")
         profileName = StringSubstr(profileName, 0, len - 4);

      if(profileName != "")
        {
         int count = ArraySize(profiles);
         ArrayResize(profiles, count + 1);
         profiles[count] = profileName;
        }
     }
   while(FileFindNext(handle, fileName));

   FileFindClose(handle);

   int count = ArraySize(profiles);
   for(int i = 0; i < count - 1; ++i)
     {
      for(int j = i + 1; j < count; ++j)
        {
         if(StringCompare(profiles[j], profiles[i]) < 0)
           {
            string tmp = profiles[i];
            profiles[i] = profiles[j];
            profiles[j] = tmp;
           }
        }
     }

   return true;
  }

bool FusionSaveProfile(const string profileName,const SEASettings &settings)
  {
   FusionSettingsEnsureFolders();

   string fileName = FusionProfileFileName(profileName);
   string tempFileName = fileName + ".tmp";
   FileDelete(tempFileName);
   int handle = FileOpen(tempFileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return false;

   bool ok = FusionSaveSettingsBlock(handle, settings);
   FileFlush(handle);
   FileClose(handle);
   if(!ok)
     {
      FileDelete(tempFileName);
      return false;
     }

   if(!FileMove(tempFileName, 0, fileName, FILE_REWRITE))
     {
      FileDelete(tempFileName);
      return false;
     }
   return true;
  }

bool FusionDeleteProfile(const string profileName)
  {
   FusionSettingsEnsureFolders();
   string fileName = FusionProfileFileName(profileName);
   if(!FileIsExist(fileName))
      return false;
   return FileDelete(fileName);
  }

bool FusionLoadProfile(const string profileName,SEASettings &settings)
  {
   FusionSettingsEnsureFolders();
   SEASettings candidate;
   SetDefaultSettings(candidate);

   string fileName = FusionProfileFileName(profileName);
   int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return false;

   int settingLineCount = 0;
   bool seenSchema = false;
   bool seenMagic = false;
   bool seenFixedLot = false;
   bool seenMA = false;
   bool seenRSI = false;
   bool seenBB = false;
   bool seenTrend = false;
   bool seenRSIFilter = false;
   bool seenBBFilter = false;
   bool seenLegacyTail = false;
   bool seenCurrentTail = false;

   while(!FileIsEnding(handle))
     {
      string line = FileReadString(handle);
      string key = "";
      string value = "";
      if(!FusionSettingsParseLine(line, key, value))
         continue;

      settingLineCount++;
      if(key == "schemaVersion") seenSchema = true;
      else if(key == "magicNumber") seenMagic = true;
      else if(key == "fixedLot") seenFixedLot = true;
      else if(key == "useMACross") seenMA = true;
      else if(key == "useRSI") seenRSI = true;
      else if(key == "useBollinger") seenBB = true;
      else if(key == "useTrendFilter") seenTrend = true;
      else if(key == "useRSIFilter") seenRSIFilter = true;
      else if(key == "bbFilterEnabled") seenBBFilter = true;
      else if(key == "bbFilterMinWidthPercent") seenLegacyTail = true;
      else if(key == "bbFilterMinSlopePoints") seenCurrentTail = true;
      FusionApplySetting(key, value, candidate);
     }

   FileClose(handle);
   if(!FusionProfileHasRequiredFields(candidate.schemaVersion,
                                      settingLineCount,
                                      seenSchema,
                                      seenMagic,
                                      seenFixedLot,
                                      seenMA,
                                      seenRSI,
                                      seenBB,
                                      seenTrend,
                                      seenRSIFilter,
                                      seenBBFilter,
                                      seenLegacyTail,
                                      seenCurrentTail))
      return false;

   FusionNormalizeProtectionSettings(candidate);
   FusionNormalizeStreakSettings(candidate);
   FusionNormalizeRiskSettings(candidate);
   FusionNormalizeTrendSettings(candidate);
   FusionNormalizeVisualSettings(candidate);
   candidate.schemaVersion = FUSION_SETTINGS_SCHEMA_VERSION;
   settings = candidate;
   return true;
  }

#endif
