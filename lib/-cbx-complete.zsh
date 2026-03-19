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

  local entry rest field1 field2 field3 field5
  local tab=$'\t'
  for entry in "${_CBX_CANDIDATES[@]}"; do
    # Field 1: id (integer, not escaped).
    field1="${entry%%${tab}*}"

    # Field 2: word (escaped). Field 3: display (escaped).
    rest="${entry#*${tab}}"
    field2="${rest%%${tab}*}"
    rest="${rest#*${tab}}"
    field3="${rest%%${tab}*}"

    # Field 5: prefix (escaped). Skip field 4 (group).
    rest="${rest#*${tab}}"
    rest="${rest#*${tab}}"
    field5="${rest%%${tab}*}"

    # Filter: only include words that match the captured prefix.
    # Compadd passes all candidates; only some match the prefix.
    # For path completions, PREFIX contains the full typed path
    # (e.g., "~/D") but words are bare filenames (e.g., "Desktop").
    # Use only the final path component of the prefix for matching.
    if [[ -n "${field5}" ]]; then
      -cbx-candidate-unescape-field "${field5}"
      local prefix="${REPLY}"
      prefix="${prefix##*/}"
      -cbx-candidate-unescape-field "${field2}"
      local word="${REPLY}"
      if [[ "${word}" != "${prefix}"* ]]; then
        continue
      fi
    fi

    # Unescape display field.
    -cbx-candidate-unescape-field "${field3}"

    _CBX_POPUP_ROWS+=("${field1}${tab}${REPLY}")
  done

  # Sort rows alphabetically by display text. Swap fields to
  # "display\tid" so (oi) sorts by display, then swap back.
  if ((${#_CBX_POPUP_ROWS[@]} > 1)); then
    local -a sort_tmp=()
    local r
    for r in "${_CBX_POPUP_ROWS[@]}"; do
      sort_tmp+=("${r#*${tab}}${tab}${r%%${tab}*}")
    done
    sort_tmp=("${(@oi)sort_tmp}")
    _CBX_POPUP_ROWS=()
    for r in "${sort_tmp[@]}"; do
      _CBX_POPUP_ROWS+=("${r#*${tab}}${tab}${r%%${tab}*}")
    done
  fi
}
