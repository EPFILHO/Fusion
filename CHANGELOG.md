# Changelog

## 1.051 - 2026-05-09
- Iniciada a nova rodada conservadora de limpeza da GUI, mantendo o comportamento operacional da 1.050.
- Movidos os helpers de input, parsing e normalizacao de `CONFIG > PROTECT` para `UI/UIPanelProtectionInputs.mqh`, deixando `UI/UIPanelProtectionTabs.mqh` mais focado em layout, visibilidade e cliques.
- Movida a renderizacao da lista de `PERFIS`, incluindo scroll, botoes e status da selecao, para `UI/UIPanelProfileListView.mqh`.
- Movidos os metadados e overviews de `STRATS`/`FILTERS` para `UI/UIPanelSignalOverview.mqh`.
- Movido o clique de `CONFIG > SYSTEM` para o partial de config e evitado trabalho de estrategia em edits diferidos que pertencem a `PERFIS`, `CONFIG` ou `PROTECT`.
- Movido o roteamento de cliques de `PERFIS` para `UI/UIPanelProfileClicks.mqh`, mantendo `UI/UIPanelProfiles.mqh` centrado na criacao e visibilidade da aba.
- Movida a criacao lazy dos paineis de `STRATS`/`FILTERS` para `UI/UIPanelSignalPanels.mqh`.
- Movida a visibilidade de `STRATS`/`FILTERS` para `UI/UIPanelSignalVisibility.mqh`.
- O `CANCELAR` principal agora tambem sai do modo `PERFIS > NOVO/DUPLICAR`, espelhando o cancelamento da propria aba.
- Movidos sync e roteamento de eventos de `STRATS`/`FILTERS` para `UI/UIPanelSignalEvents.mqh`.
- Movido o shell visual das abas `STRATS`/`FILTERS` para `UI/UIPanelSignalShell.mqh`, deixando `UIPanelSignalTabs.mqh` como composição dos partials de sinais.
- Movida a visibilidade interna de `CONFIG > PROTECT` para `UI/UIPanelProtectionVisibility.mqh`.
- Movida a construcao dos controles de `CONFIG > PROTECT` para `UI/UIPanelProtectionBuild.mqh`, reduzindo `UIPanelProtectionTabs.mqh` a estado, estilo, sync e cliques.
- Movidos overview, tema e sync dos controles de `CONFIG > PROTECT` para `UI/UIPanelProtectionSync.mqh`.
- Quebrado o refresh visual da lista de `PERFIS` em helpers para linhas, editor, botoes e mensagem de status, preservando permissoes e locks existentes.

