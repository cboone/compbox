# GitHub Copilot Instructions for Compbox

For full project conventions, see AGENTS.md in the repository root.

## PR Review

- **Done plans are historical records**: Files in `docs/plans/done/` are completed plan documents preserved for reference. They may not match the final implementation. Do not flag discrepancies between done plan content and the actual codebase.
- **No graceful skip logic in Makefile targets**: All development tools and test files are expected to be present. If a glob like `tests/scrut/*.md` or `tests/zunit/*.zunit` matches nothing, that is a project structure error that should fail loudly. Do not suggest adding guards, conditional skips, or fallback logic for empty globs in Makefile targets.
- **hyperfine `--command-name` sets `.command` in JSON**: When hyperfine is invoked with `--command-name <name>`, the exported JSON uses `<name>` as the `.command` field value. jq filters like `.results[] | select(.command == $name)` are correct. Do not suggest using a different JSON field or matching against the full command string.
