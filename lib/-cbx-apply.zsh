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
    parts=("${(@ps:\0:)meta}")
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

    # Reconstruct original compadd args and keep only option arguments.
    local -a orig_args replay_args
    orig_args=("${(@s:\x1f:)cand_meta[args]}")
    zparseopts -D -E -a replay_args \
      O: A: D: \
      o+:=replay_args e+:=replay_args q+:=replay_args Q+:=replay_args \
      r+:=replay_args R+:=replay_args S+:=replay_args n+:=replay_args \
      F+:=replay_args M+:=replay_args J+:=replay_args V+:=replay_args \
      X+:=replay_args x+:=replay_args P+:=replay_args p+:=replay_args \
      d+:=replay_args l+:=replay_args k+:=replay_args a+:=replay_args \
      W+:=replay_args f+:=replay_args i+:=replay_args U+:=replay_args \
      1+:=replay_args 2+:=replay_args -- "${orig_args[@]}"

    local word="${cand_meta[word]}"

    # Check if approximate matching was used (strip glob flags from PREFIX)
    if [[ "${PREFIX}" == *'(#'* ]]; then
      PREFIX="${PREFIX%%\(#*}"
      builtin compadd -U "${(@)replay_args}" -- "${word}"
    else
      builtin compadd "${(@)replay_args}" -- "${word}"
    fi

    return 0
  done

  return 1
}