## 1.050 - 2026-04-30
- Centralizado o modelo de permissoes da GUI em helpers nomeados para editabilidade de runtime, editabilidade do perfil ativo, carregamento de perfis e administracao de perfis.
- Adicionado um access-state unico para as decisoes globais da GUI, usado pelo header, handlers e pela aba `PERFIS` para reduzir verdades paralelas.
- A lista de `PERFIS` passou a usar um caminho unico para decidir se o perfil selecionado esta travado por outra instancia antes de habilitar `CARREGAR`, `DUPLICAR` ou `EXCLUIR`.
- O core agora tambem recusa `LOAD_PROFILE` para perfil cujo magic ja esteja ativo em outro grafico, protegendo contra comandos obsoletos ou caminhos que escapem da GUI.
- Adicionado um registry leve de perfil carregado para bloquear `CARREGAR`, `DUPLICAR`, `EXCLUIR`, `SALVAR` e `INICIAR` quando o mesmo perfil ja esta ativo/carregado em outro grafico, mantendo `CARREGAR` outro perfil como rota de saida.
- Mudancas de lock causadas por outra instancia agora refrescam imediatamente a aba ativa, entao `PERFIS` atualiza `NOVO`, `CARREGAR`, `DUPLICAR` e `EXCLUIR` assim que outro EA inicia no mesmo perfil.
- A validacao em modo somente leitura agora usa helpers explicitos de validacao visual, evitando que campos de `PROTECT` ou `STRATS` promovam estado visual para o rascunho.
- O status visual da `CONFIG` foi separado de `BuildPendingSettings()`, iniciando a divisao entre validacao, pintura/status e mutacao do rascunho.
- A validacao da `CONFIG` foi movida para `UI/UIPanelConfigValidation.mqh`, separando leitura de escalares, validacao de secoes, pintura visual/status e commit do rascunho em helpers menores.
- A tela `PERFIS > NOVO/DUPLICAR` ganhou campo `Magic`, usando a mesma validacao central de `CONFIG > SYSTEM` para facilitar criar copias sem navegar para outra aba.
- Refreshes de overview/sync em `STRATS` e `FILTERS` passaram por um helper unico, reduzindo chamadas duplicadas sem mudar o fluxo de validacao.
- Removidos refreshes redundantes de visibilidade/tema durante a criacao inicial do painel; o boot agora aplica a visibilidade final uma unica vez depois de carregar e atualizar o snapshot.
- Trocas de subabas em `CONFIG`/`PROTECT` agora evitam refresh de tema intermediario quando a validacao subsequente ja fara o refresh final.
- Tentativas de editar o perfil ativo em caminhos bloqueados de `STRATS`, `FILTERS` e `SYSTEM` agora passam por um helper unico antes de refrescar o tema.
- As acoes globais `INICIAR`, `SALVAR` e `CANCELAR` foram movidas para um partial dedicado, e o enfileiramento de salvamento de perfil passou por um helper unico.
- Ao restaurar o estado do grafico sem posicao aberta, o Fusion passa a recarregar o perfil ativo do arquivo salvo quando disponivel, evitando usar uma copia antiga do chart state como fonte principal.
- Transicoes `PERFIS > NOVO`, `DUPLICAR` e `CANCELAR` agora reaplicam a visibilidade sem repetir o refresh de tema que a validacao ja executou.
- O lifecycle de edits deferidos (`ENDEDIT`/`CHANGE`) foi movido para `UI/UIPanelDeferredEdits.mqh`, mantendo a ordem de normalizacao, validacao e redraw em um ponto nomeado.
- `SALVAR` e `CANCELAR` do header agora nascem neutros durante a criacao do painel, evitando o flash inicial de botao ativo antes do primeiro snapshot da GUI.
- O status de validacao da `CONFIG` foi movido para a faixa superior do painel e agora mostra falhas especificas de perfil, lote, protecao, magic ou estrategias em vez de cair direto na mensagem generica.
- Mensagens de status da aba `PERFIS` ficaram mais curtas e ganharam mais largura no rodape do quadro para evitar corte em locks/selecoes.
- O ultimo status da `CONFIG` agora fica guardado no estado do painel e e reaplicado quando a aba volta a ficar visivel.
- A validacao da `STRATS > MA` agora informa separadamente periodo rapido, periodo lento ou ordem invalida entre as medias, e o sync da aba preserva a pintura de erro ao voltar de outras abas.
- Mensagens de validacao de `PROTECT` ficaram mais especificas para spread, limites diarios, drawdown e streak.
- A troca para a aba `CONFIG` deixou de fazer refresh de tema intermediario antes da validacao final, e botoes globais sem acao retornam cedo sem recalcular estado pesado.
- Botoes de rolagem da lista de `PERFIS` agora retornam cedo quando ja estao no limite, evitando reconstruir a lista sem mudanca visual.
- A rolagem manual de `PERFIS` deixou de ser puxada de volta pela linha selecionada; as setas preservam o offset dentro dos limites da lista.
- `CONFIG` e suas subtabs `RISK`, `PROTECT` e `SYSTEM` agora marcam erros de validacao em vermelho quando nao estao selecionadas.
- As subtabs internas de `PROTECT` agora tambem marcam seus proprios erros de validacao em vermelho quando nao estao selecionadas.
- `STRATS` ganhou mapa de validade por estrategia; `MA` ja marca erros em vermelho na aba principal e na subtab inativa, preparado para futuras estrategias.
- `FILTERS` ganhou o mesmo contrato modular de validacao por filtro, pronto para marcar erros por subtab quando os filtros tiverem parametros proprios.
- `STRATS` e `FILTERS` agora possuem status superior proprio; `CONFIG` deixou de exibir mensagens de erro pertencentes a estrategias ou filtros.
- Quando a aba atual esta valida mas outra aba mae tem erro, o status superior mostra um aviso generico para corrigir as abas em vermelho.
- `STATUS`, `RESULTS` e `PERFIS` tambem exibem o aviso superior generico quando alguma aba mae possui erro marcado em vermelho.
- `STRATS` agora exige ao menos uma estrategia selecionada e as mensagens de pronto foram alinhadas para indicar quando o EA esta pronto para operar.
- Removido um redraw redundante de abas apos validar `CONFIG > SYSTEM`; validacao e sync de `STRATS`/`FILTERS` foram movidos para o partial de abas de sinais.
- O status superior da `CONFIG` agora prioriza o erro da subaba visivel e usa um aviso generico quando o problema esta em outra subaba marcada em vermelho.
- Edits invalidos em `CONFIG > PROTECT` agora contam como alteracao pendente visual, mantendo `SALVAR` bloqueado e `CANCELAR` disponivel como em `RISK`, `SYSTEM` e `STRATS`.
- O roteamento de cliques da aba `PERFIS` foi movido para `UI/UIPanelProfiles.mqh`, reduzindo o papel do `UIPanel.mqh` sem alterar permissoes ou fluxo.
- O roteamento de cliques e mudancas de `STRATS`/`FILTERS` foi concentrado em `UI/UIPanelSignalTabs.mqh`.
- Restore apos troca de timeframe preserva o estado iniciado quando o ativo continua igual; troca de ativo segue bloqueando o runtime por seguranca.
- O botao global `INICIAR/PAUSAR` agora nasce neutro durante a criacao da GUI e so recebe cor operacional apos o primeiro refresh de estado.
- O aviso superior de perfil bloqueado por outra instancia agora aparece tambem em `STATUS`, `RESULTS`, `PERFIS`, `STRATS` e `FILTERS`, evitando mensagens de pronto durante lock.
- A validacao e deteccao de alteracoes pendentes de `PROTECT` foram movidas para `UI/UIPanelProtectionValidation.mqh`, deixando o partial principal de protecao mais focado em layout, visibilidade e cliques.
- O `Magic` editado em `PERFIS > NOVO/DUPLICAR` passou a pertencer ao estado de validacao da aba `PERFIS`, sem marcar `CONFIG > SYSTEM`; outras abas mostram o aviso generico quando `PERFIS` tem erro.
- Enquanto `PERFIS > NOVO/DUPLICAR` esta aberto, `CONFIG > SYSTEM` nao aplica conflito de unicidade do `Magic`; a unicidade fica sob responsabilidade do editor de `PERFIS`.
- Os botoes globais permanecem neutros durante a criacao inicial da GUI e so recebem cor operacional apos o primeiro snapshot/refresh final.
- A mensagem superior compartilhada agora e recalculada na troca de abas, evitando vazamento do erro especifico de `PERFIS` para `STATUS`/`RESULTS` e restaurando o detalhe ao voltar para `PERFIS`.
- `PERFIS > NOVO/DUPLICAR` agora pinta o campo de nome quando o perfil ja existe e continua pintando `Magic` quando o numero pertence a qualquer perfil salvo.
- A validacao do editor de `PERFIS` foi movida para `UI/UIPanelProfileValidation.mqh`, evitando que `UI/UIPanelProfiles.mqh` concentre lista, cliques e regras de nome/magic no mesmo bloco.
- O modelo de permissoes/access-state da GUI foi movido para `UI/UIPanelAccessState.mqh`, reduzindo o papel do `UIPanel.mqh` como concentrador de regras de lifecycle.
- O status superior compartilhado e a pintura de abas/subabas foram movidos para `UI/UIPanelTabStatus.mqh`, isolando a linguagem visual de validacao das rotas de criacao/visibilidade.
- A validacao, marcadores vermelhos e mensagens superiores de `STRATS`/`FILTERS` foram movidos para `UI/UIPanelSignalValidation.mqh`, deixando `UI/UIPanelSignalTabs.mqh` mais focado em criacao, sync, eventos e visibilidade.
- As regras de lock e permissao de acoes da aba `PERFIS` foram movidas para `UI/UIPanelProfileActions.mqh`, removendo tambem um helper morto de lock por perfil selecionado.
- Modo, status temporario e sugestao de copia de `PERFIS` foram movidos para `UI/UIPanelProfileState.mqh`; trocas de modo limpam avisos persistentes antigos para evitar vazamento visual entre criar/duplicar/cancelar.
- Toggles de `CONFIG > PROTECT` passaram por helpers comuns, preservando o no-op barato em modo bloqueado e removendo repeticao de release/permissao/validacao.
- Cliques globais em `INICIAR`, `SALVAR` e `CANCELAR` agora usam um unico snapshot de access-state por acao, evitando recalcular permissoes em rotas bloqueadas.
- O roteamento de navegacao de abas principais/subabas foi movido para `UI/UIPanelNavigation.mqh`, deixando `HandlePanelClick()` focado em orquestrar handlers.
- Visibilidade, refresh visual e atualizacao da aba ativa foram movidos para `UI/UIPanelVisibility.mqh`, reduzindo a responsabilidade direta do `UIPanel.mqh`.
- O painel agora nasce alinhado a esquerda do grafico por padrao, usando uma constante de margem inicial em vez de calcular a posicao pela largura do chart.
- Criacao/layout de `CONFIG`, `RISK` e `SYSTEM` foi movida para `UI/UIPanelConfigTabs.mqh`, deixando `UIPanel.mqh` menos concentrado em paginas especificas.
- Criacao lazy das paginas principais e `BuildAllContent()` foram movidos para `UI/UIPanelContentLifecycle.mqh`, separando o ciclo de montagem das demais regras do painel.
- Fila de comandos e helpers de criacao/visibilidade de controles foram extraidos para partials pequenos, reduzindo responsabilidades diretas de `UI/UIPanel.mqh`.
- Estado do rascunho, leitura de magic e deteccao de alteracoes pendentes foram movidos para `UI/UIPanelDraftState.mqh`.
- O registry de perfil carregado agora remove registros de graficos ja fechados antes de acusar peer lock, evitando falso aviso ao reanexar o EA.
- Mensagens da aba `PERFIS` passaram a chamar o lock de perfil "carregado" em outro grafico, alinhando o texto com a regra real.
- A aba `PERFIS` voltou a priorizar o status do perfil selecionado quando ele pode ser carregado, deixando o aviso de lock do perfil atual para as outras abas ou para a linha ativa bloqueada.
- Mantidos intactos `CFusionHitGroup` e os helpers de runtime dos `CComboBox` para preservar a estabilizacao da 1.049.

