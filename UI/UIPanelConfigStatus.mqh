#ifndef __FUSION_UI_PANEL_CONFIG_STATUS_MQH__
#define __FUSION_UI_PANEL_CONFIG_STATUS_MQH__

   void                       SetConfigStatus(const string text,const color clr,string &outStatus)
     {
      outStatus = text;
      m_cfgStatusText = text;
      m_cfgStatusColor = clr;
      if(m_configTabCreated)
        {
         m_cfgStatus.Text(text);
         m_cfgStatus.Color(clr);
        }
     }

   void                       RestoreConfigStatus(void)
     {
      if(!m_configTabCreated)
         return;
      m_cfgStatus.Text(m_cfgStatusText);
      m_cfgStatus.Color(m_cfgStatusColor);
     }

   string                     CurrentConfigPageError(const bool lotValid,
                                                     const bool slValid,
                                                     const bool tpValid,
                                                     const bool magicValid,
                                                     const bool magicUnique,
                                                     const string magicConflictProfile)
     {
      if(m_configPage == FUSION_CFG_RISK)
        {
         if(!lotValid)
            return "Lote Fixo invalido. Ajuste o volume.";
         if(!slValid)
            return "SL Fixo invalido. Use 0 a 100000 pontos.";
         if(!tpValid)
            return "TP Fixo invalido. Use 0 a 100000 pontos.";
         return "";
        }

      if(m_configPage == FUSION_CFG_PROTECTION)
        {
         string protectError = ProtectSubtabError(m_protectPage);
         if(protectError != "")
            return protectError;
         return "";
        }

      if(m_configPage == FUSION_CFG_SYSTEM)
        {
         if(!magicValid)
            return "Magic invalido. Informe um numero inteiro positivo.";
         if(!magicUnique)
            return "Magic ja usado pelo perfil " + magicConflictProfile + ".";
         return "";
        }

      return "";
     }

   void                       ApplyConfigStatus(const bool configStatusValid,
                                                 const bool profileValid,
                                                 const bool lotValid,
                                                 const bool slValid,
                                                 const bool tpValid,
                                                 const bool magicValid,
                                                 const bool magicUnique,
                                                 const string magicConflictProfile,
                                                 const bool dirty,
                                                 string &outStatus)
     {
      string status = "";
      color statusColor = FUSION_CLR_MUTED;
      if(m_snapshot.runtimeBlocked)
        {
         status = m_snapshot.runtimeBlockReason;
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.tradePermissionBlocked)
        {
         status = m_snapshot.tradePermissionReason;
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.hasPosition)
        {
         status = "Posicao aberta: gerenciamento ativo, edicao bloqueada.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.started)
        {
         status = "EA rodando: pause antes de editar configuracoes.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(!configStatusValid)
        {
         if(!profileValid)
            status = "Perfil invalido. Carregue ou crie outro.";
         else
           {
            status = CurrentConfigPageError(lotValid,
                                            slValid,
                                            tpValid,
                                            magicValid,
                                            magicUnique,
                                            magicConflictProfile);
            if(status == "")
               status = "Corrija subaba(s) em vermelho.";
           }
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.startBlockedReason != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(m_snapshot.activeProfileBlockedReason != "")
        {
         status = ProfileBlockStatusText();
         statusColor = FUSION_CLR_WARN;
        }
      else if(HasProfileTabError())
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(ProfileEditMode())
        {
         status = "Conclua ou cancele PERFIS.";
         statusColor = FUSION_CLR_WARN;
        }
      else if(dirty && m_configInputsValid)
        {
         status = "Alteracoes pendentes. Salve para aplicar no EA.";
         statusColor = FUSION_CLR_GOOD;
        }
      else if(!m_configInputsValid)
        {
         status = "Corrija aba(s) em vermelho.";
         statusColor = FUSION_CLR_BAD;
        }
      else if(m_snapshot.started)
        {
         status = "EA em execucao com configuracao salva.";
         statusColor = FUSION_CLR_WARN;
        }
      else
        {
         status = "Configuracoes OK. EA pronto para operar.";
         statusColor = FUSION_CLR_GOOD;
        }

      SetConfigStatus(status, statusColor, outStatus);
     }

#endif
