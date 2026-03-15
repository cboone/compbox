#!/usr/bin/env zsh
# zunit test bootstrap: strict mode and helper functions for compbox tests.
#
# NOTE: File-level strict options (ERR_EXIT) are intentionally avoided here.
# When sourced by zunit, file-level options can leak into the test runner.
# Use emulate -L zsh inside each function instead.
#
# This file is sourced via zunit's load, which runs inside a function scope.
# Use typeset -gr (global readonly) so variables are visible in test scope.
# Guard against repeated sourcing since @setup runs before each test.

if [[ -z "${CBX_ZUNIT_ROOT:-}" ]]; then
  # Project root, resolved from this bootstrap's location.
  typeset -gr CBX_ZUNIT_ROOT="${0:A:h:h}"
  typeset -gr CBX_PROJECT_ROOT="${CBX_ZUNIT_ROOT:h:h}"

  # Plugin source files loaded in deterministic order.
  # Add files here as they are created in later phases.
  typeset -ga CBX_PLUGIN_SOURCES=(
    "lib/bench/timing.zsh"
    "lib/cbx-complete.zsh"
    "lib/cbx-enable.zsh"
    "lib/cbx-disable.zsh"
    "tests/fixtures/plugins/10-record-first.zsh"
    "tests/fixtures/plugins/20-record-second.zsh"
    "tests/fixtures/plugins/30-record-options.zsh"
  )

  typeset -ga CBX_TEST_GLOBALS_TO_RESET=(
    CBX_TEST_LOADED_SOURCES
    CBX_TEST_TMP_GLOBAL
    CBX_TEST_PLUGIN_STRICT_OPTIONS
    CBX_BENCH_MARKS
    CBX_BENCH_TIMINGS
    _CBX_ENABLED
    _CBX_ORIG_TAB_EMACS
    _CBX_ORIG_TAB_VIINS
    _CBX_PLUGIN_SOURCED
    _CBX_PLUGIN_ROOT
  )
fi

function cbx_load_plugin() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  typeset -ga CBX_TEST_LOADED_SOURCES=()

  local src
  for src in "${CBX_PLUGIN_SOURCES[@]}"; do
    if [[ -f "${CBX_PROJECT_ROOT}/${src}" ]]; then
      source "${CBX_PROJECT_ROOT}/${src}"
    fi
  done
}

function cbx_reset() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Disable lifecycle if active (restores bindings and removes widget).
  if ((${_CBX_ENABLED:-0})) && ((${+functions[cbx-disable]})); then
    cbx-disable
  fi

  # Remove functions created during tests (pattern: cbx_*, cbx-*, and -cbx-*).
  local fn
  for fn in ${(k)functions[(I)(cbx_*|cbx-*|-cbx-*)]}; do
    unfunction "${fn}" 2>/dev/null
  done

  # Clear globals introduced by plugin code.
  local var
  for var in "${CBX_TEST_GLOBALS_TO_RESET[@]}"; do
    unset "${var}" 2>/dev/null
  done
}
