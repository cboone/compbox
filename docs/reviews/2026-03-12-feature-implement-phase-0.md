## Branch Review: feature/implement-phase-0

Base: main (merge base: 95c319f)
Commits: 11
Files changed: 22 (17 added, 5 modified, 0 deleted, 0 renamed)
Reviewed through: 7ef4108

### Summary

This branch implements Phase 00 of the compbox rebuild: a complete test, check, and benchmark foundation. It establishes scrut and zunit test harnesses with smoke tests, a comprehensive 7-tool zsh checking script, a shfmt-based formatting script, and a hyperfine-driven benchmark driver with baseline and smoke modes. CI is fully wired with separate jobs for check-zsh, scrut, zunit, and benchmark smoke, all installing tools from verified GitHub release artifacts instead of building from source.

### Changes by Area

#### Test harnesses and fixtures

Scrut helper (`tests/helpers/setup.zsh`) bootstraps plugin sources in deterministic order and provides `cbx_test_setup`/`cbx_test_reset` for state management. Zunit bootstrap (`tests/zunit/helpers/bootstrap.zsh`) uses `typeset -gr` for global readonly variables to work within zunit's function-scoped `load`. Three test fixture plugins record load order and verify strict options. Both helpers avoid file-level `ERR_EXIT` to prevent leaking into the test runners.

Files: `tests/helpers/setup.zsh`, `tests/zunit/helpers/bootstrap.zsh`, `tests/fixtures/plugins/10-record-first.zsh`, `tests/fixtures/plugins/20-record-second.zsh`, `tests/fixtures/plugins/30-record-options.zsh`

#### Smoke tests

Scrut smoke tests verify harness bootstrap, deterministic source ordering, strict option propagation, state reset, function cleanup, benchmark opt-in behavior, and report line format parsing. Zunit smoke tests cover the same areas from the lifecycle side, including option leak verification and `run` assertion plumbing.

Files: `tests/scrut/smoke.md`, `tests/zunit/smoke.zunit`

#### Check and format scripts

`check-zsh.zsh` runs 7 tools per file: `zsh -n`, `zcompile`, `shellcheck` (with documented SC exclusions), `checkbashisms`, `shellharden`, `setopt warn_create_global/warn_nested_var`, and `shfmt`. All tools are required; no graceful skip logic. `format-zsh.zsh` formats with `shfmt` (skipping unparseable files) and re-verifies syntax. beautysh was dropped in favor of shfmt as the sole formatter.

Files: `scripts/check-zsh.zsh`, `scripts/format-zsh.zsh`

#### Benchmark harness

`scripts/bench/run.zsh` drives hyperfine with `--baseline`, `--smoke`, and full modes. Reports p50/p95/iterations via jq extraction. `lib/bench/timing.zsh` provides opt-in `CBX_BENCH=1` hooks (`cbx_bench_mark`, `cbx_bench_record_elapsed`, `cbx_bench_report`) that are pure no-ops when disabled, creating zero runtime overhead.

Files: `scripts/bench/run.zsh`, `scripts/bench/fixtures/noop-plugin.zsh`, `scripts/bench/fixtures/noop-plugin-startup.zsh`, `scripts/bench/fixtures/stock-completion.zsh`, `lib/bench/timing.zsh`

#### Build system

Makefile extended with `test-scrut`, `test-zunit`, `test` (aggregate), `test-scrut-update`, `check-zsh`, `format-zsh`, `verify`, `bench`, and `bench-baseline` targets. `.gitignore` updated for `benchmarks/*.json`.

Files: `Makefile`, `.gitignore`, `benchmarks/.gitkeep`

#### CI

Replaced the single `test` job with four parallel jobs: `check-zsh`, `test-scrut`, `test-zunit`, and `bench-smoke`. Tools are installed from GitHub release tarballs/debs with SHA-256/SHA-512 verification, eliminating the Rust toolchain dependency. Benchmark smoke uploads a JSON artifact.

Files: `.github/workflows/ci.yml`

#### Documentation

AGENTS.md expanded with skills, conventions, project structure, and make targets. CONTRIBUTING.md updated with development tools list, make target table, benchmark documentation, and updated code style guidance. `cspell.json` updated with new dictionary words.

Files: `AGENTS.md`, `CONTRIBUTING.md`, `cspell.json`

### File Inventory

**New files (17):**

