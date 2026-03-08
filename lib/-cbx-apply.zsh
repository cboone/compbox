# -cbx-apply.zsh — Selection insertion completion widget
#
# Registered via: zle -C _cbx-apply complete-word _cbx-apply
# Looks up the selected candidate by stable id and calls builtin compadd
# with the original args + selected word to let zsh handle insertion.

function _cbx-apply() {
  local selected_id="${CBX_SELECTED_ID}"

  [[ -z "${selected_id}" ]] && return 1

  # Find the captured candidate entry by id
  local entry
  for entry in "${_cbx_compcap[@]}"; do
    local entry_id="${entry%%${_cbx_sep}*}"
    [[ "${entry_id}" == "${selected_id}" ]] || continue

    # Unpack: id \x02 display \x02 metadata
    local rest="${entry#*${_cbx_sep}}"
    local meta="${rest#*${_cbx_sep}}"

    # Parse NUL-delimited metadata into an associative array
    local -A cand_meta
    local key val
    local -a parts
    parts=("${(@s:\x00:)meta}")
    local -i pidx
    for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
      key="${parts[${pidx}]}"
      val="${parts[$(( pidx + 1 ))]}"
      cand_meta[${key}]="${val}"
    done

    # Restore captured completion state
    PREFIX="${cand_meta[PREFIX]}"
    SUFFIX="${cand_meta[SUFFIX]}"
    IPREFIX="${cand_meta[IPREFIX]}"
    ISUFFIX="${cand_meta[ISUFFIX]}"

    # Reconstruct original compadd args
    local -a orig_args
    orig_args=("${(@s:\x1f:)cand_meta[args]}")

    # Strip the word list from original args (everything after flags)
    # and replace with just the selected word
    local word="${cand_meta[word]}"

    # Check if approximate matching was used (strip glob flags from PREFIX)
    if [[ "${PREFIX}" == *'(#'* ]]; then
      PREFIX="${PREFIX%%\(#*}"
      builtin compadd -U "${(@)orig_args}" -- "${word}"
    else
      builtin compadd "${(@)orig_args}" -- "${word}"
    fi

    return 0
  done

  return 1
}
