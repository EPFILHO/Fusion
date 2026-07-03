#ifndef __FUSION_CHART_INDICATOR_VISUALIZER_MQH__
#define __FUSION_CHART_INDICATOR_VISUALIZER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "IndicatorLegendOverlay.mqh"

#define FUSION_VISUAL_HANDLE_COUNT 7

class CChartIndicatorVisualizer
  {
private:
   CLogger *m_logger;
   long     m_chartId;
   int      m_handles[FUSION_VISUAL_HANDLE_COUNT];
   int      m_windows[FUSION_VISUAL_HANDLE_COUNT];
   string   m_names[FUSION_VISUAL_HANDLE_COUNT];
   string   m_keys[FUSION_VISUAL_HANDLE_COUNT];
   int      m_count;
   int      m_rsiWindow;
   int      m_skippedTimeframes;
   string   m_fingerprint;
   string   m_pendingFingerprint;
   bool     m_rebuildPending;
   int      m_maHandle;
   bool     m_showFastMA;
   bool     m_showSlowMA;
   bool     m_showTrendMA;
   int      m_fastPeriod;
   int      m_slowPeriod;
   int      m_trendPeriod;
   CIndicatorLegendOverlay m_legendOverlay;

   void     ResetEntries(void)
     {
      for(int i = 0; i < FUSION_VISUAL_HANDLE_COUNT; ++i)
        {
         m_handles[i] = INVALID_HANDLE;
         m_windows[i] = -1;
         m_names[i] = "";
         m_keys[i] = "";
        }
      m_count = 0;
      m_rsiWindow = -1;
      m_skippedTimeframes = 0;
      m_maHandle = INVALID_HANDLE;
      m_showFastMA = false;
      m_showSlowMA = false;
      m_showTrendMA = false;
      m_fastPeriod = 0;
      m_slowPeriod = 0;
      m_trendPeriod = 0;
     }

   bool     KeyExists(const string key) const
     {
      for(int i = 0; i < m_count; ++i)
         if(m_keys[i] == key)
            return true;
      return false;
     }

   bool     CompatibleTimeframe(const ENUM_TIMEFRAMES timeframe) const
     {
      return ((int)timeframe == (int)Period());
     }

   string   OwnerSuffix(void) const
     {
      return StringFormat("%I64d", m_chartId);
     }

   bool     IsOwnedVisualName(const string name) const
     {
      string suffix = OwnerSuffix();
      return (StringFind(name, "Fusion Visual MA " + suffix) >= 0 ||
              StringFind(name, "Fusion Visual BB " + suffix) >= 0 ||
              StringFind(name, "Fusion Visual RSI " + suffix) >= 0);
     }

   int      OwnedVisualCount(void) const
     {
      int count = 0;
      int windows = (int)ChartGetInteger(m_chartId, CHART_WINDOWS_TOTAL);
      for(int window = windows - 1; window >= 0; --window)
        {
         int total = ChartIndicatorsTotal(m_chartId, window);
         for(int i = total - 1; i >= 0; --i)
            if(IsOwnedVisualName(ChartIndicatorName(m_chartId, window, i)))
               count++;
        }
      return count;
     }

   bool     OwnedVisualsRemain(void) const
     {
      return (OwnedVisualCount() > 0);
     }

   bool     PurgeOwnedIndicators(void)
     {
      for(int pass = 0; pass < 8; ++pass)
        {
         bool found = false;
         int windows = (int)ChartGetInteger(m_chartId, CHART_WINDOWS_TOTAL);
         for(int window = windows - 1; window >= 0; --window)
           {
            int total = ChartIndicatorsTotal(m_chartId, window);
            for(int i = total - 1; i >= 0; --i)
              {
               string name = ChartIndicatorName(m_chartId, window, i);
               if(!IsOwnedVisualName(name))
                  continue;
               found = true;
               ChartIndicatorDelete(m_chartId, window, name);
              }
           }

         if(!found)
            return true;
         ChartRedraw(m_chartId);
        }

      bool clean = !OwnedVisualsRemain();
      if(!clean && m_logger != NULL)
         m_logger.Warn("VISUAL", "Aguardando limpeza dos indicadores visuais anteriores.");
      return clean;
     }

   int      IndicatorNameCount(const int window,const string name) const
     {
      int count = 0;
      int total = ChartIndicatorsTotal(m_chartId, window);
      for(int i = 0; i < total; ++i)
         if(ChartIndicatorName(m_chartId, window, i) == name)
            count++;
      return count;
     }

   bool     SameIndicatorParameters(const int firstHandle,const int secondHandle) const
     {
      ENUM_INDICATOR firstType;
      ENUM_INDICATOR secondType;
      MqlParam firstParams[];
      MqlParam secondParams[];
      int firstCount = IndicatorParameters(firstHandle, firstType, firstParams);
      int secondCount = IndicatorParameters(secondHandle, secondType, secondParams);
      if(firstCount < 0 || secondCount < 0 || firstType != secondType || firstCount != secondCount)
         return false;

      for(int i = 0; i < firstCount; ++i)
        {
         if(firstParams[i].type != secondParams[i].type ||
            firstParams[i].integer_value != secondParams[i].integer_value ||
            MathAbs(firstParams[i].double_value - secondParams[i].double_value) > 0.000000000001 ||
            firstParams[i].string_value != secondParams[i].string_value)
            return false;
        }
      return true;
     }

   string   FindEquivalentIndicatorName(const int window,const int handle) const
     {
      int total = ChartIndicatorsTotal(m_chartId, window);
      for(int i = 0; i < total; ++i)
        {
         string name = ChartIndicatorName(m_chartId, window, i);
         if(name == "" || IndicatorNameCount(window, name) != 1)
            continue;

         int chartHandle = ChartIndicatorGet(m_chartId, window, name);
         if(chartHandle == INVALID_HANDLE)
            continue;
         bool matches = SameIndicatorParameters(handle, chartHandle);
         IndicatorRelease(chartHandle);
         if(matches)
            return name;
        }
      return "";
     }

   void     ResolveMissingNames(void)
     {
      for(int i = 0; i < m_count; ++i)
         if(m_names[i] == "" && m_handles[i] != INVALID_HANDLE && m_windows[i] >= 0)
            m_names[i] = FindEquivalentIndicatorName(m_windows[i], m_handles[i]);
     }

   bool     AddHandle(const int handle,const int window,const string key,const string expectedName = "")
     {
      if(handle == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Warn("VISUAL", "Nao foi possivel criar um indicador visual.");
         return false;
        }

      if(m_count >= FUSION_VISUAL_HANDLE_COUNT)
        {
         IndicatorRelease(handle);
         return false;
        }

      int previousTotal = ChartIndicatorsTotal(m_chartId, window);
      ResetLastError();
      if(!ChartIndicatorAdd(m_chartId, window, handle))
        {
         int errorCode = GetLastError();
         IndicatorRelease(handle);
         if(m_logger != NULL)
            m_logger.Warn("VISUAL", "Indicador nao exibido no grafico. Erro " + IntegerToString(errorCode) + ".");
         return false;
        }

      m_handles[m_count] = handle;
      m_windows[m_count] = window;
      int currentTotal = ChartIndicatorsTotal(m_chartId, window);
      m_names[m_count] = expectedName;
      if(m_names[m_count] == "" && currentTotal > previousTotal)
         m_names[m_count] = ChartIndicatorName(m_chartId, window, currentTotal - 1);
      if(m_names[m_count] == "")
         m_names[m_count] = FindEquivalentIndicatorName(window, handle);
      m_keys[m_count] = key;
      m_count++;
      return true;
     }

   bool     SameMA(const int firstPeriod,
                   const ENUM_MA_METHOD firstMethod,
                   const ENUM_APPLIED_PRICE firstPrice,
                   const int secondPeriod,
                   const ENUM_MA_METHOD secondMethod,
                   const ENUM_APPLIED_PRICE secondPrice) const
     {
      return (firstPeriod == secondPeriod && firstMethod == secondMethod && firstPrice == secondPrice);
     }

   void     AddMovingAverages(const SEASettings &settings)
     {
      bool showFast = (settings.useMACross && CompatibleTimeframe(settings.maFastTimeframe));
      bool showSlow = (settings.useMACross && CompatibleTimeframe(settings.maSlowTimeframe));
      bool showTrend = (settings.useTrendFilter && CompatibleTimeframe(settings.trendMATimeframe));

      if(settings.useMACross && !showFast)
         m_skippedTimeframes++;
      if(settings.useMACross && !showSlow)
         m_skippedTimeframes++;
      if(settings.useTrendFilter && !showTrend)
         m_skippedTimeframes++;

      if(showSlow && showFast &&
         SameMA(settings.maFastPeriod, settings.maFastMethod, settings.maFastPrice,
                settings.maSlowPeriod, settings.maSlowMethod, settings.maSlowPrice))
         showSlow = false;
      if(showTrend && showFast &&
         SameMA(settings.maFastPeriod, settings.maFastMethod, settings.maFastPrice,
                settings.trendMAPeriod, settings.trendMAMethod, settings.trendMAPrice))
         showTrend = false;
      if(showTrend && showSlow &&
         SameMA(settings.maSlowPeriod, settings.maSlowMethod, settings.maSlowPrice,
                settings.trendMAPeriod, settings.trendMAMethod, settings.trendMAPrice))
         showTrend = false;

      if(!showFast && !showSlow && !showTrend)
         return;

      string shortName = "Fusion Visual MA " + StringFormat("%I64d", m_chartId);
      int handle = iCustom(_Symbol,
                           (ENUM_TIMEFRAMES)Period(),
                           "::VisualIndicators\\FusionVisualMA.ex5",
                           shortName,
                           showFast,
                           settings.maFastPeriod,
                           settings.maFastMethod,
                           settings.maFastPrice,
                           showSlow,
                           settings.maSlowPeriod,
                           settings.maSlowMethod,
                           settings.maSlowPrice,
                           showTrend,
                           settings.trendMAPeriod,
                           settings.trendMAMethod,
                           settings.trendMAPrice);
      if(AddHandle(handle, 0, "FUSION_MA_BUNDLE", shortName))
        {
         m_maHandle = handle;
         m_showFastMA = showFast;
         m_showSlowMA = showSlow;
         m_showTrendMA = showTrend;
         m_fastPeriod = settings.maFastPeriod;
         m_slowPeriod = settings.maSlowPeriod;
         m_trendPeriod = settings.trendMAPeriod;
        }
     }

   void     AddBands(const string key,
                     const int period,
                     const ENUM_TIMEFRAMES timeframe,
                     const double deviation,
                     const ENUM_APPLIED_PRICE price)
     {
      if(KeyExists(key))
         return;
      if(!CompatibleTimeframe(timeframe))
        {
         m_skippedTimeframes++;
         return;
        }

      string shortName = "Fusion Visual BB " + StringFormat("%I64d", m_chartId) +
                         " " + IntegerToString(period) + ":" + DoubleToString(deviation, 4) +
                         ":" + IntegerToString((int)price);
      int handle = iCustom(_Symbol,
                           timeframe,
                           "::VisualIndicators\\FusionVisualBands.ex5",
                           shortName,
                           period,
                           deviation,
                           price);
      AddHandle(handle, 0, key, shortName);
     }

   void     AddRSI(const string key,
                   const int period,
                   const ENUM_TIMEFRAMES timeframe,
                   const ENUM_APPLIED_PRICE price)
     {
      if(KeyExists(key))
         return;
      if(!CompatibleTimeframe(timeframe))
        {
         m_skippedTimeframes++;
         return;
        }

      int window = m_rsiWindow;
      if(window < 0)
         window = (int)ChartGetInteger(m_chartId, CHART_WINDOWS_TOTAL);

      string shortName = "Fusion Visual RSI " + StringFormat("%I64d", m_chartId) +
                         " " + IntegerToString(period) + ":" + IntegerToString((int)price);
      int handle = iCustom(_Symbol,
                           timeframe,
                           "::VisualIndicators\\FusionVisualRSI.ex5",
                           shortName,
                           period,
                           price);
      if(AddHandle(handle, window, key, shortName) && m_rsiWindow < 0)
         m_rsiWindow = window;
     }

   void     RemoveEntry(const int index)
     {
      int handle = m_handles[index];
      int window = m_windows[index];
      string name = m_names[index];
      bool removed = false;

      if(handle != INVALID_HANDLE && window >= 0 && name != "")
        {
         bool owned = IsOwnedVisualName(name);
         if(owned || IndicatorNameCount(window, name) == 1)
            removed = ChartIndicatorDelete(m_chartId, window, name);
        }

      if(!removed && handle != INVALID_HANDLE && name != "" && m_logger != NULL)
         m_logger.Debug("VISUAL", "Indicador visual sera removido pela varredura de propriedade: " + name);

      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
     }

   string   LegacyLegendName(const string role) const
     {
      return "Fusion_visual_ma_" + role + "_" + StringFormat("%I64d", m_chartId);
     }

   void     DeleteLegacyLegend(void)
     {
      ObjectDelete(m_chartId, LegacyLegendName("background"));
      ObjectDelete(m_chartId, LegacyLegendName("fast"));
      ObjectDelete(m_chartId, LegacyLegendName("slow"));
      ObjectDelete(m_chartId, LegacyLegendName("trend"));
     }

   bool     EnsureLegendOverlay(void)
     {
      if(m_legendOverlay.IsCreated())
         return true;

      if(!m_legendOverlay.CreateLegend(m_chartId, 0, FUSION_LEGEND_TOP))
         return false;
      if(!m_legendOverlay.StartDialog())
        {
         m_legendOverlay.Destroy(REASON_REMOVE);
         return false;
        }
      return true;
     }

   string   LegendValue(const int bufferIndex) const
     {
      string valueText = "--";
      double value[];
      ArrayResize(value, 1);
      if(m_maHandle != INVALID_HANDLE && CopyBuffer(m_maHandle, bufferIndex, 0, 1, value) == 1 && value[0] != EMPTY_VALUE)
         valueText = DoubleToString(value[0], (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
      return valueText;
     }

   string   ShortTimeframe(const ENUM_TIMEFRAMES timeframe) const
     {
      string text = EnumToString(timeframe);
      if(StringFind(text, "PERIOD_") == 0)
         return StringSubstr(text, 7);
      return text;
     }

   string   MALegendText(const string label,
                         const bool configured,
                         const ENUM_TIMEFRAMES timeframe,
                         const int period,
                         const bool visible,
                         const int bufferIndex,
                         const string sharedWith = "") const
     {
      if(!configured)
         return label + " OFF";
      if(!CompatibleTimeframe(timeframe))
         return label + " " + ShortTimeframe(timeframe) + " (outro TF)";
      if(sharedWith != "")
         return label + " (" + IntegerToString(period) + "): igual a " + sharedWith;
      if(!visible || m_maHandle == INVALID_HANDLE)
         return label + " (" + IntegerToString(period) + "): aguardando";
      return label + " (" + IntegerToString(period) + "): " + LegendValue(bufferIndex);
     }

   void     UpdateLegend(const SEASettings &settings)
     {
      DeleteLegacyLegend();
      if(!EnsureLegendOverlay())
         return;

      bool fastConfigured = settings.useMACross;
      bool slowConfigured = settings.useMACross;
      bool trendConfigured = settings.useTrendFilter;
      string slowShared = "";
      string trendShared = "";

      if(fastConfigured && slowConfigured &&
         CompatibleTimeframe(settings.maFastTimeframe) &&
         CompatibleTimeframe(settings.maSlowTimeframe) &&
         SameMA(settings.maFastPeriod, settings.maFastMethod, settings.maFastPrice,
                settings.maSlowPeriod, settings.maSlowMethod, settings.maSlowPrice))
         slowShared = "Rapida";

      if(trendConfigured && CompatibleTimeframe(settings.trendMATimeframe))
        {
         if(fastConfigured && CompatibleTimeframe(settings.maFastTimeframe) &&
            SameMA(settings.trendMAPeriod, settings.trendMAMethod, settings.trendMAPrice,
                   settings.maFastPeriod, settings.maFastMethod, settings.maFastPrice))
            trendShared = "Rapida";
         else if(slowConfigured && CompatibleTimeframe(settings.maSlowTimeframe) &&
                 SameMA(settings.trendMAPeriod, settings.trendMAMethod, settings.trendMAPrice,
                        settings.maSlowPeriod, settings.maSlowMethod, settings.maSlowPrice))
            trendShared = "Lenta";
        }

      m_legendOverlay.Update(MALegendText("MA Rapida",
                                         fastConfigured,
                                         settings.maFastTimeframe,
                                         settings.maFastPeriod,
                                         m_showFastMA,
                                         0),
                            MALegendText("MA Lenta",
                                         slowConfigured,
                                         settings.maSlowTimeframe,
                                         settings.maSlowPeriod,
                                         m_showSlowMA,
                                         1,
                                         slowShared),
                            MALegendText("MA Trend",
                                         trendConfigured,
                                         settings.trendMATimeframe,
                                         settings.trendMAPeriod,
                                         m_showTrendMA,
                                         2,
                                         trendShared));
     }

   void     ClearIndicators(void)
     {
      ResolveMissingNames();
      for(int i = m_count - 1; i >= 0; --i)
         RemoveEntry(i);
      ResetEntries();
      ChartRedraw(m_chartId);
     }

   bool     NeedsMAVisual(const SEASettings &settings) const
     {
      return ((settings.useMACross &&
               (CompatibleTimeframe(settings.maFastTimeframe) ||
                CompatibleTimeframe(settings.maSlowTimeframe))) ||
              (settings.useTrendFilter && CompatibleTimeframe(settings.trendMATimeframe)));
     }

   string   BuildFingerprint(const SEASettings &settings) const
     {
      return StringFormat("%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%.8f|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%.8f|%d",
                          (int)settings.showChartIndicators,
                          (int)Period(),
                          (int)settings.useMACross,
                          settings.maFastPeriod,
                          (int)settings.maFastTimeframe,
                          (int)settings.maFastMethod,
                          (int)settings.maFastPrice,
                          settings.maSlowPeriod,
                          (int)settings.maSlowTimeframe,
                          (int)settings.maSlowMethod,
                          (int)settings.maSlowPrice,
                          (int)settings.useRSI,
                          settings.rsiPeriod,
                          (int)settings.rsiTimeframe,
                          (int)settings.rsiPrice,
                          settings.bbDeviation,
                          (int)settings.useBollinger,
                          settings.bbPeriod,
                          (int)settings.bbTimeframe,
                          (int)settings.bbPrice,
                          (int)settings.useTrendFilter,
                          settings.trendMAPeriod,
                          (int)settings.trendMATimeframe,
                          (int)settings.trendMAMethod,
                          (int)settings.trendMAPrice,
                          (int)settings.useRSIFilter,
                          settings.bbFilterDeviation,
                          (int)settings.bbFilterEnabled) +
             StringFormat("|%d|%d|%d|%d|%d|%d|%d|%d",
                          settings.rsiFilterPeriod,
                          (int)settings.rsiFilterTimeframe,
                          (int)settings.rsiFilterPrice,
                          settings.bbFilterPeriod,
                          (int)settings.bbFilterTimeframe,
                          (int)settings.bbFilterPrice,
                          (int)ChartID(),
                          (int)m_chartId);
     }

   string   BandsKey(const int period,
                     const ENUM_TIMEFRAMES timeframe,
                     const double deviation,
                     const ENUM_APPLIED_PRICE price) const
     {
      return StringFormat("BB:%d:%d:%.8f:%d", period, (int)timeframe, deviation, (int)price);
     }

   string   RSIKey(const int period,
                   const ENUM_TIMEFRAMES timeframe,
                   const ENUM_APPLIED_PRICE price) const
     {
      return StringFormat("RSI:%d:%d:%d", period, (int)timeframe, (int)price);
     }

   void     AddConfiguredVisuals(const SEASettings &settings)
     {
      AddMovingAverages(settings);

      if(settings.useBollinger)
         AddBands(BandsKey(settings.bbPeriod, settings.bbTimeframe, settings.bbDeviation, settings.bbPrice),
                  settings.bbPeriod, settings.bbTimeframe, settings.bbDeviation, settings.bbPrice);
      if(settings.bbFilterEnabled)
         AddBands(BandsKey(settings.bbFilterPeriod, settings.bbFilterTimeframe, settings.bbFilterDeviation, settings.bbFilterPrice),
                  settings.bbFilterPeriod, settings.bbFilterTimeframe, settings.bbFilterDeviation, settings.bbFilterPrice);

      if(settings.useRSI)
         AddRSI(RSIKey(settings.rsiPeriod, settings.rsiTimeframe, settings.rsiPrice),
                settings.rsiPeriod, settings.rsiTimeframe, settings.rsiPrice);
      if(settings.useRSIFilter)
         AddRSI(RSIKey(settings.rsiFilterPeriod, settings.rsiFilterTimeframe, settings.rsiFilterPrice),
                settings.rsiFilterPeriod, settings.rsiFilterTimeframe, settings.rsiFilterPrice);
     }

   bool     DesiredVisualsReady(const SEASettings &settings) const
     {
      if(NeedsMAVisual(settings) && !KeyExists("FUSION_MA_BUNDLE"))
         return false;
      if(settings.useBollinger && CompatibleTimeframe(settings.bbTimeframe) &&
         !KeyExists(BandsKey(settings.bbPeriod, settings.bbTimeframe, settings.bbDeviation, settings.bbPrice)))
         return false;
      if(settings.bbFilterEnabled && CompatibleTimeframe(settings.bbFilterTimeframe) &&
         !KeyExists(BandsKey(settings.bbFilterPeriod, settings.bbFilterTimeframe, settings.bbFilterDeviation, settings.bbFilterPrice)))
         return false;
      if(settings.useRSI && CompatibleTimeframe(settings.rsiTimeframe) &&
         !KeyExists(RSIKey(settings.rsiPeriod, settings.rsiTimeframe, settings.rsiPrice)))
         return false;
      if(settings.useRSIFilter && CompatibleTimeframe(settings.rsiFilterTimeframe) &&
         !KeyExists(RSIKey(settings.rsiFilterPeriod, settings.rsiFilterTimeframe, settings.rsiFilterPrice)))
         return false;
      return true;
     }

   void     BeginRebuild(const string fingerprint)
     {
      ClearIndicators();
      PurgeOwnedIndicators();
      m_pendingFingerprint = fingerprint;
      m_rebuildPending = true;
      m_fingerprint = "";
     }

   void     LogVisualSummary(void)
     {
      if(m_logger == NULL)
         return;
      string message = IntegerToString(m_count) + " indicador(es) exibido(s) no grafico.";
      if(m_skippedTimeframes > 0)
         message += " " + IntegerToString(m_skippedTimeframes) + " omitido(s) por TF diferente.";
      m_logger.Info("VISUAL", message);
     }

public:
            CChartIndicatorVisualizer(void)
     {
      m_logger = NULL;
      m_chartId = 0;
      m_fingerprint = "";
      m_pendingFingerprint = "";
      m_rebuildPending = false;
      ResetEntries();
     }

   void     Init(CLogger *logger,const long chartId)
     {
      m_logger = logger;
      m_chartId = chartId;
      m_fingerprint = "";
      m_pendingFingerprint = "";
      m_rebuildPending = false;
      ResetEntries();
      DeleteLegacyLegend();
      PurgeOwnedIndicators();
     }

   void     Sync(const SEASettings &settings)
     {
      ResolveMissingNames();
      string fingerprint = BuildFingerprint(settings);
      if(!settings.showChartIndicators)
        {
         if(m_count > 0 || m_rebuildPending || OwnedVisualsRemain())
           {
            ClearIndicators();
            PurgeOwnedIndicators();
           }
         m_fingerprint = fingerprint;
         m_pendingFingerprint = "";
         m_rebuildPending = false;
         m_legendOverlay.Destroy(REASON_REMOVE);
         DeleteLegacyLegend();
         return;
        }

      if(m_rebuildPending)
        {
         if(fingerprint != m_pendingFingerprint)
           {
            BeginRebuild(fingerprint);
            UpdateLegend(settings);
            return;
           }

         if(!PurgeOwnedIndicators())
           {
            UpdateLegend(settings);
            return;
           }

         AddConfiguredVisuals(settings);
         if(!DesiredVisualsReady(settings))
           {
            BeginRebuild(fingerprint);
            UpdateLegend(settings);
            return;
           }

         m_fingerprint = fingerprint;
         m_pendingFingerprint = "";
         m_rebuildPending = false;
         ChartRedraw(m_chartId);
         UpdateLegend(settings);
         LogVisualSummary();
         return;
        }

      if(fingerprint != m_fingerprint ||
         !DesiredVisualsReady(settings) ||
         OwnedVisualCount() != m_count)
        {
         BeginRebuild(fingerprint);
         UpdateLegend(settings);
         return;
        }

      UpdateLegend(settings);
     }

   void     OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(m_legendOverlay.IsCreated())
         m_legendOverlay.ChartEvent(id, lparam, dparam, sparam);
     }

   void     Shutdown(const int reason)
     {
      ResolveMissingNames();
      m_legendOverlay.Destroy(reason);
      DeleteLegacyLegend();
      ClearIndicators();
      PurgeOwnedIndicators();
      m_fingerprint = "";
      m_pendingFingerprint = "";
      m_rebuildPending = false;
      m_logger = NULL;
     }
  };

#endif
