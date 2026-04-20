#ifndef __FUSION_UI_PANEL_MQH__
#define __FUSION_UI_PANEL_MQH__

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include "PanelUtils.mqh"
#include "StrategyTogglePanel.mqh"
#include "FilterTogglePanel.mqh"
#include "../Persistence/SettingsStore.mqh"

#define FUSION_PANEL_WIDTH   560
#define FUSION_PANEL_HEIGHT  626
#define FUSION_PANEL_TOP     20
#define FUSION_PROFILE_VISIBLE_ROWS 8

enum ENUM_FUSION_TAB
  {
   FUSION_TAB_STATUS = 0,
   FUSION_TAB_RESULTS,
   FUSION_TAB_STRATEGIES,
   FUSION_TAB_FILTERS,
   FUSION_TAB_PROFILES,
   FUSION_TAB_CONFIG,
   FUSION_TAB_COUNT
  };

enum ENUM_FUSION_STRATEGY_PAGE
  {
   FUSION_STRAT_OVERVIEW = 0,
   FUSION_STRAT_MACROSS,
   FUSION_STRAT_RSI,
   FUSION_STRAT_BB,
   FUSION_STRAT_COUNT
  };

enum ENUM_FUSION_FILTER_PAGE
  {
   FUSION_FILTER_OVERVIEW = 0,
   FUSION_FILTER_TREND,
   FUSION_FILTER_RSI,
   FUSION_FILTER_COUNT
  };

enum ENUM_FUSION_CONFIG_PAGE
  {
   FUSION_CFG_RISK = 0,
   FUSION_CFG_PROTECTION,
   FUSION_CFG_SYSTEM,
   FUSION_CFG_COUNT
  };

