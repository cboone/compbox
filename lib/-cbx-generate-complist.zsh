# -cbx-generate-complist.zsh — Candidate processing and grouping
#
# Transforms raw captured candidates into visible rows for rendering.
# Handles group dividers and builds the data structures the popup uses.

function -cbx-generate-complist() {
  local -a raw_candidates=("${_cbx_compcap[@]}")

  # Reset visible rows
  typeset -ga _cbx_row_ids=()
  typeset -ga _cbx_row_kinds=()
  typeset -ga _cbx_row_texts=()
  typeset -ga _cbx_row_descriptions=()

  (( ${#raw_candidates} )) || return 1

  local entry entry_id rest display meta
  local prev_group=""
  local -i seen_candidate=0

  for entry in "${raw_candidates[@]}"; do
    entry_id="${entry%%${_cbx_sep}*}"
    rest="${entry#*${_cbx_sep}}"
    display="${rest%%${_cbx_sep}*}"
    meta="${rest#*${_cbx_sep}}"

    # Extract word, description, and group from metadata
    local word="" desc="" group=""
    local -a parts
    parts=("${(@s:\x00:)meta}")
    local -i pidx
    for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
      case "${parts[${pidx}]}" in
        word)  word="${parts[$(( pidx + 1 ))]}" ;;
        desc)  desc="${parts[$(( pidx + 1 ))]}" ;;
        group) group="${parts[$(( pidx + 1 ))]}" ;;
      esac
    done

    # Insert divider when group changes (after at least one candidate)
    if (( seen_candidate )) && [[ "${group}" != "${prev_group}" ]]; then
      _cbx_row_ids+=("0")
      _cbx_row_kinds+=("divider")
      _cbx_row_texts+=("")
      _cbx_row_descriptions+=("")
    fi

    # Use word as display if display is empty
    [[ -z "${display}" ]] && display="${word}"

    _cbx_row_ids+=("${entry_id}")
    _cbx_row_kinds+=("candidate")
    _cbx_row_texts+=("${display}")
    _cbx_row_descriptions+=("${desc}")

    prev_group="${group}"
    seen_candidate=1
  done

  return 0
}
