#ifndef __FUSION_INPUTS_MQH__
#define __FUSION_INPUTS_MQH__

#include "Types.mqh"

enum ENUM_FUSION_INPUT_TIMEFRAME
  {
   TIMEFRAME_M1 = 0,
   TIMEFRAME_M2,
   TIMEFRAME_M3,
   TIMEFRAME_M4,
   TIMEFRAME_M5,
   TIMEFRAME_M6,
   TIMEFRAME_M10,
   TIMEFRAME_M12,
   TIMEFRAME_M15,
   TIMEFRAME_M20,
   TIMEFRAME_M30,
   TIMEFRAME_H1,
   TIMEFRAME_H2,
   TIMEFRAME_H3,
   TIMEFRAME_H4,
   TIMEFRAME_H6,
   TIMEFRAME_H8,
   TIMEFRAME_H12,
   TIMEFRAME_D1,
   TIMEFRAME_W1,
   TIMEFRAME_MN1
  };

ENUM_TIMEFRAMES FusionInputTimeframeToPeriod(const ENUM_FUSION_INPUT_TIMEFRAME timeframe)
  {
   switch(timeframe)
     {
      case TIMEFRAME_M1:  return PERIOD_M1;
      case TIMEFRAME_M2:  return PERIOD_M2;
      case TIMEFRAME_M3:  return PERIOD_M3;
      case TIMEFRAME_M4:  return PERIOD_M4;
      case TIMEFRAME_M5:  return PERIOD_M5;
      case TIMEFRAME_M6:  return PERIOD_M6;
      case TIMEFRAME_M10: return PERIOD_M10;
      case TIMEFRAME_M12: return PERIOD_M12;
      case TIMEFRAME_M15: return PERIOD_M15;
      case TIMEFRAME_M20: return PERIOD_M20;
      case TIMEFRAME_M30: return PERIOD_M30;
      case TIMEFRAME_H1:  return PERIOD_H1;
      case TIMEFRAME_H2:  return PERIOD_H2;
      case TIMEFRAME_H3:  return PERIOD_H3;
      case TIMEFRAME_H4:  return PERIOD_H4;
      case TIMEFRAME_H6:  return PERIOD_H6;
      case TIMEFRAME_H8:  return PERIOD_H8;
      case TIMEFRAME_H12: return PERIOD_H12;
      case TIMEFRAME_D1:  return PERIOD_D1;
      case TIMEFRAME_W1:  return PERIOD_W1;
      case TIMEFRAME_MN1: return PERIOD_MN1;
     }
   return FUSION_DEFAULT_TIMEFRAME;
  }

//+------------------------------------------------------------------+
//| INPUTS - organizacao amigavel para o Tester do MT5               |
//+------------------------------------------------------------------+

//--- Identificacao geral e defaults de execucao
input group "========== 001 - GERAL =========="
input int    inp_MagicNumber               = 10001;     // Magic number das posicoes do Fusion
input int    inp_SlippagePoints            = 20;        // Slippage maximo de execucao em pontos
input bool   inp_EnableDebugLogs           = false;     // Ativar logs detalhados de debug

input group " "
//--- Painel, perfil e restauracao de estado do grafico
input group "========== 002 - PAINEL E PERFIL =========="
input bool   inp_ShowPanel                 = true;      // Mostrar GUI do Fusion no grafico
input string inp_DefaultProfileName        = "default"; // Perfil carregado/criado na inicializacao

input group " "
//--- Arbitragem de sinais e direcao global de entrada
input group "========== 003 - MOTOR DE SINAIS =========="
input ENUM_CONFLICT_RESOLUTION inp_ConflictMode = CONFLICT_PRIORITY; // Modo de conflito entre estrategias
input ENUM_TRADE_DIRECTION     inp_TradeDirection = DIRECTION_BOTH;  // Direcao permitida para entradas

input group " "
//--- Protecoes de entrada: spread e direcao
input group "========== 004 - PROTECAO / ENTRADA =========="
input bool   inp_EnableSpreadProtection    = false;     // Ativar protecao de spread maximo
input int    inp_MaxSpreadPoints           = 0;         // Spread maximo em pontos; 0 desliga via inputs

