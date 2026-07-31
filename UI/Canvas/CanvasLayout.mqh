//+------------------------------------------------------------------+
//| CanvasLayout.mqh                                                  |
//| Geometria da GUI 2.0. Constantes puras, sem estado.               |
//| Prefixo FCV_ em tudo: na Fase 3 o painel novo e o antigo convivem |
//| na mesma unidade de compilacao, e nomes crus colidiriam.          |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_LAYOUT_MQH__
#define __FUSION_CANVAS_LAYOUT_MQH__

#define FCV_PANEL_W        590
#define FCV_PANEL_H_MIN    560
#define FCV_PANEL_H_MAX    900
#define FCV_TITLEBAR_H      32
#define FCV_HEADER_BOTTOM  136
#define FCV_F1_H            30
#define FCV_F1_BOTTOM      (FCV_HEADER_BOTTOM + FCV_F1_H)
#define FCV_F2_H            26
//--- Folga entre os dois fichários: apertada de proposito. Sao niveis
//--- vizinhos da mesma hierarquia e devem parecer encaixados, nao separados.
#define FCV_F2_GAP           7
#define FCV_PAD             13
#define FCV_EDIT_W         112
#define FCV_EDIT_H          26
#define FCV_RAIL_W         136
#define FCV_RAIL_ROW        26

#define FCV_FONT_UI   "Segoe UI"
#define FCV_FONT_MONO "Consolas"
#define FCV_FW_NORMAL 400
#define FCV_FW_SEMI   600
#define FCV_FW_BOLD   700

//--- Escala tipografica, em decimos de ponto. Sete degraus e nao dezoito: o
//--- desenho anterior tinha 74, 75, 77, 78, 80, 82, 84, 85, 86, 88, 90, 92, 95,
//--- 105, 110, 115, 120 e 150. Diferencas de um ou dois decimos nao sao vistas
//--- como hierarquia — sao vistas como descuido, e foi isso que fez os numeros
//--- parecerem desalinhados de tamanho.
#define FCV_FS_HERO 150   // estado em destaque
#define FCV_FS_XL   120   // valor grande de bloco
#define FCV_FS_LG   110   // valor secundario de bloco
#define FCV_FS_VAL   95   // numeros em Consolas, coluna da direita
#define FCV_FS_BODY  88   // rotulo de linha
#define FCV_FS_SM    82   // titulo de cartao, aba, botao
#define FCV_FS_CAP   76   // dica, selo, legenda

//--- Quatro raios, nao sete. Barras de rolagem sao a unica excecao e usam
//--- metade da propria largura, porque um raio fixo numa barra de 4 px de
//--- largura ou a deixaria quadrada ou a arredondaria por inteiro.
#define FCV_RADIUS_SM    4   // caixas pequenas recuadas, item de lista
#define FCV_RADIUS_CTRL  6   // controles, abas, botoes
#define FCV_RADIUS_CARD  8   // cartoes e blocos
#define FCV_RADIUS_PILL 10   // selos e capsulas de estado

//--- Nivel 1: Status · Resultados · Estrategias · Filtros · Gestao · Perfis ·
//--- Visual. Gestao reune Risco e Protecao, que decidem dinheiro; Visual cuida
//--- de aparencia. Antes os tres moravam juntos sob "Config", um nome que
//--- descrevia a indecisao e nao o conteudo.
#define FCV_TAB_COUNT     7
#define FCV_CFG_COUNT     4    // maior nivel 2 existente (Estrategias/Filtros)

//--- Identidade das telas. Nomeadas porque o estado dos controles e indexado
//--- por elas: um indice trocado nao quebra o build, so faz um controle
//--- reaparecer com o valor de outra tela.
#define FCV_SCREEN_STATUS    0
#define FCV_SCREEN_RESULTS   1
#define FCV_SCREEN_STRAT0    2    // + subaba (0..3)
#define FCV_SCREEN_FILTER0   6    // + subaba (0..3)
#define FCV_SCREEN_RISK0    10    // + item do trilho (0..4)
#define FCV_SCREEN_PROT0    15    // + item do trilho (0..6)
#define FCV_SCREEN_PROFILES 22
#define FCV_RAIL_MAX      7
#define FCV_SWATCH_COUNT 30
#define FCV_SWATCH_COLS   6

