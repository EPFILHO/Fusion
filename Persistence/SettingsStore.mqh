#ifndef __FUSION_SETTINGS_STORE_MQH__
#define __FUSION_SETTINGS_STORE_MQH__

#include "../Core/Types.mqh"
#include "../Core/ProfileNameUtils.mqh"
#include "Modules/SettingsFileUtils.mqh"
#include "Modules/ProfileSettingsSerializer.mqh"
#include "Modules/ChartStateSerializer.mqh"
#include "Modules/ProfileStore.mqh"
#include "Modules/ChartStateStore.mqh"

class CSettingsStore
  {
public:
   string            ProfilesFolderPath(void) const
     {
      FusionSettingsEnsureFolders();
      return TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + FusionProfilesFolderRelative();
     }

   string            SanitizeProfileName(const string profileName) const
     {
      return FusionSanitizeProfileName(profileName);
     }

   bool              ProfileExists(const string profileName) const
     {
      return FusionProfileExists(profileName);
     }

   bool              FindProfileByMagicNumber(const int magicNumber,const string exceptProfileName,string &foundProfileName) const
     {
      return FusionFindProfileByMagicNumber(magicNumber, exceptProfileName, foundProfileName);
     }

   bool              ListProfiles(string &profiles[]) const
     {
      return FusionListProfiles(profiles);
     }

   bool              SaveProfile(const string profileName,const SEASettings &settings)
     {
      return FusionSaveProfile(profileName, settings);
     }

   bool              DeleteProfile(const string profileName)
     {
      return FusionDeleteProfile(profileName);
     }

   bool              LoadProfile(const string profileName,SEASettings &settings) const
     {
      return FusionLoadProfile(profileName, settings);
     }

   bool              SaveChartState(const SChartStateContext &context,
                                    const string activeProfileName,
                                    const bool started,
                                    const SEASettings &settings,
                                    const SPositionRuntimeState &state,
                                    const SStreakRuntimeState &streakState,
                                    const SDailyLimitsRuntimeState &dailyState,
                                    const SDrawdownRuntimeState &drawdownState)
     {
      return FusionSaveChartState(context,
                                  activeProfileName,
                                  started,
                                  settings,
                                  state,
                                  streakState,
                                  dailyState,
                                  drawdownState);
     }

   bool              LoadChartState(const ulong chartId,
                                    SChartStateContext &context,
                                    string &activeProfileName,
                                    bool &started,
                                    SEASettings &settings,
                                    SPositionRuntimeState &state,
                                    SStreakRuntimeState &streakState,
                                    SDailyLimitsRuntimeState &dailyState,
                                    SDrawdownRuntimeState &drawdownState,
                                    string &errorReason)
     {
      return FusionLoadChartState(chartId,
                                  context,
                                  activeProfileName,
                                  started,
                                  settings,
                                  state,
                                  streakState,
                                  dailyState,
                                  drawdownState,
                                  errorReason);
     }
  };

#endif
