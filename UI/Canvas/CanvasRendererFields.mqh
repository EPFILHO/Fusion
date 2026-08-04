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
//--- As tres janelas de noticia sao iguais e vivem num array. Aqui a janela e o
//--- campo saem do proprio identificador, em vez de dezoito casos que seriam a
//--- mesma linha repetida com um indice diferente — e a copia esquecida na
//--- terceira janela e justamente o erro silencioso que o resto deste arquivo
//--- evita sendo verboso. O verboso, neste caso, seria a copia.
bool NewsFieldParts(const int fid,int &w,int &f)
  {
   if(fid<FCV_FLD_NEWS0 || fid>FCV_FLD_NEWS_LAST) return false;
   int off=fid-FCV_FLD_NEWS0;
   w=off/FCV_FLD_NEWS_STRIDE;
   f=off%FCV_FLD_NEWS_STRIDE;
   //--- O resto do bloco de 10 nao e campo de nenhuma janela.
   return (w>=0 && w<FUSION_NEWS_WINDOW_COUNT && f<=FCV_FLD_NEWS_MODE);
  }

bool FieldGetBool(const int fid)
  {
   int w,f;
   if(NewsFieldParts(fid,w,f) && f==FCV_FLD_NEWS_ON)
      return m_draft.newsWindows[w].enabled;

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
      //--- Gestao > Risco
      case FCV_FLD_COMP_SL:     return m_draft.compensateSLSpread;
      case FCV_FLD_COMP_TP:     return m_draft.compensateTPSpread;
      case FCV_FLD_TP1_ON:      return m_draft.tp1.enabled;
      case FCV_FLD_TP2_ON:      return m_draft.tp2.enabled;
      case FCV_FLD_FREE_TP:     return m_draft.freeFinalTP;
      case FCV_FLD_BE_ON:       return m_draft.useBreakeven;
      case FCV_FLD_TRAIL_ON:    return m_draft.useTrailing;
      //--- Gestao > Protecao
      case FCV_FLD_SPREAD_ON:      return m_draft.enableSpreadProtection;
      case FCV_FLD_SESSION_ON:     return m_draft.enableSessionFilter;
      case FCV_FLD_SESS_CLOSE:     return m_draft.closeOnSessionEnd;
      case FCV_FLD_SESS_OVERNIGHT: return m_draft.sessionOvernight;
      case FCV_FLD_DAY_ON:         return m_draft.enableDailyLimits;
      case FCV_FLD_DD_ON:          return m_draft.enableDrawdown;
      case FCV_FLD_LOSS_STREAK_ON: return m_draft.lossStreakEnabled;
      case FCV_FLD_WIN_STREAK_ON:  return m_draft.winStreakEnabled;
      //--- Layout
      case FCV_FLD_SHOW_INDICATORS: return m_draft.showChartIndicators;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Cor: um terceiro tipo de campo, ao lado de chave, indice e texto. |
//|                                                                   |
//| Guarda a COR, nao a posicao na grade. A distincao importa porque   |
//| um perfil pode trazer cor que nao esta na nossa grade — os padroes |
//| do EA sao clrLime, clrRed, clrMagenta, clrOrange e clrDodgerBlue, |
//| e a 1.058 cicla por uma lista de doze que nao e a nossa. Guardando |
//| indice, abrir um perfil desses mostraria a cor errada; guardando a |
//| cor, a amostra mostra o que o perfil tem e a grade simplesmente    |
//| nao marca celula nenhuma ate voce escolher uma.                    |
//+------------------------------------------------------------------+
uint FieldGetColor(const int fid)
  {
   switch(fid)
     {
      case FCV_FLD_VIS_MAFAST_COLOR: return ChartColorToArgb(m_draft.visualMAFastColor);
      case FCV_FLD_VIS_MASLOW_COLOR: return ChartColorToArgb(m_draft.visualMASlowColor);
      case FCV_FLD_VIS_TREND1_COLOR: return ChartColorToArgb(m_draft.visualMATrendColor);
      case FCV_FLD_VIS_TREND2_COLOR: return ChartColorToArgb(m_draft.visualMATrend2Color);
      case FCV_FLD_VIS_BB_COLOR:     return ChartColorToArgb(m_draft.visualBBColor);
     }
   return m_t.muted;
  }

void FieldSetColor(const int fid,const uint argb)
  {
   ClearNotice();
   color c=ToChartColor(argb);
   switch(fid)
     {
      case FCV_FLD_VIS_MAFAST_COLOR: m_draft.visualMAFastColor  =c; break;
      case FCV_FLD_VIS_MASLOW_COLOR: m_draft.visualMASlowColor  =c; break;
      case FCV_FLD_VIS_TREND1_COLOR: m_draft.visualMATrendColor =c; break;
      case FCV_FLD_VIS_TREND2_COLOR: m_draft.visualMATrend2Color=c; break;
      case FCV_FLD_VIS_BB_COLOR:     m_draft.visualBBColor      =c; break;
     }
  }

void FieldToggleBool(const int fid)
  {
   //--- Mexer num campo e voltar a agir: o aviso descrevia a acao ANTERIOR.
   //--- Mantido, ele continuaria afirmando "perfil salvo" enquanto a tela ja
   //--- tem alteracao nova por gravar.
   ClearNotice();
   int w,f;
   if(NewsFieldParts(fid,w,f) && f==FCV_FLD_NEWS_ON)
     {
      m_draft.newsWindows[w].enabled=!m_draft.newsWindows[w].enabled;
      SyncDerivedSettings();
      return;
     }

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
      //--- Gestao > Risco. TP2 e TP Final Livre nao tem caso proprio de
      //--- desligamento: quem os desliga e o SyncDerivedSettings quando TP1 sai,
      //--- e e o mesmo caminho que corrige um perfil chegando inconsistente.
      case FCV_FLD_COMP_SL:  m_draft.compensateSLSpread=!m_draft.compensateSLSpread; break;
      case FCV_FLD_COMP_TP:  m_draft.compensateTPSpread=!m_draft.compensateTPSpread; break;
      case FCV_FLD_TP1_ON:   m_draft.tp1.enabled  =!m_draft.tp1.enabled;   break;
      case FCV_FLD_TP2_ON:   m_draft.tp2.enabled  =!m_draft.tp2.enabled;   break;
      case FCV_FLD_FREE_TP:  m_draft.freeFinalTP  =!m_draft.freeFinalTP;   break;
      case FCV_FLD_BE_ON:    m_draft.useBreakeven =!m_draft.useBreakeven;  break;
      case FCV_FLD_TRAIL_ON: m_draft.useTrailing  =!m_draft.useTrailing;   break;
      //--- Gestao > Protecao
      case FCV_FLD_SPREAD_ON:
         m_draft.enableSpreadProtection=!m_draft.enableSpreadProtection; break;
      case FCV_FLD_SESSION_ON:
         m_draft.enableSessionFilter=!m_draft.enableSessionFilter; break;
      case FCV_FLD_SESS_CLOSE:
         m_draft.closeOnSessionEnd=!m_draft.closeOnSessionEnd; break;
      case FCV_FLD_SESS_OVERNIGHT:
         m_draft.sessionOvernight=!m_draft.sessionOvernight; break;
      case FCV_FLD_DAY_ON:
         m_draft.enableDailyLimits=!m_draft.enableDailyLimits; break;
      case FCV_FLD_DD_ON:
         m_draft.enableDrawdown=!m_draft.enableDrawdown; break;
      case FCV_FLD_LOSS_STREAK_ON:
         m_draft.lossStreakEnabled=!m_draft.lossStreakEnabled; break;
      case FCV_FLD_WIN_STREAK_ON:
         m_draft.winStreakEnabled=!m_draft.winStreakEnabled; break;
      //--- Layout
      case FCV_FLD_SHOW_INDICATORS:
         m_draft.showChartIndicators=!m_draft.showChartIndicators; break;
      default: return;
     }
   SyncDerivedSettings();
  }

