# filter.zsh — Type-to-filter logic
#
# Implements case-insensitive substring matching to narrow the candidate
# list while the popup is open. Operates on a fixed-size popup.

function -cbx-filter-init() {
  typeset -g _cbx_filter_string=""

  # Save unfiltered data for reset
  typeset -ga _cbx_unfiltered_ids=("${_cbx_row_ids[@]}")
  typeset -ga _cbx_unfiltered_kinds=("${_cbx_row_kinds[@]}")
  typeset -ga _cbx_unfiltered_texts=("${_cbx_row_texts[@]}")
  typeset -ga _cbx_unfiltered_descs=("${_cbx_row_descriptions[@]}")
}

function -cbx-filter-append() {
  local char="${1}"
  _cbx_filter_string+="${char}"
  -cbx-filter-apply
}

function -cbx-filter-backspace() {
  # No-op on empty filter
  [[ -z "${_cbx_filter_string}" ]] && return 1

  # Remove last character
  _cbx_filter_string="${_cbx_filter_string[1,-2]}"
  -cbx-filter-apply
}

function -cbx-filter-apply() {
  # Rebuild visible rows from unfiltered data
  _cbx_row_ids=()
  _cbx_row_kinds=()
  _cbx_row_texts=()
  _cbx_row_descriptions=()

  if [[ -z "${_cbx_filter_string}" ]]; then
    # No filter: restore all
    _cbx_row_ids=("${_cbx_unfiltered_ids[@]}")
    _cbx_row_kinds=("${_cbx_unfiltered_kinds[@]}")
    _cbx_row_texts=("${_cbx_unfiltered_texts[@]}")
    _cbx_row_descriptions=("${_cbx_unfiltered_descs[@]}")
  else
    # Case-insensitive substring match
    local filter_lower="${(L)_cbx_filter_string}"
    local -i idx
    local prev_kind=""

    for (( idx=1; idx <= ${#_cbx_unfiltered_kinds}; idx++ )); do
      if [[ "${_cbx_unfiltered_kinds[${idx}]}" == "divider" ]]; then
        # Track dividers but only include them if candidates follow
        prev_kind="divider"
        continue
      fi

      local text_lower="${(L)_cbx_unfiltered_texts[${idx}]}"
      local desc_lower="${(L)_cbx_unfiltered_descs[${idx}]}"

      if [[ "${text_lower}" == *"${filter_lower}"* ]] || \
         [[ -n "${desc_lower}" && "${desc_lower}" == *"${filter_lower}"* ]]; then
        # Include pending divider if this is a new group after a divider
        if [[ "${prev_kind}" == "divider" && ${#_cbx_row_kinds} -gt 0 ]]; then
          _cbx_row_ids+=("0")
          _cbx_row_kinds+=("divider")
          _cbx_row_texts+=("")
          _cbx_row_descriptions+=("")
        fi

        _cbx_row_ids+=("${_cbx_unfiltered_ids[${idx}]}")
        _cbx_row_kinds+=("candidate")
        _cbx_row_texts+=("${_cbx_unfiltered_texts[${idx}]}")
        _cbx_row_descriptions+=("${_cbx_unfiltered_descs[${idx}]}")
        prev_kind="candidate"
      fi
    done
  fi

  # Recount candidates
  _cbx_total_candidates=0
  local -i ci
  for (( ci=1; ci <= ${#_cbx_row_kinds}; ci++ )); do
    [[ "${_cbx_row_kinds[${ci}]}" == "candidate" ]] && (( _cbx_total_candidates++ ))
  done

  # Show a message when filter matches nothing
  if (( _cbx_total_candidates == 0 )) && [[ -n "${_cbx_filter_string}" ]]; then
    _cbx_row_ids=("0")
    _cbx_row_kinds=("message")
    _cbx_row_texts=("no matches")
    _cbx_row_descriptions=("")
  fi

  # Reset selection and viewport
  _cbx_viewport_start=1
  _cbx_selected_idx=0

  # Select first selectable row
  -cbx-navigate-first-selectable

  # Trigger full popup content redraw
  _cbx_needs_status=1
  -cbx-render-full
}
