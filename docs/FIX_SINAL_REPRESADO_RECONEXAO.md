# Sinal represado apos restauracao da permissao de trading

Branch `fix/stale-signal-reconnect`, a partir de `gui-2.0` (`9555072`). Correcao conceitual unica.

## Causa confirmada

`RefreshTradePermissionState()` (`Core/EAApplicationEntryBlock.mqh`) ja calculava `wasBlocked`,
mas na transicao **bloqueado -> liberado** apenas limpava `m_runtimeNotice`. Sem ticks durante o
bloqueio, `DiscardBlockedEntrySignals()` nunca rodava e o estado das estrategias ficava parado no
instante da queda. O primeiro tick de volta ia direto de `RefreshTradePermissionState()` para
`GetEntryDecision()`, encontrava em `[2]/[1]` um cruzamento formado no escuro e abria ordem atrasada.

Consumir o `[1]` vigente (o que `PrimeEntryState()` ja fazia) **nao basta**: se a permissao volta no
meio de um candle, esse candle vira `[1]` no fechamento seguinte e seria aceito, embora tenha
comecado a se formar durante o bloqueio.

## Contrato

Na transicao bloqueado -> liberado:

1. o estado vigente de entrada e consumido (priming), e
2. fica armada uma **barreira de candle**: so e elegivel um sinal cujo candle formador **comecou
   depois** do candle que ja estava aberto no momento da liberacao.

Frescor e definido por **estado de candle**, nunca por prazo em milissegundos: a barreira guarda a
hora de abertura do candle corrente (`iTime(symbol, tf, 0)`) e compara com a abertura do candle do
sinal (`iTime(symbol, tf, 1)`), exigindo `>` estrito. Ela se desarma sozinha no primeiro sinal
elegivel.

### Estado desconhecido (achado P1 da auditoria)

**Quarentena ativa** e **horario da quarentena conhecido** sao campos separados
(`m_freshCandleQuarantine` e `m_freshCandleBarrier`). A primeira versao amarrava os dois: gravava a
hora so quando `iTime()` respondia, e depois lia `barreira == 0` como "desarmada". Isso falhava
**aberto** exatamente no cenario que motivou o trabalho — serie/historico indisponivel e comum logo
depois de uma reconexao.

O ciclo agora e:

| momento | quarentena | horario | entradas |
|---|---|---|---|
| transicao bloqueado -> liberado | **ativa**, incondicionalmente | tenta captar `iTime(tf,0)` | bloqueadas |
| serie ainda muda | ativa | desconhecido | **bloqueadas** (`FreshCandleBarrierBlocks` devolve `true` sem horario) |
| serie responde | ativa | captado nesse instante | bloqueadas ate um candle posterior |
| sinal de candle posterior | **desarma** | zerado | liberadas |

A recuperacao e automatica e **sem prazo**: nao existe contador, timeout nem tentativa limitada. Se a
serie so responder alguns candles depois, a referencia passa a ser o candle corrente **daquele**
momento e ainda se exige um posterior — mais conservador que o necessario, nunca mais permissivo.

**A captura tardia e tentada a cada avaliacao normal de entrada, exista sinal candidato ou nao**
(`SignalManager::GetEntryDecision()` chama `RefreshFreshCandleBarrier()` antes de `GetEntrySignal()`).
Sem isso — segundo achado da auditoria — a quarentena sem horario atravessaria horas e a referencia
acabaria sendo captada no **primeiro sinal legitimo**, que seria descartado por ter servido de
referencia: a seguranca continuaria fechada, mas ao custo de uma entrada boa. A captura vive no
manager, num ponto so; as tres estrategias apenas consultam o bloqueio.

Com **posicao aberta** nao ha avaliacao de entrada e a captura nao acontece — nem precisa: entradas
estao bloqueadas de todo jeito. Ela ocorre na primeira avaliacao depois do fechamento, usando o
candle corrente daquele momento.

## Onde a regra vive

Fonte unica: `RefreshTradePermissionState()`. **Os seis chamadores** passam por ela e nenhum precisou
ser tocado:

