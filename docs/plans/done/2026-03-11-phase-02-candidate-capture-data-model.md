# Phase 02: Candidate Capture and Data Model

## Objective

Capture completion candidates from `compadd` with stable ids while keeping stock
menu display active.

## Depends On

1. `docs/plans/done/2026-03-11-phase-01-hook-lifecycle-pass-through.md`

## In Scope

1. Add `compadd` wrapper and capture gate (`IN_CBX`).
1. Capture candidate display, insertion word, and metadata.
1. Pack captured candidates in a stable internal format.
1. Keep completion UI behavior unchanged.
1. Integrate new capture files with Phase 01 source-order and reset harnesses.

## Out of Scope

1. Candidate application and insertion replay.
1. Suppression of built-in completion menu.
1. Popup rendering and navigation.

## Planned Changes

### Interception

1. Add shell-level `compadd` shim that delegates to internal `-cbx-compadd`.
1. Install and remove the shim in `cbx-enable` and `cbx-disable` while keeping lifecycle idempotent.
1. Pass through query-mode calls (`-O`, `-A`, `-D`) without capture.
1. Capture only inside plugin-controlled completion invocation (`IN_CBX` gate in `cbx-complete`).

### Data model

1. Define candidate record format with stable integer id (monotonic within an invocation).
1. Store metadata needed for later replay:
   - `word`, `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`
   - display and group fields
   - raw compadd args
1. Reset capture storage at the start of each completion invocation.
1. Add pack and unpack helpers for deterministic test visibility.

### Phase 01 integration

1. Keep `cbx-complete` keymap dispatch semantics unchanged outside capture gating.
1. Source Phase 02 files in `compbox.plugin.zsh` and both test harness source lists.
1. Add new capture globals to helper reset lists and disable cleanup.

## File-Level Plan

### Create

1. `lib/-cbx-compadd.zsh`
1. `lib/-cbx-candidate-store.zsh`
1. `tests/scrut/phase-02-candidate-capture.md`
1. `tests/zunit/phase-02-candidate-capture.zunit`

### Modify

1. `compbox.plugin.zsh` (source Phase 02 capture files in eager load order)
1. `lib/cbx-enable.zsh` (install wrapper)
1. `lib/cbx-disable.zsh` (remove wrapper and capture state)
1. `lib/cbx-complete.zsh` (set capture gate for completion path)
1. `tests/helpers/setup.zsh` (register Phase 02 files and reset globals)
1. `tests/zunit/helpers/bootstrap.zsh` (register Phase 02 files and reset globals)

## Scrut Tests To Add

1. Snapshot packed candidate entries for simple and grouped inputs.
1. Verify ids are stable and monotonic within an invocation.
1. Verify query-mode and outside-gate `compadd` calls are not captured.
1. Verify duplicate display strings remain distinct by id.
1. Verify capture state resets between independent completion invocations.

## zunit Tests To Add

1. Wrapper uses `builtin compadd` for real completion bookkeeping.
1. Capture is disabled outside `IN_CBX` scope.
1. Metadata fields round-trip through pack and unpack helpers.
1. Enable and disable lifecycle still cleans up wrapper state fully.

## Manual Checks

1. `ls <Tab>`, `git <Tab>`, and `cd <Tab>` still show stock completion UI.
1. Internal debug dump confirms candidate capture content is correct.
1. `cbx-disable` restores non-capture behavior with no wrapper residue.

## Benchmark Plan

1. Re-measure overhead on the existing stock versus pass-through completion scenario pair.
1. Profile per-stage timing for parse, pack, and append operations using `cbx_bench_*` hooks.

## Acceptance Checklist

1. `make verify` passes.
1. Capture data includes required metadata for replay.
1. Stock completion visuals and Phase 01 lifecycle semantics are unaffected.
1. Benchmark overhead remains within provisional budget.
1. Wrapper state is fully removed on disable.

## Rollback Triggers

1. Capture changes alter stock completion output or insertion semantics.
1. Wrapper state leaks outside plugin-controlled completion path.
1. Candidate packing causes high latency for large completion sets.
