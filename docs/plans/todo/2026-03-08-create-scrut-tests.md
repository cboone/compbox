# Create Scrut Tests for Compbox Plugin

## Context

The compbox zsh plugin has no automated tests. It has linting and formatting
infrastructure (markdownlint, Prettier, cspell) but nothing that verifies
functional correctness. This plan adds a comprehensive scrut test suite
exercising every pure-logic function that can be tested outside of an
interactive terminal.

Many plugin functions depend on ZLE (zsh line editor), terminal I/O, or tmux,
making them impossible to test via CLI snapshot tests. The testable surface
consists of data-transformation and computation functions that operate on shell
arrays and variables. Stubbing out the terminal-dependent callees lets us
exercise these in isolation.

## Test Architecture

### Helper: `tests/helpers/setup.zsh`

A bootstrap script sourced at the top of every scrut code block. It:

1. Sources library files in order (constants first, then pure-logic modules)
2. Stubs ZLE and rendering functions that produce terminal output
3. Provides `cbx_add_candidate` to build packed `_cbx_compcap` entries
   (avoids command substitution which strips NUL bytes)
4. Provides `dump_rows` to print row arrays for snapshot comparison

**Source order:**

```text
lib/-cbx-compadd.zsh    # _cbx_sep, _cbx_nul constants
lib/-cbx-generate-complist.zsh
lib/render.zsh           # for compute-dimensions, selected-number, constants
lib/navigate.zsh
lib/filter.zsh
lib/ghost.zsh
lib/position.zsh
```

**Stubs (defined after sourcing, to override):**

```zsh
function zle() { : }
function -cbx-render-full() { : }
function -cbx-render-update-selection() { : }
```

**Helpers:**

```zsh
function cbx_add_candidate() {
  local id="$1" display="$2" word="$3" desc="${4:-}" group="${5:-}"
  local meta="word${_cbx_nul}${word}${_cbx_nul}desc${_cbx_nul}${desc}${_cbx_nul}group${_cbx_nul}${group}"
  _cbx_compcap+=("${id}${_cbx_sep}${display}${_cbx_sep}${meta}")
}

function dump_rows() {
  local -i i
  for (( i=1; i <= ${#_cbx_row_kinds}; i++ )); do
    print -r -- "row $i: kind=${_cbx_row_kinds[$i]} id=${_cbx_row_ids[$i]} text=${_cbx_row_texts[$i]} desc=${_cbx_row_descriptions[$i]}"
  done
}
```

### Tooling Prerequisite

`scrut` is not currently installed anywhere in this repository's local or CI
flows, so this plan must add an explicit installation path instead of assuming
the binary already exists.

- Document local setup in `CONTRIBUTING.md` with `cargo install --locked scrut`
- Add a dedicated CI `test` job that installs Rust, installs `scrut`, and then
  runs `make test`
- Keep the `Makefile` target as `scrut test --shell zsh tests/*.md` so local
  and CI execution use the same command once the dependency is installed

### Test Files (6 files, ~80 test cases)

All in `tests/`. Each fenced code block is an independent test with its own
shell invocation. Every block starts with `source "$TESTDIR/helpers/setup.zsh"`.

#### `tests/generate-complist.md` (~10 tests)

Tests `-cbx-generate-complist` (`lib/-cbx-generate-complist.zsh`).

- Empty input returns 1, produces empty arrays
- Single candidate produces one row
- Multiple candidates in same group produce no dividers
- Two groups produce one divider
- Three groups produce two dividers
- Empty display falls back to word
- Descriptions are preserved
- Row IDs match candidate IDs; divider IDs are "0"
- Large candidate set (20 items) all become rows
- Group transition from empty to non-empty inserts divider

#### `tests/navigate.md` (~17 tests)

Tests navigate functions (`lib/navigate.zsh`).

- `navigate-init` sets defaults (`selected_idx=0`, `viewport_start=1`, `action=""`)
- `first-selectable` finds first candidate row
- `first-selectable` skips leading dividers
- `first-selectable` returns 1 with no candidates
- `first-selectable` returns 1 on empty array
- `navigate-down` moves to next candidate
- `navigate-down` skips dividers
- `navigate-down` at last candidate stays put
- `navigate-up` moves to previous candidate
- `navigate-up` skips dividers
- `navigate-up` at first candidate stays put
- `navigate-next` wraps from last to first candidate
- `navigate-next` wraps correctly across dividers
- `navigate-prev` wraps from first to last candidate
- `navigate-prev` wraps correctly across dividers
- `navigate-down` on empty rows is a no-op
- `navigate-next` with single candidate stays put

#### `tests/filter.md` (~13 tests)

Tests filter functions (`lib/filter.zsh`).

