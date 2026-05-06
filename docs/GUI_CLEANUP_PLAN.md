# Fusion GUI Cleanup Plan

Baseline before this document: version 1.048, commit `b5549e5`, pushed to `origin/main`.
Current stable line: version 1.049.

This plan keeps the ComboBox stabilization work protected while we remove small GUI scars left by the investigation. If the session context is compacted, resume from this file before making further GUI changes.

## Guardrails

- Do not weaken or remove `CFusionHitGroup`; it is the stable fix that prevents hidden pages from receiving mouse events.
- Do not reintroduce lazy control creation after `Run()`.
- Do not mix ComboBox runtime experiments with unrelated cleanup in the same change.
- Keep each cleanup step small enough to compile and manually test on its own.
- Prefer deleting clearly unused code over rewriting working GUI lifecycle code.
- Read-only validation must not promote visual control state into draft settings.
- When runtime leaves read-only mode, restore committed settings before config validation runs.
- A profile blocked by another running instance is editable only for profile navigation/loading, not for mutating the active profile draft.
- Do not change operational strategy/protection logic during GUI cleanup.
- Do not push cleanup changes until the current build compiles and passes the manual smoke tests below.

## 1.049 - Stability Closure

- Preserve `CFusionHitGroup` as the root fix for hidden controls intercepting mouse events.
- Keep ComboBox wrappers free of `Enable()` and `Disable()` calls.
- Keep active-profile editing blocked when another Fusion instance is using the same profile/magic.
- In profile conflict mode, allow only profile navigation/loading as the escape path.
- Treat profiles selected in the list as runtime-locked when their magic is used by another live instance; do not allow loading, duplicating, or deleting them from a passive panel.
- Confirm `STRATS > MA` ComboBoxes do not freeze after navigation through other tabs/subtabs.

## 1.050 - Cleanup Intent

Goal: make the GUI simpler, not simplistic. Reduce duplicated permission checks, validation side effects, and lifecycle coupling without changing behavior.

Progress in `fusion-1.050-gui-lifecycle`:

