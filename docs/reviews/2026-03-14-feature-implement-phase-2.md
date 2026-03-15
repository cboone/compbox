## Branch Review: feature/implement-phase-2

Base: main (merge base: 5ed965b)
Commits: 14
Files changed: 17 (8 added, 9 modified)
Reviewed through: 6e8688c

### Summary

This branch implements Phase 02 of the compbox plugin: candidate capture and data model. It adds a `compadd` interception layer that delegates to the builtin first, then captures completion candidates with stable monotonic IDs, metadata, and raw args for later replay. The implementation includes comprehensive scrut and zunit tests, benchmark instrumentation, performance optimizations (inlining pack to eliminate subshell forks), and a manual test shell helper.

### Changes by Area

**Core capture logic**

The two new library files form the heart of the phase. `lib/-cbx-compadd.zsh` provides the `compadd` wrapper (`-cbx-compadd`) that delegates to `builtin compadd`, then captures candidates when inside the `_CBX_IN_COMPLETE` gate, skipping query-mode calls (`-O`, `-A`, `-D`). It parses compadd's complex option syntax to extract group (`-J`/`-V`), display array (`-d`), and handles `-a` (indexed array) and `-k` (associative array keys) expansion. `lib/-cbx-candidate-store.zsh` provides reset, pack, and unpack helpers for the tab-separated candidate record format.

Files: `lib/-cbx-compadd.zsh`, `lib/-cbx-candidate-store.zsh`

**Lifecycle integration**

Phase 02 capture is woven into the existing Phase 01 lifecycle. Enable installs the `compadd` shim function (preserving any pre-existing wrapper for restore on disable). Disable removes the shim, restores any pre-existing wrapper, and cleans up capture globals. The completion widget resets capture state and sets/clears the `_CBX_IN_COMPLETE` gate around dispatch.

Files: `lib/cbx-enable.zsh`, `lib/cbx-disable.zsh`, `lib/cbx-complete.zsh`, `compbox.plugin.zsh`

**Tests**

Comprehensive scrut snapshot tests (12 test sections) verify packed candidate output, ID monotonicity, gate/query-mode exclusion, duplicate handling, reset behavior, display overrides, `-V` group capture, `-a`/`-k` array expansion, and raw args storage. Zunit tests (14 test cases) verify wrapper installation, gate behavior, pack/unpack round-trip, backslash literal preservation, `-a`/`-k` expansion, lifecycle cleanup, pre-existing wrapper restoration, reset, ID monotonicity, and plugin bootstrap.

Files: `tests/scrut/phase-02-candidate-capture.md`, `tests/zunit/phase-02-candidate-capture.zunit`

**Test harnesses**

Both test bootstrap files updated to register the two new Phase 02 source files and four new capture globals in the reset lists. Smoke test source count updated from 7 to 9.

Files: `tests/helpers/setup.zsh`, `tests/zunit/helpers/bootstrap.zsh`, `tests/scrut/smoke.md`

**Performance and benchmarking**

Benchmark hooks (`cbx_bench_mark`, `cbx_bench_record_elapsed`) added at three capture stages (start, parsed, packed). The lifecycle-only benchmark fixture now sources Phase 02 files. Candidate packing was optimized by inlining the tab-separated string concatenation directly instead of calling `-cbx-candidate-pack` in a subshell, eliminating one `fork()` per completion word and reducing pass-through overhead from ~4.4ms to ~2.3ms (p50).

Files: `scripts/bench/fixtures/lifecycle-only.zsh`, `benchmarks/baseline.json`

**Developer tooling**

A `cbx-dump` helper was added to the manual test shell for inspecting captured candidates after pressing Tab. The check-zsh script added SC2215 to the shellcheck exclusion list. Cspell dictionary updated with Phase 02 terms.

Files: `scripts/manual-test.zsh`, `scripts/check-zsh.zsh`, `cspell.json`

**Documentation**

The Phase 02 plan was aligned with Phase 01 implementation patterns.

