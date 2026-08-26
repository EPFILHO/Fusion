//+------------------------------------------------------------------+
//| PartialVolumePlan.mqh                                             |
//| FONTE UNICA do plano de volumes do TP Parcial.                    |
//|                                                                    |
//| Ate aqui a regra existia DUAS vezes: `VPartialVolumePlan` decidia  |
//| se a tela aceitava, e `RiskManager::BuildPlan` decidia se a ordem  |
//| saia. Duas escritas do mesmo criterio divergem, e o sintoma seria  |
//| o pior possivel - a tela aprovando uma configuracao que a entrada  |
//| recusa depois, ou o contrario, com dinheiro na mesa.               |
//|                                                                    |
//| Funcoes livres, sem estado e sem acesso ao MT5: tudo entra por     |
//| parametro. E o que torna a regra exercitavel por sonda, fora do EA.|
//|                                                                    |
//| ⚠ Nao envia ordem, nao le posicao e nao decide QUANDO fechar. So   |
//| responde "que volumes este plano reserva, e ele fecha?".           |
//+------------------------------------------------------------------+
#ifndef __FUSION_PARTIAL_VOLUME_PLAN_MQH__
#define __FUSION_PARTIAL_VOLUME_PLAN_MQH__

#include "VolumeFormat.mqh"

//--- Tolerancia de ponto flutuante. Mesma ordem de grandeza ja usada em
//--- FusionIsVolumeAligned e nas comparacoes de volume do RiskManager.
#define FUSION_PARTIAL_VOLUME_EPS 0.0000001

//--- Motivos de recusa. Cada um e um diagnostico diferente para quem le a
//--- tela: "aumente o volume" e "corrija a quantidade" nao sao a mesma frase.
#define FUSION_PARTIAL_PLAN_OK              0
#define FUSION_PARTIAL_PLAN_DISABLED        1  // TP1 desligado: nao ha plano a fazer
#define FUSION_PARTIAL_PLAN_SPEC_UNKNOWN    2  // ativo nao informou min/step/max
#define FUSION_PARTIAL_PLAN_ENTRY_INVALID   3  // volume de entrada fora da spec
#define FUSION_PARTIAL_PLAN_MODE_INVALID    4  // modo fora do enum
#define FUSION_PARTIAL_PLAN_TP1_INVALID     5  // TP1 nao e um volume negociavel
#define FUSION_PARTIAL_PLAN_TP1_TOO_BIG     6  // TP1 nao deixa saldo aberto
#define FUSION_PARTIAL_PLAN_TP2_INVALID     7  // TP2 nao e um volume negociavel
#define FUSION_PARTIAL_PLAN_TP2_TOO_BIG     8  // TP2 nao cabe no que sobrou
#define FUSION_PARTIAL_PLAN_NO_MIN_LEFT     9  // o resto final fica abaixo do minimo

struct SPartialVolumePlan
  {
   int    code;        // FUSION_PARTIAL_PLAN_*
   double tp1Volume;   // 0 quando TP1 desligado
   double tp2Volume;   // 0 quando TP2 desligado
   double remaining;   // o que fica aberto depois das reservas
  };

void FusionResetPartialVolumePlan(SPartialVolumePlan &plan)
  {
   plan.code      = FUSION_PARTIAL_PLAN_DISABLED;
   plan.tp1Volume = 0.0;
   plan.tp2Volume = 0.0;
   plan.remaining = 0.0;
  }

bool FusionPartialSpecKnown(const SSymbolSpec &spec)
  {
   return (spec.volumeStep > 0.0 && spec.volumeMin > 0.0 &&
           spec.volumeMax > 0.0 && spec.volumeMax >= spec.volumeMin);
  }

bool FusionPartialSizeModeValid(const int mode)
  {
   return (mode == PARTIAL_SIZE_PERCENT || mode == PARTIAL_SIZE_VOLUME);
  }

//--- Encaixa no grid do ativo e prende na faixa. Continua sendo o
//--- comportamento HISTORICO do modo percentual, inclusive o `MathMax` que
//--- levanta um resultado pequeno demais ate o minimo.
double FusionNormalizePartialVolume(const double volume,const SSymbolSpec &spec)
  {
   if(spec.volumeStep <= 0.0)
      return volume;

   double normalized = MathRound(volume / spec.volumeStep) * spec.volumeStep;
   normalized = MathMax(spec.volumeMin, normalized);
   normalized = MathMin(spec.volumeMax, normalized);
   return NormalizeDouble(normalized, FusionVolumeDigits(spec.volumeStep));
  }

