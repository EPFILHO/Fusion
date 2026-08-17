//+------------------------------------------------------------------+
//| VolumeFormat.mqh                                                  |
//| Como um volume e escrito e conferido contra a especificacao do    |
//| ativo.                                                            |
//|                                                                   |
//| Extraido do UI/PanelUtils.mqh da 1.058 na Etapa 2b. Motivo: a GUI |
//| 2.0 precisa escrever o Lote Fixo exatamente como a 1.058 escreve, |
//| e PanelUtils arrastava a biblioteca Controls inteira — o          |
//| renderizador em canvas nao podia inclui-la. A alternativa era uma |
//| segunda copia da regra de casas decimais, que e justamente o tipo |
//| de duplicacao que diverge sem quebrar o build: os dois paineis    |
//| passariam a grafar o mesmo lote de formas diferentes.             |
//|                                                                   |
//| Depende so de SSymbolSpec. Enquanto os dois paineis conviveram, o |
//| PanelUtils passou a incluir ESTE arquivo, e por isso ninguem      |
//| precisou mudar de chamada; a Fase 4 apagou aquele lado e sobrou   |
//| so este, que sempre foi a fonte unica.                            |
//+------------------------------------------------------------------+
#ifndef __FUSION_VOLUME_FORMAT_MQH__
#define __FUSION_VOLUME_FORMAT_MQH__

#include "Types.mqh"

//--- Casas decimais que o passo de volume exige: 0.01 pede 2, 0.001 pede 3.
int FusionVolumeDigits(const double step)
  {
   double value = step;
   int digits = 0;

   while(digits < 8 && MathAbs(value - MathRound(value)) > 0.0000001)
     {
      value *= 10.0;
      digits++;
     }

   return digits;
  }

//--- Minimo de duas casas mesmo quando o passo pediria menos: lote e sempre
//--- lido como "0.10", nunca como "0.1".
string FusionFormatVolume(const double volume,const SSymbolSpec &spec)
  {
   int digits = FusionVolumeDigits(spec.volumeStep);
   if(digits < 2)
      digits = 2;
   return DoubleToString(volume, digits);
  }

bool FusionIsVolumeAligned(const double volume,const SSymbolSpec &spec)
  {
   if(spec.volumeStep <= 0.0)
      return true;

   double steps = volume / spec.volumeStep;
   return MathAbs(steps - MathRound(steps)) <= 0.0000001;
  }

#endif
