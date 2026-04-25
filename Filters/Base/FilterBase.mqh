#ifndef __FUSION_FILTER_BASE_MQH__
#define __FUSION_FILTER_BASE_MQH__

#include "../../Core/Types.mqh"
#include "../../Core/Logger.mqh"

class CFilterBase
  {
protected:
   CLogger         *m_logger;
   string           m_id;
   string           m_name;
   string           m_symbol;
   ENUM_TIMEFRAMES  m_timeframe;
   bool             m_enabled;
   bool             m_initialized;

public:
                     CFilterBase(const string id,const string name)
     {
      m_logger      = NULL;
      m_id          = id;
      m_name        = name;
      m_symbol      = "";
      m_timeframe   = PERIOD_CURRENT;
      m_enabled     = true;
      m_initialized = false;
     }

   virtual          ~CFilterBase(void) {}

   virtual bool      Initialize(CLogger *logger,const string symbol)
     {
      m_logger      = logger;
      m_symbol      = symbol;
      m_initialized = true;
      return true;
     }

   virtual void      Shutdown(void)
     {
      m_initialized = false;
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) = 0;
   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) = 0;

   string            Id(void) const         { return m_id; }
   string            Name(void) const       { return m_name; }
   bool              Enabled(void) const    { return m_enabled; }
   void              SetEnabled(const bool value) { m_enabled = value; }
   bool              IsInitialized(void) const { return m_initialized; }
  };

#endif
