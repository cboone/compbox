# Phase 03: Apply by Id and Completion Parity

## Objective

Replay insertion through zsh completion internals using selected candidate ids,
and lock parity for core completion edge cases.

## Depends On

1. `docs/plans/done/2026-03-11-phase-02-candidate-capture-data-model.md`

## In Scope

1. Add `_cbx-apply` completion widget and id-based lookup.
1. Capture enough per-candidate origin metadata to replay the exact source `compadd` call for that id.
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
1. Extend candidate records with source-call linkage so duplicate words across separate `compadd` calls remain replayable by id.
1. Resolve selected id to its originating raw-args entry.
1. Restore captured `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`.
1. Rebuild argv from captured raw args and call `builtin compadd` with original options plus selected word.

### Parity controls

1. Keep built-in behavior for no matches and single match.
1. Preserve unambiguous common-prefix insertion behavior.
1. Apply menu suppression only when custom popup is actually entering.

## File-Level Plan

### Create

1. `lib/-cbx-apply.zsh`
1. `lib/-cbx-complete.zsh`
1. `tests/scrut/phase-03-apply-by-id-and-parity.md`
1. `tests/zunit/phase-03-apply-by-id-and-parity.zunit`

### Modify

1. `compbox.plugin.zsh` (source new Phase 03 files)
1. `lib/-cbx-candidate-store.zsh` (pack and unpack source-call linkage fields)
1. `lib/-cbx-compadd.zsh` (capture source-call linkage metadata)
1. `lib/cbx-enable.zsh` (register apply widget)
1. `lib/cbx-disable.zsh` (cleanup apply widget)
1. `lib/cbx-complete.zsh` (edge-case flow decisions)
1. `tests/helpers/setup.zsh` (register Phase 03 files and reset globals)
1. `tests/zunit/helpers/bootstrap.zsh` (register Phase 03 files and reset globals)
1. `tests/scrut/smoke.md` (update source-count expectation)

## Scrut Tests To Add

1. Snapshot apply argument reconstruction from captured metadata.
1. Duplicate display and duplicate word cases map to correct id and originating raw-args entry.
1. Verify no-match and single-match paths skip custom apply.
1. Verify unambiguous-prefix insertion behavior remains stock before custom popup path.

## zunit Tests To Add

1. Apply path inserts expected candidate for selected id.
1. Selected id replay uses the correct originating `compadd` arg vector.
1. Quoting and suffix handling match stock behavior.
1. Unambiguous prefix insertion still occurs before menu path.
1. Menu suppression toggles only in custom popup branch.

## Manual Checks

1. Duplicate labels and duplicate words insert correctly.
1. Duplicate words emitted from separate `compadd` calls still insert the selected id.
1. No-match warnings and single-match insertion match stock zsh behavior.

## Benchmark Plan

1. Measure apply-path overhead vs stock insertion for representative cases.
1. Track p95 for duplicate-heavy candidate lists, including duplicates emitted by separate `compadd` calls.

## Acceptance Checklist

1. `make verify` passes.
1. Parity edge cases behave like stock zsh.
1. Apply-by-id is correct for duplicates and quoting-sensitive values.
1. Selected id replays the correct originating `compadd` arg vector when duplicate words span multiple calls.
1. Benchmarks stay within provisional apply-path budget.

## Rollback Triggers

1. Any insertion correctness mismatch against stock behavior.
1. Any selected-id replay that resolves to the wrong originating `compadd` call.
1. Any regression in no-match or single-match semantics.
