# Arquitetura do Fusion

Este documento descreve a arquitetura atual do Fusion e serve como guia para manutencao humana ou assistida por IA.

## Objetivo

O Fusion e um EA modular para MT5. A meta e permitir que estrategias, filtros, protecoes e regras de risco sejam adicionados sem transformar o projeto em um bloco unico dificil de testar e manter.

O projeto deve permanecer simples, mas nao simplista: cada modulo precisa ter responsabilidade clara, poucas dependencias e um ponto previsivel de integracao.

## Fluxo Principal

1. `Fusion.mq5` cria uma instancia de `CFusionApplication`.
2. `CFusionApplication` carrega inputs, estado salvo do grafico e modulos principais.
3. Estrategias e filtros sao registrados no `CSignalManager`.
4. A cada tick, o EA sincroniza a posicao, gerencia posicao aberta e, se permitido, avalia novo sinal.
5. O sinal passa por filtros e por um resolvedor de conflito.
6. O plano de risco e calculado por `CRiskManager`.
7. A ordem e enviada por `CExecutionService`.
8. Protecoes podem bloquear entrada ou forcar saida.
9. A GUI envia comandos para a aplicacao, mas a aplicacao continua sendo dona do estado operacional.

## Responsabilidades dos Modulos

### `Core`

Contem o ciclo de vida do EA, tipos compartilhados, inputs, logger, registro de instancia e a classe `CFusionApplication`.

`CFusionApplication` e o orquestrador. Ele nao deve virar um deposito de regras especificas de estrategia. Sempre que uma regra puder pertencer a risco, protecao, execucao, persistencia ou sinal, ela deve sair do core.

### `Signals`

Coordena estrategias, filtros e resolvedores.

As estrategias produzem sinais. Os filtros aprovam ou bloqueiam sinais. O resolvedor decide o que fazer quando mais de uma estrategia produz sinal ao mesmo tempo.

Na inicializacao, o `SignalManager` deve aplicar as configuracoes do perfil antes de criar indicadores. Modulos desabilitados nao devem abrir handles desnecessarios nem consumir tempo de troca de timeframe.

O `SignalManager` nao deve impor um timeframe unico ao conjunto de modulos. A direcao do Fusion e carregar timeframes operacionais explicitos por estrategia e por filtro.

### `Strategies`

Cada estrategia herda de `CStrategyBase`.

Uma estrategia deve:

- carregar seus proprios parametros;
- inicializar e liberar indicadores;
- produzir sinal de entrada;
- produzir sinal de saida apenas para posicoes que ela abriu.

Uma estrategia nao deve abrir ordem diretamente, alterar lote, nem fazer gestao financeira. Isso fica em `Risk`, `Protection` e `Execution`.

### `Filters`

Cada filtro herda de `CFilterBase`.

Um filtro deve responder se um sinal pode seguir adiante. Ele nao deve gerar entrada por conta propria. Filtros sao camadas de validacao, nao donos da posicao.

### `Risk`

Calcula plano de entrada e gestao de posicao:

- lote fixo;
- stop loss;
- take profit;
- TP parcial;
- breakeven;
- trailing stop.

Este modulo nao envia ordens. Ele calcula o que deve ser feito.

### `Protection`

Bloqueia entradas ou forca saidas com base em regras de seguranca:

- spread;
- janela de sessao;
- limites diarios;
- drawdown;
- streak de ganho ou perda.

O modulo deve evoluir para expor motivos de bloqueio de forma estruturada para a GUI.

### `Execution`

Centraliza envio, fechamento parcial, fechamento total, modificacao de stops e sincronizacao de posicao.

Este e o unico lugar que deve conversar diretamente com operacoes de trade de baixo nivel, salvo excecoes justificadas.

### `Persistence`

Salva e carrega perfis nomeados e estado automatico por grafico.

Perfis sao configuracoes operacionais. Estado de grafico e restauracao local da instancia. Esses dois conceitos nao devem ser misturados.

Em grafico real ou demo, a restauracao de estado nunca religa novas entradas automaticamente. O EA volta pausado, mas continua apto a gerenciar uma posicao aberta sincronizada ou restaurada.

O estado por grafico guarda tambem o contexto visual do chart. Esse contexto serve para restauracao segura e para alertas ao usuario, nao para redefinir os timeframes operacionais dos modulos.

### `Normalization`

Centraliza detalhes de simbolo e corretora:

- volume minimo;
- volume maximo;
- step de volume;
- digits;
- point;
- tick size;
- tick value;
- stops level;
- freeze level.

Qualquer regra que dependa de especificacao do ativo deve preferir este modulo.

### `UI`

A GUI e parte do projeto porque concentra operacao em grafico, perfis e validacoes visuais.

A UI nao deve executar trade diretamente. Ela monta comandos e envia para `CFusionApplication`.

`CFusionPanel` continua sendo o orquestrador da janela, eventos globais e snapshot. Blocos de UI que ja tem responsabilidade propria ficam em includes dedicados:

- `UIPanelTypes.mqh`: dimensoes, enums e constantes da UI.
- `UI/Pages/StatusPage.mqh`: componente da aba `STATUS`.
- `UI/Pages/ResultsPage.mqh`: componente da aba `RESULTS`.
- `UIPanelSignalTabs.mqh`: abas de estrategias e filtros.
- `UIPanelProfiles.mqh`: administracao de perfis.

