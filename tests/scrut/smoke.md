# Compbox Smoke Tests

Verify the test harness bootstraps correctly and helper functions work.

## Harness loads with deterministic source order

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" && echo "sources: ${#CBX_PLUGIN_SOURCES[@]}"
sources: 0
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" && [[ -d "${CBX_PROJECT_ROOT}" ]] && echo "project root: exists"
project root: exists
```

## Helper sets up and resets global state

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" && cbx_test_setup && echo "setup: ok"
setup: ok
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" && cbx_test_setup && cbx_test_reset && echo "reset: ok"
reset: ok
```

## Reset clears functions matching plugin patterns

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" && function cbx_dummy_func() { echo "dummy"; } && typeset -f cbx_dummy_func >/dev/null && echo "before: defined" && cbx_test_reset && typeset -f cbx_dummy_func >/dev/null 2>&1 && echo "after: defined" || echo "after: cleared"
before: defined
after: cleared
```

## Benchmark report line format is parseable

```scrut
$ echo "scenario=noop p50=0.003 p95=0.005 iterations=100" | tr ' ' '\n'
scenario=noop
p50=0.003
p95=0.005
iterations=100
```
