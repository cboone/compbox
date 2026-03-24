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

  # Track the actual match count from the completion system.
  # compstate[nmatches] is available inside the completion context
  # and reflects the total matches added so far across all compadd calls.
  typeset -gi _CBX_NMATCHES="${compstate[nmatches]:-0}"

  # Only capture when compadd actually added matches. builtin compadd
  # returns 0 when at least one word matched the current prefix.
  if ((ret == 0)); then
    -cbx-capture-from-compadd "${@}" || true
  fi

  # Suppress stock insertion and listing for multi-match.
  # The popup loop handles insertion; no-match and single-match
  # paths are unaffected because nmatches <= 1 at that point.
  if ((_CBX_NMATCHES > 1)); then
    compstate[insert]=''
    compstate[list]=''
  fi

  return ${ret}
}

function -cbx-capture-from-compadd() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  cbx_bench_mark "capture-start"

  # Store raw args for replay. Track the call index for source-call linkage.
  typeset -ga _CBX_CAND_RAW_ARGS
  _CBX_CAND_RAW_ARGS+=("${(j: :)${(q)@}}")
  local call_idx=${#_CBX_CAND_RAW_ARGS[@]}

  local group="" display_var=""
  local -a words=()
  local found_sep=0
  local skip_next=0
  local prev=""
  local from_arrays=0
  local from_keys=0

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
    -a*) from_arrays=1 ;;
    -k*) from_keys=1 ;;
    -*) ;;
    *) words+=("${arg}") ;;
    esac
  done

  # When -a is set, positional args are array variable names.
  # Expand them to get the actual completion words.
  if ((from_arrays)); then
    local -a expanded=()
    local arr_name
    for arr_name in "${words[@]}"; do
      if ((${(P)+arr_name})); then
        expanded+=("${(@P)arr_name}")
      fi
    done
    words=("${expanded[@]}")
  fi

  # When -k is set, positional args are associative array variable names.
  # Expand their keys to get the actual completion words.
  if ((from_keys)); then
    local -a expanded=()
    local arr_name
    for arr_name in "${words[@]}"; do
      if ((${(P)+arr_name})); then
        expanded+=("${(@kP)arr_name}")
      fi
    done
    words=("${expanded[@]}")
  fi

  cbx_bench_mark "capture-parsed"

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

  # Escape loop-invariant fields once before the word loop.
  local esc_group esc_prefix esc_suffix esc_iprefix esc_isuffix
  -cbx-candidate-escape-field "${group}"
  esc_group="${REPLY}"
  -cbx-candidate-escape-field "${cur_prefix}"
  esc_prefix="${REPLY}"
  -cbx-candidate-escape-field "${cur_suffix}"
  esc_suffix="${REPLY}"
  -cbx-candidate-escape-field "${cur_iprefix}"
  esc_iprefix="${REPLY}"
  -cbx-candidate-escape-field "${cur_isuffix}"
  esc_isuffix="${REPLY}"

  # Pack each word as a candidate record.
  # Increment ID in this scope (not inside $() subshell) so it persists.
  typeset -ga _CBX_CANDIDATES
  typeset -gi _CBX_CAND_NEXT_ID
  local idx=0
  local w disp esc_w esc_disp
  local tab=$'\t'
  for w in "${words[@]}"; do
    ((idx++))
    ((_CBX_CAND_NEXT_ID++))
    disp="${displays[${idx}]:-${w}}"
    -cbx-candidate-escape-field "${w}"
    esc_w="${REPLY}"
    -cbx-candidate-escape-field "${disp}"
    esc_disp="${REPLY}"
    _CBX_CANDIDATES+=("${_CBX_CAND_NEXT_ID}${tab}${esc_w}${tab}${esc_disp}${tab}${esc_group}${tab}${esc_prefix}${tab}${esc_suffix}${tab}${esc_iprefix}${tab}${esc_isuffix}${tab}${call_idx}")
  done

  cbx_bench_mark "capture-packed"
  cbx_bench_record_elapsed "capture-start" "capture-parsed" "capture-parse"
  cbx_bench_record_elapsed "capture-parsed" "capture-packed" "capture-pack"
}
