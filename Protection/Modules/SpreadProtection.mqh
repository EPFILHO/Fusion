#ifndef __FUSION_SPREAD_PROTECTION_MQH__
#define __FUSION_SPREAD_PROTECTION_MQH__

#include "../../Core/Types.mqh"

class CSpreadProtection
  {
private:
   SEASettings m_settings;

public:
                     CSpreadProtection(void)
     {
      SetDefaultSettings(m_settings);
     }

   bool              Init(const SEASettings &settings)
     {
      m_settings = settings;
      return true;
     }

   bool              Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      m_settings = settings;
      return (scope == RELOAD_HOT || scope == RELOAD_WARM || scope == RELOAD_COLD);
     }

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
