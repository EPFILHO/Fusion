//+------------------------------------------------------------------+
//| CanvasRendererFields.mqh                                          |
//| Fragmento do corpo de CFusionCanvasRenderer — a ponte entre os    |
//| controles da tela e o rascunho de SEASettings.                    |
//|                                                                   |
//| O rascunho segue a regra da 1.058: o snapshot do EA so sobrescreve|
//| o que o usuario NAO esta editando. Com pendencia, o que foi       |
//| digitado permanece ate SALVAR ou CANCELAR.                        |
//|                                                                   |
//| Conversoes combo<->enum conferidas contra Core/Types.mqh:         |
//| CONFLICT/ENTRY/EXIT/RSIEXIT/RSIMODE/BBMODE/METHOD sao 0-based na  |
//| MESMA ordem dos combos; PRICE e 1-based (PRICE_CLOSE=1); TF usa a |
//| tabela abaixo.                                                    |
//+------------------------------------------------------------------+

//--- Os 21 timeframes, na ordem do combo. Mesma lista de Core/Inputs.mqh.
ENUM_TIMEFRAMES TfFromIndex(const int idx)
  {
   static ENUM_TIMEFRAMES tfs[21]=
     { PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,
       PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,
       PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1 };
   if(idx<0 || idx>=21) return PERIOD_M1;
   return tfs[idx];
  }

int TfToIndex(const ENUM_TIMEFRAMES tf)
  {
   for(int i=0;i<21;++i)
      if(TfFromIndex(i)==tf) return i;
   return 0;
  }

//+------------------------------------------------------------------+
//| Leitura: switches planos, um caso por campo, auditaveis contra o  |
//| struct. Chato de escrever e facil de conferir — a troca certa     |
//| para codigo que decide o que o usuario ve.                        |
//+------------------------------------------------------------------+
bool FieldGetBool(const int fid)
  {
   switch(fid)
     {
      case FCV_FLD_USE_MACROSS: return m_draft.useMACross;
      case FCV_FLD_USE_RSI:     return m_draft.useRSI;
      case FCV_FLD_USE_BB:      return m_draft.useBollinger;
      case FCV_FLD_USE_TREND:   return m_draft.useTrendFilter;
      case FCV_FLD_USE_RSIF:    return m_draft.useRSIFilter;
      case FCV_FLD_USE_BBF:     return m_draft.bbFilterEnabled;
      case FCV_FLD_TR_MA1_ON:   return m_draft.trendMA1Enabled;
      case FCV_FLD_TR_MA2_ON:   return m_draft.trendMA2Enabled;
      case FCV_FLD_BF_SLOPE_ON: return m_draft.bbFilterSlopeDirectionEnabled;
     }
   return false;
  }

void FieldToggleBool(const int fid)
  {
   switch(fid)
     {
      case FCV_FLD_USE_MACROSS: m_draft.useMACross =!m_draft.useMACross;  break;
      case FCV_FLD_USE_RSI:     m_draft.useRSI     =!m_draft.useRSI;      break;
      case FCV_FLD_USE_BB:      m_draft.useBollinger=!m_draft.useBollinger; break;
      case FCV_FLD_USE_RSIF:    m_draft.useRSIFilter    =!m_draft.useRSIFilter;    break;
      case FCV_FLD_USE_BBF:     m_draft.bbFilterEnabled =!m_draft.bbFilterEnabled; break;
      case FCV_FLD_TR_MA1_ON:   m_draft.trendMA1Enabled =!m_draft.trendMA1Enabled; break;
      case FCV_FLD_TR_MA2_ON:   m_draft.trendMA2Enabled =!m_draft.trendMA2Enabled; break;
      case FCV_FLD_BF_SLOPE_ON:
         m_draft.bbFilterSlopeDirectionEnabled=!m_draft.bbFilterSlopeDirectionEnabled; break;
      default: return;
     }
   SyncDerivedSettings();
  }

