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

  # Parse compadd flags (same set as fzf-tab)
  local -A apre hpre dscr mats opts
  local -a query_flags
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
        builtin compadd "$@"
        return
        ;;
    esac
  done

  # Capture candidates using -A (match array) and -D (description array)
  local -a __hits __dscr
  builtin compadd -A __hits -D __dscr "$@"
  local ret=$?

  # Also call the real builtin to keep compstate correct
  builtin compadd "$@"

  # If no candidates were captured, nothing more to do
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

  # Extract -d (description array name)
  local dscr_var=""
  for (( i=1; i <= ${#opts}; i++ )); do
    case "${opts[${i}]}" in
      -d) (( i + 1 <= ${#opts} )) && dscr_var="${opts[$(( i + 1 ))]}" ;;
    esac
  done

  # Build captured candidate entries
  local hit dscr_text
  local -i idx
  for (( idx=1; idx <= ${#__hits}; idx++ )); do
    hit="${__hits[${idx}]}"

    # Get the description if available
    dscr_text=""
    if (( idx <= ${#__dscr} )); then
      dscr_text="${__dscr[${idx}]}"
    fi

    # Assign a stable integer id
    (( _cbx_next_id++ ))

    # Pack metadata as NUL-delimited key-value pairs
    local meta=""
    meta+="word${_cbx_nul}${hit}"
    meta+="${_cbx_nul}group${_cbx_nul}${group}"
    meta+="${_cbx_nul}PREFIX${_cbx_nul}${PREFIX}"
    meta+="${_cbx_nul}SUFFIX${_cbx_nul}${SUFFIX}"
    meta+="${_cbx_nul}IPREFIX${_cbx_nul}${IPREFIX}"
    meta+="${_cbx_nul}ISUFFIX${_cbx_nul}${ISUFFIX}"
    meta+="${_cbx_nul}wpre${_cbx_nul}${word_prefix}"
    meta+="${_cbx_nul}wsuf${_cbx_nul}${word_suffix}"

    # Store the original compadd args for replay during apply
    local args_packed="${(pj:\x1f:)@}"
    meta+="${_cbx_nul}args${_cbx_nul}${args_packed}"

    # Pack: id \x02 display \x02 metadata
    _cbx_compcap+=("${_cbx_next_id}${_cbx_sep}${dscr_text:-${hit}}${_cbx_sep}${meta}")
  done

  return ${ret}
}

# Separator and NUL constants used in candidate packing
typeset -g _cbx_sep=$'\x02'
typeset -g _cbx_nul=$'\x00'