- Done: extracted named helpers for runtime editability, active-profile editability, profile loading, and profile administration.
- Done: introduced a single access-state object for global GUI permissions and shared it with header/profile rendering.
- Done: centralized selected-profile runtime locks behind one helper path used by `CARREGAR`, `DUPLICAR`, and `EXCLUIR`.
- Done: peer-lock/runtime-block transitions now refresh the active tab so profile buttons update as soon as another instance starts on the same magic/profile.
- Done: replaced temporary read-only validation copies with explicit style-only validation helpers.
- Done: added a core-side guard so `UI_COMMAND_LOAD_PROFILE` refuses a destination profile whose magic is already active in another chart, even if a stale GUI command slips through.
- Done: added a separate active-profile registry for "profile loaded in another chart", keeping it distinct from the running-instance registry and feeding the same access-state decisions.
- Done: `CARREGAR`, `DUPLICAR`, `EXCLUIR`, `SALVAR`, and `INICIAR` now respect the loaded-profile peer lock while still allowing profile-load recovery to a different free profile.
- Done: extracted `CONFIG` status/color application from `BuildPendingSettings()` as the first split between validation, visual status, and draft mutation.
- Done: moved `CONFIG` validation into `UI/UIPanelConfigValidation.mqh` and split `BuildPendingSettings()` into smaller helpers for scalar reads, section validation, visual styling, status text, and draft commit.
- Done: exposed `Magic` in `PERFIS > NOVO/DUPLICAR` as a convenience field backed by the same draft/validation path as `CONFIG > SYSTEM`.
- Done: centralized repeated overview/sync refresh groups for `STRATS` and `FILTERS` behind one helper while preserving call-specific sync flags.
- Done: removed redundant boot-time `ApplyVisibility()`/`RefreshTheme()` before the final post-snapshot visibility refresh.
- Done: `CONFIG` and `PROTECT` subtab switches now skip the intermediate theme refresh inside `ApplyVisibility()` when `RefreshConfigValidation()` immediately follows.
- Done: non-editable draft mutations in `STRATS`, `FILTERS`, signal changes, and the `SYSTEM` conflict toggle now enter through one active-profile edit guard before repainting.
- Done: top-level `INICIAR`/`SALVAR`/`CANCELAR` handlers moved into `UI/UIPanelTopActions.mqh`, with profile-save command assembly shared by header save and profile save-as.
- Done: chart-state restore now reloads the active profile from disk when no position is restored, keeping saved profiles canonical for editable startup while preserving chart-state settings for open-position recovery.
- Done: profile edit-mode transitions now reuse validation's theme refresh and call `ApplyVisibility(false)` only to rebuild the browse/edit visibility.
- Done: deferred edit events now route through `UI/UIPanelDeferredEdits.mqh`, centralizing `ENDEDIT`/`CHANGE` refresh, normalization, validation, and redraw sequencing.
- Done: header `SALVAR`/`CANCELAR` controls now start neutral before the first access-state snapshot is applied.
- Done: `CONFIG` validation status now appears in the upper panel band and reports the first specific failing domain instead of defaulting to generic pink-field guidance.
- Done: `PERFIS` status messages were shortened and the footer status label was widened to avoid clipping selected-profile lock messages.
- Done: `CONFIG` status text/color now have explicit panel state and are restored when the config area becomes visible again.
- Done: `STRATS > MA` validation now reports whether the fast period, slow period, or fast/slow ordering is invalid, and panel sync preserves invalid edit styling after tab navigation.
- Done: `PROTECT` validation copy now names the invalid field for spread, daily limits, drawdown, and streak.
- Done: main-tab navigation into `CONFIG` skips the intermediate theme refresh and relies on the validation refresh as the final repaint.
- Done: top-level `INICIAR`, `SALVAR`, and `CANCELAR` return early when no action is allowed, avoiding unnecessary command assembly or theme refresh.
- Done: `PERFIS` list up/down controls return early at scroll limits instead of rebuilding the same list state.
- Done: manual `PERFIS` scrolling now clamps the offset without forcing the selected row back into view, so up/down navigation works even when the active/selected profile starts at the first or last row.
- Done: `CONFIG`, `RISK`, `PROTECT`, and `SYSTEM` use red inactive-tab markers when their own validation domain has an error.
- Done: internal `PROTECT` subtabs now use red inactive-tab markers when their own validation domain has an error.
- Done: `STRATS` now has per-strategy validation state; `MA` marks inactive `STRATS`/`MA` tabs red when its period validation fails, and the structure can receive future RSI/BB validations.
- Done: `FILTERS` now has the same per-filter validation contract and inactive-tab marker structure, ready for future filter-specific parameters.
- Done: `STRATS` and `FILTERS` now own their upper status summaries; `CONFIG` no longer displays strategy/filter validation errors as config messages.
- Done: parent-tab status summaries now show a generic "fix red tabs" warning when the active parent tab is valid but another parent tab has validation errors.
- Done: `STATUS`, `RESULTS`, and `PERFIS` share the same upper generic warning when any parent tab has validation errors.
- Done: `STRATS` requires at least one selected strategy; ready messages now say when the EA is ready to operate.
- Done: removed one redundant tab-style redraw after `CONFIG > SYSTEM` validation and moved signal-tab validation/sync helpers into `UI/UIPanelSignalTabs.mqh`.
- Done: `CONFIG` status now reports the visible config/protection subpage error first and uses a generic red-subtab warning for errors outside the current view.
- Done: invalid live edits in `CONFIG > PROTECT` now participate in pending-change detection without promoting invalid values into the draft.
- Done: moved `PERFIS` click handling into `UI/UIPanelProfiles.mqh`, keeping profile permissions close to profile rendering/state.
- Done: moved signal panel click/change routing into `UI/UIPanelSignalTabs.mqh`, keeping STRATS/FILTERS lifecycle in the signal partial.
- Done: same-symbol chart changes preserve the started state on restore, while symbol changes still trigger the runtime safety block.
- Done: global `INICIAR/PAUSAR` starts visually neutral during panel creation and receives its operational color only after state refresh.
- Done: parent/profile-lock status now has one helper and is shown outside `CONFIG`, including STRATS/FILTERS status summaries.
- Done: moved `PROTECT` validation and pending-change helpers into `UI/UIPanelProtectionValidation.mqh`, leaving `UI/UIPanelProtectionTabs.mqh` focused on layout, visibility, sync, and clicks.
- Done: `PERFIS > NOVO/DUPLICAR` now owns its Magic validation state and red parent-tab marker instead of marking `CONFIG > SYSTEM`.
- Done: while `PERFIS > NOVO/DUPLICAR` is open, Magic uniqueness belongs to the profile editor, so `CONFIG > SYSTEM` no longer inherits duplicate-source Magic conflicts from the save-as draft.
- Done: header action buttons remain neutral through panel construction and receive operational colors only after the first settled snapshot refresh.
- Done: shared parent status is recalculated during tab visibility changes, so profile-specific errors stay local to `PERFIS` while other tabs show only the generic red-tab warning.
- Done: profile edit-mode validation now paints duplicate names and treats Magic as unavailable when it belongs to any saved profile, including the source profile in duplicate mode.
- Done: moved `PERFIS > NOVO/DUPLICAR` validation helpers into `UI/UIPanelProfileValidation.mqh`, keeping `UI/UIPanelProfiles.mqh` focused on layout, list state, visibility, and click routing.
- Done: moved GUI permission/access-state helpers into `UI/UIPanelAccessState.mqh`, keeping lifecycle editability decisions named but out of the central panel file.
- Done: moved shared parent status and tab/subtab styling into `UI/UIPanelTabStatus.mqh`, separating validation visual language from central panel visibility/routing.
- Done: moved `STRATS`/`FILTERS` validation, red markers, and local status text into `UI/UIPanelSignalValidation.mqh`, keeping signal-tab creation/sync/event routing separate.
- Done: moved `PERFIS` selected-profile locks and action-state permissions into `UI/UIPanelProfileActions.mqh`, and removed the unused selected-profile runtime-lock helper.
- Done: moved `PERFIS` mode/status helpers into `UI/UIPanelProfileState.mqh`; mode changes now clear stale temporary status overrides before repainting browse/new/duplicate state.
- Done: centralized `CONFIG > PROTECT` toggle handling so blocked clicks return without validation work and editable toggles share one release/permission/refresh path.
- Done: top action clicks now reuse one access-state snapshot per click instead of recalculating `CanPause`/`CanStart`/`CanSave`/`CanCancel` decisions on the same route.
- Done: moved main/subtab navigation click routing into `UI/UIPanelNavigation.mqh`, preserving handler order while shrinking `HandlePanelClick()`.
- Next: continue auditing duplicate refresh calls in smaller compiled steps, especially blocked edit paths.
- Pending: review remaining profile-level blocked actions only where the refresh does not explain state to the user.