- `benchmarks/.gitkeep`
- `lib/bench/timing.zsh`
- `scripts/bench/fixtures/noop-plugin-startup.zsh`
- `scripts/bench/fixtures/noop-plugin.zsh`
- `scripts/bench/fixtures/stock-completion.zsh`
- `scripts/bench/run.zsh`
- `scripts/check-zsh.zsh`
- `scripts/format-zsh.zsh`
- `tests/fixtures/plugins/10-record-first.zsh`
- `tests/fixtures/plugins/20-record-second.zsh`
- `tests/fixtures/plugins/30-record-options.zsh`
- `tests/helpers/setup.zsh`
- `tests/scrut/smoke.md`
- `tests/zunit/helpers/bootstrap.zsh`
- `tests/zunit/smoke.zunit`
- `AGENTS.md` (expanded from stub)
- `CONTRIBUTING.md` (substantially expanded)

**Modified files (5):**

- `.github/workflows/ci.yml`
- `.gitignore`
- `cspell.json`
- `docs/plans/2026-03-11-phase-00-test-benchmark-foundation.md`
- `Makefile`

### Notable Changes

- **CI pipeline restructured**: Single test job replaced with four parallel jobs. Tool installation switched from `cargo install` to pre-built binary downloads with hash verification. This significantly reduces CI time and attack surface.
- **Rust toolchain dependency removed**: scrut is now installed from a pre-built release tarball.
- **New development tool requirements**: shellcheck, shfmt, shellharden, checkbashisms, hyperfine, jq are all required for development.
- **Benchmark artifacts**: CI uploads `bench-smoke-json` artifact on each run.

### Plan Compliance

**Plan**: `docs/plans/2026-03-11-phase-00-test-benchmark-foundation.md`

**Compliance verdict**: Strong compliance. The branch delivers on all five in-scope items and all acceptance criteria. The plan was updated during implementation to reflect refinements (file paths, report format fields, CI target granularity), which is appropriate. The implementation matches the plan's spirit, delivering a robust foundation for later phases.

**Overall progress**: 5/5 in-scope items done (100%)

#### Tooling and entrypoints (Done)

All specified Make targets are present: `test-scrut`, `test-zunit`, `test`, `check-zsh`, `format-zsh`, `verify`, `bench`, `bench-baseline`. Additionally adds `test-scrut-update` which the plan did not explicitly call for but is a practical necessity. Script entrypoints for check and format are created.

#### Test harness (Done)

Scrut helper bootstrap at `tests/helpers/setup.zsh`, zunit bootstrap at `tests/zunit/helpers/bootstrap.zsh`. Both smoke test files created. Test fixtures at `tests/fixtures/plugins/*.zsh` provide deterministic ordering verification.

#### Benchmark harness (Done)

Driver script at `scripts/bench/run.zsh` with baseline scenarios and p50/p95/iterations reporting. `CBX_BENCH=1` opt-in timing design implemented in `lib/bench/timing.zsh` with no-op stubs when disabled. Scenarios include stock completion and noop plugin startup as planned.

#### CI (Done)

CI installs and runs scrut, zunit, check-zsh, and benchmark smoke. Individual `make check-zsh`, `make test-scrut`, and `make test-zunit` targets execute in separate jobs. Fast benchmark smoke path runs a small fixture set with 10 iterations and uploads a JSON artifact.

#### File-level plan (Done)

All 11 files listed under "Create" are present. All 3 files listed under "Modify" are modified. The plan was updated during implementation to add `tests/fixtures/plugins/*.zsh`, `scripts/bench/fixtures/*.zsh`, and `lib/bench/timing.zsh`, which were discovered during implementation.

#### Deviations

1. **beautysh dropped**: The initial implementation included beautysh as a fallback formatter, but it was removed in favor of shfmt as the sole formatter. The plan did not specify formatter choice, so this is a reasonable implementation decision. The commit message explains the rationale (no zsh support, indentation conflicts).

2. **check-zsh runs 7 tools, not 8**: The plan's acceptance checklist and documentation sometimes reference 7 tools, sometimes 8 (when beautysh was still included). After dropping beautysh, the tool count settled at 7, which is consistent throughout the final state.

3. **Plan updated in-flight**: The plan file itself was modified to refine file paths (e.g., `tests/smoke.md` to `tests/scrut/smoke.md`), add missing files, and adjust CI target names. These are refinements, not scope changes.

#### Fidelity concerns

None. The implementation matches the plan's intent closely, including the opt-in benchmark design with zero runtime overhead and the deterministic source ordering for test harness reliability.

#### Acceptance checklist verification

1. `make check-zsh` passes locally: Implemented, script exits non-zero on any findings.
2. `make test-scrut` passes locally: Implemented, runs scrut against `tests/scrut/*.md`.
3. `make test-zunit` passes locally: Implemented, runs zunit against `tests/zunit/*.zunit`.
4. `make bench-baseline` runs and emits p50/p95 output: Implemented, persists to `benchmarks/baseline.json`.
5. CI executes all new quality gates: Four separate CI jobs configured.

