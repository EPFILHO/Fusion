#ifndef __FUSION_PENDING_REVERSE_EXIT_MQH__
#define __FUSION_PENDING_REVERSE_EXIT_MQH__

#include "Types.mqh"

class CPendingReverseExit
  {
private:
   ENUM_SIGNAL_TYPE m_signal;
   string           m_strategyId;
   string           m_strategyName;
   string           m_shortName;

public:
                     CPendingReverseExit(void)
     {
      Reset();
     }

   void              Reset(void)
     {
      m_signal       = SIGNAL_NONE;
      m_strategyId   = "";
      m_strategyName = "";
      m_shortName    = "";
     }

   bool              HasPending(void) const
     {
      return (m_signal != SIGNAL_NONE && m_strategyId != "");
     }

   void              Arm(const ENUM_SIGNAL_TYPE signal,
                         const string strategyId,
                         const string strategyName,
                         const string shortName)
     {
      m_signal       = signal;
      m_strategyId   = strategyId;
      m_strategyName = strategyName;
      m_shortName    = shortName;
     }

   bool              TakeDecision(SSignalDecision &decision)
     {
      if(!HasPending())
         return false;

      ResetSignalDecision(decision);
      decision.signal       = m_signal;
      decision.strategyId   = m_strategyId;
      decision.strategyName = m_strategyName;
      decision.shortName    = m_shortName;

      Reset();
      return true;
     }
  };

#endif