class CFusionPanel : public CAppDialog
  {
private:
   long                       m_chartId;
   int                        m_subWindow;
   bool                       m_created;
   bool                       m_mouseOverPanel;
   bool                       m_origDragTrade;
   bool                       m_origMouseScroll;
   bool                       m_hasPendingCommand;
   bool                       m_configInputsValid;
   bool                       m_hasCommittedSettings;
   SUICommand                 m_pendingCommand;
   SUIPanelSnapshot           m_snapshot;
   SEASettings                m_committedSettings;
   SEASettings                m_draftSettings;
   CSettingsStore             m_profileStore;
   string                     m_committedProfileName;
   string                     m_profileNames[];
   int                        m_profileCount;
   int                        m_profileOffset;
   int                        m_profileSelected;
   string                     m_profileStatusOverride;
   color                      m_profileStatusOverrideColor;
   uint                       m_profileStatusOverrideUntil;
   ENUM_FUSION_TAB            m_activeTab;
   ENUM_FUSION_STRATEGY_PAGE  m_strategyPage;
   ENUM_FUSION_FILTER_PAGE    m_filterPage;
   ENUM_FUSION_CONFIG_PAGE    m_configPage;

   CButton                    m_btnStart;
   CButton                    m_btnSave;
   CButton                    m_btnLoad;
   CLabel                     m_activeProfile;
   CLabel                     m_lblProfile;
   CLabel                     m_lblHeader;

   CButton                    m_tabs[FUSION_TAB_COUNT];
   CButton                    m_strategyTabs[FUSION_STRAT_COUNT];
   CButton                    m_filterTabs[FUSION_FILTER_COUNT];
   CButton                    m_configTabs[FUSION_CFG_COUNT];

   CLabel                     m_statusLabels[8];
   CLabel                     m_statusValues[8];
   CLabel                     m_resultsLabels[6];
   CLabel                     m_resultsValues[6];

   CLabel                     m_strategyOverviewHdr;
   CLabel                     m_strategyOverviewName[3];
   CLabel                     m_strategyOverviewState[3];
   CLabel                     m_filterOverviewHdr;
   CLabel                     m_filterOverviewName[2];
   CLabel                     m_filterOverviewState[2];

   CLabel                     m_profilesHdr;
   CLabel                     m_profilesHint;
   CButton                    m_profileRows[FUSION_PROFILE_VISIBLE_ROWS];
   CButton                    m_profileUpBtn;
   CButton                    m_profileDownBtn;
   CButton                    m_profileRefreshBtn;
   CLabel                     m_profileNewLbl;
   CEdit                      m_profileNewEdit;
   CButton                    m_profileLoadBtn;
   CButton                    m_profileSaveAsBtn;
   CButton                    m_profileDuplicateBtn;
   CButton                    m_profileDeleteBtn;
   CLabel                     m_profileStatus;

   CLabel                     m_cfgRiskHdr;
   CLabel                     m_cfgRiskLotLbl;
   CEdit                      m_cfgRiskLotEdit;
   CLabel                     m_cfgRiskSpreadLbl;
   CEdit                      m_cfgRiskSpreadEdit;

   CLabel                     m_cfgProtectionHdr;
   CLabel                     m_cfgProtectionStartedLbl;
   CButton                    m_cfgProtectionStartedBtn;
   CLabel                     m_cfgProtectionPositionLbl;
   CLabel                     m_cfgProtectionPositionVal;

   CLabel                     m_cfgSystemHdr;
   CLabel                     m_cfgSystemMagicLbl;
   CEdit                      m_cfgSystemMagicEdit;
   CLabel                     m_cfgSystemConflictLbl;
   CButton                    m_cfgSystemConflictBtn;
   CLabel                     m_cfgStatus;

   CStrategyPanelBase        *m_strategyPanels[3];
   CFilterPanelBase          *m_filterPanels[2];

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

   bool                       AddLabel(CLabel &label,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color clr,const int size=8)
     {
      if(!label.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return Add(label);
     }

   bool                       AddButton(CButton &button,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color bg)
     {
      if(!button.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      button.Text(text);
      button.FontSize(8);
      button.Color(clrWhite);
      button.ColorBackground(bg);
      return Add(button);
     }

   bool                       AddEdit(CEdit &edit,const string name,const int x1,const int y1,const int x2,const int y2,const string value)
     {
      if(!edit.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      edit.Text(value);
      edit.Color(clrBlack);
      edit.ColorBackground(clrWhite);
      return Add(edit);
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

   bool                       CanEditSettings(void)
     {
      return (!m_snapshot.started && !m_snapshot.hasPosition);
     }

   bool                       CanPause(void)
     {
      return (m_snapshot.started && !m_snapshot.hasPosition);
     }

   bool                       CanStart(void)
     {
      return (!m_snapshot.started && !m_snapshot.hasPosition && m_configInputsValid && !HasPendingChanges());
     }

   bool                       CanSave(void)
     {
      return (CanEditSettings() && m_configInputsValid && HasPendingChanges());
     }

   bool                       CanLoad(void)
     {
      return (CanEditSettings() && !HasPendingChanges());
     }

   bool                       CanAdminProfiles(void)
     {
      return (CanEditSettings() && !HasPendingChanges());
     }

   string                     ProfileDraftName(void)
     {
      return m_profileStore.SanitizeProfileName(FusionTrimCopy(LiveEditText(m_profileNewEdit)));
     }

   bool                       HasValidProfileDraftName(void)
     {
      return !FusionIsBlank(ProfileDraftName());
     }

   string                     SelectedProfileName(void)
     {
      if(m_profileSelected < 0 || m_profileSelected >= m_profileCount)
         return "";
      return m_profileNames[m_profileSelected];
     }

   bool                       ProfileDraftMatchesSelection(void)
     {
      string selectedProfile = SelectedProfileName();
      if(selectedProfile == "")
         return false;

      string draftName = ProfileDraftName();
      if(draftName == "")
         return false;

      return (m_profileStore.SanitizeProfileName(selectedProfile) == draftName);
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

   bool                       HasPendingChanges(void)
     {
      if(!m_hasCommittedSettings)
         return false;

      string lotText = FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit));
      if(FusionIsDecimalText(lotText, false))
        {
         if(MathAbs(StringToDouble(lotText) - m_committedSettings.fixedLot) > 0.0000001)
            return true;
        }
      else if(lotText != CommittedLotText())
         return true;

      string spreadText = FusionTrimCopy(LiveEditText(m_cfgRiskSpreadEdit));
      if(FusionIsIntegerText(spreadText, true))
        {
         if((int)StringToInteger(spreadText) != m_committedSettings.maxSpreadPoints)
            return true;
        }
      else if(spreadText != IntegerToString(m_committedSettings.maxSpreadPoints))
         return true;

      string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
      if(FusionIsIntegerText(magicText, false))
        {
         if((int)StringToInteger(magicText) != m_committedSettings.magicNumber)
            return true;
        }
      else if(magicText != IntegerToString(m_committedSettings.magicNumber))
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

      return false;
     }

   bool                       BuildPendingSettings(SEASettings &outSettings,string &outProfileName,string &outStatus)
     {
      outSettings = m_draftSettings;
      outProfileName = DraftProfileName();

      bool profileValid = !FusionIsBlank(outProfileName);
      bool lotValid = false;
      bool spreadValid = false;
      bool magicValid = false;
      double parsedLot = 0.0;
      int parsedSpread = 0;
      int parsedMagic = 0;

      string lotText = FusionNormalizeDecimalText(LiveEditText(m_cfgRiskLotEdit));
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

      string spreadText = FusionTrimCopy(LiveEditText(m_cfgRiskSpreadEdit));
      if(FusionIsIntegerText(spreadText, true))
        {
         parsedSpread = (int)StringToInteger(spreadText);
         spreadValid = (parsedSpread >= 0);
        }

      string magicText = FusionTrimCopy(LiveEditText(m_cfgSystemMagicEdit));
      if(FusionIsIntegerText(magicText, false))
        {
         parsedMagic = (int)StringToInteger(magicText);
         magicValid = (parsedMagic > 0);
        }

      bool editable = CanEditSettings();
      FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, editable);
      FusionApplyEditStyle(m_cfgRiskSpreadEdit, spreadValid, editable);
      FusionApplyEditStyle(m_cfgSystemMagicEdit, magicValid, editable);

      m_lblProfile.Color(FUSION_CLR_MUTED);
      m_activeProfile.Text(profileValid ? outProfileName : "--");
      m_activeProfile.Color(profileValid ? FUSION_CLR_GOOD : FUSION_CLR_BAD);
      m_cfgRiskLotLbl.Color(!editable ? FUSION_CLR_MUTED : (lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_cfgRiskSpreadLbl.Color(!editable ? FUSION_CLR_MUTED : (spreadValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));
      m_cfgSystemMagicLbl.Color(!editable ? FUSION_CLR_MUTED : (magicValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD));

      m_configInputsValid = profileValid && lotValid && spreadValid && magicValid;
      if(m_configInputsValid)
        {
         outSettings.fixedLot = parsedLot;
         outSettings.maxSpreadPoints = parsedSpread;
         outSettings.magicNumber = parsedMagic;
        }

      bool dirty = HasPendingChanges();
      if(m_snapshot.hasPosition)
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
         outStatus = "Corrija os campos em rosa antes de salvar.";
         m_cfgStatus.Color(FUSION_CLR_BAD);
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

   void                       UpdateHeaderButtons(void)
     {
      if(m_snapshot.started)
        {
         m_btnStart.Text(m_snapshot.hasPosition ? "OPERANDO" : "PAUSAR");
         if(CanPause())
            FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_WARN, true);
         else
            FusionApplyNeutralButtonStyle(m_btnStart);
         FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, true, CanPause());
         return;
        }

      m_btnStart.Text("INICIAR");
      if(CanStart())
         FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnStart);

      FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, false, CanStart());
     }

   void                       RefreshTheme(void)
     {
      if(!CanEditSettings() || !HasPendingChanges())
         FusionApplyNeutralButtonStyle(m_btnSave);
      else if(CanSave())
         FusionApplyActionButtonStyle(m_btnSave, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnSave);

      if(CanLoad())
         FusionApplyActionButtonStyle(m_btnLoad, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_btnLoad);

      if(CanEditSettings())
         FusionApplyActionButtonStyle(m_cfgSystemConflictBtn, FUSION_CLR_NAV_IDLE, true);
      else
         FusionApplyNeutralButtonStyle(m_cfgSystemConflictBtn);

      m_activeProfile.Text(FusionIsBlank(DraftProfileName()) ? "--" : DraftProfileName());
      m_activeProfile.Color(FusionIsBlank(DraftProfileName()) ? FUSION_CLR_BAD : FUSION_CLR_GOOD);
      UpdateHeaderButtons();
      UpdateProfileListView();
     }

   void                       UpdateTabStyles(void)
     {
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_tabs[i], i == (int)m_activeTab);
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_strategyTabs[i], i == (int)m_strategyPage);
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_filterTabs[i], i == (int)m_filterPage);
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_configTabs[i], i == (int)m_configPage);
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
     }

   void                       UpdateStatusTab(void)
     {
      m_statusValues[0].Text(m_snapshot.started ? "RUNNING" : "PAUSED");
      m_statusValues[1].Text(m_snapshot.symbol);
      m_statusValues[2].Text(m_snapshot.timeframe);
      m_statusValues[3].Text(IntegerToString(m_snapshot.activeStrategies));
      m_statusValues[4].Text(IntegerToString(m_snapshot.activeFilters));
      m_statusValues[5].Text(m_snapshot.hasPosition ? "YES" : "NO");
      m_statusValues[6].Text(m_snapshot.ownerStrategyName == "" ? "--" : m_snapshot.ownerStrategyName);
      m_statusValues[7].Text(FusionConflictText(m_snapshot.conflictMode));
     }

   void                       UpdateResultsTab(void)
     {
      m_resultsValues[0].Text(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
      m_resultsValues[1].Text(IntegerToString(m_committedSettings.maxSpreadPoints));
      m_resultsValues[2].Text(IntegerToString(m_committedSettings.magicNumber));
      m_resultsValues[3].Text(m_committedProfileName == "" ? m_snapshot.activeProfileName : m_committedProfileName);
      m_resultsValues[4].Text(m_snapshot.started ? "HOT RELOAD READY" : "EDIT MODE");
      m_resultsValues[5].Text(m_snapshot.hasPosition ? "EA COM POSICAO" : "EA SEM POSICAO");
     }

   void                       UpdateOverviews(void)
     {
      string strategyNames[3] = {"MA Cross", "RSI", "Bollinger"};
      bool strategyStates[3] = {m_draftSettings.useMACross, m_draftSettings.useRSI, m_draftSettings.useBollinger};
      for(int i = 0; i < 3; ++i)
        {
         m_strategyOverviewName[i].Text(strategyNames[i]);
         FusionApplyStateLabel(m_strategyOverviewState[i], strategyStates[i], "ATIVO", "OFF");
        }

      string filterNames[2] = {"Trend", "RSI"};
      bool filterStates[2] = {m_draftSettings.useTrendFilter, m_draftSettings.useRSIFilter};
      for(int j = 0; j < 2; ++j)
        {
         m_filterOverviewName[j].Text(filterNames[j]);
         FusionApplyStateLabel(m_filterOverviewState[j], filterStates[j], "ATIVO", "OFF");
        }
     }

   void                       SetProfileStatus(const string text,const color clr,const bool persist=false)
     {
      uint now = GetTickCount();
      if(!persist && m_profileStatusOverrideUntil > now)
        {
         m_profileStatus.Text(m_profileStatusOverride);
         m_profileStatus.Color(m_profileStatusOverrideColor);
         return;
        }

      if(persist)
        {
         m_profileStatusOverride = text;
         m_profileStatusOverrideColor = clr;
         m_profileStatusOverrideUntil = now + 5000;
        }

      m_profileStatus.Text(text);
      m_profileStatus.Color(clr);
     }

   void                       EnsureProfileSelectionVisible(void)
     {
      if(m_profileSelected < 0)
        {
         m_profileOffset = 0;
         return;
        }

      if(m_profileSelected < m_profileOffset)
         m_profileOffset = m_profileSelected;

      if(m_profileSelected >= m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS)
         m_profileOffset = m_profileSelected - FUSION_PROFILE_VISIBLE_ROWS + 1;

      int maxOffset = m_profileCount - FUSION_PROFILE_VISIBLE_ROWS;
      if(maxOffset < 0)
         maxOffset = 0;
      if(m_profileOffset > maxOffset)
         m_profileOffset = maxOffset;
      if(m_profileOffset < 0)
         m_profileOffset = 0;
     }

   void                       UpdateProfileListView(void)
     {
      EnsureProfileSelectionVisible();

      string activeName = m_committedProfileName;
      string activeKey = m_profileStore.SanitizeProfileName(activeName);
      for(int i = 0; i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
        {
         int idx = m_profileOffset + i;
         if(idx >= 0 && idx < m_profileCount)
           {
            string rowText = m_profileNames[idx];
            string rowKey = m_profileStore.SanitizeProfileName(m_profileNames[idx]);
            if(rowKey == activeKey)
               rowText += "  [ATIVO]";
            m_profileRows[i].Text(rowText);

            if(idx == m_profileSelected)
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_NAV_ACTIVE, true);
            else if(rowKey == activeKey)
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_GOOD, true);
            else
               FusionApplyActionButtonStyle(m_profileRows[i], FUSION_CLR_NAV_IDLE, true);
           }
         else
           {
            m_profileRows[i].Text("");
            FusionApplyNeutralButtonStyle(m_profileRows[i]);
           }
        }

      if(m_profileOffset > 0)
         FusionApplyActionButtonStyle(m_profileUpBtn, FUSION_CLR_NAV_IDLE, true);
      else
         FusionApplyNeutralButtonStyle(m_profileUpBtn);

      if(m_profileOffset + FUSION_PROFILE_VISIBLE_ROWS < m_profileCount)
         FusionApplyActionButtonStyle(m_profileDownBtn, FUSION_CLR_NAV_IDLE, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDownBtn);

      FusionApplyActionButtonStyle(m_profileRefreshBtn, FUSION_CLR_ACTION_LOAD, true);

      bool validName = HasValidProfileDraftName();
      bool selected = (SelectedProfileName() != "");
      bool draftMatchesSelection = ProfileDraftMatchesSelection();
      bool selectedIsActive = (m_profileStore.SanitizeProfileName(SelectedProfileName()) == activeKey);
      bool draftExists = (validName && m_profileStore.ProfileExists(ProfileDraftName()));

      FusionApplyEditStyle(m_profileNewEdit, true, CanEditSettings());
      m_profileNewLbl.Color(CanEditSettings() ? FUSION_CLR_LABEL : FUSION_CLR_MUTED);

      if(CanLoad() && selected && draftMatchesSelection)
         FusionApplyActionButtonStyle(m_profileLoadBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileLoadBtn);

      if(CanEditSettings() && m_configInputsValid && validName && !draftExists)
         FusionApplyActionButtonStyle(m_profileSaveAsBtn, FUSION_CLR_GOOD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileSaveAsBtn);

      if(CanAdminProfiles() && selected && validName && !draftMatchesSelection && !draftExists)
         FusionApplyActionButtonStyle(m_profileDuplicateBtn, FUSION_CLR_ACTION_LOAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDuplicateBtn);

      if(CanAdminProfiles() && selected && draftMatchesSelection && !selectedIsActive)
         FusionApplyActionButtonStyle(m_profileDeleteBtn, FUSION_CLR_BAD, true);
      else
         FusionApplyNeutralButtonStyle(m_profileDeleteBtn);

      if(m_profileCount == 0)
         SetProfileStatus("Nenhum perfil salvo ainda. Use Salvar Como para criar.", FUSION_CLR_MUTED);
      else if(!CanEditSettings())
         SetProfileStatus("Perfis bloqueados enquanto o EA roda ou gerencia posicao.", FUSION_CLR_WARN);
      else if(HasPendingChanges())
         SetProfileStatus("Salve ou descarte alteracoes antes de carregar outro perfil.", FUSION_CLR_WARN);
      else if(selected && draftMatchesSelection)
         SetProfileStatus("Selecionado: " + SelectedProfileName() + ". Use Carregar ou informe um novo nome.", FUSION_CLR_MUTED);
      else if(selected && validName && !draftExists)
         SetProfileStatus("Novo nome: " + ProfileDraftName() + ". Salve como ou duplique o selecionado.", FUSION_CLR_MUTED);
      else if(draftExists)
         SetProfileStatus("Nome ja existe. Carregue o perfil ou escolha outro nome.", FUSION_CLR_WARN);
      else if(validName)
         SetProfileStatus("Novo perfil: " + ProfileDraftName() + ". Use Salvar Como.", FUSION_CLR_MUTED);
      else
         SetProfileStatus("Selecione um perfil na lista ou informe um novo nome.", FUSION_CLR_MUTED);
     }

   void                       RefreshProfileList(const bool keepSelection=true)
     {
      string previousSelection = keepSelection ? SelectedProfileName() : "";
      if(previousSelection == "")
         previousSelection = m_committedProfileName;

      m_profileStore.ListProfiles(m_profileNames);
      m_profileCount = ArraySize(m_profileNames);
      m_profileSelected = -1;

      for(int i = 0; i < m_profileCount; ++i)
        {
         if(m_profileStore.SanitizeProfileName(m_profileNames[i]) == m_profileStore.SanitizeProfileName(previousSelection))
           {
            m_profileSelected = i;
            break;
           }
        }

      if(m_profileSelected < 0 && m_profileCount > 0)
         m_profileSelected = 0;

      UpdateProfileListView();
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

   void                       UpdateConfigReadOnly(void)
     {
      m_cfgProtectionPositionVal.Text(m_snapshot.hasPosition ? "SIM" : "NAO");
     }

   void                       SetStatusVisible(const bool visible)
     {
      for(int i = 0; i < 8; ++i)
        {
         SetVisible(m_statusLabels[i], visible);
         SetVisible(m_statusValues[i], visible);
        }
     }

   void                       SetResultsVisible(const bool visible)
     {
      for(int i = 0; i < 6; ++i)
        {
         SetVisible(m_resultsLabels[i], visible);
         SetVisible(m_resultsValues[i], visible);
        }
     }

   void                       SetStrategiesVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         SetVisible(m_strategyTabs[i], visible);

      bool overviewVisible = visible && m_strategyPage == FUSION_STRAT_OVERVIEW;
      SetVisible(m_strategyOverviewHdr, overviewVisible);
      for(int j = 0; j < 3; ++j)
        {
         SetVisible(m_strategyOverviewName[j], overviewVisible);
         SetVisible(m_strategyOverviewState[j], overviewVisible);
        }

      for(int p = 0; p < 3; ++p)
        {
         if(m_strategyPanels[p] == NULL)
            continue;
         if(visible && m_strategyPage == (ENUM_FUSION_STRATEGY_PAGE)(p + 1))
            m_strategyPanels[p].Show();
         else
            m_strategyPanels[p].Hide();
        }
     }

   void                       SetFiltersVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         SetVisible(m_filterTabs[i], visible);

      bool overviewVisible = visible && m_filterPage == FUSION_FILTER_OVERVIEW;
      SetVisible(m_filterOverviewHdr, overviewVisible);
      for(int j = 0; j < 2; ++j)
        {
         SetVisible(m_filterOverviewName[j], overviewVisible);
         SetVisible(m_filterOverviewState[j], overviewVisible);
        }

      for(int p = 0; p < 2; ++p)
        {
         if(m_filterPanels[p] == NULL)
            continue;
         if(visible && m_filterPage == (ENUM_FUSION_FILTER_PAGE)(p + 1))
            m_filterPanels[p].Show();
         else
            m_filterPanels[p].Hide();
        }
     }

   void                       SetProfilesVisible(const bool visible)
     {
      SetVisible(m_profilesHdr, visible);
      SetVisible(m_profilesHint, visible);
      for(int i = 0; i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
         SetVisible(m_profileRows[i], visible);
      SetVisible(m_profileUpBtn, visible);
      SetVisible(m_profileDownBtn, visible);
      SetVisible(m_profileRefreshBtn, visible);
      SetVisible(m_profileNewLbl, visible);
      SetVisible(m_profileNewEdit, visible);
      SetVisible(m_profileLoadBtn, visible);
      SetVisible(m_profileSaveAsBtn, visible);
      SetVisible(m_profileDuplicateBtn, visible);
      SetVisible(m_profileDeleteBtn, visible);
      SetVisible(m_profileStatus, visible);
     }

   void                       SetConfigVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
         SetVisible(m_configTabs[i], visible);

      bool riskVisible = visible && m_configPage == FUSION_CFG_RISK;
      bool protectionVisible = visible && m_configPage == FUSION_CFG_PROTECTION;
      bool systemVisible = visible && m_configPage == FUSION_CFG_SYSTEM;

      SetVisible(m_cfgRiskHdr, riskVisible);
      SetVisible(m_cfgRiskLotLbl, riskVisible);
      SetVisible(m_cfgRiskLotEdit, riskVisible);
      SetVisible(m_cfgRiskSpreadLbl, riskVisible);
      SetVisible(m_cfgRiskSpreadEdit, riskVisible);

      SetVisible(m_cfgProtectionHdr, protectionVisible);
      SetVisible(m_cfgProtectionStartedLbl, protectionVisible);
      SetVisible(m_cfgProtectionStartedBtn, protectionVisible);
      SetVisible(m_cfgProtectionPositionLbl, protectionVisible);
      SetVisible(m_cfgProtectionPositionVal, protectionVisible);

      SetVisible(m_cfgSystemHdr, systemVisible);
      SetVisible(m_cfgSystemMagicLbl, systemVisible);
      SetVisible(m_cfgSystemMagicEdit, systemVisible);
      SetVisible(m_cfgSystemConflictLbl, systemVisible);
      SetVisible(m_cfgSystemConflictBtn, systemVisible);
      SetVisible(m_cfgStatus, visible);
     }

   void                       ApplyVisibility(void)
     {
      SetStatusVisible(m_activeTab == FUSION_TAB_STATUS);
      SetResultsVisible(m_activeTab == FUSION_TAB_RESULTS);
      SetStrategiesVisible(m_activeTab == FUSION_TAB_STRATEGIES);
      SetFiltersVisible(m_activeTab == FUSION_TAB_FILTERS);
      SetProfilesVisible(m_activeTab == FUSION_TAB_PROFILES);
      SetConfigVisible(m_activeTab == FUSION_TAB_CONFIG);
      RefreshTheme();
      UpdateTabStyles();
     }

   bool                       BuildHeader(void)
     {
      if(!AddLabel(m_lblHeader, "Fusion_hdr", 10, 6, 250, 26, "Fusion Control", FUSION_CLR_TITLE, 10))
         return false;
      if(!AddButton(m_btnStart, "Fusion_btnStart", 250, 4, 340, 28, "INICIAR", FUSION_CLR_GOOD))
         return false;
      if(!AddButton(m_btnSave, "Fusion_btnSave", 346, 4, 430, 28, "SALVAR", FUSION_CLR_ACTION_SAVE))
         return false;
      if(!AddButton(m_btnLoad, "Fusion_btnLoad", 436, 4, 530, 28, "CARREGAR", FUSION_CLR_ACTION_LOAD))
         return false;
      if(!AddLabel(m_lblProfile, "Fusion_lblProfile", 10, 36, 116, 54, "Perfil carregado:", FUSION_CLR_MUTED))
         return false;
      if(!AddLabel(m_activeProfile, "Fusion_activeProfile", 118, 36, 250, 56, m_snapshot.activeProfileName, FUSION_CLR_GOOD, 9))
         return false;
      m_activeProfile.Font("Arial Bold");
      return true;
     }

   bool                       BuildTabs(void)
     {
      string names[FUSION_TAB_COUNT] = {"STATUS", "RESULTS", "STRATS", "FILTERS", "PERFIS", "CONFIG"};
      int x = 10;
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(!AddButton(m_tabs[i], "Fusion_tab_" + IntegerToString(i), x, 68, x + 84, 92, names[i], FUSION_CLR_PANEL))
            return false;
         x += 86;
        }
      return true;
     }

   bool                       BuildStatusTab(void)
     {
      string labels[8] = {"Estado", "Symbol", "Timeframe", "Strategies", "Filters", "Posicao", "Owner", "Resolver"};
      int y = 112;
      for(int i = 0; i < 8; ++i)
        {
         if(!AddLabel(m_statusLabels[i], "Fusion_status_lbl_" + IntegerToString(i), 20, y, 170, y + 18, labels[i], FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_statusValues[i], "Fusion_status_val_" + IntegerToString(i), 190, y, 510, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 30;
        }
      return true;
     }

   bool                       BuildResultsTab(void)
     {
      string labels[6] = {"Lote", "Max Spread", "Magic", "Perfil", "Modo", "Execucao"};
      int y = 112;
      for(int i = 0; i < 6; ++i)
        {
         if(!AddLabel(m_resultsLabels[i], "Fusion_results_lbl_" + IntegerToString(i), 20, y, 170, y + 18, labels[i], FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_resultsValues[i], "Fusion_results_val_" + IntegerToString(i), 190, y, 510, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 34;
        }
      return true;
     }

   bool                       BuildStrategyTab(void)
     {
      string pageNames[FUSION_STRAT_COUNT] = {"GERAL", "MA", "RSI", "BB"};
      int x = 18;
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(!AddButton(m_strategyTabs[i], "Fusion_strat_tab_" + IntegerToString(i), x, 110, x + 96, 134, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 100;
        }

      if(!AddLabel(m_strategyOverviewHdr, "Fusion_strat_overview_hdr", 22, 156, 260, 176, "Visao Geral das Estrategias", FUSION_CLR_VALUE, 9))
         return false;

      int y = 194;
      for(int i = 0; i < 3; ++i)
        {
         if(!AddLabel(m_strategyOverviewName[i], "Fusion_strat_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_strategyOverviewState[i], "Fusion_strat_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 34;
        }

      m_strategyPanels[0] = new CStrategyTogglePanel("MA Cross", "ma", UI_COMMAND_TOGGLE_MACROSS);
      m_strategyPanels[1] = new CStrategyTogglePanel("RSI", "rsi", UI_COMMAND_TOGGLE_RSI);
      m_strategyPanels[2] = new CStrategyTogglePanel("Bollinger", "bb", UI_COMMAND_TOGGLE_BB);

      for(int p = 0; p < 3; ++p)
        {
         if(m_strategyPanels[p] == NULL)
            return false;
         if(!m_strategyPanels[p].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
            return false;
        }
      return true;
     }

   bool                       BuildFilterTab(void)
     {
      string pageNames[FUSION_FILTER_COUNT] = {"GERAL", "TREND", "RSI"};
      int x = 18;
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(!AddButton(m_filterTabs[i], "Fusion_filter_tab_" + IntegerToString(i), x, 110, x + 110, 134, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 114;
        }

      if(!AddLabel(m_filterOverviewHdr, "Fusion_filter_overview_hdr", 22, 156, 260, 176, "Visao Geral dos Filtros", FUSION_CLR_VALUE, 9))
         return false;

      int y = 194;
      for(int i = 0; i < 2; ++i)
        {
         if(!AddLabel(m_filterOverviewName[i], "Fusion_filter_name_" + IntegerToString(i), 24, y, 150, y + 18, "--", FUSION_CLR_LABEL, 9))
            return false;
         if(!AddLabel(m_filterOverviewState[i], "Fusion_filter_state_" + IntegerToString(i), 162, y, 280, y + 18, "--", FUSION_CLR_VALUE, 9))
            return false;
         y += 34;
        }

      m_filterPanels[0] = new CFilterTogglePanel("Trend Filter", "trend", UI_COMMAND_TOGGLE_TREND_FILTER);
      m_filterPanels[1] = new CFilterTogglePanel("RSI Filter", "rsi", UI_COMMAND_TOGGLE_RSI_FILTER);

      for(int p = 0; p < 2; ++p)
        {
         if(m_filterPanels[p] == NULL)
            return false;
         if(!m_filterPanels[p].Create(GetPointer(this), m_chartId, m_subWindow, 24, 164, 500, 360))
            return false;
        }
      return true;
     }

   bool                       BuildProfilesTab(void)
     {
      if(!AddLabel(m_profilesHdr, "Fusion_profiles_hdr", 22, 118, 300, 138, "Administracao de Perfis", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_profilesHint, "Fusion_profiles_hint", 22, 142, 520, 162, "Perfis da GUI sao para operacao em grafico. Backtest usa inputs do MT5.", FUSION_CLR_MUTED, 8))
         return false;

      int y = 176;
      for(int i = 0; i < FUSION_PROFILE_VISIBLE_ROWS; ++i)
        {
         if(!AddButton(m_profileRows[i], "Fusion_profile_row_" + IntegerToString(i), 24, y, 330, y + 24, "", FUSION_CLR_PANEL))
            return false;
         y += 28;
        }

      if(!AddButton(m_profileUpBtn, "Fusion_profile_up", 340, 176, 382, 202, ShortToString(0x25B2), FUSION_CLR_PANEL))
         return false;
      if(!AddButton(m_profileDownBtn, "Fusion_profile_down", 340, 208, 382, 234, ShortToString(0x25BC), FUSION_CLR_PANEL))
         return false;
      if(!AddButton(m_profileRefreshBtn, "Fusion_profile_refresh", 390, 176, 500, 202, "ATUALIZAR", FUSION_CLR_ACTION_LOAD))
         return false;

      if(!AddLabel(m_profileNewLbl, "Fusion_profile_new_lbl", 390, 236, 520, 254, "Novo nome", FUSION_CLR_LABEL, 8))
         return false;
      if(!AddEdit(m_profileNewEdit, "Fusion_profile_new_edit", 390, 258, 520, 282, ""))
         return false;

      if(!AddButton(m_profileLoadBtn, "Fusion_profile_load", 390, 298, 520, 324, "CARREGAR", FUSION_CLR_ACTION_LOAD))
         return false;
      if(!AddButton(m_profileSaveAsBtn, "Fusion_profile_save_as", 390, 330, 520, 356, "SALVAR COMO", FUSION_CLR_GOOD))
         return false;
      if(!AddButton(m_profileDuplicateBtn, "Fusion_profile_duplicate", 390, 362, 520, 388, "DUPLICAR", FUSION_CLR_ACTION_LOAD))
         return false;
      if(!AddButton(m_profileDeleteBtn, "Fusion_profile_delete", 390, 394, 520, 420, "EXCLUIR", FUSION_CLR_BAD))
         return false;

      if(!AddLabel(m_profileStatus, "Fusion_profile_status", 24, 430, 520, 456, "", FUSION_CLR_MUTED, 8))
         return false;

      return true;
     }

   bool                       BuildConfigTab(void)
     {
      string pageNames[FUSION_CFG_COUNT] = {"RISK", "PROTECT", "SYSTEM"};
      int x = 18;
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
        {
         if(!AddButton(m_configTabs[i], "Fusion_cfg_tab_" + IntegerToString(i), x, 110, x + 120, 134, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 124;
        }

      if(!AddLabel(m_cfgRiskHdr, "Fusion_cfg_risk_hdr", 22, 160, 260, 180, "Risco Base", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 198, 160, 216, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 200, 196, 310, 220, "0.10"))
         return false;
      if(!AddLabel(m_cfgRiskSpreadLbl, "Fusion_cfg_spread_lbl", 22, 236, 170, 254, "Max Spread", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSpreadEdit, "Fusion_cfg_spread_edit", 200, 234, 310, 258, "0"))
         return false;

      if(!AddLabel(m_cfgProtectionHdr, "Fusion_cfg_prot_hdr", 22, 160, 270, 180, "Protecao Runtime", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgProtectionStartedLbl, "Fusion_cfg_started_lbl", 22, 198, 170, 216, "EA Start", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgProtectionStartedBtn, "Fusion_cfg_started_btn", 200, 196, 310, 220, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgProtectionPositionLbl, "Fusion_cfg_pos_lbl", 22, 236, 170, 254, "Posicao", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(m_cfgProtectionPositionVal, "Fusion_cfg_pos_val", 200, 236, 320, 254, "--", FUSION_CLR_VALUE))
         return false;

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
      if(!AddLabel(m_cfgStatus, "Fusion_cfg_status", 22, 360, 470, 388, "", FUSION_CLR_MUTED, 8))
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
      if(objectName == m_btnLoad.Name())
        {
         ReleaseButton(m_btnLoad);
         if(CanLoad())
            QueueSimpleCommand(UI_COMMAND_LOAD_PROFILE);
         RefreshTheme();
         return true;
        }
      if(objectName == m_cfgProtectionStartedBtn.Name())
        {
         ReleaseButton(m_cfgProtectionStartedBtn);
         if(CanPause())
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         else if(CanStart())
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
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

      for(int t = 0; t < FUSION_TAB_COUNT; ++t)
        {
         if(objectName == m_tabs[t].Name())
           {
            ReleaseButton(m_tabs[t]);
            m_activeTab = (ENUM_FUSION_TAB)t;
            ApplyVisibility();
            return true;
           }
        }

      for(int s = 0; s < FUSION_STRAT_COUNT; ++s)
        {
         if(objectName == m_strategyTabs[s].Name())
           {
            ReleaseButton(m_strategyTabs[s]);
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
            m_configPage = (ENUM_FUSION_CONFIG_PAGE)c;
            ApplyVisibility();
            return true;
           }
        }

      for(int pr = 0; pr < FUSION_PROFILE_VISIBLE_ROWS; ++pr)
        {
         if(objectName == m_profileRows[pr].Name())
           {
            ReleaseButton(m_profileRows[pr]);
            int idx = m_profileOffset + pr;
            if(idx >= 0 && idx < m_profileCount)
              {
               m_profileSelected = idx;
               m_profileNewEdit.Text(m_profileNames[idx]);
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

      if(objectName == m_profileLoadBtn.Name())
        {
         ReleaseButton(m_profileLoadBtn);
         string selectedProfile = SelectedProfileName();
         if(CanLoad() && selectedProfile != "" && ProfileDraftMatchesSelection())
            QueueProfileCommand(UI_COMMAND_LOAD_PROFILE, selectedProfile);
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileSaveAsBtn.Name())
        {
         ReleaseButton(m_profileSaveAsBtn);
         string newProfileName = ProfileDraftName();
         SEASettings pendingSettings;
         string ignoredProfile = "";
         string status = "";
         bool valid = BuildPendingSettings(pendingSettings, ignoredProfile, status);
         if(CanEditSettings() && valid && newProfileName != "" && !m_profileStore.ProfileExists(newProfileName))
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
         else if(newProfileName != "" && m_profileStore.ProfileExists(newProfileName))
            SetProfileStatus("Perfil ja existe. Escolha outro nome para Salvar Como.", FUSION_CLR_WARN, true);
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileDuplicateBtn.Name())
        {
         ReleaseButton(m_profileDuplicateBtn);
         string selectedProfile = SelectedProfileName();
         string newProfileName = ProfileDraftName();
         if(CanAdminProfiles() && selectedProfile != "" && newProfileName != "" &&
            !ProfileDraftMatchesSelection() &&
            !m_profileStore.ProfileExists(newProfileName))
           {
            if(m_profileStore.CopyProfile(selectedProfile, newProfileName))
              {
               RefreshProfileList(false);
               for(int i = 0; i < m_profileCount; ++i)
                  if(m_profileNames[i] == m_profileStore.SanitizeProfileName(newProfileName))
                     m_profileSelected = i;
               UpdateProfileListView();
               SetProfileStatus("Perfil duplicado para " + newProfileName + ".", FUSION_CLR_GOOD, true);
              }
            else
               SetProfileStatus("Nao foi possivel duplicar o perfil.", FUSION_CLR_BAD, true);
           }
         else if(newProfileName != "" && m_profileStore.ProfileExists(newProfileName))
            SetProfileStatus("Perfil ja existe. Escolha outro nome para duplicar.", FUSION_CLR_WARN, true);
         else
            UpdateProfileListView();
         return true;
        }

      if(objectName == m_profileDeleteBtn.Name())
        {
         ReleaseButton(m_profileDeleteBtn);
         string selectedProfile = SelectedProfileName();
         if(CanAdminProfiles() && selectedProfile != "" && ProfileDraftMatchesSelection() &&
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
            for(int i = 0; i < 3; ++i)
               if(m_strategyPanels[i] != NULL)
                  m_strategyPanels[i].Sync(m_draftSettings, CanEditSettings());
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
            for(int j = 0; j < 2; ++j)
               if(m_filterPanels[j] != NULL)
                  m_filterPanels[j].Sync(m_draftSettings, CanEditSettings());
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

public:
                              CFusionPanel(void)
     {
      m_chartId         = 0;
      m_subWindow       = 0;
      m_created         = false;
      m_mouseOverPanel  = false;
      m_origDragTrade   = true;
      m_origMouseScroll = true;
      m_configInputsValid = true;
      m_hasCommittedSettings = false;
      m_activeTab       = FUSION_TAB_STATUS;
      m_strategyPage    = FUSION_STRAT_OVERVIEW;
      m_filterPage      = FUSION_FILTER_OVERVIEW;
      m_configPage      = FUSION_CFG_RISK;
      m_committedProfileName = "";
      ArrayResize(m_profileNames, 0);
      m_profileCount = 0;
      m_profileOffset = 0;
      m_profileSelected = -1;
      m_profileStatusOverride = "";
      m_profileStatusOverrideColor = FUSION_CLR_MUTED;
      m_profileStatusOverrideUntil = 0;
      SetDefaultSettings(m_committedSettings);
      SetDefaultSettings(m_draftSettings);
      for(int i = 0; i < 3; ++i)
         m_strategyPanels[i] = NULL;
      for(int j = 0; j < 2; ++j)
         m_filterPanels[j] = NULL;
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
      ClearPendingCommand();
     }

                             ~CFusionPanel(void)
     {
      Destroy(REASON_REMOVE);
     }

   bool                       AddControl(CWnd &control)
     {
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
      if(!BuildStatusTab())   { Destroy(REASON_REMOVE); return false; }
      if(!BuildResultsTab())  { Destroy(REASON_REMOVE); return false; }
      if(!BuildStrategyTab()) { Destroy(REASON_REMOVE); return false; }
      if(!BuildFilterTab())   { Destroy(REASON_REMOVE); return false; }
      if(!BuildProfilesTab()) { Destroy(REASON_REMOVE); return false; }
      if(!BuildConfigTab())   { Destroy(REASON_REMOVE); return false; }
      LoadSettings(snapshot);
      RefreshConfigValidation();
      Update(snapshot);
      return true;
     }

   virtual void                Destroy(const int reason=REASON_REMOVE)
     {
      if(!m_created)
         return;

      ChartSetInteger(m_chartId, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
      ChartSetInteger(m_chartId, CHART_MOUSE_SCROLL, m_origMouseScroll);

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

      CAppDialog::Destroy(reason);
      m_created = false;
     }

   void                       LoadSettings(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created)
         return;

      m_snapshot = snapshot;
      m_committedProfileName = m_snapshot.activeProfileName;
      m_hasCommittedSettings = true;

      m_committedSettings.fixedLot        = m_snapshot.fixedLot;
      m_committedSettings.maxSpreadPoints = m_snapshot.maxSpreadPoints;
      m_committedSettings.magicNumber     = m_snapshot.magicNumber;
      m_committedSettings.conflictMode    = m_snapshot.conflictMode;
      m_committedSettings.useMACross      = m_snapshot.useMACross;
      m_committedSettings.useRSI          = m_snapshot.useRSI;
      m_committedSettings.useBollinger    = m_snapshot.useBollinger;
      m_committedSettings.useTrendFilter  = m_snapshot.useTrendFilter;
      m_committedSettings.useRSIFilter    = m_snapshot.useRSIFilter;
      m_draftSettings = m_committedSettings;

      m_activeProfile.Text(m_committedProfileName);
      m_activeProfile.Color(FusionIsBlank(m_committedProfileName) ? FUSION_CLR_BAD : FUSION_CLR_GOOD);
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSpreadEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
      RefreshProfileList(false);
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

      m_activeProfile.Text(m_committedProfileName);
      m_activeProfile.Color(FusionIsBlank(m_committedProfileName) ? FUSION_CLR_BAD : FUSION_CLR_GOOD);
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSpreadEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
      RefreshProfileList(false);
      RefreshConfigValidation();
     }

   void                       Update(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created || m_minimized)
         return;

      m_snapshot = snapshot;
      UpdateHeaderButtons();
      UpdateStatusTab();
      UpdateResultsTab();
      UpdateOverviews();
      UpdateConfigReadOnly();
      RefreshConfigValidation();
      for(int i = 0; i < 3; ++i)
         if(m_strategyPanels[i] != NULL)
            m_strategyPanels[i].Sync(m_draftSettings, CanEditSettings());
      for(int j = 0; j < 2; ++j)
         if(m_filterPanels[j] != NULL)
            m_filterPanels[j].Sync(m_draftSettings, CanEditSettings());
      ApplyVisibility();
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

      if(id == CHARTEVENT_KEYDOWN || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_ENDEDIT)
        {
         RefreshConfigValidation();
         ApplyVisibility();
         ChartRedraw();
        }
     }

   virtual bool               OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      bool result = CAppDialog::OnEvent(id, lparam, dparam, sparam);
      if(!m_minimized)
        {
         RefreshConfigValidation();
         if(result)
            ApplyVisibility();
        }
      return result;
     }
  };

#endif
