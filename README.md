# Fusion

This project is a clean-room MT5 EA scaffold inspired by the strengths of the `Matrix` repository without copying its structure blindly.

## Current principles
- One EA instance operates only the symbol/timeframe of the chart where it is attached.
- Different charts must use different strategy magic numbers when isolation is required.
- One position at a time per EA instance.
- Multi-strategy and multi-filter architecture.
- Strategy conflict resolution is pluggable.
- The strategy that owns the entry owns the signal-based exit.
- Risk and protection layers may always force the exit.
- Hot reload is treated as a first-class concern.
- Persistence is versioned from day one.

## Initial module map
- `Core`: lifecycle, types, logging, input mapping and the application orchestrator.
- `Signals`: strategy aggregation, filter validation and conflict resolution.
- `Strategies`: strategy base class and concrete implementations.
- `Filters`: filter base class and concrete implementations.
- `Risk`: lot, SL, TP, partial TP, breakeven and trailing calculations.
- `Protection`: spread, session window, daily limits, streak and drawdown guards.
- `Execution`: order routing, sync, position ownership and trade-history reconciliation.
- `Persistence`: named profiles and chart autosave/restore.
- `Normalization`: broker and symbol normalization.
- `UI`: lightweight chart panel and UI command translation.

## Notes
- The panel included in this first revision is intentionally lean. It is the seed for hot reload, not the final UX.
- Persistence is separated into named profiles and per-chart autosave so the user can maintain multiple setups per market and strategy family.
- `OnTradeTransaction` is part of the design from the beginning, even in this first scaffold.
- Operational ownership is based on `symbol + strategy magic + position/deal identifiers`. Order comments are treated only as optional human-readable labels because brokers may alter or drop them, especially around partial closes.
- The legacy/base `magicNumber` remains for compatibility and profile identity, while execution uses the magic number owned by the strategy that produced the signal.
- On netting/exchange accounts, Fusion blocks new entries when the symbol already has a position outside the active strategy magics, because the account model itself does not isolate positions by magic.
