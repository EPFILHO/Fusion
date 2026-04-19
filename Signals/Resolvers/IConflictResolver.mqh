#ifndef __FUSION_I_CONFLICT_RESOLVER_MQH__
#define __FUSION_I_CONFLICT_RESOLVER_MQH__

#include "../../Core/Types.mqh"

class IConflictResolver
  {
public:
   virtual bool      Resolve(SSignalCandidate &candidates[],const int count,SSignalDecision &decision) = 0;
   virtual string    Name(void) const = 0;
   virtual          ~IConflictResolver(void) {}
  };

#endif