//--- Os campos DERIVADOS do struct — os dois. Nenhum e editavel: ambos sao
//--- resumo de outras chaves, e tratar qualquer um como campo o faz divergir
//--- do que as chaves dizem.
//---
//--- useTrendFilter e o resumo das duas medias. A 1.058 refaz esta conta em
//--- tres lugares (Inputs, TrendFilterPanel e o rascunho do painel); tratado
//--- como campo editavel, ele divergia das medias — era o "Tendencia do Geral
//--- nao acompanha" observado.
//---
//--- usePartialTP e o espelho de tp1.enabled. Core/Inputs.mqh:327, o
//--- desserializador de perfil e a validacao de Risco da 1.058 refazem esta
//--- mesma atribuicao — tres lugares, como o outro. E ele NAO e cosmetico: o
//--- EA le usePartialTP para decidir o gerenciamento da posicao
//--- (EAApplicationManagePosition, RiskManager), entao um TP1 ligado com
//--- usePartialTP falso daria uma posicao sem os parciais que a tela promete.
//---
//--- A normalizacao junto: TP1 desligado desliga TP2 e o TP Final Livre. Nao e
//--- so reagir ao clique — um perfil gravado em versao antiga pode chegar com
//--- essa combinacao, e a 1.058 corrige em toda passada de validacao. Por isso
//--- fica aqui, que e por onde passam tanto o clique quanto o SetSnapshot.
void SyncDerivedSettings(void)
  {
   m_draft.useTrendFilter=(m_draft.trendMA1Enabled || m_draft.trendMA2Enabled);
   if(!m_draft.tp1.enabled)
     {
      m_draft.tp2.enabled=false;
      m_draft.freeFinalTP=false;
     }
   m_draft.usePartialTP=m_draft.tp1.enabled;
  }

