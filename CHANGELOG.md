# Changelog

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
