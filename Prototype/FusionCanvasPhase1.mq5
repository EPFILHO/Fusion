//+------------------------------------------------------------------+
//| FusionCanvasPhase1.mq5                                            |
//| Harness da Fase 1 da GUI 2.0: anexa o renderizador canvas com     |
//| dados falsos. NAO faz parte do EA: nao opera, nao le perfil, nao  |
//| toca em ordem.                                                    |
//|                                                                   |
//| Diferente do prototipo (que e monolitico e congelado como         |
//| referencia), este harness consome os modulos definitivos de       |
//| UI\Canvas\ — os mesmos que a Fase 2 embrulha na interface do      |
//| painel. Por isso ele e alvo do gate de build: os modulos precisam |
//| fechar em 0/0 a cada passo.                                       |
//|                                                                   |
//| Teclas com o grafico em foco:                                     |
//|   M — roda a medicao de custo de desenho (resultado no log)       |
//|   S — liga/desliga a tela sintetica de pior caso                  |
//+------------------------------------------------------------------+
#include "..\Core\Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property description "Fase 1 da GUI 2.0: renderizador canvas com dados falsos. Nao opera."

#include "..\UI\Canvas\CanvasRenderer.mqh"
//--- Fase 2, em construcao: so incluido para o gate compilar a classe a cada
//--- passo. O harness continua desenhando com CFusionCanvasRenderer direto;
//--- nada aqui muda o comportamento da Fase 1.
#include "..\UI\Canvas\CanvasPanel.mqh"

input ENUM_FUSION_CANVAS_PALETTE inp_Palette = FUSION_PALETTE_PETROLEO;    // Paleta
input ENUM_FUSION_CANVAS_THEME   inp_Theme   = FUSION_CANVAS_THEME_AUTO;  // Tema do painel
input bool inp_RememberAppearance = true; // Lembrar aparencia escolhida no painel
input bool inp_MeasureOnStart     = true; // Medir custo de desenho ao iniciar

CFusionCanvasRenderer g_panel;

