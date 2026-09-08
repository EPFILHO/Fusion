//+------------------------------------------------------------------+
//|                                       FusionResearchVolatility.mq5 |
//|                       DEV-010B.2 -- alvo ISOLADO de pesquisa       |
//|                                                                   |
//| MESMO EA do Fusion.mq5, com um filtro adicional: o portao de alta |
//| volatilidade M5 (ATR simples de 14 true ranges / close, shift=1,  |
//| nunca iATR de Wilder -- ver Filters/Implementations/              |
//| VolatilityGateFilter.mqh). Precedente identico ao de FusionDemo   |
//| .mq5/FUSION_DEMO_ONLY: uma unica linha de #define, ANTES do       |
//| include compartilhado, e nenhum handler duplicado.                |
//|                                                                   |
//| Compilar Fusion.mq5 ou FusionDemo.mq5 sem esta macro definida     |
//| continua produzindo o binario operacional inalterado: todo o      |
//| codigo do portao vive atras de `#ifdef                            |
//| FUSION_RESEARCH_VOLATILITY_GATE`, na mesma condicao da porta, e   |
//| nao acima dela.                                                   |
//|                                                                   |
//| So para uso no worktree de pesquisa isolado (branch                |
//| research/dev-010b2-volatility-gate). Nunca compilado, copiado nem |
//| referenciado a partir de Fusion-2.000, da demo nem do perfil      |
//| WIN_copy_2 operacional -- ver docs/work_orders/DEV-010B2.md.      |
//+------------------------------------------------------------------+
#define FUSION_RESEARCH_VOLATILITY_GATE

#include "Core/Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property strict
#property description "Fusion — alvo isolado de pesquisa DEV-010B.2."
#property description "Adiciona um portao de alta volatilidade M5 (ATR simples de 14 TR)."
#property description "Uso exclusivo do worktree de pesquisa; nunca operacional/demo."

#resource "VisualIndicators\\FusionVisualMA.ex5"
#resource "VisualIndicators\\FusionVisualBands.ex5"
#resource "VisualIndicators\\FusionVisualRSI.ex5"

#include "Core/EAEntryPoints.mqh"