//--- useTrendFilter NAO e uma chave: e resumo das duas medias, recalculado.
//--- A 1.058 refaz esta conta em tres lugares (Inputs, TrendFilterPanel e o
//--- rascunho do painel). Tratado como campo editavel, ele divergia do que as
//--- medias diziam — era o "Tendencia do Geral nao acompanha" observado.
//--- E o unico derivado do struct; todos os outros sao chaves de verdade.
void SyncDerivedSettings(void)
  { m_draft.useTrendFilter=(m_draft.trendMA1Enabled || m_draft.trendMA2Enabled); }

//+------------------------------------------------------------------+
//| Ha alteracao pendente?                                            |
//|                                                                   |
//| Pela DIFERENCA real entre rascunho e comprometido, nao por uma     |
//| marca ligada em cada interacao. Marcar na interacao acusava        |
//| mudanca onde nao houve — entrar num campo e sair sem digitar,      |
//| alternar uma chave duas vezes, reescolher a mesma opcao — e com o  |
//| INICIAR dependendo de nao haver pendencia, isso deixou de ser      |
//| cosmetico: bloqueava a operacao sem causa visivel.                 |
//|                                                                   |
//| m_dirty sobrevive apenas para os controles ainda NAO ligados a     |
//| SEASettings (Gestao, Perfis, Layout). Cada tela ligada o aposenta. |
//+------------------------------------------------------------------+
//--- O texto publicado pelo objeto ja diverge do que gravamos nele?
//---
//--- IMPORTANTE, para nao criar expectativa errada: isto NAO detecta digitacao
//--- em curso. O terminal so atualiza o buffer do OBJ_EDIT quando a edicao
//--- termina, entao durante a digitacao a consulta devolve o texto anterior e
//--- esta funcao fica quieta. Quem cobre a edicao em curso e EditingNow(), que
//--- se apoia no unico sinal disponivel: haver um campo com foco.
//---
//--- Fica como rede de seguranca. Ela pega o caso em que o terminal publicou um
//--- texto sem que tenhamos absorvido — um ENDEDIT perdido, ou uma versao que
//--- passe a atualizar o buffer antes do fim. Custa um laco curto e evita que
//--- uma alteracao real passe despercebida.
//---
//--- Aqui so LEMOS. O rascunho continua sendo escrito apenas na confirmacao,
//--- para nao normalizar o numero por baixo do cursor durante a digitacao.
//--- A comparacao e contra O QUE NOS ESCREVEMOS no objeto, nunca contra o
//--- rascunho. As duas divergem por motivos OPOSTOS, e so esta distingue:
//---
//---   objeto != o que escrevemos  -> o USUARIO digitou. E pendencia.
//---   objeto != rascunho          -> o RASCUNHO mudou (CANCELAR, snapshot) e
//---                                  o BuildEdits vai reescrever o objeto
//---                                  ainda neste quadro. NAO e pendencia.
//---
//--- Comparar com o rascunho misturava os dois casos, e o desenho acontece
//--- ANTES do BuildEdits: no quadro do CANCELAR o painel ainda via o texto
//--- velho no objeto, concluia "ha pendencia" e desenhava os botoes acesos —
//--- embora o cancelamento ja tivesse ocorrido. Era por isso que o CANCELAR
//--- precisava de dois cliques: o primeiro cancelava e desenhava errado, o
//--- segundo so consertava o desenho.
bool EditTextOutOfSync(void)
  {
   for(int k=0;k<m_liveEditCount;++k)
     {
      if(m_liveEditFid[k]==FCV_FLD_NONE) continue;    // slot local: ver m_dirty
      if(ObjectFind(m_chart,m_liveEditName[k])<0) continue;
      if(ObjectGetString(m_chart,m_liveEditName[k],OBJPROP_TEXT)!=m_liveEditText[k])
         return true;
     }
   return false;
  }

bool HasPending(void)
  { return (m_dirty || EditTextOutOfSync() || !FusionSettingsEqual(m_draft,m_committed)); }

