# Phase 01: Hook Lifecycle and Pass-Through Tab

## Objective

Install and remove plugin hooks safely while preserving stock completion
behavior.

## Depends On

1. `docs/plans/2026-03-11-phase-00-test-benchmark-foundation.md`

## In Scope

1. Add plugin entrypoint and source order.
1. Implement `cbx-enable` and `cbx-disable` lifecycle.
1. Bind `Tab` to a pass-through `cbx-complete` widget.
1. Preserve original widget behavior exactly.

## Out of Scope

1. `compadd` capture.
1. Popup rendering.
1. Filtering and preview behavior.

## Planned Changes

### Lifecycle

1. Create `compbox.plugin.zsh` with eager library loading.
1. Save original `Tab` widgets from `emacs` and `viins` keymaps.
1. Bind `^I` to `cbx-complete` in both keymaps.
1. Ensure disable restores all original bindings and helpers.
1. Make enable and disable idempotent.

### Pass-through widget

1. `cbx-complete` delegates to frozen original completion widget.
1. No interception or state mutation beyond lifecycle tracking.

## File-Level Plan

### Create

1. `compbox.plugin.zsh`
1. `lib/cbx-enable.zsh`
1. `lib/cbx-disable.zsh`
1. `lib/cbx-complete.zsh`

### Modify

1. `README.md` (usage section for enable/disable semantics)

## Scrut Tests To Add

1. Snapshot lifecycle state dump before enable, after enable, and after disable.
1. Verify pass-through call path markers in deterministic helper output.

## zunit Tests To Add

1. Enabling installs widget and key bindings in both keymaps.
1. Disabling restores prior bindings exactly.
1. Repeated enable calls do not duplicate hooks.
1. Repeated disable calls are safe no-ops.

## Manual Checks

1. In tmux + zsh, press `Tab` in common completion scenarios and verify stock
   behavior remains unchanged.

## Benchmark Plan

1. Compare `Tab` latency stock vs pass-through plugin (no capture, no render).
1. Record p50 and p95 overhead target near zero (noise-level only).

## Acceptance Checklist

1. `make verify` passes.
1. Manual pass-through behavior matches stock completion.
1. Benchmark report shows no meaningful regression vs baseline.

## Rollback Triggers

1. Any binding leak after disable.
1. Any measurable pass-through lag beyond baseline noise.
