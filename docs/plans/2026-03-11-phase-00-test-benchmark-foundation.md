# Phase 00: Test and Benchmark Foundation

## Objective

Create the testing, checking, and benchmarking base so every later phase can add
behavior with immediate automated feedback.

## Depends On

1. `docs/plans/2026-03-11-rebuild-compbox-test-first-phases.md`

## In Scope

1. Add Scrut test harness and first deterministic smoke tests.
1. Add zunit harness and first lifecycle smoke tests.
1. Add zsh check, lint, and format targets aligned with check-zsh workflow.
1. Add benchmark scaffolding and baseline capture command.
1. Add CI wiring for checks, tests, and benchmark smoke mode.

## Out of Scope

1. Completion interception behavior.
1. Popup rendering behavior.
1. Final benchmark budgets (only baseline collection in this phase).

## Planned Changes

### Tooling and entrypoints

1. Extend `Makefile` with explicit targets:
   - `test-scrut`
   - `test-zunit`
   - `test` (aggregates both)
   - `check-zsh`
   - `format-zsh`
   - `verify` (check-zsh + test)
   - `bench` and `bench-baseline`
1. Add script entrypoints for repeatable zsh quality checks and formatting.

### Test harness

1. Create Scrut helper bootstrap under `tests/helpers/`.
1. Create zunit bootstrap under `tests/zunit/helpers/`.
1. Add one Scrut smoke file and one zunit smoke file to prove harness execution.

### Benchmark harness

1. Create benchmark driver script under `scripts/bench/`.
1. Add baseline scenario definitions and report format (p50, p95, iterations).
1. Add opt-in timing flag design (`CBX_BENCH=1`) with no runtime overhead when off.

### CI

1. Install and run Scrut and zunit.
1. Run `make check-zsh`, `make test-scrut`, and `make test-zunit` on PRs.
1. Run a fast benchmark smoke path in CI (small fixture set only).

## File-Level Plan

### Create

1. `tests/helpers/setup.zsh`
1. `tests/scrut/smoke.md`
1. `tests/zunit/helpers/bootstrap.zsh`
1. `tests/zunit/smoke.zunit`
1. `tests/fixtures/plugins/*.zsh`
1. `scripts/check-zsh.zsh`
1. `scripts/format-zsh.zsh`
1. `scripts/bench/run.zsh`
1. `scripts/bench/fixtures/*.zsh`
1. `lib/bench/timing.zsh`

### Modify

1. `Makefile`
1. `.github/workflows/ci.yml`
1. `CONTRIBUTING.md`

## Scrut Tests To Add

1. Harness loads plugin files in deterministic order.
1. Helper can set up and reset global state between blocks.
1. Snapshot for baseline report format parser.

## zunit Tests To Add

1. Bootstrap loads with `emulate -L zsh` and strict options.
1. Test helper reset clears globals and functions created during tests.
1. Basic assertion plumbing and failure output sanity check.

## Benchmark Plan

1. Add baseline command comparing stock completion and no-op plugin shell startup.
1. Track median and p95 for at least 100 iterations per scenario in local runs.
1. Persist baseline output locally under `benchmarks/` and upload CI smoke JSON artifacts.

## Acceptance Checklist

1. `make check-zsh` passes locally.
1. `make test-scrut` passes locally.
1. `make test-zunit` passes locally.
1. `make bench-baseline` runs and emits p50/p95 output.
1. CI executes all new quality gates.

## Rollback Triggers

1. If test harness startup is unstable across runs, rollback to minimal smoke scope.
1. If benchmark harness adds noticeable overhead to normal execution paths,
   disable by default and isolate behind explicit env flag.
