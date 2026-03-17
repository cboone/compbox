#!/usr/bin/env zsh

# Apply widget: replay a selected candidate by id using builtin compadd.
#
# -cbx-apply is the completion widget function registered via zle -C.
# It reads _CBX_APPLY_ID, resolves the candidate, restores completion
# state, and replays the originating compadd call with only the
# selected word.
#
# -cbx-apply-resolve handles id lookup and argument reconstruction.
# It is separated for testability (no builtin compadd side effect).

function -cbx-apply-resolve() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local target_id="${1}"

  # Find candidate by id (packed records start with id<TAB>).
  REPLY=""
  local entry
  for entry in "${_CBX_CANDIDATES[@]}"; do
    if [[ "${entry%%$'\t'*}" == "${target_id}" ]]; then
      REPLY="${entry}"
      break
    fi
  done

  if [[ -z "${REPLY}" ]]; then
    return 1
  fi

  # Unpack fields.
  local -a fields=()
  local rest="${REPLY}"
  while [[ "${rest}" == *$'\t'* ]]; do
    fields+=("${rest%%$'\t'*}")
    rest="${rest#*$'\t'}"
  done
  fields+=("${rest}")

  # Unescape the fields that apply-resolve uses.
  # Skip display (3), group (4), and integer fields (1, 9).
  -cbx-candidate-unescape-field "${fields[2]}"
  fields[2]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[5]}"
  fields[5]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[6]}"
  fields[6]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[7]}"
  fields[7]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[8]}"
  fields[8]="${REPLY}"

  # Set scalar return to the selected word.
  REPLY="${fields[2]}"

  # Set completion state globals for the caller to restore.
  typeset -g _CBX_RESOLVE_PREFIX="${fields[5]}"
  typeset -g _CBX_RESOLVE_SUFFIX="${fields[6]}"
  typeset -g _CBX_RESOLVE_IPREFIX="${fields[7]}"
  typeset -g _CBX_RESOLVE_ISUFFIX="${fields[8]}"

  # Look up raw args for the originating compadd call.
  local call_idx="${fields[9]}"
  if ((call_idx < 1 || call_idx > ${#_CBX_CAND_RAW_ARGS[@]})); then
    return 1
  fi
  local raw="${_CBX_CAND_RAW_ARGS[${call_idx}]}"
  if [[ -z "${raw}" ]]; then
    return 1
  fi

  # Parse raw args back into an array.
  local -a argv_raw=("${(@Q)${(z)raw}}")

  # Extract options for replay. Drop -a, -k, -d (and their values),
  # -O, -A, -D (query-mode), and -E (extra empty matches).
  # Drop positional words (everything after -- or bare words).
  typeset -ga reply=()
  local found_sep=0 skip_next=0 drop_next=0
  local arg
  for arg in "${argv_raw[@]}"; do
    if ((drop_next)); then
      drop_next=0
      continue
    fi
    if ((skip_next)); then
      reply+=("${arg}")
      skip_next=0
      continue
    fi
    if ((found_sep)); then
      continue
    fi
    case "${arg}" in
    --) found_sep=1 ;;
    -d) drop_next=1 ;;
    -d?*) ;;
    -a | -a?*) ;;
    -k | -k?*) ;;
    -[OADE]) drop_next=1 ;;
    -[OADE]?*) ;;
    -[JVXPSpsiIWrRMFxo])
      reply+=("${arg}")
      skip_next=1
      ;;
    -[JVXPSpsiIWrRMFxo]?*)
      reply+=("${arg}")
      ;;
    -*)
      reply+=("${arg}")
      ;;
    *) ;;
    esac
  done

  return 0
}

function -cbx-apply() {
  local apply_id="${_CBX_APPLY_ID:-}"
  if [[ -z "${apply_id}" ]]; then
    return 1
  fi

  if ! -cbx-apply-resolve "${apply_id}"; then
    return 1
  fi

  # Restore completion state from the originating call.
  PREFIX="${_CBX_RESOLVE_PREFIX}"
  SUFFIX="${_CBX_RESOLVE_SUFFIX}"
  IPREFIX="${_CBX_RESOLVE_IPREFIX}"
  ISUFFIX="${_CBX_RESOLVE_ISUFFIX}"

  builtin compadd "${reply[@]}" -- "${REPLY}"
}
