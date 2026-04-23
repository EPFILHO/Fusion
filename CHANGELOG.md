# Changelog

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
