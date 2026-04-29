#ifndef __FUSION_SIGNAL_MANAGER_MQH__
#define __FUSION_SIGNAL_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "../Strategies/Base/StrategyBase.mqh"
#include "../Filters/Base/FilterBase.mqh"
#include "Resolvers/IConflictResolver.mqh"

class CSignalManager
  {
private:
   CLogger            *m_logger;
   CStrategyBase      *m_strategies[];
   CFilterBase        *m_filters[];
   IConflictResolver  *m_resolver;
   string              m_symbol;

public:
                     CSignalManager(void)
     {
      m_logger    = NULL;
      m_resolver  = NULL;
      m_symbol    = "";
      ArrayResize(m_strategies, 0);
      ArrayResize(m_filters, 0);
     }

   void              SetResolver(IConflictResolver *resolver)
     {
      m_resolver = resolver;
     }

   bool              AddStrategy(CStrategyBase *strategy)
     {
      if(strategy == NULL)
         return false;

      int size = ArraySize(m_strategies);
      ArrayResize(m_strategies, size + 1);
      m_strategies[size] = strategy;
      return true;
     }

   bool              AddFilter(CFilterBase *filter)
     {
      if(filter == NULL)
         return false;

      int size = ArraySize(m_filters);
      ArrayResize(m_filters, size + 1);
      m_filters[size] = filter;
      return true;
     }

   bool              Initialize(CLogger *logger,const string symbol,const SEASettings &settings)
     {
      m_logger    = logger;
      m_symbol    = symbol;

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         if(!m_strategies[i].Reload(settings, RELOAD_COLD))
            return false;

         if(!m_strategies[i].Initialize(logger, symbol))
            return false;
        }

      for(int i = 0; i < ArraySize(m_filters); i++)
        {
         if(m_filters[i] == NULL)
            continue;

         if(!m_filters[i].Reload(settings, RELOAD_COLD))
            return false;

         if(!m_filters[i].Initialize(logger, symbol))
            return false;
        }

      return true;
     }

   void              Shutdown(void)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL)
            m_strategies[i].Shutdown();

      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL)
            m_filters[i].Shutdown();
     }

   bool              ReloadAll(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL && !m_strategies[i].Reload(settings, scope))
            return false;

      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL && !m_filters[i].Reload(settings, scope))
            return false;

      return true;
     }

   bool              GetEntryDecision(SSignalDecision &decision)
     {
      ResetSignalDecision(decision);

      if(m_resolver == NULL)
         return false;

      SSignalCandidate candidates[];
      ArrayResize(candidates, 0);

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL || !m_strategies[i].Enabled())
            continue;

         ENUM_SIGNAL_TYPE signal = m_strategies[i].GetEntrySignal();
         if(signal == SIGNAL_NONE)
            continue;

         int index = ArraySize(candidates);
         ArrayResize(candidates, index + 1);
         candidates[index].signal       = signal;
         candidates[index].priority     = m_strategies[i].Priority();
         candidates[index].strategyId   = m_strategies[i].Id();
         candidates[index].strategyName = m_strategies[i].Name();
         candidates[index].shortName    = m_strategies[i].ShortName();
        }

      if(ArraySize(candidates) == 0)
         return false;

      if(!m_resolver.Resolve(candidates, ArraySize(candidates), decision))
        {
         decision.blockedBy = m_resolver.Name();
         return false;
        }

      for(int i = 0; i < ArraySize(m_filters); i++)
        {
         if(m_filters[i] == NULL || !m_filters[i].Enabled())
            continue;

         string reason = "";
         if(!m_filters[i].AllowEntry(decision.signal, reason))
           {
            decision.blockedBy = m_filters[i].Name() + ": " + reason;
            decision.signal = SIGNAL_NONE;
            return false;
           }
        }

      return (decision.signal != SIGNAL_NONE);
     }

   ENUM_SIGNAL_TYPE  GetExitSignal(const string ownerStrategyId,const ENUM_POSITION_TYPE currentPosition,string &ownerName,string &shortName)
     {
      ownerName = "";
      shortName = "";

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         if(m_strategies[i].Id() != ownerStrategyId)
            continue;

         ownerName = m_strategies[i].Name();
         shortName = m_strategies[i].ShortName();
         return m_strategies[i].GetExitSignal(currentPosition);
        }

      return SIGNAL_NONE;
     }

   bool              GetStrategyReferenceTimeframe(const string strategyId,ENUM_TIMEFRAMES &timeframe) const
     {
      timeframe = FUSION_DEFAULT_TIMEFRAME;

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;
         if(m_strategies[i].Id() != strategyId)
            continue;

         timeframe = m_strategies[i].ReferenceTimeframe();
         return true;
        }

      return false;
     }

   int               ActiveStrategyCount(void) const
     {
      int count = 0;
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL && m_strategies[i].Enabled())
            count++;
      return count;
     }

   int               ActiveFilterCount(void) const
     {
      int count = 0;
      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL && m_filters[i].Enabled())
            count++;
      return count;
     }
  };

#endif
