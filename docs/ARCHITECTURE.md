# Arquitetura do Fusion

Este documento descreve a arquitetura atual do Fusion e serve como guia para manutencao humana ou assistida por IA.

## Objetivo

O Fusion e um EA modular para MT5. A meta e permitir que estrategias, filtros, protecoes e regras de risco sejam adicionados sem transformar o projeto em um bloco unico dificil de testar e manter.

O projeto deve permanecer simples, mas nao simplista: cada modulo precisa ter responsabilidade clara, poucas dependencias e um ponto previsivel de integracao.

## Convencao de Nomes e Organizacao

A convencao principal do projeto e `Dominio + Responsabilidade`.

O nome do arquivo deve ajudar alguem novo no projeto a responder duas perguntas rapidamente:

- qual parte do sistema este arquivo atende;
- qual responsabilidade concreta ele concentra.

Exemplos atuais:

- `UIPanelProfileListView`: UI / Perfis / renderizacao da lista, status e botoes da lista.
- `UIPanelProfileClicks`: UI / Perfis / roteamento de cliques e feedback de acoes bloqueadas.
- `UIPanelProfileBuild`: UI / Perfis / construcao/layout dos controles da aba.
- `UIPanelProtectionValidation`: UI / Protecao / validacao visual e leitura do draft.
- `UIPanelProtectionBuild`: UI / Protecao / construcao/layout dos controles.
- `UIPanelSignalEvents`: UI / Estrategias e filtros / sync e eventos dos paineis de sinal.
- `UIPanelSignalOverview`: UI / Estrategias e filtros / resumo visual.
- `UIPanelInitialState`: UI / Painel / estado inicial do orquestrador.
- `ProtectionModuleBase`: Protecao runtime / estado e reload comuns dos modulos.
- `ProfileNameUtils`: Core / regra compartilhada para nomes de perfil.

Evite criar arquivos com nomes genericos como `Helpers`, `Utils2` ou `Common` quando houver um dominio claro. Use um helper generico apenas quando a regra for realmente transversal e estavel.

Arquivos novos devem nascer pequenos. Se uma tela ou modulo exigir varias responsabilidades, prefira partials com nomes explicitos em vez de crescer um arquivo unico.

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
- janelas internas de news;
- limites diarios;
- drawdown;
- streak de ganho ou perda.

O `ProtectionManager` e o orquestrador. A direcao do projeto e manter cada protecao em seu proprio modulo, para que regras diferentes evoluam sem virar um unico arquivo monolitico.

Nesta fase, a camada de `Protection` passou a ser organizada em submodulos:

- `SpreadProtection`
- `SessionProtection`
- `NewsProtection`
- `DailyLimitsProtection`
- `DrawdownProtection`
- `StreakProtection`

`Drawdown` tem dependencia funcional de `DAY.maxDailyGain`: ele deve ser armado a partir da meta diaria, nao desde qualquer pico minimo de lucro. Isso evita travas por oscilacoes irrelevantes do dia.

