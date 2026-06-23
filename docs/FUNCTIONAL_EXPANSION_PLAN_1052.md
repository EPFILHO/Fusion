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

Fatia RSI iniciada na 1.052:

- `EAApplication` teve o guard de permissao de trade extraido para `CTradePermissionGuard`, evitando adicionar mais validacao operacional ao orquestrador;
- o estado de `VM` pendente foi encapsulado em `CPendingReverseExit`, mantendo a execucao no mesmo fluxo e retirando campos auxiliares do orquestrador;
- `STRATS > RSI` passou a ter painel concreto com toggle, prioridade, periodo, timeframe, niveis, preco, modo de sinal e modo de saida;
- os campos da RSI usam settings, inputs, persistencia, runtime e validacao de modo propria;
- a validacao da subaba cobre prioridade, periodo, niveis 0..100, `sobrevenda < sobrecompra` nos modos de zona e `sobrevenda < media < sobrecompra` quando a saida usa a linha media;
- a saida `Cruz. Media` fecha no alvo da linha media do RSI e fica disponivel apenas no combo da RSI, sem vazar para MA/BB;
- a combinacao entrada `Cruz. Media` + saida `Cruz. Media` fica bloqueada para evitar entrada e saida na mesma linha.
- o rodape da RSI descreve a combinacao entrada/saida escolhida, incluindo o detalhe de que `Saida da Zona` com `Sinal Oposto`/`VM` espera a saida da zona oposta.

Fatia Bollinger iniciada na 1.052:

- `STRATS > BB` passou de painel generico para painel concreto com toggle, prioridade, periodo, timeframe, desvio, preco, modo de sinal e modo de saida;
- os modos exibidos sao `FFFD`, `Toque/Rejeicao` e `Rompimento`, mantendo os enums existentes da estrategia;
- a validacao cobre prioridade 0..1000, periodo 1..1000 e desvio maior que 0 ate 10;
- o rodape da Bollinger descreve entrada, saida e cautelas da combinacao selecionada;
- os novos campos entram na deteccao de alteracoes pendentes para salvar/cancelar perfis corretamente;
- a estrategia Bollinger passou a usar `ArraySetAsSeries` nos buffers e `PrimeEntryState`, alinhando a leitura de candles e a protecao contra sinal antigo com MA/RSI.

## Filtros

As paginas de `FILTERS` tambem devem continuar concretas por filtro.

Campos esperados para expansao:

- `Trend Filter`: toggle, periodo da MA, timeframe, metodo e preco. Implementado com painel concreto, validacao e leitura de buffer em serie.
- `RSI Filter`: toggle, modo, periodo, timeframe, niveis, preco e rodape explicativo. Foi implementado com modos `Direcao`, `Neutro`, `Extremos` e `Avancado`; na 1.053 o modo `Avancado` foi removido da GUI para reduzir confusao.
- `Bollinger Filter`: novo filtro separado da estrategia Bollinger, com settings proprios e sem compartilhar campos ambiguos com `bb*` da estrategia.

Revisao tecnica da expansao:

- `Trend Filter` passou a usar buffer em serie e candle fechado na leitura da MA, alinhado com as estrategias.
- `RSI Filter` passou a checar handle invalido antes de copiar buffer e manteve `ArraySetAsSeries` com `buffer[1]`, alinhado com MA/RSI/Bollinger no candle fechado.

Direcao para `Bollinger Filter`:

- Criar settings com prefixo proprio, por exemplo `bbFilter*`.
- Criar classe runtime propria derivada de `CFilterBase`.
- O filtro nunca gera entrada; ele apenas aprova ou bloqueia o sinal recebido.
- Inspiracao Matrix: filtro anti-squeeze que bloqueia entradas quando as bandas estao estreitas.
- Modos candidatos: `Absoluto`, `Relativo (%)` e, se valer a complexidade agora, `Percentil`.
- A validacao e persistencia devem acompanhar os novos campos sem quebrar perfis antigos.

## Risco Global

Antes de overrides por estrategia, a 1.052/1.053 deve expor e validar somente o risco global que ja existe em `SEASettings` e `CRiskManager`.

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

`stopsLevel` ja e validado para SL/TP fixos de entrada usando Bid/Ask e spread atual. Atualizacao da 1.054: modificacoes de SL/TP em posicao aberta passaram a respeitar `freezeLevel`; BE, trailing e remocao de TP Final Livre aguardam nova tentativa quando a corretora congelaria a alteracao.

Status na 1.053:

- concluido: `CONFIG > RISK` foi dividido em `LOTE`, `SL/TP`, `TP PARCIAL`, `BREAKEVEN` e `TRAILING`;
- concluido: TP parcial, BE e trailing foram expostos na GUI e testados em conjunto;
- concluido: BE nao piora SL ja protegido pelo trailing;
- pendente: validar `freezeLevel` em mais cenarios de mercado, ATR/range, overrides por estrategia e risco por estrategia.

## Observabilidade Operacional

Ja implementado nesta fase:

- bloqueios de sessao/news logam uma vez por episodio;
- fim de bloqueio de sessao/news tambem loga uma vez, sem prometer operacao liberada se outro blocker continuar ativo;
- queda/restauro de conexao e retomada de trading tambem logam por episodio.

Pendencias para tratar em fatia propria, sem misturar com filtro/risco:

- logar novo dia/reset diario de contadores quando a protecao diaria virar o dia;
- evoluir a aba `STATUS` para uma telemetria de sinais sem gambiarra: ultimo sinal, origem, resultado, filtro/bloqueio aplicado e motivo.

## Limpeza Tecnica Da GUI

Pendencias para uma fatia futura, sem misturar com estrategia/filtro/risco:

- aproximar `CONFIG > PROTECT` do padrao usado por `STRATS` e `FILTERS`, com grupos/paineis separados por subaba em vez de uma unica pagina com show/hide individual;
- manter a troca atual em duas fases, escondendo tudo antes de mostrar a subaba ativa, ate essa refatoracao ser feita;
- revisar residuos visuais de troca de abas/subabas no MT5 apenas com caso reproduzivel, evitando mexer nos `ComboBox` sem necessidade.

## Ordem De Trabalho

1. Concluido: registrar este desenho curto.
2. Concluido: completar `MA Cross` com prioridade editavel, `VM` e distancia minima entre as medias.
3. Concluido: expandir GUI e validacao da `RSI` strategy.
4. Concluido: expandir GUI e validacao da `Bollinger` strategy.
5. Concluido: expandir GUI e validacao de `Trend Filter` e `RSI Filter`.
6. Concluido na 1.053: fazer uma limpeza curta/segura sem mudar comportamento.
7. Concluido na 1.053: adicionar `Bollinger Filter`.
8. Concluido na 1.053: expor e validar o risco global basico.

## Smoke Tests Minimos

- `STRATS > MA` continua salvando, recarregando e validando.
- `ComboBox` da MA continuam abrindo depois de navegar por `CONFIG`, `PROTECT`, `STATUS`, minimizar e maximizar.
- Perfis continuam carregar/salvar/duplicar/excluir com locks ativos.
- `CONFIG > PROTECT` e rodape de `PERFIS` continuam visualmente estaveis.
- Comportamento global atual de SL/TP nao muda antes da fatia de risco global.