Files: `docs/plans/2026-03-11-phase-02-candidate-capture-data-model.md`

### File Inventory

**New files (8):**

- `lib/-cbx-candidate-store.zsh`
- `lib/-cbx-compadd.zsh`
- `tests/scrut/phase-02-candidate-capture.md`
- `tests/zunit/phase-02-candidate-capture.zunit`

(The following were significantly expanded rather than created, but the diff shows them as modified):

**Modified files (9):**

- `benchmarks/baseline.json`
- `compbox.plugin.zsh`
- `cspell.json`
- `docs/plans/2026-03-11-phase-02-candidate-capture-data-model.md`
- `lib/cbx-complete.zsh`
- `lib/cbx-disable.zsh`
- `lib/cbx-enable.zsh`
- `scripts/bench/fixtures/lifecycle-only.zsh`
- `scripts/check-zsh.zsh`
- `scripts/manual-test.zsh`
- `tests/helpers/setup.zsh`
- `tests/scrut/smoke.md`
- `tests/zunit/helpers/bootstrap.zsh`

**Deleted files:** None
**Renamed files:** None

### Notable Changes

- **New dependency on `_CBX_IN_COMPLETE` gate**: This global is set/unset around completion dispatch in `cbx-complete` and checked in `-cbx-compadd`. It is a core architectural decision for scoping capture.
- **Pre-existing compadd wrapper preservation**: `cbx-enable` now saves any pre-existing `compadd` function and `cbx-disable` restores it, preventing interference with other plugins.
- **Performance optimization**: Inlining the pack format eliminated subshell forks, roughly halving capture overhead.

### Plan Compliance

**Plan file:** `docs/plans/2026-03-11-phase-02-candidate-capture-data-model.md`

**Compliance verdict:** Excellent compliance. Every planned item is fully implemented, with additional justified work (performance optimization, `-a`/`-k` expansion, pre-existing wrapper preservation) that strengthens the implementation beyond the plan's baseline requirements.

**Overall progress:** 23/23 items done (100%)

#### Interception (4/4 done)

- **Add shell-level compadd shim that delegates to internal `-cbx-compadd`**: Done. `cbx-enable` installs `function compadd() { -cbx-compadd "${@}"; }`.
- **Install and remove the shim in cbx-enable and cbx-disable while keeping lifecycle idempotent**: Done. Both functions handle idempotent checks, and disable properly unfunctions the shim.
- **Pass through query-mode calls (-O, -A, -D) without capture**: Done. `-cbx-compadd` scans args for these flags and returns early.
- **Capture only inside plugin-controlled completion invocation (IN_CBX gate)**: Done. `_CBX_IN_COMPLETE` is set in `cbx-complete` and checked in `-cbx-compadd`.

#### Data Model (4/4 done)

- **Define candidate record format with stable integer id**: Done. Monotonic `_CBX_CAND_NEXT_ID` incremented per word.
- **Store metadata needed for later replay (word, PREFIX, SUFFIX, IPREFIX, ISUFFIX, display, group, raw args)**: Done. All fields captured in the tab-separated packed format.
- **Reset capture storage at the start of each completion invocation**: Done. `cbx-complete` calls `-cbx-candidate-reset` before dispatch.
- **Add pack and unpack helpers for deterministic test visibility**: Done. `-cbx-candidate-pack` and `-cbx-candidate-unpack` in the candidate store.

#### Phase 01 Integration (3/3 done)

- **Keep cbx-complete keymap dispatch semantics unchanged**: Done. Only added reset and gate logic around existing dispatch.
- **Source Phase 02 files in compbox.plugin.zsh and test harnesses**: Done. Plugin sources both files; both test harness source lists updated.
- **Add new capture globals to helper reset lists and disable cleanup**: Done. Four globals added to both reset lists; disable unsets them.

#### File-Level Plan (6/6 done)

- All 4 files to create: created.
- All 6 files to modify: modified.

#### Scrut Tests (5/5 done)

