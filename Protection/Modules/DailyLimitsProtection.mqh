#ifndef __FUSION_DAILY_LIMITS_PROTECTION_MQH__
#define __FUSION_DAILY_LIMITS_PROTECTION_MQH__

#include "ProtectionModuleBase.mqh"
#include "ProtectionTimeUtils.mqh"

class CDailyLimitsProtection : public CProtectionModuleBase
  {
private:
   int         m_dayKey;
   int         m_dailyTradeCount;
   int         m_dailyLossCount;
   int         m_dailyWinCount;
   int         m_dailyBreakevenCount;
   bool        m_outcomeCountsKnown;
   double      m_dailyClosedProfit;
   bool        m_tradesLimitReached;
   bool        m_lossLimitReached;
   bool        m_gainLimitReached;
   string      m_pendingDiagnostic;

   bool              UsesDrawdownActivation(void) const
     {
      return (m_settings.profitTargetAction == PROFIT_ACTION_ATIVAR_DD &&
              m_settings.enableDrawdown &&
              m_settings.maxDrawdown > 0.0 &&
              m_settings.maxDailyGain > 0.0);
     }

   void              ResetDailyState(void)
     {
      m_dailyTradeCount = 0;
      m_dailyLossCount = 0;
      m_dailyWinCount = 0;
      m_dailyBreakevenCount = 0;
      m_outcomeCountsKnown = true;
      m_dailyClosedProfit = 0.0;
      m_tradesLimitReached = false;
      m_lossLimitReached = false;
      m_gainLimitReached = false;
      m_pendingDiagnostic = "";
     }

   string            MoneyText(const double value) const
     {
      return DoubleToString(value, 2);
     }

   void              SetPendingDiagnostic(const string eventText,
                                          const string motive,
                                          const double floatingProfit,
                                          const double projectedProfit,
                                          const string limitText)
     {
      m_pendingDiagnostic = eventText +
                            ": motivo=" + motive +
                            "; P/L bruto fechado=" + MoneyText(m_dailyClosedProfit) +
                            "; P/L bruto flutuante=" + MoneyText(floatingProfit) +
                            "; P/L bruto projetado=" + MoneyText(projectedProfit) +
                            "; limite=" + limitText + ".";
     }

   void              LatchTradesLimit(const string eventText,const double floatingProfit,const double projectedProfit)
     {
      if(m_tradesLimitReached)
         return;

      m_tradesLimitReached = true;
      SetPendingDiagnostic(eventText,
                           "Max Trades",
                           floatingProfit,
                           projectedProfit,
                           IntegerToString(m_settings.maxDailyTrades) + " trades");
     }

   void              LatchLossLimit(const string eventText,const double floatingProfit,const double projectedProfit)
     {
      if(m_lossLimitReached)
         return;

      m_lossLimitReached = true;
      SetPendingDiagnostic(eventText,
                           "Max Perda",
                           floatingProfit,
                           projectedProfit,
                           "-" + MoneyText(m_settings.maxDailyLoss));
     }

   void              LatchGainLimit(const string eventText,const double floatingProfit,const double projectedProfit)
     {
      if(m_gainLimitReached)
         return;

      m_gainLimitReached = true;
      SetPendingDiagnostic(eventText,
                           "Max Ganho",
                           floatingProfit,
                           projectedProfit,
                           MoneyText(m_settings.maxDailyGain));
     }

   bool              CurrentBlockReason(string &reason) const
     {
      reason = "";
      if(m_lossLimitReached)
        {
         reason = "Limite diario de perda atingido.";
         return true;
        }

      if(m_gainLimitReached)
        {
         reason = "Meta diaria de ganho atingida.";
         return true;
        }

      if(m_tradesLimitReached)
        {
         reason = "Limite diario de trades atingido.";
         return true;
        }

      return false;
     }

   void              UpdateLatchedLimits(void)
     {
      if(!m_settings.enableDailyLimits)
         return;

      if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
         LatchTradesLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);

      if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
         LatchLossLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);

      if(m_settings.maxDailyGain > 0.0 &&
         m_dailyClosedProfit >= m_settings.maxDailyGain &&
         !UsesDrawdownActivation())
         LatchGainLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);
     }

