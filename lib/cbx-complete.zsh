#!/usr/bin/env zsh

# Pass-through completion widget.
# Delegates to the frozen original completion widget with no interception
# or state mutation beyond lifecycle tracking.

function cbx-complete() {
  if [[ "${KEYMAP}" == "viins" ]]; then
    zle "${_CBX_ORIG_TAB_VIINS}"
  else
    zle "${_CBX_ORIG_TAB_EMACS}"
  fi
}
