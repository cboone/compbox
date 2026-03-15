#!/usr/bin/env zsh

# Flow control for completion edge cases.
#
# Determines whether the custom popup should activate or stock
# zsh completion behavior should be preserved.

function -cbx-complete-should-popup() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # No candidates: stock behavior (zsh shows "no matches" warning).
  if ((${#_CBX_CANDIDATES[@]} == 0)); then
    return 1
  fi

  # Single match: stock behavior (zsh auto-inserts).
  if ((${#_CBX_CANDIDATES[@]} == 1)); then
    return 1
  fi

  # Multiple matches: custom popup path should activate.
  return 0
}
