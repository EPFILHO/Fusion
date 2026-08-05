//+------------------------------------------------------------------+
//| SettingsPrecision.mqh                                             |
//| A precisao que o ARQUIVO DE PERFIL guarda.                        |
//|                                                                   |
//| `SEASettings` tem nove campos double, e o arquivo grava todos com |
//| casas FIXAS (`DoubleToString`). Um valor com mais casas que isso  |
//| nao sobrevive a ida e volta: 1.234 vira "1.23" no disco e volta   |
//| 1.23. Enquanto ninguem comparava as duas pontas, a perda passava; |
//| ela virou defeito visivel de duas formas ao mesmo tempo:          |
//|                                                                   |
//|  - a TELA mentia. O campo e desenhado com duas casas, entao o     |
//|    usuario lia 1.23 e o EA operava 1.234;                         |
//|  - a CONFERENCIA DE GRAVACAO acusava falso. O painel relê o       |
//|    arquivo e compara com o que o EA aplicou (AnnounceSaveOutcome);|
//|    com 1e-7 de tolerancia, uma gravacao bem-sucedida era          |
//|    anunciada como "PERFIL NAO GRAVADO".                           |
//|                                                                   |
//| A resposta e cortar a precizao na ENTRADA, e nao afrouxar a       |
//| comparacao: o que nao cabe no arquivo nao deveria existir no      |
//| rascunho, senao a tela e o disco discordam para sempre. E o que a |
//| 1.058 faz sem querer — a validacao dela relê o texto do controle  |
//| a cada passada, e o texto ja esta com duas casas.                 |
//|                                                                   |
//| ⚠️ ESTA TABELA ESPELHA `ProfileSettingsSerializer.mqh`. Mudar a   |
//| grafia de um campo la sem mudar aqui traz o falso "nao gravado"   |
//| de volta, e ele nao aparece em compilacao nenhuma.                |
//+------------------------------------------------------------------+
#ifndef __FUSION_SETTINGS_PRECISION_MQH__
#define __FUSION_SETTINGS_PRECISION_MQH__

#include "Types.mqh"

//--- Casas com que o arquivo grava cada double. Duas para tudo, menos o lote.
//---
//--- O lote usa OITO, que e o teto de FusionVolumeDigits — a funcao que deriva
//--- a precisao do `volumeStep` do ativo. Eram quatro, e nao dava: num ativo de
//--- passo 0.00001, digitar 0.00001 virava 0.0000 antes mesmo da validacao, e a
//--- conferencia de gravacao comparava zero com zero e dizia que estava tudo
//--- certo. Um lote apagado em silencio, nos dois lados ao mesmo tempo.
#define FUSION_STORAGE_DIGITS       2
#define FUSION_STORAGE_DIGITS_LOT   8

void FusionApplyStoragePrecision(SEASettings &settings)
  {
   settings.maxDailyLoss  = NormalizeDouble(settings.maxDailyLoss, FUSION_STORAGE_DIGITS);
   settings.maxDailyGain  = NormalizeDouble(settings.maxDailyGain, FUSION_STORAGE_DIGITS);
   settings.maxDrawdown   = NormalizeDouble(settings.maxDrawdown,  FUSION_STORAGE_DIGITS);
   settings.tp1.percent   = NormalizeDouble(settings.tp1.percent,  FUSION_STORAGE_DIGITS);
   settings.tp2.percent   = NormalizeDouble(settings.tp2.percent,  FUSION_STORAGE_DIGITS);
   settings.bbDeviation   = NormalizeDouble(settings.bbDeviation,  FUSION_STORAGE_DIGITS);
   settings.bbFilterDeviation      = NormalizeDouble(settings.bbFilterDeviation,      FUSION_STORAGE_DIGITS);
   settings.bbFilterMinWidthPercent= NormalizeDouble(settings.bbFilterMinWidthPercent,FUSION_STORAGE_DIGITS);
   //--- O lote NAO e cortado para a precisao de exibicao, so para a do arquivo.
   //--- Cortar para a exibicao mascararia um lote desalinhado do passo do ativo:
   //--- 0.125 com passo 0.01 viraria 0.13, que e valido — e o usuario gravaria
   //--- um lote que nunca pediu. Desalinhado, ele continua desalinhado e a
   //--- validacao o recusa, que e o comportamento honesto.
   settings.fixedLot      = NormalizeDouble(settings.fixedLot, FUSION_STORAGE_DIGITS_LOT);
  }

#endif
