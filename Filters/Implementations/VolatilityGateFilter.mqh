//+------------------------------------------------------------------+
//| VolatilityGateFilter.mqh                                          |
//|                                                                   |
//| DEV-010B.2 -- portao de alta volatilidade M5 para o alvo isolado  |
//| FusionResearchVolatility. So existe quando FUSION_RESEARCH_       |
//| VOLATILITY_GATE esta definido (ver FusionResearchVolatility.mq5); |
//| compilar Fusion.mq5/FusionDemo.mq5 sem a macro nao ve nada deste  |
//| arquivo -- corpo inteiro sob #ifdef, mesmo precedente de          |
//| Core/RuntimeModePolicy.mqh (FUSION_DEMO_ONLY).                    |
//|                                                                   |
//| Formula EXATA do EP Market Hub, nunca iATR de Wilder:             |
//|  1. timeframe fixo M5;                                            |
//|  2. somente a ultima barra M5 CONCLUIDA (shift=1) e as 14 true    |
//|     ranges encerradas que terminam nela (shifts 1..14, contra os  |
//|     closes anteriores shifts 2..15);                              |
//|  3. TR = max(high-low, abs(high-prev_close), abs(low-prev_close));|
//|  4. ATR = media aritmetica simples das 14 TR;                     |
//|  5. atr_normalized = ATR / close da barra shift=1;                |
//|  6. alta volatilidade somente quando atr_normalized > threshold_t2;|
//|  7. nunca le a barra M5 em formacao (shift=0 jamais entra na conta);|
//|  8. 15 barras indisponiveis ou qualquer valor invalido => falha   |
//|     fechada, bloqueia e conta como falha de integridade.          |
//|                                                                   |
//| Quando bloqueia, devolve false para o CSignalManager, que zera    |
//| decision.signal nesta mesma avaliacao (SignalManager.mqh). O      |
//| estado de cruzamento da MA ja e zerado por FusionMACrossApply no  |
//| MESMO tick em que dispara (Core/Types.mqh), antes de qualquer     |
//| filtro rodar -- ou seja, o unico "estado de sinal" a descartar e  |
//| exatamente esta decisao do tick corrente, e e isso que este       |
//| filtro descarta. Nao ha reentrada atrasada quando o ATR cai       |
//| abaixo do corte: o proximo sinal so nasce de um cruzamento novo.  |
//+------------------------------------------------------------------+
#ifndef __FUSION_VOLATILITY_GATE_FILTER_MQH__
#define __FUSION_VOLATILITY_GATE_FILTER_MQH__

#ifdef FUSION_RESEARCH_VOLATILITY_GATE

#include "../Base/FilterBase.mqh"

//--- Versao/formula congelada nesta entrega -- exportada na instrumentacao
//--- para o analisador Python distinguir builds do filtro no futuro.
#define FUSION_RESEARCH_VOLGATE_VERSION "dev-010b2-atr-simple-14-close-shift1-v1"
#define FUSION_RESEARCH_VOLGATE_BARS_NEEDED 15
#define FUSION_RESEARCH_VOLGATE_TR_COUNT 14

input group "========== RESEARCH (DEV-010B.2) - PORTAO DE VOLATILIDADE =========="
input bool   inp_ResearchVolGateEnabled      = false; // Ativar portao de volatilidade (so no alvo de pesquisa)
input double inp_ResearchVolGateThreshold    = 0.0;   // threshold_t2 congelado (atr_normalized), vem do .set do job
input string inp_ResearchVolGateLogRelative  = "";    // Caminho relativo (MQL5\Files) do log de instrumentacao; vazio = nao grava

