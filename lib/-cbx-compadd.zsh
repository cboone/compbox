# -cbx-compadd.zsh — compadd wrapper for candidate capture
#
# Shadows the compadd builtin. When IN_CBX is set, captures candidate metadata
# into the _cbx_compcap array. Always delegates to the real builtin to keep
# compstate bookkeeping correct.

function -cbx-compadd() {
  # Pass through when not in capture mode
  if (( ! ${+IN_CBX} )); then
    builtin compadd "$@"
    return
  fi

  # Save original args before zparseopts strips them from $@
  local -a orig_args=("$@")

  # Parse compadd flags for metadata extraction and query-mode detection.
  # zparseopts -D removes recognised options from $@, but we kept the
  # originals above so the builtin calls still get the full argument list.
  local -a opts query_flags
  zparseopts -D -E -a query_flags \
    O: A: D: \
    o+:=opts e+:=opts q+:=opts Q+:=opts r+:=opts R+:=opts S+:=opts \
    n+:=opts F+:=opts M+:=opts J+:=opts V+:=opts X+:=opts \
    x+:=opts P+:=opts p+:=opts d+:=opts l+:=opts k+:=opts \
    a+:=opts W+:=opts f+:=opts i+:=opts U+:=opts \
    1+:=opts 2+:=opts

  # Pass through immediately for query-mode calls (-O, -A, -D)
  local flag
  for flag in "${query_flags[@]}"; do
    case "${flag}" in
      -O|-A|-D)
        builtin compadd "${orig_args[@]}"
        return
        ;;
    esac
  done

  # Capture matching candidates into __hits. The -A flag puts compadd in
  # query mode (matches stored in array, not added to the completion list).
  # We pass the full original args so flags like -a, -k, -M, -U are intact.
  local -a __hits
  builtin compadd -A __hits "${orig_args[@]}"
  local ret=$?

  # Register matches with the completion system using the full original args
  builtin compadd "${orig_args[@]}"

  # If no candidates matched, nothing more to do
  (( ${#__hits} )) || return ${ret}

  # Extract group name from -J or -V flags
  local group=""
  local -i i
  for (( i=1; i <= ${#opts}; i++ )); do
    case "${opts[${i}]}" in
      -J|-V)
        (( i + 1 <= ${#opts} )) && group="${opts[$(( i + 1 ))]}"
        ;;
    esac
  done

  # Extract prefix/suffix flags
  local word_prefix="" word_suffix=""
  for (( i=1; i <= ${#opts}; i++ )); do
    case "${opts[${i}]}" in
      -P) (( i + 1 <= ${#opts} )) && word_prefix="${opts[$(( i + 1 ))]}" ;;
      -S) (( i + 1 <= ${#opts} )) && word_suffix="${opts[$(( i + 1 ))]}" ;;
    esac
  done

  # Build captured candidate entries
  local hit dscr_text
  local -i idx
  for (( idx=1; idx <= ${#__hits}; idx++ )); do
    hit="${__hits[${idx}]}"

    dscr_text=""

    # Assign a stable integer id
    (( _cbx_next_id++ ))

    # Pack metadata as NUL-delimited key-value pairs
    local meta=""
    meta+="word${_cbx_nul}${hit}"
    meta+="${_cbx_nul}desc${_cbx_nul}${dscr_text}"
    meta+="${_cbx_nul}group${_cbx_nul}${group}"
    meta+="${_cbx_nul}PREFIX${_cbx_nul}${PREFIX}"
    meta+="${_cbx_nul}SUFFIX${_cbx_nul}${SUFFIX}"
    meta+="${_cbx_nul}IPREFIX${_cbx_nul}${IPREFIX}"
    meta+="${_cbx_nul}ISUFFIX${_cbx_nul}${ISUFFIX}"
    meta+="${_cbx_nul}wpre${_cbx_nul}${word_prefix}"
    meta+="${_cbx_nul}wsuf${_cbx_nul}${word_suffix}"

    # Store the original compadd args for replay during apply
    local args_packed="${(pj:\x1f:)orig_args}"
    meta+="${_cbx_nul}args${_cbx_nul}${args_packed}"

    # Pack: id \x02 display \x02 metadata
    _cbx_compcap+=("${_cbx_next_id}${_cbx_sep}${hit}${_cbx_sep}${meta}")
  done

  return ${ret}
}

# Separator and NUL constants used in candidate packing
typeset -g _cbx_sep=$'\x02'
typeset -g _cbx_nul=$'\x00'