Bloqueios operacionais dessas protecoes devem subir para a aba `STATUS` como aviso persistente enquanto a condicao estiver ativa. O log pode acompanhar, mas o painel precisa deixar claro por que novas entradas estao sendo bloqueadas.

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
- `UIPanelHeader.mqh`: titulo, perfil carregado e botoes globais do topo.
- `UIPanelInitialState.mqh`: estado inicial do painel, snapshot vazio e flags de construcao.
- `UIPanelCommandQueue.mqh`: fila interna de comandos que a UI entrega para a aplicacao.
- `UIPanelControlHelpers.mqh`: criacao de controles, hit groups e helpers basicos de visibilidade/edicao.
- `UIPanelContentLifecycle.mqh`: criacao lazy/controlada das abas principais e conteudo interno.
- `UIPanelVisibility.mqh`: visibilidade de abas, refresh visual e atualizacao da aba ativa.
- `UIPanelNavigation.mqh`: roteamento de cliques de abas principais e subtabs.
- `UIPanelAccessState.mqh`: modelo de permissoes da GUI derivado do snapshot atual.
- `UIPanelTabStatus.mqh`: status compartilhado de abas e marcadores de validacao.
- `UIPanelDeferredEdits.mqh`: tratamento de `ENDEDIT`/`CHANGE` e normalizacao de edits.
- `UIPanelDraftState.mqh`: draft settings, pending changes e sincronizacao de controles.
- `UI/Pages/StatusPage.mqh`: componente da aba `STATUS`.
- `UI/Pages/ResultsPage.mqh`: componente da aba `RESULTS`.
- `UIPanelSignalTabs.mqh`: estado raiz das abas de estrategias e filtros.
- `UIPanelSignalShell.mqh`: estrutura visual das abas `STRATS` e `FILTERS`.
- `UIPanelSignalPanels.mqh`: criacao dos paineis internos de estrategia/filtro.
- `UIPanelSignalVisibility.mqh`: visibilidade dos paineis internos de sinal.
- `UIPanelSignalValidation.mqh`: validacao e status locais de `STRATS`/`FILTERS`.
- `UIPanelSignalEvents.mqh`: sync e roteamento de eventos dos paineis de sinal.
- `UIPanelSignalOverview.mqh`: resumo visual de estrategias e filtros.
- `UIPanelProfiles.mqh`: estado raiz da administracao de perfis.
- `UIPanelProfileBuild.mqh`: construcao/layout da aba `PERFIS`.
- `UIPanelProfileVisibility.mqh`: visibilidade browse/edit de `PERFIS`.
- `UIPanelProfileState.mqh`: modo de perfil e status de rodape.
- `UIPanelProfileActions.mqh`: permissoes de carregar/duplicar/excluir perfil.
- `UIPanelProfileClicks.mqh`: roteamento de cliques de `PERFIS`.
- `UIPanelProfileListView.mqh`: renderizacao da lista, botoes e mensagens de `PERFIS`.
- `UIPanelProfileValidation.mqh`: validacao de nome/magic em `NOVO`/`DUPLICAR`.
- `UIPanelConfigTabs.mqh`: shell de `CONFIG`, `RISK` e `SYSTEM`.
- `UIPanelConfigValidation.mqh`: leitura, validacao e commit do draft de configuracao.
- `UIPanelConfigStatus.mqh`: selecao e aplicacao de status da area `CONFIG`.
- `UIPanelProtectionTabs.mqh`: estado raiz e click routing da subaba `PROTECT`.
- `UIPanelProtectionBuild.mqh`: construcao/layout de `CONFIG > PROTECT`.
- `UIPanelProtectionInputs.mqh`: parsing, normalizacao e helpers de inputs de protecao.
- `UIPanelProtectionValidation.mqh`: validacao visual e draft de protecao.
- `UIPanelProtectionVisibility.mqh`: visibilidade interna de `PROTECT`.
- `UIPanelProtectionSync.mqh`: sync de overview, botoes e controles de protecao.
- `Platform/FolderLauncher.mqh`: integracao opcional com shell do Windows, mantida fora do core operacional.

Esse corte usa componentes pequenos, acoplados ao host visual apenas pelo metodo `AddControl`, para preservar o comportamento do `CAppDialog` no MQL5 e reduzir risco durante a refatoracao.

Mensagens operacionais persistentes devem ficar concentradas em `STATUS`. A aba `RESULTS` deve permanecer voltada a leitura de estado e resultados, sem acumular alertas de contexto.

Quando um alerta operacional for importante para a seguranca, a `STATUS` deve ser dona da apresentacao desse texto, inclusive em formato multilinha. Isso evita espalhar avisos pela GUI e mantem o mesmo ponto de leitura quando o Fusion bloqueia ou avisa sobre contexto de grafico.

Troca de timeframe do grafico, por si so, nao deve mais ser tratada como erro operacional na UI. Como o Fusion esta migrando para timeframes operacionais por modulo, o chart pode ser usado apenas para inspecao visual. Alertas persistentes de `STATUS` ficam reservados para condicoes realmente perigosas, especialmente troca de ativo e ausencia de perfil esperado.

Atualizacoes periodicas da GUI devem alterar dados, textos e estilos, mas nao devem reaplicar `Show/Hide` estrutural em todo timer. Visibilidade de abas deve mudar na criacao do painel, navegacao ou troca explicita de modo.

O timer da GUI deve atualizar somente a aba ativa e os controles globais indispensaveis. Abas pesadas, listas de perfis, validacoes de configuracao e sincronizacao de paginas de estrategias ou filtros devem rodar sob demanda ou quando a aba correspondente estiver visivel.

No bootstrap da GUI, o painel deve nascer com um unico pass de hidratacao. O estado completo necessario para criar o painel deve vir no `SUIPanelSnapshot`, evitando uma segunda carga manual logo apos `CreatePanel()`. Isso reduz repaint desnecessario e ajuda a preservar a fluidez em trocas de timeframe ou recriacao do EA.

Desde a versao `1.046`, a GUI usa pre-criacao controlada de paginas e subpaginas dentro de `CFusionHitGroup`. Esse grupo e um `CWndContainer` logico, sem desenho proprio, que participa do roteamento de mouse somente quando esta visivel. A regra e: controles de paginas diferentes nao devem ser filhos diretos do `CAppDialog`; eles devem ficar dentro do grupo da pagina ou subpagina dona.

Esse desenho substitui a criacao lazy dos blocos principais porque evita dois problemas da Standard Library do MT5:

- controles criados depois de `CAppDialog::Run()` podem exigir rebinding de IDs e aumentar risco de roteamento incorreto;
- controles simples escondidos com `Hide()` ainda podem receber `OnMouseEvent()` quando estao como filhos diretos de um container visivel.

