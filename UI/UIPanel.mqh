#ifndef __FUSION_UI_PANEL_MQH__
#define __FUSION_UI_PANEL_MQH__

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Panel.mqh>
#include "PanelUtils.mqh"
#include "HitTestGroup.mqh"
#include "../Core/Version.mqh"
#include "UIPanelTypes.mqh"
#include "Pages/StatusPage.mqh"
#include "Pages/ResultsPage.mqh"
#include "MACrossPanel.mqh"
#include "StrategyTimeframePanel.mqh"
#include "FilterTimeframePanel.mqh"
#include "../Persistence/SettingsStore.mqh"

class CFusionPanel : public CAppDialog
  {
private:
   long                       m_chartId;
   int                        m_subWindow;
   bool                       m_created;
   bool                       m_dialogRunning;
   bool                       m_mouseOverPanel;
   bool                       m_origDragTrade;
   bool                       m_origMouseScroll;
   bool                       m_hasPendingCommand;
   bool                       m_configInputsValid;
   bool                       m_hasCommittedSettings;
   CFusionHitGroup           *m_buildTarget;
   SUICommand                 m_pendingCommand;
   SUIPanelSnapshot           m_snapshot;
   SEASettings                m_committedSettings;
   SEASettings                m_draftSettings;
   ENUM_FUSION_TAB            m_activeTab;
   ENUM_FUSION_STRATEGY_PAGE  m_strategyPage;
   ENUM_FUSION_FILTER_PAGE    m_filterPage;
   ENUM_FUSION_CONFIG_PAGE    m_configPage;

   CButton                    m_tabs[FUSION_TAB_COUNT];
   CPanel                     m_tabsSeparator;
   CButton                    m_strategyTabs[FUSION_STRAT_COUNT];
   CPanel                     m_strategyTabsSeparator;
   CPanel                     m_strategyContentFrame;
   CButton                    m_filterTabs[FUSION_FILTER_COUNT];
   CPanel                     m_filterTabsSeparator;
   CPanel                     m_filterContentFrame;
   CButton                    m_configTabs[FUSION_CFG_COUNT];
   CPanel                     m_configTabsSeparator;
   CPanel                     m_configContentFrame;
   CStatusPage                m_statusPage;
   CResultsPage               m_resultsPage;
   CFusionHitGroup            m_statusGroup;
   CFusionHitGroup            m_resultsGroup;
   CFusionHitGroup            m_strategyGroup;
   CFusionHitGroup            m_filterGroup;
   CFusionHitGroup            m_profilesGroup;
   CFusionHitGroup            m_configGroup;
   CFusionHitGroup            m_strategyOverviewGroup;
   CFusionHitGroup            m_strategyPanelGroups[3];
   CFusionHitGroup            m_filterOverviewGroup;
   CFusionHitGroup            m_filterPanelGroups[2];
   CFusionHitGroup            m_profilesBrowseGroup;
   CFusionHitGroup            m_profilesEditGroup;
   CFusionHitGroup            m_configRiskGroup;
   CFusionHitGroup            m_configProtectionGroup;
   CFusionHitGroup            m_configSystemGroup;
   bool                       m_statusPageCreated;
   bool                       m_resultsPageCreated;
   bool                       m_strategyTabCreated;
   bool                       m_filterTabCreated;
   bool                       m_profilesTabCreated;
   bool                       m_configTabCreated;
   bool                       m_configRiskCreated;
   bool                       m_configProtectionCreated;
   bool                       m_configSystemCreated;

#include "UIPanelHeader.mqh"
#include "UIPanelSignalTabs.mqh"
#include "UIPanelProfiles.mqh"
#include "UIPanelProtectionTabs.mqh"

   CLabel                     m_cfgRiskHdr;
   CLabel                     m_cfgRiskLotLbl;
   CEdit                      m_cfgRiskLotEdit;

   CLabel                     m_cfgSystemHdr;
   CLabel                     m_cfgSystemMagicLbl;
   CEdit                      m_cfgSystemMagicEdit;
   CLabel                     m_cfgSystemConflictLbl;
   CButton                    m_cfgSystemConflictBtn;
   CLabel                     m_cfgStatus;

   void                       ResetCommand(SUICommand &command)
     {
      command.type        = UI_COMMAND_NONE;
      command.text        = "";
      command.hasSettings = false;
      command.reloadScope = RELOAD_HOT;
     }

   void                       ClearPendingCommand(void)
     {
      ResetCommand(m_pendingCommand);
      m_hasPendingCommand = false;
     }

   bool                       IsDeferredRefreshEdit(const string objectName)
     {
      if(objectName == m_profileNewEdit.Name())
         return true;
      for(int strategyIndex = 0; strategyIndex < 3; ++strategyIndex)
        {
         if(m_strategyPanels[strategyIndex] != NULL && m_strategyPanels[strategyIndex].IsDeferredEdit(objectName))
            return true;
        }
      if(m_configRiskCreated && objectName == m_cfgRiskLotEdit.Name())
         return true;
      if(m_configSystemCreated && objectName == m_cfgSystemMagicEdit.Name())
         return true;
      if(IsProtectionDeferredEdit(objectName))
         return true;
      return false;
     }

   bool                       HandleStrategyPanelDeferredEdit(const string objectName)
     {
      bool changed = false;
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL || !m_strategyPanels[sp].IsDeferredEdit(objectName))
            continue;
         m_strategyPanels[sp].HandleChange(objectName, m_draftSettings);
         changed = true;
        }

      if(changed)
        {
         UpdateOverviews();
         SyncStrategyPanels();
        }

      return changed;
     }

   void                       NormalizeStrategyDeferredEdit(const string objectName)
     {
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL || !m_strategyPanels[sp].IsDeferredEdit(objectName))
            continue;
         m_strategyPanels[sp].NormalizeDeferredEdit(objectName);
        }
     }

   bool                       ValidateStrategyPanels(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         if(!m_strategyPanels[sp].Validate(candidate, editable, error))
            return false;
        }
      return true;
     }

   void                       QueueSimpleCommand(const ENUM_UI_COMMAND type)
     {
      ResetCommand(m_pendingCommand);
      m_pendingCommand.type = type;
      m_pendingCommand.text = DraftProfileName();
      m_hasPendingCommand   = true;
     }

   void                       QueueProfileCommand(const ENUM_UI_COMMAND type,const string profileName)
     {
      ResetCommand(m_pendingCommand);
      m_pendingCommand.type = type;
      m_pendingCommand.text = profileName;
      m_hasPendingCommand = true;
     }

   void                       ReleaseButton(CButton &button)
     {
      button.Pressed(false);
     }

   bool                       AddHitGroup(CFusionHitGroup &group,const string name)
     {
      if(!group.Create(m_chartId, name, m_subWindow, 0, 0, FUSION_PANEL_WIDTH, FUSION_PANEL_HEIGHT))
         return false;
      return AddControl(group);
     }

   CFusionHitGroup           *PushBuildTarget(CFusionHitGroup &group)
     {
      CFusionHitGroup *previous = m_buildTarget;
      m_buildTarget = GetPointer(group);
      return previous;
     }

   void                       PopBuildTarget(CFusionHitGroup *previous)
     {
      m_buildTarget = previous;
     }

   bool                       AddLabel(CLabel &label,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color clr,const int size=8)
     {
      if(!label.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return AddControl(label);
     }

   bool                       AddButton(CButton &button,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color bg)
     {
      if(!button.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      button.Text(text);
      button.FontSize(8);
      button.Color(clrWhite);
      button.ColorBackground(bg);
      return AddControl(button);
     }

   bool                       AddEdit(CEdit &edit,const string name,const int x1,const int y1,const int x2,const int y2,const string value)
     {
      if(!edit.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      edit.Text(value);
      edit.Color(clrBlack);
      edit.ColorBackground(clrWhite);
      return AddControl(edit);
     }

   bool                       AddPanel(CPanel &panel,const string name,const int x1,const int y1,const int x2,const int y2,const color bg,const color border,const ENUM_BORDER_TYPE borderType=BORDER_FLAT)
     {
      if(!panel.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      panel.ColorBackground(bg);
      panel.ColorBorder(border);
      panel.BorderType(borderType);
      return AddControl(panel);
     }

   string                     LiveEditText(CEdit &edit)
     {
      string name = edit.Name();
      if(name != "" && ObjectFind(m_chartId, name) >= 0)
         return ObjectGetString(m_chartId, name, OBJPROP_TEXT);
      return edit.Text();
     }

   void                       SetVisible(CWnd &control,const bool visible)
     {
      if(visible)
         control.Show();
      else
         control.Hide();
     }

   bool                       EnsureStatusPageCreated(void)
     {
      if(m_statusPageCreated)
         return true;
      if(!AddHitGroup(m_statusGroup, "Fusion_group_status"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_statusGroup);
      bool created = m_statusPage.Create(GetPointer(this), m_chartId, m_subWindow);
      PopBuildTarget(previous);
      if(!created)
         return false;
      m_statusPageCreated = true;
      return true;
     }

   bool                       EnsureResultsPageCreated(void)
     {
      if(m_resultsPageCreated)
         return true;
      if(!AddHitGroup(m_resultsGroup, "Fusion_group_results"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_resultsGroup);
      bool created = m_resultsPage.Create(GetPointer(this), m_chartId, m_subWindow);
      PopBuildTarget(previous);
      if(!created)
         return false;
      m_resultsPageCreated = true;
      return true;
     }

   bool                       EnsureStrategyTabCreated(void)
     {
      if(m_strategyTabCreated)
         return true;
      if(!AddHitGroup(m_strategyGroup, "Fusion_group_strategy"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_strategyGroup);
      if(!BuildStrategyTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_strategyOverviewGroup, "Fusion_group_strategy_overview"))
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int groupIndex = 0; groupIndex < 3; ++groupIndex)
        {
         if(!AddHitGroup(m_strategyPanelGroups[groupIndex], "Fusion_group_strategy_panel_" + IntegerToString(groupIndex)))
           {
            PopBuildTarget(previous);
            return false;
           }
        }
      if(!EnsureStrategyOverviewCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int strategyIndex = 0; strategyIndex < 3; ++strategyIndex)
         if(!EnsureStrategyPanelCreated(strategyIndex))
           {
            PopBuildTarget(previous);
            return false;
           }
      PopBuildTarget(previous);
      m_strategyTabCreated = true;
      UpdateOverviews();
      SyncStrategyPanels();
      return true;
     }

   bool                       EnsureFilterTabCreated(void)
     {
      if(m_filterTabCreated)
         return true;
      if(!AddHitGroup(m_filterGroup, "Fusion_group_filter"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_filterGroup);
      if(!BuildFilterTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_filterOverviewGroup, "Fusion_group_filter_overview"))
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int groupIndex = 0; groupIndex < 2; ++groupIndex)
        {
         if(!AddHitGroup(m_filterPanelGroups[groupIndex], "Fusion_group_filter_panel_" + IntegerToString(groupIndex)))
           {
            PopBuildTarget(previous);
            return false;
           }
        }
      if(!EnsureFilterOverviewCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      for(int filterIndex = 0; filterIndex < 2; ++filterIndex)
         if(!EnsureFilterPanelCreated(filterIndex))
           {
            PopBuildTarget(previous);
            return false;
           }
      PopBuildTarget(previous);
      m_filterTabCreated = true;
      UpdateOverviews();
      SyncFilterPanels();
      return true;
     }

   bool                       EnsureProfilesTabCreated(void)
     {
      if(m_profilesTabCreated)
         return true;
      if(!AddHitGroup(m_profilesGroup, "Fusion_group_profiles"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_profilesGroup);
      if(!BuildProfilesTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_profilesTabCreated = true;
      RefreshProfileList(false);
      return true;
     }

   bool                       BuildConfigRiskPage(void)
     {
      if(!AddLabel(m_cfgRiskHdr, "Fusion_cfg_risk_hdr", 22, 160, 260, 180, "Risco Base", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 198, 160, 216, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 200, 196, 310, 220, "0.10"))
         return false;
      return true;
     }

   bool                       EnsureConfigRiskPageCreated(void)
     {
      if(m_configRiskCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configRiskGroup);
      if(!BuildConfigRiskPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configRiskCreated = true;
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      return true;
     }

   bool                       BuildConfigSystemPage(void)
     {
      if(!AddLabel(m_cfgSystemHdr, "Fusion_cfg_system_hdr", 22, 160, 300, 180, "Sistema e Persistencia", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgSystemMagicLbl, "Fusion_cfg_magic_lbl", 22, 198, 170, 216, "Magic", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgSystemMagicEdit, "Fusion_cfg_magic_edit", 200, 196, 340, 220, "0"))
         return false;
      if(!AddLabel(m_cfgSystemConflictLbl, "Fusion_cfg_conflict_lbl", 22, 236, 170, 254, "Resolver", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemConflictBtn, "Fusion_cfg_conflict_btn", 200, 234, 340, 258, "PRIORITY", FUSION_CLR_PANEL))
         return false;
      return true;
     }

   bool                       EnsureConfigSystemPageCreated(void)
     {
      if(m_configSystemCreated)
         return true;
      CFusionHitGroup *previous = PushBuildTarget(m_configSystemGroup);
      if(!BuildConfigSystemPage())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configSystemCreated = true;
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
      return true;
     }

   bool                       EnsureConfigTabCreated(void)
     {
      if(m_configTabCreated)
         return true;
      if(!AddHitGroup(m_configGroup, "Fusion_group_config"))
         return false;
      CFusionHitGroup *previous = PushBuildTarget(m_configGroup);
      if(!BuildConfigTab())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!AddHitGroup(m_configRiskGroup, "Fusion_group_config_risk") ||
         !AddHitGroup(m_configProtectionGroup, "Fusion_group_config_protection") ||
         !AddHitGroup(m_configSystemGroup, "Fusion_group_config_system"))
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigRiskPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigProtectionPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      if(!EnsureConfigSystemPageCreated())
        {
         PopBuildTarget(previous);
         return false;
        }
      PopBuildTarget(previous);
      m_configTabCreated = true;
      SyncDraftSettingsToControls();
      UpdateConfigReadOnly();
      RefreshConfigValidation();
      return true;
     }

   bool                       BuildAllContent(void)
     {
      if(!EnsureStatusPageCreated())
         return false;
      if(!EnsureResultsPageCreated())
         return false;
      if(!EnsureStrategyTabCreated())
         return false;
      if(!EnsureFilterTabCreated())
         return false;
      if(!EnsureProfilesTabCreated())
         return false;
      if(!EnsureConfigTabCreated())
         return false;
      return true;
     }

   bool                       CanEditSettings(void)
     {
      return (!m_snapshot.started && !m_snapshot.hasPosition && !m_snapshot.runtimeBlocked);
     }

   bool                       CanPause(void)
     {
      return (m_snapshot.started && !m_snapshot.hasPosition);
     }

   bool                       CanStart(void)
     {
      return (!ProfileEditMode() && !m_snapshot.runtimeBlocked &&
              !m_snapshot.started && !m_snapshot.hasPosition &&
              m_snapshot.startBlockedReason == "" &&
              m_configInputsValid && !HasPendingChanges());
     }

   bool                       CanSave(void)
     {
      return (!ProfileEditMode() && CanEditSettings() && m_snapshot.startBlockedReason == "" &&
              m_configInputsValid && HasPendingChanges());
     }

   bool                       CanLoad(void)
     {
      return (!ProfileEditMode() && CanEditSettings() && !HasPendingChanges());
     }

   bool                       CanAdminProfiles(void)
     {
      return (!ProfileEditMode() && CanEditSettings() && !HasPendingChanges());
     }

   bool                       ParsedDraftMagicNumber(int &magicNumber)
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

   string                     CommittedLotText(void)
     {
      return FusionNormalizeDecimalText(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
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
      if(m_strategyTabCreated || m_filterTabCreated)
         UpdateOverviews();
      if(m_strategyTabCreated)
         SyncStrategyPanels();
      if(m_filterTabCreated)
         SyncFilterPanels();
      if(m_profilesTabCreated)
         UpdateProfileListView();
     }

   void                       RestoreCommittedDraftToControls(void)
     {
      m_draftSettings = m_committedSettings;
      SyncDraftSettingsToControls();
     }

   bool                       HasPendingChanges(void)
     {
      if(!m_hasCommittedSettings)
         return false;

      if(m_configRiskCreated)
        {
         string lotText = FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit));
         if(FusionIsDecimalText(lotText, false))
           {
            if(MathAbs(StringToDouble(lotText) - m_committedSettings.fixedLot) > 0.0000001)
               return true;
           }
         else if(lotText != CommittedLotText())
            return true;
        }
      else
        {
         if(MathAbs(m_draftSettings.fixedLot - m_committedSettings.fixedLot) > 0.0000001)
            return true;
        }

      if(m_configSystemCreated)
        {
         string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
         if(FusionIsIntegerText(magicText, false))
           {
            if((int)StringToInteger(magicText) != m_committedSettings.magicNumber)
               return true;
           }
         else if(magicText != IntegerToString(m_committedSettings.magicNumber))
            return true;
        }
      else if(m_draftSettings.magicNumber != m_committedSettings.magicNumber)
         return true;

      if(m_draftSettings.conflictMode != m_committedSettings.conflictMode)
         return true;
      if(m_draftSettings.useMACross != m_committedSettings.useMACross)
         return true;
      if(m_draftSettings.useRSI != m_committedSettings.useRSI)
         return true;
      if(m_draftSettings.useBollinger != m_committedSettings.useBollinger)
         return true;
      if(m_draftSettings.useTrendFilter != m_committedSettings.useTrendFilter)
         return true;
      if(m_draftSettings.useRSIFilter != m_committedSettings.useRSIFilter)
         return true;
      if(m_draftSettings.maFastTimeframe != m_committedSettings.maFastTimeframe)
         return true;
      if(m_draftSettings.maSlowTimeframe != m_committedSettings.maSlowTimeframe)
         return true;
      if(m_draftSettings.maFastPeriod != m_committedSettings.maFastPeriod)
         return true;
      if(m_draftSettings.maSlowPeriod != m_committedSettings.maSlowPeriod)
         return true;
      if(m_draftSettings.maFastMethod != m_committedSettings.maFastMethod)
         return true;
      if(m_draftSettings.maSlowMethod != m_committedSettings.maSlowMethod)
         return true;
      if(m_draftSettings.maFastPrice != m_committedSettings.maFastPrice)
         return true;
      if(m_draftSettings.maSlowPrice != m_committedSettings.maSlowPrice)
         return true;
      if(m_draftSettings.maEntryMode != m_committedSettings.maEntryMode)
         return true;
      if(m_draftSettings.maExitMode != m_committedSettings.maExitMode)
         return true;
      if(m_draftSettings.rsiTimeframe != m_committedSettings.rsiTimeframe)
         return true;
      if(m_draftSettings.bbTimeframe != m_committedSettings.bbTimeframe)
         return true;
      if(m_draftSettings.trendMATimeframe != m_committedSettings.trendMATimeframe)
         return true;
      if(m_draftSettings.rsiFilterTimeframe != m_committedSettings.rsiFilterTimeframe)
         return true;
      if(m_draftSettings.enableSpreadProtection != m_committedSettings.enableSpreadProtection)
         return true;
      if(m_draftSettings.maxSpreadPoints != m_committedSettings.maxSpreadPoints)
         return true;
      if(m_draftSettings.enableSessionFilter != m_committedSettings.enableSessionFilter)
         return true;
      if(m_draftSettings.sessionStartHour != m_committedSettings.sessionStartHour ||
         m_draftSettings.sessionStartMinute != m_committedSettings.sessionStartMinute ||
         m_draftSettings.sessionEndHour != m_committedSettings.sessionEndHour ||
         m_draftSettings.sessionEndMinute != m_committedSettings.sessionEndMinute)
         return true;
      if(m_draftSettings.closeOnSessionEnd != m_committedSettings.closeOnSessionEnd)
         return true;
      if(m_draftSettings.enableDailyLimits != m_committedSettings.enableDailyLimits)
         return true;
      if(m_draftSettings.maxDailyTrades != m_committedSettings.maxDailyTrades)
         return true;
      if(MathAbs(m_draftSettings.maxDailyLoss - m_committedSettings.maxDailyLoss) > 0.0000001)
         return true;
      if(MathAbs(m_draftSettings.maxDailyGain - m_committedSettings.maxDailyGain) > 0.0000001)
         return true;
      if(m_draftSettings.enableDrawdown != m_committedSettings.enableDrawdown)
         return true;
      if(MathAbs(m_draftSettings.maxDrawdown - m_committedSettings.maxDrawdown) > 0.0000001)
         return true;
      if(m_draftSettings.enableStreak != m_committedSettings.enableStreak)
         return true;
      if(m_draftSettings.maxLossStreak != m_committedSettings.maxLossStreak)
         return true;
      if(m_draftSettings.maxWinStreak != m_committedSettings.maxWinStreak)
         return true;
      for(int newsIndex = 0; newsIndex < 3; ++newsIndex)
        {
         if(m_draftSettings.newsWindows[newsIndex].enabled != m_committedSettings.newsWindows[newsIndex].enabled)
            return true;
         if(m_draftSettings.newsWindows[newsIndex].startHour != m_committedSettings.newsWindows[newsIndex].startHour ||
            m_draftSettings.newsWindows[newsIndex].startMinute != m_committedSettings.newsWindows[newsIndex].startMinute ||
            m_draftSettings.newsWindows[newsIndex].endHour != m_committedSettings.newsWindows[newsIndex].endHour ||
            m_draftSettings.newsWindows[newsIndex].endMinute != m_committedSettings.newsWindows[newsIndex].endMinute ||
            m_draftSettings.newsWindows[newsIndex].action != m_committedSettings.newsWindows[newsIndex].action)
            return true;
        }

      return false;
     }

   bool                       HandleSignalPanelChange(const int id,const string objectName)
     {
      if(id != CHARTEVENT_CUSTOM + ON_CHANGE)
         return false;

      if(!CanEditSettings())
        {
         RefreshTheme();
         return false;
        }

      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         if(m_strategyPanels[sp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            UpdateOverviews();
            return true;
           }
        }

      for(int fp = 0; fp < 2; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         if(m_filterPanels[fp].HandleChange(objectName, m_draftSettings))
           {
            RefreshConfigValidation();
            UpdateOverviews();
            SyncFilterPanels();
            return true;
           }
        }

      return false;
     }

   bool                       BuildPendingSettings(SEASettings &outSettings,string &outProfileName,string &outStatus,const string targetProfileName="")
     {
      outSettings = m_draftSettings;
      outProfileName = DraftProfileName();
      string profileForMagicCheck = (targetProfileName == "") ? outProfileName : targetProfileName;

      bool profileValid = !FusionIsBlank(outProfileName);

      if(!m_configTabCreated)
        {
         outSettings.fixedLot = m_draftSettings.fixedLot;
         outSettings.magicNumber = m_draftSettings.magicNumber;
         string strategyError = "";
         bool strategyValid = ValidateStrategyPanels(outSettings, CanEditSettings(), strategyError);
         m_configInputsValid = (profileValid && outSettings.fixedLot > 0.0 && outSettings.magicNumber > 0 && strategyValid);
         if(m_configInputsValid)
            m_draftSettings = outSettings;
         outStatus = m_configInputsValid ? "Configuracao pronta." : (strategyError != "" ? strategyError : "Perfil invalido.");
         SyncHeaderProfile(profileValid ? outProfileName : "");
         return m_configInputsValid;
        }

      bool lotValid = false;
      bool protectionValid = true;
      bool strategyValid = true;
      bool magicValid = false;
      bool magicUnique = false;
      string magicConflictProfile = "";
      string protectionError = "";
      string strategyError = "";
      double parsedLot = 0.0;
      int parsedMagic = 0;

      string lotText = m_configRiskCreated ? FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit))
                                           : FusionNormalizeDecimalText(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      if(FusionIsDecimalText(lotText, false))
        {
         parsedLot = StringToDouble(lotText);
         lotValid = (parsedLot > 0.0);
         if(lotValid && m_snapshot.symbolSpec.volumeMin > 0.0)
            lotValid = (parsedLot >= (m_snapshot.symbolSpec.volumeMin - 0.0000001));
         if(lotValid && m_snapshot.symbolSpec.volumeMax > 0.0)
            lotValid = (parsedLot <= (m_snapshot.symbolSpec.volumeMax + 0.0000001));
         if(lotValid)
            lotValid = FusionIsVolumeAligned(parsedLot, m_snapshot.symbolSpec);
        }

      magicValid = ParsedDraftMagicNumber(parsedMagic);
      if(magicValid)
         magicUnique = MagicAvailableForProfile(parsedMagic, profileForMagicCheck, magicConflictProfile);

      bool editable = CanEditSettings();
      if(m_configRiskCreated)
         FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, editable);
      if(m_configSystemCreated)
         FusionApplyEditStyle(m_cfgSystemMagicEdit, magicValid && magicUnique, editable);
      if(m_configProtectionCreated)
         protectionValid = ValidateProtectionSettings(outSettings, editable, protectionError);
      strategyValid = ValidateStrategyPanels(outSettings, editable, strategyError);

      SyncHeaderProfile(profileValid ? outProfileName : "");
      if(m_configRiskCreated)
         m_cfgRiskLotLbl.Color(!editable ? FUSION_CLR_MUTED : (lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      if(m_configSystemCreated)
         m_cfgSystemMagicLbl.Color(!editable ? FUSION_CLR_MUTED : ((magicValid && magicUnique) ? FUSION_CLR_LABEL : FUSION_CLR_BAD));

      m_configInputsValid = profileValid && lotValid && protectionValid && strategyValid && magicValid && magicUnique;
      if(m_configInputsValid)
        {
         outSettings.fixedLot = parsedLot;
         outSettings.magicNumber = parsedMagic;
         m_draftSettings = outSettings;
        }

      bool dirty = HasPendingChanges();
      if(m_snapshot.runtimeBlocked)
        {
         outStatus = m_snapshot.runtimeBlockReason;
         m_cfgStatus.Color(FUSION_CLR_BAD);
        }
      else if(m_snapshot.hasPosition)
        {
         outStatus = "Posicao aberta: gerenciamento ativo, edicao bloqueada.";
         m_cfgStatus.Color(FUSION_CLR_WARN);
        }
      else if(m_snapshot.started)
        {
         outStatus = "EA rodando: pause antes de editar configuracoes.";
         m_cfgStatus.Color(FUSION_CLR_WARN);
        }
      else if(!m_configInputsValid)
        {
         if(magicValid && !magicUnique)
            outStatus = "Magic ja usado pelo perfil " + magicConflictProfile + ".";
         else if(protectionError != "")
            outStatus = protectionError;
         else if(strategyError != "")
            outStatus = strategyError;
         else
            outStatus = "Corrija os campos em rosa antes de salvar.";
         m_cfgStatus.Color(FUSION_CLR_BAD);
        }
      else if(m_snapshot.startBlockedReason != "")
        {
         outStatus = "Perfil em uso por outra instancia. Carregue ou crie outro perfil antes de salvar.";
         m_cfgStatus.Color(FUSION_CLR_WARN);
        }
      else if(dirty)
        {
         outStatus = "Alteracoes pendentes. Salve para aplicar no EA.";
         m_cfgStatus.Color(FUSION_CLR_GOOD);
        }
      else if(m_snapshot.started)
        {
         outStatus = "EA em execucao com configuracao salva.";
         m_cfgStatus.Color(FUSION_CLR_WARN);
        }
      else
        {
         outStatus = "Configuracao salva e pronta para iniciar.";
         m_cfgStatus.Color(FUSION_CLR_MUTED);
        }

      m_cfgStatus.Text(outStatus);
      return m_configInputsValid;
     }

   void                       RefreshTheme(void)
     {
      RefreshHeaderTheme();
      if(m_configProtectionCreated)
         RefreshProtectionTheme();
      if(m_configSystemCreated)
        {
         if(CanEditSettings())
            FusionApplyActionButtonStyle(m_cfgSystemConflictBtn, FUSION_CLR_NAV_IDLE, true);
         else
            FusionApplyNeutralButtonStyle(m_cfgSystemConflictBtn);
        }
      if(m_activeTab == FUSION_TAB_PROFILES)
         UpdateProfileListView();
     }

   void                       UpdateTabStyles(void)
     {
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_tabs[i], i == (int)m_activeTab);
      if(m_strategyTabCreated)
         for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
            FusionApplyPrimaryButtonStyle(m_strategyTabs[i], i == (int)m_strategyPage);
      if(m_filterTabCreated)
         for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
            FusionApplyPrimaryButtonStyle(m_filterTabs[i], i == (int)m_filterPage);
      if(m_configTabCreated)
        {
         for(int i = 0; i < FUSION_CFG_COUNT; ++i)
            FusionApplyPrimaryButtonStyle(m_configTabs[i], i == (int)m_configPage);
         if(m_configProtectionCreated)
            for(int p = 0; p < FUSION_PROTECT_COUNT; ++p)
               FusionApplyPrimaryButtonStyle(m_protectTabs[p], p == (int)m_protectPage);
         if(m_configSystemCreated)
            m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
        }
     }

   bool                       RefreshConfigValidation(void)
     {
      SEASettings candidate;
      string profileName = "";
      string status = "";
      bool valid = BuildPendingSettings(candidate, profileName, status);
      RefreshTheme();
      return valid;
     }

   void                       SyncStrategyPanels(void)
     {
      for(int i = 0; i < 3; ++i)
         if(m_strategyPanels[i] != NULL)
            m_strategyPanels[i].Sync(m_draftSettings, CanEditSettings());
     }

   void                       SyncFilterPanels(void)
     {
      for(int j = 0; j < 2; ++j)
         if(m_filterPanels[j] != NULL)
            m_filterPanels[j].Sync(m_draftSettings, CanEditSettings());
     }

   void                       UpdateActiveTabContent(const bool runtimeStateChanged)
     {
      if(m_activeTab == FUSION_TAB_STATUS)
        {
         if(m_statusPageCreated)
            m_statusPage.Update(m_snapshot);
        }
      else if(m_activeTab == FUSION_TAB_RESULTS)
        {
         if(m_resultsPageCreated)
            m_resultsPage.Update(m_snapshot, m_committedSettings, m_committedProfileName);
        }
      else if(m_activeTab == FUSION_TAB_STRATEGIES)
        {
         if(m_strategyTabCreated)
            UpdateOverviews();
         if(runtimeStateChanged && m_strategyTabCreated)
            SyncStrategyPanels();
        }
      else if(m_activeTab == FUSION_TAB_FILTERS)
        {
         if(m_filterTabCreated)
            UpdateOverviews();
         if(runtimeStateChanged && m_filterTabCreated)
            SyncFilterPanels();
        }
      else if(m_activeTab == FUSION_TAB_PROFILES)
        {
         if(runtimeStateChanged && m_profilesTabCreated)
            UpdateProfileListView();
        }
      else if(m_activeTab == FUSION_TAB_CONFIG)
        {
         if(m_configTabCreated)
            UpdateConfigReadOnly();
         if(runtimeStateChanged && m_configTabCreated)
            RefreshConfigValidation();
        }
     }

   void                       UpdateConfigReadOnly(void)
     {
      if(m_configProtectionCreated)
         RefreshProtectionTheme();
     }

   void                       SetConfigVisible(const bool visible)
     {
      if(!m_configTabCreated)
         return;

      SetVisible(m_configGroup, visible);
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
         SetVisible(m_configTabs[i], visible);
      SetVisible(m_configTabsSeparator, visible);
      SetVisible(m_configContentFrame, visible && m_configPage != FUSION_CFG_PROTECTION);

      bool riskVisible = visible && m_configPage == FUSION_CFG_RISK;
      bool protectionVisible = visible && m_configPage == FUSION_CFG_PROTECTION;
      bool systemVisible = visible && m_configPage == FUSION_CFG_SYSTEM;

      if(m_configRiskCreated)
        {
         SetVisible(m_configRiskGroup, riskVisible);
         SetVisible(m_cfgRiskHdr, riskVisible);
         SetVisible(m_cfgRiskLotLbl, riskVisible);
         SetVisible(m_cfgRiskLotEdit, riskVisible);
        }

      if(m_configProtectionCreated)
        {
         SetVisible(m_configProtectionGroup, protectionVisible);
         for(int p = 0; p < FUSION_PROTECT_COUNT; ++p)
            SetVisible(m_protectTabs[p], protectionVisible);
         SetProtectionControlsVisible(m_protectPage, protectionVisible);
        }

      if(m_configSystemCreated)
        {
         SetVisible(m_configSystemGroup, systemVisible);
         SetVisible(m_cfgSystemHdr, systemVisible);
         SetVisible(m_cfgSystemMagicLbl, systemVisible);
         SetVisible(m_cfgSystemMagicEdit, systemVisible);
         SetVisible(m_cfgSystemConflictLbl, systemVisible);
         SetVisible(m_cfgSystemConflictBtn, systemVisible);
        }
      SetVisible(m_cfgStatus, visible);
     }

   void                       SetShellVisible(const bool visible)
     {
      SetVisible(m_lblHeader, visible);
      SetVisible(m_btnStart, visible);
      SetVisible(m_btnSave, visible);
      SetVisible(m_btnCancel, visible);
      SetVisible(m_lblProfile, visible);
      SetVisible(m_activeProfile, visible);
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
         SetVisible(m_tabs[i], visible);
      SetVisible(m_tabsSeparator, visible);
     }

   void                       ResetDialogMouseRouting(void)
     {
      long dialogId = Id();
      string dialogName = Name();

      CAppDialog::ChartEvent(CHARTEVENT_CUSTOM + ON_MOUSE_FOCUS_SET, dialogId, 0.0, dialogName);
      CAppDialog::ChartEvent(CHARTEVENT_CUSTOM + ON_BRING_TO_TOP, dialogId, 0.0, dialogName);
     }

   void                       HideManagedContent(void)
     {
      SetShellVisible(false);
      if(m_statusPageCreated)
        {
         SetVisible(m_statusGroup, false);
         m_statusPage.SetVisible(false);
        }
      if(m_resultsPageCreated)
        {
         SetVisible(m_resultsGroup, false);
         m_resultsPage.SetVisible(false);
        }
      if(m_strategyTabCreated)
         SetStrategiesVisible(false);
      if(m_filterTabCreated)
         SetFiltersVisible(false);
      if(m_profilesTabCreated)
         SetProfilesVisible(false);
      SetConfigVisible(false);
     }

   void                       ApplyVisibility(void)
     {
      if(m_statusPageCreated)
        {
         bool statusVisible = (m_activeTab == FUSION_TAB_STATUS);
         SetVisible(m_statusGroup, statusVisible);
         m_statusPage.SetVisible(statusVisible);
        }
      if(m_resultsPageCreated)
        {
         bool resultsVisible = (m_activeTab == FUSION_TAB_RESULTS);
         SetVisible(m_resultsGroup, resultsVisible);
         m_resultsPage.SetVisible(resultsVisible);
        }
      if(m_strategyTabCreated)
         SetStrategiesVisible(m_activeTab == FUSION_TAB_STRATEGIES);
      if(m_filterTabCreated)
         SetFiltersVisible(m_activeTab == FUSION_TAB_FILTERS);
      if(m_profilesTabCreated)
         SetProfilesVisible(m_activeTab == FUSION_TAB_PROFILES);
      SetConfigVisible(m_activeTab == FUSION_TAB_CONFIG);
      RefreshTheme();
      UpdateTabStyles();
     }

   bool                       BuildTabs(void)
     {
      string names[FUSION_TAB_COUNT] = {"STATUS", "RESULTS", "STRATS", "FILTERS", "PERFIS", "CONFIG"};
      int tabWidth = 84;
      int tabGap = 2;
      int x = 18;
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(!AddButton(m_tabs[i], "Fusion_tab_" + IntegerToString(i), x, 68, x + tabWidth, 92, names[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_tabsSeparator,
                   "Fusion_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   96,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   98,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      return true;
     }

   bool                       BuildConfigTab(void)
     {
      string pageNames[FUSION_CFG_COUNT] = {"RISK", "PROTECT", "SYSTEM"};
      int tabWidth = 120;
      int tabGap = 4;
      int x = 18;
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
        {
         if(!AddButton(m_configTabs[i], "Fusion_cfg_tab_" + IntegerToString(i), x, 104, x + tabWidth, 128, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += tabWidth + tabGap;
        }
      if(!AddPanel(m_configTabsSeparator,
                   "Fusion_cfg_tabs_sep",
                   FUSION_PANEL_MARGIN,
                   132,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   134,
                   FUSION_CLR_SUBTAB_LINE,
                   FUSION_CLR_SUBTAB_LINE))
         return false;
      if(!AddPanel(m_configContentFrame,
                   "Fusion_cfg_content_frame",
                   FUSION_PANEL_MARGIN,
                   138,
                   FUSION_PANEL_WIDTH - FUSION_PANEL_MARGIN,
                   560,
                   FUSION_CLR_FRAME_BG,
                   FUSION_CLR_FRAME_BORDER))
         return false;
      if(!AddLabel(m_cfgStatus, "Fusion_cfg_status", 22, 576, FUSION_PANEL_WIDTH - 22, 600, "", FUSION_CLR_MUTED, 8))
         return false;
      return true;
     }

   bool                       HandlePanelClick(const string objectName)
     {
      if(objectName == m_btnStart.Name())
        {
         ReleaseButton(m_btnStart);
         if(CanPause())
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         else if(CanStart())
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         RefreshTheme();
         return true;
        }
      if(objectName == m_btnSave.Name())
        {
         ReleaseButton(m_btnSave);
         SEASettings pendingSettings;
         string profileName = "";
         string status = "";
         bool valid = BuildPendingSettings(pendingSettings, profileName, status);
         if(valid && CanSave())
           {
            ResetCommand(m_pendingCommand);
            m_pendingCommand.type = UI_COMMAND_SAVE_PROFILE;
            m_pendingCommand.text = profileName;
            m_pendingCommand.hasSettings = true;
            m_pendingCommand.settings = pendingSettings;
            m_pendingCommand.reloadScope = RELOAD_COLD;
            m_hasPendingCommand = true;
           }
         RefreshTheme();
         return true;
        }
      if(objectName == m_btnCancel.Name())
        {
         ReleaseButton(m_btnCancel);
         if(!ProfileEditMode() && CanEditSettings() && HasPendingChanges())
           {
            RestoreCommittedDraftToControls();
            RefreshConfigValidation();
            if(m_profilesTabCreated && m_activeTab == FUSION_TAB_PROFILES)
               SetProfileStatus("Alteracoes descartadas. Perfil salvo restaurado.", FUSION_CLR_GOOD, true);
           }
         else
            RefreshTheme();
         return true;
        }
      if(objectName == m_cfgSystemConflictBtn.Name())
        {
         ReleaseButton(m_cfgSystemConflictBtn);
         if(!CanEditSettings())
           {
            RefreshTheme();
            return true;
           }
         m_draftSettings.conflictMode = (m_draftSettings.conflictMode == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
         RefreshConfigValidation();
         UpdateTabStyles();
         return true;
        }
      if(HandleProtectionClick(objectName))
         return true;

      for(int t = 0; t < FUSION_TAB_COUNT; ++t)
        {
         if(objectName == m_tabs[t].Name())
           {
            ReleaseButton(m_tabs[t]);
            ResetDialogMouseRouting();
            m_activeTab = (ENUM_FUSION_TAB)t;
            ApplyVisibility();
            UpdateActiveTabContent(true);
            return true;
           }
        }

      for(int s = 0; s < FUSION_STRAT_COUNT; ++s)
        {
         if(objectName == m_strategyTabs[s].Name())
           {
            ReleaseButton(m_strategyTabs[s]);
            ResetDialogMouseRouting();
            m_strategyPage = (ENUM_FUSION_STRATEGY_PAGE)s;
            ApplyVisibility();
            return true;
           }
        }

      for(int f = 0; f < FUSION_FILTER_COUNT; ++f)
        {
         if(objectName == m_filterTabs[f].Name())
           {
            ReleaseButton(m_filterTabs[f]);
            ResetDialogMouseRouting();
            m_filterPage = (ENUM_FUSION_FILTER_PAGE)f;
            ApplyVisibility();
            return true;
           }
        }

      for(int c = 0; c < FUSION_CFG_COUNT; ++c)
        {
         if(objectName == m_configTabs[c].Name())
           {
            ReleaseButton(m_configTabs[c]);
            ResetDialogMouseRouting();
            m_configPage = (ENUM_FUSION_CONFIG_PAGE)c;
            ApplyVisibility();
            RefreshConfigValidation();
            return true;
           }
        }

      for(int pr = 0; pr < FUSION_PROFILE_VISIBLE_ROWS; ++pr)
        {
         if(objectName == m_profileRows[pr].Name())
           {
            ReleaseButton(m_profileRows[pr]);
            if(ProfileEditMode())
               return true;

            int idx = m_profileOffset + pr;
            if(idx >= 0 && idx < m_profileCount)
              {
               m_profileSelected = idx;
               SetProfileMode(FUSION_PROFILE_BROWSE);
               UpdateProfileListView();
              }
            return true;
           }
        }

      if(objectName == m_profileUpBtn.Name())
        {
         ReleaseButton(m_profileUpBtn);
         if(m_profileOffset > 0)
            m_profileOffset--;
         UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileDownBtn.Name())
        {
         ReleaseButton(m_profileDownBtn);
         if(m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS < m_profileCount)
            m_profileOffset++;
         UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileRefreshBtn.Name())
        {
         ReleaseButton(m_profileRefreshBtn);
         RefreshProfileList(true);
         SetProfileStatus("Lista de perfis atualizada.", FUSION_CLR_GOOD, true);
         return true;
        }

      if(objectName == m_profileNewBtn.Name())
        {
         ReleaseButton(m_profileNewBtn);
         if(CanStartNewProfile())
           {
            SetProfileMode(FUSION_PROFILE_NEW);
            ApplyVisibility();
           }
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileLoadBtn.Name())
        {
         ReleaseButton(m_profileLoadBtn);
         string selectedProfile = SelectedProfileName();
         if(!ProfileEditMode() && CanLoad() && selectedProfile != "")
            QueueProfileCommand(UI_COMMAND_LOAD_PROFILE, selectedProfile);
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileSaveAsBtn.Name())
        {
         ReleaseButton(m_profileSaveAsBtn);
         string newProfileName = ProfileDraftName();
         if(!ProfileEditMode())
           {
            UpdateProfileListView();
            return true;
           }

         if(newProfileName != "" && m_profileStore.ProfileExists(newProfileName))
           {
            SetProfileStatus("Perfil ja existe. Escolha outro nome.", FUSION_CLR_WARN, true);
            return true;
           }

         if(ProfileEditMode())
           {
            SEASettings pendingSettings;
            string ignoredProfile = "";
            string status = "";
            bool valid = BuildPendingSettings(pendingSettings, ignoredProfile, status, newProfileName);
            if(CanEditSettings() && valid && newProfileName != "")
              {
               ResetCommand(m_pendingCommand);
               m_pendingCommand.type = UI_COMMAND_SAVE_PROFILE;
               m_pendingCommand.text = newProfileName;
               m_pendingCommand.hasSettings = true;
               m_pendingCommand.settings = pendingSettings;
               m_pendingCommand.reloadScope = RELOAD_COLD;
               m_hasPendingCommand = true;
               SetProfileStatus("Solicitado salvamento do perfil " + newProfileName + ".", FUSION_CLR_GOOD, true);
              }
            else
              {
               if(status != "")
                  SetProfileStatus(status, FUSION_CLR_BAD, true);
               else
                  UpdateProfileListView();
              }
            return true;
           }

         return true;
        }

      if(objectName == m_profileDuplicateBtn.Name())
        {
         ReleaseButton(m_profileDuplicateBtn);
         if(CanStartDuplicateProfile())
           {
            string selectedProfile = SelectedProfileName();
            SEASettings sourceSettings;
            if(m_profileStore.LoadProfile(selectedProfile, sourceSettings))
              {
               m_draftSettings = sourceSettings;
               SetProfileMode(FUSION_PROFILE_DUPLICATE, SuggestedDuplicateName(selectedProfile), selectedProfile);
               SyncDraftSettingsToControls();
               RefreshConfigValidation();
               ApplyVisibility();
               SetProfileStatus("Duplicando " + selectedProfile + ". Informe nome e Magic unico antes de salvar.", FUSION_CLR_WARN, true);
              }
            else
               SetProfileStatus("Nao foi possivel ler o perfil selecionado.", FUSION_CLR_BAD, true);
           }
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileCancelBtn.Name())
        {
         ReleaseButton(m_profileCancelBtn);
         SetProfileMode(FUSION_PROFILE_BROWSE);
         RestoreCommittedDraftToControls();
         RefreshConfigValidation();
         ApplyVisibility();
         return true;
        }

      if(objectName == m_profileDeleteBtn.Name())
        {
         ReleaseButton(m_profileDeleteBtn);
         string selectedProfile = SelectedProfileName();
         if(IsDefaultProfileName(selectedProfile))
           {
            SetProfileStatus("O perfil default e reservado e nao deve ser apagado.", FUSION_CLR_WARN, true);
            return true;
           }
         if(!ProfileEditMode() && CanAdminProfiles() && selectedProfile != "" &&
            m_profileStore.SanitizeProfileName(selectedProfile) != m_profileStore.SanitizeProfileName(m_committedProfileName))
           {
            if(m_profileStore.DeleteProfile(selectedProfile))
              {
               RefreshProfileList(false);
               SetProfileStatus("Perfil excluido: " + selectedProfile + ".", FUSION_CLR_GOOD, true);
              }
            else
               SetProfileStatus("Nao foi possivel excluir o perfil.", FUSION_CLR_BAD, true);
           }
         else
            UpdateProfileListView();
         return true;
        }

      SUICommand tempCommand;
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_strategyPanels[sp].HandleClick(objectName, tempCommand))
           {
            if(!CanEditSettings())
              {
               RefreshTheme();
               return true;
              }
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            UpdateOverviews();
            SyncStrategyPanels();
            return true;
           }
        }

      for(int fp = 0; fp < 2; ++fp)
        {
         if(m_filterPanels[fp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_filterPanels[fp].HandleClick(objectName, tempCommand))
           {
            if(!CanEditSettings())
              {
               RefreshTheme();
               return true;
              }
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            UpdateOverviews();
            SyncFilterPanels();
            return true;
           }
        }

      return false;
     }

protected:
   virtual bool                CreateButtonClose(void)
     {
      return true;
     }

   virtual void                OnClickButtonClose(void)
     {
      // O Fusion nao expoe botao de fechar. Se algum clique mal roteado
      // cair aqui, ignoramos em vez de remover o EA do grafico.
     }

   virtual void                Minimize(void)
     {
      if(!m_created)
         return;
      HideManagedContent();
      CAppDialog::Minimize();
      ChartRedraw();
     }

   virtual void                Maximize(void)
     {
      CAppDialog::Maximize();
      if(!m_created)
         return;

      SetShellVisible(true);
      ApplyVisibility();
      UpdateActiveTabContent(true);
      ChartRedraw();
     }

public:
                              CFusionPanel(void)
     {
      m_chartId         = 0;
      m_subWindow       = 0;
      m_created         = false;
      m_dialogRunning   = false;
      m_mouseOverPanel  = false;
      m_origDragTrade   = true;
      m_origMouseScroll = true;
      m_configInputsValid = true;
      m_hasCommittedSettings = false;
      m_buildTarget    = NULL;
      m_activeTab       = FUSION_TAB_STATUS;
      m_strategyPage    = FUSION_STRAT_OVERVIEW;
      m_filterPage      = FUSION_FILTER_OVERVIEW;
      m_configPage      = FUSION_CFG_RISK;
      m_protectPage     = FUSION_PROTECT_GENERAL;
      m_statusPageCreated = false;
      m_resultsPageCreated = false;
      m_strategyTabCreated = false;
      m_filterTabCreated = false;
      m_profilesTabCreated = false;
      m_configTabCreated = false;
      m_configRiskCreated = false;
      m_configProtectionCreated = false;
      m_configSystemCreated = false;
      m_profileMode     = FUSION_PROFILE_BROWSE;
      m_committedProfileName = "";
      ArrayResize(m_profileNames, 0);
      m_profileCount = 0;
      m_profileOffset = 0;
      m_profileSelected = -1;
      m_profilesBrowseCreated = false;
      m_profilesEditCreated = false;
      m_profileStatusOverride = "";
      m_profileStatusOverrideColor = FUSION_CLR_MUTED;
      m_profileStatusOverrideUntil = 0;
      m_profileEditSourceName = "";
      SetDefaultSettings(m_committedSettings);
      SetDefaultSettings(m_draftSettings);
      m_strategyOverviewCreated = false;
      m_filterOverviewCreated = false;
      for(int i = 0; i < 3; ++i)
        {
         m_strategyPanels[i] = NULL;
         m_strategyPanelCreated[i] = false;
        }
      for(int j = 0; j < 2; ++j)
        {
         m_filterPanels[j] = NULL;
         m_filterPanelCreated[j] = false;
        }
      m_snapshot.started = false;
      m_snapshot.hasPosition = false;
      m_snapshot.activeProfileName = "";
      m_snapshot.symbol = "";
      m_snapshot.timeframe = "";
      m_snapshot.symbolSpec.symbol = "";
      m_snapshot.symbolSpec.digits = 0;
      m_snapshot.symbolSpec.point = 0.0;
      m_snapshot.symbolSpec.tickSize = 0.0;
      m_snapshot.symbolSpec.tickValue = 0.0;
      m_snapshot.symbolSpec.volumeMin = 0.0;
      m_snapshot.symbolSpec.volumeMax = 0.0;
      m_snapshot.symbolSpec.volumeStep = 0.0;
      m_snapshot.symbolSpec.stopsLevel = 0;
      m_snapshot.symbolSpec.freezeLevel = 0;
      m_snapshot.symbolSpec.fillingMode = 0;
      m_snapshot.magicNumber = 0;
      m_snapshot.activeStrategies = 0;
      m_snapshot.activeFilters = 0;
      m_snapshot.conflictMode = CONFLICT_PRIORITY;
      m_snapshot.fixedLot = 0.0;
      m_snapshot.maxSpreadPoints = 0;
      m_snapshot.ownerStrategyName = "";
      m_snapshot.useMACross = false;
      m_snapshot.useRSI = false;
      m_snapshot.useBollinger = false;
      m_snapshot.useTrendFilter = false;
      m_snapshot.useRSIFilter = false;
      m_snapshot.runtimeBlocked = false;
      m_snapshot.runtimeBlockReason = "";
      m_snapshot.startBlockedReason = "";
      m_snapshot.runtimeNotice = "";
      m_snapshot.dailyTradeCount = 0;
      m_snapshot.dailyClosedProfit = 0.0;
      m_snapshot.lossStreak = 0;
      m_snapshot.winStreak = 0;
      m_snapshot.drawdownProtectionActive = false;
      ClearPendingCommand();
     }

                             ~CFusionPanel(void)
     {
      Destroy(REASON_REMOVE);
     }

   bool                       AddControl(CWnd &control)
     {
      if(m_buildTarget != NULL)
         return m_buildTarget.Add(control);
      return Add(control);
     }

   bool                       CreatePanel(const long chartId,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2,const SUIPanelSnapshot &snapshot)
     {
      m_chartId   = chartId;
      m_subWindow = subwin;
      m_snapshot  = snapshot;
      ClearPendingCommand();

      if(!Create(chartId, name, subwin, x1, y1, x2, y2))
         return false;

      m_created = true;
      m_origDragTrade   = (bool)ChartGetInteger(chartId, CHART_DRAG_TRADE_LEVELS);
      m_origMouseScroll = (bool)ChartGetInteger(chartId, CHART_MOUSE_SCROLL);
      ChartSetInteger(chartId, CHART_EVENT_MOUSE_MOVE, true);

      if(!BuildHeader())      { Destroy(REASON_REMOVE); return false; }
      if(!BuildTabs())        { Destroy(REASON_REMOVE); return false; }
      if(!BuildAllContent())  { Destroy(REASON_REMOVE); return false; }
      ApplyVisibility();
      LoadSettings(snapshot);
      RefreshTheme();
      Update(snapshot);
      ApplyVisibility();
      return true;
     }

   bool                       StartDialog(void)
     {
      if(!CAppDialog::Run())
         return false;
      m_dialogRunning = true;
      return true;
     }

   virtual void                Destroy(const int reason=REASON_REMOVE)
     {
      if(!m_created)
         return;

      ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);

      CAppDialog::Destroy(reason);

      for(int i = 0; i < 3; ++i)
        {
         if(m_strategyPanels[i] != NULL)
           {
            delete m_strategyPanels[i];
            m_strategyPanels[i] = NULL;
           }
        }

      for(int j = 0; j < 2; ++j)
        {
         if(m_filterPanels[j] != NULL)
           {
            delete m_filterPanels[j];
            m_filterPanels[j] = NULL;
           }
        }

      m_created = false;
      m_dialogRunning = false;
     }

   void                       LoadSettings(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created)
         return;

      m_snapshot = snapshot;
      LoadSettings(snapshot.settings, snapshot.activeProfileName, snapshot.symbolSpec);
     }

   void                       LoadSettings(const SEASettings &settings,const string profileName,const SSymbolSpec &spec)
     {
      if(!m_created)
         return;

      m_snapshot.symbolSpec      = spec;
      m_snapshot.activeProfileName = profileName;
      m_snapshot.fixedLot        = settings.fixedLot;
      m_snapshot.maxSpreadPoints = settings.maxSpreadPoints;
      m_snapshot.magicNumber     = settings.magicNumber;
      m_snapshot.conflictMode    = settings.conflictMode;
      m_snapshot.useMACross      = settings.useMACross;
      m_snapshot.useRSI          = settings.useRSI;
      m_snapshot.useBollinger    = settings.useBollinger;
      m_snapshot.useTrendFilter  = settings.useTrendFilter;
      m_snapshot.useRSIFilter    = settings.useRSIFilter;

      m_committedSettings        = settings;
      m_draftSettings            = settings;
      m_committedProfileName     = profileName;
      m_hasCommittedSettings     = true;

      SyncHeaderProfile(m_committedProfileName);
      SyncDraftSettingsToControls();
      SetProfileMode(FUSION_PROFILE_BROWSE);
      if(m_profilesTabCreated)
        {
         ClearProfileStatusOverride();
         RefreshProfileList(false);
         if(m_activeTab == FUSION_TAB_PROFILES)
            SetProfilesVisible(true);
        }
      if(m_configTabCreated)
         RefreshConfigValidation();
      else
         RefreshTheme();
     }

   void                       Update(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created || m_minimized)
         return;

      bool runtimeStateChanged = (snapshot.started != m_snapshot.started || snapshot.hasPosition != m_snapshot.hasPosition);
      bool redrawNeeded = runtimeStateChanged ||
                          snapshot.runtimeBlocked != m_snapshot.runtimeBlocked ||
                          snapshot.startBlockedReason != m_snapshot.startBlockedReason ||
                          snapshot.runtimeNotice != m_snapshot.runtimeNotice ||
                          snapshot.dailyTradeCount != m_snapshot.dailyTradeCount ||
                          MathAbs(snapshot.dailyClosedProfit - m_snapshot.dailyClosedProfit) > 0.0000001 ||
                          snapshot.lossStreak != m_snapshot.lossStreak ||
                          snapshot.winStreak != m_snapshot.winStreak ||
                          snapshot.drawdownProtectionActive != m_snapshot.drawdownProtectionActive;
      m_snapshot = snapshot;
      UpdateHeaderButtons();
      UpdateActiveTabContent(runtimeStateChanged);
      if(redrawNeeded)
         ChartRedraw();
     }

   void                       MouseProtection(const int x,const int y)
     {
      bool inside = (x >= Left() && x <= Right() && y >= Top() && y <= Bottom());

      if(inside && !m_mouseOverPanel)
        {
         ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, false);
         ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, false);
         m_mouseOverPanel = true;
        }
      else if(!inside && m_mouseOverPanel)
        {
         ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
         ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);
         m_mouseOverPanel = false;
        }
     }

   bool                       ConsumeCommand(SUICommand &command)
     {
      if(!m_hasPendingCommand)
         return false;
      command = m_pendingCommand;
      ClearPendingCommand();
      return true;
     }

   virtual void               ChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_created)
         return;

      if(id == CHARTEVENT_MOUSE_MOVE)
         MouseProtection((int)lparam, (int)dparam);

      if(m_minimized)
        {
         CAppDialog::ChartEvent(id, lparam, dparam, sparam);
         return;
        }

      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(HandlePanelClick(sparam))
           {
            ChartRedraw();
            return;
           }
        }

      CAppDialog::ChartEvent(id, lparam, dparam, sparam);

      bool refreshAfterEvent = false;
      if((id == CHARTEVENT_OBJECT_ENDEDIT || id == CHARTEVENT_OBJECT_CHANGE) && IsDeferredRefreshEdit(sparam))
         refreshAfterEvent = true;

      if(refreshAfterEvent)
        {
         HandleStrategyPanelDeferredEdit(sparam);
         if(id == CHARTEVENT_OBJECT_ENDEDIT)
           {
            NormalizeStrategyDeferredEdit(sparam);
            NormalizeProtectionDeferredEdit(sparam);
           }
         RefreshConfigValidation();
         ChartRedraw();
        }
     }

   virtual bool               OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      bool result = CAppDialog::OnEvent(id, lparam, dparam, sparam);
      if(!m_minimized)
        {
         if(HandleSignalPanelChange(id, sparam))
            return true;
        }
      return result;
     }
  };

#endif
