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
//--- Perfil ATIVO simulado. Vazio = o primeiro legivel do disco.
//---
//--- Existe porque o harness nao tem a memoria que o EA tem: o EA guarda o
//--- perfil ativo no estado do grafico e o restaura ao reabrir, enquanto aqui a
//--- escolha e refeita a cada anexo. Com ela automatica, mover o arquivo do
//--- perfil ativo para fora fazia o harness simplesmente ADOTAR OUTRO na
//--- reabertura — parecia o EA trocando de perfil sozinho, e nao era.
//---
//--- Informando o nome, o perfil ativo fica fixo mesmo que o arquivo suma, que
//--- e o unico jeito de exercitar por aqui o estado "perfil ativo sem arquivo".
input string inp_ActiveProfile    = "";   // Perfil ativo simulado (vazio = 1o do disco)

CFusionCanvasRenderer g_panel;
//--- Snapshot vivo do harness. Guardado porque a Etapa 2c tirou dos botoes o
//--- poder de mexer no estado da tela: INICIAR agora EMITE uma intencao, e quem
//--- decide se o EA passou a rodar e quem a consome. Aqui, este arquivo.
SUIPanelSnapshot      g_snap;

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

//+------------------------------------------------------------------+
//| Primeiro perfil legivel do disco.                                 |
//|                                                                   |
//| ⚠ O harness inventa TUDO menos a lista de perfis, que vem do disco|
//| de verdade — e essa mistura tem uma regra: o que e inventado nao  |
//| pode CONTRADIZER o que e real.                                    |
//|                                                                   |
//| Ela foi quebrada e custou uma rodada de teste. O perfil ativo era |
//| um "BTCUSD" fixo, com o Magic padrao 10001, e o disco da maquina  |
//| tinha um perfil `default` com esse mesmo 10001. Resultado: a      |
//| validacao acusava — corretamente — que gravar BTCUSD com 10001    |
//| colidiria com o default; a aba Perfis acendia, o SALVAR apagava,  |
//| e apagar perfis duplicados nao resolvia nada, porque o dono do    |
//| numero era o default. Parecia defeito do painel e era do dado.    |
//|                                                                   |
//| Usar o primeiro perfil REAL como ativo resolve na origem: nome e  |
//| Magic passam a existir em disco, o campo Magic fica editavel      |
//| (so o perfil ativo tem), e a deteccao de duplicado passa a ser    |
//| exercitada com duplicado de verdade.                              |
//+------------------------------------------------------------------+
bool FirstRealProfile(string &name,int &magic)
  {
   name=""; magic=0;
   CSettingsStore store;

   //--- O `default` tem precedencia, e nao por comodidade: ele e a base do EA —
   //--- o `defaultProfileName` de SEASettings, o perfil que nem se deixa
   //--- excluir. "O primeiro da pasta" e uma ordem alfabetica sem significado
   //--- nenhum, e escolher por ela fazia o perfil ativo do harness mudar
   //--- sozinho conforme o que existisse em disco.
   SEASettings def;
   SEASettings padrao;
   SetDefaultSettings(padrao);
   if(store.LoadProfile(padrao.defaultProfileName,def))
     {
      name=padrao.defaultProfileName;
      magic=def.magicNumber;
      return true;
     }

   //--- Sem o default, o primeiro legivel — melhor que nenhum, e a tela avisa
   //--- qual foi adotado no log.
   string names[];
   if(!store.ListProfiles(names)) return false;
   for(int i=0;i<ArraySize(names);++i)
     {
      SEASettings s;
      if(!store.LoadProfile(names[i],s)) continue;
      name=names[i];
      magic=s.magicNumber;
      return true;
     }
   return false;
  }

