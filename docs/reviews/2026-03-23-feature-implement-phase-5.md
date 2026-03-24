## Branch Review: feature/implement-phase-5

Base: main (merge base: 7517373)
Commits: 26
Files changed: 29 (8 added, 20 modified, 1 deleted)
Reviewed through: b79f1c5

### Summary

This branch implements Phase 05 of the compbox plugin: cursor-aware popup
positioning via DSR probing, above/below placement with edge clamping, and
tmux-based screen save/restore. It also adds candidate filtering and
alphabetical sorting for popup rows, popup height clamping when the candidate
list exceeds available terminal space, and SIGWINCH-based resize handling that
dismisses the popup on the next keypress. The work is thorough and well-tested
with 56 new tests (27 scrut, 29 zunit) covering positioning, screen lifecycle,
fallback paths, and integration behavior. Benchmark infrastructure was expanded
with medium-candidate fixtures, DSR probe stubs for expect-based benchmarks,
recalibrated budgets, and a new `bench-smoke` make target.

### Changes by Area

#### Positioning (new)

DSR cursor probing (`CSI 6 n`), pane geometry detection via `LINES`/`COLUMNS`
with tmux fallback, popup dimension calculation from candidate rows, anchor
column computation from prefix width, and above/below placement with
right-edge clamping and minimum-3-row enforcement.

- `lib/position.zsh` (new, 243 lines)

#### Screen Lifecycle (new)

tmux `capture-pane -p -e` based screen save before popup render and CUP-based
restore after popup teardown, plus a `compose` helper for test snapshot
verification without writing to `/dev/tty`.

- `lib/screen.zsh` (new, 111 lines)

#### Completion Flow

DSR probe, pane geometry, popup dimensions, and placement computed before
render. Fallback to stock completion when any positioning precondition fails.
Popup rows truncated to visible count when placement clamps height. Screen
save before render, screen restore in the `always` block with resize
detection that skips stale CUP cleanup and falls back to `reset-prompt`.

- `lib/cbx-complete.zsh` (major rewrite, 150 lines)
- `lib/-cbx-complete.zsh` (candidate filtering and sorting in row projection)

#### Rendering

Render and erase functions gained dual-mode output: absolute CUP positioning
when placement globals are set, relative cursor movement when unset (backward
compatibility for tests). Width clamping for display text when popup width is
precomputed.

- `lib/render.zsh` (significant changes)

#### Resize Handling

TRAPWINCH sets a global flag; every popup widget checks it on the next
keypress and calls `send-break`. The `always` block detects geometry mismatch
(LINES/COLUMNS vs saved pane dimensions), skips stale CUP cleanup, and falls
back to `reset-prompt`. Architectural alternatives for immediate resize
handling documented in Phase 08 plan.

- `lib/cbx-complete.zsh` (TRAPWINCH save/restore and resize detection)
- `lib/keymap.zsh` (resize flag checks in all widget handlers)

#### Candidate Filtering and Sorting

Row projection now filters candidates against their captured PREFIX field,
using only the final path component for path completions (`${prefix##*/}`).
Popup rows sorted alphabetically (case-insensitive) by display text.

- `lib/-cbx-complete.zsh`
- `lib/-cbx-compadd.zsh` (minor)

#### Defensive Cleanup

Disable-time cleanup calls `screen-restore` if popup is still active. All
Phase 05 globals added to the unset list in `cbx-disable`.

- `lib/cbx-disable.zsh`

#### Plugin Bootstrap

Position and screen source files added to eager load order.

- `compbox.plugin.zsh`

#### Tests

27 scrut tests: DSR parsing (normal, malformed, fallback), placement (below,
above, clamped, overflow), anchor column, CUP render/erase, restore compose.

29 zunit tests: DSR parse, pane geometry, popup dimensions, placement
selection, anchor offset, CUP render/erase modes, screen restore compose,
DSR/placement failure fallback paths, screen save/restore lifecycle, height
clamping truncation, resize detection, and Phase 05 global cleanup.

Shared `cbx_stub_phase05_positioning()` helper extracted into zunit bootstrap,
replacing duplicated stub blocks in Phase 04 integration tests.

