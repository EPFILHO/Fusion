#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO/Fusion"
#property version   "2.000"
//--- Aba Comum das Propriedades. Tem de ficar no modulo principal: #property
//--- description dentro de include nao chega ao dialogo.
#property description "Indicador exclusivamente visual."
#property description "Alterações nesta janela afetam somente a exibição no gráfico."
#property description "Não alteram estratégias, filtros, perfis ou operações do Fusion."
#property description "O Identificador interno é reservado ao Fusion e não deve ser alterado."
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- ⚠ CONTRATO POSICIONAL. O Fusion anexa este indicador por iCustom
//--- (UI/ChartIndicatorVisualizer.mqh), que passa os 9 argumentos por POSICAO e
//--- nunca por nome. Ordem, tipo e quantidade sao o contrato; o
//--- input(name="...") e so o rotulo do dialogo e nao entra nele.
//---
//--- Os cinco niveis sao posicoes fixas e o Fusion preenche quantas precisar; o
//--- OnInit so desenha os primeiros "Niveis exibidos". Um valor deixado num
//--- nivel acima da contagem fica dormente, e por isso o rotulo diz de onde
//--- vem o corte.
input(name="Identificador interno (não alterar)")      string             InpShortName = "Fusion Visual RSI";
input(name="Período do RSI")                 int                InpPeriod = 14;
input(name="Preço do RSI")                   ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE;
input(name="Níveis exibidos (0 a 5)")        int                InpLevelCount = 0;
input(name="Nível 1 (0 a 100)")              int                InpLevel1 = 0;
input(name="Nível 2 (0 a 100)")              int                InpLevel2 = 0;
input(name="Nível 3 (0 a 100)")              int                InpLevel3 = 0;
input(name="Nível 4 (0 a 100)")              int                InpLevel4 = 0;
input(name="Nível 5 (0 a 100)")              int                InpLevel5 = 0;

double RSIBuffer[];
int    RSIHandle = INVALID_HANDLE;

void ReleaseRSIHandle(void)
  {
   if(RSIHandle == INVALID_HANDLE)
      return;
   IndicatorRelease(RSIHandle);
   RSIHandle = INVALID_HANDLE;
  }

int OnInit(void)
  {
   SetIndexBuffer(0, RSIBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(0, InpPeriod));
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   IndicatorSetDouble(INDICATOR_MINIMUM, 0.0);
   IndicatorSetDouble(INDICATOR_MAXIMUM, 100.0);
   IndicatorSetString(INDICATOR_SHORTNAME, InpShortName);

   int levelCount = MathMax(0, MathMin(InpLevelCount, 5));
   int levels[5];
   levels[0] = InpLevel1;
   levels[1] = InpLevel2;
   levels[2] = InpLevel3;
   levels[3] = InpLevel4;
   levels[4] = InpLevel5;
   IndicatorSetInteger(INDICATOR_LEVELS, levelCount);
   for(int i = 0; i < levelCount; ++i)
     {
      IndicatorSetDouble(INDICATOR_LEVELVALUE, i, (double)levels[i]);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR, i, clrSilver);
      IndicatorSetInteger(INDICATOR_LEVELSTYLE, i, STYLE_DOT);
      IndicatorSetInteger(INDICATOR_LEVELWIDTH, i, 1);
      IndicatorSetString(INDICATOR_LEVELTEXT, i, IntegerToString(levels[i]));
     }

   RSIHandle = iRSI(_Symbol, _Period, InpPeriod, InpPrice);
   if(RSIHandle == INVALID_HANDLE)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ReleaseRSIHandle();
  }

int OnCalculate(const int ratesTotal,
                const int prevCalculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickVolume[],
                const long &volume[],
                const int &spread[])
  {
   if(BarsCalculated(RSIHandle) < ratesTotal)
      return prevCalculated;

   int toCopy = ratesTotal;
   if(prevCalculated >= 0 && prevCalculated <= ratesTotal)
     {
      toCopy = ratesTotal - prevCalculated;
      if(prevCalculated > 0)
         toCopy++;
     }

   if(CopyBuffer(RSIHandle, 0, 0, toCopy, RSIBuffer) <= 0)
      return prevCalculated;
   return ratesTotal;
  }
