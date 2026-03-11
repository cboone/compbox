# Rebuild Compbox in Test-First Phases

## Context

The first implementation attempt of the completion popup plugin did not land in a
stable way. This plan resets the effort into small, testable phases with clear
gates, strong rollback boundaries, and early performance tracking.

The prior design document remains the feature source of truth for intent:

- `docs/plans/done/2026-03-07-design-completion-popup-plugin.md`

## Goals

1. Ship value incrementally with each phase independently testable.
1. Add automated testing from the very first phase using both Scrut and zunit.
1. Reuse the check, lint, and format mechanisms from the `check-zsh` workflow.
1. Preserve zsh completion correctness by reusing compsys and `compadd` replay.
1. Keep prompt interaction responsive, with measurable performance budgets.
1. Defer style details until dedicated UI phases so we can iterate intentionally.

## Non-Goals for This Plan

1. Lock down final visual styling details now.
1. Add non-tmux support in v1.
1. Add user configuration in v1.
1. Build multi-column layout in v1.

## Confirmed Interaction Decisions (Current)

1. Completion parity targets remain stock zsh semantics for no-match, single
   match, and unambiguous common-prefix insertion behavior.
1. Navigation keys all cycle through selectable rows:
   - `Down` and `Tab`: next selectable row with wrap
   - `Up` and `Shift-Tab`: previous selectable row with wrap
1. Filtering model for v1 is prefix matching (not substring matching).
1. Filter visibility model for v1:
   - real command line buffer remains unchanged while popup is open
   - command-line preview shows typed filter text in regular style
   - selected candidate remainder is shown as dim ghost text
   - both are rendered through preview state and restored on popup exit
1. Styling specifics are deferred to UI phases, where alternatives can be tested
   before committing to final choices.

## Quality Strategy From Day 0

### Scrut test role

Scrut verifies deterministic behavior and snapshots for:

1. Candidate packing and row generation.
1. Positioning and geometry calculations.
1. Rendering buffer output for frame and row content logic.
1. Filtering transformations and status text composition.

### zunit test role

zunit verifies zsh-native semantics and stateful widget behavior for:

1. Enable/disable lifecycle and key binding restoration.
1. Hook installation and teardown correctness.
1. `compadd` interception and apply-by-id replay behavior.
1. Keymap lifecycle during recursive edit and cleanup paths.
1. Signal and cancellation cleanup behavior where feasible.

### Manual test role

Manual checks cover interactive terminal behaviors that are not yet fully stable
to assert in CI snapshots (for example visual smoothness and redraw under rapid
navigation).

## Zsh Check, Lint, and Format Pipeline

Use the same mechanism stack as `check-zsh`, applied pragmatically to this
plugin codebase.

### Tool order

1. `zsh -n <file>` (syntax parse check).
1. `zsh -c 'zcompile "$1"' -- <file>` (compile check), then remove `<file>.zwc`.
1. `shellcheck --shell=zsh <file>` (static analysis with zsh-aware filtering).
1. `checkbashisms <file>` (advisory for accidental bash-only patterns).
1. `shellharden --check <file>` (advisory safety suggestions).
1. `zsh -c 'emulate -L zsh; setopt warn_create_global warn_nested_var; source <file>'` (scoping warnings where safe to source).
1. `shfmt -ln zsh -d <file>` (primary formatter check).
1. `beautysh --check-only <file>` (secondary formatter check/fallback).

### Blocking vs advisory policy

1. Blockers by default: `zsh -n`, `zcompile`, and formatter drift where parser
   support is available.
1. `shellcheck` is blocking after filtering known zsh false positives.
1. Advisory by default: `checkbashisms`, `shellharden`, and setopt scope
   warnings (unless a warning is clearly a correctness bug).
1. If `shfmt` cannot parse a zsh construct, treat that parse failure as
   informational for that file and rely on `beautysh`.

### Fix workflow

1. Auto-fix format issues in this order: `shfmt -ln zsh -w <file>` then
   `beautysh <file>`.