input group " "
//--- Janela de sessao: use Overnight quando cruzar meia-noite
input group "========== 005 - PROTECAO / SESSAO =========="
input bool   inp_EnableSessionFilter       = false;     // Bloquear entradas fora da janela de sessao
input int    inp_SessionStartHour          = 9;         // Hora de inicio da sessao, 0..23
input int    inp_SessionStartMinute        = 0;         // Minuto de inicio da sessao, 0..59
input int    inp_SessionEndHour            = 17;        // Hora de fim da sessao, 0..23
input int    inp_SessionEndMinute          = 0;         // Minuto de fim da sessao, 0..59
input bool   inp_SessionOvernight          = false;     // ON: inicio deve ser depois do fim
input bool   inp_CloseOnSessionEnd         = false;     // Fechar posicao aberta no fim da sessao

input group " "
//--- Janela de news 1: bloqueia entradas e pode fechar posicoes
input group "========== 006 - PROTECAO / NEWS 1 =========="
input bool   inp_EnableNewsWindow1         = false;     // Ativar janela de news 1
input int    inp_News1StartHour            = 0;         // Hora de inicio da news 1, 0..23
input int    inp_News1StartMinute          = 0;         // Minuto de inicio da news 1, 0..59
input int    inp_News1EndHour              = 0;         // Hora de fim da news 1, 0..23
input int    inp_News1EndMinute            = 0;         // Minuto de fim da news 1, 0..59
input bool   inp_News1ClosePositions       = false;     // Fechar posicoes durante news 1

input group " "
//--- Janela de news 2: bloqueia entradas e pode fechar posicoes
input group "========== 007 - PROTECAO / NEWS 2 =========="
input bool   inp_EnableNewsWindow2         = false;     // Ativar janela de news 2
input int    inp_News2StartHour            = 0;         // Hora de inicio da news 2, 0..23
input int    inp_News2StartMinute          = 0;         // Minuto de inicio da news 2, 0..59
input int    inp_News2EndHour              = 0;         // Hora de fim da news 2, 0..23
input int    inp_News2EndMinute            = 0;         // Minuto de fim da news 2, 0..59
input bool   inp_News2ClosePositions       = false;     // Fechar posicoes durante news 2

input group " "
//--- Janela de news 3: bloqueia entradas e pode fechar posicoes
input group "========== 008 - PROTECAO / NEWS 3 =========="
input bool   inp_EnableNewsWindow3         = false;     // Ativar janela de news 3
input int    inp_News3StartHour            = 0;         // Hora de inicio da news 3, 0..23
input int    inp_News3StartMinute          = 0;         // Minuto de inicio da news 3, 0..59
input int    inp_News3EndHour              = 0;         // Hora de fim da news 3, 0..23
input int    inp_News3EndMinute            = 0;         // Minuto de fim da news 3, 0..59
input bool   inp_News3ClosePositions       = false;     // Fechar posicoes durante news 3

input group " "
//--- Protecoes diarias, drawdown e sequencia
input group "========== 009 - PROTECAO / LIMITES =========="
input bool   inp_EnableDailyLimits         = false;     // Ativar limites diarios de trades e P/L
input int    inp_MaxDailyTrades            = 0;         // Maximo de trades por dia; 0 desliga limite
input double inp_MaxDailyLoss              = 0.0;       // Perda diaria maxima; 0 desliga limite
input double inp_MaxDailyGain              = 0.0;       // Ganho diario maximo; 0 desliga limite
input ENUM_PROFIT_TARGET_ACTION inp_ProfitTargetAction = PROFIT_ACTION_PARAR; // Acao ao atingir ganho diario
input bool   inp_EnableDrawdown            = false;     // Ativar protecao de drawdown
input double inp_MaxDrawdown               = 0.0;       // Valor maximo de drawdown
input ENUM_DRAWDOWN_TYPE inp_DrawdownType  = DD_TIPO_FINANCEIRO; // Tipo do DD
input ENUM_DRAWDOWN_PEAK_MODE inp_DrawdownPeakMode = DD_PICO_FLUTUANTE; // Base do DD
input bool   inp_EnableLossStreak          = false;     // Ativar limite por perdas seguidas
input int    inp_MaxLossStreak             = 0;         // Maximo de perdas seguidas; 0 desliga limite
input ENUM_STREAK_ACTION inp_LossStreakAction = STREAK_ACTION_PAUSE; // Acao ao atingir perdas
input int    inp_LossStreakPauseMinutes    = 30;        // Pausa apos perdas, em minutos
input bool   inp_EnableWinStreak           = false;     // Ativar limite por ganhos seguidos
input int    inp_MaxWinStreak              = 0;         // Maximo de ganhos seguidos; 0 desliga limite
input ENUM_STREAK_ACTION inp_WinStreakAction = STREAK_ACTION_STOP_DAY; // Acao ao atingir ganhos
input int    inp_WinStreakPauseMinutes     = 30;        // Pausa apos ganhos, em minutos