## 1.049 - 2026-04-29
- Iniciada a limpeza conservadora da GUI apos a estabilizacao dos `CComboBox`, mantendo intacto o modelo de hit-test que corrigiu os travamentos.
- Removidos helper e constantes visuais de subabas que ficaram sem uso depois da padronizacao de estilos.
- A validacao da subaba `STRATS > MA` deixou de promover valores visuais de controles para o rascunho quando a GUI esta em modo somente leitura, evitando alteracoes pendentes apos pausar/parar o EA.
- Ao sair de modo somente leitura para editavel, a GUI agora restaura o rascunho a partir da configuracao salva antes de validar a `CONFIG`, descartando estados visuais produzidos durante a execucao.
- Perfis bloqueados por outra instancia agora deixam apenas `PERFIS > CARREGAR` como caminho de saida; edicao, criacao, duplicacao e exclusao do perfil ativo ficam bloqueadas ate carregar outro perfil ou liberar o conflito.
- `PERFIS > CARREGAR` permanece habilitado como escape quando o perfil ativo esta bloqueado por outra instancia, mesmo se houver estado visual pendente descartavel.
- O conflito de perfil continua sendo detectado mesmo quando a instancia passiva enxerga uma posicao do mesmo magic, permitindo carregar outro perfil sem liberar edicao.
- A lista de `PERFIS` agora tambem bloqueia `CARREGAR`, `DUPLICAR` e `EXCLUIR` para qualquer perfil selecionado cujo magic esteja em uso por outra instancia ativa, evitando apagar ou reabrir um perfil operacional por acidente.
- Adicionado `docs/GUI_CLEANUP_PLAN.md` com guardrails, smoke tests e roteiro da `1.050` para continuar a limpeza sem reabrir a regressao.

