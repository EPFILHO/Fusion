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

input ENUM_FUSION_CANVAS_PALETTE inp_Palette = FUSION_PALETTE_PETROLEO;    // Paleta
input ENUM_FUSION_CANVAS_THEME   inp_Theme   = FUSION_CANVAS_THEME_AUTO;  // Tema do painel
input bool inp_RememberAppearance = true; // Lembrar aparencia escolhida no painel
input bool inp_MeasureOnStart     = true; // Medir custo de desenho ao iniciar

CFusionCanvasRenderer g_panel;

//+------------------------------------------------------------------+
int OnInit(void)
  {
   if(!g_panel.Create(0,"FusP1_",inp_Theme,inp_Palette,inp_RememberAppearance,10,20))
     {
      Print("Fase 1: falha ao criar o canvas.");
      return INIT_FAILED;
     }
   Print("Fase 1 da GUI 2.0 ativa (dados falsos). Teclas: M = medir custo, S = tela de estresse.");
   if(inp_MeasureOnStart) g_panel.RunPerfSuite();
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
