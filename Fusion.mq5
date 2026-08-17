//+------------------------------------------------------------------+
//|                                                        Fusion.mq5 |
//|                          Clean modular multi-strategy EA scaffold |
//|                                                                   |
//| O unico EA do projeto, com a GUI 2.0 em canvas dentro.            |
//|                                                                   |
//| Durante a Fase 3 houve um segundo alvo, FusionCanvas.mq5: o mesmo |
//| EA compilado com o painel novo, para os dois rodarem lado a lado  |
//| em graficos diferentes. A Fase 4 removeu o painel classico, e com |
//| ele o segundo alvo e o #define que os separava.                   |
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