## 1.048 - 2026-04-29
- Corrigido o dirty-state de campos validados sob demanda: edits de `CONFIG > PROTECT` agora atualizam o rascunho interno e habilitam `SALVAR` quando validos.
- A subaba `STRATS > MA` passou a reconciliar todos os combos no fluxo de validacao/salvamento, incluindo `Saida`, evitando depender apenas do evento imediato do `CComboBox`.
- A lista de modo de saida da MA passou a seguir a ordem do enum (`TP/SL`, `Cruz. oposto`) para manter `Value()` e `SelectByValue()` mais previsiveis.

## 1.047 - 2026-04-29
- O botao global `SALVAR` agora permanece bloqueado quando o perfil/magic atual esta em uso por outra instancia do Fusion, alinhando a regra com o bloqueio de `INICIAR`.
- A aba `PERFIS` volta automaticamente para a lista de perfis depois que um novo perfil ou copia e salvo/carregado pela aplicacao, sem exigir trocar de aba para atualizar a tela.
- Abas e subabas passaram a usar a mesma linguagem visual: item ativo em azul e item navegavel inativo em azul-escuro consistente.

## 1.046 - 2026-04-29
- Reestruturado o lifecycle da GUI para pre-criar paginas e subpaginas dentro de grupos logicos de hit-test, evitando que controles escondidos interceptem eventos de mouse.
- Corrigida a regressao em que os `CComboBox` da subaba `STRATS > MA` travavam depois de navegar por outras abas/subabas.
- Documentado o aprendizado: esconder controles diretos com `Hide()` nao basta para isola-los do roteamento de mouse da Standard Library; o isolamento precisa ocorrer no nivel de `CWndContainer`.
- Adicionada build identificavel para a investigacao dos `CComboBox` da aba `STRATS > MA`.

## 1.045 - 2026-04-26
- A estrategia `MA Cross` passou a ter parametros independentes por media no modelo de dados, inputs e persistencia: periodo, timeframe, metodo e preco aplicado para rapida e lenta.
- O motor da `MA Cross` ganhou `tipo de entrada` (`1o candle apos cruzamento` ou `2o candle/E2C`) sem misturar essa regra com a logica de saida.
- A saida por `cruzamento oposto` passou a usar a deteccao de cruzamento diretamente, sem depender do modo de entrada configurado.
- A subaba `MA` em `STRATS` deixou de usar o painel simplificado e ganhou pagina propria com validacao de periodos, combos de metodo/preco/entrada/saida e integracao completa com `SALVAR`, `CANCELAR` e `INICIAR`.

## 1.044 - 2026-04-26
- A correcao de minimizar/restaurar da GUI foi movida para `Minimize()` e `Maximize()`, em vez de ficar presa ao clique do botao da biblioteca padrao.
- Ao minimizar, o Fusion agora esconde explicitamente o shell e o conteudo das abas para evitar textos e controles soltos no grafico.
- Ao restaurar, o Fusion reconstrui apenas a visibilidade da aba ativa, reduzindo o risco de sobreposicao depois do restore.

## 1.043 - 2026-04-26
- O Fusion passou a reaplicar sua propria logica de visibilidade de abas apos minimizar/restaurar a janela da GUI, evitando sobreposicao de controles de paginas inativas.
- Eventos `CHARTEVENT_CHART_CHANGE` tambem passaram a reafirmar a visibilidade correta da aba ativa quando a GUI nao estiver minimizada.

## 1.042 - 2026-04-26
- A protecao de `SPREAD` passou a funcionar ponta a ponta no runtime: quando o limite e excedido, o Fusion bloqueia novas entradas, registra aviso operacional no `STATUS` e faz log com rate-limit para evitar ruido excessivo.
- O aviso operacional de protecao agora e limpo automaticamente quando a condicao deixa de bloquear o EA, sem deixar mensagem stale no painel.
- A mensagem de `SPREAD` passou a informar o valor atual e o limite configurado em pontos.