- `filter-init` saves unfiltered data and clears filter string
- `filter-append` adds character and applies filter
- Filter is case-insensitive
- Filter matches on descriptions
- Filter preserves group dividers only between surviving candidates
- Filter removes dividers when only one group survives
- No matches shows "no matches" message row
- Empty filter restores all original rows
- `filter-backspace` on empty filter returns 1
- `filter-backspace` removes last character
- Filter resets viewport and selection
- Filter updates `_cbx_total_candidates` accurately
- Substring matching (not prefix-only)

#### `tests/ghost.md` (~14 tests)

Tests ghost/suggestion functions (`lib/ghost.zsh`).

- `ghost-read-suggestion` returns 1 on empty POSTDISPLAY
- `ghost-read-suggestion` extracts first word
- `ghost-read-suggestion` strips SGR style sequences (`\e[...m`)
- `ghost-read-suggestion` handles single word
- `ghost-read-suggestion` handles stacked SGR style sequences
- `ghost-find-suggestion-match` with unique match returns index
- `ghost-find-suggestion-match` returns 1 with no match
- `ghost-find-suggestion-match` returns 1 on ambiguous (2+) matches
- `ghost-find-suggestion-match` skips divider rows
- `ghost-find-suggestion-match` returns 1 on empty suggestion
- `ghost-find-suggestion-match` is case-sensitive
- `ghost-update` computes suffix by removing PREFIX from word
- `ghost-update` uses full word when PREFIX does not match
- `ghost-update` uses full word with empty PREFIX

#### `tests/position.md` (~12 tests)

Tests position functions (`lib/position.zsh`).

- Popup placed below when space is sufficient
- Popup placed above when below is insufficient
- Below preferred when both sides have equal space
- Clamped below when neither side has full room but below is larger
- Column aligned with insertion point (`cursor_col - display_width(PREFIX)`)
- Column clamped to minimum 2
- Horizontal overflow shifts popup left
- Horizontal overflow clamped to border_col >= 1
- Above placement with popup_row clamped to 1
- `available-height` returns below when equal
- `available-height` returns above when above is larger
- PREFIX with multibyte characters

#### `tests/render-dimensions.md` (~14 tests)

Tests render computation functions (`lib/render.zsh`).

- Width computed from longest row text (+ 2 padding + 2 borders)
- Width accounts for descriptions (text + desc + 2 space gap)
- Width clamped to COLUMNS
- Visible count capped at `CBX_MAX_VISIBLE` (16)
- Visible count equals row count when under 16
- Total candidates excludes dividers
- Status line needed when rows exceed visible count
- Status line needed when filter string is active
- No status line when all fit and no filter
- Popup height is `visible_count + 2`
- `render-selected-number` counts candidates up to selected index
- `render-selected-number` at first candidate is 1
- `render-selected-number` with selected index 0 is 0
- Divider rows do not contribute to width

## Files to Create

| File | Purpose |
| --- | --- |
| `tests/helpers/setup.zsh` | Test bootstrap: source libs, stubs, helpers |
| `tests/generate-complist.md` | `-cbx-generate-complist` tests |
| `tests/navigate.md` | Navigation state machine tests |
| `tests/filter.md` | Type-to-filter tests |
| `tests/ghost.md` | Ghost text and suggestion matching tests |
| `tests/position.md` | Popup positioning tests |
| `tests/render-dimensions.md` | Dimension computation tests |

## Files to Modify

| File | Change |
| --- | --- |
| `CONTRIBUTING.md` | Document local `scrut` installation with `cargo install --locked scrut` |
| `Makefile` | Add `test` target: `scrut test --shell zsh tests/*.md` |
| `.prettierignore` | Add `tests/` (scrut markdown not Prettier-compatible) |
| `.markdownlint-cli2.jsonc` | Add `tests/**` to ignores |
| `cspell.json` | Add test-related words (`scrut`, `testdir`, etc.) |
| `.github/workflows/ci.yml` | Add `test` job that installs Rust and `scrut`, then runs `make test` |

## Key Design Decisions

**NUL byte handling:** The `cbx_add_candidate` helper appends directly to
`_cbx_compcap` instead of using `print`/command substitution, because `$()`
strips NUL bytes. This matches how the real `-cbx-compadd` function works.

**Stub granularity:** Only three functions need stubs: `zle`,
`-cbx-render-full`, and `-cbx-render-update-selection`. The real
`render-compute-dimensions` and `render-selected-number` are pure computation
and do not write to `/dev/tty`, so they run as-is.

**Per-block sourcing:** Each scrut code block runs in a fresh shell. Every
block begins with `source "$TESTDIR/helpers/setup.zsh"` to bootstrap state.
This is explicit and avoids scrut prepend-file `$TESTDIR` resolution issues.

**Shell flag:** All scrut invocations use `--shell zsh` since the plugin is
zsh-only.

## Verification

1. Run `make test` to execute all scrut tests
2. Verify all ~80 tests pass
3. Run `make lint` to confirm no lint/spell regressions
4. Run `make format-check` to confirm Prettier ignores test files
5. Verify the CI workflow is syntactically valid with `actionlint`
