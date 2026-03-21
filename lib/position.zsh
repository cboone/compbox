#!/usr/bin/env zsh

# DSR cursor probing, pane geometry, and popup placement calculations.

function -cbx-dsr-probe() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Send DSR (Device Status Report) query and parse the response.
  # Response format: ESC [ <row> ; <col> R
  # Sets _CBX_CURSOR_ROW and _CBX_CURSOR_COL (1-based).
  # Returns 1 if probe fails or response is malformed.

  if [[ ! -w /dev/tty ]] || [[ ! -r /dev/tty ]]; then
    return 1
  fi

  # Flush any pending input from tty.
  local _junk
  while read -t 0 -k 1 _junk </dev/tty 2>/dev/null; do :; done

  # Send DSR query.
  print -n $'\e[6n' >/dev/tty

  # Read response with timeout. Max 20 chars to prevent runaway reads.
  # Total budget of 2 seconds caps worst-case latency when the terminal
  # is slow or has stale data after the flush.
  local response=""
  local char
  local -i i=0
  local -F deadline=$((SECONDS + 2))
  while ((i < 20)); do
    if ((SECONDS >= deadline)); then
      return 1
    fi
    if ! read -t 1 -k 1 char </dev/tty 2>/dev/null; then
      return 1
    fi
    response+="${char}"
    if [[ "${char}" == "R" ]]; then
      break
    fi
    ((i++))
  done

  -cbx-dsr-parse "${response}"
}

function -cbx-dsr-parse() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Parse a DSR response string into row and column.
  # Input: raw response (e.g., $'\e[5;10R')
  # Sets _CBX_CURSOR_ROW and _CBX_CURSOR_COL (1-based).

  local response="${1}"

  if [[ "${response}" != *$'\e['*";"*"R" ]]; then
    return 1
  fi

  local body="${response#*$'\e['}"
  body="${body%R}"

  if [[ "${body}" != *";"* ]]; then
    return 1
  fi

  local row_str="${body%%;*}"
  local col_str="${body#*;}"

  # Validate numeric.
  if [[ "${row_str}" != <-> ]] || [[ "${col_str}" != <-> ]]; then
    return 1
  fi

  typeset -gi _CBX_CURSOR_ROW="${row_str}"
  typeset -gi _CBX_CURSOR_COL="${col_str}"
  return 0
}

