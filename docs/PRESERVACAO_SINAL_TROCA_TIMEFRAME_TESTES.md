# Preservacao do estado de entrada na troca do timeframe visual — evidencias do aceite

Branch `fix/preserve-entry-state-chart-timeframe`, sobre `gui-2.0` em `5d81b5172ef0fa35ef928235a9ab4664ea293155`.

Conta **demo**, lote minimo, logs detalhados ligados.

**Timeframes operacionais.** Os testes usaram timeframes operacionais **concretos**, como exige a interface atual: a enum dos `input` (`ENUM_FUSION_INPUT_TIMEFRAME`, em `Core/Inputs.mqh`) e a lista da GUI (`CanvasRendererFields.mqh`) oferecem os mesmos 21 periodos concretos, e o default e `PERIOD_M15`. O chart state registra os valores **ja resolvidos**, de modo que a troca altera somente o timeframe visual e o teste isola a preservacao do estado logico de entrada.

*Detalhe interno, nao uma opcao operacional:* `ResolveOperationalTimeframes` ainda normaliza valor zero ou legado, herdado de migracao. Durante uma restauracao valida de chart state o contexto salvo pode fornecer esse fallback; fora dali a fonte depende do fluxo de inicializacao e de perfil. Nada disso e escolha oferecida ao usuario.

Este documento separa tres coisas que costumam ser confundidas: o que foi **provado automaticamente**, o que foi **provado no EA real**, e o que esta **coberto estruturalmente mas nao foi provocado**. A distincao importa: cobertura estrutural nao e evidencia de execucao.

---

## 1. Provas automatizadas — sonda `EntryStateProbe.mq5`

Sonda **temporaria**, compilada a parte em 2026-08-21 21:16 e **removida antes do commit**. Ela escolhe sozinha um `ChartID` livre, prova que o `.state` e o `.tmp` daquele identificador **nao existiam antes**, e no fim prova que os removeu.

**Resultado: 70 casos, 70 aprovados, 0 falhas.** Limpeza confirmada pela propria sonda (`LIMPEZA: state ausente, tmp ausente`).

| grupo | casos | o que prova |
|---|---:|---|
| Persistencia do bloco `entry.*` | 32 | round-trip dos 16 campos; arquivo antigo sem o bloco; bloco incompleto; chave duplicada; chave desconhecida; invariantes semanticas |
| Helper puro da MA Cross (`H`) | 13 | a maquina de estados de cruzamento, comparando os **cinco** campos de estado e os **tres** de desfecho a cada caso |
| Precondicoes do handoff (`P`) | 5 | a ordem dos vereditos de `FusionEvaluateEntryHandoff` |
| Predicados de compatibilidade (`C`) | 8 | MA Cross, RSI e Bollinger, cada um com o seu |
| Orquestracao do `CSignalManager` (`M`) | 12 | restauracao por estrategia, listas e contadores, com estrategias falsas |

**Limite explicito desta secao:** os casos `M` exercitam a **orquestracao real do `CSignalManager`** — chamam `RestoreEntryStatesOrPrimeSafely()`, `PrimeEntryStates()` e `SuspendEntriesUntilFreshCandleVisualAll()` de verdade, com estrategias falsas sem indicador nem handle. Eles **nao executam o fluxo de `EAApplication`**: ordem de inicializacao, avisos, protecao e permissao nao passam por ali. Essa parte foi provada manualmente, na secao 2.

---

## 2. Provas manuais no EA real — 2026-08-22

### 2.1. Preservacao do `E2C_WAIT` e disparo unico

O caso que motivou a tarefa: uma pendencia de **segundo candle** reconhecida antes da troca precisa atravessar a reinicializacao e disparar no candle operacional correto, uma unica vez.

**Rodada final, com o binario aprovado:**

| horario | evento |
|---|---|
| 10:07:59 | `E2C_WAIT => BUY` |
| 10:08:07 | troca visual M1 -> M5 |
| 10:08:07 | estado logico restaurado integralmente |
| 10:08:59 | `E2C_FIRE_IMPORTADO => BUY` |
| 10:09:00 | ordem BUY enviada |

**Rodada anterior, na outra direcao** — mesma sequencia, provando que nao depende da mao:

| horario | evento |
|---|---|
| 08:22:59 | `E2C_WAIT => SELL` |
| 08:23:55 | troca visual M1 -> M2, estado restaurado integralmente |
| 08:23:59 | `E2C_FIRE_IMPORTADO => SELL` |
| 08:24:00 | ordem SELL enviada |

Disparo **uma unica vez**, na direcao preservada, sem repeticao em ticks ou candles posteriores.

### 2.2. Contracruzamento no intervalo cego

O ramo oposto do 2.1, e o desfecho correto e **nenhuma entrada**, nao "entrada invertida":