Esse corte usa componentes pequenos, acoplados ao host visual apenas pelo metodo `AddControl`, para preservar o comportamento do `CAppDialog` no MQL5 e reduzir risco durante a refatoracao.

Mensagens operacionais persistentes devem ficar concentradas em `STATUS`. A aba `RESULTS` deve permanecer voltada a leitura de estado e resultados, sem acumular alertas de contexto.

Atualizacoes periodicas da GUI devem alterar dados, textos e estilos, mas nao devem reaplicar `Show/Hide` estrutural em todo timer. Visibilidade de abas deve mudar na criacao do painel, navegacao ou troca explicita de modo.

O timer da GUI deve atualizar somente a aba ativa e os controles globais indispensaveis. Abas pesadas, listas de perfis, validacoes de configuracao e sincronizacao de paginas de estrategias ou filtros devem rodar sob demanda ou quando a aba correspondente estiver visivel.

As abas principais devem preferir criacao lazy ou on-demand. No estado atual, o painel nasce com `STATUS` e com a estrutura global minima; `RESULTS`, `STRATS`, `FILTERS`, `PERFIS` e `CONFIG` passam a ser materializadas na primeira abertura. Isso reduz custo de reinicializacao em troca de timeframe e deixa o crescimento da GUI mais previsivel.

Ao criar controles apos o `Run()` da `CAppDialog`, o painel deve reatribuir IDs dos controles antes de aceitar novos cliques. Sem isso, a biblioteca padrao pode rotear eventos para handlers errados.

Depois da criacao lazy por aba, o proximo nivel correto e a criacao lazy por subpagina ou secao:

- `STRATS`: shell da aba primeiro; overview e cada painel de estrategia nascem quando abertos.
- `FILTERS`: shell da aba primeiro; overview e cada painel de filtro nascem quando abertos.
- `CONFIG`: shell e status geral primeiro; `RISK`, `PROTECT` e `SYSTEM` nascem separadamente.
- `PERFIS`: shell e navegacao browse primeiro; editor de novo ou duplicar nasce somente em modo de edicao.

Esse desenho mantem o painel responsivo e, ao mesmo tempo, prepara o codigo para crescimento modular. Para adicionar uma nova estrategia ou filtro, o objetivo e encaixar uma nova unidade de painel sem reabrir a arquitetura inteira da aba.

As paginas de estrategias e filtros devem preferir campos fechados para selecao de timeframe, usando `ComboBox` com valores explicitos do MT5. Isso evita erro de digitacao, simplifica validacao e preserva a coerencia entre GUI, perfil salvo e motor operacional.

## Prioridade Atual de Arquitetura

O proximo salto estrutural do Fusion nao e mais a GUI. O proximo salto e consolidar o motor multi-timeframe por modulo.

Essa migracao ja comecou no modelo de dados, na persistencia e nos modulos existentes. Antes de novos refactors em arquivos grandes, a arquitetura deve fechar este modelo:

- cada estrategia recebe seu proprio timeframe operacional;
- cada filtro recebe seu proprio timeframe operacional;
- `SignalManager` deixa de agir como distribuidor de um timeframe global;
- `PERIOD_CURRENT` e `Period()` saem da logica operacional e ficam, no maximo, restritos ao contexto visual do grafico.

No estado atual, esse corte ja foi aplicado ao fluxo principal de configuracao, restore, save/load de perfil e defaults internos. O timeframe atual do grafico continua sendo lido apenas para montar o contexto visual do chart e para avisos de seguranca ao usuario.

Refactors adicionais em `EAApplication.mqh` e `UIPanel.mqh` continuam desejaveis, mas ficam depois dessa virada. A regra e simples: primeiro fechamos o motor, depois emagrecemos o casco.

## Hot Reload

O projeto ja possui `RELOAD_HOT`, `RELOAD_WARM` e `RELOAD_COLD`, e os modulos principais tem pontos de recarga.

Mesmo assim, a politica atual e conservadora: a GUI bloqueia edicao enquanto o EA esta rodando ou existe posicao aberta. Isso evita alteracoes ambiguas em producao e reduz risco operacional.

No futuro, hot reload pode ser reabilitado por categorias de alteracao, desde que cada modulo declare claramente o que pode ser alterado com seguranca em runtime.

## Proximas Evolucoes Arquiteturais

- Expandir o mesmo padrao modular de selecao de timeframe para novas estrategias e filtros que forem entrando no projeto.
- Criar um modelo estruturado para status de bloqueios.
- Expor estatisticas reais para `RESULTS` e `STATS`.
- Continuar separando a `UIPanel.mqh`, especialmente `CONFIG`, conforme a GUI crescer.
- Transformar trailing, breakeven, drawdown, streak e limites diarios em submodulos mais independentes se a complexidade aumentar.
- Ampliar validacoes de volume, stops, freeze level e distancia minima.

## Nota de Persistencia por Grafico

Na arquitetura atual, o estado automatico do Fusion por grafico deve ser restaurado pelo `chart_id`, e nao por `symbol + timeframe + magic`.

O arquivo salvo por grafico tambem registra metadados do chart, principalmente simbolo e timeframe visuais. Isso permite manter o vinculo do ultimo perfil do grafico quando o usuario muda apenas o timeframe.

Se o mesmo `chart_id` reaparecer com simbolo diferente do simbolo salvo, o Fusion entra em bloqueio seguro. Nesse modo ele nao sincroniza posicao nem abre novas entradas ate o usuario voltar ao ativo anterior.