## 1.041 - 2026-04-26
- A aba `PERFIS` deixou de exibir o botao de abrir pasta, reduzindo a tentacao de manipulacao manual dos arquivos de suporte do EA.
- O perfil `default` passou a ser tratado como reservado na GUI: ele nao pode ser excluido pela aba `PERFIS`, e a interface agora orienta explicitamente que esse perfil nao deve ser apagado.
- O fluxo de primeira execucao continua recriando automaticamente o perfil `default` quando ele estiver ausente, preservando um ponto estavel de suporte e restauracao.

## 1.040 - 2026-04-26
- A validacao de horarios de `SESSION` e `NEWS` passou a exigir `fim > inicio` mesmo quando o modulo estiver desligado, evitando salvar janelas incoerentes.
- Na primeira execucao em conta real/demo, se o perfil `default` ainda nao existir, o Fusion agora o cria automaticamente a partir dos inputs atuais.

## 1.039 - 2026-04-26
- Os campos de horario de `SESSION` e `NEWS` agora sanitizam a entrada no fim da edicao, mantendo apenas digitos, formatando em dois caracteres e centralizando o texto no campo.
- A validacao de protecao passou a exigir `fim > inicio` para `SESSION` e para cada janela `NEWS` ativa.
- O Fusion reforcou a autodeteccao de tester visual: no tester comum o painel fica oculto automaticamente, e no visual mode ele pode aparecer sem depender de ajuste manual de `ShowPanel`.
- O botao de pasta deixou de depender de DLL externa, eliminando o ruido `DLL loading is not allowed` no Strategy Tester.

## 1.038 - 2026-04-26
- O pre-carregamento na `CONFIG` foi reduzido para a subaba `SYSTEM`, que foi o unico caso real observado com primeiro clique vazio vindo de `PROTECT`.
- `RISK` voltou a nascer apenas pelo fluxo normal da aba ativa, mantendo a correcao mais cirurgica e com menor impacto estrutural.

## 1.037 - 2026-04-26
- `RISK` e `SYSTEM` passaram a ser precriadas junto com a aba `CONFIG`, reduzindo o risco de primeiro clique vazio em paginas leves dessa area.
- `PROTECT` continua lazy, preservando o ganho estrutural onde a pagina e maior.

## 1.036 - 2026-04-26
- O clique em abas e subabas agora precria a pagina lazy correspondente antes de aplicar a visibilidade, reduzindo o risco de primeiro clique com area vazia.
- A correcao foi aplicada de forma geral ao fluxo de troca de abas principais, `STRATS`, `FILTERS` e `CONFIG`.

## 1.035 - 2026-04-26
- As faixas de abas e subabas passaram a usar ancora alinhada a esquerda, reduzindo a sensacao de desalinhamento entre conjuntos com larguras diferentes.
- A distancia vertical entre as abas principais e `RISK / PROTECT / SYSTEM` foi reduzida para acompanhar melhor o espacamento entre `PROTECT` e suas subabas.
- `PROTECT` teve a terceira linha aproximada da segunda, preservando o restante da mecanica da GUI.

## 1.034 - 2026-04-26
- O padrao visual de abas e subabas foi estendido para o restante da GUI, mantendo a mesma mecanica de navegacao.
- As abas principais passaram a ficar centralizadas e ganharam linha de separacao no mesmo azul da aba ativa.
- `STRATS` e `FILTERS` ganharam centralizacao das subabas, linha de separacao e moldura leve no conteudo ativo.
- `PERFIS` ganhou moldura de conteudo no mesmo padrao do restante da interface.
- `CONFIG` passou a reutilizar moldura de conteudo tambem em `RISK` e `SYSTEM`, preservando a moldura propria de `PROTECT`.

## 1.033 - 2026-04-26
- A largura do painel foi ampliada levemente para dar mais respiro visual sem mudar a mecanica do Fusion.
- As faixas internas de `CONFIG` e `PROTECT` passaram a ser centralizadas pelo maior conjunto de subabas, melhorando o alinhamento entre linhas de navegacao.
- As linhas de separacao e a moldura da area ativa de `PROTECT` passaram a usar o mesmo azul da aba selecionada.
- O cabecalho foi reajustado para respeitar a nova largura, mantendo os botoes alinhados a direita.

## 1.032 - 2026-04-26
- Refinado o visual das abas internas de `CONFIG` e `PROTECT` para ficarem mais proximas de tabs de desktop, com cinza mais claro e leitura mais limpa.
- Adicionada linha de separacao sob `RISK / PROTECT / SYSTEM`.
- A subaba `PROTECT` passou a exibir moldura leve ao redor do conteudo ativo, melhorando a leitura sem alterar a mecanica de clique ou lazy loading.

