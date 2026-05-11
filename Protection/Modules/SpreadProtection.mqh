#ifndef __FUSION_SPREAD_PROTECTION_MQH__
#define __FUSION_SPREAD_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"

class CSpreadProtection : public CProtectionModuleBase
  {
public:
   bool              CanOpen(const string symbol,string &reason) const
     {
      reason = "";
      if(!m_settings.enableSpreadProtection || m_settings.maxSpreadPoints <= 0)
         return true;

      long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      if(spread <= m_settings.maxSpreadPoints)
         return true;

      reason = "Spread bloqueado: atual " + IntegerToString((int)spread) +
               " pts, limite " + IntegerToString(m_settings.maxSpreadPoints) + " pts.";
      return false;
     }
  };

#endif