Validation marker direction:

- Prefer a modular validation map over one global message string: each domain records its own validity, message, tab, and subtab.
- Show the detailed message in the owning page/subpage when it is open.
- Mark tabs/subtabs with validation errors in a warning color while preserving the active-tab visual language.
- Parent tabs own their upper summary messages: `CONFIG`, `STRATS`, and `FILTERS` each keep local status/state, while red markers show issues outside the active view.
- First slices are active for `CONFIG`, internal `PROTECT` subtabs, `STRATS > MA`, and the reusable `FILTERS` marker structure; extend later as new strategy/filter pages gain editable validation.

Validation/status messaging plan:

- Keep status ownership local by domain: `CONFIG` validation messages belong to the config area; `PERFIS` selection/load/admin messages belong to the profiles area.
- Move `CONFIG` validation feedback from the bottom edge to a more visible top-of-content position, just below subtabs and above the current subpage body, if the layout can fit without clipping.
- Replace generic validation text such as "Corrija os campos em rosa antes de salvar." with the first specific failing rule, for example "Fim da News 2 deve ser maior que o inicio.".
- Show one validation error at a time, ordered by the UI navigation order: `RISK`, `PROTECT/Geral`, `Spread`, `Session`, `News`, `Day`, `Drawdown`, `Streak`, `SYSTEM`, then strategy/filter validations if they share the same save path.
- After the first error is fixed, show the next error in that same order; avoid dumping a combined list into the panel.
- For `PERFIS`, keep messages in the profiles page, but adjust placement/width so selected-profile lock messages are not clipped.
- Use the same visual language for status text where practical, but do not create a single global status bus unless repeated local handling becomes harder to maintain.