//+------------------------------------------------------------------+
//| Volume DIGITADO pelo operador.                                     |
//|                                                                    |
//| ⚠ Aqui o `MathMax(volumeMin)` seria um defeito, e nao uma correcao. |
//| No modo percentual ele arredonda o resultado de uma CONTA; no modo  |
//| volume ele reescreveria o que a pessoa escreveu: digitar 0.003 num  |
//| ativo de minimo 0.01 viraria 0.01 calado, e o operador fecharia o   |
//| triplo do que pediu sem nunca ver um aviso.                         |
//|                                                                    |
//| Entao: valida o valor BRUTO primeiro e so depois tira o residuo de  |
//| ponto flutuante, dentro da tolerancia.                              |
//+------------------------------------------------------------------+
bool FusionPartialTypedVolumeValid(const double typed,const SSymbolSpec &spec,
                                   double &normalized)
  {
   normalized = 0.0;
   //--- NaN e infinito antes de tudo: qualquer comparacao com NaN devolve
   //--- false, entao `typed <= 0.0` sozinho DEIXARIA UM NaN PASSAR.
   if(!MathIsValidNumber(typed))
      return false;
   if(typed <= 0.0)
      return false;
   if(typed + FUSION_PARTIAL_VOLUME_EPS < spec.volumeMin)
      return false;
   if(typed - FUSION_PARTIAL_VOLUME_EPS > spec.volumeMax)
      return false;
   if(!FusionIsVolumeAligned(typed, spec))
      return false;

   //--- So agora, e so residuo: o valor ja foi julgado como veio.
   normalized = NormalizeDouble(MathRound(typed / spec.volumeStep) * spec.volumeStep,
                                FusionVolumeDigits(spec.volumeStep));
   return true;
  }

//--- Quanto um estagio reserva, no modo pedido. Devolve false quando o valor
//--- digitado nao e negociavel; no modo percentual nunca falha aqui, porque a
//--- normalizacao historica sempre produz algo dentro da faixa.
bool FusionPartialStageVolume(const ENUM_PARTIAL_SIZE_MODE mode,
                              const SPartialTPConfig &stage,
                              const double entryVolume,
                              const SSymbolSpec &spec,
                              double &volume)
  {
   volume = 0.0;
   if(mode == PARTIAL_SIZE_VOLUME)
      return FusionPartialTypedVolumeValid(stage.volume, spec, volume);

   //--- ⚠ O percentual e julgado ANTES de virar volume. Sem isto, um percentual
   //--- invalido - zero, negativo ou NaN - entraria na normalizacao e o
   //--- `MathMax(volumeMin)` dela devolveria o MINIMO NEGOCIAVEL: uma
   //--- configuracao corrompida sairia como um parcial perfeitamente valido.
   if(!MathIsValidNumber(stage.percent))
      return false;
   if(stage.percent <= 0.0 || stage.percent > 100.0)
      return false;

   volume = FusionNormalizePartialVolume(entryVolume * (stage.percent / 100.0), spec);
   return (volume > 0.0);
  }

