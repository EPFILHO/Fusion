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
      case FCV_FLD_TP1_VOL:
      case FCV_FLD_TP2_VOL:
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
bool VPeriod(const int v)   { return VRange(v,FUSION_INDICATOR_PERIOD_MIN,FUSION_INDICATOR_PERIOD_MAX); }
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

//--- MA Cross: a decisao mora em FusionMACrossConfigState (Core/Types.mqh), e o
//--- motor le do mesmo lugar. Aqui so se calam os erros de FAIXA, que tem
//--- mensagem propria e prioridade — pintar a relacao por cima de um periodo
//--- fora de faixa esconderia a causa real.
bool VMaCrossConfig(void)
  {
   if(!VPeriod(m_draft.maFastPeriod) || !VPeriod(m_draft.maSlowPeriod)) return true;
   return FusionMACrossConfigValid(m_draft);
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
//+------------------------------------------------------------------+
//| Lote — DUAS perguntas, e confundi-las deixou passar lote zero.    |
//|                                                                   |
//| Suspender `VLot()` inteiro no escopo intrinseco tirava junto a    |
//| exigencia de lote POSITIVO, que nao depende de ativo nenhum: uma  |
//| copia com lote 0 ou negativo passava a poder ser criada. As duas  |
//| metades ficam separadas aqui, escritas uma vez so, e `VLot()`     |
//| continua sendo a pergunta completa para quem ja a fazia.          |
//+------------------------------------------------------------------+
bool VLotPositive(void)
  { return (m_draft.fixedLot>0.0); }

bool VLotFitsSymbol(void)
  {
   double lot=m_draft.fixedLot;
   if(m_snap.symbolSpec.volumeMin>0.0 && lot<(m_snap.symbolSpec.volumeMin-0.0000001)) return false;
   if(m_snap.symbolSpec.volumeMax>0.0 && lot>(m_snap.symbolSpec.volumeMax+0.0000001)) return false;
   return FusionIsVolumeAligned(lot,m_snap.symbolSpec);
  }

bool VLot(void)
  { return (VLotPositive() && VLotFitsSymbol()); }

//--- Distancia menor que o minimo da corretora e ordem recusada na origem.
//--- Zero passa: zero desliga o stop, nao e uma distancia curta.
bool VStopsLevel(const int points)
  {
   if(points<=0) return true;
   int lvl=m_snap.symbolSpec.stopsLevel;
   if(lvl<=0) return true;
   return (points>=lvl);
  }

//+------------------------------------------------------------------+
//| PLANO DE VOLUMES - agora so TRADUZ o helper.                      |
//|                                                                    |
//| ⚠ `VNormalizeVolume` e `VTpTotalPercent` foram REMOVIDAS, e a      |
//| formula que vivia aqui tambem. Elas eram a terceira copia do       |
//| normalizador e uma SEGUNDA AUTORIDADE sobre o plano: "soma dos     |
//| percentuais <= 100" e apenas uma aproximacao do criterio real.     |
//| Com passo grosso, uma soma de 99 pode nao deixar o minimo aberto,  |
//| e uma de 100 pode ser recusada por outro motivo - duas portas que  |
//| discordam justamente nas bordas.                                    |
//|                                                                    |
//| Quem decide e `FusionBuildPartialVolumePlan`, o MESMO que o        |
//| RiskManager consulta. Aqui so se traduz o codigo em texto e em     |
//| qual campo acende.                                                  |
//+------------------------------------------------------------------+

//--- O volume de entrada entregue ao helper e EXATAMENTE o que o motor usa:
//--- `RiskManager::BuildEntryPlan` faz `NormalizeVolumeToSpec(fixedLot)`, que
//--- delega para esta mesma funcao. Passar uma versao "da tela" reintroduziria
//--- a divergencia que este item veio eliminar.
//+------------------------------------------------------------------+
//| Referencia viva do campo de volume: minimo, passo e maximo.        |
//|                                                                    |
//| ⚠ AQUI o `FusionFormatVolume` e o formatador certo - sao valores da |
//| propria especificacao, e as casas do passo sao exatamente o que se  |
//| quer mostrar. Ele NAO serve para o valor digitado, que precisa      |
//| aparecer bruto (ver VolumeInputText).                               |
//|                                                                    |
//| Sem esta linha, um campo chamado "Volume" convida a digitar 1 num   |
//| ativo de passo 0.01.                                                |
//+------------------------------------------------------------------+
//| RESUMO DOS VOLUMES - prestacao de contas SEQUENCIAL.               |
//|                                                                    |
//| ⚠ Substitui o "Max atual" que ficava na descricao de cada campo.   |
//| Aquele desenho era circular: o teto do TP1 dependia do TP2 e o do  |
//| TP2 dependia do TP1, entao cada dica tentava explicar a conta      |
//| inteira sozinha - e um TP2 invalido contaminava a descricao do     |
//| TP1, num texto que ainda era cortado pela largura.                 |
//|                                                                    |
//| Aqui a conta corre de cima para baixo, uma linha por etapa, e o    |
//| operador confere somando com o dedo. As descricoes dos campos      |
//| voltam a ser so o que e intrinseco: "Min. X | Passo Y".            |
//|                                                                    |
//| ⚠ Continua sendo PROJECAO VISUAL, nao autoridade. Nao aprova, nao  |
//| recusa e nao altera valor nenhum; quem decide e o plano. Se os     |
//| dois divergirem, quem esta errado e este resumo.                    |
//|                                                                    |
//| ⚠ Um valor invalido NAO apaga o que ja era conhecido: o TP2 vazio  |
//| nao pode esconder que o TP1 fecha 0.10 e restam 0.10. So a partir  |
//| do ponto quebrado a conta vira "indisponivel".                     |
//+------------------------------------------------------------------+
//--- Desce ao passo, nunca arredonda para cima: um teto arredondado para cima
//--- anunciaria um valor que o plano recusa.
double VFloorToStep(const double value)
  {
   double step=m_snap.symbolSpec.volumeStep;
   if(step<=0.0) return value;
   double steps=MathFloor(value/step + 0.0000001);
   return NormalizeDouble(steps*step,FusionVolumeDigits(step));
  }

struct SPartialSummary
  {
   bool   specKnown;
   bool   lotValid;
   double entry;
   double minLeft;
   bool   partialOn;      // TP1 ligado
   bool   tp1Valid;
   double tp1Volume;
   double afterTp1;
   double availTp1;
   bool   tp2On;
   bool   tp2Valid;
   double tp2Volume;
   double afterTp2;
   double availTp2;
   bool   availTp2Known;  // ha saldo apos TP1 para projetar o TP2?
  };

void VBuildPartialSummary(SPartialSummary &s)
  {
   s.specKnown=VVolumeSpecKnown();
   s.lotValid=false; s.entry=0.0; s.minLeft=0.0;
   s.partialOn=m_draft.tp1.enabled;
   s.tp1Valid=false; s.tp1Volume=0.0; s.afterTp1=0.0; s.availTp1=0.0;
   s.tp2On=Tp2Params(); s.tp2Valid=false; s.tp2Volume=0.0; s.afterTp2=0.0;
   s.availTp2=0.0; s.availTp2Known=false;
   if(!s.specKnown)
      return;

   s.minLeft=m_snap.symbolSpec.volumeMin;

   //--- Lote BRUTO primeiro: normalizar antes esconderia 0.125 como 0.13.
   if(!VLot())
      return;
   s.lotValid=true;
   s.entry=FusionNormalizePartialVolume(m_draft.fixedLot,m_snap.symbolSpec);
   s.availTp1=VFloorToStep(MathMin(s.entry-s.minLeft,m_snap.symbolSpec.volumeMax));
   if(!s.partialOn)
      return;

   //--- ⚠ MESMO tradutor que o plano usa para virar percentual em volume.
   //--- Escrever a conta `entrada * pct / 100` aqui seria a terceira copia.
   double v1=0.0;
   if(!FusionPartialStageVolume(m_draft.partialSizeMode,m_draft.tp1,s.entry,
                                m_snap.symbolSpec,v1))
      return;
   s.tp1Valid=true;
   s.tp1Volume=v1;
   s.afterTp1=s.entry-v1;
   if(s.afterTp1-s.minLeft > -0.0000001)
     {
      s.availTp2=VFloorToStep(MathMin(s.afterTp1-s.minLeft,m_snap.symbolSpec.volumeMax));
      s.availTp2Known=(s.availTp2+0.0000001>=s.minLeft);
     }
   if(!s.tp2On)
      return;

   double v2=0.0;
   if(!FusionPartialStageVolume(m_draft.partialSizeMode,m_draft.tp2,s.entry,
                                m_snap.symbolSpec,v2))
      return;
   s.tp2Valid=true;
   s.tp2Volume=v2;
   s.afterTp2=s.afterTp1-v2;
  }

//--- Volume no formato do ativo, para as linhas do resumo.
string VSummaryVol(const double v)
  { return FusionFormatVolume(v,m_snap.symbolSpec); }
//--- Dica do campo: SO o que e intrinseco ao ativo.
//---
//--- ⚠ Curta de proposito, e igual nos dois estagios. Nada que dependa do
//--- OUTRO campo entra aqui: era isso que fazia um TP2 invalido contaminar a
//--- descricao do TP1, num texto que a largura ainda cortava. O que depende da
//--- sequencia mora no RESUMO DOS VOLUMES.
string PartialFieldHint(void)
  {
   if(!VVolumeSpecKnown())
      return "Especificacao de volume do ativo indisponivel.";
   return "Min. "+FusionFormatVolume(m_snap.symbolSpec.volumeMin,m_snap.symbolSpec)+
          " | Passo "+FusionFormatVolume(m_snap.symbolSpec.volumeStep,m_snap.symbolSpec);
  }

//--- Percentual sem zeros inuteis: "50%", nunca "50.00%". O rotulo divide a
//--- linha com o numero da direita, e duas casas que nao dizem nada so gastam
//--- largura - a mesma largura que faz a tabela cortar.
string VSummaryPercentText(const double pct)
  {
   string text=DoubleToString(pct,2);
   if(StringFind(text,".")<0)
      return text;
   int len=StringLen(text);
   while(len>0 && StringGetCharacter(text,len-1)=='0')
      len--;
   if(len>0 && StringGetCharacter(text,len-1)=='.')
      len--;
   return StringSubstr(text,0,len);
  }

//--- "TP1" no modo volume; "TP1 50%" no percentual. O percentual aparece no
//--- rotulo para o operador ligar o que digitou ao volume que sai.
string VSummaryStageLabel(const bool isTp1)
  {
   string name=isTp1 ? "TP1" : "TP2";
   if(m_draft.partialSizeMode!=PARTIAL_SIZE_PERCENT)
      return name;
   double pct=isTp1 ? m_draft.tp1.percent : m_draft.tp2.percent;
   if(!MathIsValidNumber(pct) || pct<=0.0)
      return name;
   return name+" "+VSummaryPercentText(pct)+"%";
  }

//+------------------------------------------------------------------+
//| ORIENTACAO pelo CODIGO de recusa.                                  |
//|                                                                    |
//| ⚠ A versao anterior escolhia a frase so pelo MODO e a colava em    |
//| todos os motivos: um volume 0.125 desalinhado do passo 0.01 vinha  |
//| com "ou aumente o Lote Fixo" - e aumentar o lote NAO transforma    |
//| 0.125 em multiplo de 0.01. A tela mandava fazer o que nao resolve. |
//|                                                                    |
//| A divisao agora e nitida:                                          |
//|                                                                    |
//|   o CODIGO escolhe a NATUREZA do erro e o que se ensina;           |
//|   o MODO escolhe apenas COMO o campo se chama - "Volume" ou        |
//|     "percentual" -, nunca qual e o remedio;                        |
//|   o LOTE FIXO so e citado em ENTRY_INVALID, onde o defeito e dele. |
//|                                                                    |
//| ⚠ Os erros de falta de saldo (TOO_BIG, NO_MIN_LEFT) NAO oferecem   |
//| aumentar o lote, ainda que isso resolvesse a aritmetica no modo    |
//| volume: quem le so "aumente o lote" aumenta o risco da operacao    |
//| para contornar uma regra que nao entendeu. Esses casos ENSINAM A   |
//| REGRA - TP1 e TP2 sao saidas parciais.                             |
//|                                                                    |
//| ⚠ E nao se promete que o restante SERA encerrado: TP Fixo,         |
//| trailing, SL e saida por sinal podem estar todos desligados no     |
//| perfil. Diz-se que o volume DEVE PERMANECER aberto para o          |
//| mecanismo configurado - e, na sugestao, que o TP Fixo precisa ser  |
//| CONFIGURADO.                                                       |
//|                                                                    |
//| Nunca se procura palavra dentro do texto do erro: o codigo e dado. |
//+------------------------------------------------------------------+
string PartialFixAdvice(const int code)
  {
   bool volumeMode=(m_draft.partialSizeMode==PARTIAL_SIZE_VOLUME);

   switch(code)
     {
      case FUSION_PARTIAL_PLAN_MODE_INVALID:
         return "Selecione Percentual ou Volume.";

      //--- Nao ha o que o operador ajuste: o ativo nao respondeu.
      case FUSION_PARTIAL_PLAN_SPEC_UNKNOWN:
         return "";

      case FUSION_PARTIAL_PLAN_ENTRY_INVALID:
         return "Corrija o Lote Fixo, na tela Lote.";

      case FUSION_PARTIAL_PLAN_TP1_INVALID:
         return volumeMode
                ? "Ajuste o Volume do TP1 para respeitar o minimo, o maximo e o passo do ativo."
                : "Ajuste o percentual do TP1 para um valor entre 0 e 100.";
      case FUSION_PARTIAL_PLAN_TP2_INVALID:
         return volumeMode
                ? "Ajuste o Volume do TP2 para respeitar o minimo, o maximo e o passo do ativo."
                : "Ajuste o percentual do TP2 para um valor entre 0 e 100.";

      //--- ⚠ Fala SO do TP1: aqui o TP2 pode estar desligado, e cita-lo mandaria
      //--- conferir um estagio que nem participa do problema.
      case FUSION_PARTIAL_PLAN_TP1_TOO_BIG:
         return "O TP1 e uma saida parcial e precisa deixar pelo menos o volume minimo "
                "aberto para o encerramento final. " +
                (volumeMode ? "Reduza o Volume do TP1." : "Reduza o percentual do TP1.");

      case FUSION_PARTIAL_PLAN_TP2_TOO_BIG:
         return "TP1 e TP2 sao saidas parciais e precisam deixar pelo menos o volume "
                "minimo aberto para o encerramento final. " +
                (volumeMode ? "Reduza o Volume do TP2." : "Reduza o percentual do TP2.") +
                " Se deseja apenas dois niveis de saida, use o TP1 para a primeira "
                "parcial e configure o TP Fixo para encerrar o restante.";

      //--- O motivo do helper ja diz "precisa deixar o volume minimo aberto",
      //--- entao aqui NAO se repete a regra: diz-se para que o saldo serve.
      case FUSION_PARTIAL_PLAN_NO_MIN_LEFT:
         return "O volume restante deve permanecer aberto para o mecanismo de "
                "encerramento final configurado, como TP Fixo, trailing, SL ou sinal "
                "da estrategia. " +
                (volumeMode ? "Reduza o total reservado pelos parciais."
                            : "Reduza os percentuais dos parciais.") +
                " Se deseja apenas dois niveis de saida, use o TP1 para a primeira "
                "parcial e configure o TP Fixo para encerrar o restante.";
     }
   return "";
  }

int VPartialPlanCode(void)
  {
   SPartialVolumePlan plan;
   double entry=FusionNormalizePartialVolume(m_draft.fixedLot,m_snap.symbolSpec);
   FusionBuildPartialVolumePlan(entry,m_draft.partialSizeMode,
                                m_draft.tp1,m_draft.tp2,m_snap.symbolSpec,plan);
   return plan.code;
  }

//--- Adaptador: chama o helper UMA vez e devolve motivo E codigo. O codigo sai
//--- junto de proposito - quem monta a mensagem precisa dele para escolher a
//--- orientacao, e uma segunda chamada so para descobri-lo rodaria o plano
//--- inteiro de novo.
bool VPartialVolumePlan(string &err,int &code)
  {
   err=""; code=FUSION_PARTIAL_PLAN_DISABLED;
   if(!m_draft.tp1.enabled) return true;
   code=VPartialPlanCode();
   if(code==FUSION_PARTIAL_PLAN_OK || code==FUSION_PARTIAL_PLAN_DISABLED)
      return true;
   err=FusionPartialPlanReason(code);
   return false;
  }

//+------------------------------------------------------------------+
//| Este codigo de recusa pertence a ESTE campo?                      |
//|                                                                    |
//| ⚠ `NO_MIN_LEFT`, `ENTRY_INVALID` e `SPEC_UNKNOWN` NAO marcam campo |
//| nenhum. O primeiro nasce da COMBINACAO dos estagios - TP1 e TP2    |
//| podem ser individualmente negociaveis, e pintar "o ultimo" de      |
//| vermelho acusaria um campo valido. Os outros dois sao do ativo ou  |
//| do lote, nao do que foi digitado aqui.                             |
//+------------------------------------------------------------------+
bool VPartialCodeBlamesField(const int code,const int fid)
  {
   if(code==FUSION_PARTIAL_PLAN_MODE_INVALID)
      return (fid==FCV_FLD_PARTIAL_MODE);
   if(code==FUSION_PARTIAL_PLAN_TP1_INVALID || code==FUSION_PARTIAL_PLAN_TP1_TOO_BIG)
      return (fid==FCV_FLD_TP1_PCT || fid==FCV_FLD_TP1_VOL);
   if(code==FUSION_PARTIAL_PLAN_TP2_INVALID || code==FUSION_PARTIAL_PLAN_TP2_TOO_BIG)
      return (fid==FCV_FLD_TP2_PCT || fid==FCV_FLD_TP2_VOL);
   return false;
  }

//--- O campo de tamanho de um estagio esta valido?
//---
//--- ⚠ No escopo de DUPLICAR (`!m_vSymbolRules`) o plano NAO e consultado: ele
//--- depende da spec do ativo, e a duplicacao existe para guardar um perfil de
//--- outro simbolo. So as regras INTRINSECAS valem ali. E nao se espera receber
//--- MODE_INVALID do helper nesse caso: a ordem dele devolve SPEC_UNKNOWN antes
//--- de olhar o modo, entao o modo e conferido aqui, direto.
bool VPartialStageField(const int fid,const bool stageActive)
  {
   if(!stageActive) return true;

   //--- ⚠ Modo fora do enum deixa o campo do estagio NEUTRO, e nao vermelho.
   //--- Quem acusa e o proprio seletor (FCV_FLD_PARTIAL_MODE) e a mensagem de
   //--- ScreenErrorRiskPartial. Pintar TP1 e TP2 junto mandaria corrigir dois
   //--- campos que podem estar perfeitos, e contradiria VPartialCodeBlamesField,
   //--- que so culpa o seletor por MODE_INVALID.
   if(!FusionPartialSizeModeValid((int)m_draft.partialSizeMode))
      return true;

   //--- ⚠ O ESTAGIO e decidido pelo PAR de IDs, nunca por um campo so. Escrito
   //--- como `(fid==FCV_FLD_TP1_PCT) ? tp1.percent : tp2.percent`, um TP1_VOL
   //--- consultado no modo percentual caia no ramo do TP2 e julgava o estagio
   //--- errado. Hoje o campo incompativel com o modo fica oculto e o defeito nao
   //--- aparece - mas a funcao precisa estar certa para os QUATRO IDs.
   bool isTp1=(fid==FCV_FLD_TP1_PCT || fid==FCV_FLD_TP1_VOL);
   bool volumeMode=(m_draft.partialSizeMode==PARTIAL_SIZE_VOLUME);
   double percent=isTp1 ? m_draft.tp1.percent : m_draft.tp2.percent;
   double volume =isTp1 ? m_draft.tp1.volume  : m_draft.tp2.volume;

   //--- Intrinseco: vale nos dois escopos.
   if(volumeMode)
     {
      if(!MathIsValidNumber(volume) || volume<=0.0) return false;
     }
   else
     {
      if(!MathIsValidNumber(percent) || percent<=0.0 || percent>100.0) return false;
     }

   if(!m_vSymbolRules) return true;
   return !VPartialCodeBlamesField(VPartialPlanCode(),fid);
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
//+------------------------------------------------------------------+
//| Horario: FAIXA e depois ORDEM.                                    |
//|                                                                   |
//| ⚠ A faixa parece redundante e nao e. O que se DIGITA nunca sai da |
//| faixa — TimePartValue recorta na entrada, e "99" vira 23 numa hora |
//| e 59 num minuto. Mas o rascunho tem uma segunda porta: o ARQUIVO   |
//| DE PERFIL, e o desserializador nao recorta nada                    |
//| (`ProfileSettingsSerializer`: `StringToInteger(value)` direto). Um |
//| arquivo editado a mao, ou vindo de outra versao, entra com 25:00 e |
//| a ordem sozinha aprovaria — SALVAR e INICIAR acesos sobre um       |
//| horario que o EA nunca vai conseguir usar, e uma janela de noticia |
//| que jamais dispararia. A 1.058 conferia as quatro faixas de        |
//| proposito (`ProtectionTimeValue(texto, 23/59, ...)`).              |
//+------------------------------------------------------------------+
bool VTimeValid(const int h,const int m)
  { return (VRange(h,0,FCV_HOUR_MAX) && VRange(m,0,FCV_MINUTE_MAX)); }

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

//--- A faixa vale SEMPRE, ligada ou desligada: um horario impossivel gravado no
//--- perfil continua impossivel quando alguem ligar a secao. A ordem, essa, so
//--- e cobrada com a secao ativa — configurar antes de ligar e uso legitimo.
bool VSessionTimeValid(void)
  {
   return (VTimeValid(m_draft.sessionStartHour,m_draft.sessionStartMinute) &&
           VTimeValid(m_draft.sessionEndHour,m_draft.sessionEndMinute));
  }

bool VSessionOrder(void)
  {
   return VTimeWindowOrder(m_draft.sessionStartHour,m_draft.sessionStartMinute,
                           m_draft.sessionEndHour,m_draft.sessionEndMinute,
                           m_draft.enableSessionFilter,m_draft.sessionOvernight);
  }

bool VNewsTimeValid(const int w)
  {
   if(w<0 || w>=FUSION_NEWS_WINDOW_COUNT) return true;
   return (VTimeValid(m_draft.newsWindows[w].startHour,m_draft.newsWindows[w].startMinute) &&
           VTimeValid(m_draft.newsWindows[w].endHour,m_draft.newsWindows[w].endMinute));
  }

bool VNewsOrder(const int w)
  {
   if(w<0 || w>=FUSION_NEWS_WINDOW_COUNT) return true;
   return VTimeWindowOrder(m_draft.newsWindows[w].startHour,m_draft.newsWindows[w].startMinute,
                           m_draft.newsWindows[w].endHour,m_draft.newsWindows[w].endMinute,
                           m_draft.newsWindows[w].enabled,false);
  }

//+------------------------------------------------------------------+
//| Modo de filtro vindo do arquivo.                                  |
//|                                                                   |
//| Mesma porta dos horarios: o combo nao consegue escolher um modo   |
//| que nao existe, mas o perfil em disco pode trazer um. O combo     |
//| ATE DISFARCA — ele limita o indice e mostra a opcao zero —,       |
//| enquanto o rascunho segue com o enum invalido e seria gravado e   |
//| operado assim. A 1.058 recusa (`ModeValid`), e essa e a checagem  |
//| que faltou portar.                                                |
//+------------------------------------------------------------------+
bool VRsiFilterMode(void)
  {
   return (m_draft.rsiFilterMode==RSI_FILTER_DIRECTION ||
           m_draft.rsiFilterMode==RSI_FILTER_NEUTRAL   ||
           m_draft.rsiFilterMode==RSI_FILTER_EXTREMES);
  }

bool VBbFilterMode(void)
  {
   return (m_draft.bbFilterMode==BB_FILTER_WIDTH_ABSOLUTE ||
           m_draft.bbFilterMode==BB_FILTER_WIDTH_RELATIVE);
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

//+------------------------------------------------------------------+
//| REGRAS QUE ATRAVESSAM TELAS                                       |
//|                                                                   |
//| A cadeia de erro do painel e VERTICAL — item do trilho sobe para  |
//| a subaba e para a aba —, e ela pressupoe que todo erro tem UM     |
//| dono. Algumas regras nao tem: ligam duas telas IRMAS, e podem ser |
//| resolvidas em qualquer uma das duas.                              |
//|                                                                   |
//| Acusando so uma, o vermelho nao chega onde se corrige. O usuario  |
//| ligou o TP Final Livre e o painel acendia apenas TP Parcial —     |
//| enquanto o que faltava era ativar o Trailing, numa tela que       |
//| continuava limpa. Pior: a mensagem dizia "exige TP1 e Trailing    |
//| ativos" com o TP1 JA ativo, mandando corrigir o que estava certo. |
//|                                                                   |
//| A regra que fica, em duas metades:                                |
//|                                                                   |
//|  1. as DUAS telas envolvidas consultam o mesmo predicado, e por   |
//|     isso as duas acendem. Nao precisou de mecanismo novo — o      |
//|     RailHasError so pergunta ScreenError(tela), entao basta as    |
//|     duas responderem. `VProfitAction` ja fazia isso e funcionava; |
//|     as outras e que nao estavam consistentes.                     |
//|  2. o TEXTO e de cada tela, nao da regra. Ele muda de direcao     |
//|     conforme de onde se olha, e precisa NOMEAR A OUTRA — senao o  |
//|     usuario chega na segunda tela, nao ve nada errado nos campos  |
//|     dela e fica pior do que antes.                                |
//|                                                                   |
//| E a mensagem cita o que FALTA, nunca a lista inteira de           |
//| requisitos: listar tres quando um esta faltando faz o usuario     |
//| conferir dois que ja estao certos.                                |
//+------------------------------------------------------------------+
//--- A especificacao de volume do ativo esta disponivel? Sem ela nao da para
//--- julgar o plano de volumes, e sugerir "aumente o lote" seria palpite.
bool VVolumeSpecKnown(void)
  {
   return (m_snap.symbolSpec.volumeMin>0.0 && m_snap.symbolSpec.volumeStep>0.0 &&
           m_snap.symbolSpec.volumeMax>0.0);
  }

//--- Qual das tres condicoes do DD esta faltando, em uma frase. A ordem e a
//--- mesma de VDrawdownDependency, para o texto nunca acusar uma condicao que
//--- o predicado nao esta reprovando.
string DrawdownDependencyMissing(void)
  {
   if(!m_draft.enableDailyLimits)          return "os Limites Diarios estao desligados";
   if(m_draft.maxDailyGain<=0.0)           return "o Max Ganho esta em zero";
   if(m_draft.profitTargetAction!=PROFIT_ACTION_ATIVAR_DD)
      return "a acao do Ganho nao e Ativar DD";
   return "";
  }

//--- E o que falta do outro lado do mesmo par.
string ProfitActionMissing(void)
  {
   if(!m_draft.enableDrawdown) return "o DD esta desligado";
   return "o Max DD esta em zero";
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
      if(f>=FCV_FLD_NEWS_START_H && f<=FCV_FLD_NEWS_END_M)
         return (VNewsTimeValid(w) && VNewsOrder(w));
      return true;
     }

   switch(fid)
     {
      //--- Estrategias > Medias
      case FCV_FLD_MA_PRIORITY:    return VPriority(m_draft.maCrossPriority);
      case FCV_FLD_MA_FAST_PERIOD: return (VPeriod(m_draft.maFastPeriod) && VMaCrossConfig());
      case FCV_FLD_MA_SLOW_PERIOD: return (VPeriod(m_draft.maSlowPeriod) && VMaCrossConfig());
      //--- Os oito campos participam da mesma relacao, entao os oito pintam
      //--- quando ela quebra: a correcao pode ser em qualquer um deles, e
      //--- marcar so os periodos apontaria para o lugar errado quando o
      //--- problema esta no timeframe, no metodo ou no preco.
      case FCV_FLD_MA_FAST_TF:
      case FCV_FLD_MA_FAST_METHOD:
      case FCV_FLD_MA_FAST_PRICE:
      case FCV_FLD_MA_SLOW_TF:
      case FCV_FLD_MA_SLOW_METHOD:
      case FCV_FLD_MA_SLOW_PRICE:  return VMaCrossConfig();
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

      //--- Filtros > RSI. O modo tambem e campo: um enum que nao existe chegou
      //--- pelo arquivo, e o combo o exibe como se fosse o primeiro da lista.
      case FCV_FLD_RF_MODE:    return VRsiFilterMode();
      case FCV_FLD_RF_PERIOD:  return VPeriod(m_draft.rsiFilterPeriod);
      case FCV_FLD_RF_BUYMIN:  return (VLevel(m_draft.rsiFilterBuyMin) && VRsiFilterOrder());
      case FCV_FLD_RF_SELLMAX:
         return (!RsiFilterUsesSecondLevel() ||
                 (VLevel(m_draft.rsiFilterSellMax) && VRsiFilterOrder()));

      //--- Filtros > Bollinger
      case FCV_FLD_BF_MODE:   return VBbFilterMode();
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
      //--- Os quatro campos de tamanho passam pelo mesmo tradutor. Nenhum deles
      //--- soma percentual nem recalcula volume.
      case FCV_FLD_TP1_PCT:
      case FCV_FLD_TP1_VOL:
         return VPartialStageField(fid,m_draft.tp1.enabled);
      case FCV_FLD_TP1_DIST:
         return (!m_draft.tp1.enabled || m_draft.tp1.distancePoints>0);
      case FCV_FLD_TP2_PCT:
      case FCV_FLD_TP2_VOL:
         return VPartialStageField(fid,Tp2Params());
      case FCV_FLD_TP2_DIST:
         return (!Tp2Params() || m_draft.tp2.distancePoints>0);
      //--- O seletor so acende quando o proprio modo esta fora do enum.
      case FCV_FLD_PARTIAL_MODE:
         return FusionPartialSizeModeValid((int)m_draft.partialSizeMode);
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
         return (VSessionTimeValid() && VSessionOrder());
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
   //--- Uma causa, uma mensagem. A antiga ("MA Rapida deve ser menor que MA
   //--- Lenta") dizia ao usuario para consertar o periodo mesmo quando o
   //--- problema era o timeframe, e ensinava a regra errada.
   ENUM_MA_CROSS_CONFIG maState = FusionMACrossConfigState(m_draft);
   if(maState == MA_CROSS_CONFIG_IDENTICAL)
      return "MA Rapida e MA Lenta precisam diferir em periodo, timeframe, metodo ou preco.";
   if(maState == MA_CROSS_CONFIG_FAST_LONGER)
      return "Horizonte da MA Rapida nao pode ser maior que o da MA Lenta (periodo x TF).";
   //--- PERIOD_RANGE nao chega aqui: os dois VPeriod acima ja devolveram a
   //--- mensagem de faixa, que tem prioridade. A guarda generica fica porque o
   //--- predicado e compartilhado e pode ganhar estados novos.
   if(maState != MA_CROSS_CONFIG_OK)
      return "MA Cross: periodo ou timeframe das medias nao produzem horizonte valido.";
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
      return "Trend Filter: periodo da MA1 deve ser 1 a 1000.";
   if(m_draft.trendMA2Enabled && !VPeriod(m_draft.trendSellMAPeriod))
      return "Trend Filter: periodo da MA2 deve ser 1 a 1000.";
   if(!FusionTrendMAOrderValid(m_draft))
      return "Trend Filter: MA1 deve ser mais longa que MA2 (periodo x TF).";
   return "";
  }

string ScreenErrorRSIFilter(void)
  {
   if(!VRsiFilterMode())
      return "RSI Filter: modo invalido.";
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
   if(!VBbFilterMode())
      return "BB Filter: modo invalido.";
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
   //--- INTRINSECA: lote positivo vale em qualquer ativo, e vale nos dois escopos.
   if(!VLotPositive())
      return "Lote Fixo deve ser maior que 0.";
   //--- REGRA DO ATIVO: faixa e alinhamento ao step, suspensas no DUPLICAR.
   if(m_vSymbolRules && !VLotFitsSymbol())
      return "Lote Fixo invalido para o ativo atual.";
   if(!VPoints(m_draft.slippagePoints))
      return "Slippage invalido. Use 0 a 100000 pontos.";
   //--- CRUZADA com TP Parcial: o plano de volumes depende do lote, e a saida
   //--- pode estar aqui. Num ativo cujo minimo e 1 contrato, nenhuma divisao
   //--- percentual fecha — e a tela do TP Parcial dizia isso sem nunca citar o
   //--- lote, deixando o usuario mexendo nos percentuais para sempre.
   //---
   //--- So depois dos erros PROPRIOS desta tela: com o lote ja invalido, o
   //--- plano falha por consequencia, e apontar o plano esconderia a causa.
   //--- REGRA DO ATIVO: o plano de volumes so existe contra a spec do simbolo.
   if(m_vSymbolRules && VVolumeSpecKnown())
     {
      string volumeError=""; int planCode=FUSION_PARTIAL_PLAN_DISABLED;
      if(!VPartialVolumePlan(volumeError,planCode))
        {
         //--- ⚠ A orientacao vem do CODIGO, e nao colada por modo. Ver
         //--- PartialFixAdvice: mandar "aumente o Lote Fixo" num volume
         //--- desalinhado do passo seria mandar fazer o que nao resolve.
         string advice=PartialFixAdvice(planCode);
         return "O TP Parcial nao cabe neste volume de entrada: "+volumeError+
                (advice=="" ? "" : " "+advice);
        }
     }
   return "";
  }

string ScreenErrorRiskSLTP(void)
  {
   if(!VPoints(m_draft.fixedSLPoints))
      return "SL Fixo invalido. Use 0 a 100000 pontos.";
   if(!VPoints(m_draft.fixedTPPoints))
      return "TP Fixo invalido. Use 0 a 100000 pontos.";
   //--- REGRA DO ATIVO: stops level e do simbolo do grafico.
   if(m_vSymbolRules && !VStopsLevel(m_draft.fixedSLPoints))
      return "SL Fixo abaixo do minimo do ativo: "+IntegerToString(m_snap.symbolSpec.stopsLevel)+" pts.";
   if(m_vSymbolRules && !VStopsLevel(m_draft.fixedTPPoints))
      return "TP Fixo abaixo do minimo do ativo: "+IntegerToString(m_snap.symbolSpec.stopsLevel)+" pts.";
   return "";
  }

string ScreenErrorRiskPartial(void)
  {
   if(!m_draft.tp1.enabled) return "";

   //--- ⚠ O modo vem antes de tudo: com ele fora do enum nao ha campo de
   //--- tamanho que se possa julgar.
   if(!FusionPartialSizeModeValid((int)m_draft.partialSizeMode))
      return "Modo de tamanho do TP Parcial invalido. Escolha Percentual ou Volume.";

   bool volumeMode=(m_draft.partialSizeMode==PARTIAL_SIZE_VOLUME);

   //--- INTRINSECO: vale nos dois escopos, inclusive na duplicacao.
   if(volumeMode)
     {
      if(!MathIsValidNumber(m_draft.tp1.volume) || m_draft.tp1.volume<=0.0)
         return "Volume do TP1 deve ser maior que zero.";
      if(Tp2Params() && (!MathIsValidNumber(m_draft.tp2.volume) || m_draft.tp2.volume<=0.0))
         return "Volume do TP2 deve ser maior que zero.";
     }
   else
     {
      if(!(m_draft.tp1.percent>0.0 && m_draft.tp1.percent<=100.0))
         return "TP1 % deve ser maior que 0 e ate 100.";
      if(Tp2Params() && !(m_draft.tp2.percent>0.0 && m_draft.tp2.percent<=100.0))
         return "TP2 % deve ser maior que 0 e ate 100.";
     }

   if(m_draft.tp1.distancePoints<=0)
      return "TP1 Dist deve ser maior que 0.";
   if(Tp2Params() && m_draft.tp2.distancePoints<=0)
      return "TP2 Dist deve ser maior que 0.";

   //--- ⚠ A soma dos percentuais NAO e mais conferida aqui. Ela era uma segunda
   //--- autoridade sobre o plano, e aproximada: com passo grosso, 99 pode nao
   //--- deixar o minimo e 100 pode ser recusado por outra razao. Quem decide e
   //--- o helper, logo abaixo, com o mesmo criterio que o motor usa.

   //--- CRUZADA com Trailing. O texto cita so o que FALTA: o TP1 e condicao da
   //--- regra, mas so se chega aqui com ele ligado, entao nomea-lo mandaria
   //--- conferir o que ja esta certo.
   if(!VFreeTpBase())
      return "TP Final Livre exige o Trailing ativo. Ative o Trailing, na tela "
             "Trailing, ou desligue o TP Final Livre aqui.";

   //--- REGRA DO ATIVO: suspensa na duplicacao, onde o perfil pode ser de outro
   //--- simbolo. As checagens acima sao intrinsecas e continuam valendo la.
   string volumeError=""; int planCode=FUSION_PARTIAL_PLAN_DISABLED;
   if(m_vSymbolRules && !VPartialVolumePlan(volumeError,planCode))
     {
      string advice=PartialFixAdvice(planCode);
      return volumeError+(advice=="" ? "" : " "+advice);
     }
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
   //--- CRUZADA com TP Parcial, e ANTES do retorno de "trailing desligado": e
   //--- justamente com ele desligado que a regra dispara. Depois do retorno,
   //--- esta tela ficaria eternamente limpa enquanto e nela que se corrige.
   if(!VFreeTpBase())
      return "O TP Final Livre, ligado em TP Parcial, exige o Trailing ativo. "
             "Ative-o aqui ou desligue o TP Final Livre la.";
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
   if(!VSessionTimeValid())
      return "Horario da sessao invalido: hora 0..23, minuto 0..59.";
   if(!VSessionOrder())
      return m_draft.sessionOvernight ? "Sessao: ajuste Inicio/Fim para o modo Overnight."
                                      : "Sessao: Fim deve ser maior que Inicio.";
   return "";
  }

string ScreenErrorProtNews(void)
  {
   for(int w=0;w<FUSION_NEWS_WINDOW_COUNT;++w)
     {
      if(!VNewsTimeValid(w))
         return "Horario da News "+IntegerToString(w+1)+
                " invalido: hora 0..23, minuto 0..59.";
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
   //--- CRUZADAS com Drawdown, as tres. Antes elas so acusavam de um lado: com
   //--- o DD ligado e os Limites Diarios desligados, so a tela do Drawdown
   //--- acendia — e a correcao estava AQUI.
   //---
   //--- VDayNeedsGain vem primeiro por ser o caso mais estreito (esta contido em
   //--- VDrawdownDependency) e por isso rende a frase mais precisa.
   if(!VDayNeedsGain())
      return "O DD depende do Max Ganho desta tela, que esta em zero. Informe um "
             "valor aqui ou desligue o DD, na tela Drawdown.";
   if(!VDrawdownDependency())
      return "O DD esta ligado e depende desta tela: "+DrawdownDependencyMissing()+
             ". Ajuste aqui ou desligue o DD, na tela Drawdown.";
   if(!VProfitAction())
      return "A acao do Ganho e Ativar DD, mas "+ProfitActionMissing()+
             ". Configure o DD, na tela Drawdown, ou escolha Parar aqui.";
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
   //--- CRUZADAS com Limites Diarios. VDrawdownDependency contem o caso do
   //--- VDayNeedsGain, entao a frase dele ja cobre o Max Ganho em zero por
   //--- aqui — nao ha checagem separada a acrescentar.
   if(!VProfitAction())
      return "Limites Diarios pede Ativar DD, mas "+ProfitActionMissing()+
             ". Ajuste aqui ou mude a acao do Ganho, na tela Limites Diarios.";
   if(!VDrawdownDependency())
      return "O DD so entra em acao depois da meta do dia, e "+DrawdownDependencyMissing()+
             ". Ajuste em Limites Diarios ou desligue o DD aqui.";
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
//--- que importa e a escada de ResolveHeaderActionState, com
//--- ActiveMagicConflicts() — e la o motivo vira texto na faixa do cabecalho.
string ScreenErrorProfiles(void)
  {
   //--- ⚠ A SAIDA DO FORMULARIO VEM PRIMEIRO, e a ordem inversa era um defeito.
   //--- Dentro do NOVO ou do DUPLICAR, o Magic do RASCUNHO e a identidade
   //--- ANTIGA — a do perfil ativo, ou a do perfil de origem — e ela NAO vai ser
   //--- gravada: quem vai e o numero digitado no formulario, conferido por
   //--- `ProfileFormReady` e reconferido no disco por `MagicFreeOnDisk` dentro
   //--- do `ExecuteCreate`.
   //---
   //--- Cobrando `magicNumber<=0` antes desta saida, um perfil de origem com
   //--- Magic 0 — arquivo antigo, ou editado por fora — ficava impossivel de
   //--- DUPLICAR, mesmo com o usuario informando um Magic novo e valido. Ou
   //--- seja: a tela recusava justamente a operacao que RECUPERA o arquivo.
   //---
   //--- E a unicidade tem o mesmo motivo de sair daqui: na duplicacao o rascunho
   //--- carrega, por definicao, o Magic do perfil de ORIGEM, e cobra-la acusaria
   //--- colisao com o proprio arquivo que esta sendo copiado. Mesma excecao da
   //--- 1.058 (`if(ProfileEditMode()) magicUnique = true`).
   if(m_profEdit!=FCV_PROF_VIEW)
      return "";

   //--- Fora do formulario, o rascunho E o perfil ativo: aqui as duas regras
   //--- valem inteiras.
   if(m_draft.magicNumber<=0)
      return "Magic invalido. Informe um numero inteiro positivo.";
   string owner="";
   if(VMagicTakenByOther(m_draft.magicNumber,owner))
      return "Magic ja usado pelo perfil "+owner+".";
   return "";
  }

//+------------------------------------------------------------------+
//| Erro do FORMULARIO de criar/duplicar, para a caixa do rodape.      |
//|                                                                   |
//| Funcao SEPARADA de ScreenErrorProfiles, e a separacao e o ponto:   |
//| `FirstConfigError` consulta a tela pelo id FCV_SCREEN_PROFILES     |
//| para montar `ConfigInputsValid`, e ScreenErrorProfiles decide por  |
//| `m_profEdit` — nao pelo argumento. Fundidas, o erro do formulario  |
//| vazaria para o predicado global: um nome repetido passaria a       |
//| reprovar a CONFIGURACAO, apagando INICIAR e SALVAR e fazendo a     |
//| nota da cadeia dizer "Corrija em Perfis: Nome ja existe".          |
//|                                                                   |
//| Fonte unica preservada: quem responde e o mesmo ProfileFormReady   |
//| que marca os campos de vermelho e habilita o CRIAR. As regras de   |
//| nome e Magic nao sao reescritas aqui.                              |
//|                                                                   |
//| Duas causas, na mesma ordem que tinham no cartao:                  |
//|  1. o formulario (nome/Magic);                                    |
//|  2. a CONFIGURACAO, que pesa porque criar grava o rascunho inteiro |
//|     num arquivo novo — no ESCOPO do formulario, e nao sempre o     |
//|     completo: o DUPLICAR nao cobra o ativo deste grafico, porque   |
//|     nao ativa nada. A frase comeca pela CAUSA e aponta a aba: sem  |
//|     essa ligacao a recusa parece arbitraria para quem pediu so uma |
//|     copia.                                                         |
//+------------------------------------------------------------------+
string ScreenErrorProfileEdit(void)
  {
   bool nameBad=false, magicBad=false;
   string formError="";
   ProfileFormReady(nameBad,magicBad,formError);
   if(StringLen(formError)>0)
      return formError;

   //--- ⚠ MESMO predicado do botao e do ponto que enfileira a intencao.
   //--- Criar NAO ativa: o perfil nasce em disco e o grafico continua no perfil
   //--- anterior. Por isso o DUPLICAR nao cobra o ativo atual — so o NOVO, que
   //--- nasce da configuracao em uso aqui.
   if(ProfileFormConfigValid())
      return "";
   string cfgTab="";
   string cfgError=ProfileFormConfigError(cfgTab);
   if(StringLen(cfgError)==0)
      return "";
   if(m_profEdit==FCV_PROF_DUP)
      //--- ⚠ MESMA orientacao inexequivel do CARREGAR, e pelo mesmo motivo: o
      //--- perfil de ORIGEM nao e o ativo, entao nao ha onde edita-lo aqui. A
      //--- rota real e a mesma, e vem da mesma funcao.
      return "A configuracao do perfil de origem tem um problema proprio, que "
             "nao depende do ativo: "+cfgError+" "+
             FusionProfileFixElsewhereHint(cfgTab,"tente duplica-lo de novo");
   //--- Aqui, sim, "Corrija em <aba>" e executavel: o rascunho do NOVO E a
   //--- configuracao do perfil ATIVO, que a GUI edita. Sair do formulario o
   //--- descarta — a nota da tela ja avisa — e o NOVO fica esperando.
   return "O perfil novo nasce da configuracao em uso neste grafico, entao ela "
          "precisa ser valida para o "+m_snap.symbol+". Corrija em "+
          cfgTab+": "+cfgError;
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

      //--- Telas distintas, funcoes distintas. Ver a nota de
      //--- ScreenErrorProfileEdit: unificadas, o erro do formulario vazava para
      //--- o ConfigInputsValid global.
      case FCV_SCREEN_PROFILES:     return ScreenErrorProfiles();
      case FCV_SCREEN_PROFILE_EDIT: return ScreenErrorProfileEdit();
     }
   return "";
  }

//+------------------------------------------------------------------+
//| O MESMO erro de tela, no ESCOPO DO FORMULARIO aberto.             |
//|                                                                   |
//| Consumido pelos MARCADORES — trilho, subaba e aba —, e pela caixa |
//| do rodape. Sem isto o painel dizia duas coisas contrarias ao mesmo |
//| tempo: dentro do DUPLICAR, o CRIAR COPIA aceso afirmando que a    |
//| copia e valida, e a aba Gestao vermelha por uma regra do ativo    |
//| deste grafico — ativo que nao participa da duplicacao.            |
//|                                                                   |
//| So o DUPLICAR muda de escopo, e so enquanto o formulario esta      |
//| aberto. Fora dele, e no NOVO, nada muda: ali o ativo atual E       |
//| criterio.                                                          |
//|                                                                   |
//| ⚠ O que isto NAO esconde: erro intrinseco real da origem (ele     |
//| continua acendendo), o Magic duplicado da aba Perfis (que sai de  |
//| `HasDuplicateMagic` e de `ScreenErrorProfiles`, nenhum dos dois   |
//| sensivel ao escopo) e qualquer bloqueio do perfil ATIVO fora do   |
//| formulario.                                                       |
//+------------------------------------------------------------------+
string ScreenErrorFormScoped(const int screen)
  {
   if(m_profEdit!=FCV_PROF_DUP)
      return ScreenError(screen);

   bool keepScope=m_vSymbolRules;
   bool keepCfgKnown=m_cfgValidKnown, keepCfgValid=m_cfgValid;

   m_vSymbolRules=false;
   string e=ScreenError(screen);

   m_vSymbolRules=keepScope;
   m_cfgValidKnown=keepCfgKnown; m_cfgValid=keepCfgValid;
   return e;
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
void InvalidateValidationCache(void)
  { m_cfgValidKnown=false; m_cmtValidKnown=false; m_intrValidKnown=false; }

bool ConfigInputsValid(void)
  {
   if(!m_cfgValidKnown)
     {
      m_cfgValid=(FirstConfigError()=="");
      m_cfgValidKnown=true;
     }
   return m_cfgValid;
  }

//+------------------------------------------------------------------+
//| A MESMA validacao, no escopo INTRINSECO — sem as tres regras que  |
//| dependem do ativo do grafico.                                     |
//|                                                                   |
//| Existe para o DUPLICAR. Copiar um arquivo nao e adota-lo: um      |
//| perfil valido para ouro, com lote que nenhum indice aceita, tem   |
//| de poder ser duplicado num grafico de indice. A compatibilidade   |
//| com o ativo e cobrada quando alguem tentar CARREGAR a copia — que |
//| e o unico verbo que ativa perfil.                                 |
//|                                                                   |
//| ⚠ NAO pula telas. RiskLot, RiskSLTP e RiskPartial misturam regra  |
//| intrinseca com regra do simbolo, e pular a tela inteira deixaria  |
//| passar slippage fora de faixa, TP1 % acima de 100 ou TP Final     |
//| Livre sem Trailing. O escopo entra DENTRO de cada validacao, e    |
//| cada regra continua escrita uma vez so.                           |
//|                                                                   |
//| O escopo e trocado e devolvido aqui, com o cache do escopo cheio  |
//| salvo e restaurado — mesmo cuidado do CommittedConfigValid, e     |
//| pela mesma razao: sem ele esta consulta deixaria o                |
//| `ConfigInputsValid` do mesmo quadro respondendo pelo escopo       |
//| errado.                                                           |
//+------------------------------------------------------------------+
bool ConfigIntrinsicValid(void)
  {
   if(!m_intrValidKnown)
     {
      bool keepScope=m_vSymbolRules;
      bool keepKnown=m_cfgValidKnown, keepValid=m_cfgValid;

      m_vSymbolRules=false;
      m_cfgValidKnown=false;
      m_intrValid=(FirstConfigError()=="");
      m_intrValidKnown=true;

      m_vSymbolRules=keepScope;
      m_cfgValidKnown=keepKnown; m_cfgValid=keepValid;
     }
   return m_intrValid;
  }

//+------------------------------------------------------------------+
//| PONTO UNICO de decisao do formulario de criacao.                  |
//|                                                                   |
//| Consultado pelos tres lugares que precisam concordar: o botao que |
//| acende, o texto que explica a recusa e o ponto que enfileira a    |
//| intencao. Divergindo, a tela ofereceria o que a execucao recusa — |
//| ou o contrario, que e pior, porque nada explicaria o clique       |
//| inerte.                                                           |
//|                                                                   |
//| NOVO nasce da configuracao em uso neste grafico, entao vale a     |
//| validacao completa. DUPLICAR le outro arquivo, e para ele o ativo |
//| atual nao e criterio.                                             |
//+------------------------------------------------------------------+
bool ProfileFormConfigValid(void)
  {
   return (m_profEdit==FCV_PROF_DUP) ? ConfigIntrinsicValid() : ConfigInputsValid();
  }

//--- O erro do escopo que vale para o formulario aberto, para o texto da recusa.
string ProfileFormConfigError(string &tabName)
  {
   if(m_profEdit!=FCV_PROF_DUP)
      return FirstConfigError(tabName);

   bool keepScope=m_vSymbolRules;
   bool keepKnown=m_cfgValidKnown, keepValid=m_cfgValid;
   m_vSymbolRules=false; m_cfgValidKnown=false;
   string e=FirstConfigError(tabName);
   m_vSymbolRules=keepScope;
   m_cfgValidKnown=keepKnown; m_cfgValid=keepValid;
   return e;
  }

//+------------------------------------------------------------------+
//| A MESMA pergunta, sobre o COMPROMETIDO — a configuracao que o EA  |
//| esta usando, e nao a que esta na tela.                            |
//|                                                                   |
//| Existe por um defeito que a auditoria pegou. `AbandonNeedsConfirm`|
//| perguntava "o perfil ativo pode ser gravado?" usando              |
//| `ConfigInputsValid()`, que le o RASCUNHO — e entrar no DUPLICAR   |
//| troca o rascunho pelo perfil de ORIGEM. A pergunta passava a ser  |
//| sobre a origem, que costuma valer neste grafico, e a confirmacao  |
//| da copia ficava INALCANCAVEL: o CRIAR COPIA so acende com o       |
//| rascunho valido, e a confirmacao so existia com ele invalido. As  |
//| duas condicoes nunca podiam ser verdadeiras juntas.               |
//|                                                                   |
//| O comprometido nao muda ao entrar no formulario — `BeginDuplicate`|
//| so mexe em `m_draft` —, entao a resposta fica estavel do primeiro |
//| clique ate a conclusao, que e o que a confirmacao precisa.        |
//|                                                                   |
//| A troca e feita e desfeita aqui dentro, com o cache do rascunho   |
//| salvo e devolvido: sem isso esta consulta deixaria o              |
//| `ConfigInputsValid` do mesmo quadro respondendo pelo comprometido.|
//+------------------------------------------------------------------+
bool CommittedConfigValid(void)
  {
   if(!m_cmtValidKnown)
     {
      SEASettings keepDraft=m_draft;
      bool keepKnown=m_cfgValidKnown, keepValid=m_cfgValid;
      //--- ⚠ O MODO TAMBEM E TROCADO, e nao so o rascunho. `ScreenErrorProfiles`
      //--- decide por `m_profEdit`, e dentro do formulario ele PULA a unicidade
      //--- do Magic de proposito — a excecao existe porque, ali, o Magic do
      //--- rascunho e o do perfil de origem e cobra-lo acusaria colisao com o
      //--- proprio arquivo que se esta copiando.
      //---
      //--- Sem esta troca a excecao vazava para ca: perguntando pelo COMPROMETIDO
      //--- de dentro do DUPLICAR, um perfil orfao invalido justamente por Magic
      //--- repetido passava por valido, e a confirmacao de abandono nao aparecia
      //--- ao concluir a copia. Estreito, mas e a mesma protecao contra perda.
      int keepMode=m_profEdit;
      m_profEdit=FCV_PROF_VIEW;
      m_draft=m_committed;
      m_cfgValidKnown=false;
      m_cmtValid=(FirstConfigError()=="");
      m_draft=keepDraft;
      m_profEdit=keepMode;
      m_cfgValidKnown=keepKnown; m_cfgValid=keepValid;
      m_cmtValidKnown=true;
     }
   return m_cmtValid;
  }

//--- Primeiro erro na ordem em que as abas aparecem: e a ordem em que o
//--- usuario vai encontra-los ao procurar.
//---
//--- Devolve tambem ONDE ele esta, na mesma varredura. Duas funcoes separadas
//--- para "qual erro" e "em que aba" repetiriam a ordem — e o dia em que uma
//--- delas mudasse, a mensagem passaria a mandar o usuario para a aba errada.
string FirstConfigError(string &tabName)
  {
   tabName="";
   for(int i=0;i<4;++i)
     { string e=ScreenError(FCV_SCREEN_STRAT0+i);
       if(e!="") { tabName=m_tabNames[2]; return e; } }
   for(int i=0;i<4;++i)
     { string e=ScreenError(FCV_SCREEN_FILTER0+i);
       if(e!="") { tabName=m_tabNames[3]; return e; } }
   for(int i=0;i<5;++i)
     { string e=ScreenError(FCV_SCREEN_RISK0+i);
       if(e!="") { tabName=m_tabNames[FCV_TAB_GESTAO]; return e; } }
   for(int i=0;i<FCV_RAIL_MAX;++i)
     { string e=ScreenError(FCV_SCREEN_PROT0+i);
       if(e!="") { tabName=m_tabNames[FCV_TAB_GESTAO]; return e; } }
   string last=ScreenError(FCV_SCREEN_PROFILES);
   if(last!="") tabName=m_tabNames[FCV_TAB_PERFIS];
   return last;
  }

string FirstConfigError(void)
  {
   string ignored="";
   return FirstConfigError(ignored);
  }
