# Fusion 1.056 - Persistencia e Filtros Direcionais

## Principio da fatia

A 1.056 preserva o comportamento da 1.055 quando as novas opcoes estao desligadas. Nenhum filtro novo gera sinal; eles apenas aprovam ou bloqueiam um sinal ja produzido por uma estrategia.

## Perfis e troca de timeframe

- `SaveProfile` grava em `.tmp`, descarrega e fecha o arquivo e so entao promove o temporario com `FILE_REWRITE`.
- `LoadProfile` monta uma configuracao candidata. O objeto recebido pelo chamador permanece intacto se o arquivo estiver ausente, usar schema futuro ou nao contiver o final esperado do bloco.
- Perfis legados completos continuam aceitos com defaults para campos novos. O proximo salvamento os atualiza para o schema 13.
- A troca de timeframe restaura o ultimo estado confirmado. Drafts e pending changes nunca sao transformados em configuracao salva; quando descartados, geram aviso explicito na `STATUS`.

## Bollinger direcional

O modo `Direcao BB` usa apenas a linha central do Bollinger e candles fechados. Para um lookback `N`, calcula:

`inclinacao = (linhaCentral[1] - linhaCentral[1 + N]) / point / N`

- inclinacao maior que `Min Pts/C`: bloqueia SELL;
- inclinacao menor que `-Min Pts/C`: bloqueia BUY;
- dentro da tolerancia: nao bloqueia por direcao.

A validacao de largura existente continua ocorrendo antes da regra direcional. Falta de buffer, `point` invalido ou parametros invalidos bloqueia a entrada de forma conservadora.

## Trend com duas barreiras

Com `Duas MAs` desligado, a MA principal mantem a regra historica: BUY exige fechamento acima dela e SELL exige fechamento abaixo dela.

Com `Duas MAs` ligado:

- BUY consulta a MA principal, chamada na GUI de barreira de compra;
- SELL consulta a segunda MA, chamada na GUI de barreira de venda;
- cada MA possui periodo, timeframe, metodo e preco aplicado independentes;
- a comparacao usa o fechamento do ultimo candle encerrado no timeframe da MA correspondente.

A segunda MA e estritamente operacional. A camada visual existente continua mostrando a MA Trend principal com handle proprio e nunca fornece dados ao filtro.

## Roteiro minimo de teste

1. Abrir um perfil 1.055 completo e confirmar que os dois modos novos aparecem `OFF` e que o comportamento de entrada nao muda.
2. Salvar uma copia do perfil, reiniciar o EA e confirmar schema 13 e restauracao dos novos campos.
3. Truncar uma copia de arquivo de perfil e tentar carrega-la; a configuracao corrente deve permanecer e o Diario deve registrar a rejeicao.
4. Alterar um campo sem salvar, trocar o timeframe do grafico e confirmar o aviso de descarte, sem alteracao no perfil em disco.
5. Ativar `Direcao BB`, usar tolerancia zero e confirmar SELL bloqueado com linha central ascendente e BUY bloqueado com linha central descendente.
6. Aumentar `Min Pts/C` e confirmar que inclinacoes dentro da zona neutra deixam de bloquear.
7. Ativar `Duas MAs`, configurar a principal em 200 e a de venda em 21 e confirmar separadamente: preco abaixo da 200 bloqueia BUY; preco acima da 21 bloqueia SELL.
8. Testar timeframes diferentes nas duas MAs e confirmar que cada lado usa apenas candle fechado do seu proprio timeframe.
9. Desligar novamente os modos opcionais e comparar os bloqueios com a 1.055.
