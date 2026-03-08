# -cbx-complete.zsh — Hooked _main_complete replacement
#
# Wraps _main_complete to enable candidate capture mode and suppress
# zsh's built-in completion display after candidates are collected.

function -cbx-complete() {
  if (( ${+CBX_BYPASS_CAPTURE} )); then
    _cbx-orig-main-complete "$@"
    return $?
  fi

  # Enable capture mode
  typeset -g IN_CBX=1
  typeset -ga _cbx_compcap=()
  typeset -gi _cbx_next_id=0

  # Run the original _main_complete
  _cbx-orig-main-complete "$@"
  local ret=$?

  # Suppress built-in menu-select display
  if (( ${#_cbx_compcap} > 0 )); then
    compstate[list]=''
    compstate[insert]=''
  fi

  unset IN_CBX
  return ${ret}
}
