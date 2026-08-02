//+------------------------------------------------------------------+
//| CanvasForm.mqh                                                    |
//| Descricao declarativa de uma linha de formulario.                 |
//|                                                                   |
//| Existe para que cada tela declare o que contem em vez de repetir  |
//| aritmetica de posicao. A altura do cartao passa a ser derivada    |
//| das linhas, e nao um numero escrito a mao que precisa ser         |
//| corrigido toda vez que uma linha entra ou sai.                    |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_FORM_MQH__
#define __FUSION_CANVAS_FORM_MQH__

#define FCV_ROW_FIELD   0   // rotulo + dica + campo nativo de digitacao
#define FCV_ROW_TOGGLE  1   // rotulo + chave desenhada
#define FCV_ROW_COMBO   2   // rotulo + combo desenhado
#define FCV_ROW_COLOR   3   // rotulo + amostra de cor
#define FCV_ROW_STATIC  4   // rotulo + valor so de leitura
#define FCV_ROW_BADGE   5   // rotulo + selo semantico
#define FCV_ROW_NOTE    6   // texto corrido, altura medida pelo conteudo
//--- Linha de tres colunas: nome, amostra de cor e estilo de linha. Existe
//--- porque a tela Visual da 1.058 e uma tabela, nao uma pilha de campos —
//--- e sem ela a cor e o estilo do mesmo indicador ficariam em linhas
//--- separadas, obrigando a ler duas vezes para configurar um so.
#define FCV_ROW_COLORSTYLE 7
//--- Linha de horario: rotulo + hora e minuto em dois campos estreitos, com o
//--- separador desenhado entre eles. E a estrutura da 1.058
//--- (UIPanelProtectionBuild usa dois AddTimeEdit por horario), e nao um
//--- detalhe de desenho: cada metade tem faixa propria — 0..23 e 0..59 — e um
//--- campo unico "HH:MM" precisaria de uma segunda regra de recorte para
//--- discordar da que o EA ja aplica. Consome DOIS slots, como a linha de
//--- cor+estilo.
#define FCV_ROW_TIME       8

//--- Alturas num passo de 4 px. Antes eram 42, 30, 32, 34, 26, 28, 26 e 10 —
//--- numeros sem relacao entre si, que produzem um ritmo vertical irregular
//--- mesmo quando cada linha, isolada, parece certa.
#define FCV_ROW_FIELD_H   44
#define FCV_ROW_TOGGLE_H  32
#define FCV_ROW_COMBO_H   32
#define FCV_ROW_COLOR_H   36
#define FCV_ROW_STATIC_H  28
#define FCV_ROW_BADGE_H   28
#define FCV_ROW_CSTYLE_H  36
#define FCV_ROW_TIME_H    44
#define FCV_CARD_HEAD_H   28
#define FCV_CARD_FOOT_H   12
#define FCV_CARD_GAP      12

#define FCV_ROWS_MAX      18

//--- Itens visiveis num popup de combo, igual ao ListViewItems(10) da 1.058.
//--- Com 21 timeframes a lista inteira teria 512 px e nao caberia no painel.
#define FCV_COMBO_WINDOW  10
#define FCV_COMBO_ITEM_H  24

//--- Amostra de cor: larga quando ocupa a coluna sozinha, estreita quando
//--- divide a linha com o estilo. A altura e a mesma do campo e do combo —
//--- os tres vivem na mesma coluna e nao podem ter alturas diferentes.
//--- A largura precisa comportar a cor E o filete do chevron. A estreita subiu
//--- de 40 para 48 quando o chevron entrou: com 40, sobravam 26 px de cor, e a
//--- amostra passava a parecer um combo com um respingo colorido em vez de uma
//--- cor com um botao de abrir.
#define FCV_SWATCH_W       64
#define FCV_SWATCH_W_SLIM  48
#define FCV_SWATCH_ARROW_W 14

//--- Campo de hora/minuto: dois digitos e o cursor. Estreito de proposito —
//--- uma caixa larga para dois digitos convida a digitar mais do que cabe.
//--- O par ocupa a mesma coluna e a mesma largura total de um campo normal,
//--- para nao abrir uma segunda coluna de controles na direita da tela.
#define FCV_TIME_EDIT_W    44
#define FCV_TIME_GAP       ((FCV_EDIT_W)-2*(FCV_TIME_EDIT_W))

//--- listas de opcoes dos combos, por tipo
#define FCV_COMBO_TF        0
#define FCV_COMBO_METHOD    1
#define FCV_COMBO_PRICE     2
#define FCV_COMBO_SIDE      3
#define FCV_COMBO_NEWS      4
#define FCV_COMBO_PALETTE   5
#define FCV_COMBO_THEMEMODE 6
#define FCV_COMBO_SCALE     7
#define FCV_COMBO_CONFLICT  8
#define FCV_COMBO_LINESTYLE 9
//--- Listas operacionais, com os mesmos rotulos das combos da 1.058
//--- (UI/PanelUtils.mqh). Os textos vao para a tela do usuario: divergir aqui
//--- faria a 2.0 chamar de outro nome o que ele ja conhece.
#define FCV_COMBO_ENTRY     10
#define FCV_COMBO_EXIT      11
#define FCV_COMBO_RSIEXIT   12
#define FCV_COMBO_RSIMODE   13
#define FCV_COMBO_RSIFILTER 14
#define FCV_COMBO_BBMODE    15
#define FCV_COMBO_BBWIDTH   16
#define FCV_COMBO_STREAK    17
#define FCV_COMBO_TARGET    18
#define FCV_COMBO_DDTYPE    19
#define FCV_COMBO_DDPEAK    20

//--- semantica de selo e de valor
#define FCV_SEM_NEUTRAL 0
#define FCV_SEM_GOOD    1
#define FCV_SEM_BAD     2
#define FCV_SEM_WARN    3

struct SCanvasFormRow
  {
   int    kind;
   string label;
   string hint;      // dica sob o rotulo, ou o corpo da nota
   string value;     // valor padrao do campo, ou texto do valor/selo
   int    aux;       // tipo do combo, ou semantica do selo
   int    fid;       // campo de SEASettings que a linha edita; FCV_FLD_NONE = estado local
   //--- Segundo campo da linha, usado so pelo horario: fid guarda a hora e
   //--- fid2 o minuto. Sao duas chaves distintas de SEASettings
   //--- (sessionStartHour e sessionStartMinute), nao duas metades de uma.
   int    fid2;
   //--- Os dois estados que a 1.058 tem e a 2.0 precisa reproduzir. Sao
   //--- propriedade da linha, nao da tela: numa mesma tela um campo pode
   //--- estar invalido e o vizinho nao.
   bool   enabled;   // false = bloqueado: apagado, sem clique, sem digitacao
   bool   valid;     // false = invalido: fundo e borda de erro
  };

#endif
