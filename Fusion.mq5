//+------------------------------------------------------------------+
//|                                                        Fusion.mq5 |
//|                          Clean modular multi-strategy EA scaffold |
//+------------------------------------------------------------------+
#property copyright "OpenAI / Codex"
#property version   "1.009"
#property strict

#include "Core/EAApplication.mqh"

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
