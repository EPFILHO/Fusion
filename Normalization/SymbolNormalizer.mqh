#ifndef __MODULAR_EA_SYMBOL_NORMALIZER_MQH__
#define __MODULAR_EA_SYMBOL_NORMALIZER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"

class CSymbolNormalizer
  {
private:
   CLogger     *m_logger;
   SSymbolSpec  m_spec;

   int          VolumeDigits(const double step) const
     {
      double value = step;
      int    digits = 0;

      while(digits < 8 && MathAbs(value - MathRound(value)) > 0.0000001)
        {
         value *= 10.0;
         digits++;
        }

      return digits;
     }

public:
                     CSymbolNormalizer(void)
     {
      m_logger = NULL;
      m_spec.symbol = "";
      m_spec.digits = 0;
      m_spec.point = 0.0;
      m_spec.tickSize = 0.0;
      m_spec.tickValue = 0.0;
      m_spec.volumeMin = 0.0;
      m_spec.volumeMax = 0.0;
      m_spec.volumeStep = 0.0;
      m_spec.stopsLevel = 0;
      m_spec.freezeLevel = 0;
      m_spec.fillingMode = 0;
     }

   bool              Init(CLogger *logger,const string symbol)
     {
      m_logger = logger;
      m_spec.symbol     = symbol;
      m_spec.digits     = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      m_spec.point      = SymbolInfoDouble(symbol, SYMBOL_POINT);
      m_spec.tickSize   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      m_spec.tickValue  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      m_spec.volumeMin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      m_spec.volumeMax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      m_spec.volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      m_spec.stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      m_spec.freezeLevel= (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      m_spec.fillingMode= SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
      return true;
     }

   double            NormalizePrice(const double price) const
     {
      return NormalizeDouble(price, m_spec.digits);
     }

   double            NormalizeVolume(const double volume) const
     {
      if(m_spec.volumeStep <= 0.0)
         return volume;

      double adjusted = MathRound(volume / m_spec.volumeStep) * m_spec.volumeStep;
      adjusted = MathMax(m_spec.volumeMin, adjusted);
      adjusted = MathMin(m_spec.volumeMax, adjusted);
      return NormalizeDouble(adjusted, VolumeDigits(m_spec.volumeStep));
     }

   ENUM_ORDER_TYPE_FILLING ResolveFillingMode(void) const
     {
      if((m_spec.fillingMode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      if((m_spec.fillingMode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
         return ORDER_FILLING_FOK;
      return ORDER_FILLING_RETURN;
     }

   void              GetSpec(SSymbolSpec &outSpec) const
     {
      outSpec = m_spec;
     }
  };

#endif

