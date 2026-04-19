#ifndef __FUSION_LOGGER_MQH__
#define __FUSION_LOGGER_MQH__

class CLogger
  {
private:
   bool   m_debugEnabled;
   bool   m_isTester;
   string m_symbol;
   int    m_magic;

   string Prefix(const string level,const string scope) const
     {
      return StringFormat("[%s][%s][%d][%s]", level, m_symbol, m_magic, scope);
     }

public:
            CLogger(void)
     {
      m_debugEnabled = false;
      m_isTester     = false;
      m_symbol       = "";
      m_magic        = 0;
     }

   bool     Init(const bool debugEnabled,const string symbol,const int magic,const bool isTester)
     {
      m_debugEnabled = debugEnabled;
      m_symbol       = symbol;
      m_magic        = magic;
      m_isTester     = isTester;
      return true;
     }

   void     Log(const string level,const string scope,const string message) const
     {
      Print(Prefix(level, scope) + " " + message);
     }

   void     Debug(const string scope,const string message) const
     {
      if(!m_debugEnabled)
         return;
      Log("DEBUG", scope, message);
     }

   void     Info(const string scope,const string message) const
     {
      Log("INFO", scope, message);
     }

   void     Warn(const string scope,const string message) const
     {
      Log("WARN", scope, message);
     }

   void     Error(const string scope,const string message) const
     {
      Log("ERROR", scope, message);
     }

   void     Trade(const string scope,const string message) const
     {
      Log("TRADE", scope, message);
     }

   bool     IsTester(void) const
     {
      return m_isTester;
     }
  };

#endif
