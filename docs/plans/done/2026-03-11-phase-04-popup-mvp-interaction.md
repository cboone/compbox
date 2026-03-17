# Phase 04: Popup MVP Interaction Loop

## Objective

Ship a minimal popup interaction loop with deterministic navigation and
accept/cancel behavior, without locking final style details.

## Depends On

1. `docs/plans/done/2026-03-11-phase-03-apply-by-id-and-parity.md`

## Current Baseline

1. Candidate capture and apply-by-id replay are implemented and covered by
   Phase 03 tests.
1. Popup eligibility is already gated by `-cbx-complete-should-popup` using
   `_CBX_NMATCHES` parity rules.
1. `_CBX_POPUP_ACTIVE` is currently only a flag, no render or keymap loop
   exists yet.
1. Candidate records are escaped 9-field entries and must continue to be
   decoded through existing helpers.

## In Scope

1. Render a minimal single-column popup frame and candidate list.
1. Add recursive-edit with temporary popup keymap.
1. Support cyclical navigation keys:
   - next: `Down`, `Tab`
   - previous: `Up`, `Shift-Tab`
1. Support `Enter` accept and `Escape` cancel.
1. Route accepted selection to existing `_cbx-apply` replay path.
1. Integrate new phase files with plugin bootstrap and test harness source
   lists.

## Out of Scope

1. Final border and highlight styling decisions.
1. DSR-based precise positioning.
1. tmux capture-pane save and restore.
1. Filtering and command-line preview composition.

## Planned Changes

### Popup state and rows

1. Introduce MVP popup runtime state for rows, selected index, and exit action.
1. Project captured candidates into a selectable visible-row list for this
   phase.
1. Keep first version simple, with one row kind (candidate) in this phase.
1. Decode packed candidate fields through existing unescape helpers to preserve
   delimiter and SOH safety from Phase 03 hardening.

### Rendering MVP

1. Draw popup from buffered ANSI output in one print pass.
1. Render selected row state and basic update path.
1. Use fixed placement for MVP to reduce interaction risk.

### Accept and cancel handoff

1. Accept sets `_CBX_APPLY_ID` from selected row id and invokes
   `zle _cbx-apply`.
1. Cancel exits popup without calling apply and without mutating the command
   line.
1. Preserve stock behavior for no-match and single-match paths.

### Keymap loop

1. Create temporary `_cbx_menu` keymap.
1. Enter `zle recursive-edit`.
1. Exit via `zle send-break` on accept and cancel.
1. Guarantee keymap teardown and cursor restore on exit.
1. Guarantee teardown on all exits, including interrupt-driven exits.

### Phase integration

1. Source new Phase 04 files in plugin load order.
1. Register new files and popup globals in scrut and zunit helper bootstrap and
   reset lists.
1. Ensure `cbx-disable` cleanup removes any popup state residue.

## File-Level Plan

### Create

1. `lib/render.zsh`
1. `lib/navigate.zsh`
1. `lib/keymap.zsh`

### Modify

1. `compbox.plugin.zsh` (source Phase 04 files in eager load order)
1. `lib/cbx-complete.zsh` (open popup, run loop, accept/cancel outcomes)
1. `lib/-cbx-complete.zsh` (connect captured candidates to visible rows)
1. `lib/cbx-disable.zsh` (defensive popup cleanup)
1. `tests/helpers/setup.zsh` (register Phase 04 files and reset globals)
1. `tests/zunit/helpers/bootstrap.zsh` (register Phase 04 files and reset globals)

## Scrut Tests To Add

1. Snapshot visible-row projection from captured candidate records.
1. Snapshot minimal popup frame output for small candidate sets.
1. Snapshot selection update output for next and previous movement.
1. Snapshot wrap behavior at top and bottom boundaries.
1. Snapshot accept and cancel state transitions, including apply-id handoff on
   accept only.
1. Snapshot no-match and single-match paths staying on stock behavior.

## zunit Tests To Add

1. Navigation helpers wrap deterministically for next and previous movement.
1. Key bindings map to cyclical next and previous actions.
1. Enter sets accept action, captures selected id, and exits recursive edit.
1. Escape sets cancel action and exits recursive edit without apply-id handoff.
1. Accept path invokes `_cbx-apply`, cancel path does not.
1. Temporary keymap and popup state are always removed on exit.

## Manual Checks

1. Open popup on multi-match completion and navigate with all four movement keys.
1. Confirm wrap behavior at top and bottom.
1. Confirm accept inserts selection and cancel leaves line unchanged.
1. Confirm no-match and single-match behavior still matches stock zsh.

## Benchmark Plan

1. Measure open-popup latency for small and medium candidate counts.
1. Measure navigation redraw latency at p95.
1. Measure accept and cancel exit latency impact versus pass-through baseline.

## Acceptance Checklist

1. `make verify` passes.
1. No-match and single-match parity remains stock.
1. Popup opens, navigates, accepts, and cancels correctly.
1. Cyclical navigation behavior is consistent across key variants.
1. Recursive-edit lifecycle leaves no keymap or popup state residue.
1. MVP rendering overhead stays within provisional interactive budget.

## Rollback Triggers

1. Recursive-edit lifecycle leaks keymap or leaves cursor hidden.
1. Accept or cancel paths mutate command line unexpectedly.
1. Accept path no longer replays the selected id through `_cbx-apply`.
