//+------------------------------------------------------------------+
//|                                   VolatilityGateFormulaTest.mq5   |
//|                                                                   |
//| DEV-010B.2 -- harness puro sobre OHLC conhecido, sem MT5/tester,  |
//| sem grafico anexado nem ordens: chama exclusivamente a funcao PURA|
//| FusionResearchVolGateComputeAtrNormalized (Filters/Implementations|
//| /VolatilityGateFilter.mqh), a mesma usada pelo filtro real -- zero|
//| logica de calculo duplicada.                                      |
//|                                                                   |
//| Uso: anexar como Script a qualquer grafico/simbolo no editor MT5  |
//| (Compilar; Executar). Imprime PASS/FAIL por caso no Journal e     |
//| encerra com Alert se algum caso falhar.                           |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#define FUSION_RESEARCH_VOLATILITY_GATE
#include "../../Filters/Implementations/VolatilityGateFilter.mqh"

int g_failures = 0;

void Check(const string label,const bool condition)
  {
   if(condition)
     {
      Print("PASS " + label);
      return;
     }
   g_failures++;
   Print("FAIL " + label);
  }

void CheckClose(const string label,const double actual,const double expected,const double tolerance)
  {
   Check(label + StringFormat(" (actual=%.10f expected=%.10f)", actual, expected),
         MathAbs(actual - expected) <= tolerance);
  }

//--- Caso 1: 15 barras conhecidas com TR constante = 2 e close mais recente
//--- = 100 -> atr_normalized = (2*14/14)/100 = 0.02 exato.
void TestKnownAtrNormalized(void)
  {
   double highs[], lows[], closes[];
   ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED; i++)
     {
      closes[i] = 100.0 - (double)i;
      highs[i]  = closes[i] + 1.0;
      lows[i]   = closes[i] - 1.0;
     }

   double atrNormalized = -1.0;
   bool ok = FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
   Check("caso 1: calculo bem-sucedido com 15 barras validas", ok);
   if(ok)
      CheckClose("caso 1: atr_normalized == 0.02", atrNormalized, 0.02, 1e-9);
  }

//--- Caso 2: menos de 15 barras (14) -> falha fechada.
void TestInsufficientBars(void)
  {
   double highs[], lows[], closes[];
   ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED - 1);
   ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED - 1);
   ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED - 1);
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED - 1; i++)
     {
      closes[i] = 100.0 - (double)i;
      highs[i]  = closes[i] + 1.0;
      lows[i]   = closes[i] - 1.0;
     }

   double atrNormalized = -1.0;
   bool ok = FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
   Check("caso 2: 14 barras (faltando 1) falha fechada", !ok);
  }

//--- Caso 3: barra com low > high (dado invalido) -> falha fechada.
void TestInvalidBar(void)
  {
   double highs[], lows[], closes[];
   ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED; i++)
     {
      closes[i] = 100.0 - (double)i;
      highs[i]  = closes[i] + 1.0;
      lows[i]   = closes[i] - 1.0;
     }
   //--- Barra 3 (dentro da janela dos 14 TR) com low > high.
   highs[3] = 90.0;
   lows[3]  = 95.0;

   double atrNormalized = -1.0;
   bool ok = FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
   Check("caso 3: low > high em uma barra falha fechada", !ok);
  }

//--- Caso 4: close final <= 0 (dado invalido) -> falha fechada.
void TestNonPositiveClose(void)
  {
   double highs[], lows[], closes[];
   ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED; i++)
     {
      closes[i] = 100.0 - (double)i;
      highs[i]  = closes[i] + 1.0;
      lows[i]   = closes[i] - 1.0;
     }
   closes[0] = 0.0;

   double atrNormalized = -1.0;
   bool ok = FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
   Check("caso 4: close final <= 0 falha fechada", !ok);
  }

//--- Caso 5: indice 0 representa a barra shift=1 entregue pelo chamador. Usa
//--- serie plana a 200 para manter TR=2 sem introduzir gap artificial.
void TestShiftOneUsesLastCompletedBar(void)
  {
   double highs[], lows[], closes[];
   ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED; i++)
     {
      closes[i] = 200.0;
      highs[i]  = 201.0;
      lows[i]   = 199.0;
     }

   double atrNormalized = -1.0;
   bool ok = FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
   Check("caso 5: shift=1 recalcula com 15 barras validas", ok);
   if(ok)
      CheckClose("caso 5: atr_normalized == 2/200 = 0.01", atrNormalized, 0.01, 1e-9);
  }

void TestStrictThreshold(void)
  {
   Check("caso 6: igualdade nao bloqueia", !FusionResearchVolGateIsHigh(0.02, 0.02));
   Check("caso 6: acima bloqueia", FusionResearchVolGateIsHigh(0.0200001, 0.02));
   Check("caso 6: abaixo nao bloqueia", !FusionResearchVolGateIsHigh(0.0199999, 0.02));
  }

void OnStart()
  {
   g_failures = 0;
   TestKnownAtrNormalized();
   TestInsufficientBars();
   TestInvalidBar();
   TestNonPositiveClose();
   TestShiftOneUsesLastCompletedBar();
   TestStrictThreshold();

   if(g_failures == 0)
      Print("VolatilityGateFormulaTest: TODOS OS CASOS PASSARAM");
   else
     {
      string message = StringFormat("VolatilityGateFormulaTest: %d caso(s) FALHARAM", g_failures);
      Print(message);
      Alert(message);
     }
  }
