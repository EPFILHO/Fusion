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

- Read `docs/ARCHITECTURE.md`, especially the `Dominio + Responsabilidade` naming convention.
- Write a small design note before coding:
  - which fields each strategy/filter needs in the GUI;
  - how Bollinger will exist both as strategy and filter without sharing ambiguous settings;
  - whether risk overrides live inside each strategy section or a shared reusable risk subpanel;
  - how settings are persisted without breaking existing profiles;
  - how the `RiskManager` receives the resolved risk plan for a `strategyId`.

## Smoke Tests To Preserve

- Existing MA page still saves, reloads, validates, and opens ComboBoxes after navigation/minimize/maximize.
- Existing profiles still load/save/duplicate/delete with active-profile locks intact.
- `CONFIG > PROTECT` validation and two-line `PERFIS` footer remain visually stable.
- Existing global SL/TP behavior remains unchanged until the per-strategy risk model is intentionally implemented.

## Prompt For The 1.052 Session

```text
Vamos iniciar a 1.052 do Fusion a partir do main. A 1.051 fechou a limpeza conservadora da GUI e o ultimo checkpoint bom esta no main, compilado com 0 errors/0 warnings e testado manualmente.

Leia primeiro docs/ARCHITECTURE.md, docs/GUI_CLEANUP_PLAN.md e docs/NEXT_SESSION_HANDOFF_1052.md. Mantenha os guardrails: nao mexer no CFusionHitGroup, nao reabrir regressao dos ComboBoxes, nao usar Enable()/Disable() em ComboBoxes, compilar fora da sandbox depois de cada mudanca de codigo e trabalhar em fatias pequenas/testaveis.

Objetivo da 1.052: planejar e iniciar a expansao funcional sem desfazer a organizacao da 1.050/1.051. Primeiro alinhe um desenho curto para completar GUI/validacao de RSI, Bollinger strategy, Trend Filter, RSI Filter e adicionar Bollinger como filtro. Em seguida vamos expor/validar o risco global ja existente (SL, TP, TP parcial, breakeven, trailing), deixando override por estrategia para uma fase posterior.

Nao comece limpando a simetria STRATS/FILTERS antes de conversarmos o formato final dessas paginas. Nao mexa em hardening operacional (stopsLevel/freezeLevel, logs de news/sessao, EAApplication.mqh) antes do desenho de estrategia/filtro/risco estar claro.

Sempre me peca para testar antes de commit/push, salvo se eu disser explicitamente para commitar. Quando eu aprovar, commit/push direto no main.
```
