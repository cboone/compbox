#!/usr/bin/env zsh

# Screen save and restore for the popup region via tmux capture-pane.

function -cbx-screen-save() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Capture the screen rows behind the popup for later restoration.
  # Requires tmux and valid placement globals.
  # Sets _CBX_SCREEN_SAVED (array of captured lines),
  # _CBX_SCREEN_SAVE_START, and _CBX_SCREEN_SAVE_END (1-based rows).

  typeset -ga _CBX_SCREEN_SAVED=()
  typeset -gi _CBX_SCREEN_SAVE_START=0
  typeset -gi _CBX_SCREEN_SAVE_END=0

  if [[ -z "${TMUX:-}" ]]; then
    return 1
  fi

  local -i start_row="${_CBX_POPUP_ROW:-0}"
  local -i popup_h="${_CBX_POPUP_HEIGHT:-0}"
  if ((start_row < 1 || popup_h < 1)); then
    return 1
  fi

  local -i end_row=$((start_row + popup_h - 1))

  # tmux capture-pane uses 0-based row numbers.
  local -i tmux_start=$((start_row - 1))
  local -i tmux_end=$((end_row - 1))

  local captured
  captured="$(tmux capture-pane -p -e -S "${tmux_start}" -E "${tmux_end}" 2>/dev/null)" || return 1

  # Split captured output into lines, preserving empty lines.
  _CBX_SCREEN_SAVED=("${(@f)captured}")
  _CBX_SCREEN_SAVE_START="${start_row}"
  _CBX_SCREEN_SAVE_END="${end_row}"

  return 0
}

function -cbx-screen-restore() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Restore previously captured screen rows using CUP positioning.
  # Writes each saved line back to its original row.

  if ((${#_CBX_SCREEN_SAVED[@]} == 0)); then
    return 1
  fi

  if [[ ! -w /dev/tty ]]; then
    return 1
  fi

  local esc=$'\e'
  local buf="${esc}7"

  local -i start_row="${_CBX_SCREEN_SAVE_START}"
  local -i idx=0
  local line
  for line in "${_CBX_SCREEN_SAVED[@]}"; do
    ((idx++))
    local -i row=$((start_row + idx - 1))
    buf+="${esc}[${row};1H${esc}[2K${line}"
  done

  buf+="${esc}8"
  print -n "${buf}" >/dev/tty

  # Clear saved state.
  typeset -ga _CBX_SCREEN_SAVED=()
  typeset -gi _CBX_SCREEN_SAVE_START=0
  typeset -gi _CBX_SCREEN_SAVE_END=0

  return 0
}

function -cbx-screen-restore-compose() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Build the restore buffer without writing to tty. Used for testing.
  # REPLY is set to the composed restore sequence.

  REPLY=""

  if ((${#_CBX_SCREEN_SAVED[@]} == 0)); then
    return 1
  fi

  local esc=$'\e'
  local buf="${esc}7"

  local -i start_row="${_CBX_SCREEN_SAVE_START}"
  local -i idx=0
  local line
  for line in "${_CBX_SCREEN_SAVED[@]}"; do
    ((idx++))
    local -i row=$((start_row + idx - 1))
    buf+="${esc}[${row};1H${esc}[2K${line}"
  done

  buf+="${esc}8"
  REPLY="${buf}"
  return 0
}
