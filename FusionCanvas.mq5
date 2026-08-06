//+------------------------------------------------------------------+
//|                                                  FusionCanvas.mq5 |
//|                                                                   |
//| O MESMO EA do Fusion.mq5, construido com o painel em canvas       |
//| (CFusionCanvasPanel) no lugar do antigo. Nao ha aqui nenhuma      |
//| logica propria: a unica diferenca entre os dois executaveis e a   |
//| linha de #define abaixo.                                          |
//|                                                                   |
//| FASE 3 do plano da GUI 2.0 (docs/GUI_2000_PLANO.md, secao 6).     |
//| A escolha e em tempo de COMPILACAO, e nao um input, porque        |
//| m_panel e um membro concreto de CFusionApplication: escolher em   |
//| tempo de execucao exigiria uma indirecao que nao existe hoje e    |
//| que teria de ser desfeita na Fase 4, quando o painel antigo sair. |
//|                                                                   |
//| Dois .ex5 em vez de um so porque a Fase 3 existe para COMPARAR os |
//| dois paineis. Com um unico alvo a comparacao seria sequencial:    |
//| editar, recompilar, recarregar; com dois, cada um roda no seu     |
//| grafico ao mesmo tempo, lado a lado, e voltar ao antigo e trocar  |
//| o EA do grafico. Nenhum arquivo do EA muda para isso acontecer.   |
//|                                                                   |
//| Enquanto durar a transicao, este e o alvo EXPERIMENTAL: o painel  |
//| e novo e a logica de gravacao/criacao/exclusao dele nunca rodou   |
//| fora do harness. O caminho seguro continua sendo o Fusion.ex5.    |
//+------------------------------------------------------------------+
#include "Core/Version.mqh"

#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   FUSION_APP_VERSION
#property strict
#property description "EP Fusion com a GUI 2.0 em canvas (Fase 3, em avaliacao)."
#property description "Mesmo motor do Fusion.ex5; muda apenas o painel."

#resource "VisualIndicators\\FusionVisualMA.ex5"
#resource "VisualIndicators\\FusionVisualBands.ex5"
#resource "VisualIndicators\\FusionVisualRSI.ex5"

//--- O interruptor. Lido em Core/EAApplication.mqh, onde decide a classe do
//--- membro m_panel; ausente, vale o painel antigo.
#define FUSION_USE_CANVAS_PANEL

#include "Core/EAEntryPoints.mqh"
