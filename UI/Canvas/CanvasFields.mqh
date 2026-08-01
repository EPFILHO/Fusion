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

#endif
