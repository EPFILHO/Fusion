//+------------------------------------------------------------------+
//| CanvasRendererValidate.mqh                                        |
//| Fragmento do corpo de CFusionCanvasRenderer — Etapa 2d.           |
//|                                                                   |
//| As REGRAS sao as da 1.058, extraidas uma a uma dos Validate() dos |
//| paineis de estrategia e filtro, de UIPanelRiskValidation e de     |
//| UIPanelProtectionValidation. Nao foram rededuzidas: uma faixa     |
//| "obvia" que discorde da 1.058 faria os dois paineis aceitarem     |
//| perfis diferentes, e o arquivo gravado por um seria recusado pelo |
//| outro.                                                            |
//|                                                                   |
//| O que MUDA e so a camada de leitura. La as regras leem membros    |
//| CEdit nomeados (m_cfgRiskLotEdit, dezenas deles); aqui leem o     |
//| rascunho, que e o modelo generico por slot. Era a divida que a    |
//| correcao da Etapa 2b registrou no plano.                          |
//|                                                                   |
//| ⚠️ TEXTO RECUSADO NAO E ERRO DE VALIDACAO — e evento.             |
//|                                                                   |
//| A primeira versao guardava o veredito do parse por campo          |
//| (m_fldBadText) e o somava a validacao: campo vermelho, aviso e a  |
//| cadeia inteira acesa ate a aba. Estava errado, e o usuario achou  |
//| em minutos: quem digita letra num campo numerico ve o valor bom   |
//| VOLTAR sozinho — o BuildEdits reescreve o objeto no mesmo quadro,  |
//| porque o rascunho nao mudou. Ou seja, um quadro depois nao existe |
//| mais texto ruim em lugar nenhum, e mesmo assim a marca ficava     |
//| ligada para sempre: so entrar no campo e sair de novo a limpava.  |
//| O painel apontava um erro que ele proprio ja tinha desfeito.      |
//|                                                                   |
//| A regra que fica: **o que a validacao responde e sobre o RASCUNHO,|
//| que e o unico estado persistente.** Texto recusado nunca chega la |
//| — logo nao ha o que marcar. O usuario precisa e saber POR QUE o   |
//| valor voltou, e isso e um recado, nao um estado: vai para a caixa |
//| de aviso com prazo, em FieldSetText.                              |
//+------------------------------------------------------------------+

//--- Como o texto daquele campo deve ser lido. Decide o parse na entrada e,
//--- por consequencia, o que e recusado. Os FCV_FTYPE_* vivem em
//--- CanvasFields.mqh: sao macros, e macro obedece a ordem de inclusao — aqui
//--- elas nasceriam DEPOIS do FieldSetText que as usa.
int FieldTextKind(const int fid)
  {
   int w,f;
   if(NewsFieldParts(fid,w,f))
     {
      if(f>=FCV_FLD_NEWS_START_H && f<=FCV_FLD_NEWS_END_M) return FCV_FTYPE_INT;
      return FCV_FTYPE_NONE;
     }

   switch(fid)
     {
      //--- decimais
      case FCV_FLD_BB_DEVIATION:
      case FCV_FLD_BF_DEV:
      case FCV_FLD_BF_MINPCT:
      case FCV_FLD_FIXED_LOT:
      case FCV_FLD_TP1_PCT:
      case FCV_FLD_TP2_PCT:
      case FCV_FLD_DAY_LOSS:
      case FCV_FLD_DAY_GAIN:
      case FCV_FLD_DD_MAX:
         return FCV_FTYPE_DEC;
      //--- inteiros (inclui hora e minuto, que o TimePartValue depois recorta)
      case FCV_FLD_MAGIC:
      case FCV_FLD_MA_PRIORITY:
      case FCV_FLD_MA_FAST_PERIOD:
      case FCV_FLD_MA_SLOW_PERIOD:
      case FCV_FLD_MA_MIN_DIST:
      case FCV_FLD_RSI_PRIORITY:
      case FCV_FLD_RSI_PERIOD:
      case FCV_FLD_RSI_OVERSOLD:
      case FCV_FLD_RSI_OVERBOUGHT:
      case FCV_FLD_RSI_MIDDLE:
      case FCV_FLD_BB_PRIORITY:
      case FCV_FLD_BB_PERIOD:
      case FCV_FLD_TR_MA1_PERIOD:
      case FCV_FLD_TR_MA2_PERIOD:
      case FCV_FLD_RF_PERIOD:
      case FCV_FLD_RF_BUYMIN:
      case FCV_FLD_RF_SELLMAX:
      case FCV_FLD_BF_PERIOD:
      case FCV_FLD_BF_MINPTS:
      case FCV_FLD_BF_SLOPE_BACK:
      case FCV_FLD_BF_SLOPE_MINPTS:
      case FCV_FLD_SLIPPAGE:
      case FCV_FLD_SL_POINTS:
      case FCV_FLD_TP_POINTS:
      case FCV_FLD_TP1_DIST:
      case FCV_FLD_TP2_DIST:
      case FCV_FLD_BE_TRIGGER:
      case FCV_FLD_BE_OFFSET:
      case FCV_FLD_TRAIL_START:
      case FCV_FLD_TRAIL_STEP:
      case FCV_FLD_SPREAD_MAX:
      case FCV_FLD_SESS_START_H:
      case FCV_FLD_SESS_START_M:
      case FCV_FLD_SESS_END_H:
      case FCV_FLD_SESS_END_M:
      case FCV_FLD_DAY_TRADES:
      case FCV_FLD_LOSS_STREAK_MAX:
      case FCV_FLD_LOSS_STREAK_PAUSE:
      case FCV_FLD_WIN_STREAK_MAX:
      case FCV_FLD_WIN_STREAK_PAUSE:
         return FCV_FTYPE_INT;
     }
   return FCV_FTYPE_NONE;
  }

