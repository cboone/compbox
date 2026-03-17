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

# Project captured candidates into a selectable visible-row list.
# Each row entry is "id<TAB>display_text" decoded through existing
# unescape helpers.

function -cbx-popup-rows-from-candidates() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  typeset -ga _CBX_POPUP_ROWS=()

  local entry rest field1 field3
  local tab=$'\t'
  for entry in "${_CBX_CANDIDATES[@]}"; do
    # Field 1: id (integer, not escaped).
    field1="${entry%%${tab}*}"

    # Field 3: display (escaped). Skip fields 1 and 2.
    rest="${entry#*${tab}}"
    rest="${rest#*${tab}}"
    field3="${rest%%${tab}*}"

    # Unescape display field.
    -cbx-candidate-unescape-field "${field3}"

    _CBX_POPUP_ROWS+=("${field1}${tab}${REPLY}")
  done
}
