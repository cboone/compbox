# Phase 08: Hardening, Compatibility, and Performance Lock-In

## Objective

Stabilize behavior under stress, validate compatibility with common zsh plugins,
and lock performance budgets before declaring v1 ready.

## Depends On

1. `docs/plans/2026-03-11-phase-07-grouping-scroll-and-status.md`

## In Scope

1. Harden cleanup on all exceptional exits.
1. Validate compatibility with common prompt and completion-related plugins.
1. Finalize benchmark budgets and regression thresholds.
1. Document known limitations and deferred items.

## Out of Scope

1. New functional features outside bug fixes and hardening.
1. New configuration surface area.

## Planned Changes

### Reliability hardening

1. Audit all exit paths for cursor, keymap, preview, and screen restore cleanup.
1. Ensure SIGINT behavior is deterministic and artifact-free.
1. Add guardrails for reentrancy and partial-state failures.

### Resize handling (SIGWINCH)

Phase 05 found that immediate popup dismiss on terminal resize is not
possible with the current rendering approach (CUP escape sequences to
`/dev/tty`). The popup is invisible to zle's refresh cycle, so zle
cannot redraw or clean it up on SIGWINCH. Signal handlers cannot call
zle builtins (`send-break`, `zle -U`), `zle-line-pre-redraw` does not
fire after SIGWINCH during `recursive-edit`, and reading from `/dev/tty`
inside a zle widget corrupts input state.

Current behavior: TRAPWINCH sets a flag; popup widgets check it on the
next keypress and call `send-break`. The popup dismisses on the first
keypress after resize.

To achieve immediate resize handling (like zsh's built-in `menu-select`),
the rendering architecture must change. Candidates, in order of
investigation priority:

1. **`tmux display-menu`**: Delegates rendering, navigation, resize, and
   cleanup to tmux. Perfect style match (the project goal is "styled to
   match tmux's native menus"). Main challenge: `display-menu` returns
   immediately; selection must be passed back via `wait-for`, pane
   options, or `send-keys`. Cancel detection also needs a solution.
1. **`POSTDISPLAY`**: Integrates with zle's refresh cycle (automatic
   resize redraw). Limitations: content always below the buffer,
   left-aligned, no arbitrary column positioning, no embedded ANSI
   escapes (colors via `region_highlight` only).
1. **`tmux display-popup`**: Runs a selector process inside a popup
   overlay. More flexible than `display-menu` but requires IPC for
   result passing and has the same synchronization challenges.

### Compatibility matrix

1. Validate with zsh-autosuggestions enabled.
1. Validate with zsh-syntax-highlighting enabled.
1. Validate with zsh-vi-mode enabled.
1. Document any known incompatibilities and workarounds.

### Performance lock-in

1. Establish final p50 and p95 budgets for key scenarios.
1. Add benchmark regression checks against saved baseline artifacts.
1. Fail CI on significant regressions where practical.

## File-Level Plan

### Modify

1. `lib/cbx-complete.zsh`
1. `lib/keymap.zsh`
1. `lib/screen.zsh`
1. `lib/ghost.zsh`
1. `scripts/bench/run.zsh`
1. `README.md`
1. `CONTRIBUTING.md`

## Scrut Tests To Add

1. Snapshot cleanup sequencing on accept, cancel, interrupt, and resize outcomes.
1. Snapshot benchmark report comparison output for regression detection.

## zunit Tests To Add

1. Signal-path cleanup tests for SIGINT and SIGWINCH.
1. Reentrancy tests for repeated popup invocations.
1. Compatibility-oriented state tests for preview and keymap interactions.

## Manual Checks

1. Rapid navigation and filtering produce no artifacts.
1. Compatibility matrix scenarios run without command-line corruption.
1. Long and wide-character candidate sets restore cleanly.

## Benchmark Plan

1. Run full scenario matrix with small, medium, and large fixtures.
1. Record and publish baseline plus current p50 and p95 values.
1. Define explicit fail thresholds for regression checks.

## Acceptance Checklist

1. `make verify` passes.
1. Full manual compatibility checklist passes.
1. Benchmark outputs meet final budgets.
1. Documentation reflects final behavior and known limitations.

## Rollback Triggers

1. Unresolved cleanup artifacts in routine workflows.
1. Repeatable compatibility breakages with core zsh ecosystem plugins.
1. Benchmark regressions beyond thresholds without acceptable mitigation.
