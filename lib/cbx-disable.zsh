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

  # Remove widgets.
  zle -D cbx-complete
  zle -D _cbx-apply 2>/dev/null

  # Remove compadd wrapper.
  if ((${+functions[compadd]})); then
    unfunction compadd
  fi

  # Restore any pre-existing compadd function.
  if ((${_CBX_COMPADD_HAD_FUNCTION:-0})) && ((${+functions[-cbx-orig-compadd]})); then
    functions[compadd]="${functions[-cbx-orig-compadd]}"
  fi
  if ((${+functions[-cbx-orig-compadd]})); then
    unfunction -- -cbx-orig-compadd
  fi

  # Defensive popup cleanup: destroy keymap and erase if still active.
  # Guard with || true so failures don't trigger ERR_EXIT mid-cleanup.
  if ((${_CBX_POPUP_ACTIVE:-0})); then
    -cbx-popup-keymap-destroy 2>/dev/null || true
    -cbx-popup-erase 2>/dev/null || true
    print -n $'\e[?25h' >/dev/tty 2>/dev/null || true
  fi

  # Clean up state.
  unset _CBX_ORIG_TAB_EMACS _CBX_ORIG_TAB_VIINS _CBX_ENABLED
  unset _CBX_COMPADD_HAD_FUNCTION
  unset _CBX_CAND_NEXT_ID _CBX_CANDIDATES _CBX_CAND_RAW_ARGS _CBX_IN_COMPLETE _CBX_NMATCHES 2>/dev/null
  unset _CBX_POPUP_ACTIVE _CBX_APPLY_ID 2>/dev/null
  unset _CBX_RESOLVE_PREFIX _CBX_RESOLVE_SUFFIX _CBX_RESOLVE_IPREFIX _CBX_RESOLVE_ISUFFIX 2>/dev/null
  unset _CBX_POPUP_ROWS _CBX_POPUP_SELECTED _CBX_POPUP_ACTION _CBX_POPUP_RENDERED_LINES 2>/dev/null
}
