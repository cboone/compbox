## Branch Review: feature/implement-phase-4

Base: main (merge base: 63143db)
Commits: 15
Files changed: 25 (12 added, 11 modified, 1 deleted, 1 renamed)
Reviewed through: e36f511

### Summary

This branch implements Phase 04 of the compbox plugin: a minimal popup interaction loop with deterministic navigation, accept/cancel behavior, and buffered ANSI rendering. The popup activates on multi-match completions, provides cyclical Up/Down navigation with keyboard accept (Enter) and cancel (Escape/Ctrl-C/Ctrl-G), routes accepted selections through the existing `_cbx-apply` replay path, and guarantees keymap/cursor cleanup via zsh `always` blocks. A subsequent set of commits adds four expect-based benchmark fixtures for popup latency measurement, integrated into the benchmark runner with popup-to-popup delta reporting and budget thresholds.

### Changes by Area

#### Popup Core (lib/)

Three new library files implement the popup interaction loop:

- `lib/navigate.zsh`: Cyclical next/prev selection movement over `_CBX_POPUP_ROWS`.
- `lib/render.zsh`: Buffered ANSI popup frame builder with box-drawing borders, reverse-video highlight for the selected row, and cursor save/restore. Paired erase function clears rendered lines.
- `lib/keymap.zsh`: Temporary `_cbx_menu` keymap with widget handlers for next, prev, accept, cancel, and noop. Binds Down/Tab for next, Up/Shift-Tab for prev, Enter (both `^M` and `^J`) for accept, Escape/Ctrl-C/Ctrl-G for cancel, and Left/Right arrows to noop to prevent accidental escape-sequence cancel.

Files: `lib/navigate.zsh`, `lib/render.zsh`, `lib/keymap.zsh`

#### Completion Flow (lib/)

Modified to connect popup to the completion pipeline:

- `lib/cbx-complete.zsh`: Full popup interaction loop using `recursive-edit` with buffer save/restore, `KEYTIMEOUT=1` for instant Escape, and `{..} always {..}` for guaranteed cleanup. Dispatches accept to `_cbx-apply`.
- `lib/-cbx-complete.zsh`: Added `-cbx-popup-rows-from-candidates` to project captured candidates into id+display row pairs. Added `-cbx-complete-should-popup` (already existed, but row projection is new).
- `lib/-cbx-compadd.zsh`: Suppresses `compstate[insert]` and `compstate[list]` for multi-match so the popup handles insertion instead of stock completion.

Files: `lib/cbx-complete.zsh`, `lib/-cbx-complete.zsh`, `lib/-cbx-compadd.zsh`

#### Plugin Bootstrap and Cleanup (lib/, compbox.plugin.zsh)

- `compbox.plugin.zsh`: Sources `navigate.zsh`, `render.zsh`, and `keymap.zsh` in load order.
- `lib/cbx-disable.zsh`: Defensive popup cleanup on disable: destroys keymap, erases popup, shows cursor, unsets four new popup globals.

Files: `compbox.plugin.zsh`, `lib/cbx-disable.zsh`

#### Tests

- `tests/scrut/phase-04-popup-mvp-interaction.md`: 15 scrut snapshot tests covering row projection, render frame structure, highlight selection, navigation wrap, accept/cancel state, erase buffer, and no-match/single-match popup skip.
- `tests/zunit/phase-04-popup-mvp-interaction.zunit`: 22 zunit lifecycle tests covering row count/field extraction, display labels from `-d` array, cyclical navigation (including single-element edge case), render buffer properties, erase sequences, keymap create/destroy/bindings, accept handoff, plugin bootstrap integration, and disable cleanup.
- `tests/helpers/setup.zsh`: Registers Phase 04 source files and four new popup globals in reset lists.
- `tests/zunit/helpers/bootstrap.zsh`: Same registrations for zunit bootstrap.
- `tests/scrut/smoke.md`: Updated source count from 11 to 14.