- `tests/scrut/phase-05-positioning-and-screen-restore.md` (new, 341 lines)
- `tests/zunit/phase-05-positioning-and-screen-restore.zunit` (new, 666 lines)
- `tests/zunit/helpers/bootstrap.zsh` (shared stub helper)
- `tests/helpers/setup.zsh` (Phase 05 sources and globals)
- `tests/zunit/phase-04-popup-mvp-interaction.zunit` (stub integration)
- `tests/scrut/smoke.md` (source count update)

#### Benchmarks

New medium-candidate fixtures (`popup-open-accept-medium`,
`stock-completion-multi-medium`) for 15-candidate popup overhead measurement.
DSR probe stubs in all popup benchmark fixtures to prevent expect deadlocks.
Recalibrated popup budgets for actual popup path overhead. New `bench-smoke`
make target for quick 10-iteration runs. Updated baseline data.

- `scripts/bench/fixtures/popup-open-accept-medium.zsh` (new)
- `scripts/bench/fixtures/stock-completion-multi-medium.zsh` (new)
- `scripts/bench/fixtures/popup-cancel.zsh` (DSR stub)
- `scripts/bench/fixtures/popup-navigate-accept.zsh` (DSR stub)
- `scripts/bench/fixtures/popup-open-accept.zsh` (DSR stub)
- `scripts/bench/run.zsh` (medium scenario wiring, `--smoke` flag)
- `benchmarks/baseline.json` (recaptured)
- `Makefile` (`bench-smoke` target)

#### Configuration and Documentation

- `cspell.json` (new dictionary entries)
- `scripts/check-zsh.zsh` (SC1027 and SC1094 exclusions)
- `docs/plans/2026-03-11-phase-08-hardening-compatibility-performance.md`
  (resize findings, deferred benchmark items)
- `docs/plans/done/2026-03-11-phase-05-positioning-and-screen-restore.md`
  (plan moved to done)

### File Inventory

**New files (8):**

- `docs/plans/done/2026-03-11-phase-05-positioning-and-screen-restore.md`
- `docs/reviews/2026-03-19-feature-implement-phase-5.md`
- `lib/position.zsh`
- `lib/screen.zsh`
- `scripts/bench/fixtures/popup-open-accept-medium.zsh`
- `scripts/bench/fixtures/stock-completion-multi-medium.zsh`
- `tests/scrut/phase-05-positioning-and-screen-restore.md`
- `tests/zunit/phase-05-positioning-and-screen-restore.zunit`

**Modified files (20):**

- `Makefile`
- `benchmarks/baseline.json`
- `compbox.plugin.zsh`
- `cspell.json`
- `docs/plans/2026-03-11-phase-08-hardening-compatibility-performance.md`
- `lib/-cbx-compadd.zsh`
- `lib/-cbx-complete.zsh`
- `lib/cbx-complete.zsh`
- `lib/cbx-disable.zsh`
- `lib/keymap.zsh`
- `lib/render.zsh`
- `scripts/bench/fixtures/popup-cancel.zsh`
- `scripts/bench/fixtures/popup-navigate-accept.zsh`
- `scripts/bench/fixtures/popup-open-accept.zsh`
- `scripts/bench/run.zsh`
- `scripts/check-zsh.zsh`
- `tests/helpers/setup.zsh`
- `tests/scrut/smoke.md`
- `tests/zunit/helpers/bootstrap.zsh`
- `tests/zunit/phase-04-popup-mvp-interaction.zunit`

**Deleted files (1):**

- `docs/plans/2026-03-11-phase-05-positioning-and-screen-restore.md`
  (moved to `done/`)

### Notable Changes

- **New dependencies on terminal capabilities**: DSR probe requires a terminal
  that responds to `CSI 6 n`. Screen save/restore requires tmux. Both have
  fallback paths.
- **ShellCheck exclusions**: SC1027 (zsh `<->` glob pattern) and SC1094
  (cascading parse errors from sourced zsh files) added to the exclusion list.
- **Benchmark budget recalibration**: Popup budgets increased significantly
  (e.g., `BUDGET_POPUP_OPEN_P50` from ~5ms to 255ms) after DSR stub fix
  exposed that benchmarks were previously exercising the stock fallback path
  instead of the actual popup path.
