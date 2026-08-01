//+------------------------------------------------------------------+
//| SettingsCompare.mqh                                               |
//| Duas configuracoes sao iguais?                                    |
//|                                                                   |
//| Serve para responder "ha alteracao pendente?" pela DIFERENCA real |
//| entre o rascunho e o comprometido, em vez de por uma marca ligada |
//| a cada interacao. Marcar na interacao acusa mudanca onde nao      |
//| houve: entrar num campo e sair sem digitar, alternar uma chave    |
//| duas vezes, reescolher a mesma opcao de um combo. Com o INICIAR   |
//| dependendo de nao haver pendencia, essa mentira passou a ter      |
//| consequencia operacional.                                         |
//|                                                                   |
//| A comparacao segue a ORDEM DO STRUCT, campo a campo, para poder   |
//| ser conferida lado a lado com Core/Types.mqh. Cobre todos os      |
//| campos, inclusive os que nenhuma tela edita hoje: faltar um       |
//| significa alteracao que o painel nao percebe — e um SALVAR        |
//| apagado com a mudanca a vista.                                    |
//|                                                                   |
//| Fora: isTester e schemaVersion nao sao configuracao do usuario.   |
//+------------------------------------------------------------------+
#ifndef __FUSION_SETTINGS_COMPARE_MQH__
#define __FUSION_SETTINGS_COMPARE_MQH__

#include "Types.mqh"

//--- Tolerancia dos campos decimais, a mesma da 1.058.
#define FUSION_SETTINGS_EPS 0.0000001

bool FusionSameDouble(const double a,const double b)
  { return (MathAbs(a-b) <= FUSION_SETTINGS_EPS); }

bool FusionSameNewsWindow(const SNewsWindowConfig &a,const SNewsWindowConfig &b)
  {
   return (a.enabled     == b.enabled     &&
           a.startHour   == b.startHour   &&
           a.startMinute == b.startMinute &&
           a.endHour     == b.endHour     &&
           a.endMinute   == b.endMinute   &&
           a.action      == b.action);
  }

bool FusionSamePartialTP(const SPartialTPConfig &a,const SPartialTPConfig &b)
  {
   return (a.enabled == b.enabled &&
           FusionSameDouble(a.percent,b.percent) &&
           a.distancePoints == b.distancePoints);
  }

