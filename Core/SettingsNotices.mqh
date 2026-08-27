//+------------------------------------------------------------------+
//| SettingsNotices.mqh                                               |
//| Avisos derivados apenas de SEASettings.                           |
//|                                                                   |
//| Extraido do UI/PanelUtils.mqh DA 1.058 porque o painel 2.0        |
//| precisava das mesmas respostas e nao podia incluir aquele         |
//| arquivo: PanelUtils arrastava os controles do CAppDialog, que e   |
//| justamente o que a 2.0 deixou de usar. A Fase 4 apagou o painel   |
//| classico, e o PanelUtils com ele — a referencia acima aponta para |
//| a pasta Fusion-1.058 e para o historico, nao para esta arvore.    |
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
      return "ATENÇÃO: saída TP/SL ativa com SL e TP zerados.";
   if(slZero)
      return "ATENÇÃO: operar sem SL é ARRISCADO.";
   if(tpZero)
      return "Saída TP/SL ativa com TP fixo zerado.";
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

//+------------------------------------------------------------------+
//| A ROTA UNICA de conserto de um perfil que NAO e o ativo.          |
//|                                                                   |
//| A GUI so edita a configuracao do perfil ATIVO. Entao mandar        |
//| "Corrija em Gestao" sobre um perfil apenas SELECIONADO e uma       |
//| instrucao inexequivel: nao ha onde editar aquele perfil neste      |
//| grafico — e, no caso que motivou isto, ele nem pode ser ativado    |
//| aqui, porque a incompatibilidade com o ativo e justamente o motivo |
//| da recusa. O usuario ia ate a aba e nao encontrava o que corrigir. |
//|                                                                   |
//| A rota que EXISTE e esta: carregar o perfil onde ele vale, ajustar |
//| la, salvar, e voltar. Escrita uma vez so para as variantes nao se  |
//| espalharem — e a licao 1 da secao 8 do plano: mensagem que instrui |
//| acao impossivel e pior que mensagem nenhuma.                      |
//+------------------------------------------------------------------+
string FusionProfileFixElsewhereHint(const string tabName,const string retryAction)
  {
   return "Para corrigi-lo pela interface, carregue-o em um gráfico de ativo "
          "compatível, faça o ajuste em " + tabName + " e salve; depois " +
          retryAction + ".";
  }

#endif
