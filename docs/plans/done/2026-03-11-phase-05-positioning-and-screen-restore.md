# Phase 05: Positioning, Placement, and Screen Restore

## Objective

Replace fixed placement with cursor-aware positioning and reliable screen
restoration in tmux, with safe fallback behavior.

## Depends On

1. `docs/plans/done/2026-03-11-phase-04-popup-mvp-interaction.md`

## Current Baseline

1. Phase 04 popup interaction is complete and currently renders with fixed
   relative placement from the cursor.
1. Rendering and erase use cursor save and restore sequences, not absolute row
   and column targeting.
1. No DSR probe is implemented yet, so placement does not adapt to pane edges.
1. No tmux row capture and restore exists yet; cleanup only erases compbox
   output.

## In Scope

1. Add DSR cursor probing and insertion-point anchoring.
1. Add above/below placement and right-edge clamping.
1. Add tmux capture-pane row save and restore.
1. Add robust fallback when DSR or restore preconditions fail.

## Out of Scope

1. Type-to-filter behavior.
1. Group dividers and scroll indicators.
1. Final styling lock-in.

## Planned Changes

### Positioning

1. Probe cursor row and column with DSR (`CSI 6 n`) before popup render.
1. Compute insertion anchor from cursor column and prefix display width.
1. Choose below or above placement based on available rows.
1. Clamp popup dimensions and horizontal placement to pane bounds.
1. If DSR or pane-geometry preconditions fail for an invocation, skip popup and
   route immediately to stock completion behavior.

### Screen lifecycle

1. Save rows behind popup with `tmux capture-pane -p -e` using explicit start
   and end row ranges.
1. Restore captured rows on accept, cancel, interrupt, resize, and early exit.
1. Integrate restore fallback into popup teardown and defensive disable-time
   cleanup.
1. If capture or restore fails for a case, fall back to prompt redraw.

## File-Level Plan

### Create

1. `lib/position.zsh`
1. `lib/screen.zsh`

### Modify

1. `compbox.plugin.zsh` (source Phase 05 files in eager load order)
1. `lib/cbx-complete.zsh` (DSR probe, placement decisions, and fallback routing)
1. `lib/render.zsh` (absolute row and column addressing)
1. `lib/keymap.zsh` (cleanup sequence integration)
1. `lib/cbx-disable.zsh` (defensive restore fallback cleanup)
1. `tests/helpers/setup.zsh` (register Phase 05 files and reset globals)
1. `tests/zunit/helpers/bootstrap.zsh` (register Phase 05 files and reset globals)
1. `tests/scrut/smoke.md` (source-count update)

## Scrut Tests To Add

1. Position calculation snapshots for below, above, and clamped placements.
1. DSR response parsing snapshots for normal, malformed, and fallback cases.
1. Overflow and near-edge cases for horizontal alignment.
1. Restore command composition snapshots for captured row ranges.

## zunit Tests To Add

1. DSR failure path returns to stock completion behavior for the same invocation.
1. Placement selection chooses below or above correctly from pane geometry.
1. Cleanup always restores saved screen state or prompt redraw fallback.
1. Ctrl-C and resize pathways run cleanup and do not insert selection.

## Manual Checks

1. Prompt near terminal bottom opens popup above.
1. Prompt near right edge clamps popup without corruption.
1. DSR malformed or unavailable cases fall back to stock completion cleanly.
1. Cancel and accept restore underlying screen region cleanly.

## Benchmark Plan

1. Measure DSR probe overhead per popup invocation.
1. Measure capture and restore timing by popup height and placement direction.
1. Track p95 for open and close lifecycle with medium candidate lists.

## Acceptance Checklist

1. `make verify` passes.
1. Placement behavior is correct for below, above, and clamped cases.
1. Screen restore is clean on normal, interrupt, and resize exits.
1. DSR and restore-precondition fallback is reliable and low-risk.

## Rollback Triggers

1. Frequent placement failures in target terminal and tmux setup.
1. Persistent restore artifacts in common manual scenarios.
