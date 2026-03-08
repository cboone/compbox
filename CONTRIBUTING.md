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

### Getting Started

```bash
# Clone the repository
git clone https://github.com/cboone/compbox.git
cd compbox

# Run linter
make lint

# Check formatting
make format-check

# Run tests
make test
```

### Test Dependencies

Tests use [scrut](https://github.com/facebookincubator/scrut) for CLI
snapshot testing:

```bash
cargo install --locked scrut
```

## Code Style

- Run `make lint` before committing
- Run `make format` to format Markdown, JSON, and YAML files

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