//+------------------------------------------------------------------+
//| Snapshot sintetico com os campos que o EA preencheria.            |
//|                                                                   |
//| E o que permite exercitar o mapeamento snapshot -> tela SEM tocar |
//| no EA: os tipos sao os reais (SUIPanelSnapshot de Core/Types.mqh),|
//| so os valores e que sao inventados aqui. Se um campo mudar de     |
//| nome ou tipo, este harness para de compilar — que e exatamente o  |
//| aviso que queremos.                                               |
//+------------------------------------------------------------------+
SUIPanelSnapshot BuildFakeSnapshot(void)
  {
   SUIPanelSnapshot s;
   //--- Base conhecida antes de qualquer substituicao: assim os campos que este
   //--- harness ainda nao exercita valem o padrao do EA, e nao o que estiver na
   //--- memoria. Um valor absurdo vindo dai pareceria defeito do painel.
   SetDefaultSettings(s.settings);
   s.symbol            = _Symbol;
   //--- Resumo dos TFs das estrategias ligadas, no formato que o EA monta em
   //--- OperationalTimeframesSummary — NAO e o timeframe do grafico.
   s.timeframe         = "MA M1/M5 | RSI M15";
   s.activeProfileName = "BTCUSD";
   s.activeProfileFileMissing = false;
   s.started           = false;
   s.hasPosition       = false;
   s.runtimeBlocked    = false;
   s.magicNumber       = 10001;
   s.activeStrategies  = 1;
   s.activeFilters     = 0;
   s.conflictMode      = CONFLICT_PRIORITY;
   s.ownerStrategyName = "";
   //--- Motivos vazios atribuidos EXPLICITAMENTE. Em MQL5 uma string nunca
   //--- atribuida vale NULL, que nao e igual a "": deixados de fora, os testes
   //--- de "tem motivo?" davam verdadeiro e o painel se comportava como se
   //--- houvesse bloqueio — INICIAR e SALVAR desabilitados sem causa visivel.
   s.runtimeNotice              = "";
   s.runtimeBlockReason         = "";
   s.startBlockedReason         = "";
   s.activeProfileBlockedReason = "";
   s.entryBlockReason           = "";
   s.entryBlockDetail           = "";
   s.tradePermissionReason      = "";
   s.dailyLimitsBlockReason     = "";
   s.drawdownConfigLockReason   = "";
   s.sessionProtectionBlockReason = "";
   s.newsProtectionBlockReason  = "";
   s.tradePermissionBlocked     = false;
   s.pendingReverseExit         = false;
   s.entryBlockIsRiskStops      = false;
   s.dailyLimitsBlocked         = false;
   s.sessionProtectionBlocked   = false;
   s.newsProtectionBlocked      = false;

   //--- Resultados: valores escolhidos para exercitar os estados, nao para
   //--- parecerem plausiveis. Fechado positivo e flutuante negativo mostram as
   //--- duas cores na mesma tela; drawdown ligado com folga positiva mostra o
   //--- selo ATIVO e os numeros de base preenchidos.
   s.dailyClosedProfit        = 125.40;
   s.dailyFloatingProfit      = -32.10;
   s.dailyProjectedProfit     = 93.30;
   s.dailyTradeCount          = 7;
   s.dailyOutcomeCountsKnown  = true;
   s.dailyLossCount           = 3;
   s.dailyWinCount            = 4;
   s.dailyBreakevenCount      = 0;
   s.partialReconciliationPending = false;
   s.lossStreak               = 1;
   s.winStreak                = 2;
   s.settings.lossStreakEnabled = true;
   s.settings.winStreakEnabled  = false;
   s.settings.enableDrawdown  = true;
   s.drawdownProtectionActive = true;
   s.drawdownLimitReached     = false;
   s.drawdownPeakProfit       = 180.00;
   s.drawdownFloorProfit      = 144.00;
   s.drawdownBufferProfit     = 18.60;

   //--- Parametros de estrategia deliberadamente FORA do padrao. Com valores
   //--- padrao a tela ficaria igual quer os controles estejam ligados aos
   //--- campos, quer os numeros estejam escritos no desenho — e o teste nao
   //--- distinguiria as duas coisas. Cada valor aqui e unico.
   s.settings.useMACross          = true;
   s.settings.maCrossPriority     = 700;
   s.settings.maFastPeriod        = 8;
   s.settings.maFastTimeframe     = PERIOD_M15;
   s.settings.maFastMethod        = MODE_EMA;
   s.settings.maFastPrice         = PRICE_TYPICAL;
   s.settings.maSlowPeriod        = 34;
   s.settings.maSlowTimeframe     = PERIOD_H1;
   s.settings.maSlowMethod        = MODE_LWMA;
   s.settings.maSlowPrice         = PRICE_WEIGHTED;
   s.settings.maMinDistancePoints = 150;
   s.settings.maEntryMode         = ENTRY_2ND_CANDLE;
   s.settings.maExitMode          = EXIT_REVERSE_SIGNAL;

   s.settings.useRSI              = true;
   s.settings.rsiPriority         = 450;
   s.settings.rsiPeriod           = 21;
   s.settings.rsiTimeframe        = PERIOD_M30;
   s.settings.rsiPrice            = PRICE_MEDIAN;
   s.settings.rsiMode             = RSI_SIGNAL_ZONE;
   s.settings.rsiOversold         = 25;
   s.settings.rsiOverbought       = 75;
   s.settings.rsiMiddle           = 55;
   s.settings.rsiExitMode         = RSI_EXIT_MIDDLE_TARGET;

   s.settings.useBollinger        = false;
   s.settings.bbPriority          = 120;
   s.settings.bbPeriod            = 26;
   s.settings.bbDeviation         = 2.75;
   s.settings.bbTimeframe         = PERIOD_H4;
   s.settings.bbPrice             = PRICE_LOW;
   s.settings.bbMode              = BB_SIGNAL_BREAKOUT;
   s.settings.bbExitMode          = EXIT_OPPOSITE_SIGNAL;

   s.settings.conflictMode        = CONFLICT_CANCEL;

   //--- Filtros, tambem fora do padrao, pelo mesmo motivo.
   s.settings.useTrendFilter      = true;
   s.settings.trendMA1Enabled     = true;
   s.settings.trendMAPeriod       = 55;
   s.settings.trendMATimeframe    = PERIOD_H2;
   s.settings.trendMAMethod       = MODE_SMMA;
   s.settings.trendMAPrice        = PRICE_OPEN;
   s.settings.trendMA2Enabled     = true;
   s.settings.trendSellMAPeriod   = 13;
   s.settings.trendSellMATimeframe= PERIOD_M20;
   s.settings.trendSellMAMethod   = MODE_EMA;
   s.settings.trendSellMAPrice    = PRICE_HIGH;

   s.settings.useRSIFilter        = true;
   s.settings.rsiFilterMode       = RSI_FILTER_EXTREMES;
   s.settings.rsiFilterPeriod     = 9;
   s.settings.rsiFilterTimeframe  = PERIOD_M12;
   s.settings.rsiFilterPrice      = PRICE_TYPICAL;
   s.settings.rsiFilterBuyMin     = 45;
   s.settings.rsiFilterSellMax    = 40;

   s.settings.bbFilterEnabled     = false;
   s.settings.bbFilterMode        = BB_FILTER_WIDTH_RELATIVE;
   s.settings.bbFilterPeriod      = 33;
   s.settings.bbFilterTimeframe   = PERIOD_H6;
   s.settings.bbFilterDeviation   = 1.80;
   s.settings.bbFilterPrice       = PRICE_WEIGHTED;
   s.settings.bbFilterMinWidthPoints  = 250;
   s.settings.bbFilterMinWidthPercent = 0.65;
   s.settings.bbFilterSlopeDirectionEnabled = true;
   s.settings.bbFilterSlopeLookback   = 7;
   s.settings.bbFilterMinSlopePoints  = 35;
   //--- O snapshot repete as tres chaves fora de settings; divergir aqui
   //--- mascararia justamente o erro que esses campos existem para revelar.
   s.useMACross  = s.settings.useMACross;
   s.useRSI      = s.settings.useRSI;
   s.useBollinger= s.settings.useBollinger;
   s.conflictMode= s.settings.conflictMode;
   return s;
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   g_panel.SetSnapshot(BuildFakeSnapshot());
   if(!g_panel.Create(0,"FusP1_",inp_Theme,inp_Palette,inp_RememberAppearance,10,20))
     {
      Print("Fase 1: falha ao criar o canvas.");
      return INIT_FAILED;
     }
   Print("Fase 1 da GUI 2.0 ativa (dados falsos). Teclas: M = medir custo, S = tela de estresse.");
   if(inp_MeasureOnStart) g_panel.RunPerfSuite();
   EventSetMillisecondTimer(200);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_panel.Destroy();
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_panel.ChartEvent(id,lparam,dparam,sparam);
  }

//+------------------------------------------------------------------+
void OnTick(void)
  {
  }

//--- Mesma cadencia do EA com posicao aberta (5 Hz). Existe para o harness
//--- exercitar o que o painel percebe sozinho — hoje, o texto digitado e ainda
//--- nao confirmado. O Pulse so redesenha quando ha algo novo a mostrar.
void OnTimer(void)
  {
   g_panel.Pulse();
  }