input group " "
//--- Configuracoes globais usadas pelos modulos de risco/execucao
input group "========== 010 - RISCO GLOBAL =========="
input double inp_FixedLot                  = 0.10;      // Lote fixo
input int    inp_FixedSLPoints             = 200;       // Stop loss fixo em pontos; 0 desliga
input int    inp_FixedTPPoints             = 400;       // Take profit fixo em pontos; 0 desliga
input bool   inp_CompensateSLSpread        = false;     // Compensar spread no SL
input bool   inp_CompensateTPSpread        = false;     // Compensar spread no TP
input bool   inp_EnableTP1                 = false;     // Ativar TP1
input double inp_TP1Percent                = 50.0;      // Percentual de volume do TP1
input int    inp_TP1DistancePoints         = 150;       // Distancia do TP1 em pontos
input bool   inp_EnableTP2                 = false;     // Ativar TP2
input double inp_TP2Percent                = 25.0;      // Percentual de volume do TP2
input int    inp_TP2DistancePoints         = 300;       // Distancia do TP2 em pontos
input bool   inp_FreeFinalTP               = false;     // TP final livre apos parcial; requer trailing ativo
input bool   inp_UseTrailing               = false;     // Ativar trailing stop
input int    inp_TrailingStartPoints       = 150;       // Inicio do trailing em pontos
input int    inp_TrailingStepPoints        = 80;        // Passo do trailing em pontos
input bool   inp_UseBreakeven              = false;     // Ativar breakeven
input int    inp_BreakevenTriggerPoints    = 120;       // Gatilho do breakeven em pontos
input int    inp_BreakevenOffsetPoints     = 10;        // Offset do breakeven em pontos

input group " "
//--- Estrategia MA Cross
input group "========== 011 - ESTRATEGIA / MA CROSS =========="
input bool               inp_UseMACross    = true;      // Ativar estrategia MA Cross
input int                inp_MACrossPriority = 10;      // Prioridade da estrategia; maior vence
input int                inp_MAFastPeriod  = 9;         // Periodo da media rapida
input int                inp_MASlowPeriod  = 21;        // Periodo da media lenta
input int                inp_MAMinDistancePoints = 0;   // Distancia minima entre medias; 0 desliga
input ENUM_FUSION_INPUT_TIMEFRAME inp_MAFastTF = TIMEFRAME_M15; // Timeframe da media rapida
input ENUM_FUSION_INPUT_TIMEFRAME inp_MASlowTF = TIMEFRAME_M15; // Timeframe da media lenta
input ENUM_MA_METHOD     inp_MAFastMethod  = MODE_EMA;  // Metodo da media rapida
input ENUM_MA_METHOD     inp_MASlowMethod  = MODE_EMA;  // Metodo da media lenta
input ENUM_APPLIED_PRICE inp_MAFastPrice   = PRICE_CLOSE; // Preco da media rapida
input ENUM_APPLIED_PRICE inp_MASlowPrice   = PRICE_CLOSE; // Preco da media lenta
input ENUM_ENTRY_MODE    inp_MAEntryMode   = ENTRY_NEXT_CANDLE; // Momento da entrada
input ENUM_EXIT_MODE     inp_MAExitMode    = EXIT_OPPOSITE_SIGNAL; // Modo de saida

input group " "
//--- Estrategia RSI
input group "========== 012 - ESTRATEGIA / RSI =========="
input bool                   inp_UseRSI    = false;     // Ativar estrategia RSI
input int                    inp_RSIPriority = 8;       // Prioridade da estrategia; maior vence
input int                    inp_RSIPeriod = 14;        // Periodo do RSI
input ENUM_FUSION_INPUT_TIMEFRAME inp_RSITF = TIMEFRAME_M15; // Timeframe do RSI
input int                    inp_RSIOversold = 30;      // Nivel de sobrevenda
input int                    inp_RSIOverbought = 70;    // Nivel de sobrecompra
input int                    inp_RSIMiddle = 50;        // Nivel central
input ENUM_RSI_SIGNAL_MODE   inp_RSIMode   = RSI_SIGNAL_CROSSOVER; // Modo de sinal
input ENUM_APPLIED_PRICE     inp_RSIPrice  = PRICE_CLOSE; // Preco aplicado ao RSI
input ENUM_RSI_EXIT_MODE     inp_RSIExitMode = RSI_EXIT_OPPOSITE_SIGNAL; // Modo de saida

