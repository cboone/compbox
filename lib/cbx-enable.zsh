#!/usr/bin/env zsh

function cbx-enable() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  # Idempotent: skip if already enabled.
  if ((${_CBX_ENABLED:-0})); then
    return 0
  fi

  zmodload zsh/zle

  # Save original Tab widget from emacs keymap.
  # bindkey output: "^I" widget-name
  local emacs_raw
  emacs_raw="$(bindkey -M emacs '^I')"
  typeset -g _CBX_ORIG_TAB_EMACS="${emacs_raw##*\" }"

  # Save original Tab widget from viins keymap.
  local viins_raw
  viins_raw="$(bindkey -M viins '^I')"
  typeset -g _CBX_ORIG_TAB_VIINS="${viins_raw##*\" }"

  # Register the pass-through completion widget.
  zle -N cbx-complete

  # Bind Tab to our widget in both keymaps.
  bindkey -M emacs '^I' cbx-complete
  bindkey -M viins '^I' cbx-complete

  # Install compadd wrapper for candidate capture.
  function compadd() { -cbx-compadd "${@}"; }

  typeset -gi _CBX_ENABLED=1
}
