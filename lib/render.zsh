#!/usr/bin/env zsh

# Popup rendering: buffered ANSI output for the candidate list frame.
#
# -cbx-popup-render-buffer builds the ANSI string in REPLY.
# -cbx-popup-render writes the buffer to /dev/tty.
# -cbx-popup-erase-buffer and -cbx-popup-erase handle clearing.
#
# When _CBX_POPUP_ROW and _CBX_POPUP_COL are set, uses absolute CUP
# positioning. Otherwise falls back to relative cursor movement.

function -cbx-popup-render-buffer() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local row_count="${#_CBX_POPUP_ROWS[@]}"
  if ((row_count == 0)); then
    typeset -gi _CBX_POPUP_RENDERED_LINES=0
    REPLY=""
    return
  fi

  # Determine how many rows to display. When the popup height has
  # been clamped by placement, only show what fits (height - 2 for
  # borders). Scrolling is added in Phase 07.
  local -i max_visible=$((${_CBX_POPUP_HEIGHT:-row_count + 2} - 2))
  if ((max_visible > row_count)); then
    max_visible="${row_count}"
  fi
  if ((max_visible < 1)); then
    max_visible=1
  fi

  # When popup width is precomputed (Phase 05 placement path),
  # clamp displayed text so rendered width stays within pane bounds.
  local -i clamp_width=0
  local -i max_display_width=0
  if (( ${+_CBX_POPUP_WIDTH} )); then
    clamp_width=1
    max_display_width=$((_CBX_POPUP_WIDTH - 4))
    if ((max_display_width < 0)); then
      max_display_width=0
    fi
  fi

  # Extract display strings and calculate max width.
  local -a displays=()
  local max_width=0
  local row disp
  local tab=$'\t'
  local -i i=0
  for row in "${_CBX_POPUP_ROWS[@]}"; do
    ((i++))
    if ((i > max_visible)); then
      break
    fi
    disp="${row#*${tab}}"
    if ((clamp_width)) && ((${#disp} > max_display_width)); then
      if ((max_display_width == 0)); then
        disp=""
      else
        disp="${disp[1,$max_display_width]}"
      fi
    fi
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

  # Check for absolute positioning mode.
  local -i use_cup=0
  local -i popup_row="${_CBX_POPUP_ROW:-0}"
  local -i popup_col="${_CBX_POPUP_COL:-0}"
  if ((popup_row > 0 && popup_col > 0)); then
    use_cup=1
  fi

  # Save cursor and hide it.
  buf+="${esc}7${esc}[?25l"

  local -i current_row="${popup_row}"

  if ((use_cup)); then
    buf+="${esc}[${current_row};${popup_col}H"
  else
    buf+=$'\n\r'
  fi

  # Top border.
  buf+="┌${hfill}┐"

  # Rows.
  local idx=0
  local padded
  for disp in "${displays[@]}"; do
    ((idx++))
    ((current_row++))

    if ((use_cup)); then
      buf+="${esc}[${current_row};${popup_col}H"
    else
      buf+=$'\n\r'
    fi

    # Right-pad display to max_width.
    padded="${(r:${max_width}:: :)disp}"

    if ((idx == _CBX_POPUP_SELECTED)); then
      buf+="│${esc}[7m ${padded} ${esc}[0m│"
    else
      buf+="│ ${padded} │"
    fi
  done

  # Bottom border.
  ((current_row++))
  if ((use_cup)); then
    buf+="${esc}[${current_row};${popup_col}H"
  else
    buf+=$'\n\r'
  fi
  buf+="└${hfill}┘"

  # Restore cursor and show it.
  buf+="${esc}8${esc}[?25h"

  # Store line count for erase.
  typeset -gi _CBX_POPUP_RENDERED_LINES=$((max_visible + 2))

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

  # Check for absolute positioning mode.
  local -i use_cup=0
  local -i popup_row="${_CBX_POPUP_ROW:-0}"
  if ((popup_row > 0)); then
    use_cup=1
  fi

  local i
  for ((i = 0; i < lines; i++)); do
    if ((use_cup)); then
      local -i row=$((popup_row + i))
      buf+="${esc}[${row};1H${esc}[2K"
    else
      buf+=$'\n\r'
      buf+="${esc}[2K"
    fi
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