int FieldGetIndex(const int fid)
  {
   switch(fid)
     {
      case FCV_FLD_CONFLICT:       return (int)m_draft.conflictMode;
      case FCV_FLD_MA_FAST_TF:     return TfToIndex(m_draft.maFastTimeframe);
      case FCV_FLD_MA_FAST_METHOD: return (int)m_draft.maFastMethod;
      case FCV_FLD_MA_FAST_PRICE:  return (int)m_draft.maFastPrice-1;
      case FCV_FLD_MA_SLOW_TF:     return TfToIndex(m_draft.maSlowTimeframe);
      case FCV_FLD_MA_SLOW_METHOD: return (int)m_draft.maSlowMethod;
      case FCV_FLD_MA_SLOW_PRICE:  return (int)m_draft.maSlowPrice-1;
      case FCV_FLD_MA_ENTRY_MODE:  return (int)m_draft.maEntryMode;
      case FCV_FLD_MA_EXIT_MODE:   return (int)m_draft.maExitMode;
      case FCV_FLD_RSI_TF:         return TfToIndex(m_draft.rsiTimeframe);
      case FCV_FLD_RSI_PRICE:      return (int)m_draft.rsiPrice-1;
      case FCV_FLD_RSI_MODE:       return (int)m_draft.rsiMode;
      case FCV_FLD_RSI_EXIT_MODE:  return (int)m_draft.rsiExitMode;
      case FCV_FLD_BB_TF:          return TfToIndex(m_draft.bbTimeframe);
      case FCV_FLD_BB_PRICE:       return (int)m_draft.bbPrice-1;
      case FCV_FLD_BB_MODE:        return (int)m_draft.bbMode;
      case FCV_FLD_BB_EXIT_MODE:   return (int)m_draft.bbExitMode;
      case FCV_FLD_TR_MA1_TF:      return TfToIndex(m_draft.trendMATimeframe);
      case FCV_FLD_TR_MA1_METHOD:  return (int)m_draft.trendMAMethod;
      case FCV_FLD_TR_MA1_PRICE:   return (int)m_draft.trendMAPrice-1;
      case FCV_FLD_TR_MA2_TF:      return TfToIndex(m_draft.trendSellMATimeframe);
      case FCV_FLD_TR_MA2_METHOD:  return (int)m_draft.trendSellMAMethod;
      case FCV_FLD_TR_MA2_PRICE:   return (int)m_draft.trendSellMAPrice-1;
      case FCV_FLD_RF_TF:          return TfToIndex(m_draft.rsiFilterTimeframe);
      case FCV_FLD_RF_PRICE:       return (int)m_draft.rsiFilterPrice-1;
      case FCV_FLD_RF_MODE:        return (int)m_draft.rsiFilterMode;
      case FCV_FLD_BF_TF:          return TfToIndex(m_draft.bbFilterTimeframe);
      case FCV_FLD_BF_PRICE:       return (int)m_draft.bbFilterPrice-1;
      case FCV_FLD_BF_MODE:        return (int)m_draft.bbFilterMode;
     }
   return 0;
  }