//+------------------------------------------------------------------+
//| Faixas — os mesmos numeros da 1.058.                              |
//+------------------------------------------------------------------+
bool VRange(const int v,const int lo,const int hi) { return (v>=lo && v<=hi); }
//--- Periodo de indicador: 1..1000 em todos os paineis.
bool VPeriod(const int v)   { return VRange(v,1,1000); }
//--- Prioridade de estrategia: 0..1000.
bool VPriority(const int v) { return VRange(v,0,1000); }
//--- Distancia em pontos: 0..100000.
bool VPoints(const int v)   { return VRange(v,0,100000); }
//--- Nivel de RSI: 0..100.
bool VLevel(const int v)    { return VRange(v,0,100); }
//--- Desvio de Bollinger: maior que 0 e ate 10.
bool VDeviation(const double v) { return (v>0.0 && v<=10.0); }

//+------------------------------------------------------------------+
//| Regras cruzadas. Cada uma vale para TODOS os campos que participa |
//| dela, e e por isso que sao funcoes e nao trechos dentro do        |
//| switch: a mesma resposta pinta a MA Rapida e a MA Lenta.          |
//+------------------------------------------------------------------+
bool VHasStrategy(void)
  { return (m_draft.useMACross || m_draft.useRSI || m_draft.useBollinger); }

bool VMaOrder(void)
  {
   if(!VPeriod(m_draft.maFastPeriod) || !VPeriod(m_draft.maSlowPeriod)) return true;
   return (m_draft.maFastPeriod < m_draft.maSlowPeriod);
  }

//--- RSI: quais niveis o modo escolhido realmente usa. Fora deles a 1.058 nao
//--- valida — configurar antes de usar e uso legitimo.
bool VRsiZoneOrder(void)
  {
   if(!RsiUsesZones()) return true;
   return (m_draft.rsiOversold < m_draft.rsiOverbought);
  }

//--- Saida por cruzamento da media exige a media ENTRE as duas zonas: sair no
//--- meio so faz sentido se o meio estiver dentro da faixa que o sinal usa.
bool VRsiMiddleOrder(void)
  {
   if(m_draft.rsiExitMode!=RSI_EXIT_MIDDLE_TARGET || !RsiUsesZones()) return true;
   return (m_draft.rsiOversold<m_draft.rsiMiddle && m_draft.rsiMiddle<m_draft.rsiOverbought);
  }

//--- Entrar POR cruzar a media e sair AO cruzar a media e a mesma linha nas
//--- duas pontas: a posicao fecharia no instante em que abriu.
bool VRsiExitCombo(void)
  { return !(m_draft.rsiMode==RSI_SIGNAL_MIDDLE && m_draft.rsiExitMode==RSI_EXIT_MIDDLE_TARGET); }

bool VRsiFilterOrder(void)
  {
   if(m_draft.rsiFilterMode==RSI_FILTER_NEUTRAL)
      return (m_draft.rsiFilterSellMax < m_draft.rsiFilterBuyMin);
   if(m_draft.rsiFilterMode==RSI_FILTER_EXTREMES)
      return (m_draft.rsiFilterBuyMin < m_draft.rsiFilterSellMax);
   return true;
  }

//--- Filtro de inclinacao so e cobrado com o filtro E a inclinacao ligados.
bool VSlopeActive(void)
  { return (m_draft.bbFilterEnabled && m_draft.bbFilterSlopeDirectionEnabled); }

//+------------------------------------------------------------------+
//| Risco.                                                            |
//+------------------------------------------------------------------+
//--- Lote conferido contra a ESPECIFICACAO DO ATIVO, nao contra uma faixa
//--- inventada: minimo, maximo e passo mudam de simbolo para simbolo, e um lote
//--- desalinhado do passo e recusado pela corretora, nao pelo EA.
bool VLot(void)
  {
   double lot=m_draft.fixedLot;
   if(lot<=0.0) return false;
   if(m_snap.symbolSpec.volumeMin>0.0 && lot<(m_snap.symbolSpec.volumeMin-0.0000001)) return false;
   if(m_snap.symbolSpec.volumeMax>0.0 && lot>(m_snap.symbolSpec.volumeMax+0.0000001)) return false;
   return FusionIsVolumeAligned(lot,m_snap.symbolSpec);
  }

//--- Distancia menor que o minimo da corretora e ordem recusada na origem.
//--- Zero passa: zero desliga o stop, nao e uma distancia curta.
bool VStopsLevel(const int points)
  {
   if(points<=0) return true;
   int lvl=m_snap.symbolSpec.stopsLevel;
   if(lvl<=0) return true;
   return (points>=lvl);
  }

double VNormalizeVolume(const double volume)
  {
   SSymbolSpec spec=m_snap.symbolSpec;
   if(spec.volumeStep<=0.0) return volume;
   double normalized=MathRound(volume/spec.volumeStep)*spec.volumeStep;
   normalized=MathMax(spec.volumeMin,normalized);
   normalized=MathMin(spec.volumeMax,normalized);
   return NormalizeDouble(normalized,FusionVolumeDigits(spec.volumeStep));
  }

