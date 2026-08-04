//+------------------------------------------------------------------+
//| CanvasFields.mqh                                                  |
//| Identificadores de campo: a ligacao declarada entre um controle   |
//| da tela e um campo de SEASettings.                                |
//|                                                                   |
//| Cada linha de formulario que edita configuracao declara QUAL      |
//| campo edita. A traducao identificador -> campo vive em dois       |
//| switches planos (ler e escrever), auditaveis lado a lado com o    |
//| struct. Verboso de proposito: a alternativa — espelhar o estado   |
//| em outro lugar e sincronizar — cria duas fontes da mesma verdade. |
//|                                                                   |
//| So os campos das telas ja ligadas entram aqui; a lista cresce     |
//| tela a tela, junto com a auditoria de cada uma.                   |
//+------------------------------------------------------------------+
#ifndef __FUSION_CANVAS_FIELDS_MQH__
#define __FUSION_CANVAS_FIELDS_MQH__

#define FCV_FLD_NONE              -1

//--- Estrategias > Geral
#define FCV_FLD_USE_MACROSS        0   // bool
#define FCV_FLD_USE_RSI            1   // bool
#define FCV_FLD_USE_BB             2   // bool
#define FCV_FLD_CONFLICT           3   // combo CONFLICT

//--- Estrategias > Medias
#define FCV_FLD_MA_PRIORITY       10   // int
#define FCV_FLD_MA_FAST_PERIOD    11   // int
#define FCV_FLD_MA_FAST_TF        12   // combo TF
#define FCV_FLD_MA_FAST_METHOD    13   // combo METHOD
#define FCV_FLD_MA_FAST_PRICE     14   // combo PRICE
#define FCV_FLD_MA_SLOW_PERIOD    15   // int
#define FCV_FLD_MA_SLOW_TF        16   // combo TF
#define FCV_FLD_MA_SLOW_METHOD    17   // combo METHOD
#define FCV_FLD_MA_SLOW_PRICE     18   // combo PRICE
#define FCV_FLD_MA_MIN_DIST       19   // int
#define FCV_FLD_MA_ENTRY_MODE     20   // combo ENTRY
#define FCV_FLD_MA_EXIT_MODE      21   // combo EXIT

//--- Estrategias > RSI
#define FCV_FLD_RSI_PRIORITY      30   // int
#define FCV_FLD_RSI_PERIOD        31   // int
#define FCV_FLD_RSI_TF            32   // combo TF
#define FCV_FLD_RSI_PRICE         33   // combo PRICE
#define FCV_FLD_RSI_MODE          34   // combo RSIMODE
#define FCV_FLD_RSI_OVERSOLD      35   // int
#define FCV_FLD_RSI_OVERBOUGHT    36   // int
#define FCV_FLD_RSI_MIDDLE        37   // int
#define FCV_FLD_RSI_EXIT_MODE     38   // combo RSIEXIT

//--- Estrategias > Bollinger
#define FCV_FLD_BB_PRIORITY       50   // int
#define FCV_FLD_BB_PERIOD         51   // int
#define FCV_FLD_BB_DEVIATION      52   // double(2)
#define FCV_FLD_BB_TF             53   // combo TF
#define FCV_FLD_BB_PRICE          54   // combo PRICE
#define FCV_FLD_BB_MODE           55   // combo BBMODE
#define FCV_FLD_BB_EXIT_MODE      56   // combo EXIT

//--- Filtros > Geral (as tres chaves mestras)
#define FCV_FLD_USE_TREND         70   // bool
#define FCV_FLD_USE_RSIF          71   // bool
#define FCV_FLD_USE_BBF           72   // bool

//--- Filtros > Tendencia. Cada media tem a propria chave: a 1.058 permite
//--- usar so a M1, e uma chave unica esconderia isso.
#define FCV_FLD_TR_MA1_ON         74   // bool
#define FCV_FLD_TR_MA1_PERIOD     75   // int
#define FCV_FLD_TR_MA1_TF         76   // combo TF
#define FCV_FLD_TR_MA1_METHOD     77   // combo METHOD
#define FCV_FLD_TR_MA1_PRICE      78   // combo PRICE
#define FCV_FLD_TR_MA2_ON         79   // bool
#define FCV_FLD_TR_MA2_PERIOD     80   // int
#define FCV_FLD_TR_MA2_TF         81   // combo TF
#define FCV_FLD_TR_MA2_METHOD     82   // combo METHOD
#define FCV_FLD_TR_MA2_PRICE      83   // combo PRICE