//+------------------------------------------------------------------+
//| O plano completo. Uma resposta so para a tela e para o motor.      |
//|                                                                    |
//| Ordem das recusas importa: spec desconhecida vem antes de tudo,     |
//| porque sem grid nao ha como julgar nem o volume de entrada - e uma    |
//| tela dizendo "aumente o volume" quando o ativo nem respondeu manda    |
//| corrigir o que esta certo.                                          |
//+------------------------------------------------------------------+
bool FusionBuildPartialVolumePlan(const double entryVolume,
                                  const ENUM_PARTIAL_SIZE_MODE mode,
                                  const SPartialTPConfig &tp1,
                                  const SPartialTPConfig &tp2,
                                  const SSymbolSpec &spec,
                                  SPartialVolumePlan &plan)
  {
   FusionResetPartialVolumePlan(plan);

   if(!tp1.enabled)
     {
      plan.code      = FUSION_PARTIAL_PLAN_DISABLED;
      plan.remaining = entryVolume;
      return true;                       // sem parcial nao ha o que recusar
     }

   if(!FusionPartialSpecKnown(spec))
     { plan.code = FUSION_PARTIAL_PLAN_SPEC_UNKNOWN; return false; }

   if(!FusionPartialSizeModeValid((int)mode))
     { plan.code = FUSION_PARTIAL_PLAN_MODE_INVALID; return false; }

   //--- ⚠ O volume de ENTRADA tambem precisa caber na grade, e nao so na faixa.
   //--- Faltava o passo: 1.005 num ativo de step 0.01 passava pela porta e o
   //--- plano inteiro era calculado sobre um volume que a corretora recusaria
   //--- na hora de enviar. NaN primeiro, pela mesma razao do volume digitado.
   if(!MathIsValidNumber(entryVolume) ||
      entryVolume + FUSION_PARTIAL_VOLUME_EPS < spec.volumeMin ||
      entryVolume - FUSION_PARTIAL_VOLUME_EPS > spec.volumeMax ||
      !FusionIsVolumeAligned(entryVolume, spec))
     { plan.code = FUSION_PARTIAL_PLAN_ENTRY_INVALID; return false; }

   //--- TP1
   double v1 = 0.0;
   if(!FusionPartialStageVolume(mode, tp1, entryVolume, spec, v1) ||
      v1 + FUSION_PARTIAL_VOLUME_EPS < spec.volumeMin)
     { plan.code = FUSION_PARTIAL_PLAN_TP1_INVALID; return false; }

   //--- Tem de sobrar posicao: fechar tudo pelo TP1 nao e parcial, e virar.
   if(v1 + FUSION_PARTIAL_VOLUME_EPS >= entryVolume)
     { plan.code = FUSION_PARTIAL_PLAN_TP1_TOO_BIG; return false; }

   plan.tp1Volume = v1;
   double reserved = v1;

   //--- TP2
   if(tp2.enabled)
     {
      double v2 = 0.0;
      if(!FusionPartialStageVolume(mode, tp2, entryVolume, spec, v2) ||
         v2 + FUSION_PARTIAL_VOLUME_EPS < spec.volumeMin)
        { plan.code = FUSION_PARTIAL_PLAN_TP2_INVALID; return false; }

      //--- Cada estagio e julgado contra o que ainda existe naquele momento,
      //--- e nao contra a posicao inteira.
      double remainingBeforeTp2 = entryVolume - reserved;
      if(v2 + FUSION_PARTIAL_VOLUME_EPS >= remainingBeforeTp2)
        { plan.code = FUSION_PARTIAL_PLAN_TP2_TOO_BIG; return false; }

      plan.tp2Volume = v2;
      reserved      += v2;
     }

   plan.remaining = entryVolume - reserved;
   if(plan.remaining + FUSION_PARTIAL_VOLUME_EPS < spec.volumeMin)
     { plan.code = FUSION_PARTIAL_PLAN_NO_MIN_LEFT; return false; }

   plan.code = FUSION_PARTIAL_PLAN_OK;
   return true;
  }

//--- Texto curto do motivo, para a tela e para o log falarem igual.
string FusionPartialPlanReason(const int code)
  {
   switch(code)
     {
      case FUSION_PARTIAL_PLAN_OK:            return "";
      case FUSION_PARTIAL_PLAN_DISABLED:      return "";
      case FUSION_PARTIAL_PLAN_SPEC_UNKNOWN:  return "Especificacao de volume do ativo indisponivel.";
      case FUSION_PARTIAL_PLAN_ENTRY_INVALID: return "Volume de entrada invalido para validar TP Parcial (faixa ou passo do ativo).";
      case FUSION_PARTIAL_PLAN_MODE_INVALID:  return "Modo de tamanho do TP Parcial invalido.";
      case FUSION_PARTIAL_PLAN_TP1_INVALID:   return "TP1 precisa fechar um volume negociavel.";
      case FUSION_PARTIAL_PLAN_TP1_TOO_BIG:   return "TP1 precisa deixar saldo aberto.";
      case FUSION_PARTIAL_PLAN_TP2_INVALID:   return "TP2 precisa fechar um volume negociavel.";
      case FUSION_PARTIAL_PLAN_TP2_TOO_BIG:   return "TP2 nao cabe no volume restante.";
      case FUSION_PARTIAL_PLAN_NO_MIN_LEFT:   return "TP parcial precisa deixar o volume minimo aberto.";
     }
   return "Motivo desconhecido.";
  }

#endif