Files: `tests/scrut/phase-04-popup-mvp-interaction.md`, `tests/zunit/phase-04-popup-mvp-interaction.zunit`, `tests/helpers/setup.zsh`, `tests/zunit/helpers/bootstrap.zsh`, `tests/scrut/smoke.md`

#### Benchmarks

Four new expect-based benchmark fixtures and runner integration:

- `scripts/bench/fixtures/stock-completion-multi.zsh`: Stock multi-match baseline (no plugin).
- `scripts/bench/fixtures/popup-open-accept.zsh`: Open popup, accept first candidate.
- `scripts/bench/fixtures/popup-navigate-accept.zsh`: Open, navigate down twice, accept.
- `scripts/bench/fixtures/popup-cancel.zsh`: Open popup, cancel with Ctrl-G.
- `scripts/bench/run.zsh`: New popup budget thresholds, `require_fixtures()` updated, popup scenarios in all modes, popup overhead delta reporting section.
- `scripts/bench/fixtures/pass-through-tab.zsh`: Changed from multi-match to single-match prefix to avoid hanging on `recursive-edit`.
- `scripts/bench/fixtures/stock-completion.zsh`: Same single-match change for consistent delta.
- `benchmarks/baseline.json`: Updated with new popup scenario data.

Files: `scripts/bench/fixtures/popup-*.zsh`, `scripts/bench/fixtures/stock-completion-multi.zsh`, `scripts/bench/run.zsh`, `scripts/bench/fixtures/pass-through-tab.zsh`, `scripts/bench/fixtures/stock-completion.zsh`, `benchmarks/baseline.json`

#### Configuration

- `scripts/check-zsh.zsh`: Added SC1046, SC1047, SC1141 to ShellCheck exclusions for zsh `always` blocks.

Files: `scripts/check-zsh.zsh`

#### Documentation

- `docs/plans/done/2026-03-11-phase-04-popup-mvp-interaction.md`: Plan moved from active to done.
- `docs/plans/done/2026-03-17-popup-benchmark-fixtures.md`: Benchmark fixture plan (completed).

Files: `docs/plans/done/2026-03-11-phase-04-popup-mvp-interaction.md`, `docs/plans/done/2026-03-17-popup-benchmark-fixtures.md`

### File Inventory

**New files (12):**

- `lib/navigate.zsh`
- `lib/render.zsh`
- `lib/keymap.zsh`
- `tests/scrut/phase-04-popup-mvp-interaction.md`
- `tests/zunit/phase-04-popup-mvp-interaction.zunit`
- `scripts/bench/fixtures/popup-open-accept.zsh`
- `scripts/bench/fixtures/popup-navigate-accept.zsh`
- `scripts/bench/fixtures/popup-cancel.zsh`
- `scripts/bench/fixtures/stock-completion-multi.zsh`
- `docs/plans/done/2026-03-11-phase-04-popup-mvp-interaction.md`
- `docs/plans/done/2026-03-17-popup-benchmark-fixtures.md`

**Modified files (11):**

- `compbox.plugin.zsh`
- `lib/cbx-complete.zsh`
- `lib/-cbx-complete.zsh`
- `lib/-cbx-compadd.zsh`
- `lib/cbx-disable.zsh`
- `tests/helpers/setup.zsh`
- `tests/zunit/helpers/bootstrap.zsh`
- `tests/scrut/smoke.md`
- `scripts/bench/run.zsh`
- `scripts/bench/fixtures/pass-through-tab.zsh`
- `scripts/bench/fixtures/stock-completion.zsh`
- `scripts/check-zsh.zsh`
- `benchmarks/baseline.json`

**Deleted files (1):**

- `docs/plans/2026-03-11-phase-04-popup-mvp-interaction.md` (moved to done/)

**Renamed files (1):**

- `scripts/bench/fixtures/pass-through-tab.zsh` -> `scripts/bench/fixtures/stock-completion-multi.zsh` (copy with modifications)

### Notable Changes

