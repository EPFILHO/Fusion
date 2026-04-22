#ifndef __FUSION_UI_PANEL_STATUS_RESULTS_MQH__
#define __FUSION_UI_PANEL_STATUS_RESULTS_MQH__

   CLabel                     m_statusLabels[8];
   CLabel                     m_statusValues[8];
   CLabel                     m_resultsLabels[6];
   CLabel                     m_resultsValues[6];

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

#endif