//+------------------------------------------------------------------+
//| Dependencias entre campos: quem so faz sentido com o que.         |
//|                                                                   |
//| Extraidas UMA A UMA dos paineis da 1.058, nao deduzidas. A regra  |
//| que eu supunha — "estrategia desligada apaga seus parametros" —   |
//| esta ERRADA: ali os parametros seguem editaveis, porque configurar|
//| antes de ligar e uso legitimo. O que a 1.058 apaga e so o que o   |
//| EA vai ignorar POR CAUSA DE OUTRA ESCOLHA.                        |
//+------------------------------------------------------------------+
//--- RSI (estrategia): as zonas so valem nos modos que as usam, e a linha
//--- media so vale quando o sinal OU a saida dependem dela.
bool RsiUsesZones(void)
  { return (m_draft.rsiMode==RSI_SIGNAL_CROSSOVER || m_draft.rsiMode==RSI_SIGNAL_ZONE); }
bool RsiUsesMiddle(void)
  { return (m_draft.rsiMode==RSI_SIGNAL_MIDDLE || m_draft.rsiExitMode==RSI_EXIT_MIDDLE_TARGET); }

//--- Filtro RSI: o segundo nivel nao existe no modo Direcao, que usa uma
//--- linha so.
bool RsiFilterUsesSecondLevel(void)
  { return (m_draft.rsiFilterMode!=RSI_FILTER_DIRECTION); }

//--- Niveis padrao de cada modo do filtro RSI (UI/RSIFilterPanel.mqh). Cada
//--- par ja nasce respeitando a ordem que o modo exige:
//---   Direcao  50/50 — uma linha so, os dois campos apontam para ela
//---   Neutro   60/40 — venda < compra, com o meio bloqueado entre eles
//---   Extremos 30/70 — sobrevenda < sobrecompra
void ApplyRsiFilterModeDefaults(const ENUM_RSI_FILTER_MODE mode)
  {
   if(mode==RSI_FILTER_NEUTRAL)       { m_draft.rsiFilterBuyMin=60; m_draft.rsiFilterSellMax=40; }
   else if(mode==RSI_FILTER_EXTREMES) { m_draft.rsiFilterBuyMin=30; m_draft.rsiFilterSellMax=70; }
   else                               { m_draft.rsiFilterBuyMin=50; m_draft.rsiFilterSellMax=50; }
  }

//--- Filtro Bollinger: a largura minima e medida em pontos OU em porcento,
//--- nunca nos dois; e a inclinacao so existe com o filtro ligado.
bool BbFilterAbsolute(void)
  { return (m_draft.bbFilterMode==BB_FILTER_WIDTH_ABSOLUTE); }
bool BbFilterSlopeEditable(void)
  { return m_draft.bbFilterEnabled; }
bool BbFilterSlopeParams(void)
  { return (m_draft.bbFilterEnabled && m_draft.bbFilterSlopeDirectionEnabled); }

//+------------------------------------------------------------------+
//| Gestao: quem apaga com o que.                                     |
//|                                                                   |
//| ⚠ Extraidas UMA A UMA de UIPanelRiskValidation e                  |
//| UIPanelProtectionValidation. O padrao NAO e uniforme, e supo-lo   |
//| uniforme erra nos dois sentidos:                                  |
//|                                                                   |
//|  - Em Risco, a chave APAGA os parametros (BE desligado apaga      |
//|    gatilho e offset) — o contrario do que vale nas Estrategias.   |
//|  - Em Limites Diarios e Drawdown, a chave NAO apaga os numeros:   |
//|    Max Trades, Max Perda, Max Ganho e Max DD seguem editaveis com |
//|    a protecao desligada. So os COMBOS apagam.                     |
//|  - Em Sequencias a chave apaga tudo do seu lado, e a Pausa min    |
//|    exige ainda que a acao seja Pausar — com "Parar dia" nao ha    |
//|    pausa a configurar.                                            |
//|                                                                   |
//| A sessao e as janelas de noticia nao tem dependencia nenhuma:     |
//| horario segue editavel com o filtro desligado.                    |
//+------------------------------------------------------------------+
//--- TP parcial: TP1 comanda. TP2 so existe com TP1, e seus numeros so com
//--- TP2 tambem ligado — dois degraus, nao um.
bool Tp1Params(void)   { return m_draft.tp1.enabled; }
bool Tp2Editable(void) { return m_draft.tp1.enabled; }
bool Tp2Params(void)   { return (m_draft.tp1.enabled && m_draft.tp2.enabled); }
bool FreeTpEditable(void) { return m_draft.tp1.enabled; }