bool FusionSettingsEqual(const SEASettings &a,const SEASettings &b)
  {
   //--- geral
   if(a.panelEnabled        != b.panelEnabled)        return false;
   if(a.defaultProfileName  != b.defaultProfileName)  return false;
   if(a.magicNumber         != b.magicNumber)         return false;
   if(a.slippagePoints      != b.slippagePoints)      return false;
   //--- debugLogs FICA DE FORA de proposito. Ele nao pertence ao perfil: nao e
   //--- serializado e e sempre reaplicado a partir do input do EA. Compara-lo
   //--- faria uma diferenca que nenhum SALVAR consegue eliminar — pendencia
   //--- eterna, com o botao aceso para sempre. A 1.058 tambem o exclui.

   //--- visual
   if(a.showChartIndicators != b.showChartIndicators) return false;
   if(a.visualMAFastColor   != b.visualMAFastColor)   return false;
   if(a.visualMASlowColor   != b.visualMASlowColor)   return false;
   if(a.visualMATrendColor  != b.visualMATrendColor)  return false;
   if(a.visualMATrend2Color != b.visualMATrend2Color) return false;
   if(a.visualBBColor       != b.visualBBColor)       return false;
   if(a.visualMAFastStyle   != b.visualMAFastStyle)   return false;
   if(a.visualMASlowStyle   != b.visualMASlowStyle)   return false;
   if(a.visualMATrendStyle  != b.visualMATrendStyle)  return false;
   if(a.visualMATrend2Style != b.visualMATrend2Style) return false;
   if(a.visualBBStyle       != b.visualBBStyle)       return false;

   //--- conflito e direcao
   if(a.conflictMode        != b.conflictMode)        return false;
   if(a.tradeDirection      != b.tradeDirection)      return false;

   //--- spread e sessao
   if(a.enableSpreadProtection != b.enableSpreadProtection) return false;
   if(a.maxSpreadPoints     != b.maxSpreadPoints)     return false;
   if(a.enableSessionFilter != b.enableSessionFilter) return false;
   if(a.sessionStartHour    != b.sessionStartHour)    return false;
   if(a.sessionStartMinute  != b.sessionStartMinute)  return false;
   if(a.sessionEndHour      != b.sessionEndHour)      return false;
   if(a.sessionEndMinute    != b.sessionEndMinute)    return false;
   if(a.sessionOvernight    != b.sessionOvernight)    return false;
   if(a.closeOnSessionEnd   != b.closeOnSessionEnd)   return false;

   //--- noticias
   for(int i=0;i<FUSION_NEWS_WINDOW_COUNT;++i)
      if(!FusionSameNewsWindow(a.newsWindows[i],b.newsWindows[i])) return false;

   //--- limites diarios
   if(a.enableDailyLimits   != b.enableDailyLimits)   return false;
   if(a.maxDailyTrades      != b.maxDailyTrades)      return false;
   if(!FusionSameDouble(a.maxDailyLoss,b.maxDailyLoss)) return false;
   if(!FusionSameDouble(a.maxDailyGain,b.maxDailyGain)) return false;
   if(a.profitTargetAction  != b.profitTargetAction)  return false;

   //--- drawdown
   if(a.enableDrawdown      != b.enableDrawdown)      return false;
   if(!FusionSameDouble(a.maxDrawdown,b.maxDrawdown)) return false;
   if(a.drawdownType        != b.drawdownType)        return false;
   if(a.drawdownPeakMode    != b.drawdownPeakMode)    return false;

   //--- sequencias
   if(a.lossStreakEnabled   != b.lossStreakEnabled)   return false;
   if(a.maxLossStreak       != b.maxLossStreak)       return false;
   if(a.lossStreakAction    != b.lossStreakAction)    return false;
   if(a.lossStreakPauseMinutes != b.lossStreakPauseMinutes) return false;
   if(a.winStreakEnabled    != b.winStreakEnabled)    return false;
   if(a.maxWinStreak        != b.maxWinStreak)        return false;
   if(a.winStreakAction     != b.winStreakAction)     return false;
   if(a.winStreakPauseMinutes != b.winStreakPauseMinutes) return false;

   //--- risco
   if(!FusionSameDouble(a.fixedLot,b.fixedLot))       return false;
   if(a.fixedSLPoints       != b.fixedSLPoints)       return false;
   if(a.fixedTPPoints       != b.fixedTPPoints)       return false;
   if(a.compensateSLSpread  != b.compensateSLSpread)  return false;
   if(a.compensateTPSpread  != b.compensateTPSpread)  return false;
   if(a.usePartialTP        != b.usePartialTP)        return false;
   if(a.freeFinalTP         != b.freeFinalTP)         return false;
   if(!FusionSamePartialTP(a.tp1,b.tp1))              return false;
   if(!FusionSamePartialTP(a.tp2,b.tp2))              return false;
   if(a.useTrailing         != b.useTrailing)         return false;
   if(a.trailingStartPoints != b.trailingStartPoints) return false;
   if(a.trailingStepPoints  != b.trailingStepPoints)  return false;
   if(a.useBreakeven        != b.useBreakeven)        return false;
   if(a.breakevenTriggerPoints != b.breakevenTriggerPoints) return false;
   if(a.breakevenOffsetPoints  != b.breakevenOffsetPoints)  return false;

   //--- estrategia MA Cross
   if(a.useMACross          != b.useMACross)          return false;
   if(a.maCrossPriority     != b.maCrossPriority)     return false;
   if(a.maFastPeriod        != b.maFastPeriod)        return false;
   if(a.maSlowPeriod        != b.maSlowPeriod)        return false;
   if(a.maMinDistancePoints != b.maMinDistancePoints) return false;
   if(a.maFastTimeframe     != b.maFastTimeframe)     return false;
   if(a.maSlowTimeframe     != b.maSlowTimeframe)     return false;
   if(a.maFastMethod        != b.maFastMethod)        return false;
   if(a.maSlowMethod        != b.maSlowMethod)        return false;
   if(a.maFastPrice         != b.maFastPrice)         return false;
   if(a.maSlowPrice         != b.maSlowPrice)         return false;
   if(a.maEntryMode         != b.maEntryMode)         return false;
   if(a.maExitMode          != b.maExitMode)          return false;

   //--- estrategia RSI
   if(a.useRSI              != b.useRSI)              return false;
   if(a.rsiPriority         != b.rsiPriority)         return false;
   if(a.rsiPeriod           != b.rsiPeriod)           return false;
   if(a.rsiTimeframe        != b.rsiTimeframe)        return false;
   if(a.rsiOversold         != b.rsiOversold)         return false;
   if(a.rsiOverbought       != b.rsiOverbought)       return false;
   if(a.rsiMiddle           != b.rsiMiddle)           return false;
   if(a.rsiMode             != b.rsiMode)             return false;
   if(a.rsiPrice            != b.rsiPrice)            return false;
   if(a.rsiExitMode         != b.rsiExitMode)         return false;

   //--- estrategia Bollinger
   if(a.useBollinger        != b.useBollinger)        return false;
   if(a.bbPriority          != b.bbPriority)          return false;
   if(a.bbPeriod            != b.bbPeriod)            return false;
   if(a.bbTimeframe         != b.bbTimeframe)         return false;
   if(!FusionSameDouble(a.bbDeviation,b.bbDeviation)) return false;
   if(a.bbPrice             != b.bbPrice)             return false;
   if(a.bbMode              != b.bbMode)              return false;
   if(a.bbExitMode          != b.bbExitMode)          return false;

   //--- filtro de tendencia (useTrendFilter e derivado, mas comparado assim
   //--- mesmo: se divergir, algo o deixou fora de sincronia e queremos saber)
   if(a.useTrendFilter      != b.useTrendFilter)      return false;
   if(a.trendMA1Enabled     != b.trendMA1Enabled)     return false;
   if(a.trendMAPeriod       != b.trendMAPeriod)       return false;
   if(a.trendMATimeframe    != b.trendMATimeframe)    return false;
   if(a.trendMAMethod       != b.trendMAMethod)       return false;
   if(a.trendMAPrice        != b.trendMAPrice)        return false;
   if(a.trendMA2Enabled     != b.trendMA2Enabled)     return false;
   if(a.trendSellMAPeriod   != b.trendSellMAPeriod)   return false;
   if(a.trendSellMATimeframe!= b.trendSellMATimeframe)return false;
   if(a.trendSellMAMethod   != b.trendSellMAMethod)   return false;
   if(a.trendSellMAPrice    != b.trendSellMAPrice)    return false;

   //--- filtro RSI
   if(a.useRSIFilter        != b.useRSIFilter)        return false;
   if(a.rsiFilterMode       != b.rsiFilterMode)       return false;
   if(a.rsiFilterPeriod     != b.rsiFilterPeriod)     return false;
   if(a.rsiFilterTimeframe  != b.rsiFilterTimeframe)  return false;
   if(a.rsiFilterBuyMin     != b.rsiFilterBuyMin)     return false;
   if(a.rsiFilterSellMax    != b.rsiFilterSellMax)    return false;
   if(a.rsiFilterPrice      != b.rsiFilterPrice)      return false;

   //--- filtro Bollinger
   if(a.bbFilterEnabled     != b.bbFilterEnabled)     return false;
   if(a.bbFilterMode        != b.bbFilterMode)        return false;
   if(a.bbFilterPeriod      != b.bbFilterPeriod)      return false;
   if(a.bbFilterTimeframe   != b.bbFilterTimeframe)   return false;
   if(!FusionSameDouble(a.bbFilterDeviation,b.bbFilterDeviation)) return false;
   if(a.bbFilterPrice       != b.bbFilterPrice)       return false;
   if(a.bbFilterMinWidthPoints != b.bbFilterMinWidthPoints) return false;
   if(!FusionSameDouble(a.bbFilterMinWidthPercent,b.bbFilterMinWidthPercent)) return false;
   if(a.bbFilterSlopeDirectionEnabled != b.bbFilterSlopeDirectionEnabled) return false;
   if(a.bbFilterSlopeLookback  != b.bbFilterSlopeLookback)  return false;
   if(a.bbFilterMinSlopePoints != b.bbFilterMinSlopePoints) return false;

   return true;
  }

#endif
