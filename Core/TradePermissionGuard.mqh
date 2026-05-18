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

   bool              PermissionsAllowed(string &reason) const
     {
      reason = "";
      if(m_isTester)
         return true;

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
     }

   void              Init(CLogger *logger,const bool isTester)
     {
      m_logger = logger;
      m_isTester = isTester;
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
      if(PermissionsAllowed(reason))
        {
         Reset();
         return true;
        }

      string notice = FormatNotice(reason, hasPosition);
      bool changed = (!m_blocked || m_notice != notice);
      m_blocked = true;
      m_notice = notice;

      if(changed && m_logger != NULL)
         m_logger.Warn("AUTOTRADE", notice);

      return false;
     }
  };

#endif