bool BreakevenParams(void) { return m_draft.useBreakeven; }
bool TrailingParams(void)  { return m_draft.useTrailing; }
bool SpreadLimitEditable(void) { return m_draft.enableSpreadProtection; }

//--- Combos que dependem da chave da propria secao.
bool DayActionEditable(void)  { return m_draft.enableDailyLimits; }
bool DrawdownCombosEditable(void) { return m_draft.enableDrawdown; }

//--- Sequencias, um lado de cada vez.
bool LossStreakParams(void) { return m_draft.lossStreakEnabled; }
bool WinStreakParams(void)  { return m_draft.winStreakEnabled; }
bool LossStreakPauseEditable(void)
  { return (m_draft.lossStreakEnabled && m_draft.lossStreakAction==STREAK_ACTION_PAUSE); }
bool WinStreakPauseEditable(void)
  { return (m_draft.winStreakEnabled && m_draft.winStreakAction==STREAK_ACTION_PAUSE); }

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
//| Desde a Etapa 2c a diferenca e a UNICA fonte: o antigo m_dirty foi |
//| removido. Ele existia para os controles nao ligados a SEASettings, |
//| e depois da 2b so a tela de estresse tinha desses — mantido, uma   |
//| tecla de diagnostico passaria a acender o SALVAR e a fazer o       |
//| painel emitir gravacao de um rascunho intocado.                    |
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
      //--- Slot local (formulario de perfil, tela de estresse): nao descreve
      //--- campo de SEASettings, entao nao ha pendencia de perfil a acusar.
      if(m_liveEditFid[k]==FCV_FLD_NONE) continue;
      if(ObjectFind(m_chart,m_liveEditName[k])<0) continue;
      if(ObjectGetString(m_chart,m_liveEditName[k],OBJPROP_TEXT)!=m_liveEditText[k])
         return true;
     }
   return false;
  }

bool HasPending(void)
  { return (EditTextOutOfSync() || !FusionSettingsEqual(m_draft,m_committed)); }

int FieldGetIndex(const int fid)
  {
   int w,f;
   if(NewsFieldParts(fid,w,f) && f==FCV_FLD_NEWS_MODE)
      return (int)m_draft.newsWindows[w].action;

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
      //--- Gestao. As cinco listas destes combos foram conferidas contra os
      //--- FusionPopulate*Combo da 1.058: todas listam na ordem do enum, entao
      //--- indice e valor coincidem, como nos combos anteriores.
      case FCV_FLD_DIRECTION:       return (int)m_draft.tradeDirection;
      case FCV_FLD_DAY_ACTION:      return (int)m_draft.profitTargetAction;
      case FCV_FLD_DD_TYPE:         return (int)m_draft.drawdownType;
      case FCV_FLD_DD_PEAK:         return (int)m_draft.drawdownPeakMode;
      case FCV_FLD_LOSS_STREAK_ACT: return (int)m_draft.lossStreakAction;
      case FCV_FLD_WIN_STREAK_ACT:  return (int)m_draft.winStreakAction;
      //--- Layout. ENUM_LINE_STYLE do MQL5: SOLID=0, DASH=1, DOT=2 — o combo
      //--- tem exatamente essas tres, na ordem, entao indice e valor coincidem.
      //--- Estilo vindo do perfil fora dessas tres (DASHDOT, por exemplo) cai no
      //--- indice 0 pelo limite do combo, e ao escolher qualquer opcao ele passa
      //--- a valer — nao ha como exibir o que a lista nao tem.
      case FCV_FLD_VIS_MAFAST_STYLE: return (int)m_draft.visualMAFastStyle;
      case FCV_FLD_VIS_MASLOW_STYLE: return (int)m_draft.visualMASlowStyle;
      case FCV_FLD_VIS_TREND1_STYLE: return (int)m_draft.visualMATrendStyle;
      case FCV_FLD_VIS_TREND2_STYLE: return (int)m_draft.visualMATrend2Style;
      case FCV_FLD_VIS_BB_STYLE:     return (int)m_draft.visualBBStyle;
     }
   return 0;
  }

