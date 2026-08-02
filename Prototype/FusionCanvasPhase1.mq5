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
//--- "PERIOD_M15" -> "M15". Copia do ShortTimeframeName do EA, que e metodo de
//--- classe e nao alcanca daqui.
string FakeShortTF(const ENUM_TIMEFRAMES tf)
  {
   string name=EnumToString(tf);
   const string prefix="PERIOD_";
   if(StringFind(name,prefix)==0) return StringSubstr(name,StringLen(prefix));
   return name;
  }

//--- Resumo dos TFs de CADA estrategia ligada — nao e o timeframe do grafico.
//--- Mesma montagem de OperationalTimeframesSummary (Core/EAApplicationModules),
//--- inclusive o detalhe de so mostrar a barra quando o TF lento difere do
//--- rapido, e o "--" quando nenhuma estrategia esta ligada.
string FakeTimeframesSummary(const SEASettings &st)
  {
   string summary="";
   if(st.useMACross)
     {
      string fast=FakeShortTF(st.maFastTimeframe);
      string slow=FakeShortTF(st.maSlowTimeframe);
      summary="MA "+fast;
      if(slow!=fast) summary+="/"+slow;
     }
   if(st.useRSI)
     {
      if(summary!="") summary+=" | ";
      summary+="RSI "+FakeShortTF(st.rsiTimeframe);
     }
   if(st.useBollinger)
     {
      if(summary!="") summary+=" | ";
      summary+="BB "+FakeShortTF(st.bbTimeframe);
     }
   return (summary=="" ? "--" : summary);
  }

