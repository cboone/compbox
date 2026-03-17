# Popup Benchmark Fixtures

## Context

Phase 04 introduced the popup interaction loop, but its benchmark plan items
were not implemented:

1. Measure open-popup latency for small and medium candidate counts.
2. Measure navigation redraw latency at p95.
3. Measure accept and cancel exit latency impact versus pass-through baseline.

The existing `pass-through-tab` fixture was changed to single-match to avoid
hanging on `recursive-edit`. No fixture currently exercises the popup path.

## Approach

Add four expect-based benchmark fixtures and integrate them into the runner.
Use popup-to-popup deltas as the primary signal (the `after` sleep needed
between Tab and the next key cancels out in these comparisons).

## New Fixtures

### `scripts/bench/fixtures/stock-completion-multi.zsh`

- Template: `stock-completion.zsh`
- Prefix: `alph` (matches `alpha-one` and `alpha-two`, no plugin loaded)
- Key sequence: `echo $tmpdir/alph\t\r`
- Purpose: stock multi-match baseline for popup delta comparison

### `scripts/bench/fixtures/popup-open-accept.zsh`

- Template: `pass-through-tab.zsh`
- Prefix: `alph` (triggers popup with 2 candidates)
- Key sequence: Tab, `after 200`, Enter (accept), Enter (execute)
- Purpose: open-popup + immediate accept latency

### `scripts/bench/fixtures/popup-navigate-accept.zsh`

- Template: `popup-open-accept.zsh`
- Key sequence: Tab, `after 200`, Down, Down, Enter (accept), Enter (execute)
- Purpose: navigation redraw overhead (delta vs popup-open-accept)
- Down arrow: `\x1b\[B` in expect, no delay between arrows (zle processes
  keystrokes sequentially within recursive-edit)

### `scripts/bench/fixtures/popup-cancel.zsh`

- Template: `popup-open-accept.zsh`
- Key sequence: Tab, `after 200`, Ctrl-G (`\x07`), `after 50`, Ctrl-U + Enter
- Purpose: cancel exit latency (delta vs popup-open-accept)
- Uses Ctrl-G instead of Escape to avoid KEYTIMEOUT delay (~400ms)
- After cancel, BUFFER is restored; Ctrl-U clears line, Enter gets clean prompt

## Runner Changes

### `scripts/bench/run.zsh`

Add budget thresholds:

```text
BUDGET_POPUP_OPEN_P50=225   # popup-open-accept vs stock-completion-multi
BUDGET_POPUP_OPEN_P95=240   # (includes ~200ms expect sleep; serves as hang detector)
BUDGET_POPUP_NAV_P50=5      # popup-navigate-accept vs popup-open-accept
BUDGET_POPUP_NAV_P95=8      # (after delay cancels out in this delta)
BUDGET_POPUP_CANCEL_P50=5   # popup-cancel vs popup-open-accept
BUDGET_POPUP_CANCEL_P95=8   # (after delay cancels out in this delta)
```

Update `require_fixtures()` with the four new files.

Update `configure_scenarios()`:

| Mode     | New scenarios added                                                            |
| -------- | ------------------------------------------------------------------------------ |
| baseline | stock-completion-multi, popup-open-accept, popup-navigate-accept, popup-cancel |
| smoke    | popup-open-accept only                                                         |
| full     | stock-completion-multi, popup-open-accept, popup-navigate-accept, popup-cancel |

Add "Popup overhead" delta reporting section after existing "Lifecycle overhead"
section, using the existing `print_delta()` function.

## Key Design Decisions

1. **Ctrl-G over Escape for cancel**: Escape (`^[`) starts multi-byte sequences
   and triggers KEYTIMEOUT (~400ms wait). Ctrl-G (`^G`) is a single byte bound
   to the same cancel widget with no KEYTIMEOUT penalty.

2. **`after` delay between Tab and next key**: The popup render path (candidate
   capture, row projection, ANSI buffer build, print to tty, keymap creation,
   recursive-edit entry) must complete before the next key arrives. Use a
   constant extracted from the fixture so it can be tuned in one place:
   - Start at `after 200` for CI safety (`ubuntu-latest` runners are slower
     than local hardware).
   - If local testing shows 200ms is unnecessarily generous, the constant
     can be reduced later without changing any budgets, since the delay
     cancels out in popup-to-popup deltas.

3. **Popup-to-popup deltas as primary signal**: The `after` sleep is constant
   across all popup fixtures and cancels out in navigate-vs-open and
   cancel-vs-open comparisons. The popup-vs-stock delta includes the sleep and
   serves mainly as a smoke test for unexpected overhead.

## CI Considerations

The `bench-smoke` job in `.github/workflows/ci.yml` runs on `ubuntu-latest`
with a 5-minute timeout. It installs `zsh`, `jq`, and `hyperfine`; `expect`
and `bc` are pre-installed on the runner image.

1. **Smoke mode adds one popup fixture** (`popup-open-accept`). With 10
   iterations and a 200ms `after` delay, the popup fixture adds ~2 seconds of
   expect sleep per run (200ms delay + overhead). Total added CI time: ~25
   seconds (including hyperfine warmup). Well within the 5-minute timeout.
2. **If the fixture hangs**, expect's `set timeout 10` kills the spawn after
   10 seconds. Hyperfine records the failure. At 10 runs, a consistent hang
   would add ~100 seconds before failing. This is noisy but stays within the
   timeout.
3. **Budget thresholds for the popup-vs-stock delta** should account for the
   `after` delay plus CI jitter. Set the open budget to `after` value + 25ms
   headroom. Popup-to-popup budgets are unaffected by the delay.
4. **`expect` and `bc` availability**: Both are pre-installed on
   `ubuntu-latest` (confirmed by the existing `pass-through-tab` fixture
   running successfully in CI). No CI workflow changes needed.

## Verification

1. `make verify` passes (fixtures do not affect tests).
2. `make bench --smoke` completes without timeouts.
3. All four new fixtures exit cleanly when run individually.
4. `make bench` produces popup overhead deltas within budget.
5. `make check-zsh` passes on all new fixture files.
6. Push to a PR branch and confirm `bench-smoke` CI job passes.
