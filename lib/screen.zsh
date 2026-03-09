# screen.zsh — Screen save and restore via tmux capture-pane
#
# Captures the terminal rows behind the popup before rendering and
# restores them when the popup closes.

function -cbx-screen-save() {
  local -i start_row="${1}"
  local -i end_row="${2}"

  # Require a tmux session for screen save/restore
  [[ -n "${TMUX:-}" ]] || return 1

  # Convert visible terminal rows into tmux pane coordinates.
  # The visible pane is addressed with negative offsets from the bottom.
  local -i pane_height
  pane_height=$(tmux display-message -p '#{pane_height}' 2>/dev/null) || return 1
  (( pane_height > 0 )) || return 1

  local -i tmux_start=$(( start_row - pane_height - 1 ))
  local -i tmux_end=$(( end_row - pane_height - 1 ))

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
    buf+="\e[${row};1H"
    buf+="\e[2K"
    buf+="${_cbx_saved_screen[${idx}]}"
    (( row++ ))
  done

  printf '%b' "${buf}" > /dev/tty

  # Clean up
  _cbx_saved_screen=()
}
