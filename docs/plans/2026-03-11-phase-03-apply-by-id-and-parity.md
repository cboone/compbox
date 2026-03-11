# Phase 03: Apply by Id and Completion Parity

## Objective

Replay insertion through zsh completion internals using selected candidate ids,
and lock parity for core completion edge cases.

## Depends On

1. `docs/plans/2026-03-11-phase-02-candidate-capture-data-model.md`

## In Scope

1. Add `_cbx-apply` completion widget and id-based lookup.
1. Replay original `compadd` args and insertion state.
1. Validate no-match, single-match, and unambiguous-prefix parity.
1. Add flow control to suppress built-in menu only on custom popup path.

## Out of Scope

1. Full popup rendering and interaction loop.
1. Filtering and command-line preview composition.

## Planned Changes

### Apply path

1. Register `_cbx-apply` via `zle -C`.
1. Read selected candidate id from internal row state.
1. Restore captured `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`.
1. Call `builtin compadd` with original args plus selected word.

### Parity controls

1. Keep built-in behavior for no matches and single match.
1. Preserve unambiguous common-prefix insertion behavior.
1. Apply menu suppression only when custom popup is actually entering.

## File-Level Plan

### Create

1. `lib/-cbx-apply.zsh`
1. `lib/-cbx-complete.zsh`

### Modify

1. `lib/cbx-enable.zsh` (register apply widget)
1. `lib/cbx-disable.zsh` (cleanup apply widget)
1. `lib/cbx-complete.zsh` (edge-case flow decisions)

## Scrut Tests To Add

1. Snapshot apply argument reconstruction from captured metadata.
1. Duplicate display and duplicate word cases map to correct id.
1. Verify no-match and single-match paths skip custom apply.

## zunit Tests To Add

1. Apply path inserts expected candidate for selected id.
1. Quoting and suffix handling match stock behavior.
1. Unambiguous prefix insertion still occurs before menu path.
1. Menu suppression toggles only in custom popup branch.

## Manual Checks

1. Duplicate labels and duplicate words insert correctly.
1. No-match warnings and single-match insertion match stock zsh behavior.

## Benchmark Plan

1. Measure apply-path overhead vs stock insertion for representative cases.
1. Track p95 for duplicate-heavy candidate lists.

## Acceptance Checklist

1. `make verify` passes.
1. Parity edge cases behave like stock zsh.
1. Apply-by-id is correct for duplicates and quoting-sensitive values.
1. Benchmarks stay within provisional apply-path budget.

## Rollback Triggers

1. Any insertion correctness mismatch against stock behavior.
1. Any regression in no-match or single-match semantics.
