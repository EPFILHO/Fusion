//+------------------------------------------------------------------+
//| SettingsNotices.mqh                                               |
//| Avisos derivados apenas de SEASettings.                           |
//|                                                                   |
//| Extraido de UI/PanelUtils.mqh porque o painel 2.0 precisa das     |
//| mesmas respostas e nao pode incluir aquele arquivo: PanelUtils    |
//| arrasta os controles do CAppDialog, que e justamente o que a 2.0  |
//| deixou de usar.                                                   |
//|                                                                   |
//| Extrair, e nao copiar. Duplicar regra que decide o que o usuario  |
//| ve foi o erro que ja nos custou combos divergentes: duas copias   |
//| envelhecem em ritmos diferentes e a diferenca aparece como bug de |
//| um painel so.                                                     |
//+------------------------------------------------------------------+
#ifndef __FUSION_SETTINGS_NOTICES_MQH__
#define __FUSION_SETTINGS_NOTICES_MQH__

#include "Types.mqh"

//--- Alguma estrategia ligada depende de TP/SL para sair?
bool FusionUsesTPSLExit(const SEASettings &settings)
  {
   return ((settings.useMACross   && settings.maExitMode  == EXIT_TP_SL) ||
           (settings.useRSI       && settings.rsiExitMode == RSI_EXIT_TP_SL) ||
           (settings.useBollinger && settings.bbExitMode  == EXIT_TP_SL));
  }

//--- Saida por TP/SL com nivel zerado: o EA opera sem aquela protecao.
string FusionTPSLExitZeroNotice(const SEASettings &settings)
  {
   if(!FusionUsesTPSLExit(settings))
      return "";

   bool slZero = (settings.fixedSLPoints <= 0);
   bool tpZero = (settings.fixedTPPoints <= 0);
   if(slZero && tpZero)
      return "ATENCAO: saida TP/SL ativa com SL e TP zerados.";
   if(slZero)
      return "ATENCAO: operar sem SL e ARRISCADO.";
   if(tpZero)
      return "Saida TP/SL ativa com TP fixo zerado.";
   return "";
  }

//--- Ha ao menos uma janela de noticias ligada? Sem nenhuma, o bloqueio por
//--- noticias nao pode estar em vigor e anuncia-lo confundiria.
bool FusionHasEnabledNewsWindow(const SEASettings &settings)
  {
   for(int i = 0; i < FUSION_NEWS_WINDOW_COUNT; ++i)
      if(settings.newsWindows[i].enabled)
         return true;
   return false;
  }

#endif
