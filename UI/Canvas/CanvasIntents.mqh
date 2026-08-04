//+------------------------------------------------------------------+
//| CanvasIntents.mqh                                                 |
//| O vocabulario que o renderizador fala com quem o conduz.          |
//|                                                                   |
//| NAO e o SUICommand do EA, e a distincao e o ponto deste arquivo.  |
//| O renderizador nao alcanca Persistence (decisao da Fase 1, e a    |
//| razao de o desenho nunca tocar em disco), entao ele nao pode      |
//| decidir se uma acao e possivel: a lista de perfis que ele tem em  |
//| maos pode estar velha, e as travas de concorrencia foram lidas    |
//| ha ate um segundo.                                                |
//|                                                                   |
//| O que ele sabe e o que o usuario PEDIU. Publica a intencao; quem  |
//| constroi o painel reconfere contra o disco e os registros do      |
//| terminal no instante da acao e so entao traduz para SUICommand —  |
//| ou executa sozinho, no caso das que nao chegam ao EA.             |
//|                                                                   |
//| Tres delas nunca viram SUICommand:                                |
//|   EXCLUIR    — mexe no disco, o EA nao participa (igual a 1.058)  |
//|   DUPLICAR   — le um perfil do disco para semear o formulario     |
//|   (ATUALIZAR — nem intencao e: ver ConsumeProfileRefreshRequest)  |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_INTENTS_MQH__
#define __FUSION_CANVAS_INTENTS_MQH__

#include "..\..\Core\Types.mqh"

#define FCV_INTENT_NONE            0
//--- INICIAR / PAUSAR
#define FCV_INTENT_TOGGLE_RUN      1
//--- SALVAR do cabecalho: grava o rascunho no perfil ATIVO
#define FCV_INTENT_SAVE_ACTIVE     2
//--- CRIAR PERFIL / CRIAR COPIA: grava o rascunho num nome NOVO
#define FCV_INTENT_CREATE_PROFILE  3
#define FCV_INTENT_LOAD_PROFILE    4
#define FCV_INTENT_DELETE_PROFILE  5
#define FCV_INTENT_DUPLICATE       6

//--- Severidade da resposta que volta para a tela. Mesmos tres niveis do
//--- FCV_SEM_* do desenho; separados para nao amarrar o vocabulario de
//--- comandos ao cabecalho de layout.
#define FCV_ANSWER_GOOD  0
#define FCV_ANSWER_WARN  1
#define FCV_ANSWER_BAD   2

struct SCanvasIntent
  {
   int          kind;
   //--- Perfil ALVO. No CREATE e o nome digitado no formulario; nas demais, o
   //--- nome do perfil selecionado na lista.
   string       profile;
   //--- So o CREATE usa: o Magic digitado. Vai separado de settings porque e o
   //--- unico campo do formulario que nao passou pelo rascunho.
   int          magic;
   //--- Rascunho no instante do clique. Copiado aqui, e nao lido depois, porque
   //--- entre o clique e a execucao o snapshot do EA pode ter chegado.
   SEASettings  settings;
  };

#endif