O ponto critico para os `CComboBox` foi isolar `STRATS`, `FILTERS`, `CONFIG`, `PERFIS`, `STATUS`, `RESULTS` e tambem suas subpaginas internas em grupos independentes. Assim, uma subaba escondida nao intercepta clique de uma subaba visivel, e os dropdowns do `CComboBox` deixam de ficar presos ao ultimo combo usado.

Para adicionar uma nova estrategia, filtro ou subpagina, o objetivo e encaixar uma nova unidade de painel dentro do grupo logico correspondente, sem voltar a adicionar controles de conteudo diretamente no `CAppDialog`.

As paginas de estrategias e filtros devem preferir campos fechados para selecao de timeframe, usando `ComboBox` com valores explicitos do MT5. Isso evita erro de digitacao, simplifica validacao e preserva a coerencia entre GUI, perfil salvo e motor operacional.

## Prioridade Atual de Arquitetura

A linha 1.050/1.051 fechou um ciclo de saneamento conservador da GUI. O painel ficou dividido em partials com responsabilidades mais claras, sem remover os guardrails de `CFusionHitGroup` e sem reabrir a regressao dos ComboBoxes.

O proximo salto da 1.052 deve ser expansao funcional planejada, nao novo refactor aleatorio:

- completar a GUI e validacao das estrategias/filtros alem da MA;
- adicionar Bollinger tambem como filtro, com settings proprios;
- expor e validar o risco global que ja existe no core: SL, TP, TP parcial, breakeven e trailing;
- manter risco por estrategia fora da primeira etapa da 1.052, mas desenhar a GUI e os componentes para serem reaproveitaveis depois;
- evitar limpar "simetria" de `STRATS`/`FILTERS` antes de saber a forma final das paginas de estrategia e filtro.

O modelo multi-timeframe por modulo ja foi incorporado ao fluxo principal de configuracao, restore, save/load de perfil e defaults internos. O timeframe atual do grafico continua sendo contexto visual do chart, nao regra operacional global.

Refactors em `EAApplication.mqh` continuam desejaveis, mas devem esperar o desenho de estrategia/filtro/risco. A regra para a 1.052 e simples: primeiro desenhar as novas responsabilidades, depois mover codigo em fatias pequenas e compiladas.

## Hot Reload

O projeto ja possui `RELOAD_HOT`, `RELOAD_WARM` e `RELOAD_COLD`, e os modulos principais tem pontos de recarga.

Mesmo assim, a politica atual e conservadora: a GUI bloqueia edicao enquanto o EA esta rodando ou existe posicao aberta. Isso evita alteracoes ambiguas em producao e reduz risco operacional.

No futuro, hot reload pode ser reabilitado por categorias de alteracao, desde que cada modulo declare claramente o que pode ser alterado com seguranca em runtime.

## Proximas Evolucoes Arquiteturais

- Completar campos e validacoes de RSI, Bollinger strategy, Trend Filter, RSI Filter e Bollinger Filter.
- Expor risco global completo na GUI antes de criar overrides por estrategia.
- Criar componentes de risco reaproveitaveis para futura composicao por estrategia.
- Criar um modelo estruturado para status de bloqueios.
- Expor estatisticas reais para `RESULTS` e `STATS`.
- Continuar separando a `UIPanel.mqh`, especialmente `CONFIG`, conforme a GUI crescer.
- Transformar trailing, breakeven, drawdown, streak e limites diarios em submodulos mais independentes se a complexidade aumentar.
- Ampliar validacoes de volume, stops, freeze level e distancia minima.

## Nota de Persistencia por Grafico

Na arquitetura atual, o estado automatico do Fusion por grafico deve ser restaurado pelo `chart_id`, e nao por `symbol + timeframe + magic`.

O arquivo salvo por grafico tambem registra metadados do chart, principalmente simbolo e timeframe visuais. Isso permite manter o vinculo do ultimo perfil do grafico quando o usuario muda apenas o timeframe.

O chart state tambem registra o `deinitReason` do ultimo encerramento daquela instancia. Isso e usado para diferenciar:

- `REASON_CHARTCHANGE`: o mesmo grafico mudou de simbolo ou timeframe e o Fusion deve tentar preservar o contexto operacional com aviso ou bloqueio seguro;
- `REASON_CHARTCLOSE`: o grafico foi fechado de fato, entao um `chart_id` reaproveitado nao deve reviver automaticamente aquele contexto;
- outros motivos de reinicializacao, como recompilacao ou restart, onde a restauracao continua valida.

Se o mesmo `chart_id` reaparecer com simbolo diferente do simbolo salvo e o ultimo motivo foi `REASON_CHARTCHANGE`, o Fusion entra em bloqueio seguro. Nesse modo ele nao sincroniza posicao nem abre novas entradas ate o usuario voltar ao ativo anterior.