void FieldSetIndex(const int fid,const int idx)
  {
   ClearNotice();
   int w,f;
   if(NewsFieldParts(fid,w,f) && f==FCV_FLD_NEWS_MODE)
     {
      m_draft.newsWindows[w].action=(ENUM_NEWS_WINDOW_ACTION)idx;
      return;
     }

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
      //--- Trocar o modo do filtro RSI REDEFINE os dois niveis. Nao e cortesia:
      //--- a ordem exigida se INVERTE entre os modos (Neutro pede venda <
      //--- compra; Extremos pede compra < venda), entao o par que era valido em
      //--- um modo costuma ser invalido no outro. Sair de Direcao com 50/50
      //--- deixaria Neutro invalido no ato. Valores da 1.058.
      case FCV_FLD_RF_MODE:
        {
         ENUM_RSI_FILTER_MODE nm=(ENUM_RSI_FILTER_MODE)idx;
         if(m_draft.rsiFilterMode!=nm) ApplyRsiFilterModeDefaults(nm);
         m_draft.rsiFilterMode=nm;
         break;
        }
      case FCV_FLD_BF_TF:          m_draft.bbFilterTimeframe=TfFromIndex(idx); break;
      case FCV_FLD_BF_PRICE:       m_draft.bbFilterPrice=(ENUM_APPLIED_PRICE)(idx+1); break;
      case FCV_FLD_BF_MODE:        m_draft.bbFilterMode=(ENUM_BB_FILTER_WIDTH_MODE)idx; break;
      //--- Gestao
      case FCV_FLD_DIRECTION:  m_draft.tradeDirection=(ENUM_TRADE_DIRECTION)idx;       break;
      case FCV_FLD_DAY_ACTION: m_draft.profitTargetAction=(ENUM_PROFIT_TARGET_ACTION)idx; break;
      case FCV_FLD_DD_TYPE:    m_draft.drawdownType=(ENUM_DRAWDOWN_TYPE)idx;           break;
      case FCV_FLD_DD_PEAK:    m_draft.drawdownPeakMode=(ENUM_DRAWDOWN_PEAK_MODE)idx;  break;
      case FCV_FLD_LOSS_STREAK_ACT: m_draft.lossStreakAction=(ENUM_STREAK_ACTION)idx;  break;
      case FCV_FLD_WIN_STREAK_ACT:  m_draft.winStreakAction=(ENUM_STREAK_ACTION)idx;   break;
      //--- Layout
      case FCV_FLD_VIS_MAFAST_STYLE: m_draft.visualMAFastStyle  =(ENUM_LINE_STYLE)idx; break;
      case FCV_FLD_VIS_MASLOW_STYLE: m_draft.visualMASlowStyle  =(ENUM_LINE_STYLE)idx; break;
      case FCV_FLD_VIS_TREND1_STYLE: m_draft.visualMATrendStyle =(ENUM_LINE_STYLE)idx; break;
      case FCV_FLD_VIS_TREND2_STYLE: m_draft.visualMATrend2Style=(ENUM_LINE_STYLE)idx; break;
      case FCV_FLD_VIS_BB_STYLE:     m_draft.visualBBStyle      =(ENUM_LINE_STYLE)idx; break;
      default: return;
     }
  }

//--- Hora e minuto sempre com dois digitos: "9:0" alinhado ao lado de "17:30"
//--- nao se le como horario. Mesmo StringFormat da 1.058 (SyncProtectionControls).
string TimePartText(const int value) { return StringFormat("%02d",value); }