//--- O plano de volumes precisa FECHAR: cada parcial tem de ser um lote valido
//--- e ainda sobrar o minimo aberto. Um percentual aritmeticamente correto pode
//--- virar um volume que a corretora recusa depois do arredondamento ao passo —
//--- e ai o erro so apareceria na hora de operar.
bool VPartialVolumePlan(string &err)
  {
   err="";
   if(!m_draft.tp1.enabled) return true;

   SSymbolSpec spec=m_snap.symbolSpec;
   if(spec.volumeMin<=0.0 || spec.volumeStep<=0.0 || spec.volumeMax<=0.0)
     { err="Especificacao de lote do ativo indisponivel."; return false; }

   double entry=VNormalizeVolume(m_draft.fixedLot);
   if(entry<spec.volumeMin || entry>spec.volumeMax)
     { err="Lote invalido para validar TP Parcial."; return false; }

   double v1=VNormalizeVolume(entry*(m_draft.tp1.percent/100.0));
   if(v1<spec.volumeMin || v1+0.0000001>=entry)
     { err="TP1 precisa fechar lote parcial valido e deixar saldo."; return false; }

   double reserved=v1;
   if(m_draft.tp2.enabled)
     {
      double v2=VNormalizeVolume(entry*(m_draft.tp2.percent/100.0));
      if(v2<spec.volumeMin)
        { err="TP2 precisa fechar lote parcial valido."; return false; }
      reserved+=v2;
     }

   if((entry-reserved)+0.0000001<spec.volumeMin)
     { err="TP parcial precisa deixar lote minimo aberto."; return false; }
   return true;
  }

bool VTpTotalPercent(void)
  {
   if(!m_draft.tp1.enabled) return true;
   double total=m_draft.tp1.percent + (m_draft.tp2.enabled ? m_draft.tp2.percent : 0.0);
   return (total<=100.0+0.0000001);
  }

//--- O TP Final Livre entrega o restante ao trailing. Sem trailing ligado, o
//--- restante ficaria sem alvo e sem gestao nenhuma.
bool VFreeTpBase(void)
  {
   if(!m_draft.tp1.enabled || !m_draft.freeFinalTP) return true;
   return m_draft.useTrailing;
  }

bool VBeOrder(void)
  {
   if(!m_draft.useBreakeven) return true;
   if(!VRange(m_draft.breakevenTriggerPoints,1,100000)) return true;
   if(!VPoints(m_draft.breakevenOffsetPoints))          return true;
   return (m_draft.breakevenOffsetPoints<=m_draft.breakevenTriggerPoints);
  }

//+------------------------------------------------------------------+
//| Protecao.                                                         |
//+------------------------------------------------------------------+
//--- Overnight INVERTE a ordem exigida: a sessao que atravessa a meia-noite
//--- comeca depois de terminar. Cobrar "fim > inicio" nos dois modos recusava
//--- justamente a configuracao que o modo existe para permitir.
bool VTimeWindowOrder(const int sh,const int sm,const int eh,const int em,
                      const bool required,const bool overnight)
  {
   if(!required) return true;
   int a=sh*60+sm, b=eh*60+em;
   return overnight ? (a>b) : (b>a);
  }

bool VSessionOrder(void)
  {
   return VTimeWindowOrder(m_draft.sessionStartHour,m_draft.sessionStartMinute,
                           m_draft.sessionEndHour,m_draft.sessionEndMinute,
                           m_draft.enableSessionFilter,m_draft.sessionOvernight);
  }

bool VNewsOrder(const int w)
  {
   if(w<0 || w>=FUSION_NEWS_WINDOW_COUNT) return true;
   return VTimeWindowOrder(m_draft.newsWindows[w].startHour,m_draft.newsWindows[w].startMinute,
                           m_draft.newsWindows[w].endHour,m_draft.newsWindows[w].endMinute,
                           m_draft.newsWindows[w].enabled,false);
  }

bool VSpread(void)
  {
   if(!m_draft.enableSpreadProtection) return (m_draft.maxSpreadPoints>=0);
   return (m_draft.maxSpreadPoints>0);
  }

//--- Meta de ganho e o gatilho do DD quando a acao do dia e ATIVAR DD: sem meta
//--- maior que zero, a protecao nunca ligaria.
bool VDayNeedsGain(void)
  {
   return !(m_draft.enableDrawdown && m_draft.enableDailyLimits &&
            m_draft.profitTargetAction==PROFIT_ACTION_ATIVAR_DD) ||
          (m_draft.maxDailyGain>0.0);
  }

//--- E o lado oposto do mesmo par: pedir ATIVAR DD sem DD configurado escolhe
//--- uma acao que nao tem o que ativar.
bool VProfitAction(void)
  {
   if(!(m_draft.enableDailyLimits && m_draft.profitTargetAction==PROFIT_ACTION_ATIVAR_DD))
      return true;
   return (m_draft.enableDrawdown && m_draft.maxDrawdown>0.0);
  }

bool VDrawdownValue(void)
  {
   if(m_draft.maxDrawdown<0.0) return false;
   if(!m_draft.enableDrawdown) return true;
   if(m_draft.maxDrawdown<=0.0) return false;
   if(m_draft.drawdownType==DD_TIPO_PERCENTUAL && m_draft.maxDrawdown>100.0) return false;
   return true;
  }

//--- O DD nao e uma protecao solta: ele so entra em cena depois que a meta do
//--- dia foi batida. Ligado sem esse caminho, jamais seria avaliado.
bool VDrawdownDependency(void)
  {
   if(!m_draft.enableDrawdown) return true;
   return (m_draft.enableDailyLimits && m_draft.maxDailyGain>0.0 &&
           m_draft.profitTargetAction==PROFIT_ACTION_ATIVAR_DD);
  }

bool VLossStreakLimit(void)
  { return (!m_draft.lossStreakEnabled || m_draft.maxLossStreak>0); }
bool VWinStreakLimit(void)
  { return (!m_draft.winStreakEnabled || m_draft.maxWinStreak>0); }
bool VLossStreakPause(void)
  { return (!LossStreakPauseEditable() || m_draft.lossStreakPauseMinutes>0); }
bool VWinStreakPause(void)
  { return (!WinStreakPauseEditable() || m_draft.winStreakPauseMinutes>0); }

