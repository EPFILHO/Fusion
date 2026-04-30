#ifndef __FUSION_ACTIVE_PROFILE_REGISTRY_MQH__
#define __FUSION_ACTIVE_PROFILE_REGISTRY_MQH__

class CActiveProfileRegistry
  {
private:
   string m_key;
   string m_prefix;
   bool   m_registered;
   int    m_ttlSeconds;

   string SanitizeProfileName(const string value) const
     {
      string safe = value;
      string invalid = "\\/:*?\"<>| ";
      for(int i = 0; i < StringLen(invalid); ++i)
        {
         string token = StringSubstr(invalid, i, 1);
         StringReplace(safe, token, "_");
        }
      return safe;
     }

   uint   ProfileHash(const string value) const
     {
      uint hash = 2166136261;
      for(int i = 0; i < StringLen(value); ++i)
        {
         hash ^= (uint)StringGetCharacter(value, i);
         hash *= 16777619;
        }
      return hash;
     }

   string ProfileToken(const string profileName) const
     {
      string safe = SanitizeProfileName(profileName);
      if(safe == "")
         return "";
      return StringFormat("%08X", ProfileHash(safe));
     }

   string Prefix(const string profileName) const
     {
      string token = ProfileToken(profileName);
      if(token == "")
         return "";
      return "Fusion.P." + token + ".";
     }

   string Key(const string profileName,const long chartId) const
     {
      string prefix = Prefix(profileName);
      if(prefix == "")
         return "";
      return prefix + StringFormat("%I64d", chartId);
     }

   void   PruneStale(const string prefix,const datetime now) const
     {
      if(prefix == "")
         return;

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
      if(prefix == "")
         return false;

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
         CActiveProfileRegistry(void)
     {
      m_key         = "";
      m_prefix      = "";
      m_registered  = false;
      m_ttlSeconds  = 30;
     }

   bool HasActiveProfilePeer(const string profileName,const long chartId,string &reason)
     {
      reason = "";
      if(profileName == "")
         return false;

      datetime now = TimeLocal();
      string prefix = Prefix(profileName);
      string key = Key(profileName, chartId);
      PruneStale(prefix, now);

      string peerKey = "";
      if(!HasLivePeer(prefix, key, now, peerKey))
         return false;

      reason = "Perfil " + profileName + " ja esta carregado em outro grafico.";
      return true;
     }

   bool Register(const string profileName,const long chartId)
     {
      if(profileName == "")
        {
         Unregister();
         return false;
        }

      string key = Key(profileName, chartId);
      string prefix = Prefix(profileName);
      if(key == "" || prefix == "")
        {
         Unregister();
         return false;
        }

      if(m_registered && m_key != key)
         Unregister();

      m_prefix = prefix;
      m_key = key;
      m_registered = (GlobalVariableSet(m_key, (double)TimeLocal()) > 0.0);
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
