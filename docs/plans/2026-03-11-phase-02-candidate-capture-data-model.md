# Phase 02: Candidate Capture and Data Model

## Objective

Capture completion candidates from `compadd` with stable ids while keeping stock
menu display active.

## Depends On

1. `docs/plans/2026-03-11-phase-01-hook-lifecycle-pass-through.md`

## In Scope

1. Add `compadd` wrapper and capture gate (`IN_CBX`).
1. Capture candidate display, insertion word, and metadata.
1. Pack captured candidates in a stable internal format.
1. Keep completion UI behavior unchanged.

## Out of Scope

1. Candidate application and insertion replay.
1. Suppression of built-in completion menu.
1. Popup rendering and navigation.

## Planned Changes

### Interception

1. Add internal `-cbx-compadd` implementation.
1. Pass through query-mode calls (`-O`, `-A`, `-D`) without capture.
1. Capture only inside plugin-controlled completion invocation.

### Data model

1. Define candidate record format with stable integer id.
1. Store metadata needed for later replay:
   - `word`, `PREFIX`, `SUFFIX`, `IPREFIX`, `ISUFFIX`
   - display and group fields
   - raw compadd args
1. Add unpack helpers for deterministic test visibility.

## File-Level Plan

### Create

1. `lib/-cbx-compadd.zsh`
1. `lib/-cbx-candidate-store.zsh`

### Modify

1. `lib/cbx-enable.zsh` (install wrapper)
1. `lib/cbx-disable.zsh` (remove wrapper)
1. `lib/cbx-complete.zsh` (set capture gate for completion path)

## Scrut Tests To Add

1. Snapshot packed candidate entries for simple and grouped inputs.
1. Verify ids are stable and monotonic within an invocation.
1. Verify query-mode `compadd` calls are not captured.
1. Verify duplicate display strings remain distinct by id.

## zunit Tests To Add

1. Wrapper uses `builtin compadd` for real completion bookkeeping.
1. Capture is disabled outside `IN_CBX` scope.
1. Metadata fields round-trip through pack and unpack helpers.

## Manual Checks

1. `ls <Tab>`, `git <Tab>`, and `cd <Tab>` still show stock completion UI.
1. Internal debug dump confirms candidate capture content is correct.

## Benchmark Plan

1. Measure overhead of capture path on multi-match completion.
1. Profile per-stage timing for parse, pack, and append operations.

## Acceptance Checklist

1. `make verify` passes.
1. Capture data includes required metadata for replay.
1. Stock completion visuals are unaffected.
1. Benchmark overhead remains within provisional budget.

## Rollback Triggers

1. Capture changes alter stock completion output or insertion semantics.
1. Candidate packing causes high latency for large completion sets.