//+------------------------------------------------------------------+
//| Pendencia POR SECAO — so para as tres que o EA pode suspender.    |
//|                                                                   |
//| Batido o limite, a configuracao daquela secao fica congelada ate  |
//| liberar. Alterar e nao poder gravar seria um beco; por isso a     |
//| alteracao pendente numa secao suspensa e tratada como ERRO, com a |
//| saida obvia — CANCELAR — sempre disponivel. Regra da 1.058.       |
//+------------------------------------------------------------------+
bool VDayPending(void)
  {
   if(m_draft.enableDailyLimits!=m_committed.enableDailyLimits)   return true;
   if(m_draft.profitTargetAction!=m_committed.profitTargetAction) return true;
   if(m_draft.maxDailyTrades!=m_committed.maxDailyTrades)         return true;
   if(MathAbs(m_draft.maxDailyLoss-m_committed.maxDailyLoss)>0.0000001) return true;
   if(MathAbs(m_draft.maxDailyGain-m_committed.maxDailyGain)>0.0000001) return true;
   return false;
  }

bool VDrawdownPending(void)
  {
   if(m_draft.enableDrawdown!=m_committed.enableDrawdown)     return true;
   if(m_draft.drawdownType!=m_committed.drawdownType)         return true;
   if(m_draft.drawdownPeakMode!=m_committed.drawdownPeakMode) return true;
   return (MathAbs(m_draft.maxDrawdown-m_committed.maxDrawdown)>0.0000001);
  }

