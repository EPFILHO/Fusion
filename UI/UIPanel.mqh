#ifndef __FUSION_UI_PANEL_MQH__
#define __FUSION_UI_PANEL_MQH__

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include "PanelUtils.mqh"
#include "StrategyTogglePanel.mqh"
#include "FilterTogglePanel.mqh"

#define FUSION_PANEL_WIDTH   560
#define FUSION_PANEL_HEIGHT  626
#define FUSION_PANEL_TOP     20

enum ENUM_FUSION_TAB
  {
   FUSION_TAB_STATUS = 0,
   FUSION_TAB_RESULTS,
   FUSION_TAB_STRATEGIES,
   FUSION_TAB_FILTERS,
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
   string                     m_committedProfileName;
   ENUM_FUSION_TAB            m_activeTab;
   ENUM_FUSION_STRATEGY_PAGE  m_strategyPage;
   ENUM_FUSION_FILTER_PAGE    m_filterPage;
   ENUM_FUSION_CONFIG_PAGE    m_configPage;

   CButton                    m_btnStart;
   CButton                    m_btnSave;
   CButton                    m_btnLoad;
   CEdit                      m_editProfile;
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

   void                       SetVisible(CWnd &control,const bool visible)
     {
      if(visible)
         control.Show();
      else
         control.Hide();
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
      return FusionTrimCopy(m_editProfile.Text());
     }

   string                     CommittedLotText(void)
     {
      return FusionNormalizeDecimalText(FusionFormatVolume(m_committedSettings.fixedLot, m_snapshot.symbolSpec));
     }

   bool                       HasPendingChanges(void)
     {
      if(!m_hasCommittedSettings)
         return false;

      if(DraftProfileName() != m_committedProfileName)
         return true;

      string lotText = FusionNormalizeDecimalText(m_cfgRiskLotEdit.Text());
      if(FusionIsDecimalText(lotText, false))
        {
         if(MathAbs(StringToDouble(lotText) - m_committedSettings.fixedLot) > 0.0000001)
            return true;
        }
      else if(lotText != CommittedLotText())
         return true;

      string spreadText = FusionTrimCopy(m_cfgRiskSpreadEdit.Text());
      if(FusionIsIntegerText(spreadText, true))
        {
         if((int)StringToInteger(spreadText) != m_committedSettings.maxSpreadPoints)
            return true;
        }
      else if(spreadText != IntegerToString(m_committedSettings.maxSpreadPoints))
         return true;

      string magicText = FusionTrimCopy(m_cfgSystemMagicEdit.Text());
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

      string lotText = FusionNormalizeDecimalText(m_cfgRiskLotEdit.Text());
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

      string spreadText = FusionTrimCopy(m_cfgRiskSpreadEdit.Text());
      if(FusionIsIntegerText(spreadText, true))
        {
         parsedSpread = (int)StringToInteger(spreadText);
         spreadValid = (parsedSpread >= 0);
        }

      string magicText = FusionTrimCopy(m_cfgSystemMagicEdit.Text());
      if(FusionIsIntegerText(magicText, false))
        {
         parsedMagic = (int)StringToInteger(magicText);
         magicValid = (parsedMagic > 0);
        }

      FusionApplyEditStyle(m_editProfile, profileValid, true);
      FusionApplyEditStyle(m_cfgRiskLotEdit, lotValid, true);
      FusionApplyEditStyle(m_cfgRiskSpreadEdit, spreadValid, true);
      FusionApplyEditStyle(m_cfgSystemMagicEdit, magicValid, true);

      m_lblProfile.Color(profileValid ? FUSION_CLR_MUTED : FUSION_CLR_BAD);
      m_cfgRiskLotLbl.Color(lotValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD);
      m_cfgRiskSpreadLbl.Color(spreadValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD);
      m_cfgSystemMagicLbl.Color(magicValid ? FUSION_CLR_LABEL : FUSION_CLR_BAD);

      m_configInputsValid = profileValid && lotValid && spreadValid && magicValid;
      if(m_configInputsValid)
        {
         outSettings.fixedLot = parsedLot;
         outSettings.maxSpreadPoints = parsedSpread;
         outSettings.magicNumber = parsedMagic;
        }

      bool dirty = HasPendingChanges();
      if(!m_configInputsValid)
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
      bool dirty = HasPendingChanges();

      if(m_snapshot.started)
        {
         m_btnStart.Text("PAUSAR");
         FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_WARN, true);
         FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, true);
         return;
        }

      m_btnStart.Text("INICIAR");
      if(!dirty && m_configInputsValid)
         FusionApplyActionButtonStyle(m_btnStart, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnStart);

      FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, false);
     }

   void                       RefreshTheme(void)
     {
      bool dirty = HasPendingChanges();

      if(!dirty)
         FusionApplyNeutralButtonStyle(m_btnSave);
      else if(m_configInputsValid)
         FusionApplyActionButtonStyle(m_btnSave, FUSION_CLR_GOOD, true);
      else
         FusionApplyBlockedButtonStyle(m_btnSave);

      FusionApplyActionButtonStyle(m_btnLoad, FUSION_CLR_ACTION_LOAD, true);
      FusionApplyActionButtonStyle(m_cfgSystemConflictBtn, FUSION_CLR_NAV_IDLE, true);
      FusionApplyEditStyle(m_editProfile, !FusionIsBlank(DraftProfileName()), true);
      UpdateHeaderButtons();
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
      if(!AddLabel(m_lblProfile, "Fusion_lblProfile", 10, 36, 70, 54, "Perfil", FUSION_CLR_MUTED))
         return false;
      if(!AddEdit(m_editProfile, "Fusion_editProfile", 72, 34, 250, 56, m_snapshot.activeProfileName))
         return false;
      return true;
     }

   bool                       BuildTabs(void)
     {
      string names[FUSION_TAB_COUNT] = {"STATUS", "RESULTS", "STRATS", "FILTERS", "CONFIG"};
      int x = 10;
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(!AddButton(m_tabs[i], "Fusion_tab_" + IntegerToString(i), x, 68, x + 100, 92, names[i], FUSION_CLR_PANEL))
            return false;
         x += 104;
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
         if(m_snapshot.started)
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         else if(m_configInputsValid && !HasPendingChanges())
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
         if(valid && HasPendingChanges())
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
         QueueSimpleCommand(UI_COMMAND_LOAD_PROFILE);
         return true;
        }
      if(objectName == m_cfgProtectionStartedBtn.Name())
        {
         ReleaseButton(m_cfgProtectionStartedBtn);
         if(m_snapshot.started)
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         else if(m_configInputsValid && !HasPendingChanges())
            QueueSimpleCommand(UI_COMMAND_TOGGLE_RUNNING);
         RefreshTheme();
         return true;
        }
      if(objectName == m_cfgSystemConflictBtn.Name())
        {
         ReleaseButton(m_cfgSystemConflictBtn);
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

      SUICommand tempCommand;
      for(int sp = 0; sp < 3; ++sp)
        {
         if(m_strategyPanels[sp] == NULL)
            continue;
         ResetCommand(tempCommand);
         if(m_strategyPanels[sp].HandleClick(objectName, tempCommand))
           {
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            UpdateOverviews();
            for(int i = 0; i < 3; ++i)
               if(m_strategyPanels[i] != NULL)
                  m_strategyPanels[i].Sync(m_draftSettings);
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
            ToggleDraftFlag(tempCommand.type);
            RefreshConfigValidation();
            UpdateOverviews();
            for(int j = 0; j < 2; ++j)
               if(m_filterPanels[j] != NULL)
                  m_filterPanels[j].Sync(m_draftSettings);
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

      m_editProfile.Text(m_committedProfileName);
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSpreadEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
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

      m_editProfile.Text(m_committedProfileName);
      m_cfgRiskLotEdit.Text(FusionFormatVolume(m_draftSettings.fixedLot, m_snapshot.symbolSpec));
      m_cfgRiskSpreadEdit.Text(IntegerToString(m_draftSettings.maxSpreadPoints));
      m_cfgSystemMagicEdit.Text(IntegerToString(m_draftSettings.magicNumber));
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_draftSettings.conflictMode));
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
            m_strategyPanels[i].Sync(m_draftSettings);
      for(int j = 0; j < 2; ++j)
         if(m_filterPanels[j] != NULL)
            m_filterPanels[j].Sync(m_draftSettings);
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
