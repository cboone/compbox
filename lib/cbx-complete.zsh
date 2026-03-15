#!/usr/bin/env zsh

# Pass-through completion widget.
# Delegates to the frozen original completion widget with no interception
# or state mutation beyond lifecycle tracking.

function cbx-complete() {
  # Reset capture state for this completion invocation.
  -cbx-candidate-reset

  # Set capture gate so compadd wrapper records candidates.
  typeset -gi _CBX_IN_COMPLETE=1

  if [[ "${KEYMAP}" == "viins" ]]; then
    zle "${_CBX_ORIG_TAB_VIINS}"
  else
    zle "${_CBX_ORIG_TAB_EMACS}"
  fi

  # Clear capture gate.
  unset _CBX_IN_COMPLETE
}