//--- Controles publicados por passada. O limite e por tela desenhada, nao
//--- pelo total do painel: o que nao esta na tela nao publica caixa.
#define FCV_CTRL_MAX     24
//--- Botoes tambem publicam caixa de clique, em vez de o hit-testing repetir a
//--- aritmetica do desenho. Com o modo novo/duplicar, Perfis tem seis.
#define FCV_BTN_MAX      12

#define FCV_BTN_NONE      0
#define FCV_BTN_LOAD      1
#define FCV_BTN_NEW       2
#define FCV_BTN_DUP       3
#define FCV_BTN_DEL       4
#define FCV_BTN_SAVE      5
#define FCV_BTN_CANCEL    6
#define FCV_BTN_START     7
#define FCV_BTN_SAVECFG   8
#define FCV_BTN_CANCELCFG 9

//--- Modo de edicao da aba Perfis
#define FCV_PROF_VIEW     0
#define FCV_PROF_NEW      1
#define FCV_PROF_DUP      2
//--- Estado persistente dos controles, indexado por tela. Cada combinacao de
//--- abas tem faixa propria para que um toggle nao vaze de uma subaba a outra.
#define FCV_SCREEN_MAX   32
//--- A tela mais densa hoje (Estrategias > Medias) usa 11 slots. A folga
//--- existe para que uma linha nova nao faca dois controles compartilharem
//--- estado silenciosamente.
#define FCV_SLOT_MAX     20
#define FCV_STATE_MAX    (FCV_SCREEN_MAX*FCV_SLOT_MAX)

#define FCV_SB_W      6
#define FCV_SB_ARROW 14
#define FCV_SB_X    (FCV_PANEL_W-11)

#define FCV_VK_PRIOR 33
#define FCV_VK_NEXT  34
#define FCV_VK_END   35
#define FCV_VK_HOME  36
#define FCV_VK_UP    38
#define FCV_VK_DOWN  40
#define FCV_VK_M     77
#define FCV_VK_S     83
#define FCV_VK_B     66

//--- Escala do painel, em porcento das unidades logicas. Nomeada por efeito
//--- (Menor/Padrao/Maior) e nao por numero: o usuario escolhe o que enxerga
//--- melhor, e o porcento nao significa nada para ele.
#define FCV_SCALE_MIN      105
#define FCV_SCALE_STEP       5
#define FCV_SCALE_DEFAULT  110
#define FCV_SCALE_COUNT      3

//--- A tela Visual e a unica cujo estado e lido de fora do desenho (o input
//--- inicial e o botao de tema da barra escrevem nela). Os slots ficam
//--- nomeados aqui para que a ordem das linhas e quem escreve nelas nao se
//--- desencontrem em silencio: mexeu na ordem da tela, mexa aqui.
#define FCV_SCREEN_VISUAL          23
#define FCV_TAB_GESTAO              4
#define FCV_TAB_PERFIS              5
#define FCV_TAB_VISUAL              6
//--- Cada indicador consome DOIS slots (cor e estilo), dai o passo 2.
#define FCV_VISUAL_SLOT_INDICATORS  0
#define FCV_VISUAL_SLOT_COLOR0      1
#define FCV_VISUAL_SLOT_STRIDE      2
#define FCV_VISUAL_SLOT_PALETTE    11
#define FCV_VISUAL_SLOT_THEME      12
#define FCV_VISUAL_SLOT_SCALE      13
#define FCV_VISUAL_STATE(slot)     (FCV_SCREEN_VISUAL*FCV_SLOT_MAX+(slot))

#endif