//--- Funcao PURA (sem CopyRates/MT5), unica dona da formula. O filtro e o
//--- harness de teste (Research/Tests/VolatilityGateFormulaTest.mq5) chamam
//--- SO esta funcao -- nenhuma logica de calculo duplicada entre os dois.
//---
//--- `highs`/`lows`/`closes` devem vir em ordem "series" (indice 0 = ultima
//--- barra M5 CONCLUIDA, indice 14 = a mais antiga das 15 necessarias); os
//--- 14 TR usam `closes[i+1]` como fechamento anterior, nunca `closes[0]`.
bool FusionResearchVolGateComputeAtrNormalized(const double &highs[],
                                                const double &lows[],
                                                const double &closes[],
                                                double &atrNormalized)
  {
   atrNormalized = 0.0;
   if(ArraySize(highs) < FUSION_RESEARCH_VOLGATE_BARS_NEEDED ||
      ArraySize(lows) < FUSION_RESEARCH_VOLGATE_BARS_NEEDED ||
      ArraySize(closes) < FUSION_RESEARCH_VOLGATE_BARS_NEEDED)
      return false;

   double trSum = 0.0;
   for(int i = 0; i < FUSION_RESEARCH_VOLGATE_TR_COUNT; i++)
     {
      double high      = highs[i];
      double low       = lows[i];
      double close     = closes[i];
      double prevClose = closes[i + 1];
      if(!MathIsValidNumber(high) || !MathIsValidNumber(low) ||
         !MathIsValidNumber(close) || !MathIsValidNumber(prevClose) ||
         high <= 0.0 || low <= 0.0 || close <= 0.0 || prevClose <= 0.0 ||
         high < low || close > high || close < low)
         return false;
      double tr = MathMax(high - low, MathMax(MathAbs(high - prevClose), MathAbs(low - prevClose)));
      trSum += tr;
     }

   double lastClose = closes[0];
   if(lastClose <= 0.0)
      return false;

   double atr = trSum / (double)FUSION_RESEARCH_VOLGATE_TR_COUNT;
   double result = atr / lastClose;
   if(!MathIsValidNumber(result))
      return false;

   atrNormalized = result;
   return true;
  }

bool FusionResearchVolGateIsHigh(const double atrNormalized,const double threshold)
  {
   return (MathIsValidNumber(atrNormalized) && MathIsValidNumber(threshold) &&
           atrNormalized > threshold);
  }