string FieldGetText(const int fid)
  {
   int w,f;
   if(NewsFieldParts(fid,w,f))
     {
      switch(f)
        {
         case FCV_FLD_NEWS_START_H: return TimePartText(m_draft.newsWindows[w].startHour);
         case FCV_FLD_NEWS_START_M: return TimePartText(m_draft.newsWindows[w].startMinute);
         case FCV_FLD_NEWS_END_H:   return TimePartText(m_draft.newsWindows[w].endHour);
         case FCV_FLD_NEWS_END_M:   return TimePartText(m_draft.newsWindows[w].endMinute);
        }
      return "";
     }

   switch(fid)
     {
      case FCV_FLD_MAGIC:          return IntegerToString(m_draft.magicNumber);
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
      //--- Gestao > Risco. O lote e o unico campo cuja grafia depende do ativo:
      //--- o passo de volume decide as casas decimais, e escreve-lo com duas
      //--- fixas mostraria 0.10 num ativo cujo passo e 0.001.
      case FCV_FLD_FIXED_LOT:   return FusionFormatVolume(m_draft.fixedLot,m_snap.symbolSpec);
      case FCV_FLD_SLIPPAGE:    return IntegerToString(m_draft.slippagePoints);
      case FCV_FLD_SL_POINTS:   return IntegerToString(m_draft.fixedSLPoints);
      case FCV_FLD_TP_POINTS:   return IntegerToString(m_draft.fixedTPPoints);
      case FCV_FLD_TP1_PCT:     return DoubleToString(m_draft.tp1.percent,2);
      case FCV_FLD_TP1_DIST:    return IntegerToString(m_draft.tp1.distancePoints);
      case FCV_FLD_TP2_PCT:     return DoubleToString(m_draft.tp2.percent,2);
      case FCV_FLD_TP2_DIST:    return IntegerToString(m_draft.tp2.distancePoints);
      case FCV_FLD_BE_TRIGGER:  return IntegerToString(m_draft.breakevenTriggerPoints);
      case FCV_FLD_BE_OFFSET:   return IntegerToString(m_draft.breakevenOffsetPoints);
      case FCV_FLD_TRAIL_START: return IntegerToString(m_draft.trailingStartPoints);
      case FCV_FLD_TRAIL_STEP:  return IntegerToString(m_draft.trailingStepPoints);
      //--- Gestao > Protecao
      case FCV_FLD_SPREAD_MAX:  return IntegerToString(m_draft.maxSpreadPoints);
      case FCV_FLD_SESS_START_H: return TimePartText(m_draft.sessionStartHour);
      case FCV_FLD_SESS_START_M: return TimePartText(m_draft.sessionStartMinute);
      case FCV_FLD_SESS_END_H:   return TimePartText(m_draft.sessionEndHour);
      case FCV_FLD_SESS_END_M:   return TimePartText(m_draft.sessionEndMinute);
      case FCV_FLD_DAY_TRADES:  return IntegerToString(m_draft.maxDailyTrades);
      case FCV_FLD_DAY_LOSS:    return DoubleToString(m_draft.maxDailyLoss,2);
      case FCV_FLD_DAY_GAIN:    return DoubleToString(m_draft.maxDailyGain,2);
      case FCV_FLD_DD_MAX:      return DoubleToString(m_draft.maxDrawdown,2);
      case FCV_FLD_LOSS_STREAK_MAX:   return IntegerToString(m_draft.maxLossStreak);
      case FCV_FLD_LOSS_STREAK_PAUSE: return IntegerToString(m_draft.lossStreakPauseMinutes);
      case FCV_FLD_WIN_STREAK_MAX:    return IntegerToString(m_draft.maxWinStreak);
      case FCV_FLD_WIN_STREAK_PAUSE:  return IntegerToString(m_draft.winStreakPauseMinutes);
     }
   return "";
  }

//--- Texto digitado -> rascunho.
//---
//--- O PARSE E RECUSAVEL desde a Etapa 2d: texto que nao e numero nao entra no
//--- rascunho, e o campo guarda o ultimo valor bom. Antes disso "abc" virava
//--- zero sem uma palavra — e zero e valor legitimo em quase todo campo, entao
//--- o apagamento passava. E a mesma regra da 1.058, que so escreve no rascunho
//--- quando o parse passa.
//---
//--- ⚠ A recusa NAO marca erro de validacao, e a distincao custou uma rodada de
//--- teste. O BuildEdits reescreve o objeto com o valor do rascunho no mesmo
//--- quadro, entao um instante depois nao existe mais texto ruim em lugar
//--- nenhum — deixar campo, subaba e aba vermelhos apontaria um erro que o
//--- proprio painel ja desfez, e so entrar e sair do campo o limpava. O usuario
//--- precisa e saber POR QUE o valor voltou: isso e recado, e vai para a caixa
//--- de aviso com prazo.
//---
//--- Hora/minuto digitados -> valor recortado a faixa. Copia do SanitizeTimeText
//--- da 1.058 (UIPanelProtectionInputs): so os digitos contam e o excedente e
//--- preso no maximo, entao "99" vira 23 numa hora e 59 num minuto.
//---
//--- Este recorte NAO e a validacao da Etapa 2d, e nao esta adiantado dela: na
//--- 1.058 ele tambem mora no fim da edicao, e nao entre as regras de faixa.
//--- A razao e que hora e minuto nao tem estado invalido para mostrar — nao
//--- existe "25" para pintar de vermelho, existe um horario que o EA nunca vai
//--- conseguir usar. Quem valida horario ali e a ordem entre inicio e fim.
int TimePartValue(const string text,const int maxValue)
  {
   string digits="";
   for(int i=0;i<StringLen(text);++i)
     {
      ushort ch=StringGetCharacter(text,i);
      if(ch>='0' && ch<='9') digits+=StringSubstr(text,i,1);
     }
   if(digits=="") return 0;
   int value=(int)StringToInteger(digits);
   if(value<0) return 0;
   return (value>maxValue) ? maxValue : value;
  }