//--- Filtros > RSI
#define FCV_FLD_RF_PERIOD         90   // int
#define FCV_FLD_RF_TF             91   // combo TF
#define FCV_FLD_RF_PRICE          92   // combo PRICE
#define FCV_FLD_RF_MODE           93   // combo RSIFILTER
#define FCV_FLD_RF_BUYMIN         94   // int
#define FCV_FLD_RF_SELLMAX        95   // int

//--- Filtros > Bollinger
#define FCV_FLD_BF_PERIOD        100   // int
#define FCV_FLD_BF_DEV           101   // double(2)
#define FCV_FLD_BF_TF            102   // combo TF
#define FCV_FLD_BF_PRICE         103   // combo PRICE
#define FCV_FLD_BF_MODE          104   // combo BBWIDTH
#define FCV_FLD_BF_MINPTS        105   // int
#define FCV_FLD_BF_MINPCT        106   // double(2)
#define FCV_FLD_BF_SLOPE_ON      107   // bool
#define FCV_FLD_BF_SLOPE_BACK    108   // int
#define FCV_FLD_BF_SLOPE_MINPTS  109   // int

//--- Layout > Indicadores no grafico. Sao configuracao DO PERFIL (o EA desenha
//--- as linhas com elas), ao contrario de paleta/tema/escala, que sao
//--- preferencia de quem opera e vivem em variavel global do terminal.
//--- Cada indicador tem cor e estilo; a linha da tela amarra os dois.
#define FCV_FLD_SHOW_INDICATORS  220   // bool
#define FCV_FLD_VIS_MAFAST_COLOR 221   // color
#define FCV_FLD_VIS_MAFAST_STYLE 222   // combo LINESTYLE
#define FCV_FLD_VIS_MASLOW_COLOR 223
#define FCV_FLD_VIS_MASLOW_STYLE 224
#define FCV_FLD_VIS_TREND1_COLOR 225
#define FCV_FLD_VIS_TREND1_STYLE 226
#define FCV_FLD_VIS_TREND2_COLOR 227
#define FCV_FLD_VIS_TREND2_STYLE 228
#define FCV_FLD_VIS_BB_COLOR     229
#define FCV_FLD_VIS_BB_STYLE     230

//--- Perfis
//--- O Magic identifica as ordens deste perfil no grafico. Mora em Perfis, e
//--- nao em Config, porque e identidade do perfil e a lista ja mostra o de
//--- cada um.
#define FCV_FLD_MAGIC            118   // int

//--- Gestao > Risco -------------------------------------------------
//--- O lote e o unico campo formatado pela especificacao do ativo
//--- (FusionFormatVolume); os demais sao inteiro ou decimal de 2 casas.
#define FCV_FLD_FIXED_LOT        120   // double(spec)
#define FCV_FLD_SLIPPAGE         121   // int
#define FCV_FLD_SL_POINTS        122   // int
#define FCV_FLD_TP_POINTS        123   // int
#define FCV_FLD_COMP_SL          124   // bool
#define FCV_FLD_COMP_TP          125   // bool
#define FCV_FLD_TP1_ON           126   // bool
#define FCV_FLD_TP1_PCT          127   // double(2)
#define FCV_FLD_TP1_DIST         128   // int
#define FCV_FLD_TP2_ON           129   // bool
#define FCV_FLD_TP2_PCT          130   // double(2)
#define FCV_FLD_TP2_DIST         131   // int
#define FCV_FLD_FREE_TP          132   // bool
#define FCV_FLD_BE_ON            133   // bool
#define FCV_FLD_BE_TRIGGER       134   // int
#define FCV_FLD_BE_OFFSET        135   // int
#define FCV_FLD_TRAIL_ON         136   // bool
#define FCV_FLD_TRAIL_START      137   // int
#define FCV_FLD_TRAIL_STEP       138   // int

