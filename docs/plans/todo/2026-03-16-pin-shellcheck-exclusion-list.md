# Pin ShellCheck Exclusion List to Match check-zsh-scripts Skill

## Context

GitHub issue #28. The `check-zsh-scripts` skill in `cboone/cc-plugins` defines a canonical set of ShellCheck SC code exclusions for zsh scripts. Compbox's `scripts/check-zsh.zsh` was the original source of this list, but the two have diverged: compbox has 22 codes while the skill's canonical `--exclude` list has 6. The goal is to make the relationship explicit and auditable so future drift is immediately visible.

### Current divergence

| Category                        | Codes                                                                          | Count |
| ------------------------------- | ------------------------------------------------------------------------------ | ----- |
| Canonical (in both)             | SC1090, SC2039, SC2154, SC2168, SC2296, SC2299                                 | 6     |
| Project-specific (compbox only) | SC1036, SC1072, SC1073, SC2034, SC2206, SC2215                                 | 6     |
| Dead codes (never fire)         | SC1091, SC3003, SC3010, SC3030, SC3037, SC3043, SC3044, SC3046, SC3054, SC3057 | 11    |

**Why 11 codes are dead:**

- SC1091: only fires at info severity; compbox uses `--severity=warning`
- SC3xxx (10 codes): only fire with `--shell=sh`, not `--shell=bash`

**SC2034 note:** The skill classifies SC2034 as "Reliably Apply to Zsh" (should be checked), but compbox legitimately excludes it: it fires on zsh completion system variables (`PREFIX`, `SUFFIX`, etc.), test fixture globals, and indirect expansion patterns. This is a project-specific false positive.

## Changes

### 1. Restructure `SHELLCHECK_EXCLUDE` in `scripts/check-zsh.zsh` (lines 22-38)

Replace the monolithic comment block and single string with a two-tier structure using zsh arrays:

```zsh
# Canonical SC codes excluded per the check-zsh-scripts skill (cboone/cc-plugins).
# These are stable false positives when running shellcheck --shell=bash on zsh scripts.
# Reference: check-zsh-scripts skill, SKILL.md section 3c and references/tools/shellcheck.md
#   SC1090  Non-constant source: dynamic source paths
#   SC2039  Non-POSIX features: zsh builtins flagged when using --shell=bash
#   SC2154  Variable referenced but not assigned: framework variables
#   SC2168  local outside function: zsh allows local in broader contexts
#   SC2296  Parameter expansion in ${...}: zsh expansion flags
#   SC2299  Nested ${...}: zsh nested parameter expansions
readonly -a _SHELLCHECK_SKILL_CODES=(SC1090 SC2039 SC2154 SC2168 SC2296 SC2299)

# Project-specific SC codes excluded for compbox. These fire on legitimate zsh
# patterns that the skill's canonical list does not cover.
#   SC1036  "(" unexpected: zsh glob qualifiers like (N) and (.)
#   SC1072  Expected test expression: triggered by zsh glob qualifier syntax
#   SC1073  Could not parse: triggered by zsh glob qualifier syntax
#   SC2034  Variable appears unused: zsh completion system variables (PREFIX,
#           SUFFIX, IPREFIX, ISUFFIX), test fixture globals, indirect expansion
#   SC2206  Quote to prevent splitting: zsh does not split unquoted expansions
#   SC2215  Flag used as command name: zsh internal functions with - prefix
readonly -a _SHELLCHECK_PROJECT_CODES=(SC1036 SC1072 SC1073 SC2034 SC2206 SC2215)

readonly SHELLCHECK_EXCLUDE="${(j:,:)_SHELLCHECK_SKILL_CODES},${(j:,:)_SHELLCHECK_PROJECT_CODES}"
```

**Removed codes (dead, never fire with current flags):**

- SC1091: info-only, never triggers at `--severity=warning`
- SC3003, SC3010, SC3030, SC3037, SC3043, SC3044, SC3046, SC3054, SC3057: only apply to `--shell=sh`

The `${(j:,:)array}` join idiom is already used in the same file (line 59).

### 2. Update CLAUDE.md ShellCheck section (line 34)

Add a note about skill alignment:

```markdown
ShellCheck does not support `--shell=zsh`. Use `--shell=bash` with SC code exclusions for zsh false positives. See `SHELLCHECK_EXCLUDE` in `scripts/check-zsh.zsh` for the current exclusion list. The canonical codes come from the `check-zsh-scripts` skill; project-specific codes are documented inline.
```

### 3. Update AGENTS.md ShellCheck section (line 34)

Same change as CLAUDE.md.

### 4. Follow-up: file issue on `cboone/cc-plugins`

After merging, file an issue suggesting:

- Add caveat to `references/tools/shellcheck.md` that SC2034 can be a project-specific false positive (completion system variables, cross-file globals, indirect expansion)
- Note that SC3xxx codes do not fire with `--shell=bash` on shellcheck 0.11.0, so the output-filtering instruction in SKILL.md section 3c is currently a no-op

## Commits

1. `chore: restructure shellcheck exclusion list to pin skill alignment (#28)` - the `scripts/check-zsh.zsh` change
2. `docs: note skill alignment in shellcheck guidance (#28)` - the CLAUDE.md and AGENTS.md updates

## Verification

1. Run `make verify` (runs `make check-zsh` + `make test`) to confirm the restructured variable produces identical shellcheck behavior
2. Spot-check the constructed string:

   ```bash
   zsh -c 'readonly -a a=(SC1090 SC2039); readonly -a b=(SC1036 SC1072); print "${(j:,:)a},${(j:,:)b}"'
   ```

## Files to modify

- `scripts/check-zsh.zsh` (lines 22-38)
- `CLAUDE.md` (line 34)
- `AGENTS.md` (line 34)
