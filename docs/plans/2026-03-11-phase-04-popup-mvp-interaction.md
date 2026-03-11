# Phase 04: Popup MVP Interaction Loop

## Objective

Ship a minimal popup interaction loop with deterministic navigation and
accept/cancel behavior, without locking final style details.

## Depends On

1. `docs/plans/2026-03-11-phase-03-apply-by-id-and-parity.md`

## In Scope

1. Render a minimal single-column popup frame and candidate list.
1. Add recursive-edit with temporary popup keymap.
1. Support cyclical navigation keys:
   - next: `Down`, `Tab`
   - previous: `Up`, `Shift-Tab`
1. Support `Enter` accept and `Escape` cancel.

## Out of Scope

1. Final border and highlight styling decisions.
1. DSR-based precise positioning.
1. tmux capture-pane save and restore.
1. Filtering and command-line preview composition.

## Planned Changes

### Popup state and rows

1. Introduce visible-row model with selectable candidate rows.
1. Keep first version simple, with one row type in this phase.

### Rendering MVP

1. Draw popup from buffered ANSI output in one print pass.
1. Render selected row state and basic update path.
1. Use fixed placement for MVP to reduce interaction risk.

### Keymap loop

1. Create temporary `_cbx_menu` keymap.
1. Enter `zle recursive-edit`.
1. Exit via `zle send-break` on accept and cancel.
1. Guarantee keymap teardown and cursor restore on exit.

## File-Level Plan

### Create

1. `lib/render.zsh`
1. `lib/navigate.zsh`
1. `lib/keymap.zsh`

### Modify

1. `lib/cbx-complete.zsh` (open popup, run loop, accept/cancel outcomes)
1. `lib/-cbx-complete.zsh` (connect captured candidates to visible rows)

## Scrut Tests To Add

1. Snapshot minimal popup frame output for small candidate sets.
1. Snapshot selection update output for next and previous movement.
1. Snapshot accept and cancel state transitions.

## zunit Tests To Add

1. Key bindings map to cyclical next and previous actions.
1. Enter sets accept action and exits recursive edit.
1. Escape sets cancel action and exits recursive edit.
1. Temporary keymap is always removed on exit.

## Manual Checks

1. Open popup on multi-match completion and navigate with all four movement keys.
1. Confirm wrap behavior at top and bottom.
1. Confirm accept inserts selection and cancel leaves line unchanged.

## Benchmark Plan

1. Measure open-popup latency for small and medium candidate counts.
1. Measure navigation redraw latency at p95.

## Acceptance Checklist

1. `make verify` passes.
1. Popup opens, navigates, accepts, and cancels correctly.
1. Cyclical navigation behavior is consistent across key variants.
1. MVP rendering overhead stays within provisional interactive budget.

## Rollback Triggers

1. Recursive-edit lifecycle leaks keymap or leaves cursor hidden.
1. Accept or cancel paths mutate command line unexpectedly.