### Code Quality Assessment

#### Code Quality

**Readability**: The code is consistently well-structured. Every script uses `emulate -L zsh` with appropriate option sets. Functions are small and single-purpose. Comments explain "why" rather than "what", particularly the `|| true` annotations explaining why advisory tools need to suppress non-zero exits under `ERR_EXIT`.

**Maintainability**: The `CBX_PLUGIN_SOURCES` arrays in both test helpers provide a single place to add new plugin files as later phases are implemented. The `CBX_TEST_GLOBALS_TO_RESET` arrays similarly centralize cleanup. The check-zsh script's `SHELLCHECK_EXCLUDE` has inline documentation for every SC code.

**Patterns and consistency**: Both test helpers follow the same structural pattern (project root resolution, source list, globals-to-reset list, load function, reset function) but adapted appropriately for their respective frameworks (scrut's file-level sourcing vs. zunit's function-scoped `load`). The benchmark timing API is clean and symmetric (`mark`/`record_elapsed`/`report`).

**Duplication**: The source list (`CBX_PLUGIN_SOURCES`) and globals-to-reset list (`CBX_TEST_GLOBALS_TO_RESET`) are duplicated between the scrut and zunit helpers. This is a reasonable trade-off: the two helpers operate in fundamentally different execution contexts (scrut uses a bash-backed shell, zunit uses zsh with function-scoped loading), and a shared include would add complexity for little benefit at this project size.

#### Potential Issues

1. **`find_zsh_files` duplication**: The `find_zsh_files` function is duplicated between `check-zsh.zsh` and `format-zsh.zsh`. If the glob patterns diverge, one script could operate on a different file set than the other. Low severity since both currently use identical patterns.

2. **`run_setopt_warnings` command injection surface**: The `source` command in `run_setopt_warnings` embeds the file path directly in a string passed to `zsh -c`. This is safe in practice because the paths come from `find_zsh_files` which glob-expands project-local patterns, but paths with single quotes would break the quoting. This is a theoretical concern for this project (no filenames with quotes), not a practical one.

3. **`extract_stats` jq p95 calculation**: The p95 computation uses `floor` on `length * 0.95`, which means for arrays shorter than 20 elements (like the 10-iteration smoke run), the index could be imprecise. For the smoke case this is acceptable since the values are not used for comparison. For the 100-iteration baseline, the index is accurate.

4. **Benchmark `smoke` and `baseline` scenarios are identical**: Both modes configure the same two scenarios (`stock-completion` and `noop-plugin-startup`). The only difference is iteration count (10 vs 100). This is likely intentional to keep smoke fast while ensuring it exercises the same code paths, but it means smoke does not actually test a "small fixture set" vs. a larger one. The difference is purely iteration count.

#### Completeness

- No TODO, FIXME, HACK, or XXX comments in the new code.
- No stub implementations or placeholder values.
- Tests cover the harness bootstrap, state management, option isolation, function cleanup, and benchmark opt-in behavior for both test frameworks.
- Documentation is thorough: AGENTS.md, CONTRIBUTING.md, and the plan file are all updated.
- The scrut test for "baseline report format parser" is minimal (it just splits a hardcoded string on spaces) rather than testing the actual `extract_stats` function output. This is acceptable for phase 0 since hyperfine is not available in scrut's test environment.

#### Assessment Verdict

**Overall quality**: This code is ready to merge. The implementation is thorough, well-documented, and meets every item in the plan.

**Strengths**:

- Disciplined use of `emulate -L zsh` with function-local option scoping throughout
- Thorough `|| true` documentation explaining why advisory tool exit codes must be suppressed
- Clean separation of concerns: check, format, and benchmark are independent scripts
- Opt-in benchmark design with genuinely zero overhead when disabled (no-op function stubs, no globals created)
- CI installs tools from verified artifacts instead of building from source
- Both test frameworks exercise the same behaviors from different angles

**Issues to address**:

None blocking. The code is clean and well-structured.

**Suggestions**:

1. Consider extracting `find_zsh_files` into a shared utility if the glob patterns need to stay synchronized across check-zsh and format-zsh.
2. The `run_setopt_warnings` function could use `${(q)file}` for safer quoting in the `zsh -c` string, though this is not a practical risk today.
3. In a future phase, the `smoke` and `baseline` benchmark modes could diverge in scenario selection rather than just iteration count, to make the distinction more meaningful.