## 1.031 - 2026-04-25
- Iniciada a modularizacao real de `Protection`: `ProtectionManager` passou a orquestrar submodulos dedicados para `Spread`, `Session`, `News`, `Daily Limits`, `Drawdown` e `Streak`.
- O modelo de dados ganhou suporte a tres janelas de `NEWS`, cada uma com horario proprio e acao individual de apenas bloquear entradas ou fechar posicoes abertas e bloquear novas entradas.
- A regra de `drawdown` foi alinhada com a ideia operacional do Matrix: no Fusion ele depende de `DAY.maxDailyGain`, em vez de ficar armando desde qualquer pequeno pico de lucro do dia.
- A subaba `PROTECT` comecou a nascer como area propria com subabas internas (`GERAL`, `SPREAD`, `SESSION`, `NEWS`, `DAY`, `DRAWDOWN`, `STREAK`), preparando a GUI para crescer sem virar um bloco unico.
- O painel passou a redesenhar automaticamente o estado visual quando o bloqueio por `Magic` ou os indicadores runtime mudam, reduzindo a dependencia de eventos de mouse para repintar o `INICIAR`.

## 1.030 - 2026-04-25
- Os edits das subabas de `CONFIG` passaram a entrar no mesmo refresh visual de validacao, fazendo `SALVAR` e `CANCELAR` mudarem de cor de forma coerente apos a edicao.
- O refresh de pos-edicao da GUI deixou de chamar `ApplyVisibility()` para esses campos, reduzindo a chance de interferencia temporaria com `ComboBox` de timeframe depois de certas acoes de perfil.

## 1.029 - 2026-04-25
- A validacao de instancia ativa do Fusion passou a tratar `Magic Number` como chave global de operacao, e nao mais apenas `symbol + magic`.
- Quando outro Fusion ativo usa o mesmo `Magic`, o painel passa a bloquear somente o `INICIAR`, sem transformar isso em `runtimeBlocked` global.
- A aba `STATUS` agora mostra esse caso como `INICIO BLOQUEADO`, com orientacao para carregar outro perfil antes de operar.
- O bloqueio de inicio e recalculado em tempo real no timer e apos salvar/carregar perfil, permitindo que a liberacao apareca automaticamente quando a outra instancia para.

## 1.028 - 2026-04-25
- Unificado o bootstrap da GUI para nascer com um unico pass de hidratacao de estado.
- `SUIPanelSnapshot` passou a carregar o `SEASettings` completo, permitindo que `CreatePanel()` inicialize o painel sem segunda carga logo em seguida.
- Removida a hidratacao redundante do painel no `EAApplication` logo apos `CreatePanel()`, reduzindo repaint desnecessario na troca de timeframe e no boot do EA.

## 1.027 - 2026-04-25
- Adicionado botao global `CANCELAR` no topo da GUI para descartar alteracoes pendentes do perfil carregado e restaurar imediatamente a ultima configuracao salva.
- O novo `CANCELAR` atua apenas sobre alteracoes pendentes do perfil atual; o `CANCELAR` local de `NOVO` e `DUPLICAR` continua responsavel apenas pelo fluxo de criacao de perfis.
- Removido o aviso de mudanca de timeframe do grafico na `STATUS`, porque o Fusion agora caminha para operacao multi-timeframe por modulo e o usuario pode trocar o TF apenas para inspecao visual.
- Mantido o bloqueio forte apenas para troca de ativo, que continua sendo risco operacional real para o contexto do EA.

## 1.026 - 2026-04-25
- Corrigido o restore por `chart_id` para ignorar estado salvo cuja ultima saida foi `REASON_CHARTCLOSE`, evitando que um grafico novo herde contexto “fantasma” de outro grafico fechado.
- O bloqueio por troca de ativo continua existindo para mudancas reais de contexto do mesmo grafico (`REASON_CHARTCHANGE`), mas deixa de disparar em reaproveitamento acidental de `chart_id`.
- O boot sem chart state valido agora tenta carregar de verdade o perfil definido em `defaultProfileName` antes de cair nos `inputs`.
- Quando o perfil default nao existe, o Fusion passa a avisar explicitamente na `STATUS` que os `inputs` atuais foram mantidos ate carregar ou salvar um perfil.
- O chart state passou a registrar tambem o `deinitReason` para diferenciar troca de contexto, fechamento de grafico e reaproveitamento indevido de estado.

## 1.025 - 2026-04-25
- Extraido o topo da GUI para `UI/UIPanelHeader.mqh`, removendo do `UIPanel` o botao global `CARREGAR` e preparando o painel para novos polimentos sem inflar o arquivo central.
- A janela agora expõe o nome completo `EP Fusion - versao 1.025` no titulo do dialogo.
- A aba `STATUS` passou a usar bloco de aviso multilinha proprio, evitando que alertas de troca de ativo ou timeframe fiquem cortados.
- A aba `PERFIS` ganhou o botao `ABRIR PASTA`, usando helper isolado de plataforma para abrir a pasta de perfis sem colocar logica de shell dentro do `EAApplication`.
- `SettingsStore` passou a centralizar melhor os caminhos de perfis e de chart state, reduzindo repeticao de strings e deixando o caminho da pasta de perfis disponivel para a GUI.

## 1.024 - 2026-04-25
- Corrigido o fluxo de eventos interno da GUI para nao reaplicar `ApplyVisibility()` apos eventos tratados pela `CAppDialog`.
- Essa mudanca evita que `ComboBox` de timeframe esconda a propria lista ao receber clique interno e tambem reduz o atraso ao trocar entre subabas vizinhas em `STRATS` e `FILTERS`.

