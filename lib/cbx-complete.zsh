# cbx-complete.zsh — Top-level Tab widget
#
# Orchestrates the completion flow: triggers completion, captures candidates,
# determines initial selection, renders the popup, enters the navigation loop,
# and handles cleanup and insertion on exit.

function cbx-complete() {
  # Require tmux for popup rendering (screen save/restore)
  if [[ -z "${TMUX:-}" ]]; then
    typeset -g CBX_BYPASS_CAPTURE=1
    zle ".cbx-orig-${CBX_ORIG_WIDGET}"
    unset CBX_BYPASS_CAPTURE
    return 0
  fi

  # Read autosuggestion before completion modifies POSTDISPLAY
  -cbx-ghost-read-suggestion

  # Save ghost text
  -cbx-ghost-save

  # Initialize capture state once per Tab press so that multiple
  # _main_complete calls (retries by the completion system) accumulate
  # candidates instead of clearing them.
  typeset -ga _cbx_compcap=()
  typeset -gi _cbx_next_id=0

  # Run the original completion widget (with capture hooks active)
  zle ".cbx-orig-${CBX_ORIG_WIDGET}"

  # If no candidates were captured, let zsh handle it normally
  if (( ${#_cbx_compcap} == 0 )); then
    -cbx-ghost-restore
    return 0
  fi

  # Single match: auto-insert without popup
  if (( ${#_cbx_compcap} == 1 )); then
    typeset -g CBX_SELECTED_ID="${_cbx_compcap[1]%%${_cbx_sep}*}"
    zle _cbx-apply
    -cbx-ghost-restore
    unset CBX_SELECTED_ID
    return 0
  fi

  # Process candidates into visible rows
  -cbx-generate-complist || {
    -cbx-ghost-restore
    return 0
  }

  # Query cursor position via DSR
  if ! -cbx-query-cursor; then
    -cbx-ghost-restore
    typeset -g CBX_BYPASS_CAPTURE=1
    _cbx_compcap=()
    zle ".cbx-orig-${CBX_ORIG_WIDGET}"
    unset CBX_BYPASS_CAPTURE
    return 0
  fi

  # Initialize navigation state
  -cbx-navigate-init
  -cbx-filter-init

  # Determine initial selection
  if -cbx-ghost-find-suggestion-match; then
    _cbx_selected_idx=${_cbx_suggestion_idx}
  else
    -cbx-navigate-first-selectable
  fi

  # Compute popup dimensions and position
  -cbx-render-compute-dimensions

  # Clamp visible count to available height
  -cbx-available-height
  local -i max_rows=$(( _cbx_avail_height - 2 ))
  (( max_rows < 1 )) && max_rows=1
  if (( _cbx_visible_count > max_rows )); then
    _cbx_visible_count=${max_rows}
    _cbx_popup_height=$(( _cbx_visible_count + 2 ))
    # Recompute status-line flag after clamping
    if (( ${#_cbx_row_kinds} > _cbx_visible_count )); then
      _cbx_needs_status=1
    fi
  fi

  -cbx-compute-position ${_cbx_popup_height} ${_cbx_popup_width}

  # Ensure selected row is visible in initial viewport
  if (( _cbx_selected_idx > _cbx_visible_count )); then
    _cbx_viewport_start=$(( _cbx_selected_idx - _cbx_visible_count + 1 ))
  fi

  # Save screen region behind popup
  local -i screen_end=$(( _cbx_popup_row + _cbx_popup_height - 1 ))
  if ! -cbx-screen-save ${_cbx_popup_row} ${screen_end}; then
    -cbx-ghost-restore
    typeset -g CBX_BYPASS_CAPTURE=1
    _cbx_compcap=()
    zle ".cbx-orig-${CBX_ORIG_WIDGET}"
    unset CBX_BYPASS_CAPTURE
    return 0
  fi

  # Set ghost text before rendering so that zle -R clears the area
  # below the prompt first; the popup is then drawn on the cleared rows.
  if (( _cbx_selected_idx > 0 )); then
    local word
    word=$(-cbx-get-selected-word)
    -cbx-ghost-update "${word}"
  fi

  # Initial render (must come after ghost update to avoid zle -R erasure)
  -cbx-render-full

  # Set up signal handlers: SIGWINCH dismisses on resize, SIGINT cancels
  trap '-cbx-cleanup; zle reset-prompt; return 0' WINCH INT

  # Create keymap and enter navigation loop
  -cbx-keymap-create
  -cbx-keymap-enter

  # Clean up on exit (accept, cancel, or interrupt)
  -cbx-cleanup

  # Handle the result
  if [[ "${_cbx_action}" == "accept" && ${_cbx_selected_idx} -gt 0 ]]; then
    typeset -g CBX_SELECTED_ID="${_cbx_row_ids[${_cbx_selected_idx}]}"
    zle _cbx-apply
    unset CBX_SELECTED_ID
  fi

  return 0
}

function -cbx-cleanup() {
  # Restore screen
  -cbx-screen-restore

  # Restore ghost text
  -cbx-ghost-restore

  # Remove temporary keymap
  -cbx-keymap-destroy

  # Show cursor (in case it was hidden)
  printf '\e[?25h' > /dev/tty

  # Remove signal traps
  trap - WINCH INT

  # Refresh the prompt
  zle -R
}
