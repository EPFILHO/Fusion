#ifndef __FUSION_SIGNAL_MANAGER_MQH__
#define __FUSION_SIGNAL_MANAGER_MQH__

#include "../Core/Types.mqh"
#include "../Core/Logger.mqh"
#include "../Strategies/Base/StrategyBase.mqh"
#include "../Filters/Base/FilterBase.mqh"
#include "Resolvers/IConflictResolver.mqh"

class CSignalManager
  {
private:
   CLogger            *m_logger;
   CStrategyBase      *m_strategies[];
   CFilterBase        *m_filters[];
   IConflictResolver  *m_resolver;
   string              m_symbol;

   string            FormatEntryBlockReason(const SSignalDecision &decision,const CFilterBase *filter,const string reason) const
     {
      string strategyName = (decision.strategyName != "") ? decision.strategyName : decision.shortName;
      string text = "Entrada " + SignalToString(decision.signal);
      if(strategyName != "")
         text += " da " + strategyName;
      text += " bloqueada por " + filter.Name();
      if(reason != "")
         text += ": " + reason;
      return text;
     }

public:
                     CSignalManager(void)
     {
      m_logger    = NULL;
      m_resolver  = NULL;
      m_symbol    = "";
      ArrayResize(m_strategies, 0);
      ArrayResize(m_filters, 0);
     }

   void              SetResolver(IConflictResolver *resolver)
     {
      m_resolver = resolver;
     }

   bool              AddStrategy(CStrategyBase *strategy)
     {
      if(strategy == NULL)
         return false;

      int size = ArraySize(m_strategies);
      ArrayResize(m_strategies, size + 1);
      m_strategies[size] = strategy;
      return true;
     }

   bool              AddFilter(CFilterBase *filter)
     {
      if(filter == NULL)
         return false;

      int size = ArraySize(m_filters);
      ArrayResize(m_filters, size + 1);
      m_filters[size] = filter;
      return true;
     }

   bool              Initialize(CLogger *logger,const string symbol,const SEASettings &settings)
     {
      m_logger    = logger;
      m_symbol    = symbol;

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         if(!m_strategies[i].Reload(settings, RELOAD_COLD))
            return false;

         if(!m_strategies[i].Initialize(logger, symbol))
            return false;
        }

      for(int i = 0; i < ArraySize(m_filters); i++)
        {
         if(m_filters[i] == NULL)
            continue;

         if(!m_filters[i].Reload(settings, RELOAD_COLD))
            return false;

         if(!m_filters[i].Initialize(logger, symbol))
            return false;
        }

      return true;
     }

   void              Shutdown(void)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL)
            m_strategies[i].Shutdown();

      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL)
            m_filters[i].Shutdown();
     }

   bool              ReloadAll(const SEASettings &settings,const ENUM_RELOAD_SCOPE scope)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL && !m_strategies[i].Reload(settings, scope))
            return false;

      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL && !m_filters[i].Reload(settings, scope))
            return false;

      return true;
     }

   void              PrimeEntryStates(void)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL && m_strategies[i].Enabled())
            m_strategies[i].PrimeEntryState();
     }

   //--- Exportacao do estado logico para o chart state. Parte sempre de um
   //--- snapshot ja resetado pelo chamador; aqui so se preenche versao, hora e
   //--- o que cada estrategia sabe de si.
   //---
   //--- `present` e `valid` NAO sao preenchidos: sao campos de runtime do
   //--- carregamento, e nao entram nas 16 linhas serializadas.
   void              ExportEntryStates(SEntryStateSnapshot &snapshot)
     {
      snapshot.version    = FUSION_ENTRY_STATE_VERSION;
      if(snapshot.capturedAt <= 0)
         snapshot.capturedAt = TimeLocal();

      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL)
            m_strategies[i].ExportEntryState(snapshot);
     }

   //--- ⚠ Barreira do intervalo cego em TODAS as estrategias, inclusive as
   //--- desligadas. Uma estrategia habilitada logo depois da troca entraria com
   //--- um [1] formado enquanto o EA se reinicializava. Ela fica armada e SEM
   //--- horario; o primeiro tick apos ser habilitada captura o candle vigente.
   void              SuspendEntriesUntilFreshCandleVisualAll(void)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL)
            m_strategies[i].SuspendEntriesUntilFreshCandleVisual();
     }

   //--- Restauracao por estrategia. Devolve quantas foram importadas e monta a
   //--- descricao para o log.
   //---
   //--- ⚠ Uma estrategia que nao pode importar recebe PrimeEntryState()
   //--- INDIVIDUAL — inclusive desligada. Isso nao passa pelo PrimeEntryStates()
   //--- generico, cuja semantica (so estrategias habilitadas) e usada por outros
   //--- oito chamadores e nao pode mudar por causa desta restauracao.
   //---
   //--- ⚠ Falha de uma NAO desfaz as outras: restauracao parcial e um desfecho
   //--- legitimo, e derrubar tudo por causa de uma trocaria um problema pequeno
   //--- por um grande.
   //--- ⚠ TRES categorias, e nao duas. Estrategia DESLIGADA nao e falha: ela e
   //--- resetada por seguranca e entra em `inactiveList`. Misturar as duas fazia
   //--- a configuracao mais comum — so MA ativa — parecer restauracao parcial em
   //--- toda troca de timeframe.
   //---
   //---   importedList  — ativa e restaurada
   //---   failedList    — ATIVA que nao pode ser restaurada (com motivo)
   //---   inactiveList  — desligada, resetada com seguranca
   void              RestoreEntryStatesOrPrimeSafely(const SEntryStateSnapshot &snapshot,
                                                     const SEASettings &originSettings,
                                                     const SEASettings &currentSettings,
                                                     int &activeImported,
                                                     int &activeFailed,
                                                     string &importedList,
                                                     string &failedList,
                                                     string &inactiveList)
     {
      activeImported = 0;
      activeFailed   = 0;
      importedList   = "";
      failedList     = "";
      inactiveList   = "";

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         string name = m_strategies[i].Name();

         //--- Desligada: reset individual, por seguranca, e nada de falha.
         //--- ⚠ Chamado aqui, e nao pelo PrimeEntryStates() generico, cuja
         //--- semantica (so habilitadas) e usada por outros oito chamadores.
         if(!m_strategies[i].Enabled())
           {
            m_strategies[i].PrimeEntryState();
            inactiveList += (inactiveList == "" ? "" : ", ") + name;
            continue;
           }

         string reason = "";
         bool   done   = false;

         if(!m_strategies[i].ReadyForEntryStateImport())
            reason = "nao operacional";
         else if(!m_strategies[i].EntryStateCompatible(originSettings, currentSettings))
            reason = "configuracao incompativel";
         else if(!m_strategies[i].ImportEntryState(snapshot, reason))
           {
            //--- Motivo vem da estrategia. Vazio nunca sai daqui: um "primeada ()"
            //--- no log nao diz nada a quem investiga.
            if(reason == "")
               reason = "importacao recusada sem detalhe";
           }
         else
            done = true;

         if(done)
           {
            activeImported++;
            importedList += (importedList == "" ? "" : ", ") + name;
           }
         else
           {
            m_strategies[i].PrimeEntryState();
            activeFailed++;
            failedList += (failedList == "" ? "" : ", ") + name + " (" + reason + ")";
           }
        }
     }

   //--- Diferente de PrimeEntryStates, arma tambem quem esta desligado: uma
   //--- estrategia reativada logo depois da restauracao entraria com um [1]
   //--- formado no escuro. A propria Reload devolve o estado quando o usuario
   //--- muda parametros.
   void              SuspendEntriesUntilFreshCandle(void)
     {
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL)
            m_strategies[i].SuspendEntriesUntilFreshCandle();
     }

   bool              GetEntryDecision(SSignalDecision &decision)
     {
      ResetSignalDecision(decision);

      if(m_resolver == NULL)
         return false;

      SSignalCandidate candidates[];
      ArrayResize(candidates, 0);

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL || !m_strategies[i].Enabled())
            continue;

         //--- Ponto unico da captura tardia da barreira. Se a serie estava muda na
         //--- reconexao, e so aqui que ela e reencontrada - avaliacao normal de
         //--- entrada, exista sinal ou nao. Deixar a captura para dentro das
         //--- estrategias significava captar no primeiro sinal candidato, que
         //--- entao servia de referencia e era descartado: um sinal legitimo
         //--- perdido, possivelmente horas depois da reconexao.
         m_strategies[i].RefreshFreshCandleBarrier();
         //--- Mesma captura tardia, para a barreira do intervalo cego. As duas
         //--- ficam aqui, imediatamente antes da avaliacao, porque so debaixo do
         //--- tick a serie esta atualizada.
         m_strategies[i].RefreshVisualBarrier();

         ENUM_SIGNAL_TYPE signal = m_strategies[i].GetEntrySignal();
         if(signal == SIGNAL_NONE)
            continue;

         int index = ArraySize(candidates);
         ArrayResize(candidates, index + 1);
         candidates[index].signal       = signal;
         candidates[index].priority     = m_strategies[i].Priority();
         candidates[index].strategyId   = m_strategies[i].Id();
         candidates[index].strategyName = m_strategies[i].Name();
         candidates[index].shortName    = m_strategies[i].ShortName();
        }

      if(ArraySize(candidates) == 0)
         return false;

      if(!m_resolver.Resolve(candidates, ArraySize(candidates), decision))
        {
         decision.blockedBy = m_resolver.Name();
         return false;
        }

      for(int i = 0; i < ArraySize(m_filters); i++)
        {
         if(m_filters[i] == NULL || !m_filters[i].Enabled())
            continue;

         string reason = "";
         if(!m_filters[i].AllowEntry(decision.signal, reason))
           {
            decision.blockedBy = FormatEntryBlockReason(decision, m_filters[i], reason);
            decision.signal = SIGNAL_NONE;
            return false;
           }
        }

      return (decision.signal != SIGNAL_NONE);
     }

   ENUM_SIGNAL_TYPE  GetExitSignal(const string ownerStrategyId,const ENUM_POSITION_TYPE currentPosition,string &ownerName,string &shortName)
     {
      ownerName = "";
      shortName = "";

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         if(m_strategies[i].Id() != ownerStrategyId)
            continue;

         ownerName = m_strategies[i].Name();
         shortName = m_strategies[i].ShortName();
         return m_strategies[i].GetExitSignal(currentPosition);
        }

      return SIGNAL_NONE;
     }

   bool              GetStrategyExitMode(const string strategyId,ENUM_EXIT_MODE &mode) const
     {
      mode = EXIT_TP_SL;

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;

         if(m_strategies[i].Id() != strategyId)
            continue;

         mode = m_strategies[i].ExitMode();
         return true;
        }

      return false;
     }

   bool              GetStrategyReferenceTimeframe(const string strategyId,ENUM_TIMEFRAMES &timeframe) const
     {
      timeframe = FUSION_DEFAULT_TIMEFRAME;

      for(int i = 0; i < ArraySize(m_strategies); i++)
        {
         if(m_strategies[i] == NULL)
            continue;
         if(m_strategies[i].Id() != strategyId)
            continue;

         timeframe = m_strategies[i].ReferenceTimeframe();
         return true;
        }

      return false;
     }

   int               ActiveStrategyCount(void) const
     {
      int count = 0;
      for(int i = 0; i < ArraySize(m_strategies); i++)
         if(m_strategies[i] != NULL && m_strategies[i].Enabled())
            count++;
      return count;
     }

   int               ActiveFilterCount(void) const
     {
      int count = 0;
      for(int i = 0; i < ArraySize(m_filters); i++)
         if(m_filters[i] != NULL && m_filters[i].Enabled())
            count++;
      return count;
     }
  };

#endif
