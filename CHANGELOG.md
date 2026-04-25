# Changelog

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