SUIPanelSnapshot BuildFakeSnapshot(void)
  {
   SUIPanelSnapshot s;
   //--- Base conhecida antes de qualquer substituicao: assim os campos que este
   //--- harness ainda nao exercita valem o padrao do EA, e nao o que estiver na
   //--- memoria. Um valor absurdo vindo dai pareceria defeito do painel.
   SetDefaultSettings(s.settings);
   s.symbol            = _Symbol;
   //--- timeframe, activeStrategies e activeFilters sao DERIVADOS de settings e
   //--- por isso ficam no fim desta funcao, depois das chaves que os alimentam.
   //--- Escritos a mao aqui em cima, contradiziam os proprios settings do
   //--- harness — o resumo dizia "MA M1/M5 | RSI M15" enquanto as medias
   //--- estavam em M15/H1 e o RSI em M30, e a contagem dizia 1 estrategia com
   //--- duas ligadas. Quem testava concluia, com razao, que a tela e que estava
   //--- errada.
   s.activeProfileName = "BTCUSD";
   s.activeProfileFileMissing = false;
   s.started           = false;
   s.hasPosition       = false;
   s.runtimeBlocked    = false;
   s.magicNumber       = 10001;
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
   s.streakProtectionBlockReason  = "";
   s.tradePermissionBlocked     = false;
   s.pendingReverseExit         = false;
   s.entryBlockIsRiskStops      = false;
   s.dailyLimitsBlocked         = false;
   s.sessionProtectionBlocked   = false;
   s.newsProtectionBlocked      = false;
   //--- Os dois bloqueios de secao que a Gestao consulta. Sem valor explicito,
   //--- uma secao inteira poderia nascer somente-leitura no harness e o defeito
   //--- pareceria da tela, nao do dado.
   s.streakProtectionBlocked    = false;
   s.drawdownConfigLocked       = false;

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
   //--- Protecao de DD NAO disparada. E deliberado: com ela em curso, o resumo
   //--- responde ao ESTADO e ignora a chave — um DD que ja disparou continua
   //--- valendo mesmo com a chave desligada depois, e dizer "OFF" ali esconderia
   //--- um bloqueio em vigor (regra da 1.058, preservada). So que no harness o
   //--- estado e constante, entao o selo ficava preso em ATIVO e a chave parecia
   //--- morta. Com false, a chave manda e da para testa-la.
   //--- Para exercitar o caminho oposto, ligar esta linha ou drawdownLimitReached.
   s.drawdownProtectionActive = false;
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

   //--- Gestao > Risco, tambem fora do padrao, pelo mesmo motivo dos demais.
   //--- As chaves do TP parcial ficam LIGADAS de proposito: so com TP1 ativo da
   //--- para ver que TP2 e o TP Final Livre deixam de estar apagados, que e a
   //--- dependencia mais facil de portar errado.
   s.settings.fixedLot              = 0.30;
   s.settings.slippagePoints        = 15;
   s.settings.fixedSLPoints         = 350;
   s.settings.fixedTPPoints         = 700;
   s.settings.compensateSLSpread    = true;
   s.settings.compensateTPSpread    = false;
   s.settings.tp1.enabled           = true;
   s.settings.tp1.percent           = 40.0;
   s.settings.tp1.distancePoints    = 220;
   s.settings.tp2.enabled           = true;
   s.settings.tp2.percent           = 35.0;
   s.settings.tp2.distancePoints    = 480;
   s.settings.freeFinalTP           = false;
   s.settings.usePartialTP          = s.settings.tp1.enabled;   // derivado
   s.settings.useBreakeven          = true;
   s.settings.breakevenTriggerPoints= 95;
   s.settings.breakevenOffsetPoints = 25;
   s.settings.useTrailing           = false;   // apaga Inicio e Passo
   s.settings.trailingStartPoints   = 210;
   s.settings.trailingStepPoints    = 65;

   //--- Gestao > Protecao. Cada combo numa opcao diferente da padrao, senao a
   //--- ordem invertida de uma lista passaria despercebida — foi exatamente o
   //--- erro encontrado nas listas de Acao Ganho, Tipo DD e Base DD.
   s.settings.enableSpreadProtection= true;
   s.settings.maxSpreadPoints       = 45;
   s.settings.tradeDirection        = DIRECTION_SELL_ONLY;
   s.settings.enableSessionFilter   = true;
   s.settings.sessionStartHour      = 9;
   s.settings.sessionStartMinute    = 30;
   s.settings.sessionEndHour        = 17;
   s.settings.sessionEndMinute      = 45;
   s.settings.sessionOvernight      = false;
   s.settings.closeOnSessionEnd     = true;
   //--- Tres janelas com horarios distintos: um valor repetido nao provaria que
   //--- cada uma escreve no seu proprio item do array.
   s.settings.newsWindows[0].enabled     = true;
   s.settings.newsWindows[0].startHour   = 10;
   s.settings.newsWindows[0].startMinute = 25;
   s.settings.newsWindows[0].endHour     = 10;
   s.settings.newsWindows[0].endMinute   = 40;
   s.settings.newsWindows[0].action      = NEWS_ACTION_CLOSE_AND_BLOCK;
   s.settings.newsWindows[1].enabled     = false;
   s.settings.newsWindows[1].startHour   = 14;
   s.settings.newsWindows[1].startMinute = 55;
   s.settings.newsWindows[1].endHour     = 15;
   s.settings.newsWindows[1].endMinute   = 10;
   s.settings.newsWindows[1].action      = NEWS_ACTION_BLOCK_ENTRIES;
   s.settings.newsWindows[2].enabled     = true;
   s.settings.newsWindows[2].startHour   = 21;
   s.settings.newsWindows[2].startMinute = 5;
   s.settings.newsWindows[2].endHour     = 21;
   s.settings.newsWindows[2].endMinute   = 20;
   s.settings.newsWindows[2].action      = NEWS_ACTION_CLOSE_AND_BLOCK;
   s.settings.enableDailyLimits     = true;
   s.settings.maxDailyTrades        = 12;
   s.settings.maxDailyLoss          = 250.00;
   s.settings.maxDailyGain          = 500.00;
   s.settings.profitTargetAction    = PROFIT_ACTION_ATIVAR_DD;
   s.settings.maxDrawdown           = 30.00;
   s.settings.drawdownType          = DD_TIPO_PERCENTUAL;
   s.settings.drawdownPeakMode      = DD_PICO_REALIZADO;
   //--- lossStreakEnabled e winStreakEnabled ja foram definidos acima, em
   //--- estados opostos: mostram de uma vez o lado editavel e o apagado. A acao
   //--- de perda vai para Parar dia, que APAGA a Pausa min daquele lado.
   s.settings.maxLossStreak         = 4;
   s.settings.lossStreakAction      = STREAK_ACTION_STOP_DAY;
   s.settings.lossStreakPauseMinutes= 45;
   s.settings.maxWinStreak          = 6;
   s.settings.winStreakAction       = STREAK_ACTION_PAUSE;
   s.settings.winStreakPauseMinutes = 20;

   //--- O snapshot repete as tres chaves fora de settings; divergir aqui
   //--- mascararia justamente o erro que esses campos existem para revelar.
   s.useMACross  = s.settings.useMACross;
   s.useRSI      = s.settings.useRSI;
   s.useBollinger= s.settings.useBollinger;
   s.conflictMode= s.settings.conflictMode;

   //--- Derivados, calculados a partir das chaves acima e nao escritos a mao.
   s.timeframe        = FakeTimeframesSummary(s.settings);
   s.activeStrategies = (s.settings.useMACross ? 1 : 0) +
                        (s.settings.useRSI ? 1 : 0) +
                        (s.settings.useBollinger ? 1 : 0);
   s.activeFilters    = (s.settings.useTrendFilter ? 1 : 0) +
                        (s.settings.useRSIFilter ? 1 : 0) +
                        (s.settings.bbFilterEnabled ? 1 : 0);
   return s;
  }

