#!/usr/bin/env zsh

# Popup rendering: buffered ANSI output for the candidate list frame.
#
# -cbx-popup-render-buffer builds the ANSI string in REPLY.
# -cbx-popup-render writes the buffer to /dev/tty.
# -cbx-popup-erase-buffer and -cbx-popup-erase handle clearing.

function -cbx-popup-render-buffer() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local row_count="${#_CBX_POPUP_ROWS[@]}"
  if ((row_count == 0)); then
    typeset -gi _CBX_POPUP_RENDERED_LINES=0
    REPLY=""
    return
  fi

  # Extract display strings and calculate max width.
  local -a displays=()
  local max_width=0
  local row disp
  local tab=$'\t'
  for row in "${_CBX_POPUP_ROWS[@]}"; do
    disp="${row#*${tab}}"
    displays+=("${disp}")
    if ((${#disp} > max_width)); then
      max_width=${#disp}
    fi
  done

  # Inner width: display text + 2 spaces (left and right padding).
  local inner_width=$((max_width + 2))

  # Build horizontal border fill.
  local _empty=""
  local hfill="${(l:${inner_width}::─:)_empty}"

  # Build output buffer with ANSI sequences.
  local esc=$'\e'
  local buf=""

  # Save cursor and hide it.
  buf+="${esc}7${esc}[?25l"

  # Move to next line.
  buf+=$'\n\r'

  # Top border.
  buf+="┌${hfill}┐"

  # Rows.
  local idx=0
  local padded
  for disp in "${displays[@]}"; do
    ((idx++))
    buf+=$'\n\r'

    # Right-pad display to max_width.
    padded="${(r:${max_width}:: :)disp}"

    if ((idx == _CBX_POPUP_SELECTED)); then
      buf+="│${esc}[7m ${padded} ${esc}[0m│"
    else
      buf+="│ ${padded} │"
    fi
  done

  # Bottom border.
  buf+=$'\n\r'
  buf+="└${hfill}┘"

  # Restore cursor and show it.
  buf+="${esc}8${esc}[?25h"

  # Store line count for erase.
  typeset -gi _CBX_POPUP_RENDERED_LINES=$((row_count + 2))

  REPLY="${buf}"
}

function -cbx-popup-render() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  -cbx-popup-render-buffer
  print -n "${REPLY}" >/dev/tty
}

function -cbx-popup-erase-buffer() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local lines="${_CBX_POPUP_RENDERED_LINES:-0}"
  if ((lines == 0)); then
    REPLY=""
    return
  fi

  local esc=$'\e'
  local buf="${esc}7"

  local i
  for ((i = 0; i < lines; i++)); do
    buf+=$'\n\r'
    buf+="${esc}[2K"
  done

  buf+="${esc}8${esc}[?25h"

  REPLY="${buf}"
}

function -cbx-popup-erase() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  -cbx-popup-erase-buffer
  print -n "${REPLY}" >/dev/tty
  unset _CBX_POPUP_RENDERED_LINES
}
