# Contributing to Compbox

Thank you for your interest in contributing to compbox.

Please note that this project has a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold it.

## Reporting Issues

- **Bug reports and feature requests:** Use the [issue tracker](https://github.com/cboone/compbox/issues/new/choose)
- **Questions and ideas:** Use [GitHub Discussions](https://github.com/cboone/compbox/discussions)
- **Security vulnerabilities:** See [SECURITY.md](.github/SECURITY.md)

## Development Setup

### Requirements

- zsh 5.9+
- tmux

### Development Tools

Install all tools used by `make check-zsh`, `make format-zsh`, and `make bench`:

- [shellcheck](https://www.shellcheck.net/): `brew install shellcheck`
- [shfmt](https://github.com/mvdan/sh): `brew install shfmt`
- [shellharden](https://github.com/anordal/shellharden): `brew install shellharden`
- [checkbashisms](https://tracker.debian.org/pkg/devscripts): `brew install checkbashisms`
- [hyperfine](https://github.com/sharkdp/hyperfine): `brew install hyperfine`
- [jq](https://jqlang.github.io/jq/): `brew install jq`

### Getting Started

```bash
# Clone the repository
git clone https://github.com/cboone/compbox.git
cd compbox

# Run linter
make lint

# Check formatting
make format-check

# Run all checks and tests
make verify

# Run tests only
make test
```

### Test Dependencies

Tests use [scrut](https://github.com/facebookincubator/scrut) for CLI
snapshot testing and [zunit](https://github.com/zunit-zsh/zunit) for zsh
lifecycle testing:

```bash
# scrut (required)
cargo install --locked scrut

# zunit (required for `make test`; installed automatically in CI)
git clone https://github.com/zunit-zsh/zunit.git /tmp/zunit
cd /tmp/zunit && sudo ./build.zsh
```

### Benchmark Instrumentation

Internal timing hooks are opt-in. Set `CBX_BENCH=1` before sourcing plugin files
to enable benchmark helpers such as `cbx_bench_mark`,
`cbx_bench_record_elapsed`, and `cbx_bench_report`.

Leave `CBX_BENCH` unset for normal development and runtime paths so timing
state is not created.

### Benchmark Artifacts

- `make bench-baseline` writes `benchmarks/baseline.json` for local comparison.
- Benchmark JSON files under `benchmarks/` are intentionally gitignored.
- CI smoke benchmarks upload a `bench-smoke-json` artifact for each run.

### Available Make Targets

| Target                | Description                                  |
| --------------------- | -------------------------------------------- |
| `make test`           | Run all tests (scrut + zunit)                |
| `make test-scrut`     | Run scrut CLI tests                          |
| `make test-zunit`     | Run zunit lifecycle tests                    |
| `make check-zsh`      | Check zsh scripts for syntax and lint issues |
| `make format-zsh`     | Format zsh scripts with shfmt                |
| `make verify`         | Run checks and tests                         |
| `make bench`          | Run benchmarks                               |
| `make bench-baseline` | Capture benchmark baseline                   |
| `make lint`           | Run all linters                              |
| `make format`         | Format Markdown, JSON, and YAML files        |
| `make help`           | Show all available targets                   |

## Code Style

- Run `make verify` before committing
- Run `make format` to format Markdown, JSON, and YAML files
- Run `make format-zsh` to format zsh scripts

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
<type>: <description>
```

**Types:**

- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation changes
- `refactor`: code refactoring (no functional change)
- `test`: adding or updating tests
- `build`: build system or dependency changes
- `ci`: CI configuration changes
- `chore`: maintenance tasks

**Examples:**

```text
feat: add user authentication endpoint
fix: resolve race condition in worker pool
docs: update installation instructions
refactor: simplify configuration loading
test: add unit tests for validation logic
chore: update linter to latest version
```

## Pull Request Process

1. Fork the repository
1. Create a feature branch
1. Make your changes
1. Ensure linting passes: `make lint`
1. Submit a pull request

### Branch Naming

Use descriptive branch names with a type prefix:

- `feature/*`: new features
- `fix/*`: bug fixes
- `docs/*`: documentation changes
- `refactor/*`: code refactoring
- `test/*`: test additions or fixes
