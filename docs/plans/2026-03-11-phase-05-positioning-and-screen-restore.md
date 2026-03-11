# Phase 05: Positioning, Placement, and Screen Restore

## Objective

Replace fixed placement with cursor-aware positioning and reliable screen
restoration in tmux, with safe fallback behavior.

## Depends On

1. `docs/plans/2026-03-11-phase-04-popup-mvp-interaction.md`

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

1. Compute insertion anchor from cursor column and prefix display width.
1. Choose below or above placement based on available rows.
1. Clamp popup dimensions and horizontal placement to terminal bounds.
1. If DSR fails for invocation, skip popup and defer to stock completion.

### Screen lifecycle

1. Save rows behind popup with `tmux capture-pane -p -e`.
1. Restore captured rows on accept, cancel, interrupt, and early exit.
1. If restore fails for a case, fall back to prompt redraw.

## File-Level Plan

### Create

1. `lib/position.zsh`
1. `lib/screen.zsh`

### Modify

1. `lib/cbx-complete.zsh` (positioning decisions and fallback routing)
1. `lib/render.zsh` (absolute row and column addressing)
1. `lib/keymap.zsh` (cleanup sequence integration)

## Scrut Tests To Add

1. Position calculation snapshots for below, above, and clamped placements.
1. Overflow and near-edge cases for horizontal alignment.
1. Restore command composition snapshots for captured row ranges.

## zunit Tests To Add

1. DSR failure path returns to stock completion behavior.
1. Cleanup always restores saved screen state or prompt redraw fallback.
1. Ctrl-C and resize pathways run cleanup and do not insert selection.

## Manual Checks

1. Prompt near terminal bottom opens popup above.
1. Prompt near right edge clamps popup without corruption.
1. Cancel and accept restore underlying screen region cleanly.

## Benchmark Plan

1. Measure DSR read overhead per popup invocation.
1. Measure capture and restore timing by popup height.
1. Track p95 for open and close lifecycle with medium candidate lists.

## Acceptance Checklist

1. `make verify` passes.
1. Placement behavior is correct for below, above, and clamped cases.
1. Screen restore is clean on normal and interrupt exits.
1. DSR failure fallback is reliable and low-risk.

## Rollback Triggers

1. Frequent placement failures in target terminal and tmux setup.
1. Persistent restore artifacts in common manual scenarios.