bool VStreakPending(void)
  {
   if(m_draft.lossStreakEnabled!=m_committed.lossStreakEnabled) return true;
   if(m_draft.lossStreakAction!=m_committed.lossStreakAction)   return true;
   if(m_draft.winStreakEnabled!=m_committed.winStreakEnabled)   return true;
   if(m_draft.winStreakAction!=m_committed.winStreakAction)     return true;
   if(m_draft.maxLossStreak!=m_committed.maxLossStreak)         return true;
   if(m_draft.lossStreakPauseMinutes!=m_committed.lossStreakPauseMinutes) return true;
   if(m_draft.maxWinStreak!=m_committed.maxWinStreak)           return true;
   if(m_draft.winStreakPauseMinutes!=m_committed.winStreakPauseMinutes)   return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Magic — identidade do perfil.                                     |
//|                                                                   |
//| Repetido, o EA passa a adotar as ordens do outro grafico. A       |
//| resposta sai da lista ja lida do disco; o comando reconfere antes |
//| de gravar (Etapa 2c), porque entre a leitura e o clique existe    |
//| uma janela.                                                       |
//+------------------------------------------------------------------+
bool VMagicTakenByOther(const int magic,string &owner)
  {
   owner="";
   if(magic<=0) return false;
   string mine=ProfileKey(m_snap.activeProfileName);
   for(int i=0;i<m_profCount;++i)
     {
      if(m_profMagic[i]!=magic) continue;
      if(ProfileKey(m_profName[i])==mine) continue;   // o proprio perfil nao colide consigo
      owner=m_profName[i];
      return true;
     }
   return false;
  }

bool VMagic(void)
  {
   if(m_draft.magicNumber<=0) return false;
   string owner="";
   return !VMagicTakenByOther(m_draft.magicNumber,owner);
  }

//+------------------------------------------------------------------+
//| Validade de UM campo — o que pinta a caixa de vermelho.           |
//|                                                                   |
//| Um campo e invalido quando o VALOR NO RASCUNHO viola a faixa ou   |
//| uma regra cruzada de que ele participa. Texto recusado nao entra  |
//| aqui: ele nunca chega ao rascunho e o campo volta sozinho ao      |
//| ultimo valor bom (ver a nota no topo deste arquivo).              |
//|                                                                   |
//| Regra cruzada pinta os DOIS lados: com so um pintado, o usuario   |
//| corrige o campo aceso e a relacao continua quebrada.              |
//+------------------------------------------------------------------+
bool FieldValid(const int fid)
  {
   if(fid==FCV_FLD_NONE) return true;

   int w,f;
   if(NewsFieldParts(fid,w,f))
     {
      if(f>=FCV_FLD_NEWS_START_H && f<=FCV_FLD_NEWS_END_M) return VNewsOrder(w);
      return true;
     }

   switch(fid)
     {
      //--- Estrategias > Medias
      case FCV_FLD_MA_PRIORITY:    return VPriority(m_draft.maCrossPriority);
      case FCV_FLD_MA_FAST_PERIOD: return (VPeriod(m_draft.maFastPeriod) && VMaOrder());
      case FCV_FLD_MA_SLOW_PERIOD: return (VPeriod(m_draft.maSlowPeriod) && VMaOrder());
      case FCV_FLD_MA_MIN_DIST:    return VPoints(m_draft.maMinDistancePoints);

      //--- Estrategias > RSI. Nivel fora de uso nao e cobrado: a 1.058 so
      //--- valida zona e media nos modos que as leem.
      case FCV_FLD_RSI_PRIORITY:   return VPriority(m_draft.rsiPriority);
      case FCV_FLD_RSI_PERIOD:     return VPeriod(m_draft.rsiPeriod);
      case FCV_FLD_RSI_OVERSOLD:
         return (!RsiUsesZones() ||
                 (VLevel(m_draft.rsiOversold) && VRsiZoneOrder() && VRsiMiddleOrder()));
      case FCV_FLD_RSI_OVERBOUGHT:
         return (!RsiUsesZones() ||
                 (VLevel(m_draft.rsiOverbought) && VRsiZoneOrder() && VRsiMiddleOrder()));
      case FCV_FLD_RSI_MIDDLE:
         return (!RsiUsesMiddle() || (VLevel(m_draft.rsiMiddle) && VRsiMiddleOrder()));

      //--- Estrategias > Bollinger
      case FCV_FLD_BB_PRIORITY:    return VPriority(m_draft.bbPriority);
      case FCV_FLD_BB_PERIOD:      return VPeriod(m_draft.bbPeriod);
      case FCV_FLD_BB_DEVIATION:   return VDeviation(m_draft.bbDeviation);

      //--- Filtros > Tendencia. A media desligada nao e cobrada, e a ordem
      //--- entre as duas so existe com as duas ligadas.
      case FCV_FLD_TR_MA1_PERIOD:
         return (!m_draft.trendMA1Enabled ||
                 (VPeriod(m_draft.trendMAPeriod) && FusionTrendMAOrderValid(m_draft)));
      case FCV_FLD_TR_MA2_PERIOD:
         return (!m_draft.trendMA2Enabled ||
                 (VPeriod(m_draft.trendSellMAPeriod) && FusionTrendMAOrderValid(m_draft)));

      //--- Filtros > RSI
      case FCV_FLD_RF_PERIOD:  return VPeriod(m_draft.rsiFilterPeriod);
      case FCV_FLD_RF_BUYMIN:  return (VLevel(m_draft.rsiFilterBuyMin) && VRsiFilterOrder());
      case FCV_FLD_RF_SELLMAX:
         return (!RsiFilterUsesSecondLevel() ||
                 (VLevel(m_draft.rsiFilterSellMax) && VRsiFilterOrder()));

      //--- Filtros > Bollinger
      case FCV_FLD_BF_PERIOD: return VPeriod(m_draft.bbFilterPeriod);
      case FCV_FLD_BF_DEV:    return VDeviation(m_draft.bbFilterDeviation);
      case FCV_FLD_BF_MINPTS:
         return (!BbFilterAbsolute() || VRange(m_draft.bbFilterMinWidthPoints,1,100000));
      case FCV_FLD_BF_MINPCT:
         return (BbFilterAbsolute() ||
                 (m_draft.bbFilterMinWidthPercent>0.0 && m_draft.bbFilterMinWidthPercent<=100.0));
      case FCV_FLD_BF_SLOPE_BACK:
         return (!VSlopeActive() || VRange(m_draft.bbFilterSlopeLookback,1,100));
      case FCV_FLD_BF_SLOPE_MINPTS:
         return (!VSlopeActive() || VPoints(m_draft.bbFilterMinSlopePoints));

      //--- Perfis
      case FCV_FLD_MAGIC: return VMagic();

      //--- Gestao > Risco
      case FCV_FLD_FIXED_LOT:  return VLot();
      case FCV_FLD_SLIPPAGE:   return VPoints(m_draft.slippagePoints);
      case FCV_FLD_SL_POINTS:  return (VPoints(m_draft.fixedSLPoints) && VStopsLevel(m_draft.fixedSLPoints));
      case FCV_FLD_TP_POINTS:  return (VPoints(m_draft.fixedTPPoints) && VStopsLevel(m_draft.fixedTPPoints));
      case FCV_FLD_TP1_PCT:
        {
         if(!m_draft.tp1.enabled) return true;
         string ignored="";
         return (m_draft.tp1.percent>0.0 && m_draft.tp1.percent<=100.0 &&
                 VTpTotalPercent() && VPartialVolumePlan(ignored));
        }
      case FCV_FLD_TP1_DIST:
         return (!m_draft.tp1.enabled || m_draft.tp1.distancePoints>0);
      case FCV_FLD_TP2_PCT:
        {
         if(!Tp2Params()) return true;
         string ignored="";
         return (m_draft.tp2.percent>0.0 && m_draft.tp2.percent<=100.0 &&
                 VTpTotalPercent() && VPartialVolumePlan(ignored));
        }
      case FCV_FLD_TP2_DIST:
         return (!Tp2Params() || m_draft.tp2.distancePoints>0);
      case FCV_FLD_BE_TRIGGER:
         return (!m_draft.useBreakeven ||
                 (VRange(m_draft.breakevenTriggerPoints,1,100000) && VBeOrder()));
      case FCV_FLD_BE_OFFSET:
         return (!m_draft.useBreakeven ||
                 (VPoints(m_draft.breakevenOffsetPoints) && VBeOrder()));
      case FCV_FLD_TRAIL_START:
         return (!m_draft.useTrailing || VRange(m_draft.trailingStartPoints,1,100000));
      case FCV_FLD_TRAIL_STEP:
         return (!m_draft.useTrailing || VRange(m_draft.trailingStepPoints,1,100000));

      //--- Gestao > Protecao
      case FCV_FLD_SPREAD_MAX: return VSpread();
      case FCV_FLD_SESS_START_H:
      case FCV_FLD_SESS_START_M:
      case FCV_FLD_SESS_END_H:
      case FCV_FLD_SESS_END_M:
         return VSessionOrder();
      case FCV_FLD_DAY_TRADES: return (m_draft.maxDailyTrades>=0);
      case FCV_FLD_DAY_LOSS:   return (m_draft.maxDailyLoss>=0.0);
      case FCV_FLD_DAY_GAIN:   return (m_draft.maxDailyGain>=0.0 && VDayNeedsGain());
      case FCV_FLD_DD_MAX:     return (VDrawdownValue() && VDrawdownDependency());
      case FCV_FLD_LOSS_STREAK_MAX:   return VLossStreakLimit();
      case FCV_FLD_LOSS_STREAK_PAUSE: return VLossStreakPause();
      case FCV_FLD_WIN_STREAK_MAX:    return VWinStreakLimit();
      case FCV_FLD_WIN_STREAK_PAUSE:  return VWinStreakPause();
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Erro de UMA tela, na voz da 1.058.                                |
//|                                                                   |
//| Devolve "" quando nao ha erro. A ordem dos testes e a mesma dos   |
//| Validate() originais: o primeiro erro encontrado e o que aparece, |
//| e listar sete de uma vez nao ajudaria a corrigir nenhum.          |
//+------------------------------------------------------------------+
string ScreenErrorStrategyGeneral(void)
  { return VHasStrategy() ? "" : "Selecione ao menos uma estrategia."; }

string ScreenErrorMA(void)
  {
   if(!VPriority(m_draft.maCrossPriority))
      return "MA Prioridade: use valor de 0 a 1000.";
   if(!VPeriod(m_draft.maFastPeriod))
      return "MA Rapida: use periodo de 1 a 1000.";
   if(!VPeriod(m_draft.maSlowPeriod))
      return "MA Lenta: use periodo de 1 a 1000.";
   if(!VMaOrder())
      return "MA Rapida deve ser menor que MA Lenta.";
   if(!VPoints(m_draft.maMinDistancePoints))
      return "MA Dist. Min: use 0 a 100000 pontos.";
   return "";
  }

string ScreenErrorRSI(void)
  {
   if(!VPriority(m_draft.rsiPriority))
      return "RSI: prioridade deve ser 0 a 1000.";
   if(!VPeriod(m_draft.rsiPeriod))
      return "RSI: periodo deve ser 1 a 1000.";
   if(RsiUsesZones())
     {
      if(!VLevel(m_draft.rsiOversold) || !VLevel(m_draft.rsiOverbought))
         return "RSI: niveis devem ser 0 a 100.";
      if(!VRsiZoneOrder())
         return "RSI: sobrevenda < sobrecompra.";
     }
   if(RsiUsesMiddle() && !VLevel(m_draft.rsiMiddle))
      return "RSI: linha media deve ser 0 a 100.";
   if(!VRsiMiddleOrder())
      return "RSI: use sobrevenda < media < sobrecompra.";
   if(!VRsiExitCombo())
      return "RSI: entrada/saida Cruz. Media invalidas.";
   return "";
  }

string ScreenErrorBB(void)
  {
   if(!VPriority(m_draft.bbPriority))
      return "Bollinger: prioridade deve ser 0 a 1000.";
   if(!VPeriod(m_draft.bbPeriod))
      return "Bollinger: periodo deve ser 1 a 1000.";
   if(!VDeviation(m_draft.bbDeviation))
      return "Bollinger: desvio deve ser maior que 0 e ate 10.";
   return "";
  }

string ScreenErrorTrend(void)
  {
   if(m_draft.trendMA1Enabled && !VPeriod(m_draft.trendMAPeriod))
      return "Trend Filter: periodo da M1 deve ser 1 a 1000.";
   if(m_draft.trendMA2Enabled && !VPeriod(m_draft.trendSellMAPeriod))
      return "Trend Filter: periodo da M2 deve ser 1 a 1000.";
   if(!FusionTrendMAOrderValid(m_draft))
      return "Trend Filter: M1 deve ser mais longa que M2 (periodo x TF).";
   return "";
  }

string ScreenErrorRSIFilter(void)
  {
   if(!VPeriod(m_draft.rsiFilterPeriod))
      return "RSI Filter: periodo 1..1000.";
   if(!VLevel(m_draft.rsiFilterBuyMin) ||
      (RsiFilterUsesSecondLevel() && !VLevel(m_draft.rsiFilterSellMax)))
      return "RSI Filter: niveis 0..100.";
   if(!VRsiFilterOrder())
      return (m_draft.rsiFilterMode==RSI_FILTER_NEUTRAL) ? "RSI: venda < compra."
                                                         : "RSI: sobrevenda < sobrecompra.";
   return "";
  }

string ScreenErrorBBFilter(void)
  {
   if(!VPeriod(m_draft.bbFilterPeriod))
      return "BB Filter: periodo deve ser 1 a 1000.";
   if(!VDeviation(m_draft.bbFilterDeviation))
      return "BB Filter: desvio deve ser maior que 0 e ate 10.";
   if(!FieldValid(FCV_FLD_BF_MINPTS))
      return "BB Filter: largura minima em pontos deve ser 1 a 100000.";
   if(!FieldValid(FCV_FLD_BF_MINPCT))
      return "BB Filter: largura relativa deve ser maior que 0 e ate 100%.";
   if(!FieldValid(FCV_FLD_BF_SLOPE_BACK))
      return "BB Filter: inclinacao deve usar 1 a 100 candles.";
   if(!FieldValid(FCV_FLD_BF_SLOPE_MINPTS))
      return "BB Filter: inclinacao minima deve ser 0 a 100000 pontos.";
   return "";
  }

string ScreenErrorRiskLot(void)
  {
   if(!VLot())
      return "Lote Fixo invalido para o ativo atual.";
   if(!VPoints(m_draft.slippagePoints))
      return "Slippage invalido. Use 0 a 100000 pontos.";
   return "";
  }

string ScreenErrorRiskSLTP(void)
  {
   if(!VPoints(m_draft.fixedSLPoints))
      return "SL Fixo invalido. Use 0 a 100000 pontos.";
   if(!VPoints(m_draft.fixedTPPoints))
      return "TP Fixo invalido. Use 0 a 100000 pontos.";
   if(!VStopsLevel(m_draft.fixedSLPoints))
      return "SL Fixo abaixo do minimo do ativo: "+IntegerToString(m_snap.symbolSpec.stopsLevel)+" pts.";
   if(!VStopsLevel(m_draft.fixedTPPoints))
      return "TP Fixo abaixo do minimo do ativo: "+IntegerToString(m_snap.symbolSpec.stopsLevel)+" pts.";
   return "";
  }

string ScreenErrorRiskPartial(void)
  {
   if(!m_draft.tp1.enabled) return "";
   if(!(m_draft.tp1.percent>0.0 && m_draft.tp1.percent<=100.0))
      return "TP1 % deve ser maior que 0 e ate 100.";
   if(Tp2Params() && !(m_draft.tp2.percent>0.0 && m_draft.tp2.percent<=100.0))
      return "TP2 % deve ser maior que 0 e ate 100.";
   if(m_draft.tp1.distancePoints<=0)
      return "TP1 Dist deve ser maior que 0.";
   if(Tp2Params() && m_draft.tp2.distancePoints<=0)
      return "TP2 Dist deve ser maior que 0.";
   if(!VTpTotalPercent())
      return "Soma de TP1 % e TP2 % deve ser ate 100.";
   if(!VFreeTpBase())
      return "TP Final Livre exige TP1 e Trailing ativos.";
   string volumeError="";
   if(!VPartialVolumePlan(volumeError))
      return volumeError;
   return "";
  }

string ScreenErrorRiskBreakeven(void)
  {
   if(!m_draft.useBreakeven) return "";
   if(!VRange(m_draft.breakevenTriggerPoints,1,100000))
      return "BE Gatilho deve ser maior que 0 e ate 100000.";
   if(!VPoints(m_draft.breakevenOffsetPoints))
      return "BE Offset deve ficar entre 0 e 100000.";
   if(!VBeOrder())
      return "BE Offset nao pode ser maior que o gatilho.";
   return "";
  }

string ScreenErrorRiskTrailing(void)
  {
   if(!m_draft.useTrailing) return "";
   if(!VRange(m_draft.trailingStartPoints,1,100000))
      return "Trailing Inicio deve ser maior que 0 e ate 100000.";
   if(!VRange(m_draft.trailingStepPoints,1,100000))
      return "Trailing Passo deve ser maior que 0 e ate 100000.";
   return "";
  }

string ScreenErrorProtSpread(void)
  {
   if(!VSpread())
      return m_draft.enableSpreadProtection ? "Max Spread deve ser > 0 quando ativo."
                                            : "Max Spread deve ser zero ou inteiro positivo.";
   return "";
  }

string ScreenErrorProtSession(void)
  {
   if(!VSessionOrder())
      return m_draft.sessionOvernight ? "Sessao: ajuste Inicio/Fim para o modo Overnight."
                                      : "Sessao: Fim deve ser maior que Inicio.";
   return "";
  }

string ScreenErrorProtNews(void)
  {
   for(int w=0;w<FUSION_NEWS_WINDOW_COUNT;++w)
     {
      if(!VNewsOrder(w))
         return "News "+IntegerToString(w+1)+": Fim deve ser maior que Inicio.";
     }
   return "";
  }

string ScreenErrorProtDay(void)
  {
   //--- A trava vem primeiro: com a secao suspensa, qualquer alteracao ali e
   //--- impossivel de gravar, e apontar um erro de faixa mandaria corrigir o
   //--- campo errado.
   if(DailyConfigLocked() && VDayPending())
      return "DAY em bloqueio: edicao suspensa ate o novo dia.";
   if(m_draft.maxDailyTrades<0)
      return "Max Trades deve ser zero ou inteiro positivo.";
   if(m_draft.maxDailyLoss<0.0)
      return "Max Perda diario invalido.";
   if(m_draft.maxDailyGain<0.0)
      return "Max Ganho diario invalido.";
   if(!VDayNeedsGain())
      return "DD ON exige Max Ganho > 0 no DAY.";
   if(!VProfitAction())
      return "ATIVAR DD requer DD ON com Max DD > 0.";
   return "";
  }

string ScreenErrorProtDrawdown(void)
  {
   if(DrawdownConfigLocked() && VDrawdownPending())
      return "DD ativo: edicao suspensa ate liberar.";
   if(!VDrawdownValue())
     {
      if(m_draft.enableDrawdown && m_draft.drawdownType==DD_TIPO_PERCENTUAL)
         return "Max DD percentual deve ser > 0 e <= 100.";
      return m_draft.enableDrawdown ? "Max DD deve ser > 0 quando ativo."
                                    : "Max DD deve ser zero ou valor positivo.";
     }
   if(!VProfitAction())
      return "ATIVAR DD requer DD ON com Max DD > 0.";
   if(!VDrawdownDependency())
      return "DD requer DAY ON, Max Ganho > 0 e ATIVAR DD.";
   return "";
  }

string ScreenErrorProtStreak(void)
  {
   if(StreakConfigLocked() && VStreakPending())
      return "Streak em bloqueio: edicao suspensa ate liberar.";
   if(m_draft.maxLossStreak<0)
      return "Max Loss deve ser zero ou inteiro positivo.";
   if(!VLossStreakLimit())
      return "Loss Streak ON requer Max Loss maior que 0.";
   if(m_draft.lossStreakPauseMinutes<0)
      return "Pausa Loss deve ser zero ou inteiro positivo.";
   if(!VLossStreakPause())
      return "Pausa Loss deve ser maior que 0 quando acao for PAUSAR.";
   if(m_draft.maxWinStreak<0)
      return "Max Win deve ser zero ou inteiro positivo.";
   if(!VWinStreakLimit())
      return "Win Streak ON requer Max Win maior que 0.";
   if(m_draft.winStreakPauseMinutes<0)
      return "Pausa Win deve ser zero ou inteiro positivo.";
   if(!VWinStreakPause())
      return "Pausa Win deve ser maior que 0 quando acao for PAUSAR.";
   return "";
  }

//--- Perfis: o Magic e o unico campo editavel da aba.
//---
//--- ⚠ HasDuplicateMagic() NAO entra aqui, embora acenda a aba. Sao perguntas
//--- diferentes: ele responde "ha Magic repetido em ALGUM lugar do disco", e
//--- dois perfis parados que colidem entre si nao atrapalham esta conta. Posto
//--- aqui, ele entraria em ConfigInputsValid e passaria a impedir INICIAR e
//--- SALVAR por causa de arquivos que este grafico nao usa. Quem cuida do caso
//--- que importa e AccCanStart, com ActiveMagicConflicts().
string ScreenErrorProfiles(void)
  {
   if(m_draft.magicNumber<=0)
      return "Magic invalido. Informe um numero inteiro positivo.";
   //--- Dentro do formulario de criar/duplicar, o Magic do RASCUNHO nao e o que
   //--- vai ser gravado: quem manda e o do formulario, conferido por
   //--- ProfileFormReady. E na duplicacao o rascunho carrega, por definicao, o
   //--- Magic do perfil de ORIGEM — cobrar unicidade dele acusaria colisao com
   //--- o proprio arquivo que esta sendo copiado, e o CRIAR COPIA nunca
   //--- acenderia. Mesma excecao da 1.058 (`if(ProfileEditMode()) magicUnique = true`).
   if(m_profEdit!=FCV_PROF_VIEW) return "";
   string owner="";
   if(VMagicTakenByOther(m_draft.magicNumber,owner))
      return "Magic ja usado pelo perfil "+owner+".";
   return "";
  }

//+------------------------------------------------------------------+
//| Erro por identidade de tela — a mesma que indexa os slots.        |
//| Reusa-la evita uma segunda tabela de "quem e quem" que poderia    |
//| divergir da primeira.                                             |
//+------------------------------------------------------------------+
string ScreenError(const int screen)
  {
   switch(screen)
     {
      case FCV_SCREEN_STRAT0+0: return ScreenErrorStrategyGeneral();
      case FCV_SCREEN_STRAT0+1: return ScreenErrorMA();
      case FCV_SCREEN_STRAT0+2: return ScreenErrorRSI();
      case FCV_SCREEN_STRAT0+3: return ScreenErrorBB();

      case FCV_SCREEN_FILTER0+0: return "";      // panorama: nao tem campo proprio
      case FCV_SCREEN_FILTER0+1: return ScreenErrorTrend();
      case FCV_SCREEN_FILTER0+2: return ScreenErrorRSIFilter();
      case FCV_SCREEN_FILTER0+3: return ScreenErrorBBFilter();

      case FCV_SCREEN_RISK0+0: return ScreenErrorRiskLot();
      case FCV_SCREEN_RISK0+1: return ScreenErrorRiskSLTP();
      case FCV_SCREEN_RISK0+2: return ScreenErrorRiskPartial();
      case FCV_SCREEN_RISK0+3: return ScreenErrorRiskBreakeven();
      case FCV_SCREEN_RISK0+4: return ScreenErrorRiskTrailing();

      case FCV_SCREEN_PROT0+0: return "";        // Geral: so chaves, sem faixa
      case FCV_SCREEN_PROT0+1: return ScreenErrorProtSpread();
      case FCV_SCREEN_PROT0+2: return ScreenErrorProtSession();
      case FCV_SCREEN_PROT0+3: return ScreenErrorProtNews();
      case FCV_SCREEN_PROT0+4: return ScreenErrorProtDay();
      case FCV_SCREEN_PROT0+5: return ScreenErrorProtDrawdown();
      case FCV_SCREEN_PROT0+6: return ScreenErrorProtStreak();

      case FCV_SCREEN_PROFILES:
      case FCV_SCREEN_PROFILE_EDIT: return ScreenErrorProfiles();
     }
   return "";
  }

//+------------------------------------------------------------------+
//| configInputsValid — o predicado que faltava a camada de acesso.   |
//|                                                                   |
//| Ate a 2c ele valia true, o que AFROUXAVA a regra: dava para       |
//| iniciar com campo invalido. Agora ele aperta, e por isso so entra |
//| junto com os comandos: apertar antes de existir caminho de        |
//| gravacao seria trancar sem motivo.                                |
//|                                                                   |
//| Calculado UMA VEZ POR QUADRO. Ele percorre as vinte e uma telas,  |
//| e num quadro so e consultado tres vezes — INICIAR, SALVAR e CRIAR |
//| PERFIL. O rascunho nao muda no meio de um desenho, entao as tres  |
//| respostas seriam identicas por construcao.                        |
//|                                                                   |
//| O cache e invalidado no inicio do DrawFrame, e nao a cada mudanca |
//| do rascunho: toda alteracao pede redesenho, entao o quadro e a    |
//| fronteira natural — e depender de lembrar de invalidar em cada    |
//| ponto de escrita seria criar a chance de esquecer um.             |
//+------------------------------------------------------------------+
void InvalidateValidationCache(void) { m_cfgValidKnown=false; }

bool ConfigInputsValid(void)
  {
   if(!m_cfgValidKnown)
     {
      m_cfgValid=(FirstConfigError()=="");
      m_cfgValidKnown=true;
     }
   return m_cfgValid;
  }

//--- Primeiro erro na ordem em que as abas aparecem: e a ordem em que o
//--- usuario vai encontra-los ao procurar.
string FirstConfigError(void)
  {
   for(int i=0;i<4;++i)
     { string e=ScreenError(FCV_SCREEN_STRAT0+i);  if(e!="") return e; }
   for(int i=0;i<4;++i)
     { string e=ScreenError(FCV_SCREEN_FILTER0+i); if(e!="") return e; }
   for(int i=0;i<5;++i)
     { string e=ScreenError(FCV_SCREEN_RISK0+i);   if(e!="") return e; }
   for(int i=0;i<FCV_RAIL_MAX;++i)
     { string e=ScreenError(FCV_SCREEN_PROT0+i);   if(e!="") return e; }
   return ScreenError(FCV_SCREEN_PROFILES);
  }
