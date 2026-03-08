# navigate.zsh — Selection movement and scrolling
#
# Manages the popup state machine: selection index, viewport scrolling,
# and finding the next/previous selectable row.

function -cbx-navigate-init() {
  typeset -gi _cbx_selected_idx=0
  typeset -gi _cbx_viewport_start=1
  typeset -g _cbx_action=""
}

# Find and select the first selectable (candidate) row
function -cbx-navigate-first-selectable() {
  local -i idx
  for (( idx=1; idx <= ${#_cbx_row_kinds}; idx++ )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      return 0
    fi
  done
  _cbx_selected_idx=0
  return 1
}

# Move selection down, skipping dividers
function -cbx-navigate-down() {
  local -i total=${#_cbx_row_kinds}
  (( total == 0 )) && return

  local -i prev=${_cbx_selected_idx}
  local -i idx=$(( _cbx_selected_idx + 1 ))

  while (( idx <= total )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
    (( idx++ ))
  done

  # Already at bottom, no movement
  return 0
}

# Move selection up, skipping dividers
function -cbx-navigate-up() {
  local -i total=${#_cbx_row_kinds}
  (( total == 0 )) && return

  local -i prev=${_cbx_selected_idx}
  local -i idx=$(( _cbx_selected_idx - 1 ))

  while (( idx >= 1 )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
    (( idx-- ))
  done

  # Already at top, no movement
  return 0
}

# Cycle forward through selectable candidates (wraps around)
function -cbx-navigate-next() {
  local -i total=${#_cbx_row_kinds}
  (( total == 0 )) && return

  local -i prev=${_cbx_selected_idx}
  local -i idx=$(( _cbx_selected_idx + 1 ))

  # Try from current position to end
  while (( idx <= total )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
    (( idx++ ))
  done

  # Wrap to beginning
  for (( idx=1; idx < _cbx_selected_idx; idx++ )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
  done
}

# Cycle backward through selectable candidates (wraps around)
function -cbx-navigate-prev() {
  local -i total=${#_cbx_row_kinds}
  (( total == 0 )) && return

  local -i prev=${_cbx_selected_idx}
  local -i idx=$(( _cbx_selected_idx - 1 ))

  # Try from current position to beginning
  while (( idx >= 1 )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
    (( idx-- ))
  done

  # Wrap to end
  for (( idx=total; idx > _cbx_selected_idx; idx-- )); do
    if [[ "${_cbx_row_kinds[${idx}]}" == "candidate" ]]; then
      _cbx_selected_idx=${idx}
      -cbx-navigate-ensure-visible
      -cbx-render-update-selection ${prev} ${_cbx_selected_idx}
      return 0
    fi
  done
}

# Ensure the selected row is within the visible viewport, scrolling if needed
function -cbx-navigate-ensure-visible() {
  if (( _cbx_selected_idx < _cbx_viewport_start )); then
    _cbx_viewport_start=${_cbx_selected_idx}
    # Need full redraw when viewport changes
    _cbx_needs_status=1
    -cbx-render-full
  elif (( _cbx_selected_idx >= _cbx_viewport_start + _cbx_visible_count )); then
    _cbx_viewport_start=$(( _cbx_selected_idx - _cbx_visible_count + 1 ))
    _cbx_needs_status=1
    -cbx-render-full
  fi
}

function -cbx-navigate-accept() {
  _cbx_action="accept"
  zle send-break
}

function -cbx-navigate-cancel() {
  _cbx_action="cancel"
  zle send-break
}