void FieldSetIndex(const int fid,const int idx)
  {
   switch(fid)
     {
      case FCV_FLD_CONFLICT:       m_draft.conflictMode=(ENUM_CONFLICT_RESOLUTION)idx; break;
      case FCV_FLD_MA_FAST_TF:     m_draft.maFastTimeframe=TfFromIndex(idx);   break;
      case FCV_FLD_MA_FAST_METHOD: m_draft.maFastMethod=(ENUM_MA_METHOD)idx;   break;
      case FCV_FLD_MA_FAST_PRICE:  m_draft.maFastPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_MA_SLOW_TF:     m_draft.maSlowTimeframe=TfFromIndex(idx);   break;
      case FCV_FLD_MA_SLOW_METHOD: m_draft.maSlowMethod=(ENUM_MA_METHOD)idx;   break;
      case FCV_FLD_MA_SLOW_PRICE:  m_draft.maSlowPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_MA_ENTRY_MODE:  m_draft.maEntryMode=(ENUM_ENTRY_MODE)idx;   break;
      case FCV_FLD_MA_EXIT_MODE:   m_draft.maExitMode=(ENUM_EXIT_MODE)idx;     break;
      case FCV_FLD_RSI_TF:         m_draft.rsiTimeframe=TfFromIndex(idx);      break;
      case FCV_FLD_RSI_PRICE:      m_draft.rsiPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_RSI_MODE:       m_draft.rsiMode=(ENUM_RSI_SIGNAL_MODE)idx;  break;
      case FCV_FLD_RSI_EXIT_MODE:  m_draft.rsiExitMode=(ENUM_RSI_EXIT_MODE)idx; break;
      case FCV_FLD_BB_TF:          m_draft.bbTimeframe=TfFromIndex(idx);       break;
      case FCV_FLD_BB_PRICE:       m_draft.bbPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_BB_MODE:        m_draft.bbMode=(ENUM_BB_SIGNAL_MODE)idx;    break;
      case FCV_FLD_BB_EXIT_MODE:   m_draft.bbExitMode=(ENUM_EXIT_MODE)idx;     break;
      case FCV_FLD_TR_MA1_TF:      m_draft.trendMATimeframe=TfFromIndex(idx);  break;
      case FCV_FLD_TR_MA1_METHOD:  m_draft.trendMAMethod=(ENUM_MA_METHOD)idx;  break;
      case FCV_FLD_TR_MA1_PRICE:   m_draft.trendMAPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_TR_MA2_TF:      m_draft.trendSellMATimeframe=TfFromIndex(idx); break;
      case FCV_FLD_TR_MA2_METHOD:  m_draft.trendSellMAMethod=(ENUM_MA_METHOD)idx; break;
      case FCV_FLD_TR_MA2_PRICE:   m_draft.trendSellMAPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_RF_TF:          m_draft.rsiFilterTimeframe=TfFromIndex(idx); break;
      case FCV_FLD_RF_PRICE:       m_draft.rsiFilterPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_RF_MODE:        m_draft.rsiFilterMode=(ENUM_RSI_FILTER_MODE)idx; break;
      case FCV_FLD_BF_TF:          m_draft.bbFilterTimeframe=TfFromIndex(idx); break;
      case FCV_FLD_BF_PRICE:       m_draft.bbFilterPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_BF_MODE:        m_draft.bbFilterMode=(ENUM_BB_FILTER_WIDTH_MODE)idx; break;
      default: return;
     }
  }

string FieldGetText(const int fid)
  {
   switch(fid)
     {
      case FCV_FLD_MA_PRIORITY:    return IntegerToString(m_draft.maCrossPriority);
      case FCV_FLD_MA_FAST_PERIOD: return IntegerToString(m_draft.maFastPeriod);
      case FCV_FLD_MA_SLOW_PERIOD: return IntegerToString(m_draft.maSlowPeriod);
      case FCV_FLD_MA_MIN_DIST:    return IntegerToString(m_draft.maMinDistancePoints);
      case FCV_FLD_RSI_PRIORITY:   return IntegerToString(m_draft.rsiPriority);
      case FCV_FLD_RSI_PERIOD:     return IntegerToString(m_draft.rsiPeriod);
      case FCV_FLD_RSI_OVERSOLD:   return IntegerToString(m_draft.rsiOversold);
      case FCV_FLD_RSI_OVERBOUGHT: return IntegerToString(m_draft.rsiOverbought);
      case FCV_FLD_RSI_MIDDLE:     return IntegerToString(m_draft.rsiMiddle);
      case FCV_FLD_BB_PRIORITY:    return IntegerToString(m_draft.bbPriority);
      case FCV_FLD_BB_PERIOD:      return IntegerToString(m_draft.bbPeriod);
      case FCV_FLD_BB_DEVIATION:   return DoubleToString(m_draft.bbDeviation,2);
      case FCV_FLD_TR_MA1_PERIOD:  return IntegerToString(m_draft.trendMAPeriod);
      case FCV_FLD_TR_MA2_PERIOD:  return IntegerToString(m_draft.trendSellMAPeriod);
      case FCV_FLD_RF_PERIOD:      return IntegerToString(m_draft.rsiFilterPeriod);
      case FCV_FLD_RF_BUYMIN:      return IntegerToString(m_draft.rsiFilterBuyMin);
      case FCV_FLD_RF_SELLMAX:     return IntegerToString(m_draft.rsiFilterSellMax);
      case FCV_FLD_BF_PERIOD:      return IntegerToString(m_draft.bbFilterPeriod);
      case FCV_FLD_BF_DEV:         return DoubleToString(m_draft.bbFilterDeviation,2);
      case FCV_FLD_BF_MINPTS:      return IntegerToString(m_draft.bbFilterMinWidthPoints);
      case FCV_FLD_BF_MINPCT:      return DoubleToString(m_draft.bbFilterMinWidthPercent,2);
      case FCV_FLD_BF_SLOPE_BACK:  return IntegerToString(m_draft.bbFilterSlopeLookback);
      case FCV_FLD_BF_SLOPE_MINPTS:return IntegerToString(m_draft.bbFilterMinSlopePoints);
     }
   return "";
  }

