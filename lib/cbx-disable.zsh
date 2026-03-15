#!/usr/bin/env zsh

function cbx-disable() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  # Idempotent: skip if not enabled.
  if ((!${_CBX_ENABLED:-0})); then
    return 0
  fi

  zmodload zsh/zle

  # Restore original Tab bindings.
  bindkey -M emacs '^I' "${_CBX_ORIG_TAB_EMACS}"
  bindkey -M viins '^I' "${_CBX_ORIG_TAB_VIINS}"

  # Remove the widget.
  zle -D cbx-complete

  # Remove compadd wrapper.
  if ((${+functions[compadd]})); then
    unfunction compadd
  fi

  # Clean up state.
  unset _CBX_ORIG_TAB_EMACS _CBX_ORIG_TAB_VIINS _CBX_ENABLED
  unset _CBX_CAND_NEXT_ID _CBX_CANDIDATES _CBX_CAND_RAW_ARGS _CBX_IN_COMPLETE 2>/dev/null
}
