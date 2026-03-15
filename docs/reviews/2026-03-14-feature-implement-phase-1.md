## Branch Review: feature/implement-phase-1

Base: main (merge base: bb39c9a)
Commits: 13
Files changed: 19 (11 added, 7 modified, 0 deleted, 0 renamed)
Reviewed through: d2e7d9c

### Summary

This branch implements Phase 01 of the compbox plugin: hook lifecycle management and pass-through Tab completion. It adds `cbx-enable`, `cbx-disable`, and `cbx-complete` functions that safely intercept the Tab key in both emacs and viins keymaps, delegate to the original widget with zero interception, and restore all bindings on disable. The branch also includes comprehensive scrut and zunit tests, benchmark fixtures for lifecycle overhead measurement, and a manual test script.

### Changes by Area

#### Core Plugin Code

The plugin entrypoint (`compbox.plugin.zsh`) and three library files implement the complete lifecycle. `cbx-enable` saves original Tab bindings, registers the `cbx-complete` widget, and binds Tab in both keymaps. `cbx-disable` restores everything and cleans up state. `cbx-complete` dispatches to the saved original widget based on the active keymap. All operations are idempotent, and the plugin entrypoint guards against repeated sourcing.

Files: `compbox.plugin.zsh`, `lib/cbx-enable.zsh`, `lib/cbx-disable.zsh`, `lib/cbx-complete.zsh`

#### Tests

Scrut tests (10 cases) cover lifecycle state snapshots, binding installation and restoration, idempotency for both enable and disable, pass-through widget dispatch by keymap, auto-enable on source, and repeated sourcing guard. Zunit tests (10 cases) cover the same lifecycle behaviors plus widget registration/removal, global cleanup after disable, saved widget names, and a clean-shell bootstrap test that verifies the plugin works in `zsh -f` without preloaded files.

Files: `tests/scrut/phase-01-lifecycle.md`, `tests/zunit/phase-01-lifecycle.zunit`

#### Test Harnesses

Both the scrut helper and zunit bootstrap register the three new Phase 01 library files in the plugin source list and add all lifecycle globals to the reset list. The reset functions now call `cbx-disable` before cleanup to properly restore bindings.

Files: `tests/helpers/setup.zsh`, `tests/zunit/helpers/bootstrap.zsh`

#### Benchmarks

Two new non-interactive fixtures (`stock-compinit`, `lifecycle-only`) measure plugin startup cost in isolation. The existing `pass-through-tab` expect-based fixture measures end-to-end Tab completion overhead through the `cbx-complete` widget. The benchmark runner now shows results in milliseconds with colored delta summaries comparing lifecycle overhead between paired scenarios. A committed `baseline.json` provides a reference point across worktrees and machines.

Files: `scripts/bench/run.zsh`, `scripts/bench/fixtures/stock-compinit.zsh`, `scripts/bench/fixtures/lifecycle-only.zsh`, `scripts/bench/fixtures/pass-through-tab.zsh`, `scripts/bench/fixtures/stock-completion.zsh`, `benchmarks/baseline.json`, `.gitignore`

#### Documentation

The README usage section replaces the TODO placeholder with documentation for `cbx-enable`, `cbx-disable`, and the auto-activation behavior. A manual test script launches a clean interactive zsh with the plugin loaded for hands-on verification. The Phase 01 plan was also updated to align dependencies and scope with Phase 00.

Files: `README.md`, `scripts/manual-test.zsh`, `docs/plans/2026-03-11-phase-01-hook-lifecycle-pass-through.md`

### File Inventory

**New files (11):**

- `benchmarks/baseline.json`
- `compbox.plugin.zsh`
- `lib/cbx-complete.zsh`
- `lib/cbx-disable.zsh`
- `lib/cbx-enable.zsh`
- `scripts/bench/fixtures/lifecycle-only.zsh`
- `scripts/bench/fixtures/pass-through-tab.zsh`
- `scripts/bench/fixtures/stock-compinit.zsh`
- `scripts/manual-test.zsh`
- `tests/scrut/phase-01-lifecycle.md`
- `tests/zunit/phase-01-lifecycle.zunit`

**Modified files (7):**

- `.gitignore`
- `README.md`
- `docs/plans/2026-03-11-phase-01-hook-lifecycle-pass-through.md`
- `scripts/bench/fixtures/stock-completion.zsh`
- `scripts/bench/run.zsh`
- `tests/helpers/setup.zsh`
- `tests/zunit/helpers/bootstrap.zsh`

**Deleted files:** None

**Renamed files:** None

### Notable Changes

- **Benchmark baseline committed**: `benchmarks/baseline.json` (1,268 lines) is now tracked in git via a `.gitignore` exception, providing a stable reference for cross-worktree comparison. Ad-hoc benchmark runs remain gitignored.
- **Benchmark runner overhauled**: `scripts/bench/run.zsh` gained millisecond formatting, ANSI-colored delta summaries, paired scenario comparisons (lifecycle-only vs stock-compinit, pass-through-tab vs stock-completion), and new modes (baseline, smoke, full).

### Plan Compliance

**Plan:** `docs/plans/2026-03-11-phase-01-hook-lifecycle-pass-through.md`

**Compliance verdict:** Full compliance. Every planned item is implemented thoroughly, with no shortcuts or omissions. The implementation matches both the letter and spirit of the plan.

**Overall progress:** 24/24 items done (100%)

#### Lifecycle (6/6)