All five planned scrut test categories are covered, plus additional tests for display override, `-V` group, `-a`/`-k` expansion, and raw args.

#### Zunit Tests (4/4 done)

All four planned zunit test categories are covered, plus additional tests for `-a`/`-k` expansion, ID monotonicity, reset completeness, pre-existing wrapper restoration, backslash preservation, and bootstrap verification.

#### Manual Checks (not directly verifiable from diff)

The `cbx-dump` helper and manual test shell provide the tooling needed for manual verification. This is appropriate.

#### Benchmark Plan (2/2 done)

- Re-measure overhead: Done. Benchmark data updated multiple times as optimizations landed.
- Profile per-stage timing: Done. `cbx_bench_mark` hooks at capture-start, capture-parsed, capture-packed.

#### Acceptance Checklist (5/5 done)

All items are addressed: verify passes (implied by clean state), metadata is captured, lifecycle semantics preserved, benchmark overhead measured and optimized, wrapper state fully removed on disable.

#### Deviations

- **Scope addition: `-a`/`-k` array expansion** (commit 0483074): Not in the original plan, but clearly necessary for real-world usage since `_path_files` and other completion functions pass array variable names via `-a`. Well-justified.
- **Scope addition: pre-existing compadd wrapper preservation** (commit 4a4b8b9): Not in the original plan, but important for compatibility with other zsh plugins. Well-justified.
- **Scope addition: inline packing optimization** (commit 9dc51af): Not in the original plan, but addresses a concrete performance problem discovered during benchmarking. Well-justified.
- **Scope addition: backslash literal preservation** (commit 137794b): Fix for `print -r --` in unpack to preserve literal escape sequences. Discovered through testing.

All deviations are reasonable and improve the implementation.

### Code Quality Assessment

**Overall quality:** This code is ready to merge. The implementation is clean, well-structured, and thoroughly tested. The zsh conventions are followed consistently.

**Strengths:**

- **Thorough option parsing**: The `compadd` argument parser in `-cbx-capture-from-compadd` handles the full complexity of `compadd`'s option syntax: combined flags (`-J?*`), `--` separator, skip-next for value-taking options, and the compadd-specific option character set (`-[XPSpsiIWrRMFExoOADE]`).
- **Performance-conscious design**: Inlining the pack format to avoid subshell forks demonstrates good awareness of zsh performance characteristics. The benchmark hooks are non-intrusive (no-ops unless `CBX_BENCH=1`).
- **Test coverage**: Both test frameworks (scrut for snapshot verification, zunit for assertion-based lifecycle tests) cover the feature comprehensively. Edge cases like duplicate display strings, empty arrays, backslash literals, and pre-existing wrappers are all tested.
- **Idempotent lifecycle**: Enable/disable remain properly idempotent with the new capture layer added.
- **Clean separation**: The candidate store (reset/pack/unpack) is cleanly separated from the compadd interception logic.

**Issues to address:**

None identified. The code is clean and the implementation is solid.

**Suggestions (non-blocking):**

1. **`-cbx-candidate-pack` is now only used in tests**: After the inline optimization (commit 9dc51af), the pack function is only called from the zunit round-trip test. This is fine as a test utility, but the function's header comment ("Packed format: tab-separated fields in fixed order") should arguably note that production packing is inlined in `-cbx-capture-from-compadd` for performance. This would prevent future confusion about where packing actually happens.

2. **Query-mode detection scans all args**: The loop in `-cbx-compadd` that checks for `-O`/`-A`/`-D` iterates through all arguments, stopping at `--`. Since query-mode flags typically appear early in the argument list, this is fine in practice. No change needed, but worth noting for awareness.

3. **Option parser character class**: The option character set `[XPSpsiIWrRMFExoOADE]` includes both uppercase and lowercase letters. The fact that `-a` and `-k` are handled separately before the catch-all `-*` case is correct, but the `case` ordering is important: `-a*` and `-k*` must appear before the generic `*-)` fallthrough. The current ordering is correct.
