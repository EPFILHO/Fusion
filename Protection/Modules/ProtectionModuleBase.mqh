#ifndef __FUSION_PROTECTION_MODULE_BASE_MQH__
#define __FUSION_PROTECTION_MODULE_BASE_MQH__

#include "../../Core/Types.mqh"

class CProtectionModuleBase
  {
protected:
   SEASettings       m_settings;

public:
                     CProtectionModuleBase(void)
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
  };

#endif
