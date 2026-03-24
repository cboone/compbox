#!/usr/bin/env zsh

# Popup keymap: temporary keymap and widget handlers for the candidate menu.
#
# Creates the _cbx_menu keymap with navigation, accept, and cancel bindings.
# Widget handlers modify popup state and call send-break to exit recursive-edit.

function -cbx-popup-keymap-create() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Register widget functions.
  zle -N -- -cbx-popup-next-widget
  zle -N -- -cbx-popup-prev-widget
  zle -N -- -cbx-popup-accept-widget
  zle -N -- -cbx-popup-cancel-widget
  zle -N -- -cbx-popup-noop-widget

  # Create empty keymap.
  bindkey -N _cbx_menu

  # Navigation: next (Down, Tab) and previous (Up, Shift-Tab).
  bindkey -M _cbx_menu $'\e[B' -cbx-popup-next-widget
  bindkey -M _cbx_menu '^I' -cbx-popup-next-widget
  bindkey -M _cbx_menu $'\e[A' -cbx-popup-prev-widget
  bindkey -M _cbx_menu $'\e[Z' -cbx-popup-prev-widget

  # Accept (Enter) and cancel (Escape, Ctrl-C, Ctrl-G).
  # Bind both ^M (CR) and ^J (LF) because pty ICRNL translates \r to \n.
  bindkey -M _cbx_menu '^M' -cbx-popup-accept-widget
  bindkey -M _cbx_menu '^J' -cbx-popup-accept-widget
  bindkey -M _cbx_menu '^[' -cbx-popup-cancel-widget
  bindkey -M _cbx_menu '^C' -cbx-popup-cancel-widget
  bindkey -M _cbx_menu '^G' -cbx-popup-cancel-widget

  # Catch-all: bind printable ASCII to noop so any keypress after
  # resize triggers a widget that checks _CBX_RESIZED and dismisses.
  # Specific bindings above take precedence over this range binding.
  bindkey -M _cbx_menu -R ' '-'~' -cbx-popup-noop-widget

  # Prevent common escape sequences from triggering bare-escape cancel.
  bindkey -M _cbx_menu $'\e[C' -cbx-popup-noop-widget
  bindkey -M _cbx_menu $'\e[D' -cbx-popup-noop-widget
  bindkey -M _cbx_menu $'\eOA' -cbx-popup-prev-widget
  bindkey -M _cbx_menu $'\eOB' -cbx-popup-next-widget
  bindkey -M _cbx_menu $'\eOC' -cbx-popup-noop-widget
  bindkey -M _cbx_menu $'\eOD' -cbx-popup-noop-widget
}

function -cbx-popup-keymap-destroy() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  zle -D -- -cbx-popup-next-widget 2>/dev/null
  zle -D -- -cbx-popup-prev-widget 2>/dev/null
  zle -D -- -cbx-popup-accept-widget 2>/dev/null
  zle -D -- -cbx-popup-cancel-widget 2>/dev/null
  zle -D -- -cbx-popup-noop-widget 2>/dev/null

  bindkey -D _cbx_menu 2>/dev/null
}

# Widget handlers: called during recursive-edit from _cbx_menu keymap.
# Each checks the resize flag first; if set, dismiss immediately.

function -cbx-popup-next-widget() {
  if ((_CBX_RESIZED)); then
    zle send-break
    return
  fi
  -cbx-popup-next
  -cbx-popup-render
}

function -cbx-popup-prev-widget() {
  if ((_CBX_RESIZED)); then
    zle send-break
    return
  fi
  -cbx-popup-prev
  -cbx-popup-render
}

function -cbx-popup-accept-widget() {
  if ((_CBX_RESIZED)); then
    zle send-break
    return
  fi
  local tab=$'\t'
  local selected_row="${_CBX_POPUP_ROWS[${_CBX_POPUP_SELECTED}]}"
  typeset -g _CBX_APPLY_ID="${selected_row%%${tab}*}"
  typeset -g _CBX_POPUP_ACTION="accept"
  zle send-break
}

function -cbx-popup-cancel-widget() {
  if ((_CBX_RESIZED)); then
    zle send-break
    return
  fi
  typeset -g _CBX_POPUP_ACTION="cancel"
  zle send-break
}

function -cbx-popup-noop-widget() {
  if ((_CBX_RESIZED)); then
    zle send-break
    return
  fi
  return 0
}