- **New ShellCheck exclusions**: SC1046, SC1047, SC1141 added for zsh `always` blocks. These are legitimate false positives from bash-mode parsing of zsh-specific syntax.
- **Existing fixture behavior change**: `pass-through-tab.zsh` and `stock-completion.zsh` switched from multi-match (`al` prefix, 2 hits) to single-match (`bet` prefix, 1 hit) to prevent hanging on `recursive-edit`. This is a necessary adaptation: the popup now blocks on multi-match.
- **Baseline benchmark data**: `benchmarks/baseline.json` grew from ~60 lines to ~2537 lines with the addition of popup scenario timing data.

### Plan Compliance

**Plan**: `docs/plans/done/2026-03-11-phase-04-popup-mvp-interaction.md`

**Compliance verdict**: Strong compliance. All planned items are implemented. The plan's intent is faithfully executed with no meaningful deviations.

**Overall progress**: 22/22 items done (100%)

#### Popup state and rows (4/4 done)

- [x] Introduce MVP popup runtime state for rows, selected index, and exit action. `_CBX_POPUP_ROWS`, `_CBX_POPUP_SELECTED`, `_CBX_POPUP_ACTION` in `cbx-complete.zsh`.
- [x] Project captured candidates into a selectable visible-row list. `-cbx-popup-rows-from-candidates` in `-cbx-complete.zsh`.
- [x] Keep first version simple, with one row kind (candidate). Only candidate rows are projected.
- [x] Decode packed candidate fields through existing unescape helpers. `-cbx-candidate-unescape-field` called in the projection loop.

#### Rendering MVP (3/3 done)

- [x] Draw popup from buffered ANSI output in one print pass. `-cbx-popup-render-buffer` builds full ANSI string in `REPLY`, `-cbx-popup-render` writes it in one `print -n`.
- [x] Render selected row state and basic update path. Reverse-video (`\e[7m`) highlight on the selected row, re-rendered on each navigation keystroke.
- [x] Use fixed placement for MVP to reduce interaction risk. Popup renders at cursor position with save/restore, no DSR positioning.

#### Accept and cancel handoff (3/3 done)

- [x] Accept sets `_CBX_APPLY_ID` from selected row id and invokes `zle _cbx-apply`. Implemented in `-cbx-popup-accept-widget` and the dispatch in `cbx-complete.zsh`.
- [x] Cancel exits popup without calling apply and without mutating the command line. Buffer save/restore in `cbx-complete.zsh`, cancel widget only sets action.
- [x] Preserve stock behavior for no-match and single-match paths. `-cbx-complete-should-popup` returns 1 for nmatches <= 1; `compstate[insert/list]` suppression only for nmatches > 1.

#### Keymap loop (4/4 done)

- [x] Create temporary `_cbx_menu` keymap. `-cbx-popup-keymap-create` in `keymap.zsh`.
- [x] Enter `zle recursive-edit`. Called in `cbx-complete.zsh` popup path.
- [x] Exit via `zle send-break` on accept and cancel. Both accept and cancel widgets call `zle send-break`.
- [x] Guarantee keymap teardown and cursor restore on exit, including interrupt-driven exits. `{..} always {..}` block restores keymap, erases popup, shows cursor, resets `_CBX_POPUP_ACTIVE`.

#### Phase integration (3/3 done)

- [x] Source new Phase 04 files in plugin load order. `compbox.plugin.zsh` sources navigate, render, keymap before `cbx-complete.zsh`.
- [x] Register new files and popup globals in scrut and zunit helper bootstrap and reset lists. Both `setup.zsh` and `bootstrap.zsh` updated.
- [x] Ensure `cbx-disable` cleanup removes any popup state residue. `cbx-disable.zsh` destroys keymap, erases popup, unsets all four popup globals.

#### Tests (5/5 done)

