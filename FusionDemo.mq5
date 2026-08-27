//+------------------------------------------------------------------+
//|                                                    FusionDemo.mq5 |
//|                      EP Fusion 2.000 DEMO — versao de demonstracao |
//|                                                                   |
//| MESMO EA do Fusion.mq5. A unica diferenca entre os dois binarios  |
//| e a linha de #define abaixo: nenhum handler, nenhuma regra e      |
//| nenhum arquivo operacional sao duplicados aqui.                   |
//|                                                                   |
//| Ha precedente direto: na Fase 3 o projeto ja produziu dois        |
//| executaveis do mesmo EA por um #define, e foi por isso que os     |
//| seis pontos de entrada foram para Core/EAEntryPoints.mqh. Copiar  |
//| OnInit/OnTick/OnTimer/OnDeinit para ca criaria duas listas para   |
//| manter em sincronia, e o modo de falha seria silencioso.          |
//|                                                                   |
//| ⚠ O #define vem ANTES do include compartilhado, e e o que faz a   |
//| porta de RuntimeModePolicy.mqh existir nesta compilacao. Nao ha   |
//| input para isso: uma restricao que o operador pudesse desligar    |
//| nao seria uma modalidade de binario.                              |
//|                                                                   |
//| Permitido em conta DEMO e no Strategy Tester. Recusa contest e    |
//| real na partida, antes de tocar em qualquer coisa.                |
//+------------------------------------------------------------------+
#define FUSION_DEMO_ONLY

#include "Core/Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property strict
#property description "EP Fusion 2.000 DEMO — versao de demonstracao."
#property description "Funciona somente em conta DEMO e no Strategy Tester."
#property description "Em conta real ou de contest, recusa a partida e nao opera."
#property description "A versao completa (Fusion.ex5) roda tambem em conta real."

#resource "VisualIndicators\\FusionVisualMA.ex5"
#resource "VisualIndicators\\FusionVisualBands.ex5"
#resource "VisualIndicators\\FusionVisualRSI.ex5"

#include "Core/EAEntryPoints.mqh"