//--- Mesma leitura que CFusionCanvasPanel::RefreshProfiles faz no EA. Duplicada
//--- aqui de proposito: o harness dirige o RENDERIZADOR direto, sem passar pelo
//--- painel, e e essa diferenca que faz dele um teste do renderizador e nao do
//--- painel. Sao dez linhas; compartilha-las exigiria um cabecalho que
//--- arrastaria Persistence para dentro de UI/Canvas.
void LoadRealProfiles(void)
  {
   CSettingsStore store;
   string names[];
   if(!store.ListProfiles(names)) return;

   int total=ArraySize(names);
   string keep[]; int magics[]; double lots[];
   ArrayResize(keep,total);
   ArrayResize(magics,total);
   ArrayResize(lots,total);
   int n=0;
   for(int i=0;i<total;++i)
     {
      SEASettings s;
      if(!store.LoadProfile(names[i],s)) continue;
      keep[n]=names[i]; magics[n]=s.magicNumber; lots[n]=s.fixedLot; n++;
     }
   g_panel.SetProfiles(keep,magics,lots,n,names);
   PrintFormat("Perfis lidos do disco: %d de %d arquivos.",n,total);
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
   //--- Perfis sao o unico dado do painel que este harness NAO inventa: a lista
   //--- vem do disco de verdade, pelo mesmo caminho que o painel usa no EA.
   //--- Ler perfil e inofensivo — nao opera, nao grava, nao carrega nada — e em
   //--- troca o protótipo mostra os perfis reais do terminal, com os Magic
   //--- reais, que e o que revela conflito de Magic e nome estranho em disco.
   //--- Inventar nomes aqui testaria o desenho e escondia justamente isso.
   LoadRealProfiles();
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
   //--- Mesmo tratamento que CFusionCanvasPanel da ao botao ATUALIZAR: o
   //--- renderizador so registra o pedido, quem le o disco e quem o conduz.
   if(g_panel.ConsumeProfileRefreshRequest()) LoadRealProfiles();
   g_panel.Pulse();
  }
