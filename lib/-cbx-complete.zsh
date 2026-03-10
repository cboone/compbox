# -cbx-complete.zsh — Hooked _main_complete replacement
#
# Wraps _main_complete to enable candidate capture mode and suppress
# zsh's built-in completion display after candidates are collected.

function -cbx-complete() {
  if (( ${+CBX_BYPASS_CAPTURE} )); then
    _cbx-orig-main-complete "$@"
    return $?
  fi

  # Enable capture mode (cbx-complete initializes _cbx_compcap once per
  # Tab press; we only set IN_CBX here so that multiple _main_complete
  # calls accumulate candidates instead of resetting them)
  typeset -g IN_CBX=1

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