- [x] Scrut tests: Row projection, frame structure, highlight selection, navigation wrap, accept/cancel state, erase, no-match/single-match skip. 15 tests covering all listed areas.
- [x] zunit tests: Navigation wrapping, keymap bindings, accept handoff, cancel behavior, bootstrap integration, disable cleanup. 22 tests covering all listed areas.
- [x] Navigation helpers wrap deterministically (tested for next, prev, single-element edge case).
- [x] Accept path extracts correct id and sets action (zunit test verifies).
- [x] Temporary keymap and popup state are always removed on exit (disable cleanup test verifies).

#### Benchmark plan items (partially addressed in follow-up commits)

The plan's benchmark section called for:

1. Measure open-popup latency -- Done via `popup-open-accept.zsh` fixture.
2. Measure navigation redraw latency at p95 -- Done via `popup-navigate-accept.zsh` fixture.
3. Measure accept and cancel exit latency impact -- Done via `popup-cancel.zsh` fixture.

These were addressed in a follow-up set of commits with their own plan (`2026-03-17-popup-benchmark-fixtures.md`).

**Deviations**: None identified. The implementation matches the plan's specified approach at every point.

**Fidelity concerns**: None. The implementation is thorough and matches the plan's spirit. The `KEYTIMEOUT=1` optimization and `^J` binding for pty ICRNL translation are quality-of-life fixes beyond the plan scope that are well-justified.

### Code Quality Assessment

#### Overall quality

This code is ready to merge. The implementation is clean, well-structured, and thoroughly tested. Each module has a single clear responsibility, the interaction loop is robust against edge cases, and the cleanup guarantees are solid.

#### Strengths

1. **Robust cleanup via `always` blocks.** The `{..} always {..}` pattern in `cbx-complete.zsh` guarantees keymap teardown, cursor restore, and state cleanup on all exit paths, including interrupts. `TRY_BLOCK_ERROR=0` correctly suppresses the `send-break` exception so the accept/cancel dispatch runs.

2. **Defensive buffer save/restore.** The popup path saves `BUFFER` and `CURSOR` before stock completion runs, then restores them when entering the popup. This prevents stock completion's common-prefix insertion from leaking into the popup flow, while the `compstate[insert/list]` suppression in `-cbx-compadd` provides a complementary layer.

3. **Clean separation of concerns.** Navigation, rendering, and keymap management are each in their own file with no cross-dependencies beyond shared state variables. Widget handlers are thin wrappers: navigate + render or set-state + send-break.

4. **Thoughtful keymap design.** Binding both `^M` and `^J` for accept handles pty ICRNL translation. Binding Left/Right arrows to noop prevents multi-byte escape sequences from accidentally triggering the bare-escape cancel. Binding both CSI (`\e[A/B`) and SS3 (`\eOA/B`) arrow variants handles different terminal emulators.

5. **Comprehensive test coverage.** 15 scrut + 22 zunit tests cover row projection, rendering, navigation boundaries, accept/cancel state, erase sequences, keymap lifecycle, bootstrap integration, and disable cleanup. The test matrix is thorough.

6. **Well-designed benchmark suite.** Using popup-to-popup deltas as the primary signal cancels out the `after` sleep and isolates actual navigation/cancel overhead. Budget thresholds are clearly documented.

7. **KEYTIMEOUT optimization.** Lowering `KEYTIMEOUT` to 1 (10ms) during the popup loop makes Escape feel instant while being safe since the popup keymap has no user multi-key sequences.

#### Issues to address

None identified. No bugs, security issues, or correctness problems are visible in the diff.

#### Suggestions

1. **Render buffer could use `local` for `esc` and `buf` in the hot path.** In `-cbx-popup-render-buffer`, `esc` and `buf` are already local, but the function does not call `emulate -L zsh` while sibling functions do. This is not a bug (the function inherits the caller's options), but adding it would be consistent with the codebase pattern. Very minor.

2. **The `_CBX_POPUP_RENDERED_LINES` global is set inside `render-buffer` as a side effect.** Returning it via a second `REPLY` variable or a naming convention like `REPLY2` would be more explicit, but the current approach is pragmatic and documented in the file header comment.
