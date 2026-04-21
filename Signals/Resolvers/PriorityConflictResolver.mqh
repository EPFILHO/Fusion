#ifndef __FUSION_PRIORITY_CONFLICT_RESOLVER_MQH__
#define __FUSION_PRIORITY_CONFLICT_RESOLVER_MQH__

#include "IConflictResolver.mqh"

class CPriorityConflictResolver : public IConflictResolver
  {
public:
   virtual bool      Resolve(SSignalCandidate &candidates[],const int count,SSignalDecision &decision) override
     {
      ResetSignalDecision(decision);
      if(count <= 0)
         return false;

      int bestIndex    = 0;
      int bestPriority = candidates[0].priority;

      for(int i = 1; i < count; i++)
        {
         if(candidates[i].priority > bestPriority)
           {
            bestIndex    = i;
            bestPriority = candidates[i].priority;
           }
         else if(candidates[i].priority == bestPriority && candidates[i].signal != candidates[bestIndex].signal)
           {
            return false;
           }
        }

      decision.signal       = candidates[bestIndex].signal;
      decision.strategyId   = candidates[bestIndex].strategyId;
      decision.strategyName = candidates[bestIndex].strategyName;
      decision.shortName    = candidates[bestIndex].shortName;
      decision.magicNumber  = candidates[bestIndex].magicNumber;
      return true;
     }

   virtual string    Name(void) const override
     {
      return "PriorityResolver";
     }
  };

#endif
