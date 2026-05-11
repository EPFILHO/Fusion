#ifndef __FUSION_UI_PANEL_DRAFT_STATE_MQH__
#define __FUSION_UI_PANEL_DRAFT_STATE_MQH__

   bool                       ParsedProfileMagicNumber(int &magicNumber)
     {
      magicNumber = 0;
      if(!m_profilesEditCreated)
         return false;

      string profileMagicText = FusionTrimCopy(LiveEditText(m_profileMagicEdit));
      if(!FusionIsIntegerText(profileMagicText, false))
         return false;

      magicNumber = (int)StringToInteger(profileMagicText);
      return (magicNumber > 0);
     }

   bool                       ParsedConfigMagicNumber(int &magicNumber)
     {
      magicNumber = 0;
      if(!m_configSystemCreated)
        {
         magicNumber = m_draftSettings.magicNumber;
         return (magicNumber > 0);
        }
      string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
      if(!FusionIsIntegerText(magicText, false))
         return false;

      magicNumber = (int)StringToInteger(magicText);
      return (magicNumber > 0);
     }

   void                       ToggleDraftFlag(const ENUM_UI_COMMAND type)
     {
      if(type == UI_COMMAND_TOGGLE_MACROSS)
         m_draftSettings.useMACross = !m_draftSettings.useMACross;
      else if(type == UI_COMMAND_TOGGLE_RSI)
         m_draftSettings.useRSI = !m_draftSettings.useRSI;
      else if(type == UI_COMMAND_TOGGLE_BB)
         m_draftSettings.useBollinger = !m_draftSettings.useBollinger;
      else if(type == UI_COMMAND_TOGGLE_TREND_FILTER)
         m_draftSettings.useTrendFilter = !m_draftSettings.useTrendFilter;
      else if(type == UI_COMMAND_TOGGLE_RSI_FILTER)
         m_draftSettings.useRSIFilter = !m_draftSettings.useRSIFilter;
     }

   string                     DraftProfileName(void)
     {
      return FusionTrimCopy(m_committedProfileName);
     }

   void                       SyncDraftSettingsToControls(void)
     {
      if(m_configRiskCreated)
         m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      if(m_configProtectionCreated)
         SyncProtectionControls();
      if(m_configSystemCreated)
        {
         m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
         m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
        }
      if(m_profilesEditCreated)
         m_profileMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      RefreshSignalDraftViews(true, true);
      if(m_profilesTabCreated)
         UpdateProfileListView();
     }

   void                       RestoreCommittedDraftToControls(void)
     {
      m_draftSettings = m_committedSettings;
      SyncDraftSettingsToControls();
     }

#include "UIPanelPendingChanges.mqh"

#endif
