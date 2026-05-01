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
- Next: audit duplicated refresh calls around `RefreshConfigValidation()`, `SyncStrategyPanels()`, `SyncFilterPanels()`, and `ApplyVisibility()` in small compiled steps.
- Pending: keep auditing disk-profile canonical reloads and duplicate refresh calls in smaller compiled steps.

Recommended order:

- Extract the editability model into clearly named helpers: runtime editable, active-profile editable, profile-load allowed, profile-admin allowed.
- Make profile permissions explicit and non-overlapping: loading a profile is a recovery action, while editing/administering the active profile is a mutation.
- Centralize selected-profile runtime locks so row selection, load, duplicate, and delete cannot drift into separate rules.
- Separate "has position locally" from "sees a same-magic position owned by another active instance"; the latter must allow profile-load recovery without allowing edits.
- Treat the profile file on disk as canonical when a profile name is reused after manual deletion/recreation; reload from disk before resuming editable state instead of trusting stale in-memory settings.
- Split validation from mutation where practical, especially around `BuildPendingSettings()`, protection validation, and strategy validation.
- Replace temporary validation copies such as `ignoredProtection` / `ignoredStrategy` with an explicit "style-only validation" path if it can be done with a small diff.
- Audit `RefreshConfigValidation()`, `SyncStrategyPanels()`, `SyncFilterPanels()`, and `ApplyVisibility()` call sites, but remove only proven duplicates.
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
