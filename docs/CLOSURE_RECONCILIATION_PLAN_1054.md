# Fusion 1.054 - Reconciliacao De Fechamentos

## Status

Implementada em 2026-06-30 e aguardando validacao prolongada em mercado.

A implementacao foi retomada depois de ocorrencias repetidas no WIN. Em uma delas, apos perda e restauracao de conexao, o historico entregou primeiro apenas a parcial de `5/10` contratos. O resumo prematuro registrou `155`, mas a posicao completa posteriormente apareceu no MT5 com `550`. A diferenca de `395` era o deal final ainda ausente, nao custo de corretagem.

## Comportamento Atual

Quando uma posicao desaparece, `EAApplication::SyncPositionState` preserva seu estado em uma reconciliacao pendente. `ExecutionService::GetClosedTradeSummary` seleciona o historico pelo identificador da posicao e compara volume acumulado de entrada e saida.

Encontrar um deal de saida nao basta. O resumo somente fica completo quando todo o volume de entrada possui saida correspondente, com tolerancia baseada no passo de volume do ativo.

Durante a espera, novas entradas, virada de mao e alteracoes de perfil ficam bloqueadas. As consultas sao repetidas no tick, timer e antecipadas por eventos de trade, com intervalos de `1`, `2` e depois `5` segundos. A mensagem de espera aparece uma vez.

O estado pendente usa a persistencia operacional existente e sobrevive a reinicio ou troca de timeframe. Se a mesma posicao reaparecer depois de uma oscilacao de conexao, a pendencia e cancelada e o gerenciamento normal continua.

Uma auditoria de inicializacao cobre estados antigos que ja foram persistidos sem posicao pendente. Ela le os deals de saida do dia por ativo, identifica a propriedade pelo magic do deal de entrada e recompõe P/L bruto, Trades, Loss/Win/BE e streak. Posicoes parcialmente abertas contribuem apenas com o lucro ja realizado, sem incrementar Trades do Dia. A auditoria aguarda conexao e repete a leitura se encontrar fechamento incompleto.

Durante a auditoria, novas entradas ficam bloqueadas. Historico vazio ou com menos trades que o chart state confirmado e rejeitado como leitura contraditoria. Se o magic mudar com DD inativo, o estado operacional anterior e descartado e a auditoria e rearmada para a nova identidade; DD ativo bloqueia a troca de magic.

## Cenarios Conhecidos

- SL, TP ou fechamento manual seguido por atraso temporario na disponibilidade do historico.
- Posicao encerrada pelo broker enquanto MT5, EA ou VPS estava desligado.
- Fechamento pelo celular durante indisponibilidade do terminal principal.
- Perda e restauracao de conexao durante o fechamento.
- Fechamento no ultimo tick da sessao, sem novos ticks ate a reabertura.
- Fechamento proximo da virada do dia em BTCUSD ou outros mercados continuos.
- Fechamento antes da virada processado somente depois do reset diario.

No WIN/B3, o caso especifico da meia-noite e pouco provavel porque a sessao encerra antes. O risco continua relevante para ativos continuos, reconexoes e encerramentos ocorridos com o terminal desligado.

## Impactos Possiveis

- P/L fechado ausente no resultado diario.
- Trades do Dia e contadores Win/Loss/BE incorretos.
- STREAK incorreto.
- DAY/DD ativados tarde ou liberados indevidamente.
- Fechamento do dia anterior contaminando o dia atual.
- Nova entrada autorizada antes de o resultado anterior ser conhecido.

## Invariantes Obrigatorios

A implementacao deve preservar:

1. Cada posicao fechada e contabilizada no maximo uma vez.
2. O estado anterior nao e descartado enquanto o historico estiver indisponivel.
3. Novas entradas ficam bloqueadas durante reconciliacao pendente.
4. O horario real do deal de saida define o dia do fechamento.
5. Fechamento de dia anterior nunca altera DAY/DD/STREAK do dia atual.
6. Reinicio do EA/MT5 preserva uma reconciliacao ainda pendente.
7. Parciais ja contabilizadas nao sao somadas novamente no fechamento final.
8. Virada de mao aguarda a reconciliacao final antes da nova entrada.
9. Logs de espera sao limitados e nao aparecem a cada tick.
10. O caminho normal de fechamento imediato permanece inalterado.

## Desenho Implementado

A solucao foi mantida coesa:

1. Estender `SClosedTradeSummary` com o horario do ultimo deal de saida.
2. Sincronizar para um estado temporario, evitando apagar antecipadamente `m_positionState`.
3. Se a posicao sumiu e o historico ainda nao esta pronto, manter o estado anterior como pendente.
4. Repetir a consulta em tick, timer e eventos de trade, com limitacao de logs.
5. Usar o mesmo caminho durante a inicializacao e restauracao.
6. Comparar o dia do deal com o dia operacional atual antes de atualizar as protecoes.
7. Somente depois do sucesso: registrar fechamento, consumir sinais acumulados, limpar estado e persistir.

Foi usado um estado pendente explicito no `EAApplication`. Para persistencia, o estado anterior da posicao continua sendo salvo ate a reconciliacao terminar; depois, P/L e contadores atualizados e o estado limpo sao gravados juntos.

## Fora Do Escopo

Este plano nao deve ser misturado com:

- resultado liquido com comissao/swap/fee;
- tratamento de `TRADE_RETCODE_PLACED` e `TRADE_RETCODE_DONE_PARTIAL`;
- refatoracao ampla de `EAApplication`;
- mudancas de GUI;
- alteracoes em estrategias ou filtros.

Esses assuntos podem compartilhar dados de historico, mas possuem contratos e testes proprios. O Fusion declara seus resultados como `P/L Bruto` e nao estima custos que podem variar por corretora ou ser cobrados fora do MT5.

## Matriz Minima De Testes

- Fechamento manual normal no mesmo dia.
- Fechamento por SL e TP no mesmo dia.
- Fechamento final depois de TP parcial.
- Historico indisponivel na primeira consulta e disponivel na tentativa seguinte.
- Terminal reiniciado depois de fechamento ocorrido offline no mesmo dia.
- Terminal reiniciado depois de fechamento pertencente ao dia anterior.
- Fechamento no ultimo tick da sessao e reconciliacao apenas pelo timer/reabertura.
- Fechamento antes da meia-noite processado depois da meia-noite.
- Fechamento depois da meia-noite sem perder o resultado do novo dia.
- Virada de mao pendente durante atraso de reconciliacao.
- Reinicio adicional enquanto a reconciliacao ainda esta pendente.

## Validacao Pendente

Manter a fatia em observacao ate ocorrerem novos fechamentos com parcial, SL/trailing e oscilacao de conexao. O sinal esperado no log e uma unica mensagem `CLOSE_SYNC` de espera, seguida por `Posicao fechada. P/L bruto: ...` somente depois que o volume de saida estiver completo.