input group " "
//--- Estrategia Bollinger; independente do BB Filter
input group "========== 013 - ESTRATEGIA / BOLLINGER =========="
input bool                   inp_UseBollinger = false;  // Ativar estrategia Bollinger
input int                    inp_BollingerPriority = 6; // Prioridade da estrategia; maior vence
input int                    inp_BollingerPeriod = 20;  // Periodo do Bollinger
input ENUM_FUSION_INPUT_TIMEFRAME inp_BollingerTF = TIMEFRAME_M15; // Timeframe do Bollinger
input double                 inp_BollingerDeviation = 2.0; // Desvio do Bollinger
input ENUM_APPLIED_PRICE     inp_BollingerPrice = PRICE_CLOSE; // Preco aplicado ao Bollinger
input ENUM_BB_SIGNAL_MODE    inp_BollingerMode = BB_SIGNAL_REENTRY; // Modo de sinal
input ENUM_EXIT_MODE         inp_BollingerExitMode = EXIT_OPPOSITE_SIGNAL; // Modo de saida

input group " "
//--- Trend Filter: bloqueia sinais contra a media de tendencia
input group "========== 014 - FILTRO / TREND =========="
input bool               inp_UseTrendFilter = false;    // Ativar Trend Filter
input int                inp_TrendMAPeriod  = 50;       // Periodo da media de tendencia
input ENUM_FUSION_INPUT_TIMEFRAME inp_TrendMATF = TIMEFRAME_M15; // Timeframe da media de tendencia
input ENUM_MA_METHOD     inp_TrendMAMethod  = MODE_SMA; // Metodo da media de tendencia
input ENUM_APPLIED_PRICE inp_TrendMAPrice   = PRICE_CLOSE; // Preco da media de tendencia

input group " "
//--- RSI Filter: aprova ou bloqueia sinais; nunca abre trades
input group "========== 015 - FILTRO / RSI =========="
input bool               inp_UseRSIFilter   = false;    // Ativar RSI Filter
input ENUM_RSI_FILTER_MODE inp_RSIFilterMode = RSI_FILTER_DIRECTION; // Modo do filtro
input int                inp_RSIFilterPeriod = 14;      // Periodo do RSI Filter
input ENUM_FUSION_INPUT_TIMEFRAME inp_RSIFilterTF = TIMEFRAME_M15; // Timeframe do RSI Filter
input int                inp_RSIFilterBuyMin = 50;      // Linha de direcao ou limite de compra
input int                inp_RSIFilterSellMax = 50;     // Limite de venda quando o modo usa
input ENUM_APPLIED_PRICE inp_RSIFilterPrice = PRICE_CLOSE; // Preco aplicado ao RSI Filter

input group " "
//--- BB Filter: anti-squeeze independente da estrategia Bollinger
input group "========== 016 - FILTRO / BOLLINGER =========="
input bool                    inp_UseBBFilter = false;  // Ativar BB Filter
input ENUM_BB_FILTER_WIDTH_MODE inp_BBFilterMode = BB_FILTER_WIDTH_ABSOLUTE; // Modo de largura
input int                     inp_BBFilterPeriod = 20;  // Periodo do Bollinger Filter
input ENUM_FUSION_INPUT_TIMEFRAME inp_BBFilterTF = TIMEFRAME_M15; // Timeframe do Bollinger Filter
input double                  inp_BBFilterDeviation = 2.0; // Desvio do Bollinger Filter
input ENUM_APPLIED_PRICE      inp_BBFilterPrice = PRICE_CLOSE; // Preco aplicado ao Bollinger Filter
input int                     inp_BBFilterMinWidthPoints = 100; // Largura minima das bandas em pontos
input double                  inp_BBFilterMinWidthPercent = 0.20; // Largura minima das bandas em percentual

