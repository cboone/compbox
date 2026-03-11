# Phase 07: Grouping, Scroll, and Status

## Objective

Add grouped row rendering, scroll-aware viewport behavior, and clear status
feedback while preserving navigation responsiveness.

## Depends On

1. `docs/plans/2026-03-11-phase-06-prefix-filter-and-preview-composition.md`

## In Scope

1. Introduce visible row kinds: candidate, divider, and empty.
1. Add group divider rendering between surviving groups.
1. Add viewport scrolling for large candidate sets.
1. Add status info for selected position and filter state.
1. Keep cyclical navigation while skipping non-selectable rows.

## Out of Scope

1. New filtering modes.
1. Final style lock-in for dividers and indicators.

## Planned Changes

### Row model

1. Build grouped visible rows from captured candidates.
1. Insert divider rows only where group transitions occur.
1. Keep divider rows non-selectable and id-less.

### Viewport and status

1. Track viewport start and visible row count.
1. Scroll viewport to keep selected row visible.
1. Show selected and total candidate counts.
1. Show active filter text in status display.

### Render integration

1. Render dividers, candidates, and status in one buffered pass.
1. Update only changed regions for selection movement when feasible.

## File-Level Plan

### Create

1. `lib/-cbx-generate-complist.zsh`

### Modify

1. `lib/render.zsh`
1. `lib/navigate.zsh`
1. `lib/filter.zsh`
1. `lib/cbx-complete.zsh`

## Scrut Tests To Add

1. Row generation snapshots for one, two, and three groups.
1. Divider omission snapshots when only one group survives filtering.
1. Viewport and status snapshots for overflow candidate sets.

## zunit Tests To Add

1. Navigation skips divider and empty rows in all movement directions.
1. Viewport follows selection through wrap-around movement.
1. Selected number and total count calculations stay correct under filtering.

## Manual Checks

1. Group dividers render only at true transitions.
1. Large lists scroll smoothly with cyclical navigation.
1. Status reflects filter and selection accurately.

## Benchmark Plan

1. Measure redraw cost with grouped lists and active status updates.
1. Measure worst-case navigation latency near viewport boundaries.
1. Compare p95 before and after grouped rendering.

## Acceptance Checklist

1. `make verify` passes.
1. Grouping and divider logic is correct across filter transitions.
1. Scroll and status behavior remains stable under rapid navigation.
1. p95 redraw latency remains within agreed limits.

## Rollback Triggers

1. Divider handling introduces selection bugs or skipped candidates.
1. Viewport churn creates visible flicker or lag in normal usage.
