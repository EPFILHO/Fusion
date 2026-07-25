# Fusion 1.056 - Persistencia e Filtros Direcionais

## Principio da fatia

A 1.056 preserva o comportamento da 1.055 quando as novas opcoes estao desligadas. Nenhum filtro novo gera sinal; eles apenas aprovam ou bloqueiam um sinal ja produzido por uma estrategia.

## Perfis e troca de timeframe

- `SaveProfile` grava em `.tmp`, descarrega e fecha o arquivo e so entao promove o temporario com `FILE_REWRITE`.
- `LoadProfile` monta uma configuracao candidata. O objeto recebido pelo chamador permanece intacto se o arquivo estiver ausente, usar schema futuro ou nao contiver o final esperado do bloco.
- Perfis legados completos continuam aceitos com defaults/migracao para campos novos. O proximo salvamento os atualiza para o schema 14.
- A troca de timeframe restaura o ultimo estado confirmado. Drafts e pending changes nunca sao transformados em configuracao salva; quando descartados, geram aviso explicito na `STATUS`.

## Bollinger direcional

O modo `Direcao BB` usa apenas a linha central do Bollinger e candles fechados. Para um lookback `N`, calcula:

`inclinacao = (linhaCentral[1] - linhaCentral[1 + N]) / point / N`

- inclinacao maior que `Incl. min. (pts/candle)`: bloqueia SELL;
- inclinacao menor que `-Incl. min. (pts/candle)`: bloqueia BUY;
- dentro da tolerancia: nao bloqueia por direcao.

A validacao de largura existente continua ocorrendo antes da regra direcional. Falta de buffer, `point` invalido ou parametros invalidos bloqueia a entrada de forma conservadora.

## Trend com duas medias independentes

`Media 1` e `Media 2` possuem ON/OFF, periodo, timeframe, metodo e preco aplicado independentes. Cada media ativa funciona como barreira completa:

- BUY exige preco atual estritamente acima de todas as medias ON;
- SELL exige preco atual estritamente abaixo de todas as medias ON;
- igualdade ou preco entre duas medias bloqueia o sinal de forma conservadora;
- com apenas uma media ON, ela funciona como filtro unico para os dois lados;
- com ambas OFF, o Trend Filter fica desligado.

Com ambas ON, a M1 e a media longa e deve ter horizonte efetivo (`periodo x duracao do timeframe`) maior que a M2. A GUI impede salvar a ordem invalida e o motor repete a guarda antes de aprovar entradas.

As duas medias visuais usam handles proprios, aparecem apenas quando o timeframe do grafico coincide com o timeframe configurado e nunca fornecem dados ao filtro.

## Roteiro minimo de teste

1. Abrir um perfil 1.055 completo e confirmar que os dois modos novos aparecem `OFF` e que o comportamento de entrada nao muda.
2. Salvar uma copia do perfil, reiniciar o EA e confirmar schema 14 e restauracao dos novos campos.
3. Truncar uma copia de arquivo de perfil e tentar carrega-la; a configuracao corrente deve permanecer e o Diario deve registrar a rejeicao.
4. Alterar um campo sem salvar, trocar o timeframe do grafico e confirmar o aviso de descarte, sem alteracao no perfil em disco.
5. Ativar `Direcao BB`, usar tolerancia zero e confirmar SELL bloqueado com linha central ascendente e BUY bloqueado com linha central descendente.
6. Aumentar `Incl. min. (pts/candle)` e confirmar que inclinacoes dentro da zona neutra deixam de bloquear.
7. Ativar M1=200 e M2=21 no mesmo TF e confirmar: acima das duas permite apenas BUY; abaixo das duas permite apenas SELL; entre elas bloqueia ambos.
8. Testar cada media isoladamente e confirmar que ela bloqueia BUY abaixo e SELL acima.
9. Testar timeframes diferentes e confirmar que a validacao usa `periodo x TF`; M1 igual ou mais curta que M2 deve impedir o salvamento.
10. Confirmar que a comparacao acompanha o preco atual e o valor corrente de cada MA.
11. Em `CONFIG > VISUAL`, testar cor e estilo das quatro MAs e das Bandas sem alterar qualquer decisao operacional.
