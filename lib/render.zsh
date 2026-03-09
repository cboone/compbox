# render.zsh — Box drawing, content filling, and differential redraw
#
# Renders the bordered popup using ANSI escape sequences. Supports full
# initial render and differential redraw for selection changes.

# Box-drawing characters (tmux rounded style)
readonly CBX_TL='╭' CBX_TR='╮' CBX_BL='╰' CBX_BR='╯'
readonly CBX_H='─' CBX_V='│'
readonly CBX_ML='├' CBX_MR='┤'
readonly CBX_ARROW_UP='▲' CBX_ARROW_DOWN='▼'
readonly CBX_ESC=$'\e'

readonly CBX_MAX_VISIBLE=16

function -cbx-render-compute-dimensions() {
  # Compute popup width from longest visible row
  local -i max_text_width=0
  local -i idx

  for (( idx=1; idx <= ${#_cbx_row_texts}; idx++ )); do
    [[ "${_cbx_row_kinds[${idx}]}" != "candidate" ]] && continue
    local text="${_cbx_row_texts[${idx}]}"
    local desc="${_cbx_row_descriptions[${idx}]}"
    local -i text_width=${(m)#text}
    if [[ -n "${desc}" ]]; then
      # Add space for description: "  desc"
      (( text_width += ${(m)#desc} + 2 ))
    fi
    (( text_width > max_text_width )) && max_text_width=${text_width}
  done

  # Add padding (1 space on each side of content)
  typeset -gi _cbx_content_width=$(( max_text_width + 2 ))

  # Clamp to terminal width (including borders), minimum 1 column
  local -i max_content=$(( COLUMNS - 2 ))
  (( max_content >= 1 && _cbx_content_width > max_content )) && _cbx_content_width=${max_content}
  (( _cbx_content_width < 1 )) && _cbx_content_width=1

  # Total width including borders
  typeset -gi _cbx_popup_width=$(( _cbx_content_width + 2 ))

  # Count selectable rows
  typeset -gi _cbx_total_candidates=0
  for (( idx=1; idx <= ${#_cbx_row_kinds}; idx++ )); do
    [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]] && (( _cbx_total_candidates++ ))
  done

  # Visible row count (content rows, not counting borders)
  local -i total_rows=${#_cbx_row_kinds}
  typeset -gi _cbx_visible_count=${total_rows}
  (( _cbx_visible_count > CBX_MAX_VISIBLE )) && _cbx_visible_count=${CBX_MAX_VISIBLE}

  # Total popup height: content rows + top border + bottom border/status
  local needs_status=0
  (( total_rows > _cbx_visible_count )) && needs_status=1
  [[ -n "${_cbx_filter_string:-}" ]] && needs_status=1

  typeset -gi _cbx_needs_status=${needs_status}
  typeset -gi _cbx_popup_height=$(( _cbx_visible_count + 2 ))
}

function -cbx-render-full() {
  local buf=""

  # Hide cursor
  buf+="${CBX_ESC}[?25l"

  local -i col=${_cbx_border_col}
  local -i content_w=${_cbx_content_width}

  # Top border
  -cbx-render-top-border buf

  # Content rows
  local -i vidx
  for (( vidx=_cbx_viewport_start; vidx < _cbx_viewport_start + _cbx_visible_count; vidx++ )); do
    if (( vidx > ${#_cbx_row_kinds} )); then
      # Empty row (beyond data)
      local -i empty_row=$(( _cbx_popup_row + 1 + vidx - _cbx_viewport_start ))
      buf+="${CBX_ESC}[${empty_row};${col}H${CBX_V}"
      -cbx-render-pad buf ${content_w}
      buf+="${CBX_V}"
    else
      local -i is_sel=0
      (( vidx == _cbx_selected_idx )) && is_sel=1
      -cbx-render-row buf ${vidx} ${is_sel}
    fi
  done

  # Bottom border / status line
  local has_below=0
  (( _cbx_viewport_start + _cbx_visible_count - 1 < ${#_cbx_row_kinds} )) && has_below=1
  if (( has_below || _cbx_needs_status )); then
    -cbx-render-status-line buf
  else
    local -i bottom_row=$(( _cbx_popup_row + 1 + _cbx_visible_count ))
    buf+="${CBX_ESC}[${bottom_row};${col}H${CBX_BL}"
    local -i hi
    for (( hi=0; hi < content_w; hi++ )); do buf+="${CBX_H}"; done
    buf+="${CBX_BR}"
  fi

  # Show cursor
  buf+="${CBX_ESC}[?25h"

  # Restore cursor to prompt position
  buf+="${CBX_ESC}[${_cbx_cursor_row};${_cbx_cursor_col}H"

  printf '%s' "${buf}" > /dev/tty
}

# Compute which candidate number the current selection represents
function -cbx-render-selected-number() {
  typeset -gi _cbx_selected_num=0
  local -i ci
  for (( ci=1; ci <= _cbx_selected_idx; ci++ )); do
    [[ "${_cbx_row_kinds[${ci}]}" == "candidate" ]] && (( _cbx_selected_num++ ))
  done
}

# Differential redraw: repaint only changed rows
function -cbx-render-update-selection() {
  local -i prev_idx="${1}"
  local -i new_idx="${2}"

  local buf=""
  buf+="${CBX_ESC}[?25l"

  # Repaint old selection (remove highlight)
  -cbx-render-row buf ${prev_idx} 0

  # Repaint new selection (add highlight)
  -cbx-render-row buf ${new_idx} 1

  # Update status line if needed
  if (( _cbx_needs_status )); then
    -cbx-render-status-line buf
  fi

  # Update top border for scroll indicator
  -cbx-render-top-border buf

  buf+="${CBX_ESC}[?25h"
  buf+="${CBX_ESC}[${_cbx_cursor_row};${_cbx_cursor_col}H"

  printf '%s' "${buf}" > /dev/tty
}

# Render a single content row into the buffer
function -cbx-render-row() {
  local -n __buf="${1}"
  local -i vidx="${2}"
  local -i is_selected="${3}"

  # Compute screen row from viewport position
  local -i screen_offset=$(( vidx - _cbx_viewport_start ))
  if (( screen_offset < 0 || screen_offset >= _cbx_visible_count )); then
    return
  fi
  local -i row=$(( _cbx_popup_row + 1 + screen_offset ))
  local -i col=${_cbx_border_col}

  if [[ "${_cbx_row_kinds[${vidx}]}" == "divider" ]]; then
    __buf+="${CBX_ESC}[${row};${col}H${CBX_ML}"
    local -i hi
    for (( hi=0; hi < _cbx_content_width; hi++ )); do __buf+="${CBX_H}"; done
    __buf+="${CBX_MR}"
    return
  fi

  if [[ "${_cbx_row_kinds[${vidx}]}" == "message" ]]; then
    local msg="${_cbx_row_texts[${vidx}]}"
    local -i msg_width=${(m)#msg}
    if (( msg_width > _cbx_content_width )); then
      msg="${msg[1,${_cbx_content_width}]}"
      msg_width=${(m)#msg}
    fi
    local -i left_pad=$(( (_cbx_content_width - msg_width) / 2 ))
    (( left_pad < 0 )) && left_pad=0
    local -i right_pad=$(( _cbx_content_width - msg_width - left_pad ))
    (( right_pad < 0 )) && right_pad=0
    __buf+="${CBX_ESC}[${row};${col}H${CBX_V}"
    local -i si
    for (( si=0; si < left_pad; si++ )); do __buf+=" "; done
    __buf+="${CBX_ESC}[2m${msg}${CBX_ESC}[0m"
    for (( si=0; si < right_pad; si++ )); do __buf+=" "; done
    __buf+="${CBX_V}"
    return
  fi

  local text="${_cbx_row_texts[${vidx}]}"
  local desc="${_cbx_row_descriptions[${vidx}]}"
  local -i text_display_width=${(m)#text}

  local -i avail=$(( _cbx_content_width - 2 ))
  if [[ -n "${desc}" ]]; then
    local -i desc_width=${(m)#desc}
    local -i desc_budget=$(( avail - 2 ))
    if (( desc_width > desc_budget )); then
      desc="${desc[1,${desc_budget}]}"
      desc_width=${desc_budget}
    fi
    avail=$(( avail - desc_width - 2 ))
  fi
  (( avail < 0 )) && avail=0
  if (( text_display_width > avail )); then
    text="${text[1,${avail}]}"
    text_display_width=${avail}
  fi

  __buf+="${CBX_ESC}[${row};${col}H${CBX_V} "

  if (( is_selected )); then
    __buf+="${CBX_ESC}[31m${text}${CBX_ESC}[0m"
  else
    __buf+="${text}"
  fi

  if [[ -n "${desc}" ]]; then
    local -i desc_width=${(m)#desc}
    local -i spaces=$(( _cbx_content_width - 2 - text_display_width - desc_width ))
    (( spaces < 1 )) && spaces=1
    local -i si
    for (( si=0; si < spaces; si++ )); do __buf+=" "; done
    if (( is_selected )); then
      __buf+="${CBX_ESC}[2;31m${desc}${CBX_ESC}[0m"
    else
      __buf+="${CBX_ESC}[2m${desc}${CBX_ESC}[0m"
    fi
    __buf+=" "
  else
    local -i pad=$(( _cbx_content_width - 1 - text_display_width ))
    local -i si
    for (( si=0; si < pad; si++ )); do __buf+=" "; done
  fi

  __buf+="${CBX_V}"
}

function -cbx-render-status-line() {
  local -n __buf="${1}"

  local -i row=$(( _cbx_popup_row + 1 + _cbx_visible_count ))
  local -i col=${_cbx_border_col}

  local has_below=0
  (( _cbx_viewport_start + _cbx_visible_count - 1 < ${#_cbx_row_kinds} )) && has_below=1

  __buf+="${CBX_ESC}[${row};${col}H${CBX_BL} "

  local status_text=""
  if [[ -n "${_cbx_filter_string:-}" ]]; then
    status_text+="filter: ${_cbx_filter_string}  "
  fi
  if (( has_below )); then
    status_text+="${CBX_ARROW_DOWN}   "
  fi

  -cbx-render-selected-number
  status_text+="[${_cbx_selected_num}/${_cbx_total_candidates}]"

  local -i status_width=${(m)#status_text}
  local -i max_status=$(( _cbx_content_width - 2 ))
  if (( status_width > max_status )); then
    status_text="${status_text[1,${max_status}]}"
    status_width=${(m)#status_text}
  fi

  local -i fill=$(( _cbx_content_width - 2 - status_width ))
  if (( fill > 0 )); then
    local -i si
    for (( si=0; si < fill; si++ )); do __buf+=" "; done
  fi
  __buf+="${status_text} ${CBX_BR}"
}

function -cbx-render-top-border() {
  local -n __buf="${1}"

  local -i row=${_cbx_popup_row}
  local -i col=${_cbx_border_col}

  local has_above=0
  (( _cbx_viewport_start > 1 )) && has_above=1

  __buf+="${CBX_ESC}[${row};${col}H"
  if (( has_above )); then
    local -i fill_width=$(( _cbx_content_width - 3 ))
    local -i left_fill=$(( fill_width / 2 ))
    local -i right_fill=$(( fill_width - left_fill ))
    __buf+="${CBX_TL}"
    local -i hi
    for (( hi=0; hi < left_fill; hi++ )); do __buf+="${CBX_H}"; done
    __buf+=" ${CBX_ARROW_UP} "
    for (( hi=0; hi < right_fill; hi++ )); do __buf+="${CBX_H}"; done
    __buf+="${CBX_TR}"
  else
    __buf+="${CBX_TL}"
    local -i hi
    for (( hi=0; hi < _cbx_content_width; hi++ )); do __buf+="${CBX_H}"; done
    __buf+="${CBX_TR}"
  fi
}

# Pad buffer with spaces
function -cbx-render-pad() {
  local -n __buf="${1}"
  local -i count="${2}"
  local -i i
  for (( i=0; i < count; i++ )); do __buf+=" "; done
}
