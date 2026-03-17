# Compbox

## Overview

A zsh plugin that replaces the built-in completion display with a bordered popup menu styled to match tmux's native menus.

## Skills

### Required Skills

Always use these skills when working on their respective file types:

- **write-zsh-scripts**: Use when creating or editing any `.zsh` file, including plugin source files in `lib/`, test helpers, and scripts.
- **write-scrut-tests**: Use when creating or editing scrut test files in `tests/scrut/`. Most guidance applies to zsh-based scrut tests, though the skill was written for bash.
- **check-zsh**: Use after modifying zsh scripts to validate them. Runs 7 tools: `zsh -n`, `zcompile`, `shellcheck`, `checkbashisms`, `shellharden`, `setopt warnings`, and `shfmt`.
- **write-markdown**: Use when creating or editing Markdown files.

### Validation

Run `make verify` (which runs `make check-zsh` and `make test`) after any code change.

## Zsh Conventions

### Scrut Test Helpers

The scrut test helper at `tests/helpers/setup.zsh` must NOT set file-level strict options (`ERR_EXIT`). When sourced by scrut, file-level options leak into scrut's internal shell and break its bash-based state management (`shopt`). Use `emulate -L zsh` inside each function instead.

### Zunit Test Helpers

The zunit bootstrap at `tests/zunit/helpers/bootstrap.zsh` must use `typeset -gr` (global readonly) for variables, because zunit's `load` runs inside a function scope. Guard against repeated sourcing since `@setup` runs before each test.

### ShellCheck

ShellCheck does not support `--shell=zsh`. Use `--shell=bash` with SC code exclusions for zsh false positives. See `SHELLCHECK_EXCLUDE` in `scripts/check-zsh.zsh` for the current exclusion list. The canonical codes come from the `check-zsh-scripts` skill; project-specific codes are documented inline.

### Tool Availability

All development and CI tools are expected to be installed. Do not add "when available" fallbacks or graceful skip logic. If a tool is missing, that is a setup error that should fail loudly.

## Project Structure

```text
lib/                          Plugin source files (loaded in order)
lib/bench/                    Benchmark timing instrumentation
scripts/                      Development scripts (check, format, bench)
scripts/lib/                  Shared script libraries
scripts/bench/                Benchmark runner
scripts/bench/fixtures/       Benchmark fixture scripts
tests/helpers/setup.zsh       Scrut test bootstrap
tests/scrut/*.md              Scrut CLI snapshot tests
tests/zunit/helpers/          Zunit test bootstrap
tests/zunit/*.zunit           Zunit lifecycle tests
tests/fixtures/               Test fixture plugins
benchmarks/                   Benchmark output (baseline committed, ad-hoc gitignored)
docs/plans/                   Implementation plans (active)
docs/plans/done/              Completed plans
docs/reviews/                 Branch reviews
```

## Make Targets

| Target              | Purpose                       |
| ------------------- | ----------------------------- |
| `make test`         | Run all tests (scrut + zunit) |
| `make test-scrut`   | Run scrut CLI tests           |
| `make test-zunit`   | Run zunit lifecycle tests     |
| `make check-zsh`    | Check zsh scripts (7 tools)   |
| `make format-zsh`   | Format zsh scripts            |
| `make verify`       | Run checks and tests          |
| `make bench`        | Run benchmarks                |
| `make lint`         | Run all linters               |
| `make format`       | Format Markdown, JSON, YAML   |
| `make format-check` | Check formatting              |
| `make spell`        | Run spell check               |