function -cbx-pane-geometry() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Get pane dimensions. Accepts optional height/width arguments,
  # otherwise uses LINES/COLUMNS, falling back to tmux display-message.

  local -i pane_h="${1:-${LINES:-0}}"
  local -i pane_w="${2:-${COLUMNS:-0}}"

  if ((pane_h > 0)) && ((pane_w > 0)); then
    typeset -gi _CBX_PANE_HEIGHT="${pane_h}"
    typeset -gi _CBX_PANE_WIDTH="${pane_w}"
    return 0
  fi

  if [[ -n "${TMUX:-}" ]]; then
    local dims
    dims="$(tmux display-message -p '#{pane_height} #{pane_width}' 2>/dev/null)" || return 1
    local -a parts=(${=dims})
    if ((${#parts[@]} == 2)); then
      typeset -gi _CBX_PANE_HEIGHT="${parts[1]}"
      typeset -gi _CBX_PANE_WIDTH="${parts[2]}"
      return 0
    fi
  fi

  return 1
}

function -cbx-popup-dimensions() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Compute popup height and width from candidate rows.
  # Sets _CBX_POPUP_HEIGHT and _CBX_POPUP_WIDTH.

  local row_count="${#_CBX_POPUP_ROWS[@]}"
  if ((row_count == 0)); then
    return 1
  fi

  local max_width=0
  local row disp
  local tab=$'\t'
  for row in "${_CBX_POPUP_ROWS[@]}"; do
    disp="${row#*${tab}}"
    if ((${#disp} > max_width)); then
      max_width=${#disp}
    fi
  done

  # Height: rows + top border + bottom border.
  typeset -gi _CBX_POPUP_HEIGHT=$((row_count + 2))
  # Width: left border + left pad + content + right pad + right border.
  typeset -gi _CBX_POPUP_WIDTH=$((max_width + 4))
}

function -cbx-popup-anchor-col() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Compute the popup anchor column from the cursor position
  # and the display width of the completion prefix.
  # REPLY is set to the anchor column (1-based).

  local -i cursor_col="${_CBX_CURSOR_COL}"

  if ((${#_CBX_CANDIDATES[@]} == 0)); then
    REPLY="${cursor_col}"
    return
  fi

  # Extract the prefix from the first candidate (field 5, 1-based).
  local first="${_CBX_CANDIDATES[1]}"
  local tab=$'\t'
  local rest="${first}"
  local -i f
  for ((f = 1; f < 5; f++)); do
    rest="${rest#*${tab}}"
  done
  local esc_prefix="${rest%%${tab}*}"
  -cbx-candidate-unescape-field "${esc_prefix}"

  local -i anchor=$((cursor_col - ${#REPLY}))
  if ((anchor < 1)); then
    anchor=1
  fi

  REPLY="${anchor}"
}

function -cbx-popup-placement() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Compute popup placement from cursor position and pane geometry.
  # Requires: _CBX_CURSOR_ROW, _CBX_CURSOR_COL, _CBX_PANE_HEIGHT,
  #   _CBX_PANE_WIDTH, _CBX_POPUP_HEIGHT, _CBX_POPUP_WIDTH
  # Sets: _CBX_POPUP_ROW, _CBX_POPUP_COL, _CBX_POPUP_DIRECTION

  local -i cursor_row="${_CBX_CURSOR_ROW}"
  local -i pane_h="${_CBX_PANE_HEIGHT}"
  local -i pane_w="${_CBX_PANE_WIDTH}"
  local -i popup_h="${_CBX_POPUP_HEIGHT}"
  local -i popup_w="${_CBX_POPUP_WIDTH}"

  # Need enough width for the frame and padding.
  if ((pane_w < 4)); then
    return 1
  fi

  # Keep popup width inside pane bounds.
  if ((popup_w > pane_w)); then
    popup_w="${pane_w}"
    typeset -gi _CBX_POPUP_WIDTH="${popup_w}"
  fi

  # Below placement: popup starts on the row after the cursor.
  local -i rows_below=$((pane_h - cursor_row))
  # Above placement: popup ends on the row before the cursor.
  local -i rows_above=$((cursor_row - 1))

  # Pick the direction with more room. Clamp popup height to fit
  # rather than failing when the candidate list is taller than the
  # available space. The visible rows are truncated; scrolling is
  # added in Phase 07.
  if ((rows_below >= rows_above)); then
    typeset -g _CBX_POPUP_DIRECTION="below"
    if ((popup_h > rows_below)); then
      popup_h="${rows_below}"
      typeset -gi _CBX_POPUP_HEIGHT="${popup_h}"
    fi
    typeset -gi _CBX_POPUP_ROW=$((cursor_row + 1))
  else
    typeset -g _CBX_POPUP_DIRECTION="above"
    if ((popup_h > rows_above)); then
      popup_h="${rows_above}"
      typeset -gi _CBX_POPUP_HEIGHT="${popup_h}"
    fi
    typeset -gi _CBX_POPUP_ROW=$((cursor_row - popup_h))
  fi

  # Need at least 3 rows (top border + 1 candidate + bottom border).
  if ((popup_h < 3)); then
    return 1
  fi

  # Horizontal: anchor to completion word start, clamped to pane.
  -cbx-popup-anchor-col
  local -i col="${REPLY}"
  if ((col + popup_w - 1 > pane_w)); then
    col=$((pane_w - popup_w + 1))
  fi
  if ((col < 1)); then
    col=1
  fi
  typeset -gi _CBX_POPUP_COL="${col}"

  return 0
}
