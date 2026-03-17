#!/usr/bin/env zsh

# Flow control for completion edge cases.
#
# Determines whether the custom popup should activate or stock
# zsh completion behavior should be preserved.
#
# Uses _CBX_NMATCHES (tracked from compstate[nmatches] inside the
# compadd wrapper) rather than the candidate array length, because
# captured candidates may include non-matching words from batch
# compadd calls.

function -cbx-complete-should-popup() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local nmatches="${_CBX_NMATCHES:-0}"

  # No matches: stock behavior (zsh beeps).
  if ((nmatches == 0)); then
    return 1
  fi

  # Single match: stock behavior (zsh auto-inserts).
  if ((nmatches == 1)); then
    return 1
  fi

  # Multiple matches: custom popup path should activate.
  return 0
}
