#ifndef __MODULAR_EA_PROTECTION_MANAGER_MQH__
#define __MODULAR_EA_PROTECTION_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"

class CProtectionManager
  {
private:
   CLogger     *m_logger;
   SEASettings  m_settings;
   int          m_dayKey;
   int          m_dailyTradeCount;
   double       m_dailyClosedProfit;
   int          m_lossStreak;
   int          m_winStreak;
   bool         m_lossStreakBlocked;
   bool         m_winStreakBlocked;

   int          CurrentDayKey(const datetime value) const
     {
      MqlDateTime parts;
      TimeToStruct(value, parts);
      return (parts.year * 1000) + parts.day_of_year;
     }

   bool         IsInsideSession(const datetime now) const
     {
      if(!m_settings.enableSessionFilter)
         return true;

      MqlDateTime parts;
      TimeToStruct(now, parts);

      int currentMinutes = (parts.hour * 60) + parts.min;
      int startMinutes   = (m_settings.sessionStartHour * 60) + m_settings.sessionStartMinute;
      int endMinutes     = (m_settings.sessionEndHour * 60) + m_settings.sessionEndMinute;

      if(startMinutes <= endMinutes)
         return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);

      return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
     }

public:
                     CProtectionManager(void)
     {
      m_logger             = NULL;
      SetDefaultSettings(m_settings);
      m_dayKey             = 0;
      m_dailyTradeCount    = 0;
      m_dailyClosedProfit  = 0.0;
      m_lossStreak         = 0;
      m_winStreak          = 0;
      m_lossStreakBlocked  = false;
      m_winStreakBlocked   = false;
     }

   bool              Init(CLogger *logger,const SEASettings &settings)
     {
      m_logger = logger;
      m_settings = settings;
      m_dayKey = CurrentDayKey(TimeCurrent());
      return true;
     }

   bool              Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      m_settings = settings;
      return (scope == RELOAD_HOT || scope == RELOAD_WARM || scope == RELOAD_COLD);
     }

   void              ResetIfNewDay(void)
     {
      int currentKey = CurrentDayKey(TimeCurrent());
      if(currentKey == m_dayKey)
         return;

      m_dayKey            = currentKey;
      m_dailyTradeCount   = 0;
      m_dailyClosedProfit = 0.0;
      m_lossStreak        = 0;
      m_winStreak         = 0;
      m_lossStreakBlocked = false;
      m_winStreakBlocked  = false;
     }

   bool              IsDirectionAllowed(const ENUM_SIGNAL_TYPE signal,string &reason) const
     {
      reason = "";
      if(signal == SIGNAL_NONE)
         return true;

      if(signal == SIGNAL_BUY && m_settings.tradeDirection == DIRECTION_SELL_ONLY)
        {
         reason = "BUY disabled by direction rule";
         return false;
        }

      if(signal == SIGNAL_SELL && m_settings.tradeDirection == DIRECTION_BUY_ONLY)
        {
         reason = "SELL disabled by direction rule";
         return false;
        }

      return true;
     }

   bool              CanOpen(const string symbol,string &reason)
     {
      ResetIfNewDay();
      reason = "";

      if(m_lossStreakBlocked)
        {
         reason = "Loss streak block active";
         return false;
        }

      if(m_winStreakBlocked)
        {
         reason = "Win streak block active";
         return false;
        }

      if(m_settings.enableDailyLimits)
        {
         if(m_settings.maxDailyTrades > 0 && m_dailyTradeCount >= m_settings.maxDailyTrades)
           {
            reason = "Daily trade limit reached";
            return false;
           }

         if(m_settings.maxDailyLoss > 0.0 && m_dailyClosedProfit <= -m_settings.maxDailyLoss)
           {
            reason = "Daily loss limit reached";
            return false;
           }

         if(m_settings.maxDailyGain > 0.0 && m_dailyClosedProfit >= m_settings.maxDailyGain)
           {
            reason = "Daily gain limit reached";
            return false;
           }
        }

      if(!IsInsideSession(TimeCurrent()))
        {
         reason = "Outside session window";
         return false;
        }

      if(m_settings.maxSpreadPoints > 0)
        {
         long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
         if(spread > m_settings.maxSpreadPoints)
           {
            reason = "Spread above limit";
            return false;
           }
        }

      return true;
     }

   bool              ShouldForceClose(SPositionRuntimeState &state,const double floatingProfit,string &reason)
     {
      reason = "";
      ResetIfNewDay();

      double projectedProfit = m_dailyClosedProfit + floatingProfit;
      if(projectedProfit > state.dayPeakProjectedProfit)
         state.dayPeakProjectedProfit = projectedProfit;

      if(m_settings.enableDailyLimits)
        {
         if(m_settings.maxDailyLoss > 0.0 && projectedProfit <= -m_settings.maxDailyLoss)
           {
            reason = "Projected daily loss limit reached";
            return true;
           }

         if(m_settings.maxDailyGain > 0.0 && projectedProfit >= m_settings.maxDailyGain)
           {
            reason = "Projected daily gain limit reached";
            return true;
           }
        }

      if(m_settings.enableDrawdown && m_settings.maxDrawdown > 0.0)
        {
         double drawdown = state.dayPeakProjectedProfit - projectedProfit;
         if(drawdown >= m_settings.maxDrawdown)
           {
            reason = "Drawdown limit reached";
            return true;
           }
        }

      if(m_settings.enableSessionFilter && m_settings.closeOnSessionEnd && !IsInsideSession(TimeCurrent()))
        {
         reason = "Session closed";
         return true;
        }

      return false;
     }

   void              OnPartialRealized(const double profit)
     {
      m_dailyClosedProfit += profit;
     }

   void              OnPositionClosed(const double totalPositionProfit,const double realizedPartialProfit)
     {
      double finalPortion = totalPositionProfit - realizedPartialProfit;
      m_dailyClosedProfit += finalPortion;
      m_dailyTradeCount++;

      if(totalPositionProfit > 0.0)
        {
         m_winStreak++;
         m_lossStreak = 0;
        }
      else if(totalPositionProfit < 0.0)
        {
         m_lossStreak++;
         m_winStreak = 0;
        }

      if(m_settings.enableStreak)
        {
         if(m_settings.maxLossStreak > 0 && m_lossStreak >= m_settings.maxLossStreak)
            m_lossStreakBlocked = true;

         if(m_settings.maxWinStreak > 0 && m_winStreak >= m_settings.maxWinStreak)
            m_winStreakBlocked = true;
        }
     }

   int               DailyTradeCount(void) const
     {
      return m_dailyTradeCount;
     }

   double            DailyClosedProfit(void) const
     {
      return m_dailyClosedProfit;
     }
  };

#endif