1. Re-run `zsh -n` immediately after format fixes to verify no syntax regression.
1. Re-run all enabled checks before marking a phase complete.

### Automation integration

1. Add phase-0 tooling targets for repeatable local execution (for example
   `make check-zsh`, `make format-zsh`, `make verify`).
1. Run the same zsh quality pipeline in CI alongside Scrut and zunit.
1. Keep command order consistent between local and CI to reduce drift.

## Performance and Benchmarking Strategy

Prompt latency is a first-order requirement, not a late-stage polish item.

### Benchmark objectives

1. Measure baseline stock completion latency before behavior changes.
1. Track plugin overhead per phase against baseline.
1. Catch regressions early with repeatable benchmark fixtures.

### Benchmark scenarios

1. No matches.
1. Single match.
1. Multi-match popup open.
1. Navigation keypress redraw.
1. Filter keypress update.
1. Accept and cancel exit paths.
1. Candidate scales (small, medium, large sets).

### Measurement approach

1. Add lightweight internal timing hooks around top-level and stage-level paths
   (capture, transform, render, update, cleanup).
1. Record timings with `EPOCHREALTIME` in shell-native format.
1. Provide a repeatable benchmark entrypoint (`make bench`) that runs scenarios
   multiple times and reports p50/p95.
1. Keep benchmark mode opt-in with an environment flag so normal usage has no
   profiler overhead.

### Regression policy

1. Establish initial budgets after first baseline collection.
1. Treat significant p95 regressions as phase blockers unless the phase explicitly
   redefines the expected cost profile.
1. Track benchmark history in versioned artifacts so trend changes are visible.

## Phase Roadmap (High Level)

### Phase 0: Test and benchmark foundation

Set up Scrut and zunit harnesses, shared fixtures, benchmark scaffolding, and
the zsh check/lint/format pipeline with local + CI entrypoints.

### Phase 1: Hook lifecycle with pass-through behavior

Implement plugin enable/disable and key binding interception while preserving
stock completion behavior.

### Phase 2: Candidate capture and stable data model

Implement `compadd` capture path, stable candidate ids, and metadata packing.

### Phase 3: Apply-by-id insertion and parity edge cases

Implement replay insertion by candidate id and validate no-match, single-match,
and unambiguous-prefix parity behavior.

### Phase 4: Popup MVP interaction loop

Implement minimal popup rendering, selection movement, accept/cancel flows, and
recursive-edit lifecycle without final visual decisions.

### Phase 5: Positioning, placement, and tmux restore

Implement DSR-based placement, above/below logic, overflow clamping, and tmux
screen region save/restore with robust fallback behavior.

### Phase 6: Prefix filtering and command-line preview composition

Implement prefix filtering and merged command-line preview model:

1. typed filter text in regular style
1. selected candidate remainder in dim style
1. strict preview state restore on all exits

### Phase 7: Grouping, scrolling, and status polish

Implement divider rows, viewport scrolling, and status information for candidate
position and filter state.

### Phase 8: Hardening, compatibility, and performance lock-in

Stress test against common zsh plugins, handle resize and interrupts cleanly,
finalize performance budgets, and document remaining deferred work.

## Cross-Phase Definition of Done

A phase is complete only when all are true:

1. Phase scope is implemented with no unresolved critical bugs.
1. Zsh check/lint/format pipeline passes for files touched in the phase.
1. Scrut tests for new deterministic behavior are added and passing.
1. zunit tests for new widget and shell semantics are added and passing.
1. Benchmark scenarios for touched paths are recorded and within allowed budget.
1. Manual checks for the phase checklist pass in tmux + zsh target environment.
1. Documentation is updated to reflect current behavior and known limitations.

## Deliverables After This High-Level Plan

Next, draft phase-specific plans that include:

1. Exact scope boundaries and out-of-scope list.
1. File-level change map.
1. Scrut and zunit test cases to add in that phase.
1. Benchmark updates and expected budget impact.
1. Acceptance checklist and rollback trigger conditions.
