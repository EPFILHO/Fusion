# Fusion 1.055 - Reconciliacao De Parciais

## Objetivo

O lucro de uma parcial nao pode ser estimado para atualizar DAY ou DD. A fonte de verdade operacional e o conjunto de deals de saida da posicao, identificado por `DEAL_POSITION_ID` e somado por `DEAL_PROFIT`.

## Invariantes

1. Solicitar uma parcial nao significa considera-la executada.
2. TP1/TP2 somente ficam executados depois que o historico confirma novo volume de saida.
3. DAY/DD recebem apenas a diferenca entre o total real de parciais e o total ja contabilizado.
4. O fechamento final subtrai as parciais reais ja contabilizadas e nao as soma duas vezes.
5. `PLACED` e `DONE_PARTIAL` entram em reconciliacao; nenhum deles credita lucro estimado.
6. `TIMEOUT` e `CONNECTION` sao indeterminados e nao autorizam repeticao imediata da parcial.
7. Se `DONE_PARTIAL` executar menos volume que o pedido, o nivel e encerrado de forma conservadora depois que a ordem deixa de estar ativa. O Fusion nao reenvia automaticamente o restante.
8. Uma ordem parcial ainda ativa impede uma saida forcada concorrente, evitando sobre-execucao ou reversao acidental em conta netting.
9. O estado pendente sobrevive a reinicio e troca de timeframe pelo chart state.
10. A GUI nunca apresenta um P/L projetado pendente como valor final exato.
11. A intencao pendente e persistida antes do `OrderSend`; se a gravacao falhar, a parcial nao e enviada.
12. O chart state e montado em arquivo temporario e somente substitui o anterior depois da escrita completa.

## Fluxo

Antes do `OrderSend`, o Fusion exige uma leitura valida do historico da posicao, guarda o volume de saida ja existente e persiste a intencao. O chart state e escrito em temporario e promovido somente depois da gravacao completa. Somente depois desse sucesso o envio e permitido. O retorno completa tickets e retcode no estado; se houver reinicio nessa janela, o Fusion procura uma ordem ativa da mesma posicao e usa o historico para decidir, sem repetir cegamente a parcial.

Tick, timer e `OnTradeTransaction` repetem a leitura enquanto houver pendencia. Quando surge novo volume de saida e a ordem nao esta mais ativa, o nivel e confirmado. O total de `DEAL_PROFIT` substitui o acumulado anterior e somente a diferenca do dia operacional atual entra em DAY/DD.

Se o volume da posicao diminuir antes de o deal ficar visivel, o Fusion nao usa `OrderCalcProfit`. Ele preserva o ultimo P/L projetado confirmado e passa a acompanhar apenas a variacao do flutuante do volume restante. Assim o DD continua sendo avaliado a cada tick sem transformar uma estimativa em lucro realizado. Quando o historico chega, a base provisoria e descartada e o calculo volta imediatamente para:

```text
P/L projetado = P/L realizado confirmado do dia + POSITION_PROFIT atual
```

Na aba `RESULTS`, o flutuante continua mostrando `POSITION_PROFIT`. Durante a curta pendencia, o fechado recebe a indicacao `(confirmado)` e o projetado mostra `RECONCILIANDO PARCIAL`. Com posicao aberta, ticks podem atualizar a pagina ate cinco vezes por segundo, reduzindo a defasagem visual sem transformar a GUI em trabalho prioritario do motor.

## Matriz Minima De Testes Em Demo

- TP1 com `DONE` e deal imediatamente disponivel.
- TP1 com deal disponivel somente no evento/tick seguinte.
- TP1 seguido de TP2, conferindo soma exata e ausencia de duplicacao.
- Parcial com lucro, prejuizo e resultado zero.
- `PLACED` sem fill, depois cancelado/expirado.
- `PLACED` com fill parcial enquanto a ordem ainda esta ativa.
- `DONE_PARTIAL` com volume executado menor que o solicitado.
- DAY e DD proximos do limite durante a parcial.
- DD acionado enquanto existe ordem parcial ativa.
- Fechamento final imediatamente depois da parcial.
- Troca de timeframe e reinicio com parcial pendente.
- Parcial antes da virada do dia reconciliada depois da virada.
- Comparacao visual entre `P/L Bruto Flutuante` e o lucro da posicao no MT5 em mercado rapido.

O CSV `Fusion_trade_requests_*.csv` permanece importante para confirmar os retcodes e volumes reais de cada corretora.
