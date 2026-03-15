#!/usr/bin/env zsh

# compadd interception: wraps builtin compadd to capture candidates.
#
# -cbx-compadd is the internal entry point called by the compadd shim
# installed in cbx-enable. It delegates to builtin compadd first, then
# captures candidate data when inside plugin-controlled completion.

function -cbx-compadd() {
  # Always delegate to builtin for real completion bookkeeping.
  builtin compadd "${@}"
  local ret=$?

  # Skip capture outside plugin-controlled completion.
  if ((!${_CBX_IN_COMPLETE:-0})); then
    return ${ret}
  fi

  # Skip query-mode calls (-O, -A, -D).
  local arg
  for arg in "${@}"; do
    case "${arg}" in
    -O* | -A* | -D*) return ${ret} ;;
    --) break ;;
    esac
  done

  -cbx-capture-from-compadd "${@}" || true

  return ${ret}
}

function -cbx-capture-from-compadd() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Store raw args for replay.
  typeset -ga _CBX_CAND_RAW_ARGS
  _CBX_CAND_RAW_ARGS+=("${(j: :)${(q)@}}")

  local group="" display_var=""
  local -a words=()
  local found_sep=0
  local skip_next=0
  local prev=""

  # Manual option parsing: extract metadata and collect positional words.
  local arg
  for arg in "${@}"; do
    if ((skip_next)); then
      skip_next=0
      case "${prev}" in
      -d) display_var="${arg}" ;;
      -J | -V) group="${arg}" ;;
      esac
      prev=""
      continue
    fi

    if ((found_sep)); then
      words+=("${arg}")
      continue
    fi

    case "${arg}" in
    --) found_sep=1 ;;
    -d)
      skip_next=1
      prev="-d"
      ;;
    -d?*) display_var="${arg#-d}" ;;
    -J)
      skip_next=1
      prev="-J"
      ;;
    -J?*) group="${arg#-J}" ;;
    -V)
      skip_next=1
      prev="-V"
      ;;
    -V?*) group="${arg#-V}" ;;
    -[XPSpsiIWrRMFExoOADE])
      skip_next=1
      prev="${arg}"
      ;;
    -[XPSpsiIWrRMFExoOADE]?*) ;;
    -*) ;;
    *) words+=("${arg}") ;;
    esac
  done

  # Extract display strings from -d array variable.
  local -a displays=()
  if [[ -n "${display_var}" ]]; then
    if ((${(P)+display_var})); then
      displays=("${(@P)display_var}")
    fi
  fi

  # Capture completion state parameters.
  local cur_prefix="${PREFIX:-}"
  local cur_suffix="${SUFFIX:-}"
  local cur_iprefix="${IPREFIX:-}"
  local cur_isuffix="${ISUFFIX:-}"

  # Pack each word as a candidate record.
  # Increment ID in this scope (not inside $() subshell) so it persists.
  typeset -ga _CBX_CANDIDATES
  typeset -gi _CBX_CAND_NEXT_ID
  local idx=0
  local w disp packed
  for w in "${words[@]}"; do
    ((idx++))
    ((_CBX_CAND_NEXT_ID++))
    disp="${displays[${idx}]:-${w}}"
    packed="$(-cbx-candidate-pack \
      "${_CBX_CAND_NEXT_ID}" \
      "${w}" "${disp}" "${group}" \
      "${cur_prefix}" "${cur_suffix}" \
      "${cur_iprefix}" "${cur_isuffix}")"
    _CBX_CANDIDATES+=("${packed}")
  done
}
