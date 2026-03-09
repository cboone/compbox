# position.zsh — Cursor query and popup placement
#
# Uses Device Status Report (DSR) to determine cursor position, then
# computes popup placement relative to the insertion point.

function -cbx-query-cursor() {
  # Query terminal for cursor position via DSR
  local response=""

  # Send DSR request
  print -n '\e[6n' > /dev/tty

  # Read response: ESC [ row ; col R
  IFS= read -rs -t 1 -d 'R' response < /dev/tty 2>/dev/null

  if [[ -z "${response}" ]]; then
    return 1
  fi

  # Strip leading ESC [
  response="${response#*\[}"

  # Parse row;col
  typeset -gi _cbx_cursor_row="${response%;*}"
  typeset -gi _cbx_cursor_col="${response#*;}"

  return 0
}

function -cbx-compute-position() {
  local -i menu_height="${1}"
  local -i menu_width="${2}"

  # Compute the insertion point column
  # The insertion point is where the completed word starts, which is
  # the cursor column minus the display width of PREFIX
  local -i prefix_width="${(m)#PREFIX}"
  typeset -gi _cbx_popup_col=$(( _cbx_cursor_col - prefix_width ))

  # Clamp to at least column 1 (leaving room for left border)
  (( _cbx_popup_col < 2 )) && _cbx_popup_col=2

  # The border sits one column to the left of content
  typeset -gi _cbx_border_col=$(( _cbx_popup_col - 1 ))

  # Horizontal overflow: shift left if popup exceeds COLUMNS
  local -i right_edge=$(( _cbx_border_col + menu_width - 1 ))
  if (( right_edge > COLUMNS )); then
    local -i shift=$(( right_edge - COLUMNS ))
    _cbx_border_col=$(( _cbx_border_col - shift ))
    _cbx_popup_col=$(( _cbx_popup_col - shift ))
    (( _cbx_border_col < 1 )) && _cbx_border_col=1
    (( _cbx_popup_col < 2 )) && _cbx_popup_col=2
  fi

  # Vertical placement
  local -i space_below=$(( LINES - _cbx_cursor_row ))
  local -i space_above=$(( _cbx_cursor_row - 1 ))

  if (( menu_height <= space_below )); then
    # Below the prompt line
    typeset -gi _cbx_popup_row=$(( _cbx_cursor_row + 1 ))
    typeset -g _cbx_popup_direction="below"
  elif (( menu_height <= space_above )); then
    # Above the prompt line, bottom edge adjacent
    typeset -gi _cbx_popup_row=$(( _cbx_cursor_row - menu_height ))
    typeset -g _cbx_popup_direction="above"
  elif (( space_below >= space_above )); then
    # Below, clamped
    typeset -gi _cbx_popup_row=$(( _cbx_cursor_row + 1 ))
    typeset -g _cbx_popup_direction="below"
  else
    # Above, clamped
    typeset -gi _cbx_popup_row=$(( _cbx_cursor_row - menu_height ))
    (( _cbx_popup_row < 1 )) && _cbx_popup_row=1
    typeset -g _cbx_popup_direction="above"
  fi

  return 0
}

# Compute the available height for the popup, accounting for direction
function -cbx-available-height() {
  local -i space_below=$(( LINES - _cbx_cursor_row ))
  local -i space_above=$(( _cbx_cursor_row - 1 ))

  if (( space_below >= space_above )); then
    typeset -gi _cbx_avail_height=${space_below}
  else
    typeset -gi _cbx_avail_height=${space_above}
  fi
}