class CVolatilityGateFilter : public CFilterBase
  {
private:
   double   m_threshold;
   string   m_logRelative;
   long     m_decisionsEvaluated;
   long     m_blockedHighVolatility;
   long     m_closedFailures;
   datetime m_firstBlockTime;
   datetime m_lastBlockTime;
   bool     m_instrumentationWritten;

   //--- Le as 15 barras M5 mais recentes JA CONCLUIDAS (shift 1..15) e reduz a
   //--- atr_normalized. Falha fechada em qualquer dado ausente/invalido.
   bool              ComputeAtrNormalized(double &atrNormalized)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      //--- start=1 pula deliberadamente a barra em formacao (shift 0); nunca
      //--- a lemos, mesmo que CopyRates a devolvesse.
      int copied = CopyRates(m_symbol, PERIOD_M5, 1, FUSION_RESEARCH_VOLGATE_BARS_NEEDED, rates);
      if(copied < FUSION_RESEARCH_VOLGATE_BARS_NEEDED)
         return false;

      double highs[], lows[], closes[];
      ArrayResize(highs, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
      ArrayResize(lows, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
      ArrayResize(closes, FUSION_RESEARCH_VOLGATE_BARS_NEEDED);
      for(int i = 0; i < FUSION_RESEARCH_VOLGATE_BARS_NEEDED; i++)
        {
         highs[i]  = rates[i].high;
         lows[i]   = rates[i].low;
         closes[i] = rates[i].close;
        }

      //--- Formula PURA e unica (sem CopyRates): ver
      //--- FusionResearchVolGateComputeAtrNormalized acima.
      return FusionResearchVolGateComputeAtrNormalized(highs, lows, closes, atrNormalized);
     }

   void              WriteInstrumentationFile(void) const
     {
      if(m_logRelative == "")
         return;

      //--- FolderCreate nao garante pais intermediarios. Criamos cada nivel
      //--- sob MQL5\Files, sempre a partir do caminho relativo recebido.
      int length = StringLen(m_logRelative);
      for(int i = 0; i < length; i++)
        {
         if(StringGetCharacter(m_logRelative, i) != '\\')
            continue;
         string partial = StringSubstr(m_logRelative, 0, i);
         if(partial != "" && !FolderCreate(partial) && GetLastError() != 0)
            ResetLastError();
        }

      int handle = FileOpen(m_logRelative, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Warn("RESEARCH_VOLGATE", "Falha ao abrir log de instrumentacao: " + m_logRelative);
         return;
        }

      FileWriteString(handle, "schema=fusion-research-volgate-instrumentation-v1\n");
      FileWriteString(handle, "formula_version=" + FUSION_RESEARCH_VOLGATE_VERSION + "\n");
      FileWriteString(handle, "symbol=" + m_symbol + "\n");
      FileWriteString(handle, "timeframe=M5\n");
      FileWriteString(handle, "enabled=" + (m_enabled ? "true" : "false") + "\n");
      FileWriteString(handle, "threshold_t2=" + DoubleToString(m_threshold, 16) + "\n");
      FileWriteString(handle, "decisions_evaluated=" + IntegerToString((int)m_decisionsEvaluated) + "\n");
      FileWriteString(handle, "blocked_high_volatility=" + IntegerToString((int)m_blockedHighVolatility) + "\n");
      FileWriteString(handle, "closed_failures=" + IntegerToString((int)m_closedFailures) + "\n");
      FileWriteString(handle, "first_block_time=" +
                       (m_firstBlockTime > 0 ? TimeToString(m_firstBlockTime, TIME_DATE | TIME_SECONDS) : "") + "\n");
      FileWriteString(handle, "last_block_time=" +
                       (m_lastBlockTime > 0 ? TimeToString(m_lastBlockTime, TIME_DATE | TIME_SECONDS) : "") + "\n");
      FileClose(handle);
     }

public:
                     CVolatilityGateFilter(void) : CFilterBase("research_volatility_gate", "Portao de Volatilidade (Pesquisa)")
     {
      m_threshold              = 0.0;
      m_logRelative            = "";
      m_decisionsEvaluated     = 0;
      m_blockedHighVolatility  = 0;
      m_closedFailures         = 0;
      m_firstBlockTime         = 0;
      m_lastBlockTime          = 0;
      m_instrumentationWritten = false;
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      //--- Le direto dos inputs proprios do alvo de pesquisa, e nao de
      //--- SEASettings: o portao nao precisa de nenhum campo novo na struct
      //--- compartilhada, entao Fusion.mq5/FusionDemo.mq5 nao ganham sequer
      //--- uma linha extra em Types.mqh/Inputs.mqh.
      m_enabled     = inp_ResearchVolGateEnabled;
      m_threshold   = inp_ResearchVolGateThreshold;
      m_logRelative = inp_ResearchVolGateLogRelative;
      if(m_enabled && (!MathIsValidNumber(m_threshold) || m_threshold <= 0.0 || m_logRelative == ""))
         return false;
      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;

      m_decisionsEvaluated++;

      double atrNormalized = 0.0;
      if(!ComputeAtrNormalized(atrNormalized))
        {
         m_closedFailures++;
         reason = "falha fechada: dados M5 insuficientes/invalidos para ATR simples de 14 TR";
         return false;
        }

      if(FusionResearchVolGateIsHigh(atrNormalized, m_threshold))
        {
         m_blockedHighVolatility++;
         datetime nowBar = iTime(m_symbol, PERIOD_M5, 1);
         if(m_firstBlockTime == 0)
            m_firstBlockTime = nowBar;
         m_lastBlockTime = nowBar;
         reason = StringFormat("alta volatilidade: atr_normalized=%.10f > threshold_t2=%.10f",
                                atrNormalized, m_threshold);
         return false;
        }

      return true;
     }

   //--- Instrumentacao minima da DEV-010B.2. Chamado uma unica vez no
   //--- encerramento (Shutdown), nunca por tick/calculo -- ver EAApplication.mqh.
   void              WriteInstrumentation(void)
     {
      if(m_instrumentationWritten)
         return;
      m_instrumentationWritten = true;
      WriteInstrumentationFile();
     }
  };

#endif // FUSION_RESEARCH_VOLATILITY_GATE
#endif // __FUSION_VOLATILITY_GATE_FILTER_MQH__
