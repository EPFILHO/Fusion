#ifndef __FUSION_SETTINGS_FILE_UTILS_MQH__
#define __FUSION_SETTINGS_FILE_UTILS_MQH__

#include "../../Core/ProfileNameUtils.mqh"

string FusionProfilesFolderRelative(void)
  {
   return "Fusion\\Profiles";
  }

string FusionChartStateFolderRelative(void)
  {
   return "Fusion\\ChartState";
  }

string FusionProfileFileName(const string profileName)
  {
   return FusionProfilesFolderRelative() + "\\" + FusionSanitizeProfileName(profileName) + ".cfg";
  }

string FusionChartStateFileName(const ulong chartId)
  {
   string chartKey = "chart_" + StringFormat("%I64u", chartId);
   return FusionChartStateFolderRelative() + "\\" + FusionSanitizeProfileName(chartKey) + ".state";
  }

void FusionSettingsEnsureFolders(void)
  {
   FolderCreate("Fusion");
   FolderCreate(FusionProfilesFolderRelative());
   FolderCreate(FusionChartStateFolderRelative());
  }

bool FusionSettingsParseLine(const string line,string &key,string &value)
  {
   int separator = StringFind(line, "=");
   if(separator < 0)
      return false;

   key   = StringSubstr(line, 0, separator);
   value = StringSubstr(line, separator + 1);
   return true;
  }

bool FusionSettingsWriteLine(const int handle,const string key,const string value)
  {
   return (FileWriteString(handle, key + "=" + value + "\r\n") > 0);
  }

#endif