| # | chamador |
|---|---|
| 1 | `Core/EAApplication.mqh` — `Initialize()` |
| 2 | `Core/EAApplication.mqh` — `OnTick()` |
| 3 | `Core/EAApplication.mqh` — `OnTimer()` |
| 4 | `Core/EAApplicationEntry.mqh` — `TryPlaceEntryDecision()` |
| 5 | `Core/EAApplicationManagePosition.mqh` — `ManageOpenPosition()` |
| 6 | `Core/EAApplicationCommands.mqh` — comando INICIAR |

Em `Initialize()` o guard acabou de receber `Init()` -> `Reset()`, entao `wasBlocked` e `false` e a
barreira nao arma por engano no boot.

A barreira e o helper vivem em `CStrategyBase`; as tres estrategias apenas consultam. Cada uma arma no
proprio `ReferenceTimeframe()` (MA usa o timeframe da media rapida), entao **timeframes independentes
esperam candles diferentes**, e nao o mesmo relogio.

## Saidas preservadas

`GetExitSignal()` das tres estrategias avalia ao vivo e **nao le a barreira**. Nada foi alterado em
saida, pending reverse, reconciliacao, trailing, breakeven ou TP parcial. `SuspendEntriesUntilFreshCandle()`
toca somente o campo da barreira.

## Casos: o que esta provado

Provado **por leitura de codigo** e pelo build; **nada foi executado no MT5 nesta rodada**.

| # | caso | estado |
|---|---|---|
| 1 | desconecta antes do cruzamento, reconecta depois: nao abre no primeiro tick | por codigo |
| 2 | cruzamento realmente novo apos a reconexao: abre | por codigo |
| 3 | AutoTrading desligado/religado: mesma protecao (`TERMINAL_TRADE_ALLOWED` na mesma transicao) | por codigo |
| 4 | restauracao detectada pelo timer antes do primeiro tick | por codigo |
| 5 | restauracao detectada pelo proprio tick | por codigo |
| 6 | perda/retorno com posicao aberta: gerenciamento retoma, nenhum estado de saida apagado | por codigo |
| 7 | MA, RSI e Bollinger nao reapresentam sinais acumulados | por codigo |
| 8 | operacao normal sem desconexao mantem `Candle seguinte` e `Segundo candle` (barreira em zero e inerte) | por codigo |
| 9 | PAUSAR/INICIAR continuam consumindo o estado vigente | por codigo |

**Pendente de teste real no MT5:** todos os nove.

⚠️ **Desligar e religar o AutoTrading nao substitui a desconexao.** Percorre a mesma transicao
bloqueado -> liberado e serve para conferir a barreira, mas **os ticks continuam chegando** durante o
bloqueio, e a cada um deles `DiscardBlockedEntrySignals()` vai preparando os estados. O defeito
original nasceu justamente da **ausencia de ticks**, com o estado congelado no instante da queda. Os
casos 1, 2, 4 e 5 so ficam provados de verdade com perda real de conexao; pelo AutoTrading eles
provam a barreira, nao o represamento.

O estado desconhecido (serie indisponivel) tambem nao e reproduzivel pelo AutoTrading: depende de a
serie do timeframe nao responder, o que acompanha a reconexao real.

## Notas de comportamento

- Com posicao aberta ou EA pausado, o **priming** e pulado (guarda de `DiscardBlockedEntrySignals`,
  preservada), mas a **barreira arma assim mesmo**. Por isso o disparo de `Segundo candle` tem
  conferencia propria em `MACrossStrategy`: e a unica forma de o invariante valer sem depender de
  quem chamou o que.
- A barreira e estado de runtime e nao vai para o chart state. Reinicio/troca de timeframe ja
  descartam sinais por caminho proprio.
- O log da volta da permissao (`CTradePermissionGuard::Refresh`) deixou de dizer "EA pronto para
  operar", que passou a ser falso enquanto a quarentena estiver de pe. Agora diz **"Trading habilitado
  novamente. Aguardando sinal formado apos a liberacao."** — o guard afirma so o que ele sabe.

## Build

`build-linked.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'` — MetaEditor
5.0.0.6090, quatro alvos: `FusionVisualMA`, `FusionVisualBands`, `FusionVisualRSI`, `Fusion`.
**0 errors, 0 warnings em todos.**
