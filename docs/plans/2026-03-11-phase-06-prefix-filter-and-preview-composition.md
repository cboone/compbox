# Phase 06: Prefix Filter and Preview Composition

## Objective

Add prefix filtering and command-line preview composition where typed filter text
appears in regular style and selected remainder appears as dim ghost text.

## Depends On

1. `docs/plans/2026-03-11-phase-05-positioning-and-screen-restore.md`

## In Scope

1. Add case-insensitive prefix filtering against insertion/display text.
1. Keep real command line buffer unchanged while popup is open.
1. Compose preview state into command line display:
   - filter segment in regular style
   - remainder segment in dim style
1. Restore prior preview state on all popup exits.

## Out of Scope

1. Substring matching mode.
1. Description-based filter matching.
1. Final status-line copy and styling decisions.

## Planned Changes

### Filter behavior

1. Printable keys extend filter string within popup state.
1. Backspace removes the last filter character.
1. Empty filter restores full candidate list and selection baseline.
1. No-match filter result shows dedicated no-match row.

### Preview composition

1. Save pre-popup `$POSTDISPLAY`.
1. Compose preview with typed filter segment plus selected remainder.
1. Update preview on filter and selection change.
1. Restore saved `$POSTDISPLAY` on accept, cancel, interrupt, and resize.

## File-Level Plan

### Create

1. `lib/filter.zsh`
1. `lib/ghost.zsh`

### Modify

1. `lib/keymap.zsh` (printable and backspace handling)
1. `lib/navigate.zsh` (selection reset behavior on filter updates)
1. `lib/cbx-complete.zsh` (preview save and restore orchestration)

## Scrut Tests To Add

1. Prefix filter snapshots for case-insensitive matching.
1. Snapshot no-match row generation and empty-filter reset behavior.
1. Snapshot preview composition for representative filter and selection pairs.

## zunit Tests To Add

1. Printable keys update filter state and do not mutate command buffer.
1. Backspace behavior at empty and non-empty filter states.
1. `$POSTDISPLAY` save and restore across all exit paths.
1. Preview updates track both filter changes and selection changes.

## Manual Checks

1. Typed filter text is visible on command line as regular text.
1. Selected remainder appears as dim ghost text.
1. Accept inserts selected candidate, cancel restores original command line view.

## Benchmark Plan

1. Measure filter keypress to render update latency.
1. Measure preview composition overhead under rapid typing.
1. Track p95 in medium and large candidate sets.

## Acceptance Checklist

1. `make verify` passes.
1. Prefix filtering behavior matches documented model.
1. Preview composition matches agreed command-line UX.
1. p95 typing and update latency remains within interactive budget.

## Rollback Triggers

1. Typed filter text and preview segments become visually ambiguous.
1. Preview lifecycle conflicts with other prompt widgets and leaves residue.
