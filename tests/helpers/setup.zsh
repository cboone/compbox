#!/usr/bin/env zsh
# Scrut test helper: bootstrap and state management for compbox tests.
#
# NOTE: File-level strict options (ERR_EXIT) are intentionally avoided here.
# When sourced by scrut, file-level options leak into scrut's internal shell
# and break its bash-based state management. Use emulate -L zsh inside each
# function instead.

# Project root, resolved from this helper's location.
readonly CBX_TEST_ROOT="${0:A:h:h}"
readonly CBX_PROJECT_ROOT="${CBX_TEST_ROOT:h}"

# Plugin source files loaded in deterministic order.
# Add files here as they are created in later phases.
readonly -a CBX_PLUGIN_SOURCES=()

function cbx_test_setup() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  local src
  for src in "${CBX_PLUGIN_SOURCES[@]}"; do
    if [[ -f "${CBX_PROJECT_ROOT}/${src}" ]]; then
      source "${CBX_PROJECT_ROOT}/${src}"
    fi
  done
}

function cbx_test_reset() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Remove functions created during tests (pattern: cbx_* and -cbx-*).
  local fn
  for fn in ${(k)functions[(I)(cbx_*|-cbx-*)]}; do
    unfunction "${fn}" 2>/dev/null
  done

  # Clear globals introduced by plugin code.
  # Add variable cleanup here as globals are introduced in later phases.
}
