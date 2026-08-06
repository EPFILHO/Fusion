//+------------------------------------------------------------------+
//| EAEntryPoints.mqh                                                 |
//| Os pontos de entrada do terminal, num lugar so.                   |
//|                                                                   |
//| Existe por causa da FASE 3: a partir dela o projeto produz DOIS   |
//| executaveis do mesmo EA — Fusion.ex5 com o painel antigo e        |
//| FusionCanvas.ex5 com o painel em canvas —, e a unica diferenca    |
//| entre eles e uma linha de #define. Copiar estes seis handlers no  |
//| segundo .mq5 criaria duas listas para manter em sincronia, e o    |
//| modo de falha seria silencioso: um handler novo acrescentado a um |
//| e esquecido no outro compila 0/0 e simplesmente nao roda.         |
//|                                                                   |
//| Com o corpo aqui, cada .mq5 fica com o que de fato lhe pertence — |
//| suas #property, seus #resource e a escolha do painel — e nada     |
//| mais.                                                             |
//+------------------------------------------------------------------+
#ifndef __FUSION_EA_ENTRY_POINTS_MQH__
#define __FUSION_EA_ENTRY_POINTS_MQH__

#include "EAApplication.mqh"

CFusionApplication *g_app = NULL;

int OnInit()
  {
   g_app = new CFusionApplication();
   if(g_app == NULL)
      return INIT_FAILED;

   if(!g_app.Initialize())
     {
      delete g_app;
      g_app = NULL;
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(g_app == NULL)
      return;

   g_app.Shutdown(reason);
   delete g_app;
   g_app = NULL;
  }

void OnTick()
  {
   if(g_app != NULL)
      g_app.OnTick();
  }

void OnTimer()
  {
   if(g_app != NULL)
      g_app.OnTimer();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(g_app != NULL)
      g_app.OnChartEvent(id, lparam, dparam, sparam);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(g_app != NULL)
      g_app.OnTradeTransaction(trans, request, result);
  }

#endif
