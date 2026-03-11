# GitHub Copilot Instructions for Compbox

For full project conventions, see AGENTS.md in the repository root.

## PR Review

- **Done plans are historical records**: Files in `docs/plans/done/` are completed plan documents preserved for reference. They may not match the final implementation. Do not flag discrepancies between done plan content and the actual codebase.
- **`make test` gracefully handles missing test files**: The test target intentionally skips when no test files exist rather than failing. This supports incremental development where tests are added phase by phase. Do not suggest making `make test` fail when zero test files are found.
