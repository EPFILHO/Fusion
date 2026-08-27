//+------------------------------------------------------------------+
//|                                                        Fusion.mq5 |
//|                          Clean modular multi-strategy EA scaffold |
//|                                                                   |
//| A versao COMPLETA do EA, com a GUI 2.0 em canvas dentro.          |
//|                                                                   |
//| Durante a Fase 3 houve um segundo alvo, FusionCanvas.mq5: o mesmo |
//| EA compilado com o painel novo, para os dois rodarem lado a lado  |
//| em graficos diferentes. A Fase 4 removeu o painel classico, e com |
//| ele o segundo alvo e o #define que os separava.                   |
//|                                                                   |
//| O segundo alvo voltou, por outro motivo: FusionDemo.mq5 e o MESMO |
//| EA compilado com FUSION_DEMO_ONLY, e so roda em conta demo e no   |
//| Strategy Tester. Esta compilacao NAO define o simbolo, entao a    |
//| porta de Core/RuntimeModePolicy.mqh nem chega a existir aqui:     |
//| demo, contest, real e Tester, como sempre foi.                    |
//+------------------------------------------------------------------+
#include "Core/Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property strict
#property description "EP Fusion 2.000 — versao completa."
#property description "Roda em conta demo, de contest, real e no Strategy Tester."
#property description "A versao de demonstracao (FusionDemo.ex5) nao opera em conta real."

#resource "VisualIndicators\\FusionVisualMA.ex5"
#resource "VisualIndicators\\FusionVisualBands.ex5"
#resource "VisualIndicators\\FusionVisualRSI.ex5"

#include "Core/EAEntryPoints.mqh"
