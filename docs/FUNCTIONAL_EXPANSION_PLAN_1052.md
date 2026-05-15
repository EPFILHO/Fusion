# Fusion 1.052 - Functional Expansion Plan

Este plano registra o desenho curto acordado para iniciar a 1.052 sem desfazer a organizacao conservadora da GUI fechada na 1.050/1.051.

## Guardrails

- Nao mexer no `CFusionHitGroup`.
- Nao reabrir regressao dos `ComboBox`.
- Nao usar `Enable()`/`Disable()` em `ComboBox`.
- Compilar fora da sandbox com MetaEditor depois de cada mudanca de codigo.
- Trabalhar em fatias pequenas, testaveis e revisaveis.
- Nao limpar simetria de `STRATS`/`FILTERS` antes de fechar o formato final das paginas.
- Nao mexer em hardening operacional antes de fechar estrategia, filtro e risco.

## Estrategias

As paginas de `STRATS` devem continuar concretas por estrategia nesta etapa. A MA Cross permanece como pagina de referencia e deve ser preservada nos smoke tests.

Campos esperados para expansao:

- `MA Cross`: manter toggle, prioridade, medias rapida/lenta, timeframes, metodos, precos, entrada e saida; antes da RSI, auditar os inputs MATRIX faltantes, principalmente `VM` e distancia minima entre as medias.
- `RSI`: toggle, prioridade, periodo, timeframe, sobrevendido, sobrecomprado, linha media, modo de sinal, preco e saida.
- `Bollinger`: toggle, prioridade, periodo, timeframe, desvio, preco, modo de sinal e saida.

## Auditoria MA/MATRIX

Auditoria inicial da `MA Cross` antes de expandir a RSI:

- implantado em `SEASettings`, inputs, persistencia e runtime: toggle, prioridade, periodo rapido/lento, timeframe rapido/lento, metodo rapido/lento, preco rapido/lento, modo de entrada e modo de saida;
- implantado na subaba MA: toggle, periodo rapido/lento, timeframe rapido/lento, metodo rapido/lento, preco rapido/lento, modo de entrada e modo de saida;
- prioridade existe no modelo e no runtime, mas ainda nao esta exposta como campo editavel na subaba MA;
- `VM` nao esta implantado como modo de saida: hoje existem apenas `TP/SL` e `FCO`/fechar no cruzamento oposto;
- distancia minima entre as medias nao esta implantada: nao ha campo em `SEASettings`, input, persistencia, runtime ou subaba MA;
- a validacao atual da MA cobre apenas periodo rapido/lento entre 1 e 1000 e exige periodo rapido menor que periodo lento.

Fatia MA iniciada na 1.052:

- prioridade passou a ser campo editavel da subaba `STRATS > MA`;
- `VM` passou a ser modo de saida explicito junto de `TP/SL` e `FCO`;
- distancia minima entre medias passou a ser filtro interno da estrategia MA, em pontos, aplicado antes de aceitar o cruzamento;
- a distancia e comparada pelo modulo de `fast - slow`, porque o valor assinado muda conforme a fast vem de baixo ou de cima;
- os novos campos sao persistidos nos perfis e entram em alteracoes pendentes;
- `FCO` segue como modo de saida padrao e distancia minima `0` preserva o comportamento atual de perfis antigos.

## Filtros

As paginas de `FILTERS` tambem devem continuar concretas por filtro.

Campos esperados para expansao:

- `Trend Filter`: toggle, periodo da MA, timeframe, metodo e preco.
- `RSI Filter`: toggle, periodo, timeframe, minimo para compra, maximo para venda e preco.
- `Bollinger Filter`: novo filtro separado da estrategia Bollinger, com settings proprios e sem compartilhar campos ambiguos com `bb*` da estrategia.

Direcao para `Bollinger Filter`:

- Criar settings com prefixo proprio, por exemplo `bbFilter*`.
- Criar classe runtime propria derivada de `CFilterBase`.
- O filtro nunca gera entrada; ele apenas aprova ou bloqueia o sinal recebido.
- A validacao e persistencia devem acompanhar os novos campos sem quebrar perfis antigos.

## Risco Global

Antes de overrides por estrategia, a 1.052 deve expor e validar somente o risco global que ja existe em `SEASettings` e `CRiskManager`.

Campos:

- lote fixo;
- SL fixo em pontos;
- TP fixo em pontos;
- TP parcial 1 e 2;
- breakeven;
- trailing stop.

Validacoes iniciais de GUI:

- lote respeita minimo, maximo e step do simbolo;
- SL/TP aceitam zero para desabilitar distancia fixa, mas nao valores negativos;
- TP parcial exige etapa ativa com percentual positivo, distancia positiva e soma dos percentuais ate 100;
- breakeven exige trigger positivo e offset nao negativo quando ativo;
- trailing exige start e step positivos quando ativo.

`stopsLevel` e `freezeLevel` ficam fora desta primeira etapa.

## Ordem De Trabalho

1. Registrar este desenho curto.
2. Completar `MA Cross` com prioridade editavel, `VM` e distancia minima entre as medias.
3. Expandir GUI e validacao da `RSI` strategy.
4. Expandir GUI e validacao da `Bollinger` strategy.
5. Expandir GUI e validacao de `Trend Filter` e `RSI Filter`.
6. Adicionar `Bollinger Filter`.
7. Expor e validar o risco global completo.

## Smoke Tests Minimos

- `STRATS > MA` continua salvando, recarregando e validando.
- `ComboBox` da MA continuam abrindo depois de navegar por `CONFIG`, `PROTECT`, `STATUS`, minimizar e maximizar.
- Perfis continuam carregar/salvar/duplicar/excluir com locks ativos.
- `CONFIG > PROTECT` e rodape de `PERFIS` continuam visualmente estaveis.
- Comportamento global atual de SL/TP nao muda antes da fatia de risco global.
