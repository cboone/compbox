# ghost.zsh — $POSTDISPLAY management and autosuggestion awareness
#
# Manages ghost text preview of the selected candidate on the command line
# and reads zsh-autosuggestions' suggestion for initial selection hinting.

function -cbx-ghost-save() {
  typeset -g _cbx_saved_postdisplay="${POSTDISPLAY}"
}

function -cbx-ghost-restore() {
  # Only restore if we actually saved a value; makes this idempotent.
  (( ! ${+_cbx_saved_postdisplay} )) && return 0
  POSTDISPLAY="${_cbx_saved_postdisplay}"
  unset _cbx_saved_postdisplay
}

# Show the selected candidate's completion suffix as dim ghost text
function -cbx-ghost-update() {
  local selected_word="${1}"
  local current_prefix="${PREFIX}"

  # Compute the suffix (what would be inserted after the current prefix)
  local ghost_text
  if [[ -n "${current_prefix}" && "${selected_word}" == "${current_prefix}"* ]]; then
    ghost_text="${selected_word#${current_prefix}}"
  else
    ghost_text="${selected_word}"
  fi

  # Set as dim text in POSTDISPLAY
  POSTDISPLAY=$'\e[2m'"${ghost_text}"$'\e[0m'
  zle -R
}

# Read the current autosuggestion and extract the next word for initial
# selection matching
function -cbx-ghost-read-suggestion() {
  setopt localoptions EXTENDED_GLOB
  local postdisplay="${POSTDISPLAY}"

  # If POSTDISPLAY is empty, no suggestion available
  if [[ -z "${postdisplay}" ]]; then
    typeset -g _cbx_suggestion_word=""
    return 1
  fi

  # Strip ANSI escape sequences to get raw suggestion text
  local clean="${postdisplay}"
  local esc=$'\e'
  clean="${clean//${esc}\[[0-9;]#m/}"

  # Extract the first word (the completion target)
  typeset -g _cbx_suggestion_word="${clean%%[[:space:]]*}"

  [[ -n "${_cbx_suggestion_word}" ]] && return 0
  return 1
}

# Find the candidate index matching the autosuggestion
function -cbx-ghost-find-suggestion-match() {
  local suggestion="${_cbx_suggestion_word}"
  [[ -z "${suggestion}" ]] && return 1

  local -i match_idx=0
  local -i match_count=0
  local -i idx

  for (( idx=1; idx <= ${#_cbx_row_texts}; idx++ )); do
    [[ "${_cbx_row_kinds[${idx}]}" != "candidate" ]] && continue

    # Normalize both for comparison
    local row_text="${_cbx_row_texts[${idx}]}"
    if [[ "${row_text}" == "${suggestion}" ]]; then
      match_idx=${idx}
      (( match_count++ ))
    fi
  done

  # Only use the match if it's unambiguous
  if (( match_count == 1 )); then
    typeset -gi _cbx_suggestion_idx=${match_idx}
    return 0
  fi

  return 1
}
