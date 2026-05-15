   bool                       HasSelectedStrategy(const SEASettings &settings) const
     {
      return (settings.useMACross || settings.useRSI || settings.useBollinger);
     }

   bool                       ValidateStrategyPanels(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";
      bool allValid = true;
      bool hasSelectedStrategy = HasSelectedStrategy(candidate);
      m_strategyPageValid[(int)FUSION_STRAT_OVERVIEW] = hasSelectedStrategy;
      if(!hasSelectedStrategy)
        {
         allValid = false;
         error = "Selecione ao menos uma estrategia.";
        }
      for(int sp = 0; sp < FUSION_STRATEGY_PANEL_COUNT; ++sp)
        {
         bool panelValid = true;
         string panelError = "";
         if(m_strategyPanels[sp] == NULL)
            panelValid = true;
         else
            panelValid = m_strategyPanels[sp].Validate(candidate, editable, panelError);

         m_strategyPageValid[sp + 1] = panelValid;
         if(!panelValid)
           {
            allValid = false;
            if(error == "")
               error = panelError;
           }
       }
      return allValid;
     }

   bool                       ValidateFilterPanels(SEASettings &candidate,const bool editable,string &error)
     {
      error = "";
      bool allValid = true;
      m_filterPageValid[(int)FUSION_FILTER_OVERVIEW] = true;
      for(int fp = 0; fp < FUSION_FILTER_PANEL_COUNT; ++fp)
        {
         bool panelValid = true;
         string panelError = "";
         if(m_filterPanels[fp] == NULL)
            panelValid = true;
         else
            panelValid = m_filterPanels[fp].Validate(candidate, editable, panelError);

         m_filterPageValid[fp + 1] = panelValid;
         if(!panelValid)
           {
            allValid = false;
            if(error == "")
               error = panelError;
           }
        }
      return allValid;
     }

   bool                       StrategySubtabHasError(const ENUM_FUSION_STRATEGY_PAGE page) const
     {
      return !m_strategyPageValid[(int)page];
     }

   bool                       HasStrategyTabError(void) const
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
         if(!m_strategyPageValid[i])
            return true;
      return false;
     }

   void                       ApplyStrategyTabStyles(void)
     {
      for(int i = 0; i < FUSION_STRAT_COUNT; ++i)
        {
         if(i == (int)m_strategyPage)
            FusionApplyPrimaryButtonStyle(m_strategyTabs[i], true);
         else if(StrategySubtabHasError((ENUM_FUSION_STRATEGY_PAGE)i))
            FusionApplyActionButtonStyle(m_strategyTabs[i], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_strategyTabs[i], false);
        }
     }

   bool                       FilterSubtabHasError(const ENUM_FUSION_FILTER_PAGE page) const
     {
      if(page == FUSION_FILTER_OVERVIEW)
         return false;
      return !m_filterPageValid[(int)page];
     }

   bool                       HasFilterTabError(void) const
     {
      for(int i = 1; i < FUSION_FILTER_COUNT; ++i)
         if(!m_filterPageValid[i])
            return true;
      return false;
     }

   void                       ApplyFilterTabStyles(void)
     {
      for(int i = 0; i < FUSION_FILTER_COUNT; ++i)
        {
         if(i == (int)m_filterPage)
            FusionApplyPrimaryButtonStyle(m_filterTabs[i], true);
         else if(FilterSubtabHasError((ENUM_FUSION_FILTER_PAGE)i))
            FusionApplyActionButtonStyle(m_filterTabs[i], FUSION_CLR_BAD, true);
         else
            FusionApplyPrimaryButtonStyle(m_filterTabs[i], false);
        }
     }

   void                       SetStrategyStatus(const string text,const color clr)
     {
      m_strategyStatusText = text;
      m_strategyStatusColor = clr;
      if(m_strategyTabCreated)
        {
         m_strategyStatus.Text(text);
         m_strategyStatus.Color(clr);
        }
     }

   void                       SetFilterStatus(const string text,const color clr)
     {
      m_filterStatusText = text;
      m_filterStatusColor = clr;
      if(m_filterTabCreated)
        {
         m_filterStatus.Text(text);
         m_filterStatus.Color(clr);
        }
     }

   void                       RestoreStrategyStatus(void)
     {
      if(!m_strategyTabCreated)
         return;
      m_strategyStatus.Text(m_strategyStatusText);
      m_strategyStatus.Color(m_strategyStatusColor);
     }

   void                       RestoreFilterStatus(void)
     {
      if(!m_filterTabCreated)
         return;
      m_filterStatus.Text(m_filterStatusText);
      m_filterStatus.Color(m_filterStatusColor);
     }

   void                       ApplyStrategyStatus(const bool strategyValid,const string strategyError)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileBlockStatusText() != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.tradePermissionBlocked)
        {
         status = m_snapshot.tradePermissionReason;
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: estrategias somente leitura.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar estrategias.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!strategyValid)
        {
         status = (strategyError != "" ? strategyError : "Corrija os campos de estrategias.");
         statusColor = FUSION_CLR_BAD;
        }
      else if(HasConfigTabError() || HasFilterTabError() || HasProfileTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileEditMode())
        {
         status = "Conclua ou cancele PERFIS.";
         statusColor = FUSION_CLR_WARN;
        }
      else
        {
         status = "Estrategia(s) selecionada(s). EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetStrategyStatus(status, statusColor);
     }

   void                       ApplyFilterStatus(const bool filterValid,const string filterError)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileBlockStatusText() != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.tradePermissionBlocked)
        {
         status = m_snapshot.tradePermissionReason;
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: filtros somente leitura.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar filtros.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!filterValid)
        {
         status = (filterError != "" ? filterError : "Corrija os campos de filtros.");
         statusColor = FUSION_CLR_BAD;
        }
      else if(HasConfigTabError() || HasStrategyTabError() || HasProfileTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileEditMode())
        {
         status = "Conclua ou cancele PERFIS.";
         statusColor = FUSION_CLR_WARN;
        }
      else
        {
         status = "EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetFilterStatus(status, statusColor);
     }
