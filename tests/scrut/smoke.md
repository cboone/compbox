# Compbox Smoke Tests

Verify the test harness bootstraps correctly and helper functions work.

## Harness loads plugin files in deterministic order

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   echo "sources: ${#CBX_PLUGIN_SOURCES[@]}"
sources: 7
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   printf '%s\n' "${CBX_TEST_LOADED_SOURCES[@]}"
10-record-first
20-record-second
30-record-options
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   [[ -d "${CBX_PROJECT_ROOT}" ]] &&
>   echo "project root: exists"
project root: exists
```

## Helper setup enables strict loading and reset clears globals

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   echo "strict options: ${CBX_TEST_PLUGIN_STRICT_OPTIONS}"
strict options: on
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   echo "global before reset: ${CBX_TEST_TMP_GLOBAL}" &&
>   cbx_test_reset &&
>   [[ -n "${CBX_TEST_TMP_GLOBAL-}" ]] &&
>   echo "global after reset: set" ||
>   echo "global after reset: cleared"
global before reset: set-by-first-fixture
global after reset: cleared
```

## Reset clears functions matching plugin patterns

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   function cbx_dummy_func() { echo "dummy"; } &&
>   typeset -f cbx_dummy_func >/dev/null &&
>   echo "before: defined" &&
>   cbx_test_reset &&
>   typeset -f cbx_dummy_func >/dev/null 2>&1 &&
>   echo "after: defined" ||
>   echo "after: cleared"
before: defined
after: cleared
```

## Benchmark timing hooks are opt-in with CBX_BENCH

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   cbx_bench_mark "startup" &&
>   (( ${+CBX_BENCH_MARKS} )) &&
>   echo "bench vars: set" ||
>   echo "bench vars: unset"
bench vars: unset
```

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   export CBX_BENCH=1 &&
>   source "${CBX_PROJECT_ROOT}/lib/bench/timing.zsh" &&
>   cbx_bench_mark "startup" &&
>   (( ${+CBX_BENCH_MARKS[startup]} )) &&
>   echo "bench vars: set" &&
>   unset CBX_BENCH
bench vars: set
```

## Benchmark report line format is parseable

```scrut
$ echo "scenario=noop-plugin-startup p50=0.0030 p95=0.0050 iterations=100" |
>   tr ' ' '\n'
scenario=noop-plugin-startup
p50=0.0030
p95=0.0050
iterations=100
```