- **Resize handling deferred to Phase 08**: Immediate dismiss on resize is
  architecturally blocked by the current CUP rendering approach. Three
  candidate architectures documented for Phase 08.

### Plan Compliance

Plan: `docs/plans/done/2026-03-11-phase-05-positioning-and-screen-restore.md`

#### Compliance Verdict

**Good compliance.** All plan items are fully implemented. The branch delivers
everything the plan specified and adds valuable scope (candidate filtering,
sorting, height clamping, resize handling, medium benchmark fixtures) that was
necessary for a functional popup. Three benchmark items were intentionally
deferred to Phase 08, which is documented and reasonable.

#### Overall Progress

12/12 core items done (100%). 3 benchmark items deferred to Phase 08 with
documentation.

#### Positioning (all done)

- **Probe cursor row and column with DSR**: Done. `-cbx-dsr-probe` sends
  `CSI 6 n`, parses response with `-cbx-dsr-parse`. Input flush, per-read
  timeout (1s), and total deadline (2s) protect against stalls.
- **Compute insertion anchor from cursor column and prefix display width**:
  Done. `-cbx-popup-anchor-col` extracts prefix from candidate field 5,
  offsets cursor column, floors at 1.
- **Choose below or above placement based on available rows**: Done.
  `-cbx-popup-placement` compares rows above vs below cursor and picks
  the direction with more room.
- **Clamp popup dimensions and horizontal placement to pane bounds**: Done.
  Width clamped to `pane_w`, column clamped so popup does not extend past
  right edge, column floored at 1.
- **DSR/pane-geometry failure skips popup and routes to stock completion**:
  Done. Chain of `! -cbx-dsr-probe || ! -cbx-pane-geometry || ...` in
  `cbx-complete` falls through to stock completion rerun.

#### Screen Lifecycle (all done)

- **Save rows with `tmux capture-pane -p -e`**: Done. `-cbx-screen-save`
  captures rows behind popup using 0-based tmux coordinates.
- **Restore captured rows on accept, cancel, interrupt, resize, and early
  exit**: Done. `always` block in `cbx-complete` handles all paths. Resize
  skips restore and uses `reset-prompt` instead.
- **Integrate restore fallback into defensive disable-time cleanup**: Done.
  `cbx-disable` calls `-cbx-screen-restore` when popup is active.
- **Capture/restore failure falls back to prompt redraw**: Done.
  `reset-prompt` called when `screen-restore` returns failure.

#### File-Level Plan (all done)

- **Create `lib/position.zsh`**: Done.
- **Create `lib/screen.zsh`**: Done.
- **Modify `compbox.plugin.zsh`**: Done (source order).
- **Modify `lib/cbx-complete.zsh`**: Done (DSR, placement, fallback, screen).
- **Modify `lib/render.zsh`**: Done (CUP positioning, width clamping).
- **Modify `lib/keymap.zsh`**: Done (resize flag checks).
- **Modify `lib/cbx-disable.zsh`**: Done (screen restore, Phase 05 globals).
- **Modify `tests/helpers/setup.zsh`**: Done.
- **Modify `tests/zunit/helpers/bootstrap.zsh`**: Done.
- **Modify `tests/scrut/smoke.md`**: Done.

#### Tests (all done)

- **Scrut: position calculation snapshots**: Done (below, above, clamped).
- **Scrut: DSR parsing snapshots**: Done (normal, malformed, fallback).
- **Scrut: overflow and near-edge horizontal alignment**: Done.
- **Scrut: restore command composition snapshots**: Done.
- **zunit: DSR failure returns to stock completion**: Done.
- **zunit: placement selection**: Done.
- **zunit: cleanup restores saved screen or fallback**: Done.
- **zunit: Ctrl-C and resize pathways**: Done (resize detection test).

#### Benchmark Plan (partially done, deferred by design)

- **Measure DSR probe overhead per popup invocation**: Not measured
  independently. Deferred to Phase 08.
- **Measure capture and restore timing by popup height**: Not measured
  independently. Deferred to Phase 08.