//--- Texto digitado -> rascunho. Parse minimo por enquanto: as regras de
//--- faixa e as cruzadas (sobrevenda < sobrecompra...) entram na Etapa 2d,
//--- que e a camada de validacao. Ate la, valor nao-numerico vira zero — o
//--- mesmo comportamento cru do StringToInteger, marcado aqui como divida.
void FieldSetText(const int fid,const string text)
  {
   switch(fid)
     {
      case FCV_FLD_MA_PRIORITY:    m_draft.maCrossPriority   =(int)StringToInteger(text); break;
      case FCV_FLD_MA_FAST_PERIOD: m_draft.maFastPeriod      =(int)StringToInteger(text); break;
      case FCV_FLD_MA_SLOW_PERIOD: m_draft.maSlowPeriod      =(int)StringToInteger(text); break;
      case FCV_FLD_MA_MIN_DIST:    m_draft.maMinDistancePoints=(int)StringToInteger(text); break;
      case FCV_FLD_RSI_PRIORITY:   m_draft.rsiPriority       =(int)StringToInteger(text); break;
      case FCV_FLD_RSI_PERIOD:     m_draft.rsiPeriod         =(int)StringToInteger(text); break;
      case FCV_FLD_RSI_OVERSOLD:   m_draft.rsiOversold       =(int)StringToInteger(text); break;
      case FCV_FLD_RSI_OVERBOUGHT: m_draft.rsiOverbought     =(int)StringToInteger(text); break;
      case FCV_FLD_RSI_MIDDLE:     m_draft.rsiMiddle         =(int)StringToInteger(text); break;
      case FCV_FLD_BB_PRIORITY:    m_draft.bbPriority        =(int)StringToInteger(text); break;
      case FCV_FLD_BB_PERIOD:      m_draft.bbPeriod          =(int)StringToInteger(text); break;
      case FCV_FLD_BB_DEVIATION:   m_draft.bbDeviation       =StringToDouble(text);       break;
      case FCV_FLD_TR_MA1_PERIOD:  m_draft.trendMAPeriod     =(int)StringToInteger(text); break;
      case FCV_FLD_TR_MA2_PERIOD:  m_draft.trendSellMAPeriod =(int)StringToInteger(text); break;
      case FCV_FLD_RF_PERIOD:      m_draft.rsiFilterPeriod   =(int)StringToInteger(text); break;
      case FCV_FLD_RF_BUYMIN:      m_draft.rsiFilterBuyMin   =(int)StringToInteger(text); break;
      case FCV_FLD_RF_SELLMAX:     m_draft.rsiFilterSellMax  =(int)StringToInteger(text); break;
      case FCV_FLD_BF_PERIOD:      m_draft.bbFilterPeriod    =(int)StringToInteger(text); break;
      case FCV_FLD_BF_DEV:         m_draft.bbFilterDeviation =StringToDouble(text);       break;
      case FCV_FLD_BF_MINPTS:      m_draft.bbFilterMinWidthPoints =(int)StringToInteger(text); break;
      case FCV_FLD_BF_MINPCT:      m_draft.bbFilterMinWidthPercent=StringToDouble(text);      break;
      case FCV_FLD_BF_SLOPE_BACK:  m_draft.bbFilterSlopeLookback  =(int)StringToInteger(text); break;
      case FCV_FLD_BF_SLOPE_MINPTS:m_draft.bbFilterMinSlopePoints =(int)StringToInteger(text); break;
      default: return;
     }
  }
