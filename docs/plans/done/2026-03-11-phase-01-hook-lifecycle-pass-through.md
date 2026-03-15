# Phase 01: Hook Lifecycle and Pass-Through Tab

## Objective

Install and remove plugin hooks safely while preserving stock completion
behavior.

## Depends On

1. `docs/plans/done/2026-03-11-phase-00-test-benchmark-foundation.md`

## In Scope

1. Add plugin entrypoint and source order.
1. Implement `cbx-enable` and `cbx-disable` lifecycle.
1. Bind `Tab` to a pass-through `cbx-complete` widget.
1. Preserve original widget behavior exactly.
1. Integrate lifecycle code with Phase 00 test and benchmark harnesses.

## Out of Scope

1. `compadd` capture.
1. Popup rendering.
1. Filtering and preview behavior.

## Planned Changes

### Lifecycle

1. Create `compbox.plugin.zsh` with eager library loading.
1. On plugin source, call `cbx-enable` once (guarded against repeated sourcing).
1. Save original `Tab` widgets from `emacs` and `viins` keymaps.
1. Bind `^I` to `cbx-complete` in both keymaps.
1. Ensure disable restores all original bindings and helpers.
1. Make enable and disable idempotent.

### Pass-through widget

1. `cbx-complete` delegates to frozen original completion widget.
1. No interception or state mutation beyond lifecycle tracking.

### Harness integration

1. Register new Phase 01 plugin files in test helper source lists.
1. Ensure helper reset clears any lifecycle globals created in this phase.
1. Add a benchmark fixture and scenario for pass-through `Tab` execution.

## File-Level Plan

### Create

1. `compbox.plugin.zsh`
1. `lib/cbx-enable.zsh`
1. `lib/cbx-disable.zsh`
1. `lib/cbx-complete.zsh`
1. `tests/scrut/phase-01-lifecycle.md`
1. `tests/zunit/phase-01-lifecycle.zunit`
1. `scripts/bench/fixtures/pass-through-tab.zsh`

### Modify

1. `README.md` (usage section for enable/disable semantics)
1. `tests/helpers/setup.zsh` (add Phase 01 plugin sources and reset state)
1. `tests/zunit/helpers/bootstrap.zsh` (add Phase 01 plugin sources and reset state)
1. `scripts/bench/run.zsh` (add pass-through `Tab` benchmark scenario)

## Scrut Tests To Add

1. `tests/scrut/phase-01-lifecycle.md`: snapshot lifecycle state before enable, after enable, and after disable.
1. `tests/scrut/phase-01-lifecycle.md`: verify repeated enable and disable calls are idempotent.
1. `tests/scrut/phase-01-lifecycle.md`: verify pass-through call path markers in deterministic helper output.

## zunit Tests To Add

1. `tests/zunit/phase-01-lifecycle.zunit`: enabling installs widget and key bindings in both keymaps.
1. `tests/zunit/phase-01-lifecycle.zunit`: disabling restores prior bindings exactly.
1. `tests/zunit/phase-01-lifecycle.zunit`: repeated enable calls do not duplicate hooks.
1. `tests/zunit/phase-01-lifecycle.zunit`: repeated disable calls are safe no-ops.
1. `tests/zunit/phase-01-lifecycle.zunit`: sourcing `compbox.plugin.zsh` auto-enables once without duplicate installs.

## Manual Checks

1. In tmux + zsh, press `Tab` in common completion scenarios and verify stock
   behavior remains unchanged.

## Benchmark Plan

1. Add pass-through fixture `scripts/bench/fixtures/pass-through-tab.zsh` with deterministic completion workload.
1. Add a pass-through scenario to `scripts/bench/run.zsh` for smoke and baseline modes.
1. Compare p50 and p95 latency for stock completion versus pass-through `Tab` and keep overhead near noise-level.

## Acceptance Checklist

1. `make verify` passes.
1. Scrut and zunit lifecycle tests in dedicated Phase 01 files pass.
1. Manual pass-through behavior matches stock completion.
1. Test helper source lists include all new Phase 01 plugin files.
1. Benchmark report shows no meaningful regression vs baseline.

## Rollback Triggers

1. Any binding leak after disable.
1. Any measurable pass-through lag beyond baseline noise.