void FillSettingsFromInputs(SEASettings &settings)
  {
   SetDefaultSettings(settings);

   settings.magicNumber            = inp_MagicNumber;
   settings.slippagePoints         = inp_SlippagePoints;
   settings.debugLogs              = inp_EnableDebugLogs;
   settings.panelEnabled           = inp_ShowPanel;
   settings.defaultProfileName     = inp_DefaultProfileName;
   settings.conflictMode           = inp_ConflictMode;
   settings.tradeDirection         = inp_TradeDirection;
   settings.enableSpreadProtection = (inp_EnableSpreadProtection || inp_MaxSpreadPoints > 0);
   settings.maxSpreadPoints        = inp_MaxSpreadPoints;
   settings.enableSessionFilter    = inp_EnableSessionFilter;
   settings.sessionStartHour       = inp_SessionStartHour;
   settings.sessionStartMinute     = inp_SessionStartMinute;
   settings.sessionEndHour         = inp_SessionEndHour;
   settings.sessionEndMinute       = inp_SessionEndMinute;
   settings.sessionOvernight       = inp_SessionOvernight;
   settings.closeOnSessionEnd      = inp_CloseOnSessionEnd;
   settings.newsWindows[0].enabled = inp_EnableNewsWindow1;
   settings.newsWindows[0].startHour = inp_News1StartHour;
   settings.newsWindows[0].startMinute = inp_News1StartMinute;
   settings.newsWindows[0].endHour = inp_News1EndHour;
   settings.newsWindows[0].endMinute = inp_News1EndMinute;
   settings.newsWindows[0].action = inp_News1ClosePositions ? NEWS_ACTION_CLOSE_AND_BLOCK : NEWS_ACTION_BLOCK_ENTRIES;
   settings.newsWindows[1].enabled = inp_EnableNewsWindow2;
   settings.newsWindows[1].startHour = inp_News2StartHour;
   settings.newsWindows[1].startMinute = inp_News2StartMinute;
   settings.newsWindows[1].endHour = inp_News2EndHour;
   settings.newsWindows[1].endMinute = inp_News2EndMinute;
   settings.newsWindows[1].action = inp_News2ClosePositions ? NEWS_ACTION_CLOSE_AND_BLOCK : NEWS_ACTION_BLOCK_ENTRIES;
   settings.newsWindows[2].enabled = inp_EnableNewsWindow3;
   settings.newsWindows[2].startHour = inp_News3StartHour;
   settings.newsWindows[2].startMinute = inp_News3StartMinute;
   settings.newsWindows[2].endHour = inp_News3EndHour;
   settings.newsWindows[2].endMinute = inp_News3EndMinute;
   settings.newsWindows[2].action = inp_News3ClosePositions ? NEWS_ACTION_CLOSE_AND_BLOCK : NEWS_ACTION_BLOCK_ENTRIES;
   settings.enableDailyLimits      = inp_EnableDailyLimits;
   settings.maxDailyTrades         = inp_MaxDailyTrades;
   settings.maxDailyLoss           = inp_MaxDailyLoss;
   settings.maxDailyGain           = inp_MaxDailyGain;
   settings.profitTargetAction     = inp_ProfitTargetAction;
   settings.enableDrawdown         = inp_EnableDrawdown;
   settings.maxDrawdown            = inp_MaxDrawdown;
   settings.drawdownType           = inp_DrawdownType;
   settings.drawdownPeakMode       = inp_DrawdownPeakMode;
   settings.lossStreakEnabled      = inp_EnableLossStreak;
   settings.maxLossStreak          = inp_MaxLossStreak;
   settings.lossStreakAction       = inp_LossStreakAction;
   settings.lossStreakPauseMinutes = inp_LossStreakPauseMinutes;
   settings.winStreakEnabled       = inp_EnableWinStreak;
   settings.maxWinStreak           = inp_MaxWinStreak;
   settings.winStreakAction        = inp_WinStreakAction;
   settings.winStreakPauseMinutes  = inp_WinStreakPauseMinutes;
   settings.fixedLot               = inp_FixedLot;
   settings.fixedSLPoints          = inp_FixedSLPoints;
   settings.fixedTPPoints          = inp_FixedTPPoints;
   settings.compensateSLSpread     = inp_CompensateSLSpread;
   settings.compensateTPSpread     = inp_CompensateTPSpread;
   settings.tp1.enabled            = inp_EnableTP1;
   settings.tp1.percent            = inp_TP1Percent;
   settings.tp1.distancePoints     = inp_TP1DistancePoints;
   settings.tp2.enabled            = inp_EnableTP2;
   settings.tp2.percent            = inp_TP2Percent;
   settings.tp2.distancePoints     = inp_TP2DistancePoints;
   settings.freeFinalTP            = inp_FreeFinalTP;
   if(!settings.tp1.enabled)
     {
      settings.tp2.enabled = false;
      settings.freeFinalTP = false;
     }
   settings.usePartialTP           = settings.tp1.enabled;
   settings.useTrailing            = inp_UseTrailing;
   settings.trailingStartPoints    = inp_TrailingStartPoints;
   settings.trailingStepPoints     = inp_TrailingStepPoints;
   settings.useBreakeven           = inp_UseBreakeven;
   settings.breakevenTriggerPoints = inp_BreakevenTriggerPoints;
   settings.breakevenOffsetPoints  = inp_BreakevenOffsetPoints;
   settings.useMACross             = inp_UseMACross;
   settings.maCrossPriority        = inp_MACrossPriority;
   settings.maFastPeriod           = inp_MAFastPeriod;
   settings.maSlowPeriod           = inp_MASlowPeriod;
   settings.maMinDistancePoints    = inp_MAMinDistancePoints;
   settings.maFastTimeframe        = FusionInputTimeframeToPeriod(inp_MAFastTF);
   settings.maSlowTimeframe        = FusionInputTimeframeToPeriod(inp_MASlowTF);
   settings.maFastMethod           = inp_MAFastMethod;
   settings.maSlowMethod           = inp_MASlowMethod;
   settings.maFastPrice            = inp_MAFastPrice;
   settings.maSlowPrice            = inp_MASlowPrice;
   settings.maEntryMode            = inp_MAEntryMode;
   settings.maExitMode             = inp_MAExitMode;
   settings.useRSI                 = inp_UseRSI;
   settings.rsiPriority            = inp_RSIPriority;
   settings.rsiPeriod              = inp_RSIPeriod;
   settings.rsiTimeframe           = FusionInputTimeframeToPeriod(inp_RSITF);
   settings.rsiOversold            = inp_RSIOversold;
   settings.rsiOverbought          = inp_RSIOverbought;
   settings.rsiMiddle              = inp_RSIMiddle;
   settings.rsiMode                = inp_RSIMode;
   settings.rsiPrice               = inp_RSIPrice;
   settings.rsiExitMode            = inp_RSIExitMode;
   settings.useBollinger           = inp_UseBollinger;
   settings.bbPriority             = inp_BollingerPriority;
   settings.bbPeriod               = inp_BollingerPeriod;
   settings.bbTimeframe            = FusionInputTimeframeToPeriod(inp_BollingerTF);
   settings.bbDeviation            = inp_BollingerDeviation;
   settings.bbPrice                = inp_BollingerPrice;
   settings.bbMode                 = inp_BollingerMode;
   settings.bbExitMode             = inp_BollingerExitMode;
   settings.useTrendFilter         = inp_UseTrendFilter;
   settings.trendMAPeriod          = inp_TrendMAPeriod;
   settings.trendMATimeframe       = FusionInputTimeframeToPeriod(inp_TrendMATF);
   settings.trendMAMethod          = inp_TrendMAMethod;
   settings.trendMAPrice           = inp_TrendMAPrice;
   settings.useRSIFilter           = inp_UseRSIFilter;
   settings.rsiFilterMode          = inp_RSIFilterMode;
   settings.rsiFilterPeriod        = inp_RSIFilterPeriod;
   settings.rsiFilterTimeframe     = FusionInputTimeframeToPeriod(inp_RSIFilterTF);
   settings.rsiFilterBuyMin        = inp_RSIFilterBuyMin;
   settings.rsiFilterSellMax       = inp_RSIFilterSellMax;
   settings.rsiFilterPrice         = inp_RSIFilterPrice;
   settings.bbFilterEnabled        = inp_UseBBFilter;
   settings.bbFilterMode           = inp_BBFilterMode;
   settings.bbFilterPeriod         = inp_BBFilterPeriod;
   settings.bbFilterTimeframe      = FusionInputTimeframeToPeriod(inp_BBFilterTF);
   settings.bbFilterDeviation      = inp_BBFilterDeviation;
   settings.bbFilterPrice          = inp_BBFilterPrice;
   settings.bbFilterMinWidthPoints = inp_BBFilterMinWidthPoints;
   settings.bbFilterMinWidthPercent = inp_BBFilterMinWidthPercent;
  }

#endif
