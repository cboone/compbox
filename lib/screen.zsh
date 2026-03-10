# screen.zsh — Screen save and restore via tmux capture-pane
#
# Captures the terminal rows behind the popup before rendering and
# restores them when the popup closes.

function -cbx-screen-save() {
  local -i start_row="${1}"
  local -i end_row="${2}"

  # Require a tmux session for screen save/restore
  [[ -n "${TMUX:-}" ]] || return 1

  # Convert 1-based terminal rows to tmux capture-pane coordinates.
  # tmux uses 0-based line numbers: 0 = first visible line,
  # pane_height-1 = last visible line, negative = history/scrollback.
  local -i tmux_start=$(( start_row - 1 ))
  local -i tmux_end=$(( end_row - 1 ))

  # Capture the rows with ANSI styling preserved
  typeset -ga _cbx_saved_screen=()
  local line
  while IFS= read -r line; do
    _cbx_saved_screen+=("${line}")
  done < <(tmux capture-pane -p -e -S "${tmux_start}" -E "${tmux_end}" 2>/dev/null)

  # If nothing was captured, treat as failure so the caller can fall back
  (( ${#_cbx_saved_screen} )) || return 1

  typeset -gi _cbx_saved_start=${start_row}
  typeset -gi _cbx_saved_end=${end_row}
}

function -cbx-screen-restore() {
  (( ${#_cbx_saved_screen} )) || return 0

  local buf=""
  local -i row=${_cbx_saved_start}
  local -i idx

  for (( idx=1; idx <= ${#_cbx_saved_screen}; idx++ )); do
    # Move cursor to the start of this row and reprint preserved content
    buf+="${CBX_ESC}[${row};1H"
    buf+="${CBX_ESC}[2K"
    buf+="${_cbx_saved_screen[${idx}]}"
    (( row++ ))
  done

  printf '%s' "${buf}" > /dev/tty

  # Clean up
  _cbx_saved_screen=()
}
