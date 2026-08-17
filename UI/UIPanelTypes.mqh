#ifndef __FUSION_UI_PANEL_TYPES_MQH__
#define __FUSION_UI_PANEL_TYPES_MQH__

//+------------------------------------------------------------------+
//| Geometria do painel no grafico.                                   |
//|                                                                   |
//| O que restou deste arquivo depois da Fase 4. Ate a 1.058 ele era  |
//| o vocabulario do painel classico — seis enums de aba e pagina e   |
//| tres structs de estado de acesso —, e tudo aquilo saiu junto com  |
//| a implementacao que os usava. A GUI 2.0 nomeia as proprias telas  |
//| em UI/Canvas/CanvasLayout.mqh, sob o prefixo FCV_.                |
//|                                                                   |
//| Sobraram os quatro valores que Core/EAApplication.mqh passa ao    |
//| CreatePanel. WIDTH e HEIGHT viram o canto oposto do retangulo; o  |
//| painel em canvas dimensiona-se sozinho a partir da altura do      |
//| grafico (DecidePanelHeight, grampeado em [560,900]) e nao os le.  |
//+------------------------------------------------------------------+
#define FUSION_PANEL_WIDTH   590
#define FUSION_PANEL_HEIGHT  626
#define FUSION_PANEL_LEFT    10
#define FUSION_PANEL_TOP     20

#endif // __FUSION_UI_PANEL_TYPES_MQH__