//--- Gestao > Protecao > Entrada
#define FCV_FLD_SPREAD_ON        140   // bool
#define FCV_FLD_SPREAD_MAX       141   // int
#define FCV_FLD_DIRECTION        142   // combo SIDE

//--- Faixa de cada metade de um horario. Sao os limites que a 1.058 usa ao
//--- recortar o texto digitado (IsTimeEditObject).
#define FCV_HOUR_MAX    23
#define FCV_MINUTE_MAX  59

//--- Gestao > Protecao > Sessao. Hora e minuto sao chaves separadas no
//--- struct, com faixas diferentes (0..23 e 0..59).
#define FCV_FLD_SESSION_ON       143   // bool
#define FCV_FLD_SESS_START_H     144   // int
#define FCV_FLD_SESS_START_M     145   // int
#define FCV_FLD_SESS_END_H       146   // int
#define FCV_FLD_SESS_END_M       147   // int
#define FCV_FLD_SESS_CLOSE       148   // bool
#define FCV_FLD_SESS_OVERNIGHT   149   // bool

//--- Gestao > Protecao > Noticias: tres janelas iguais
//--- (FUSION_NEWS_WINDOW_COUNT), seis campos cada, em blocos de 10 para o
//--- indice da janela caber na aritmetica sem tabela.
#define FCV_FLD_NEWS0            150
#define FCV_FLD_NEWS_STRIDE       10
#define FCV_FLD_NEWS_ON           0    // bool    150 / 160 / 170
#define FCV_FLD_NEWS_START_H      1    // int
#define FCV_FLD_NEWS_START_M      2    // int
#define FCV_FLD_NEWS_END_H        3    // int
#define FCV_FLD_NEWS_END_M        4    // int
#define FCV_FLD_NEWS_MODE         5    // combo NEWS
//--- Campo da janela w. Fora deste intervalo os switches nao respondem.
#define FCV_FLD_NEWS(w,f)  (FCV_FLD_NEWS0+(w)*FCV_FLD_NEWS_STRIDE+(f))
#define FCV_FLD_NEWS_LAST  (FCV_FLD_NEWS(FUSION_NEWS_WINDOW_COUNT-1,FCV_FLD_NEWS_MODE))

//--- Gestao > Protecao > Limites Diarios
#define FCV_FLD_DAY_ON           190   // bool
#define FCV_FLD_DAY_TRADES       191   // int
#define FCV_FLD_DAY_LOSS         192   // double(2)
#define FCV_FLD_DAY_GAIN         193   // double(2)
#define FCV_FLD_DAY_ACTION       194   // combo TARGET

//--- Gestao > Protecao > Drawdown
#define FCV_FLD_DD_ON            200   // bool
#define FCV_FLD_DD_MAX           201   // double(2)
#define FCV_FLD_DD_TYPE          202   // combo DDTYPE
#define FCV_FLD_DD_PEAK          203   // combo DDPEAK

//--- Gestao > Protecao > Sequencias. Perda e ganho sao independentes: cada
//--- lado tem chave, limite, acao e pausa proprios.
#define FCV_FLD_LOSS_STREAK_ON   210   // bool
#define FCV_FLD_LOSS_STREAK_MAX  211   // int
#define FCV_FLD_LOSS_STREAK_ACT  212   // combo STREAK
#define FCV_FLD_LOSS_STREAK_PAUSE 213  // int
#define FCV_FLD_WIN_STREAK_ON    214   // bool
#define FCV_FLD_WIN_STREAK_MAX   215   // int
#define FCV_FLD_WIN_STREAK_ACT   216   // combo STREAK
#define FCV_FLD_WIN_STREAK_PAUSE 217   // int

//--- Como o texto de um campo e lido na entrada. Mora aqui, e nao junto da
//--- validacao que o consome, por uma razao de preprocessador: FieldSetText
//--- (CanvasRendererFields.mqh) usa estas macros e e incluido ANTES do
//--- fragmento de validacao — macro, ao contrario de metodo de classe, so
//--- existe depois de definida.
#define FCV_FTYPE_NONE 0
#define FCV_FTYPE_INT  1
#define FCV_FTYPE_DEC  2

#endif
