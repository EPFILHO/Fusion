# Fusion 1.052 - Planning Handoff

Start from `main` after the 1.051 GUI cleanup closure. The 1.051 line focused on conservative GUI organization, profile UX cleanup, protection-panel cleanup, and small structural helpers. Do not resume 1.052 by continuing random GUI refactors; start with a design pass.

## Guardrails

- Keep the 1.051 GUI stabilization intact.
- Do not weaken or remove `CFusionHitGroup`.
- Do not call `Enable()`/`Disable()` on ComboBoxes.
- Compile outside the sandbox with MetaEditor after each code change.
- Keep operational changes separate from cosmetic/cleanup changes.
- Discuss `STRATS`/`FILTERS` validation symmetry before changing it, because the strategy/filter pages are likely to expand.

## Main 1.052 Questions

1. Complete the strategy/filter GUI model.
   - MA is the most complete strategy page today.
   - RSI, Bollinger, Trend Filter, and RSI Filter still need richer editable fields and validations.
   - Avoid over-abstracting `STRATS`/`FILTERS` until the final page shape is clearer.

2. Define risk scope.
   - Today SL/TP, partial TP, breakeven, and trailing are global in `SEASettings`.
   - Decide whether strategies should use global risk defaults, per-strategy overrides, or both.
   - Preferred direction: keep global defaults and add optional per-strategy overrides.

3. Decide position-plan persistence.
   - If a strategy enters with custom risk settings, decide whether the open position should keep that entry plan frozen.
   - Preferred direction: freeze the risk plan used at entry so BE/trailing/partials do not change unexpectedly after profile edits.

4. Operational hardening.
   - Validate entry SL/TP and stop modifications against broker `stopsLevel`/`freezeLevel`.
   - Improve session/news protection logging so a continuous block logs at start and clear/end, not repeatedly every minute.
   - Review `EAApplication.mqh` after the risk/strategy model is clear, because it will likely be touched by strategy-owned plans.

## Suggested First Slice

- Write a small design note before coding:
  - which fields each strategy/filter needs in the GUI;
  - whether risk overrides live inside each strategy section or a shared reusable risk subpanel;
  - how settings are persisted without breaking existing profiles;
  - how the `RiskManager` receives the resolved risk plan for a `strategyId`.

## Smoke Tests To Preserve

- Existing MA page still saves, reloads, validates, and opens ComboBoxes after navigation/minimize/maximize.
- Existing profiles still load/save/duplicate/delete with active-profile locks intact.
- `CONFIG > PROTECT` validation and two-line `PERFIS` footer remain visually stable.
- Existing global SL/TP behavior remains unchanged until the per-strategy risk model is intentionally implemented.
