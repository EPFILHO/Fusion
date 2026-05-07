# Fusion 1.050 - Next Session Handoff

Last known good commit: `108631e` (`Extract panel orchestration helpers`) on `main`.

The 1.050 GUI cleanup is in a good checkpoint. `UI/UIPanel.mqh` is now mostly an orchestrator, with lifecycle, command queue, control helpers, draft state, access state, visibility, navigation, tab status, profiles, protection, and signal logic split into focused partials.

Manual tests reported by the user passed after the last changes. The last compiled build in this session passed with `0 errors, 0 warnings`.

## Guardrails

- Always commit/push directly to `main` unless the user explicitly asks for a branch.
- Compile outside the sandbox with MetaEditor after code changes.
- Keep each cleanup small, testable, and behavior-preserving.
- Do not change strategy entry/exit behavior or runtime protection rules during GUI cleanup.
- Do not weaken or remove `CFusionHitGroup`.
- Do not remove ComboBox runtime helpers or call `Enable()`/`Disable()` on ComboBoxes.
- Preserve the current profile-lock behavior:
  - A profile loaded in another chart blocks editing/admin on the current active profile.
  - Loading a different free profile remains the escape path.
  - In `PERFIS`, when a free profile is selected and `CARREGAR` is enabled, status should describe the selected profile, not the blocked active profile.

## Current File Shape

- `UI/UIPanel.mqh`: orchestrator, about 543 lines.
- Larger files still worth auditing carefully:
  - `UI/UIPanelProtectionTabs.mqh`
  - `UI/UIPanelProfiles.mqh`
  - `UI/UIPanelSignalTabs.mqh`
- Recent focused partials:
  - `UI/UIPanelContentLifecycle.mqh`
  - `UI/UIPanelCommandQueue.mqh`
  - `UI/UIPanelControlHelpers.mqh`
  - `UI/UIPanelDraftState.mqh`
  - plus earlier partials for access state, visibility, tab status, profile validation/actions/state, signal validation, and protection validation.

## Recommended Next Work

1. Audit `UI/UIPanelProtectionTabs.mqh`.
   - Look for separable layout/build, sync/theme, visibility, and click-routing blocks.
   - Extract only cohesive blocks if the resulting partial will stay small and clearer.
   - Avoid moving validation again; `UI/UIPanelProtectionValidation.mqh` already owns that.

2. Audit `UI/UIPanelProfiles.mqh`.
   - Good candidates: profile list rendering/scroll state, browse/edit visibility, or row styling.
   - Keep profile action permissions in `UI/UIPanelProfileActions.mqh` and validation in `UI/UIPanelProfileValidation.mqh`.

3. Audit `UI/UIPanelSignalTabs.mqh`.
   - Good candidates: overview creation/sync, strategy/filter panel creation, or visibility.
   - Keep signal validation in `UI/UIPanelSignalValidation.mqh`.

4. Continue the refresh/no-op audit.
   - Check `RefreshConfigValidation()`, `RefreshTheme()`, `ApplyVisibility()`, `UpdateProfileListView()`, `SyncStrategyPanels()`, and `SyncFilterPanels()` call sites.
   - Remove only duplicated calls that are proven redundant.
   - Blocked button/action paths should return early without rebuilding state unnecessarily.

5. Keep documentation updated after each safe slice.
   - Update `CHANGELOG.md` for user-visible or structural cleanup.
   - Update `docs/GUI_CLEANUP_PLAN.md` when a planned cleanup item is completed.

## Smoke Tests For The Next Session

- Attach EA with no other chart using the same profile: no false "perfil carregado em outro grafico" warning.
- Attach two charts with the same profile loaded: editing/admin stays blocked, but loading another free profile remains possible.
- In `PERFIS`, select a free profile while the active profile is blocked elsewhere: footer should describe the selected profile and `CARREGAR` should be enabled.
- Select a profile whose magic/profile is active elsewhere: `CARREGAR`, `DUPLICAR`, and `EXCLUIR` stay disabled.
- `PERFIS > NOVO/DUPLICAR`: duplicate names and duplicate magic values paint the correct fields and block save.
- `CONFIG > PROTECT`: invalid fields mark the right subtab and keep `SALVAR` blocked plus `CANCELAR` available.
- `STRATS > MA`: invalid periods keep fields pink after leaving and returning to the subtab.
- MA ComboBoxes still open after navigating through `STATUS`, `RESULTS`, `PERFIS`, `CONFIG`, `PROTECT`, minimize, and maximize.
- Saving/canceling config changes still persists or restores correctly across profile switches.

## Prompt For The Next Session

```text
Vamos continuar a 1.050 do Fusion a partir do main. O ultimo checkpoint bom e o commit 108631e (`Extract panel orchestration helpers`), compilado com 0 errors/0 warnings e testado na GUI.

Leia primeiro docs/GUI_CLEANUP_PLAN.md e docs/NEXT_SESSION_HANDOFF_1050.md. Mantenha os guardrails: nao mexer no CFusionHitGroup, nao reabrir regressao dos ComboBoxes, nao usar Enable()/Disable() em ComboBoxes, nao alterar comportamento operacional, e compilar fora da sandbox depois de cada mudanca de codigo.

Objetivo da proxima sessao: continuar a limpeza conservadora da GUI. O UIPanel.mqh ja virou orquestrador; agora audite em fatias pequenas os arquivos ainda maiores: UI/UIPanelProtectionTabs.mqh, UI/UIPanelProfiles.mqh e UI/UIPanelSignalTabs.mqh. Extraia apenas blocos coesos que reduzam responsabilidade sem criar novos monolitos. Continue tambem a auditoria de RefreshConfigValidation(), RefreshTheme(), ApplyVisibility(), UpdateProfileListView(), SyncStrategyPanels() e SyncFilterPanels(), removendo so duplicidade comprovada e mantendo caminhos bloqueados/no-op baratos.

Sempre me peca para testar antes de commit/push, salvo se eu disser explicitamente para commitar. Quando eu aprovar, commit/push direto no main.
```
