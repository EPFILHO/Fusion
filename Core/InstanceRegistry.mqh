#ifndef __FUSION_INSTANCE_REGISTRY_MQH__
#define __FUSION_INSTANCE_REGISTRY_MQH__

class CInstanceRegistry
  {
private:
   string m_key;
   string m_prefix;
   bool   m_registered;
   int    m_ttlSeconds;

   string Prefix(const int magicNumber) const
     {
      return "Fusion.I." + IntegerToString(magicNumber) + ".";
     }

   string Key(const int magicNumber,const long chartId) const
     {
      return Prefix(magicNumber) + StringFormat("%I64d", chartId);
     }

   void   PruneStale(const string prefix,const datetime now) const
     {
      for(int i = GlobalVariablesTotal() - 1; i >= 0; --i)
        {
         string name = GlobalVariableName(i);
         if(StringFind(name, prefix) != 0)
            continue;

         datetime lastSeen = (datetime)GlobalVariableGet(name);
         if(lastSeen <= 0 || now - lastSeen > m_ttlSeconds)
            GlobalVariableDel(name);
        }
     }

   bool   HasLivePeer(const string prefix,const string ownKey,const datetime now,string &peerKey) const
     {
      peerKey = "";
      for(int i = GlobalVariablesTotal() - 1; i >= 0; --i)
        {
         string name = GlobalVariableName(i);
         if(StringFind(name, prefix) != 0 || name == ownKey)
            continue;

         datetime lastSeen = (datetime)GlobalVariableGet(name);
         if(lastSeen > 0 && now - lastSeen <= m_ttlSeconds)
           {
            peerKey = name;
            return true;
           }
        }
      return false;
     }

public:
         CInstanceRegistry(void)
     {
      m_key         = "";
      m_prefix      = "";
      m_registered  = false;
      m_ttlSeconds  = 30;
     }

   bool HasActiveConflict(const int magicNumber,const long chartId,string &reason)
     {
      reason = "";
      if(magicNumber <= 0)
         return false;

      datetime now = TimeLocal();
      string prefix = Prefix(magicNumber);
      string key = Key(magicNumber, chartId);
      PruneStale(prefix, now);

      string peerKey = "";
      if(!HasLivePeer(prefix, key, now, peerKey))
         return false;

      reason = "Magic " + IntegerToString(magicNumber) + " ja esta em uso por outro Fusion ativo.";
      return true;
     }

   bool Register(const string symbol,const int magicNumber,const long chartId,string &reason)
     {
      reason = "";
      if(magicNumber <= 0)
        {
         reason = "Magic Number invalido para registrar instancia.";
         return false;
        }

      if(HasActiveConflict(magicNumber, chartId, reason))
        {
         return false;
        }

      datetime now = TimeLocal();
      string prefix = Prefix(magicNumber);
      string key = Key(magicNumber, chartId);

      if(m_registered && m_key != key)
         Unregister();

      m_prefix = prefix;
      m_key = key;
      m_registered = (GlobalVariableSet(m_key, (double)now) > 0.0);
      if(!m_registered)
         reason = "Nao foi possivel registrar a instancia do Fusion.";
      return m_registered;
     }

   void Refresh(void)
     {
      if(!m_registered || m_key == "")
         return;
      GlobalVariableSet(m_key, (double)TimeLocal());
     }

   void Unregister(void)
     {
      if(m_key != "" && GlobalVariableCheck(m_key))
         GlobalVariableDel(m_key);
      m_key = "";
      m_prefix = "";
      m_registered = false;
     }

   bool Registered(void) const
     {
      return m_registered;
     }
  };

#endif
