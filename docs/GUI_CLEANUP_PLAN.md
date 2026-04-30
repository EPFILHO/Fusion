# Fusion GUI Cleanup Plan

Baseline before this document: version 1.048, commit `b5549e5`, pushed to `origin/main`.
Current stable candidate: version 1.049, pending commit/push after manual validation.

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
- Confirm `STRATS > MA` ComboBoxes do not freeze after navigation through other tabs/subtabs.

## 1.050 - Cleanup Intent

Goal: make the GUI simpler, not simplistic. Reduce duplicated permission checks, validation side effects, and lifecycle coupling without changing behavior.

Recommended order:

- Extract the editability model into clearly named helpers: runtime editable, active-profile editable, profile-load allowed, profile-admin allowed.
- Make profile permissions explicit and non-overlapping: loading a profile is a recovery action, while editing/administering the active profile is a mutation.
- Separate "has position locally" from "sees a same-magic position owned by another active instance"; the latter must allow profile-load recovery without allowing edits.
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
- `CONFIG > PROTECT` edit fields still enable `SALVAR` when editable.
