#ifndef __FUSION_TRADE_PERMISSION_GUARD_MQH__
#define __FUSION_TRADE_PERMISSION_GUARD_MQH__

#include "Logger.mqh"

class CTradePermissionGuard
  {
private:
   CLogger *m_logger;
   bool     m_isTester;
   bool     m_blocked;
   string   m_notice;
   bool     m_connectionKnown;
   bool     m_connected;

   bool              IsConnectionReason(const string reason) const
     {
      return (reason == "Conexão com servidor perdida.");
     }

   bool              IsAccountPermissionReason(const string reason) const
     {
      return (reason == "Conta não permite negociação." ||
              reason == "Conta não permite negociação automática por EA.");
     }

   void              RefreshConnectionState(const bool connected)
     {
      if(m_isTester)
         return;

      if(!m_connectionKnown)
        {
         m_connectionKnown = true;
         m_connected = connected;
         if(!connected && m_logger != NULL)
            m_logger.Warn("CONNECTION", "Conexão com servidor perdida. Entradas bloqueadas.");
         return;
        }

      if(m_connected == connected)
         return;

      m_connected = connected;
      if(m_logger == NULL)
         return;

      if(connected)
         m_logger.Info("CONNECTION", "Conexão com servidor restaurada. Verificando permissões de trading.");
      else
         m_logger.Warn("CONNECTION", "Conexão com servidor perdida. Entradas bloqueadas.");
     }

   bool              PermissionsAllowed(string &reason)
     {
      reason = "";
      if(m_isTester)
         return true;

      bool connected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
      RefreshConnectionState(connected);
      if(!connected)
        {
         reason = "Conexão com servidor perdida.";
         return false;
        }

      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         reason = "AutoTrading desabilitado no MT5.";
         return false;
        }

      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         reason = "Permissão de trade do EA desabilitada.";
         return false;
        }

      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        {
         reason = "Conta não permite negociação.";
         return false;
        }

      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {
         reason = "Conta não permite negociação automática por EA.";
         return false;
        }

      return true;
     }

   string            FormatNotice(const string reason,const bool hasPosition) const
     {
      if(IsConnectionReason(reason))
        {
         if(hasPosition)
            return "Conexão perdida. Gerenciamento da posição interrompido; aguardando MT5/corretora.";
         return "Conexão perdida. Aguardando MT5/corretora.";
        }

      if(IsAccountPermissionReason(reason))
        {
         if(hasPosition)
            return reason + " Gerenciamento da posição interrompido. Aguardando MT5/corretora liberar.";
         //--- Sem o prefixo "Trading temporariamente indisponivel: ", que ficou
         //--- redundante e custava caro. Redundante porque o painel ja anuncia
         //--- o estado ao lado — distintivo IMPEDIDO e titulo TRADING
         //--- INDISPONIVEL na aba Status. Caro porque esta e a unica das seis
         //--- formas que estoura a faixa de uma linha do cabecalho da 2.0 (~556
         //--- unidades): com o prefixo o texto era cortado com reticencias
         //--- justamente antes de "Aguardando MT5/corretora liberar", que e o
         //--- que diz o que esperar.
         //---
         //--- Seguro para os dois paineis: a classificacao (IsConnectionReason,
         //--- IsAccountPermissionReason) compara o `reason`, nunca este texto
         //--- formatado, e quem o consome so o exibe ou o compara consigo mesmo
         //--- para detectar mudanca.
         return reason + " Aguardando MT5/corretora liberar.";
        }

      if(hasPosition)
         return reason + " Gerenciamento da posição interrompido. Habilite imediatamente.";
      return reason + " Habilite para iniciar.";
     }

public:
                     CTradePermissionGuard(void)
     {
      m_logger = NULL;
      m_isTester = false;
      m_blocked = false;
      m_notice = "";
      m_connectionKnown = false;
      m_connected = true;
     }

   void              Init(CLogger *logger,const bool isTester)
     {
      m_logger = logger;
      m_isTester = isTester;
      m_connectionKnown = false;
      m_connected = true;
      Reset();
     }

   void              Reset(void)
     {
      m_blocked = false;
      m_notice = "";
     }

   bool              IsBlocked(void) const
     {
      return m_blocked;
     }

   string            Notice(void) const
     {
      return m_notice;
     }

   bool              Refresh(const bool hasPosition)
     {
      string reason = "";
      bool wasBlocked = m_blocked;
      if(PermissionsAllowed(reason))
        {
         //--- Nao diz mais "EA pronto para operar": desde a quarentena de candle
         //--- (RefreshTradePermissionState -> SuspendEntriesUntilFreshCandle) a
         //--- permissao voltar NAO significa que a proxima entrada passa. O guard
         //--- so afirma o que ele mesmo sabe - a permissao - e anuncia a espera.
         if(wasBlocked && m_logger != NULL)
            m_logger.Info("AUTOTRADE", "Trading habilitado novamente. Aguardando sinal formado após a liberação.");
         Reset();
         return true;
        }

      string notice = FormatNotice(reason, hasPosition);
      bool changed = (!m_blocked || m_notice != notice);
      m_blocked = true;
      m_notice = notice;

      if(changed && m_logger != NULL && !IsConnectionReason(reason))
         m_logger.Warn("AUTOTRADE", notice);

      return false;
     }
  };

#endif