void FieldSetText(const int fid,const string text)
  {
   //--- Portao unico de entrada de texto. Fica ANTES de qualquer switch de
   //--- proposito: um caso novo esquecido aqui deixaria aquele campo sem
   //--- veredito, e ele voltaria a aceitar lixo em silencio.
   //--- A virgula e normalizada para ponto — "0,30" e a grafia que o proprio
   //--- terminal exibe em boa parte das localizacoes, e recusa-la (ou pior,
   //--- converte-la para zero pelo StringToDouble) seria recusar o teclado do
   //--- usuario.
   ClearNotice();
   string parsed=text;
   int kind=FieldTextKind(fid);
   if(kind!=FCV_FTYPE_NONE)
     {
      bool ok;
      if(kind==FCV_FTYPE_DEC)
        {
         parsed=FusionNormalizeDecimalText(text);
         ok=FusionIsDecimalText(parsed,true);
        }
      else
         ok=FusionIsIntegerText(text,true);
      if(!ok) { RejectTypedText(text,kind); return; }   // mantem o ultimo valor bom
      //--- Decimal digitado e cortado na precisao do ARQUIVO, aqui e nao
      //--- depois. O campo ja e desenhado com duas casas: guardar 1.234 faria a
      //--- tela mostrar 1.23 enquanto o EA operaria 1.234 — a mesma classe de
      //--- divergencia entre o que se ve e o que vale que o parse recusado
      //--- criava. E, gravado, o valor voltaria diferente do disco.
      if(kind==FCV_FTYPE_DEC)
         parsed=DoubleToString(StringToDouble(parsed),
                               (fid==FCV_FLD_FIXED_LOT) ? FUSION_STORAGE_DIGITS_LOT
                                                        : FUSION_STORAGE_DIGITS);
     }

   int w,f;
   if(NewsFieldParts(fid,w,f))
     {
      switch(f)
        {
         case FCV_FLD_NEWS_START_H:
            m_draft.newsWindows[w].startHour  =TimePartValue(parsed,FCV_HOUR_MAX);   return;
         case FCV_FLD_NEWS_START_M:
            m_draft.newsWindows[w].startMinute=TimePartValue(parsed,FCV_MINUTE_MAX); return;
         case FCV_FLD_NEWS_END_H:
            m_draft.newsWindows[w].endHour    =TimePartValue(parsed,FCV_HOUR_MAX);   return;
         case FCV_FLD_NEWS_END_M:
            m_draft.newsWindows[w].endMinute  =TimePartValue(parsed,FCV_MINUTE_MAX); return;
        }
      return;
     }

   switch(fid)
     {
      case FCV_FLD_MAGIC:          m_draft.magicNumber       =(int)StringToInteger(parsed); break;
      case FCV_FLD_MA_PRIORITY:    m_draft.maCrossPriority   =(int)StringToInteger(parsed); break;
      case FCV_FLD_MA_FAST_PERIOD: m_draft.maFastPeriod      =(int)StringToInteger(parsed); break;
      case FCV_FLD_MA_SLOW_PERIOD: m_draft.maSlowPeriod      =(int)StringToInteger(parsed); break;
      case FCV_FLD_MA_MIN_DIST:    m_draft.maMinDistancePoints=(int)StringToInteger(parsed); break;
      case FCV_FLD_RSI_PRIORITY:   m_draft.rsiPriority       =(int)StringToInteger(parsed); break;
      case FCV_FLD_RSI_PERIOD:     m_draft.rsiPeriod         =(int)StringToInteger(parsed); break;
      case FCV_FLD_RSI_OVERSOLD:   m_draft.rsiOversold       =(int)StringToInteger(parsed); break;
      case FCV_FLD_RSI_OVERBOUGHT: m_draft.rsiOverbought     =(int)StringToInteger(parsed); break;
      case FCV_FLD_RSI_MIDDLE:     m_draft.rsiMiddle         =(int)StringToInteger(parsed); break;
      case FCV_FLD_BB_PRIORITY:    m_draft.bbPriority        =(int)StringToInteger(parsed); break;
      case FCV_FLD_BB_PERIOD:      m_draft.bbPeriod          =(int)StringToInteger(parsed); break;
      case FCV_FLD_BB_DEVIATION:   m_draft.bbDeviation       =StringToDouble(parsed);       break;
      case FCV_FLD_TR_MA1_PERIOD:  m_draft.trendMAPeriod     =(int)StringToInteger(parsed); break;
      case FCV_FLD_TR_MA2_PERIOD:  m_draft.trendSellMAPeriod =(int)StringToInteger(parsed); break;
      case FCV_FLD_RF_PERIOD:      m_draft.rsiFilterPeriod   =(int)StringToInteger(parsed); break;
      //--- No modo Direcao os dois campos sao a MESMA linha: o segundo nao
      //--- aparece na tela, mas continua existindo no struct e sendo lido pelo
      //--- EA se o modo mudar depois. Mante-lo em sincronia evita que uma linha
      //--- fantasma, de outro modo, ressurja com valor de outra epoca.
      case FCV_FLD_RF_BUYMIN:
         m_draft.rsiFilterBuyMin=(int)StringToInteger(parsed);
         if(m_draft.rsiFilterMode==RSI_FILTER_DIRECTION)
            m_draft.rsiFilterSellMax=m_draft.rsiFilterBuyMin;
         break;
      case FCV_FLD_RF_SELLMAX:     m_draft.rsiFilterSellMax  =(int)StringToInteger(parsed); break;
      case FCV_FLD_BF_PERIOD:      m_draft.bbFilterPeriod    =(int)StringToInteger(parsed); break;
      case FCV_FLD_BF_DEV:         m_draft.bbFilterDeviation =StringToDouble(parsed);       break;
      case FCV_FLD_BF_MINPTS:      m_draft.bbFilterMinWidthPoints =(int)StringToInteger(parsed); break;
      case FCV_FLD_BF_MINPCT:      m_draft.bbFilterMinWidthPercent=StringToDouble(parsed);      break;
      case FCV_FLD_BF_SLOPE_BACK:  m_draft.bbFilterSlopeLookback  =(int)StringToInteger(parsed); break;
      case FCV_FLD_BF_SLOPE_MINPTS:m_draft.bbFilterMinSlopePoints =(int)StringToInteger(parsed); break;
      //--- Gestao > Risco
      case FCV_FLD_FIXED_LOT:   m_draft.fixedLot              =StringToDouble(parsed);       break;
      case FCV_FLD_SLIPPAGE:    m_draft.slippagePoints        =(int)StringToInteger(parsed); break;
      case FCV_FLD_SL_POINTS:   m_draft.fixedSLPoints         =(int)StringToInteger(parsed); break;
      case FCV_FLD_TP_POINTS:   m_draft.fixedTPPoints         =(int)StringToInteger(parsed); break;
      case FCV_FLD_TP1_PCT:     m_draft.tp1.percent           =StringToDouble(parsed);       break;
      case FCV_FLD_TP1_DIST:    m_draft.tp1.distancePoints    =(int)StringToInteger(parsed); break;
      case FCV_FLD_TP2_PCT:     m_draft.tp2.percent           =StringToDouble(parsed);       break;
      case FCV_FLD_TP2_DIST:    m_draft.tp2.distancePoints    =(int)StringToInteger(parsed); break;
      case FCV_FLD_BE_TRIGGER:  m_draft.breakevenTriggerPoints=(int)StringToInteger(parsed); break;
      case FCV_FLD_BE_OFFSET:   m_draft.breakevenOffsetPoints =(int)StringToInteger(parsed); break;
      case FCV_FLD_TRAIL_START: m_draft.trailingStartPoints   =(int)StringToInteger(parsed); break;
      case FCV_FLD_TRAIL_STEP:  m_draft.trailingStepPoints    =(int)StringToInteger(parsed); break;
      //--- Gestao > Protecao
      case FCV_FLD_SPREAD_MAX:  m_draft.maxSpreadPoints       =(int)StringToInteger(parsed); break;
      case FCV_FLD_SESS_START_H: m_draft.sessionStartHour  =TimePartValue(parsed,FCV_HOUR_MAX);   break;
      case FCV_FLD_SESS_START_M: m_draft.sessionStartMinute=TimePartValue(parsed,FCV_MINUTE_MAX); break;
      case FCV_FLD_SESS_END_H:   m_draft.sessionEndHour    =TimePartValue(parsed,FCV_HOUR_MAX);   break;
      case FCV_FLD_SESS_END_M:   m_draft.sessionEndMinute  =TimePartValue(parsed,FCV_MINUTE_MAX); break;
      case FCV_FLD_DAY_TRADES:  m_draft.maxDailyTrades        =(int)StringToInteger(parsed); break;
      case FCV_FLD_DAY_LOSS:    m_draft.maxDailyLoss          =StringToDouble(parsed);       break;
      case FCV_FLD_DAY_GAIN:    m_draft.maxDailyGain          =StringToDouble(parsed);       break;
      case FCV_FLD_DD_MAX:      m_draft.maxDrawdown           =StringToDouble(parsed);       break;
      case FCV_FLD_LOSS_STREAK_MAX:   m_draft.maxLossStreak         =(int)StringToInteger(parsed); break;
      case FCV_FLD_LOSS_STREAK_PAUSE: m_draft.lossStreakPauseMinutes=(int)StringToInteger(parsed); break;
      case FCV_FLD_WIN_STREAK_MAX:    m_draft.maxWinStreak          =(int)StringToInteger(parsed); break;
      case FCV_FLD_WIN_STREAK_PAUSE:  m_draft.winStreakPauseMinutes =(int)StringToInteger(parsed); break;
      default: return;
     }
  }
