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

  # Always suppress built-in display and insertion in capture mode.
  # Since we no longer register matches with the completion system
  # (to prevent zle -R from displaying a match list and scrolling),
  # we suppress unconditionally to avoid beeps or retries from nmatches=0.
  compstate[list]=''
  compstate[insert]=''

  unset IN_CBX
  return ${ret}
}
