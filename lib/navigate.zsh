#!/usr/bin/env zsh

# Popup navigation: cyclical selection movement for the candidate list.

function -cbx-popup-next() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local count="${#_CBX_POPUP_ROWS[@]}"
  if ((count == 0)); then
    return
  fi

  ((_CBX_POPUP_SELECTED++))
  if ((_CBX_POPUP_SELECTED > count)); then
    typeset -gi _CBX_POPUP_SELECTED=1
  fi
}

function -cbx-popup-prev() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local count="${#_CBX_POPUP_ROWS[@]}"
  if ((count == 0)); then
    return
  fi

  ((_CBX_POPUP_SELECTED--))
  if ((_CBX_POPUP_SELECTED < 1)); then
    typeset -gi _CBX_POPUP_SELECTED="${count}"
  fi
}