| horario | evento |
|---|---|
| 10:31:00.012 | `E2C_WAIT => BUY` |
| 10:31:04.746 | troca visual M1 -> M5 |
| 10:31:04.759 | estado logico restaurado |
| 10:31:59.884 | cruzamento **novo recusado** pelo intervalo cego — candle do sinal = barreira visual = 16:31 |
| 10:31:59.884 | pendencia importada **cancelada**, porque o cruzamento novo invalidou a direcao preservada |

**Nenhum `Entry sent` nessa sequencia.** As duas coisas aconteceram na mesma volta e sobre objetos diferentes: a barreira visual recusou o sinal nascido no vao, e a maquina de estados cancelou a pendencia anterior porque o mercado desmentiu aquela direcao. Nenhuma das duas maos operou.

Esta e uma prova **mais forte que o caso automatizado `H9`**, que cobre a mesma transicao de forma deterministica: aqui ela ocorreu no mercado, com o timing real da reinicializacao.

### 2.3. Troca com posicao aberta

| horario | evento |
|---|---|
| 09:24:00 | posicao SELL aberta pela MA Cross |
| 09:35:33 | troca visual para M5 |
| 09:35:33 | posicao aberta detectada e ressincronizada (`SYNC`) |
| 09:35:33 | `INFO` confirmando gerenciamento normal |

E na rodada final, logo depois da ordem do 2.1:

| horario | evento |
|---|---|
| 10:09:13 | troca visual com posicao aberta |
| 10:09:13 | posicao detectada e ressincronizada |
| 10:09:13 | `INFO` confirmando gerenciamento normal |

O que ficou **provado** nas duas: posicao ressincronizada, gerenciamento preservado, **nenhum aviso de handoff publicado**, nenhum `WARN` generico, nenhum `CONTEXT` enganoso e nenhuma ordem duplicada.

Mensagem aprovada:

> `Troca de timeframe concluida. A posicao aberta continua sendo gerenciada normalmente; nenhuma nova entrada sera aberta enquanto ela permanecer ativa.`

Com debug ligado:

> `Novos sinais de entrada nao foram preservados porque ja havia uma posicao aberta no momento da troca de timeframe.`

### 2.4. Reinicio que nao e troca de timeframe

As 10:00 houve uma troca **depois de reanexo normal**, com o EA ainda **nao iniciado**. Nenhuma mensagem de handoff foi emitida — correto, e nao defeito: sem EA iniciado nao ha estado logico a preservar. A prova relevante do 2.3 e a das 10:09, com EA iniciado.

### 2.5. AutoTrading bloqueado

O aviso **acionavel** tem de sobreviver ao handoff: quem precisa religar o AutoTrading nao pode ver essa instrucao trocada por um informe generico.

| horario | evento |
|---|---|
| 22:05:38.238 | AutoTrading desabilitado |
| 22:05:38.269 | aviso `AUTOTRADE` publicado |
| 22:05:38.325 | sinais descartados durante o bloqueio |
| 22:05:54.062 | troca visual M1 -> M5 |
| 22:05:54.077 | handoff **recusado**, e o aviso acionavel de AutoTrading **preservado** na GUI |
| 22:06:13.003 | AutoTrading habilitado |
| 22:06:13.091 | trading restabelecido, e o estado de entrada novamente consumido |

O consumo do estado na volta e a quarentena de reconexao agindo — ela e independente da barreira visual e tem prioridade sobre ela.

---

## 3. Cobertura estrutural, sem provocacao manual no MT5

Estes caminhos **nao foram provocados manualmente em execucao no MT5**. A auditoria os considerou cobertos por prova deterministica na sonda ou por revisao estrutural; provoca-los exigiria corromper arquivo a mao ou forcar falha de indicador — o que testa o teste, nao o produto.

- falha de `iMA` na criacao de handles;
- corrupcao manual do chart state em operacao (coberta pelos casos 7 a 10 da sonda);
- mudanca de protecao exatamente entre o desligamento e o religamento;
- estado vencido pela janela de 120 segundos (coberto pelos casos `P`);
- troca de ativo do grafico (coberta pelos casos `P`);
- **limpeza de um aviso de handoff ja publicado quando uma posicao surge depois.** O ciclo provado no 2.3 e outro: com posicao **ja aberta** no momento da troca, o aviso nem chega a ser publicado. O caso em que o aviso e publicado sem posicao e uma posicao abre em seguida esta coberto por `ClearHandoffNotice()`, com limpeza por comparacao exata do texto, mas nao foi executado no MT5.

---

## 4. Verificacao de build

| item | resultado |
|---|---|
| `FusionVisualMA.mq5` | 0 errors, 0 warnings |
| `FusionVisualBands.mq5` | 0 errors, 0 warnings |
| `FusionVisualRSI.mq5` | 0 errors, 0 warnings |
| `Fusion.mq5` | 0 errors, 0 warnings |
| `git diff --check` | sem apontamentos |

Os avisos `LF will be replaced by CRLF` que aparecem ao lado do `git diff` sao do `core.autocrlf=true` e **nao indicam reescrita**: os arquivos no disco sao integralmente CRLF, e o `git diff --stat` e proporcional as linhas realmente tocadas.
