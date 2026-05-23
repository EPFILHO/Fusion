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
      return (reason == "Conexao com servidor perdida.");
     }

   bool              IsAccountPermissionReason(const string reason) const
     {
      return (reason == "Conta nao permite negociacao." ||
              reason == "Conta nao permite negociacao automatica por EA.");
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
            m_logger.Warn("CONNECTION", "Conexao com servidor perdida. Entradas bloqueadas.");
         return;
        }

      if(m_connected == connected)
         return;

      m_connected = connected;
      if(m_logger == NULL)
         return;

      if(connected)
         m_logger.Info("CONNECTION", "Conexao com servidor restaurada. Verificando permissoes de trading.");
      else
         m_logger.Warn("CONNECTION", "Conexao com servidor perdida. Entradas bloqueadas.");
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
         reason = "Conexao com servidor perdida.";
         return false;
        }

      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
        {
         reason = "AutoTrading desabilitado no MT5.";
         return false;
        }

      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         reason = "Permissao de trade do EA desabilitada.";
         return false;
        }

      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
        {
         reason = "Conta nao permite negociacao.";
         return false;
        }

      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        {
         reason = "Conta nao permite negociacao automatica por EA.";
         return false;
        }

      return true;
     }

   string            FormatNotice(const string reason,const bool hasPosition) const
     {
      if(IsConnectionReason(reason))
        {
         if(hasPosition)
            return "Conexao perdida. Gerenciamento da posicao interrompido; aguardando MT5/corretora.";
         return "Conexao perdida. Aguardando MT5/corretora.";
        }

      if(IsAccountPermissionReason(reason))
        {
         if(hasPosition)
            return reason + " Gerenciamento da posicao interrompido. Aguardando MT5/corretora liberar.";
         return "Trading temporariamente indisponivel: " + reason + " Aguardando MT5/corretora liberar.";
        }

      if(hasPosition)
         return reason + " Gerenciamento da posicao interrompido. Habilite imediatamente.";
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
         if(wasBlocked && m_logger != NULL)
            m_logger.Info("AUTOTRADE", "Trading habilitado novamente. EA pronto para operar.");
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
