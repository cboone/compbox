# render.zsh — Box drawing, content filling, and differential redraw
#
# Renders the bordered popup using ANSI escape sequences. Supports full
# initial render and differential redraw for selection changes.

# Box-drawing characters (tmux rounded style)
readonly CBX_TL='╭' CBX_TR='╮' CBX_BL='╰' CBX_BR='╯'
readonly CBX_H='─' CBX_V='│'
readonly CBX_ML='├' CBX_MR='┤'
readonly CBX_ARROW_UP='▲' CBX_ARROW_DOWN='▼'

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

  # Clamp to terminal width (including borders)
  local -i max_content=$(( COLUMNS - 2 ))
  (( _cbx_content_width > max_content )) && _cbx_content_width=${max_content}

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
  buf+="\e[?25l"

  local -i row=${_cbx_popup_row}
  local -i col=${_cbx_border_col}
  local -i width=${_cbx_popup_width}
  local -i content_w=${_cbx_content_width}

  # Check if we need scroll-up indicator
  local has_above=0 has_below=0
  (( _cbx_viewport_start > 1 )) && has_above=1
  (( _cbx_viewport_start + _cbx_visible_count - 1 < ${#_cbx_row_kinds} )) && has_below=1

  # Top border
  buf+="\e[${row};${col}H"
  if (( has_above )); then
    # Insert scroll indicator centered in top border
    local -i fill_width=$(( content_w - 3 ))
    local -i left_fill=$(( fill_width / 2 ))
    local -i right_fill=$(( fill_width - left_fill ))
    buf+="${CBX_TL}"
    local -i fi
    for (( fi=0; fi < left_fill; fi++ )); do buf+="${CBX_H}"; done
    buf+=" ${CBX_ARROW_UP} "
    for (( fi=0; fi < right_fill; fi++ )); do buf+="${CBX_H}"; done
    buf+="${CBX_TR}"
  else
    buf+="${CBX_TL}"
    local -i fi
    for (( fi=0; fi < content_w; fi++ )); do buf+="${CBX_H}"; done
    buf+="${CBX_TR}"
  fi
  (( row++ ))

  # Content rows
  local -i vidx
  for (( vidx=_cbx_viewport_start; vidx < _cbx_viewport_start + _cbx_visible_count; vidx++ )); do
    buf+="\e[${row};${col}H"

    if (( vidx > ${#_cbx_row_kinds} )); then
      # Empty row
      buf+="${CBX_V}"
      -cbx-render-pad buf ${content_w}
      buf+="${CBX_V}"
    elif [[ "${_cbx_row_kinds[${vidx}]}" == "divider" ]]; then
      # Group divider
      buf+="${CBX_ML}"
      for (( fi=0; fi < content_w; fi++ )); do buf+="${CBX_H}"; done
      buf+="${CBX_MR}"
    else
      # Candidate row
      local text="${_cbx_row_texts[${vidx}]}"
      local desc="${_cbx_row_descriptions[${vidx}]}"
      local -i text_display_width=${(m)#text}

      # Truncate text if needed
      local -i avail=$(( content_w - 2 ))
      if [[ -n "${desc}" ]]; then
        avail=$(( avail - ${(m)#desc} - 2 ))
      fi
      if (( text_display_width > avail )); then
        # Simple truncation
        text="${text[1,${avail}]}"
        text_display_width=${avail}
      fi

      buf+="${CBX_V} "

      if (( vidx == _cbx_selected_idx )); then
        # Selected: red foreground
        buf+="\e[31m${text}\e[0m"
      else
        buf+="${text}"
      fi

      # Right-align description if present
      if [[ -n "${desc}" ]]; then
        local -i desc_width=${(m)#desc}
        local -i spaces=$(( content_w - 2 - text_display_width - desc_width ))
        (( spaces < 1 )) && spaces=1
        local -i si
        for (( si=0; si < spaces; si++ )); do buf+=" "; done
        if (( vidx == _cbx_selected_idx )); then
          buf+="\e[2;31m${desc}\e[0m"
        else
          buf+="\e[2m${desc}\e[0m"
        fi
        buf+=" "
      else
        # Pad remaining space
        local -i pad=$(( content_w - 1 - text_display_width ))
        local -i si
        for (( si=0; si < pad; si++ )); do buf+=" "; done
      fi

      buf+="${CBX_V}"
    fi

    (( row++ ))
  done

  # Bottom border / status line
  buf+="\e[${row};${col}H"
  if (( has_below || _cbx_needs_status )); then
    buf+="${CBX_BL} "
    local status_text=""
    if [[ -n "${_cbx_filter_string:-}" ]]; then
      status_text+="filter: ${_cbx_filter_string}  "
    fi
    if (( has_below )); then
      status_text+="${CBX_ARROW_DOWN}   "
    fi

    # Count for status
    local -i selected_num
    -cbx-render-selected-number
    status_text+="[${selected_num}/${_cbx_total_candidates}]"

    local -i status_width=${(m)#status_text}
    local -i fill=$(( content_w - 2 - status_width ))
    if (( fill > 0 )); then
      local -i si
      for (( si=0; si < fill; si++ )); do buf+=" "; done
    fi
    buf+="${status_text} ${CBX_BR}"
  else
    buf+="${CBX_BL}"
    for (( fi=0; fi < content_w; fi++ )); do buf+="${CBX_H}"; done
    buf+="${CBX_BR}"
  fi

  # Show cursor
  buf+="\e[?25h"

  # Restore cursor to prompt position
  buf+="\e[${_cbx_cursor_row};${_cbx_cursor_col}H"

  printf '%b' "${buf}" > /dev/tty
}

# Compute which candidate number the current selection represents
function -cbx-render-selected-number() {
  selected_num=0
  local -i ci
  for (( ci=1; ci <= _cbx_selected_idx; ci++ )); do
    [[ "${_cbx_row_kinds[${ci}]}" == "candidate" ]] && (( selected_num++ ))
  done
}

# Differential redraw: repaint only changed rows
function -cbx-render-update-selection() {
  local -i prev_idx="${1}"
  local -i new_idx="${2}"

  local buf=""
  buf+="\e[?25l"

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

  buf+="\e[?25h"
  buf+="\e[${_cbx_cursor_row};${_cbx_cursor_col}H"

  printf '%b' "${buf}" > /dev/tty
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
    __buf+="\e[${row};${col}H${CBX_ML}"
    local -i fi
    for (( fi=0; fi < _cbx_content_width; fi++ )); do __buf+="${CBX_H}"; done
    __buf+="${CBX_MR}"
    return
  fi

  local text="${_cbx_row_texts[${vidx}]}"
  local desc="${_cbx_row_descriptions[${vidx}]}"
  local -i text_display_width=${(m)#text}

  local -i avail=$(( _cbx_content_width - 2 ))
  if [[ -n "${desc}" ]]; then
    avail=$(( avail - ${(m)#desc} - 2 ))
  fi
  if (( text_display_width > avail )); then
    text="${text[1,${avail}]}"
    text_display_width=${avail}
  fi

  __buf+="\e[${row};${col}H${CBX_V} "

  if (( is_selected )); then
    __buf+="\e[31m${text}\e[0m"
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
      __buf+="\e[2;31m${desc}\e[0m"
    else
      __buf+="\e[2m${desc}\e[0m"
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

  __buf+="\e[${row};${col}H${CBX_BL} "

  local status_text=""
  if [[ -n "${_cbx_filter_string:-}" ]]; then
    status_text+="filter: ${_cbx_filter_string}  "
  fi
  if (( has_below )); then
    status_text+="${CBX_ARROW_DOWN}   "
  fi

  local -i selected_num
  -cbx-render-selected-number
  status_text+="[${selected_num}/${_cbx_total_candidates}]"

  local -i status_width=${(m)#status_text}
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

  __buf+="\e[${row};${col}H"
  if (( has_above )); then
    local -i fill_width=$(( _cbx_content_width - 3 ))
    local -i left_fill=$(( fill_width / 2 ))
    local -i right_fill=$(( fill_width - left_fill ))
    __buf+="${CBX_TL}"
    local -i fi
    for (( fi=0; fi < left_fill; fi++ )); do __buf+="${CBX_H}"; done
    __buf+=" ${CBX_ARROW_UP} "
    for (( fi=0; fi < right_fill; fi++ )); do __buf+="${CBX_H}"; done
    __buf+="${CBX_TR}"
  else
    __buf+="${CBX_TL}"
    local -i fi
    for (( fi=0; fi < _cbx_content_width; fi++ )); do __buf+="${CBX_H}"; done
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
