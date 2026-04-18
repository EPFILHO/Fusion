#ifndef __MODULAR_EA_CANCEL_CONFLICT_RESOLVER_MQH__
#define __MODULAR_EA_CANCEL_CONFLICT_RESOLVER_MQH__

#include "IConflictResolver.mqh"

class CCancelConflictResolver : public IConflictResolver
  {
public:
   virtual bool      Resolve(SSignalCandidate &candidates[],const int count,SSignalDecision &decision) override
     {
      ResetSignalDecision(decision);
      if(count <= 0)
         return false;

      ENUM_SIGNAL_TYPE firstSignal = candidates[0].signal;
      int              bestIndex   = 0;

      for(int i = 1; i < count; i++)
        {
         if(candidates[i].signal != firstSignal)
            return false;

         if(candidates[i].priority > candidates[bestIndex].priority)
            bestIndex = i;
        }

      decision.signal       = candidates[bestIndex].signal;
      decision.strategyId   = candidates[bestIndex].strategyId;
      decision.strategyName = candidates[bestIndex].strategyName;
      decision.shortName    = candidates[bestIndex].shortName;
      return true;
     }

   virtual string    Name(void) const override
     {
      return "CancelResolver";
     }
  };

#endif
