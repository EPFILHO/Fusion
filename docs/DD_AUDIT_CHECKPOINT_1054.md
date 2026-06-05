# Auditoria e Checkpoint de DAY/DD - 1.054

Data: 2026-06-05

## Escopo Validado

- DD financeiro e percentual.
- Base `Meta Max.Ganho` fixa no Max Ganho configurado.
- Base `Pico Ganho` acompanhando o maior P/L projetado.
- Fechamento forcado ao cruzar o `Piso DD`.
- Saidas por TP, SL ou trailing acima do piso preservando a `Folga DD`.
- Novas entradas permitidas enquanto o DD esta ativo e ainda nao foi atingido.
- Bloqueio de novas entradas depois que o DD e atingido.
- Persistencia do bloqueio apos pausa e restauracao do grafico.
- GUI mostrando pico/base, piso, folga e dados do gatilho.
- Logs diagnosticos de DAY e reducao de avisos repetidos.

## Resultado da Auditoria

A formula e o comportamento intradiario do DD ficaram coerentes com os testes em
mercado aberto. O checkpoint compila no MetaEditor com `0 errors, 0 warnings`.

## Riscos Conhecidos

1. `TRADE_RETCODE_PLACED` ainda e tratado como operacao concluida em entradas,
   fechamentos e parciais. Em execucao assincrona ou de bolsa, a ordem pode ter
   sido apenas colocada e ainda nao executada.
2. Ao detectar que uma posicao fechou, o resumo do historico e consultado uma
   unica vez. Se o negocio ainda nao estiver disponivel, nao existe retentativa
   para contabilizar DAY/DD.
3. O pico do DD e atualizado em memoria a cada tick, mas nao e salvo
   periodicamente. Uma interrupcao abrupta pode restaurar um pico anterior.
4. DAY/DD usam `DEAL_PROFIT` e `POSITION_PROFIT`; comissao, swap e taxas nao
   entram no calculo protegido.

## Pendencia Prioritaria Separada

O reset no novo dia operacional ainda falha quando nao chegam ticks, como em
feriado ou antes da abertura. A correcao sera feita em uma fatia isolada depois
deste checkpoint, sem misturar com as mudancas de DD ja testadas.
