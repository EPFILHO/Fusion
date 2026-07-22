#ifndef __FUSION_BOLLINGER_FILTER_MQH__
#define __FUSION_BOLLINGER_FILTER_MQH__

#include "../Base/FilterBase.mqh"

class CBollingerFilter : public CFilterBase
  {
private:
   int                       m_handle;
   ENUM_BB_FILTER_WIDTH_MODE m_mode;
   int                       m_period;
   double                    m_deviation;
   ENUM_APPLIED_PRICE        m_price;
   int                       m_minWidthPoints;
   double                    m_minWidthPercent;
   bool                      m_slopeDirectionEnabled;
   int                       m_slopeLookback;
   int                       m_minSlopePoints;

   void              ReleaseHandle(void)
     {
      ReleaseIndicatorHandle(m_handle);
     }

   bool              CreateHandle(void)
     {
      ReleaseHandle();
      m_handle = iBands(m_symbol, m_timeframe, m_period, 0, m_deviation, m_price);
      return (m_handle != INVALID_HANDLE);
     }

   bool              LoadBands(double &middle[],double &upper[],double &lower[])
     {
      int required = m_slopeDirectionEnabled ? (m_slopeLookback + 2) : 2;
      ArrayResize(middle, required);
      ArrayResize(upper, required);
      ArrayResize(lower, required);
      ArraySetAsSeries(middle, true);
      ArraySetAsSeries(upper, true);
      ArraySetAsSeries(lower, true);

      if(CopyBuffer(m_handle, 0, 0, required, middle) < required)
         return false;
      if(CopyBuffer(m_handle, 1, 0, required, upper) < required)
         return false;
      if(CopyBuffer(m_handle, 2, 0, required, lower) < required)
         return false;
      return true;
     }

public:
                     CBollingerFilter(void) : CFilterBase("bb_filter", "Bollinger Filter")
     {
      m_handle = INVALID_HANDLE;
      m_mode = BB_FILTER_WIDTH_ABSOLUTE;
      m_period = 20;
      m_deviation = 2.0;
      m_price = PRICE_CLOSE;
      m_minWidthPoints = 100;
      m_minWidthPercent = 0.20;
      m_slopeDirectionEnabled = false;
      m_slopeLookback = 3;
      m_minSlopePoints = 0;
     }

   virtual bool      Initialize(CLogger *logger,const string symbol) override
     {
      if(!CFilterBase::Initialize(logger, symbol))
         return false;
      if(!m_enabled)
         return true;
      return CreateHandle();
     }

   virtual void      Shutdown(void) override
     {
      ReleaseHandle();
      CFilterBase::Shutdown();
     }

   virtual bool      Reload(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope) override
     {
      m_enabled = settings.bbFilterEnabled;
      m_mode = settings.bbFilterMode;
      m_minWidthPoints = settings.bbFilterMinWidthPoints;
      m_minWidthPercent = settings.bbFilterMinWidthPercent;
      m_slopeDirectionEnabled = settings.bbFilterSlopeDirectionEnabled;
      m_slopeLookback = settings.bbFilterSlopeLookback;
      m_minSlopePoints = settings.bbFilterMinSlopePoints;

      if(scope == RELOAD_HOT && m_initialized)
         return true;

      bool changed = (m_period != settings.bbFilterPeriod ||
                      m_timeframe != settings.bbFilterTimeframe ||
                      MathAbs(m_deviation - settings.bbFilterDeviation) > 0.0000001 ||
                      m_price != settings.bbFilterPrice);

      m_period = settings.bbFilterPeriod;
      m_timeframe = settings.bbFilterTimeframe;
      m_deviation = settings.bbFilterDeviation;
      m_price = settings.bbFilterPrice;

      if(!m_initialized)
         return true;

      if(!m_enabled)
        {
         ReleaseHandle();
         return true;
        }

      if(scope == RELOAD_COLD || scope == RELOAD_WARM || changed || m_handle == INVALID_HANDLE)
         return CreateHandle();

      return true;
     }

   virtual bool      AllowEntry(const ENUM_SIGNAL_TYPE signal,string &reason) override
     {
      reason = "";
      if(!m_enabled || !m_initialized || signal == SIGNAL_NONE)
         return true;
      if(m_handle == INVALID_HANDLE)
        {
         reason = "indicador indisponivel";
         return false;
        }
      if(m_slopeDirectionEnabled &&
         (m_slopeLookback < 1 || m_slopeLookback > 100 || m_minSlopePoints < 0))
        {
         reason = "configuracao de inclinacao invalida";
         return false;
        }

      double middle[];
      double upper[];
      double lower[];
      if(!LoadBands(middle, upper, lower))
        {
         reason = "sem dados suficientes do indicador";
         return false;
        }

      double width = MathMax(0.0, upper[1] - lower[1]);
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      if(point <= 0.0)
        {
         reason = "point do simbolo invalido";
         return false;
        }

      if(m_mode == BB_FILTER_WIDTH_RELATIVE)
        {
         double basis = MathAbs(middle[1]);
         if(basis <= 0.0)
           {
            reason = "linha media invalida para calculo relativo";
            return false;
           }

         double widthPercent = (width / basis) * 100.0;
         if(widthPercent < m_minWidthPercent)
           {
            reason = "largura " + DoubleToString(widthPercent, 2) +
                     "% abaixo do minimo " + DoubleToString(m_minWidthPercent, 2) + "%";
            return false;
           }
        }
      else
        {
         double widthPoints = width / point;
         if(widthPoints < (double)m_minWidthPoints)
           {
            reason = "largura " + DoubleToString(widthPoints, 1) +
                     " pts abaixo do minimo " + IntegerToString(m_minWidthPoints) + " pts";
            return false;
           }
        }

      if(m_slopeDirectionEnabled)
        {
         double slopePointsPerBar = ((middle[1] - middle[1 + m_slopeLookback]) / point) /
                                    (double)m_slopeLookback;
         if(signal == SIGNAL_SELL && slopePointsPerBar > (double)m_minSlopePoints)
           {
            reason = "venda bloqueada: BB ascendente (" +
                     DoubleToString(slopePointsPerBar, 1) + " pts/candle)";
            return false;
           }
         if(signal == SIGNAL_BUY && slopePointsPerBar < -(double)m_minSlopePoints)
           {
            reason = "compra bloqueada: BB descendente (" +
                     DoubleToString(slopePointsPerBar, 1) + " pts/candle)";
            return false;
           }
        }

      return true;
     }
  };

#endif
