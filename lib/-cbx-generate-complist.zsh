# -cbx-generate-complist.zsh — Candidate processing and grouping
#
# Transforms raw captured candidates into visible rows for rendering.
# Handles group dividers and builds the data structures the popup uses.

function -cbx-generate-complist() {
  local -a raw_candidates=("${_cbx_compcap[@]}")

  # Reset visible rows
  typeset -ga _cbx_visible_rows=()
  typeset -ga _cbx_row_ids=()
  typeset -ga _cbx_row_kinds=()
  typeset -ga _cbx_row_texts=()
  typeset -ga _cbx_row_descriptions=()

  (( ${#raw_candidates} )) || return 1

  # Group candidates by their group name
  local -A group_order
  local -a group_names=()
  local -a group_members
  local entry entry_id rest display meta
  local -i order_idx=0

  for entry in "${raw_candidates[@]}"; do
    entry_id="${entry%%${_cbx_sep}*}"
    rest="${entry#*${_cbx_sep}}"
    display="${rest%%${_cbx_sep}*}"
    meta="${rest#*${_cbx_sep}}"

    # Extract group from metadata
    local group=""
    local -a parts
    parts=("${(@s:\x00:)meta}")
    local -i pidx
    for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
      [[ "${parts[${pidx}]}" == "group" ]] && group="${parts[$(( pidx + 1 ))]}"
    done

    # Track group ordering
    if [[ -z "${group_order[(i)${group}]+set}" ]] || \
       (( ${group_order[(i)${group}]} == 0 )); then
      if [[ -z "${group_order[${group}]+exists}" ]]; then
        (( order_idx++ ))
        group_order[${group}]=${order_idx}
        group_names+=("${group}")
      fi
    fi

    # Extract word from metadata for display text
    local word=""
    for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
      [[ "${parts[${pidx}]}" == "word" ]] && word="${parts[$(( pidx + 1 ))]}"
    done

    # Parse description if display contains " -- " separator
    local desc=""
    if [[ "${display}" == *' -- '* ]]; then
      desc="${display#* -- }"
      display="${display%% -- *}"
    fi

    # Use word as display if display is empty
    [[ -z "${display}" ]] && display="${word}"

    # Build row data
    _cbx_visible_rows+=("${entry_id}:candidate:${display}")
    _cbx_row_ids+=("${entry_id}")
    _cbx_row_kinds+=("candidate")
    _cbx_row_texts+=("${display}")
    _cbx_row_descriptions+=("${desc}")
  done

  # Insert group dividers between different groups if multiple groups exist
  if (( ${#group_names} > 1 )); then
    local -a new_ids=() new_kinds=() new_texts=() new_descs=()
    local current_group="" prev_group=""

    for entry in "${raw_candidates[@]}"; do
      entry_id="${entry%%${_cbx_sep}*}"
      rest="${entry#*${_cbx_sep}}"
      display="${rest%%${_cbx_sep}*}"
      meta="${rest#*${_cbx_sep}}"

      local group=""
      local -a parts
      parts=("${(@s:\x00:)meta}")
      local -i pidx
      for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
        [[ "${parts[${pidx}]}" == "group" ]] && group="${parts[$(( pidx + 1 ))]}"
      done

      local word=""
      for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
        [[ "${parts[${pidx}]}" == "word" ]] && word="${parts[$(( pidx + 1 ))]}"
      done

      local desc=""
      if [[ "${display}" == *' -- '* ]]; then
        desc="${display#* -- }"
        display="${display%% -- *}"
      fi
      [[ -z "${display}" ]] && display="${word}"

      # Insert divider when group changes
      if [[ -n "${prev_group}" && "${group}" != "${prev_group}" ]]; then
        new_ids+=("0")
        new_kinds+=("divider")
        new_texts+=("")
        new_descs+=("")
      fi

      new_ids+=("${entry_id}")
      new_kinds+=("candidate")
      new_texts+=("${display}")
      new_descs+=("${desc}")

      prev_group="${group}"
    done

    _cbx_row_ids=("${new_ids[@]}")
    _cbx_row_kinds=("${new_kinds[@]}")
    _cbx_row_texts=("${new_texts[@]}")
    _cbx_row_descriptions=("${new_descs[@]}")
  fi

  return 0
}