public:
                     CDailyLimitsProtection(void)
     {
      m_dayKey = 0;
      ResetDailyState();
     }

   bool              Init(const SEASettings &settings)
     {
      CProtectionModuleBase::Init(settings);
      m_dayKey = FusionProtectionCurrentDayKey();
      return true;
     }

   void              ResetDaily(void)
     {
      m_dayKey = FusionProtectionCurrentDayKey();
      ResetDailyState();
     }

   bool              ResetIfNewDay(void)
     {
      int currentKey = FusionProtectionCurrentDayKey();
      if(currentKey == m_dayKey)
         return false;

      m_dayKey = currentKey;
      ResetDailyState();
      return true;
     }

   void              ExportState(SDailyLimitsRuntimeState &state) const
     {
      state.dayKey = m_dayKey;
      state.dailyTradeCount = m_dailyTradeCount;
      state.dailyLossCount = m_dailyLossCount;
      state.dailyWinCount = m_dailyWinCount;
      state.dailyBreakevenCount = m_dailyBreakevenCount;
      state.outcomeCountsKnown = m_outcomeCountsKnown;
      state.dailyClosedProfit = m_dailyClosedProfit;
      state.tradesLimitReached = m_tradesLimitReached;
      state.lossLimitReached = m_lossLimitReached;
      state.gainLimitReached = m_gainLimitReached;
     }

   void              ImportState(const SDailyLimitsRuntimeState &state)
     {
      int currentDayKey = FusionProtectionCurrentDayKey();
      if(state.dayKey != currentDayKey)
        {
         m_dayKey = currentDayKey;
         ResetDailyState();
         return;
        }

      m_dayKey = state.dayKey;
      m_dailyTradeCount = (state.dailyTradeCount < 0) ? 0 : state.dailyTradeCount;
      m_dailyLossCount = (state.dailyLossCount < 0) ? 0 : state.dailyLossCount;
      m_dailyWinCount = (state.dailyWinCount < 0) ? 0 : state.dailyWinCount;
      m_dailyBreakevenCount = (state.dailyBreakevenCount < 0) ? 0 : state.dailyBreakevenCount;
      int classifiedTrades = m_dailyLossCount + m_dailyWinCount + m_dailyBreakevenCount;
      m_outcomeCountsKnown = (state.outcomeCountsKnown && classifiedTrades == m_dailyTradeCount);
      if(m_dailyTradeCount == 0)
         m_outcomeCountsKnown = true;
      m_dailyClosedProfit = state.dailyClosedProfit;
      m_tradesLimitReached = state.tradesLimitReached;
      m_lossLimitReached = state.lossLimitReached;
      m_gainLimitReached = state.gainLimitReached;
      UpdateLatchedLimits();
     }

   bool              CanOpen(string &reason,bool &activateDrawdown)
     {
      reason = "";
      activateDrawdown = false;

      if(CurrentBlockReason(reason))
         return false;

      if(!m_settings.enableDailyLimits)
         return true;

      if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
        {
         LatchTradesLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);
         reason = "Limite diario de trades atingido.";
         return false;
        }

      if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
        {
         LatchLossLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);
         reason = "Limite diario de perda atingido.";
         return false;
        }

      if(m_settings.maxDailyGain > 0.0 && m_dailyClosedProfit >= m_settings.maxDailyGain)
        {
         if(UsesDrawdownActivation())
           {
            activateDrawdown = true;
            return true;
           }

         reason = "Meta diaria de ganho atingida.";
         LatchGainLimit("DAY bloqueado", 0.0, m_dailyClosedProfit);
         return false;
        }

      return true;
     }

   bool              ShouldForceClose(const double floatingProfit,string &reason,bool &activateDrawdown,double &projectedProfit)
     {
      reason = "";
      activateDrawdown = false;
      projectedProfit = m_dailyClosedProfit + floatingProfit;

      if(m_lossLimitReached)
        {
         reason = "Limite diario de perda projetada atingido.";
         return true;
        }

      if(m_gainLimitReached)
        {
         reason = "Meta diaria de ganho atingida.";
         return true;
        }

      if(m_tradesLimitReached)
        {
         reason = "Limite diario de trades atingido.";
         return false;
        }

      if(!m_settings.enableDailyLimits)
         return false;

      if(m_settings.maxDailyLoss > 0.0 && projectedProfit <= -m_settings.maxDailyLoss)
        {
         LatchLossLimit("DAY forcou fechamento", floatingProfit, projectedProfit);
         reason = "Limite diario de perda projetada atingido.";
         return true;
        }

      if(m_settings.maxDailyGain > 0.0 && projectedProfit >= m_settings.maxDailyGain)
        {
         if(UsesDrawdownActivation())
           {
            activateDrawdown = true;
            return false;
           }

         reason = "Meta diaria de ganho atingida.";
         LatchGainLimit("DAY forcou fechamento", floatingProfit, projectedProfit);
         return true;
        }

      return false;
     }

   void              OnPartialRealized(const double profit)
     {
      m_dailyClosedProfit += profit;
      UpdateLatchedLimits();
     }

   void              OnPositionClosed(const double totalPositionProfit,const double realizedPartialProfit)
     {
      double finalPortion = totalPositionProfit - realizedPartialProfit;
      m_dailyClosedProfit += finalPortion;
      m_dailyTradeCount++;
      if(totalPositionProfit > 0.0)
         m_dailyWinCount++;
      else if(totalPositionProfit < 0.0)
         m_dailyLossCount++;
      else
         m_dailyBreakevenCount++;
      UpdateLatchedLimits();
     }

   int               DailyTradeCount(void) const
     {
      return m_dailyTradeCount;
     }

   int               DailyLossCount(void) const
     {
      return m_dailyLossCount;
     }

   int               DailyWinCount(void) const
     {
      return m_dailyWinCount;
     }

   int               DailyBreakevenCount(void) const
     {
      return m_dailyBreakevenCount;
     }

   bool              OutcomeCountsKnown(void) const
     {
      return m_outcomeCountsKnown;
     }

   double            DailyClosedProfit(void) const
     {
      return m_dailyClosedProfit;
     }

   bool              IsBlocking(string &reason) const
     {
      int currentDayKey = FusionProtectionCurrentDayKey();
      if(currentDayKey != m_dayKey)
        {
         reason = "";
         return false;
        }

      return CurrentBlockReason(reason);
     }

   bool              ConsumePendingDiagnostic(string &diagnostic)
     {
      diagnostic = m_pendingDiagnostic;
      m_pendingDiagnostic = "";
      return (diagnostic != "");
     }
  };

#endif
