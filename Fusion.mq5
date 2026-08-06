//+------------------------------------------------------------------+
//|                                                        Fusion.mq5 |
//|                          Clean modular multi-strategy EA scaffold |
//|                                                                   |
//| Painel ANTIGO (CFusionPanel, biblioteca Controls). E o padrao: na |
//| ausencia de FUSION_USE_CANVAS_PANEL o EA constroi este.           |
//| O painel em canvas sai no FusionCanvas.mq5, ao lado deste.        |
//+------------------------------------------------------------------+
#include "Core/Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property strict

#resource "VisualIndicators\\FusionVisualMA.ex5"
#resource "VisualIndicators\\FusionVisualBands.ex5"
#resource "VisualIndicators\\FusionVisualRSI.ex5"

#include "Core/EAEntryPoints.mqh"