- [x] Create `compbox.plugin.zsh` with eager library loading: Done. Sources all libs in deterministic order.
- [x] On plugin source, call `cbx-enable` once (guarded): Done. `_CBX_PLUGIN_SOURCED` integer guard prevents re-entry.
- [x] Save original Tab widgets from emacs and viins keymaps: Done. Both captured via `bindkey -M` output parsing.
- [x] Bind `^I` to `cbx-complete` in both keymaps: Done.
- [x] Ensure disable restores all original bindings and helpers: Done. Widget removed, bindings restored, globals unset.
- [x] Make enable and disable idempotent: Done. Both guard on `_CBX_ENABLED`.

#### Pass-through widget (2/2)

- [x] `cbx-complete` delegates to frozen original completion widget: Done. Dispatches via `zle` based on `KEYMAP`.
- [x] No interception or state mutation beyond lifecycle tracking: Done. Widget does nothing except call the original.

#### Harness integration (3/3)

- [x] Register new Phase 01 plugin files in test helper source lists: Done in both `setup.zsh` and `bootstrap.zsh`.
- [x] Ensure helper reset clears any lifecycle globals: Done. `_CBX_ENABLED`, `_CBX_ORIG_TAB_EMACS`, `_CBX_ORIG_TAB_VIINS`, `_CBX_PLUGIN_SOURCED`, `_CBX_PLUGIN_ROOT` all in reset list, and `cbx-disable` is called during reset.
- [x] Add a benchmark fixture and scenario for pass-through Tab execution: Done. Both expect-based (`pass-through-tab`) and non-interactive (`lifecycle-only`, `stock-compinit`) fixtures added.

#### File-Level Plan - Create (7/7)

All seven planned files created: `compbox.plugin.zsh`, `lib/cbx-enable.zsh`, `lib/cbx-disable.zsh`, `lib/cbx-complete.zsh`, `tests/scrut/phase-01-lifecycle.md`, `tests/zunit/phase-01-lifecycle.zunit`, `scripts/bench/fixtures/pass-through-tab.zsh`.

#### File-Level Plan - Modify (4/4)

All four planned files modified: `README.md`, `tests/helpers/setup.zsh`, `tests/zunit/helpers/bootstrap.zsh`, `scripts/bench/run.zsh`.

#### Scrut Tests (3/3)

- [x] Snapshot lifecycle state before enable, after enable, and after disable: Done (3 separate test cases).
- [x] Verify repeated enable and disable calls are idempotent: Done (2 test cases).
- [x] Verify pass-through call path markers: Done (2 test cases mock `zle` and verify dispatch by keymap).

#### Zunit Tests (5/5)

- [x] Enabling installs widget and key bindings in both keymaps: Done.
- [x] Disabling restores prior bindings exactly: Done.
- [x] Repeated enable calls do not duplicate hooks: Done.
- [x] Repeated disable calls are safe no-ops: Done.
- [x] Sourcing `compbox.plugin.zsh` auto-enables once without duplicate installs: Done (includes repeated sourcing guard verification).

#### Additional items beyond plan

- `scripts/bench/fixtures/stock-compinit.zsh` and `scripts/bench/fixtures/lifecycle-only.zsh` were added as benchmark fixtures not explicitly listed in the file-level plan, but they directly support the benchmark plan's goal of comparing lifecycle overhead. Reasonable addition.
- `scripts/manual-test.zsh` supports the plan's "Manual Checks" section. Reasonable addition.
- `benchmarks/baseline.json` committed to git. Supports the benchmark plan and acceptance checklist. Reasonable addition.
- Three additional zunit tests beyond the plan's five: clean-shell bootstrap, saved widget names, widget registration/removal, and global cleanup. All improve coverage without scope creep.

**Deviations:** None. The implementation follows the plan's specified approach precisely.

**Fidelity concerns:** None. The plan called for idempotent enable/disable, pass-through delegation, harness integration, and comprehensive tests. All are implemented to a high standard.

### Code Quality Assessment

#### Overall quality

This code is ready to merge. The implementation is clean, minimal, and well-structured. Each function does one thing, the lifecycle state management is correct, and the test coverage is thorough.

#### Strengths

- **Correct ZLE widget behavior**: `cbx-complete` intentionally omits `emulate -L zsh` and strict options, which is correct for a ZLE widget that needs to preserve the calling context so the delegated widget behaves identically to the original.
- **Clean idempotency**: Both `cbx-enable` and `cbx-disable` use a single integer flag (`_CBX_ENABLED`) for idempotency. Simple and correct.
- **Thorough cleanup**: `cbx-disable` unsets all globals it created, `zle -D` removes the widget, and bindings are restored. Test harness reset calls `cbx-disable` before cleanup, preventing binding leaks between tests.
- **Defensive test design**: The zunit clean-shell test (`zsh -f -c '...'`) verifies the plugin bootstraps correctly without pre-sourced files, catching load-order bugs that harness-based tests might miss.
- **Well-structured benchmarks**: The dual-pair comparison approach (stock-compinit vs lifecycle-only for startup cost, stock-completion vs pass-through-tab for runtime cost) isolates different overhead components clearly.
- **Consistent style**: All functions use `emulate -L zsh` with `ERR_EXIT NO_UNSET PIPE_FAIL` (except the ZLE widget, correctly). `readonly` and `typeset -g` usage is consistent throughout.

#### Issues to address

None identified. The code is clean and correct.

#### Suggestions

- The `_CBX_PLUGIN_ROOT` global is set in `compbox.plugin.zsh` but not used by any lifecycle function in this phase. It is presumably reserved for future phases. This is fine as-is; just noting it for awareness.
- The `baseline.json` file is 1,268 lines of raw timing data. Consider whether future baselines should strip the individual `times` arrays to reduce file size, keeping only summary statistics. This is a minor concern and not blocking.