SUIPanelSnapshot BuildFakeSnapshot(void)
  {
   SUIPanelSnapshot s;
   //--- Base conhecida antes de qualquer substituicao: assim os campos que este
   //--- harness ainda nao exercita valem o padrao do EA, e nao o que estiver na
   //--- memoria. Um valor absurdo vindo dai pareceria defeito do painel.
   SetDefaultSettings(s.settings);
   s.symbol            = _Symbol;
   //--- Especificacao do ativo, lida do simbolo REAL do grafico.
   //---
   //--- Deixada em branco ate a Etapa 2c, ela nao fazia falta: nada a lia. A
   //--- validacao da 2d le — o Lote Fixo e conferido contra minimo, maximo e
   //--- passo, e o plano de volumes do TP Parcial e simulado com eles. Sem
   //--- valores, a tela de TP Parcial acusa "especificacao indisponivel" para
   //--- sempre, e o harness nasce invalido: INICIAR e SALVAR apagados, sem
   //--- causa visivel. Ler do simbolo e melhor que inventar numeros — assim o
   //--- harness exercita as MESMAS faixas que o EA vai enfrentar.
   s.symbolSpec.symbol     = _Symbol;
   s.symbolSpec.digits     = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   s.symbolSpec.point      = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   s.symbolSpec.tickSize   = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   s.symbolSpec.tickValue  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   s.symbolSpec.volumeMin  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   s.symbolSpec.volumeMax  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   s.symbolSpec.volumeStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   s.symbolSpec.stopsLevel = (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   s.symbolSpec.freezeLevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   s.symbolSpec.fillingMode= SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   //--- timeframe, activeStrategies e activeFilters sao DERIVADOS de settings e
   //--- por isso ficam no fim desta funcao, depois das chaves que os alimentam.
   //--- Escritos a mao aqui em cima, contradiziam os proprios settings do
   //--- harness — o resumo dizia "MA M1/M5 | RSI M15" enquanto as medias
   //--- estavam em M15/H1 e o RSI em M30, e a contagem dizia 1 estrategia com
   //--- duas ligadas. Quem testava concluia, com razao, que a tela e que estava
   //--- errada.
   //--- Perfil ativo e Magic vindos do DISCO, e nao inventados: ver
   //--- FirstRealProfile. Sem nenhum perfil legivel, o nome fixo volta — e ai
   //--- nao ha lista com que contradizer.
   //---
   //--- O input tem prioridade e pode nomear um perfil que NAO existe: e assim
   //--- que se exercita aqui o estado "perfil ativo sem arquivo". Nesse caso o
   //--- Magic fica o padrao, e a colisao que isso possa causar tem saida — o
   //--- cartao PERFIL ATIVO aceita edicao justamente para isso.
   string activeName=FusionTrimCopy(inp_ActiveProfile); int activeMagic=0;
   if(StringLen(activeName)>0)
     {
      CSettingsStore store;
      SEASettings chosen;
      if(store.LoadProfile(activeName,chosen)) activeMagic=chosen.magicNumber;
      else                                     activeMagic=s.settings.magicNumber;
     }
   else if(!FirstRealProfile(activeName,activeMagic))
     { activeName="BTCUSD"; activeMagic=10001; }
   s.activeProfileName = activeName;
   //--- O Magic tambem entra em settings, que e de onde o RASCUNHO nasce. Era
   //--- justamente essa metade que ficava com o 10001 do SetDefaultSettings e
   //--- colidia com o perfil default do disco.
   s.settings.magicNumber = activeMagic;
   s.activeProfileFileMissing = false;
   s.started           = false;
   s.hasPosition       = false;
   s.runtimeBlocked    = false;
   s.magicNumber       = activeMagic;
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
   //--- ⚠ Os dois niveis obedecem a ORDEM que o modo exige — Extremos pede
   //--- compra < venda. Ate a Etapa 2c eles eram 45/40, que violam a regra;
   //--- enquanto nada validava, a inversao era invisivel. Com a 2d ligada, o
   //--- harness nasceria com erro permanente em Filtros > RSI e com INICIAR e
   //--- SALVAR apagados — parecendo defeito do painel, e nao do dado falso.
   s.settings.rsiFilterBuyMin     = 30;
   s.settings.rsiFilterSellMax    = 70;

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
   //--- Lote DERIVADO da especificacao, e nao um 0.30 escrito a mao. Dois
   //--- motivos, os dois descobertos ao ligar a validacao:
   //---   0.30 nao existe num ativo cujo passo e 1 (indices), e o campo nascia
   //---   vermelho no harness;
   //---   e o plano do TP Parcial precisa caber — 40% + 35% tem de dar dois
   //---   lotes validos e ainda deixar o minimo aberto, o que exige uma entrada
   //---   com varios minimos dentro.
   double baseLot = s.symbolSpec.volumeMin * 10.0;
   if(s.symbolSpec.volumeMax > 0.0 && baseLot > s.symbolSpec.volumeMax)
      baseLot = s.symbolSpec.volumeMax;
   if(s.symbolSpec.volumeStep > 0.0)
      baseLot = MathRound(baseLot / s.symbolSpec.volumeStep) * s.symbolSpec.volumeStep;
   if(baseLot <= 0.0) baseLot = 0.30;      // simbolo sem especificacao publicada
   s.settings.fixedLot              = NormalizeDouble(baseLot,8);
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

   //--- O arquivo do perfil ATIVO ainda esta la?
   //---
   //--- No EA quem responde isso e o proprio EA, e a resposta vai no snapshot.
   //--- O harness deixava `activeProfileFileMissing` fixo em false, e isso o fazia
   //--- mentir assim que alguem movia o arquivo para exercitar o painel: a tela
   //--- perdia o perfil da lista, mostrava o cartao de ativo-fora-da-lista e ao
   //--- mesmo tempo afirmava, no cabecalho, que o arquivo estava no lugar.
   //---
   //--- E o campo NAO e cosmetico: e ele que acende o SALVAR sem pendencia, que e
   //--- justamente a acao que recria o arquivo perdido.
   SEASettings active;
   g_snap.activeProfileFileMissing =
      (StringLen(g_snap.activeProfileName)>0 &&
       !store.LoadProfile(g_snap.activeProfileName,active));
   g_panel.SetSnapshot(g_snap);

   PrintFormat("Perfis lidos do disco: %d de %d arquivos. Ativo (simulado): %s%s",
               n,total,g_snap.activeProfileName,
               g_snap.activeProfileFileMissing ? " — ARQUIVO AUSENTE" : "");
  }

//+------------------------------------------------------------------+
//| Intencoes emitidas pelos botoes (Etapa 2c).                       |
//|                                                                   |
//| O harness NAO executa nenhuma: gravar ou apagar perfil sairia do  |
//| que ele e — um exercitador de tela que nao opera e nao escreve.   |
//| Ele responde por escrito, na mesma caixa de aviso que o painel de |
//| verdade usa, e assim o caminho inteiro (clique -> intencao ->     |
//| resposta -> aviso) fica testavel sem o EA.                        |
//|                                                                   |
//| Duas excecoes, ambas SO DE LEITURA: INICIAR alterna o estado do   |
//| snapshot falso, para os estados operacionais continuarem          |
//| exercitaveis; e DUPLICAR le o perfil do disco, que e o que semeia |
//| o formulario e sem o que a tela de duplicacao nao existe.         |
//+------------------------------------------------------------------+
void DrainIntents(void)
  {
   SCanvasIntent intent;
   while(g_panel.ConsumeIntent(intent))
     {
      switch(intent.kind)
        {
         case FCV_INTENT_TOGGLE_RUN:
            g_snap.started=!g_snap.started;
            g_panel.SetSnapshot(g_snap);
            g_panel.SetNotice(g_snap.started ? "EA INICIADO (SIMULACAO)" : "EA PAUSADO (SIMULACAO)",
                              "O harness nao opera: so alternou o estado do snapshot falso.",
                              FCV_SEM_WARN);
            break;

         case FCV_INTENT_SAVE_ACTIVE:
            g_panel.SetNotice("GRAVACAO NAO EXECUTADA",
                              "O harness nao escreve em disco. No EA, isto gravaria o perfil "+
                              intent.profile+".",FCV_SEM_WARN);
            break;

         case FCV_INTENT_CREATE_PROFILE:
            g_panel.SetNotice("CRIACAO NAO EXECUTADA",
                              "O harness nao escreve em disco. No EA, isto criaria o perfil "+
                              intent.profile+" com Magic "+IntegerToString(intent.magic)+".",
                              FCV_SEM_WARN);
            break;

         case FCV_INTENT_LOAD_PROFILE:
            g_panel.SetNotice("CARGA NAO EXECUTADA",
                              "O harness nao troca de perfil. No EA, isto carregaria "+
                              intent.profile+".",FCV_SEM_WARN);
            break;

         //--- Inalcancavel por aqui — quem arma o estado de criacao falhada e o
         //--- painel, e o harness nao o usa. Tratada mesmo assim: intencao sem
         //--- caso e intencao descartada em silencio, e o dia em que o harness
         //--- ganhar esse caminho nao pode ser descoberto por um botao inerte.
         case FCV_INTENT_RESTORE_ACTIVE:
            g_panel.SetNotice("RESTAURACAO NAO EXECUTADA",
                              "O harness nao recarrega perfil. No EA, isto devolveria "+
                              intent.profile+" ao que esta em disco.",FCV_SEM_WARN);
            break;

         case FCV_INTENT_DELETE_PROFILE:
            g_panel.SetNotice("EXCLUSAO NAO EXECUTADA",
                              "O harness nao apaga arquivo. No EA, isto excluiria o perfil "+
                              intent.profile+".",FCV_SEM_WARN);
            break;

         case FCV_INTENT_DUPLICATE:
           {
            CSettingsStore store;
            SEASettings source;
            if(store.LoadProfile(intent.profile,source))
               g_panel.BeginDuplicate(source,intent.profile+"_copy",intent.profile);
            else
               g_panel.SetNotice("NAO FOI POSSIVEL DUPLICAR",
                                 "O arquivo de "+intent.profile+" nao pode ser lido.",
                                 FCV_SEM_BAD);
            break;
           }
        }
     }
  }

//+------------------------------------------------------------------+
int OnInit(void)
  {
   g_snap=BuildFakeSnapshot();
   g_panel.SetSnapshot(g_snap);
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
   //--- Mesmo ponto em que o EA drena: e no evento de grafico que o clique
   //--- acontece, e responder no temporizador atrasaria o aviso ate 200 ms.
   DrainIntents();
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
