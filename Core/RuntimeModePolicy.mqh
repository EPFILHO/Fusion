//+------------------------------------------------------------------+
//| RuntimeModePolicy.mqh                                             |
//| FONTE ÚNICA da regra "esta compilação pode rodar nesta conta?".   |
//|                                                                    |
//| O projeto produz DOIS binários do mesmo EA:                        |
//|   · Fusion.ex5     — completa: demo, contest, real e Tester;      |
//|   · FusionDemo.ex5 — demonstração: somente demo e Tester.         |
//|                                                                    |
//| A diferença entre eles é UMA linha de #define no .mq5. Nenhum      |
//| código operacional é duplicado, e não existe `input` que ligue ou  |
//| desligue a restrição — se existisse, bastaria mudá-lo para anular  |
//| a modalidade, e o binário deixaria de ser o que ele diz ser.       |
//|                                                                    |
//| ⚠ O PREDICADO é função livre e NÃO toca o terminal: entram por     |
//| parâmetro o modo da conta, se esse modo é conhecido, e se está no  |
//| Tester — e nada além disso. Ele não recebe conta, número de conta  |
//| nem identidade alguma. É o mesmo idioma de PartialVolumePlan: a    |
//| regra fica exercitável por sonda, fora do EA, e a leitura do MT5   |
//| mora numa função separada, que só busca os valores.                |
//|                                                                    |
//| ⚠ Isto NÃO é licenciamento. Não há binding por conta, prazo,       |
//| servidor, hardware ou rede; a versão completa não é protegida por  |
//| nada aqui. É apenas a modalidade da compilação.                    |
//+------------------------------------------------------------------+
#ifndef __FUSION_RUNTIME_MODE_POLICY_MQH__
#define __FUSION_RUNTIME_MODE_POLICY_MQH__

//--- Modo de conta que o terminal não soube informar, ou informou fora do
//--- enum conhecido. Não é um valor do MT5: é a AUSÊNCIA de resposta confiável.
#define FUSION_ACCOUNT_MODE_UNKNOWN (-1)

//--- Nome do modo para o diário. Nunca acompanha número de conta.
//---
//--- ⚠ Comparação, e não `switch`: o valor vem de AccountInfoInteger como
//--- `long`, e um `switch` com rótulos do enum obriga o compilador a estreitar
//--- para `int` — warning 43, possível perda de dados. Aqui não há conversão.
string FusionAccountModeText(const long tradeMode)
  {
   if(tradeMode == ACCOUNT_TRADE_MODE_DEMO)    return "DEMO";
   if(tradeMode == ACCOUNT_TRADE_MODE_CONTEST) return "CONTEST";
   if(tradeMode == ACCOUNT_TRADE_MODE_REAL)    return "REAL";
   return "DESCONHECIDO";
  }

//+------------------------------------------------------------------+
//| O PREDICADO. Tudo entra por parâmetro; nada é lido daqui.          |
//|                                                                    |
//| ⚠ FALHA FECHADA: sem saber o tipo da conta, recusa. A alternativa  |
//| — assumir demo no escuro — transformaria uma falha de leitura em   |
//| permissão para operar numa conta real.                             |
//|                                                                    |
//| O Tester passa antes de qualquer outra coisa: lá não existe conta  |
//| a proteger, e é onde o comprador avalia o produto.                 |
//+------------------------------------------------------------------+
bool FusionDemoBuildAllowsRun(const bool isTester,
                              const bool tradeModeKnown,
                              const long tradeMode)
  {
   if(isTester)
      return true;
   if(!tradeModeKnown)
      return false;
   return (tradeMode == ACCOUNT_TRADE_MODE_DEMO);
  }

//+------------------------------------------------------------------+
//| A LEITURA. Só busca os valores no terminal; não decide nada.       |
//|                                                                    |
//| Duas condições para o modo ser considerado conhecido: a chamada    |
//| não pode ter erro E o valor tem de ser um dos três do enum. Um     |
//| valor fora da lista é tratado como desconhecido, e não como "não é |
//| demo, então recuse por ser real" — o motivo registrado precisa ser |
//| verdadeiro.                                                        |
//+------------------------------------------------------------------+
bool FusionReadAccountTradeMode(long &tradeMode)
  {
   tradeMode = FUSION_ACCOUNT_MODE_UNKNOWN;

   ResetLastError();
   long value = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   if(GetLastError() != 0)
      return false;

   if(value != ACCOUNT_TRADE_MODE_DEMO &&
      value != ACCOUNT_TRADE_MODE_CONTEST &&
      value != ACCOUNT_TRADE_MODE_REAL)
      return false;

   tradeMode = value;
   return true;
  }

//--- Frase única da recusa, para diário e Alert dizerem a mesma coisa.
string FusionDemoBuildRefusalText(void)
  {
   return "Esta é a versão de demonstração do EP Fusion. Ela funciona somente "
          "em conta demo e no Strategy Tester. Nenhuma operação foi iniciada.";
  }

//+------------------------------------------------------------------+
//| Porta de partida da compilação DEMO.                               |
//|                                                                    |
//| ⚠ Chamada ANTES de construir a aplicação, e é isso que garante o   |
//| resto: sem instância registrada, sem handle, sem timer, sem perfil |
//| lido ou gravado, sem chart state tocado e sem nenhuma ordem. Ela   |
//| não constrói nada — só lê, registra e responde.                    |
//+------------------------------------------------------------------+
bool FusionDemoBuildStartupAllowed(void)
  {
   bool isTester = (bool)MQLInfoInteger(MQL_TESTER);

   long tradeMode = FUSION_ACCOUNT_MODE_UNKNOWN;
   bool known = FusionReadAccountTradeMode(tradeMode);

   if(FusionDemoBuildAllowsRun(isTester, known, tradeMode))
      return true;

   //--- O modo entra no diário; o número da conta, nunca.
   PrintFormat("FUSION DEMO: execução recusada. Modo da conta: %s.",
               FusionAccountModeText(tradeMode));
   Print(FusionDemoBuildRefusalText());

   //--- Uma vez por instância. A recusa devolve INIT_FAILED e o terminal
   //--- retira o EA, então não há laço — a guarda existe para o caso de o
   //--- terminal reinicializar o programa sem descarregá-lo.
   static bool alerted = false;
   if(!isTester && !alerted)
     {
      alerted = true;
      Alert(FusionDemoBuildRefusalText());
     }

   return false;
  }

#endif
