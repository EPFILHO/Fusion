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
elegivel. Sem hora confiavel, falha fechado.

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

**Pendente de teste real no MT5:** todos os nove. O caminho barato para 1, 2, 4 e 5 e desligar e
religar o AutoTrading (caso 3), que percorre exatamente a mesma transicao.

## Notas de comportamento

- Com posicao aberta ou EA pausado, o **priming** e pulado (guarda de `DiscardBlockedEntrySignals`,
  preservada), mas a **barreira arma assim mesmo**. Por isso o disparo de `Segundo candle` tem
  conferencia propria em `MACrossStrategy`: e a unica forma de o invariante valer sem depender de
  quem chamou o que.
- A barreira e estado de runtime e nao vai para o chart state. Reinicio/troca de timeframe ja
  descartam sinais por caminho proprio.

## Build

`build-linked.ps1 -MetaEditor 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'` — MetaEditor
5.0.0.6090, quatro alvos: `FusionVisualMA`, `FusionVisualBands`, `FusionVisualRSI`, `Fusion`.
**0 errors, 0 warnings em todos.**
