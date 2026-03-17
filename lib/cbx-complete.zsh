#!/usr/bin/env zsh

# Completion widget with popup interaction loop.
# Delegates to the stock completion widget, then opens a popup for
# multi-match results with cyclical navigation and accept/cancel.

function cbx-complete() {
  # Reset capture state for this completion invocation.
  -cbx-candidate-reset

  # Set capture gate so compadd wrapper records candidates.
  typeset -gi _CBX_IN_COMPLETE=1

  # Save buffer state so cancel leaves the line unchanged.
  # Stock completion may insert a common prefix for multi-match;
  # we restore the original state when the popup path activates.
  local saved_buffer="${BUFFER}"
  local saved_cursor="${CURSOR}"

  if [[ "${KEYMAP}" == "viins" ]]; then
    zle "${_CBX_ORIG_TAB_VIINS}"
  else
    zle "${_CBX_ORIG_TAB_EMACS}"
  fi

  # Clear capture gate.
  unset _CBX_IN_COMPLETE

  if -cbx-complete-should-popup; then
    # Restore buffer to pre-completion state. The compadd wrapper
    # suppresses stock insertion for multi-match, but restoring
    # here provides a safety net.
    BUFFER="${saved_buffer}"
    CURSOR="${saved_cursor}"

    typeset -gi _CBX_POPUP_ACTIVE=1

    # Project candidates to visible rows and initialize selection.
    -cbx-popup-rows-from-candidates
    typeset -gi _CBX_POPUP_SELECTED=1
    typeset -g _CBX_POPUP_ACTION=""

    -cbx-popup-render

    local saved_keymap="${KEYMAP}"
    -cbx-popup-keymap-create
    zle -K _cbx_menu

    {
      zle recursive-edit
    } always {
      # Suppress the send-break exception so execution continues to the
      # accept/cancel check below.
      TRY_BLOCK_ERROR=0
      zle -K "${saved_keymap}"
      -cbx-popup-erase
      -cbx-popup-keymap-destroy
      print -n $'\e[?25h' >/dev/tty
      typeset -gi _CBX_POPUP_ACTIVE=0
    }

    if [[ "${_CBX_POPUP_ACTION}" == "accept" ]]; then
      zle _cbx-apply
    fi
  else
    typeset -gi _CBX_POPUP_ACTIVE=0
  fi
}