## 1.023 - 2026-04-25
- Removida a dependencia residual de `Period()` do caminho operacional do Fusion; ele ficou restrito ao contexto visual e a comparacoes de seguranca do grafico.
- O fallback operacional do EA passou a usar `chart context` salvo ou `FUSION_DEFAULT_TIMEFRAME`, em vez de puxar o timeframe atual do grafico durante save/load/apply.
- O Fusion passou a ter timeframe padrao explicito (`PERIOD_M15`) para configuracoes novas, inputs e defaults internos, eliminando o uso de `PERIOD_CURRENT` como sentinela operacional.
- `StrategyBase`, `FilterBase`, `MACrossStrategy` e os novos componentes de `ComboBox` de timeframe foram alinhados com esse modelo explicito.

## 1.022 - 2026-04-25
- `STRATS` e `FILTERS` passaram a expor selecao de timeframe por modulo com `ComboBox`, sem depender de texto livre.
- `MA Cross` agora pode ser configurado pela GUI com `TF Rapido` e `TF Lento`.
- `RSI`, `Bollinger`, `Trend Filter` e `RSI Filter` agora podem ter seus timeframes operacionais editados visualmente e persistidos nos perfis.
- A GUI passou a tratar mudanca de timeframe nas abas de estrategia e filtro como alteracao pendente real, habilitando `SALVAR` de forma coerente.
- O suporte a `ComboBox` foi encapsulado em componentes reutilizaveis para manter a expansao de novas estrategias e filtros sem inflar o `UIPanel.mqh`.

## 1.021 - 2026-04-24
- O motor do Fusion passou a carregar timeframes explicitos por modulo em `SEASettings`, `Inputs` e persistencia de perfis/chart state.
- `MA Cross` agora suporta `fastTF` e `slowTF` independentes no nucleo operacional.
- `RSI`, `Bollinger`, `Trend Filter` e `RSI Filter` passaram a usar seus proprios timeframes operacionais, em vez de depender de um timeframe global do grafico.
- `SignalManager` deixou de inicializar estrategias e filtros com um timeframe unico imposto pelo chart.
- Perfis antigos com timeframes nao explicitos passam por resolucao segura de fallback para evitar quebra imediata na migracao.
- A mensagem operacional de troca de ativo/timeframe saiu de `RESULTS` e ficou persistente em `STATUS`.
- Ao criar a GUI, o painel agora tambem recebe o `SEASettings` completo logo no boot para nao perder campos ainda nao expostos visualmente.
- `README.md`, `docs/ARCHITECTURE.md` e `docs/DECISIONS.md` foram alinhados com a virada multi-timeframe e com o adiamento consciente dos refactors maiores em `EAApplication.mqh` e `UIPanel.mqh`.

## 1.020 - 2026-04-24
- A persistencia automatica por grafico passou a ser chaveada por `chart_id`, e nao mais por `symbol + timeframe + magic`.
- O estado salvo por grafico agora grava tambem metadados do contexto visual, incluindo simbolo e timeframe do chart.
- A restauracao voltou a localizar corretamente o ultimo perfil daquele grafico mesmo apos troca de timeframe.
- Se o usuario trocar o ativo do grafico, o Fusion entra em bloqueio seguro: nao sincroniza posicao, nao abre novas entradas e exige voltar ao ativo anterior para recuperar o contexto.
- A GUI passou a refletir esse bloqueio em `STATUS`, `RESULTS`, `CONFIG` e no botao `INICIAR`.
- Documentada a prioridade arquitetural do proximo ciclo: consolidar o modelo multi-timeframe por modulo antes de novos refactors amplos em `EAApplication.mqh` e `UIPanel.mqh`.

## 1.019 - 2026-04-24
- Adicionado lazy interno em `STRATS`, `FILTERS`, `PERFIS` e `CONFIG`.
- `STRATS` e `FILTERS` passam a criar overview e painéis individuais somente quando cada subpágina é aberta.
- `CONFIG` passa a criar `RISK`, `PROTECT` e `SYSTEM` separadamente, mantendo apenas o shell e o status geral no boot da aba.
- `PERFIS` passa a separar o modo browse do modo de edição, criando o editor apenas ao entrar em `NOVO` ou `DUPLICAR`.
- Ajustado o fluxo de validação para usar `m_draftSettings` como fallback seguro quando uma subpágina ainda não foi materializada.

## 1.018 - 2026-04-23
- Corrigido o bug em que cliques em controles criados sob demanda podiam disparar `ExpertRemove()`.
- Cada aba lazy agora reatribui IDs da `CAppDialog` logo apos criar novos controles.
- Adicionada protecao extra para ignorar qualquer roteamento acidental ao handler interno de fechamento da biblioteca padrao.

## 1.017 - 2026-04-23
- Iniciada a migracao da GUI para lazy/on-demand nas abas principais.
- `STATUS` passa a ser a unica pagina criada no boot; `RESULTS`, `STRATS`, `FILTERS`, `PERFIS` e `CONFIG` sao criadas na primeira abertura.
- Corrigidos acessos prematuros a controles de `PERFIS` e `CONFIG` antes da criacao das abas.
- Cada aba lazy agora se hidrata ao nascer com os dados correntes do snapshot e do perfil carregado.

