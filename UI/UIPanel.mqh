#ifndef __FUSION_UI_PANEL_MQH__
#define __FUSION_UI_PANEL_MQH__

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include "PanelUtils.mqh"
#include "StrategyTogglePanel.mqh"
#include "FilterTogglePanel.mqh"

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
   long                     m_chartId;
   int                      m_subWindow;
   bool                     m_created;
   SUIPanelSnapshot         m_snapshot;
   ENUM_FUSION_TAB          m_activeTab;
   ENUM_FUSION_STRATEGY_PAGE m_strategyPage;
   ENUM_FUSION_FILTER_PAGE  m_filterPage;
   ENUM_FUSION_CONFIG_PAGE  m_configPage;

   CButton                  m_btnStart;
   CButton                  m_btnSave;
   CButton                  m_btnLoad;
   CEdit                    m_editProfile;
   CLabel                   m_lblProfile;
   CLabel                   m_lblHeader;

   CButton                  m_tabs[FUSION_TAB_COUNT];
   CButton                  m_strategyTabs[FUSION_STRAT_COUNT];
   CButton                  m_filterTabs[FUSION_FILTER_COUNT];
   CButton                  m_configTabs[FUSION_CFG_COUNT];

   CLabel                   m_statusLabels[8];
   CLabel                   m_statusValues[8];
   CLabel                   m_resultsLabels[6];
   CLabel                   m_resultsValues[6];

   CLabel                   m_strategyOverviewHdr;
   CLabel                   m_strategyOverviewName[3];
   CLabel                   m_strategyOverviewState[3];
   CLabel                   m_filterOverviewHdr;
   CLabel                   m_filterOverviewName[2];
   CLabel                   m_filterOverviewState[2];

   CLabel                   m_cfgRiskHdr;
   CLabel                   m_cfgRiskLotLbl;
   CEdit                    m_cfgRiskLotEdit;
   CLabel                   m_cfgRiskSpreadLbl;
   CEdit                    m_cfgRiskSpreadEdit;

   CLabel                   m_cfgProtectionHdr;
   CLabel                   m_cfgProtectionStartedLbl;
   CButton                  m_cfgProtectionStartedBtn;
   CLabel                   m_cfgProtectionPositionLbl;
   CLabel                   m_cfgProtectionPositionVal;

   CLabel                   m_cfgSystemHdr;
   CLabel                   m_cfgSystemMagicLbl;
   CEdit                    m_cfgSystemMagicEdit;
   CLabel                   m_cfgSystemConflictLbl;
   CButton                  m_cfgSystemConflictBtn;
   CButton                  m_cfgApplyBtn;

   CStrategyPanelBase      *m_strategyPanels[3];
   CFilterPanelBase        *m_filterPanels[2];

   bool                     AddLabel(CLabel &label,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color clr,const int size=8)
     {
      if(!label.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      label.Text(text);
      label.Color(clr);
      label.FontSize(size);
      return Add(label);
     }

   bool                     AddButton(CButton &button,const string name,const int x1,const int y1,const int x2,const int y2,const string text,const color bg)
     {
      if(!button.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      button.Text(text);
      button.FontSize(8);
      button.Color(clrWhite);
      button.ColorBackground(bg);
      return Add(button);
     }

   bool                     AddEdit(CEdit &edit,const string name,const int x1,const int y1,const int x2,const int y2,const string value)
     {
      if(!edit.Create(m_chartId, name, m_subWindow, x1, y1, x2, y2))
         return false;
      edit.Text(value);
      edit.Color(clrBlack);
      edit.ColorBackground(clrWhite);
      return Add(edit);
     }

   void                     UpdateHeaderButtons(void)
     {
      m_btnStart.Text(m_snapshot.started ? "PAUSAR" : "INICIAR");
      m_btnStart.ColorBackground(m_snapshot.started ? FUSION_CLR_WARN : FUSION_CLR_GOOD);
      m_editProfile.Text(m_snapshot.activeProfileName);
     }

   void                     UpdateTabStyles(void)
     {
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_tabs[i], i == (int)m_activeTab);
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_strategyTabs[i], i == (int)m_strategyPage);
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_filterTabs[i], i == (int)m_filterPage);
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
         FusionApplyPrimaryButtonStyle(m_configTabs[i], i == (int)m_configPage);
      FusionApplyToggleButtonStyle(m_cfgProtectionStartedBtn, m_snapshot.started);
      m_cfgSystemConflictBtn.Text(FusionConflictText(m_snapshot.conflictMode));
     }

   void                     SetVisible(CWnd &control,const bool visible)
     {
      if(visible)
         control.Show();
      else
         control.Hide();
     }

   void                     UpdateStatusTab(void)
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

   void                     UpdateResultsTab(void)
     {
      m_resultsValues[0].Text(DoubleToString(m_snapshot.fixedLot, 2));
      m_resultsValues[1].Text(IntegerToString(m_snapshot.maxSpreadPoints));
      m_resultsValues[2].Text(IntegerToString(m_snapshot.magicNumber));
      m_resultsValues[3].Text(m_snapshot.activeProfileName);
      m_resultsValues[4].Text(m_snapshot.started ? "HOT RELOAD READY" : "EDIT MODE");
      m_resultsValues[5].Text(m_snapshot.hasPosition ? "EA COM POSICAO" : "EA SEM POSICAO");
     }

   void                     UpdateOverviews(void)
     {
      string strategyNames[3] = {"MA Cross", "RSI", "Bollinger"};
      bool strategyStates[3] = {m_snapshot.useMACross, m_snapshot.useRSI, m_snapshot.useBollinger};
      for(int i = 0; i < 3; ++i)
        {
         m_strategyOverviewName[i].Text(strategyNames[i]);
         m_strategyOverviewState[i].Text(strategyStates[i] ? "ATIVA" : "OFF");
         m_strategyOverviewState[i].Color(strategyStates[i] ? FUSION_CLR_GOOD : FUSION_CLR_BAD);
        }

      string filterNames[2] = {"Trend", "RSI"};
      bool filterStates[2] = {m_snapshot.useTrendFilter, m_snapshot.useRSIFilter};
      for(int j = 0; j < 2; ++j)
        {
         m_filterOverviewName[j].Text(filterNames[j]);
         m_filterOverviewState[j].Text(filterStates[j] ? "ATIVO" : "OFF");
         m_filterOverviewState[j].Color(filterStates[j] ? FUSION_CLR_GOOD : FUSION_CLR_BAD);
        }
     }

   void                     UpdateConfigTab(void)
     {
      m_cfgRiskLotEdit.Text(DoubleToString(m_snapshot.fixedLot, 2));
      m_cfgRiskSpreadEdit.Text(IntegerToString(m_snapshot.maxSpreadPoints));
      m_cfgSystemMagicEdit.Text(IntegerToString(m_snapshot.magicNumber));
      m_cfgProtectionPositionVal.Text(m_snapshot.hasPosition ? "SIM" : "NAO");
     }

   void                     SetStatusVisible(const bool visible)
     {
      for(int i = 0; i < 8; ++i)
        {
         SetVisible(m_statusLabels[i], visible);
         SetVisible(m_statusValues[i], visible);
        }
     }

   void                     SetResultsVisible(const bool visible)
     {
      for(int i = 0; i < 6; ++i)
        {
         SetVisible(m_resultsLabels[i], visible);
         SetVisible(m_resultsValues[i], visible);
        }
     }

   void                     SetStrategiesVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         SetVisible(m_strategyTabs[i], visible);
      SetVisible(m_strategyOverviewHdr, visible && m_strategyPage == FUSION_STRAT_OVERVIEW);
      for(int j = 0; j < 3; ++j)
        {
         SetVisible(m_strategyOverviewName[j], visible && m_strategyPage == FUSION_STRAT_OVERVIEW);
         SetVisible(m_strategyOverviewState[j], visible && m_strategyPage == FUSION_STRAT_OVERVIEW);
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

   void                     SetFiltersVisible(const bool visible)
     {
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
         SetVisible(m_filterTabs[i], visible);
      SetVisible(m_filterOverviewHdr, visible && m_filterPage == FUSION_FILTER_OVERVIEW);
      for(int j = 0; j < 2; ++j)
        {
         SetVisible(m_filterOverviewName[j], visible && m_filterPage == FUSION_FILTER_OVERVIEW);
         SetVisible(m_filterOverviewState[j], visible && m_filterPage == FUSION_FILTER_OVERVIEW);
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

   void                     SetConfigVisible(const bool visible)
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
      SetVisible(m_cfgApplyBtn, visible);
     }

   void                     ApplyVisibility(void)
     {
      SetStatusVisible(m_activeTab == FUSION_TAB_STATUS);
      SetResultsVisible(m_activeTab == FUSION_TAB_RESULTS);
      SetStrategiesVisible(m_activeTab == FUSION_TAB_STRATEGIES);
      SetFiltersVisible(m_activeTab == FUSION_TAB_FILTERS);
      SetConfigVisible(m_activeTab == FUSION_TAB_CONFIG);
      UpdateTabStyles();
     }

   bool                     BuildHeader(void)
     {
      if(!AddLabel(m_lblHeader, "Fusion_hdr", 10, 8, 250, 28, "Fusion Control", FUSION_CLR_VALUE, 10))
         return false;
      if(!AddButton(m_btnStart, "Fusion_btnStart", 260, 6, 350, 28, "INICIAR", FUSION_CLR_GOOD))
         return false;
      if(!AddButton(m_btnSave, "Fusion_btnSave", 356, 6, 430, 28, "SALVAR", FUSION_CLR_ACCENT_DARK))
         return false;
      if(!AddButton(m_btnLoad, "Fusion_btnLoad", 436, 6, 510, 28, "CARREGAR", FUSION_CLR_ACCENT))
         return false;
      if(!AddLabel(m_lblProfile, "Fusion_lblProfile", 10, 34, 70, 52, "Perfil", FUSION_CLR_MUTED))
         return false;
      if(!AddEdit(m_editProfile, "Fusion_editProfile", 72, 34, 220, 54, m_snapshot.activeProfileName))
         return false;
      return true;
     }

   bool                     BuildTabs(void)
     {
      string names[FUSION_TAB_COUNT] = {"STATUS", "RESULTS", "STRATS", "FILTERS", "CONFIG"};
      int x = 10;
      for(int i = 0; i < FUSION_TAB_COUNT; ++i)
        {
         if(!AddButton(m_tabs[i], "Fusion_tab_" + IntegerToString(i), x, 62, x + 96, 84, names[i], FUSION_CLR_PANEL))
            return false;
         x += 100;
        }
      return true;
     }

   bool                     BuildStatusTab(void)
     {
      string labels[8] = {"Estado", "Symbol", "Timeframe", "Strategies", "Filters", "Posicao", "Owner", "Resolver"};
      int y = 100;
      for(int i = 0; i < 8; ++i)
        {
         if(!AddLabel(m_statusLabels[i], "Fusion_status_lbl_" + IntegerToString(i), 20, y, 150, y + 16, labels[i], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_statusValues[i], "Fusion_status_val_" + IntegerToString(i), 170, y, 490, y + 16, "--", FUSION_CLR_VALUE))
            return false;
         y += 26;
        }
      return true;
     }

   bool                     BuildResultsTab(void)
     {
      string labels[6] = {"Lote", "Max Spread", "Magic", "Perfil", "Modo", "Execucao"};
      int y = 100;
      for(int i = 0; i < 6; ++i)
        {
         if(!AddLabel(m_resultsLabels[i], "Fusion_results_lbl_" + IntegerToString(i), 20, y, 150, y + 16, labels[i], FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_resultsValues[i], "Fusion_results_val_" + IntegerToString(i), 170, y, 490, y + 16, "--", FUSION_CLR_VALUE))
            return false;
         y += 28;
        }
      return true;
     }

   bool                     BuildStrategyTab(void)
     {
      string pageNames[FUSION_STRAT_COUNT] = {"GERAL", "MA", "RSI", "BB"};
      int x = 18;
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(!AddButton(m_strategyTabs[i], "Fusion_strat_tab_" + IntegerToString(i), x, 100, x + 90, 122, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 96;
        }

      if(!AddLabel(m_strategyOverviewHdr, "Fusion_strat_overview_hdr", 20, 142, 250, 160, "Visao Geral das Estrategias", FUSION_CLR_VALUE, 9))
         return false;

      int y = 176;
      for(int i = 0; i < 3; ++i)
        {
         if(!AddLabel(m_strategyOverviewName[i], "Fusion_strat_name_" + IntegerToString(i), 22, y, 220, y + 16, "--", FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_strategyOverviewState[i], "Fusion_strat_state_" + IntegerToString(i), 240, y, 360, y + 16, "--", FUSION_CLR_VALUE))
            return false;
         y += 28;
        }

      m_strategyPanels[0] = new CStrategyTogglePanel("MA Cross", "ma", UI_COMMAND_TOGGLE_MACROSS);
      m_strategyPanels[1] = new CStrategyTogglePanel("RSI", "rsi", UI_COMMAND_TOGGLE_RSI);
      m_strategyPanels[2] = new CStrategyTogglePanel("Bollinger", "bb", UI_COMMAND_TOGGLE_BB);

      int panelY1 = 148;
      int panelY2 = 300;
      for(int p = 0; p < 3; ++p)
        {
         if(m_strategyPanels[p] == NULL)
            return false;
         if(!m_strategyPanels[p].Create(this, m_chartId, m_subWindow, 24, panelY1, 470, panelY2))
            return false;
        }
      return true;
     }

   bool                     BuildFilterTab(void)
     {
      string pageNames[FUSION_FILTER_COUNT] = {"GERAL", "TREND", "RSI"};
      int x = 18;
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(!AddButton(m_filterTabs[i], "Fusion_filter_tab_" + IntegerToString(i), x, 100, x + 90, 122, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 96;
        }

      if(!AddLabel(m_filterOverviewHdr, "Fusion_filter_overview_hdr", 20, 142, 250, 160, "Visao Geral dos Filtros", FUSION_CLR_VALUE, 9))
         return false;

      int y = 176;
      for(int i = 0; i < 2; ++i)
        {
         if(!AddLabel(m_filterOverviewName[i], "Fusion_filter_name_" + IntegerToString(i), 22, y, 220, y + 16, "--", FUSION_CLR_LABEL))
            return false;
         if(!AddLabel(m_filterOverviewState[i], "Fusion_filter_state_" + IntegerToString(i), 240, y, 360, y + 16, "--", FUSION_CLR_VALUE))
            return false;
         y += 28;
        }

      m_filterPanels[0] = new CFilterTogglePanel("Trend Filter", "trend", UI_COMMAND_TOGGLE_TREND_FILTER);
      m_filterPanels[1] = new CFilterTogglePanel("RSI Filter", "rsi", UI_COMMAND_TOGGLE_RSI_FILTER);

      for(int p = 0; p < 2; ++p)
        {
         if(m_filterPanels[p] == NULL)
            return false;
         if(!m_filterPanels[p].Create(this, m_chartId, m_subWindow, 24, 148, 470, 300))
            return false;
        }
      return true;
     }

   bool                     BuildConfigTab(void)
     {
      string pageNames[FUSION_CFG_COUNT] = {"RISK", "PROTECT", "SYSTEM"};
      int x = 18;
      for(int i = 0; i < FUSION_CFG_COUNT; ++i)
        {
         if(!AddButton(m_configTabs[i], "Fusion_cfg_tab_" + IntegerToString(i), x, 100, x + 108, 122, pageNames[i], FUSION_CLR_PANEL))
            return false;
         x += 114;
        }

      if(!AddLabel(m_cfgRiskHdr, "Fusion_cfg_risk_hdr", 22, 150, 250, 168, "Risco Base", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgRiskLotLbl, "Fusion_cfg_lot_lbl", 22, 184, 120, 200, "Lote Fixo", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskLotEdit, "Fusion_cfg_lot_edit", 180, 182, 270, 204, "0.10"))
         return false;
      if(!AddLabel(m_cfgRiskSpreadLbl, "Fusion_cfg_spread_lbl", 22, 214, 150, 230, "Max Spread", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgRiskSpreadEdit, "Fusion_cfg_spread_edit", 180, 212, 270, 234, "0"))
         return false;

      if(!AddLabel(m_cfgProtectionHdr, "Fusion_cfg_prot_hdr", 22, 150, 260, 168, "Protecao Runtime", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgProtectionStartedLbl, "Fusion_cfg_started_lbl", 22, 184, 150, 200, "EA Start", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgProtectionStartedBtn, "Fusion_cfg_started_btn", 180, 182, 270, 204, "OFF", FUSION_CLR_BAD))
         return false;
      if(!AddLabel(m_cfgProtectionPositionLbl, "Fusion_cfg_pos_lbl", 22, 214, 150, 230, "Posicao", FUSION_CLR_LABEL))
         return false;
      if(!AddLabel(m_cfgProtectionPositionVal, "Fusion_cfg_pos_val", 180, 214, 260, 230, "--", FUSION_CLR_VALUE))
         return false;

      if(!AddLabel(m_cfgSystemHdr, "Fusion_cfg_system_hdr", 22, 150, 260, 168, "Sistema e Persistencia", FUSION_CLR_VALUE, 9))
         return false;
      if(!AddLabel(m_cfgSystemMagicLbl, "Fusion_cfg_magic_lbl", 22, 184, 150, 200, "Magic", FUSION_CLR_LABEL))
         return false;
      if(!AddEdit(m_cfgSystemMagicEdit, "Fusion_cfg_magic_edit", 180, 182, 300, 204, "0"))
         return false;
      if(!AddLabel(m_cfgSystemConflictLbl, "Fusion_cfg_conflict_lbl", 22, 214, 160, 230, "Resolver", FUSION_CLR_LABEL))
         return false;
      if(!AddButton(m_cfgSystemConflictBtn, "Fusion_cfg_conflict_btn", 180, 212, 300, 234, "PRIORITY", FUSION_CLR_PANEL))
         return false;
      if(!AddButton(m_cfgApplyBtn, "Fusion_cfg_apply_btn", 22, 280, 140, 304, "APLICAR", FUSION_CLR_ACCENT))
         return false;
      return true;
     }

public:
                        CFusionPanel(void)
     {
      m_chartId      = 0;
      m_subWindow    = 0;
      m_created      = false;
      m_activeTab    = FUSION_TAB_STATUS;
      m_strategyPage = FUSION_STRAT_OVERVIEW;
      m_filterPage   = FUSION_FILTER_OVERVIEW;
      m_configPage   = FUSION_CFG_RISK;
      for(int i = 0; i < 3; ++i)
         m_strategyPanels[i] = NULL;
      for(int j = 0; j < 2; ++j)
         m_filterPanels[j] = NULL;
      ZeroMemory(m_snapshot);
     }

                       ~CFusionPanel(void)
     {
      Destroy();
     }

   bool                 AddControl(CWnd &control)
     {
      return Add(control);
     }

   bool                 Create(const long chartId,const SUIPanelSnapshot &snapshot)
     {
      m_chartId   = chartId;
      m_snapshot  = snapshot;
      m_subWindow = 0;

      if(!CAppDialog::Create(chartId, "FusionPanel", m_subWindow, 10, 20, 530, 360))
         return false;

      if(!BuildHeader()) return false;
      if(!BuildTabs()) return false;
      if(!BuildStatusTab()) return false;
      if(!BuildResultsTab()) return false;
      if(!BuildStrategyTab()) return false;
      if(!BuildFilterTab()) return false;
      if(!BuildConfigTab()) return false;

      m_created = true;
      Update(snapshot);
      return true;
     }

   void                 Destroy(void)
     {
      if(!m_created)
         return;
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
      CAppDialog::Destroy();
      m_created = false;
     }

   void                 Update(const SUIPanelSnapshot &snapshot)
     {
      if(!m_created)
         return;
      m_snapshot = snapshot;
      UpdateHeaderButtons();
      UpdateStatusTab();
      UpdateResultsTab();
      UpdateOverviews();
      UpdateConfigTab();
      for(int i = 0; i < 3; ++i)
         if(m_strategyPanels[i] != NULL)
            m_strategyPanels[i].Sync(m_snapshot);
      for(int j = 0; j < 2; ++j)
         if(m_filterPanels[j] != NULL)
            m_filterPanels[j].Sync(m_snapshot);
      ApplyVisibility();
   }

   string               ProfileName(void) const
     {
      return m_editProfile.Text();
     }

   double               EditedFixedLot(void) const
     {
      return StringToDouble(m_cfgRiskLotEdit.Text());
     }

   int                  EditedMaxSpread(void) const
     {
      return (int)StringToInteger(m_cfgRiskSpreadEdit.Text());
     }

   int                  EditedMagicNumber(void) const
     {
      return (int)StringToInteger(m_cfgSystemMagicEdit.Text());
     }

   ENUM_CONFLICT_RESOLUTION EditedConflictMode(void) const
     {
      return m_snapshot.conflictMode;
     }

   void                 SetProfileName(const string profileName)
     {
      m_editProfile.Text(profileName);
     }

   bool                 HandleChartEvent(const int id,const string objectName,SUICommand &command)
     {
      command.type = UI_COMMAND_NONE;
      command.text = "";
      command.hasSettings = false;
      command.reloadScope = RELOAD_HOT;

      if(!m_created)
         return false;

      if(id != CHARTEVENT_OBJECT_CLICK)
         return false;

      if(objectName == m_btnStart.Name())
         command.type = UI_COMMAND_TOGGLE_RUNNING;
      else if(objectName == m_btnSave.Name())
         command.type = UI_COMMAND_SAVE_PROFILE;
      else if(objectName == m_btnLoad.Name())
         command.type = UI_COMMAND_LOAD_PROFILE;
      else if(objectName == m_cfgSystemConflictBtn.Name())
        {
         m_snapshot.conflictMode = (m_snapshot.conflictMode == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
         UpdateTabStyles();
         return true;
        }
      else if(objectName == m_cfgProtectionStartedBtn.Name())
         command.type = UI_COMMAND_TOGGLE_RUNNING;
      else if(objectName == m_cfgApplyBtn.Name())
        {
         command.type = UI_COMMAND_APPLY_SETTINGS;
         command.reloadScope = RELOAD_HOT;
        }
      else
        {
         for(int t = 0; t < FUSION_TAB_COUNT; ++t)
            if(objectName == m_tabs[t].Name())
              {
               m_activeTab = (ENUM_FUSION_TAB)t;
               ApplyVisibility();
               return true;
              }

         for(int s = 0; s < FUSION_STRAT_COUNT; ++s)
            if(objectName == m_strategyTabs[s].Name())
              {
               m_strategyPage = (ENUM_FUSION_STRATEGY_PAGE)s;
               ApplyVisibility();
               return true;
              }

         for(int f = 0; f < FUSION_FILTER_COUNT; ++f)
            if(objectName == m_filterTabs[f].Name())
              {
               m_filterPage = (ENUM_FUSION_FILTER_PAGE)f;
               ApplyVisibility();
               return true;
              }

         for(int c = 0; c < FUSION_CFG_COUNT; ++c)
            if(objectName == m_configTabs[c].Name())
              {
               m_configPage = (ENUM_FUSION_CONFIG_PAGE)c;
               ApplyVisibility();
               return true;
              }

         for(int sp = 0; sp < 3; ++sp)
            if(m_strategyPanels[sp] != NULL && m_strategyPanels[sp].HandleClick(objectName, command))
               break;
         for(int fp = 0; fp < 2 && command.type == UI_COMMAND_NONE; ++fp)
            if(m_filterPanels[fp] != NULL && m_filterPanels[fp].HandleClick(objectName, command))
               break;
        }

      command.text = ProfileName();
      return command.type != UI_COMMAND_NONE;
     }
  };

#endif
