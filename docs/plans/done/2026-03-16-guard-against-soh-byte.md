# Guard Against SOH Byte in Candidate Field Values

Issue: #27

## Context

The unescape function (`-cbx-candidate-unescape-field`) uses the SOH byte
(`\x01`) as a placeholder during backslash restoration. The algorithm replaces
`\\` with SOH, processes other escape sequences (`\t`, `\n`), then replaces SOH
with `\`. If a field value contains a literal SOH byte, it passes through
escaping untouched and then gets converted to a backslash during unescape,
silently corrupting data.

This is a theoretical concern (SOH never appears in completion data), but the
placeholder-based design has a structural weakness: global substitution cannot
safely add new escape sequences without ordering ambiguity.

Identified during Copilot review of PR #26 (delimiter escaping).

## Approach

Escape SOH in the escape function and rewrite the unescape function as a
single-pass character-by-character parser. This eliminates the placeholder
entirely, making the function correct for all byte values.

### Why not global substitution for unescape?

Adding a SOH escape sequence (e.g., `\1 -> SOH`) to the global-substitution
unescape creates an unsolvable ordering problem:

- If processed before `SOH -> \`: introduces SOH bytes that the final step
  converts to backslash
- If processed after `SOH -> \`: backslash restoration creates false `\X`
  matches

A character-by-character parser handles all escape sequences in one pass with no
placeholders and no ordering sensitivity.

### Performance

The unescape function runs once per field per completion selection (in
`-cbx-apply-resolve`). Fields are short strings (file paths, commands). The
character-by-character loop is negligible for this use case. The hot path
(packing in `-cbx-capture-from-compadd`, called per-candidate) uses the escape
function, which remains global-substitution-based.

## Changes

### 1. Update `-cbx-candidate-escape-field`

File: `lib/-cbx-candidate-store.zsh` (lines 5-15)

Add one line after the newline substitution:

```zsh
REPLY="${REPLY//$'\x01'/\\1}"
```

The `\1` escape sequence maps naturally to SOH (character code 1). Ordering is
safe: backslash is already escaped first, so `\1` in the original data becomes
`\\1` and won't collide.

### 2. Rewrite `-cbx-candidate-unescape-field`

File: `lib/-cbx-candidate-store.zsh` (lines 17-31)

Replace the placeholder-based body with a character-by-character parser:

- Iterate through input using zsh 1-based string indexing
- On `\`, look at next character: `\` -> backslash, `t` -> tab, `n` -> newline,
  `1` -> SOH
- Unknown escapes pass through literally (defensive)
- Return via REPLY (same convention)

### 3. Add zunit tests

File: `tests/zunit/phase-02-candidate-capture.zunit`

Three new tests following existing patterns:

- **SOH in word round-trips through pack and unpack**: pack with
  `$'before\x01after'`, unpack, verify match (pattern: lines 196-210)
- **SOH + backslash combination round-trips**: pack with `$'a\x01b\\c'`,
  unpack, verify both survive (pattern: lines 80-106)
- **SOH in word round-trips through production capture and apply-resolve**: use
  `-cbx-capture-from-compadd`, then `-cbx-apply-resolve`, verify REPLY (pattern:
  lines 238-250)

### 4. Add scrut test

File: `tests/scrut/phase-02-candidate-capture.md`

One snapshot test: SOH in word field round-trips through pack and unpack
(pattern: lines 242-255).

### 5. No changes needed

- `lib/-cbx-compadd.zsh`: calls `-cbx-candidate-escape-field`, picks up new SOH
  line automatically
- `lib/-cbx-apply.zsh`: calls `-cbx-candidate-unescape-field`, picks up new
  parser automatically

## Verification

1. `make verify` (runs `make check-zsh` and `make test`)
2. `make bench` (confirm no performance regression)
3. `make spell` (check for new dictionary words)