## 1.016 - 2026-04-23
- Corrigida a inicializacao do `SignalManager` para aplicar configuracoes antes de criar indicadores.
- Estrategias e filtros desabilitados deixam de criar handles na inicializacao e passam a liberar handles ao serem desligados.
- Adicionado log de timing da fase de `Initialize` quando `debugLogs` estiver ativo.

## 1.015 - 2026-04-23
- Otimizado o update periodico da GUI para atualizar apenas a aba ativa.
- Evitado refresh de perfis, validacoes de config e sync de estrategias/filtros quando essas abas nao estao visiveis.
- Mantidos os botoes globais e o status operacional atualizados sem sobrecarregar o timer.

## 1.014 - 2026-04-23
- Ajustado o refresh da GUI para nao reaplicar visibilidade estrutural em todo `OnTimer`.
- Mantida a visibilidade das abas apenas na criacao do painel e em navegacao/mudanca de modo.
- Reduzida a chance de cliques intermitentes causada por `Show/Hide` repetido em objetos do MT5.

## 1.013 - 2026-04-22
- Transformadas as abas `STATUS` e `RESULTS` em componentes reais em `UI/Pages`.
- Removido o include textual antigo `UIPanelStatusResults.mqh`.
- Mantido `CFusionPanel` como orquestrador da janela, delegando criação, visibilidade e atualização dessas abas.

## 1.012 - 2026-04-22
- Alterada a restauração de estado por gráfico para que contas real/demo nunca retomem operações automaticamente.
- Mantido o comportamento automático no Strategy Tester para preservar backtests via parâmetros `input`.
- Mantido o gerenciamento de posições restauradas/abertas mesmo com o EA pausado, incluindo refresh e liberação do registro de instância.

## 1.011 - 2026-04-22
- Split reusable `CFusionPanel` sections into dedicated UI include files.
- Moved panel constants/enums to `UI/UIPanelTypes.mqh`.
- Moved status/results, strategy/filter tabs and profile-tab logic out of `UI/UIPanel.mqh`.
- Preserved existing GUI behavior while reducing the main panel file size.

## 1.010 - 2026-04-22
- Reworked the README in Portuguese to document the current project state.
- Added architecture and project-decision documents under `docs/`.
- Standardized strategy and filter panel descriptions.
- Renamed the profile refresh button to `Atualizar Lista`.

## 1.009 - 2026-04-21
- Decoupled the `NOVO` profile action from current configuration validity; validation now belongs to save/start.
- Added a real duplicate-profile flow that loads the selected profile as an editable draft and requires a unique Magic Number before saving.
- Removed the dead direct-copy profile helper to avoid implying unsafe Magic duplication.

## 1.008 - 2026-04-21
- Fixed `CSettingsStore::LoadProfile` const-correctness so profile magic validation compiles in MQL5.

## 1.007 - 2026-04-21
- Added global profile validation so a Magic Number can belong to only one saved profile.
- Blocked profile saves and new-profile creation when the chosen Magic Number is already used.
- Blocked direct profile duplication because it would copy the same Magic Number.
- Kept runtime instance validation as an additional safety layer for active charts.

## 1.006 - 2026-04-21
- Reverted the incorrect per-strategy magic-number model.
- Restored the profile/EA magic number as the operational trade identity.
- Added a runtime instance registry to block another active Fusion on the same symbol and magic number.
- Added a netting/exchange account guard to avoid opening when the symbol has a foreign magic position.
- Documented the profile-magic ownership decision and the next validation step for profile metadata.

## 1.004 - 2026-04-21
- Reworked profile management into explicit browse, new and duplicate modes.
- Added a `NOVO` profile button and a `CANCELAR` action for profile editing mode.
- Removed the fragile live key-tracking workaround for `CEdit` profile names.
- Kept load/delete actions exclusive to browse mode to avoid ambiguous profile operations.

## 1.003 - 2026-04-20
- Added a live draft state for the profile `Novo nome` field.
- Made profile load/delete depend on an empty new-name draft, while save-as/duplicate use the live draft.
- Cleared the new-name draft when selecting a saved profile to keep selection and creation flows separate.

## 1.002 - 2026-04-20
- Replaced the loaded profile input in the header with a read-only status label.
- Replaced profile list `UP`/`DN` buttons with arrow glyphs.
- Improved profile tab validation so load/delete require the typed name to match the selected profile.
- Refreshed profile validation from live edit text and chart edit/key events.

## 1.001 - 2026-04-20
- Added the `PERFIS` panel tab for profile administration from the chart.
- Added profile listing, selection, refresh, load, save-as, duplicate and delete actions.
- Guarded profile actions with the same runtime locks used by the EA configuration flow.
- Added safe profile file helpers for listing, existence checks, duplication and deletion.

## 1.000 - 2026-04-18
- Created the first clean-room project scaffold for a modular MT5 EA.
- Split the project into core, signals, strategies, filters, risk, protection, execution, persistence, normalization and UI.
- Added versioned settings, named profiles and chart autosave/restore foundations.
- Added a lightweight chart panel as the first hot reload surface.
- Added base interfaces for strategies, filters and conflict resolvers.