Recommended order:

- Extract the editability model into clearly named helpers: runtime editable, active-profile editable, profile-load allowed, profile-admin allowed.
- Make profile permissions explicit and non-overlapping: loading a profile is a recovery action, while editing/administering the active profile is a mutation.
- Centralize selected-profile runtime locks so row selection, load, duplicate, and delete cannot drift into separate rules.
- Separate "has position locally" from "sees a same-magic position owned by another active instance"; the latter must allow profile-load recovery without allowing edits.
- Treat the profile file on disk as canonical when a profile name is reused after manual deletion/recreation; reload from disk before resuming editable state instead of trusting stale in-memory settings.
- Split validation from mutation where practical, especially around `BuildPendingSettings()`, protection validation, and strategy validation.
- Replace temporary validation copies such as `ignoredProtection` / `ignoredStrategy` with an explicit "style-only validation" path if it can be done with a small diff.
- Audit `RefreshConfigValidation()`, `SyncStrategyPanels()`, `SyncFilterPanels()`, and `ApplyVisibility()` call sites, but remove only proven duplicates.
- Improve validation/status copy and placement in small UI-only steps: first `CONFIG`, then `PERFIS`, preserving tab-specific ownership of messages.
- Keep ComboBox runtime helpers (`FusionResetComboRuntimeObjects()` / `FusionRaiseComboRuntimeObjects()`) until a dedicated experiment proves they are unnecessary.
- Review `UIPanel.mqh` responsibilities and move small cohesive pieces into existing partial files only when it lowers risk and improves readability.

Out of scope for 1.050:

- Strategy entry/exit behavior.
- Protection runtime rules.
- Visual redesign.
- Replacing Standard Library controls.
- Large file reorganization.

Manual smoke tests after each cleanup step:

- MA ComboBoxes open after navigating through `CONFIG`, `PROTECT`, `STATUS`, minimize and maximize.
- Changing MA `Saida` while stopped enables `SALVAR` and persists in the profile.
- Changing ComboBoxes while running, then stopping from `CONFIG`, does not enable `SALVAR`.
- Two EAs on the same profile: blocked instance can load another profile, but cannot edit/save/new/duplicate/delete the active conflicting profile.
- Two stopped EAs: if one already has a profile loaded/active, another chart cannot load, duplicate, delete, save over, or start with that same profile; it should load a different free profile instead.
- After loading a free profile in the passive EA, selecting a profile that is still running elsewhere keeps `CARREGAR`, `DUPLICAR`, and `EXCLUIR` disabled.
- `PERFIS > NOVO/DUPLICAR`: changing `Magic` in the local edit field should validate uniqueness, enable `SALVAR` only with a free positive integer, and save the new profile with that magic.
- `CONFIG > PROTECT` edit fields still enable `SALVAR` when editable.
- `CONFIG` invalid fields show one specific message at a time in the expected tab/subtab order, and the message is fully visible.
- `PERFIS` status messages such as selected-profile locks are fully visible and stay in the profiles context.