- **Track p95 for open/close lifecycle with medium candidate lists**: Partially
  done. Medium-candidate fixtures exist and budget thresholds are set, but
  isolated p95 lifecycle tracking deferred to Phase 08.

#### Deviations

- **Scope additions (justified)**: Candidate filtering, alphabetical sorting,
  popup height clamping, and SIGWINCH resize handling were not in the plan but
  were necessary for a usable popup. Without filtering, unrelated candidates
  appeared. Without clamping, the popup failed silently when candidates
  exceeded available space. Resize handling was a natural extension of the
  screen lifecycle work. All additions are well-tested.
- **`lib/-cbx-complete.zsh` not in plan**: The plan did not mention this file,
  but candidate filtering and sorting logically belong in the flow-control
  module. Reasonable placement.
- **`lib/-cbx-compadd.zsh` not in plan**: Minor change (1 line), not a
  deviation of concern.
- **Benchmark items deferred**: The plan specified three benchmark measurements
  that were deferred to Phase 08 with documentation. Reasonable given Phase 08
  is specifically about performance lock-in.

#### Fidelity Concerns

None. The implementation matches the plan's intent in both letter and spirit.
The DSR probe design, placement algorithm, screen save/restore approach, and
fallback routing all follow the plan's described approach precisely. The
additional scope (filtering, sorting, clamping, resize) strengthens the
implementation without contradicting the plan.

### Code Quality Assessment

#### Overall Quality

This code is ready to merge. The implementation is clean, well-structured, and
thoroughly tested. The zsh code follows project conventions consistently. Error
handling is thoughtful, with clear fallback chains and defensive cleanup at
every exit path.

#### Strengths

- **Robust fallback design**: Every positioning and screen operation has a
  clear failure path that degrades gracefully to stock completion or prompt
  redraw. No silent failures.
- **Thorough testing**: 56 new tests cover all code paths including edge cases
  (zero geometry, narrow panes, malformed DSR, empty candidates, resize during
  popup). The zunit integration tests exercise the full `cbx-complete` flow
  with stubbed externals.
- **Clean separation of concerns**: Position calculation, screen management,
  rendering, and completion flow are in separate files with well-defined
  interfaces (global variables as the data contract).
- **Consistent coding style**: Every function uses `emulate -L zsh` with
  `NO_UNSET PIPE_FAIL`. Naming follows the `-cbx-` prefix convention. Tab
  field separation is consistent.
- **Benchmark infrastructure**: DSR stub discovery and fix was particularly
  valuable. The benchmarks were silently testing the wrong code path, and this
  was caught and corrected with budget recalibration.
- **Shared test helper**: The `cbx_stub_phase05_positioning()` extraction
  eliminates 50+ lines of duplication across Phase 04 tests.
- **SIGWINCH investigation thoroughness**: The commit message for `e2748f8`
  documents every approach that was tried and why each failed, providing
  valuable context for Phase 08.

#### Issues to Address

No blocking issues found.

#### Suggestions

- **DSR input flush loop**: The `while read -t 0` flush loop at the top of
  `-cbx-dsr-probe` has no iteration cap. In pathological cases (rapid input
  buffered in the tty), this could spin. A counter limit (similar to the
  20-char cap on the response read) would add safety. Low risk in practice.
- **Screen restore `local -i` in loop**: In `-cbx-screen-restore` and
  `-cbx-screen-restore-compose`, `local -i row` is declared inside the `for`
  loop body. In zsh this is fine (locals in the same function scope are
  reused), but declaring it before the loop would be marginally clearer.
- **Popup budget values**: The popup P50 budgets (255ms, 260ms) include ~200ms
  of expect `after 200` sleep from the fixture, making the actual overhead
  budget ~55-60ms. This is documented in the comment but could be confusing to
  future readers. Consider naming the constants to reflect this (e.g.,
  `BUDGET_POPUP_OPEN_TOTAL_P50`) or adding the breakdown in the constant
  comment.
- **`-cbx-popup-rows-from-candidates` sort**: The sort uses a field-swap
  approach (swap id and display, sort, swap back). This works correctly but
  is O(n) extra allocations. For the expected candidate counts (< 100), this
  is negligible. If Phase 07 introduces scrolling with large lists, this
  could be revisited.
