# Delimiter Escaping in Candidate Pack/Unpack Format

Issue: #22

## Context

The candidate store uses tab-delimited packed records (9 fields). If any
field contains a literal tab character, the record becomes ambiguous and
unpack splits on the wrong boundaries. While tabs in completion candidates
are vanishingly rare (no real-world failures observed), the format is
structurally fragile. This change adds escape/unescape handling and
field-count validation as defensive measures.

## Escaping Scheme

**Escape (during pack):** backslash first, then tab, then newline:

```zsh
REPLY="${1//\\/\\\\}"           # \ -> \\
REPLY="${REPLY//$'\t'/\\t}"     # TAB -> \t
REPLY="${REPLY//$'\n'/\\n}"     # LF  -> \n
```

**Unescape (during unpack):** placeholder approach to avoid ordering ambiguity:

```zsh
local soh=$'\x01'
REPLY="${1//\\\\/${soh}}"       # \\ -> SOH placeholder
REPLY="${REPLY//\\t/$'\t'}"     # \t -> TAB
REPLY="${REPLY//\\n/$'\n'}"     # \n -> LF
REPLY="${REPLY//${soh}/\\}"     # SOH -> \
```

The SOH placeholder ($'\x01') avoids the ambiguity where `\\t` (escaped
backslash + literal t) would otherwise be mis-parsed. SOH cannot appear in
real completion values.

Integer fields (id, call_idx) skip escaping since they cannot contain
special characters.

## Changes

### 1. `lib/-cbx-candidate-store.zsh` -- add helpers, update pack/unpack

- Add `-cbx-candidate-escape-field` function (REPLY convention, no subshell)
- Add `-cbx-candidate-unescape-field` function (REPLY convention, no subshell)
- Update `-cbx-candidate-pack`: escape 7 string fields before printf
- Update `-cbx-candidate-unpack`: validate field count (expect 9), unescape
  string fields after split

### 2. `lib/-cbx-compadd.zsh` -- escape in production packing

- Escape 5 loop-invariant fields once before the word loop (group, prefix,
  suffix, iprefix, isuffix)
- Escape 2 per-word fields inside the loop (word, display)
- This minimizes hot-path overhead: only 2 function calls per candidate

### 3. `lib/-cbx-apply.zsh` -- unescape in production unpacking

- Unescape the 5 fields that `-cbx-apply-resolve` actually uses: word (2),
  prefix (5), suffix (6), iprefix (7), isuffix (8)
- Skip display (3), group (4), and integer fields (1, 9) since apply does
  not use them

### 4. `tests/scrut/phase-02-candidate-capture.md` -- scrut snapshot tests

- Tab in word field round-trips through pack/unpack
- Newline in display field round-trips through pack/unpack
- Field-count validation rejects corrupted records

### 5. `tests/zunit/phase-02-candidate-capture.zunit` -- zunit tests

- Tab in word round-trips through pack/unpack
- Newline in display round-trips through pack/unpack
- Field-count validation returns non-zero for wrong field count
- End-to-end: tab in word round-trips through production capture and
  apply-resolve

### 6. Existing test: backslash literal preservation

The existing zunit test (line 80) packs `a\nb` and `Label\tX` (literal
backslash sequences). These round-trip correctly under the new escaping
scheme because the backslash is escaped to `\\` during pack, and the
placeholder-based unescape correctly restores it. No changes needed to this
test; it serves as a regression gate.

## Implementation Order

1. Add escape/unescape helpers to candidate-store.zsh
2. Update `-cbx-candidate-pack` to call escape
3. Update `-cbx-candidate-unpack` to call unescape + validate field count
4. Update production packing in compadd.zsh
5. Update production unpacking in apply.zsh
6. Add tests (scrut + zunit)
7. `make verify` to confirm all tests pass
8. `make bench` to check for performance regression
9. `make spell` and update cspell.json if needed

## Verification

- `make verify` (runs `make check-zsh` + `make test`)
- Existing backslash preservation test must pass unchanged
- `make bench` to compare against baseline (budget: 3ms p50 lifecycle, 5ms
  p50 completion)
