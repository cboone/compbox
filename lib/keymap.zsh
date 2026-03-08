# keymap.zsh — Temporary keymap and handler widgets for recursive-edit
#
# Creates the _cbx_menu keymap with navigation bindings and enters
# recursive-edit for the popup interaction loop.

function -cbx-keymap-create() {
  # Create a fresh keymap based on the empty safe-to-use base
  bindkey -N _cbx_menu

  # Navigation
  bindkey -M _cbx_menu '^[[A' _cbx-widget-up         # Up arrow
  bindkey -M _cbx_menu '^[[B' _cbx-widget-down       # Down arrow
  bindkey -M _cbx_menu '^I'   _cbx-widget-next       # Tab
  bindkey -M _cbx_menu '^[[Z' _cbx-widget-prev       # Shift-Tab

  # Accept / Cancel
  bindkey -M _cbx_menu '^M'   _cbx-widget-accept     # Enter
  bindkey -M _cbx_menu '^['   _cbx-widget-cancel     # Escape

  # Backspace
  bindkey -M _cbx_menu '^?'   _cbx-widget-backspace  # Backspace
  bindkey -M _cbx_menu '^H'   _cbx-widget-backspace  # Ctrl-H

  # Bind printable characters to the filter handler
  local -i i
  for (( i=32; i <= 126; i++ )); do
    local char
    printf -v char '%b' "$(printf '\\x%02x' ${i})"
    bindkey -M _cbx_menu "${char}" _cbx-widget-char
  done
}

function -cbx-keymap-destroy() {
  bindkey -D _cbx_menu 2>/dev/null
}

function -cbx-keymap-enter() {
  # Switch to the popup keymap and enter recursive-edit
  zle -K _cbx_menu
  zle recursive-edit
  local ret=$?

  # recursive-edit returns 1 when exited via send-break
  # Determine action from state variable
  return 0
}

# Widget handlers
function _cbx-widget-up() {
  -cbx-navigate-up
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-up

function _cbx-widget-down() {
  -cbx-navigate-down
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-down

function _cbx-widget-next() {
  -cbx-navigate-next
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-next

function _cbx-widget-prev() {
  -cbx-navigate-prev
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-prev

function _cbx-widget-accept() {
  -cbx-navigate-accept
}
zle -N _cbx-widget-accept

function _cbx-widget-cancel() {
  -cbx-navigate-cancel
}
zle -N _cbx-widget-cancel

function _cbx-widget-char() {
  # The typed character is available via $KEYS
  -cbx-filter-append "${KEYS}"
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-char

function _cbx-widget-backspace() {
  -cbx-filter-backspace
  -cbx-ghost-update-from-selection
}
zle -N _cbx-widget-backspace

# Helper to update ghost text from current selection
function -cbx-ghost-update-from-selection() {
  if (( _cbx_selected_idx > 0 && _cbx_selected_idx <= ${#_cbx_row_texts} )); then
    local word
    word=$(-cbx-get-selected-word)
    -cbx-ghost-update "${word}"
  fi
}

# Look up the selected candidate's word from its id
function -cbx-get-selected-word() {
  local selected_id="${_cbx_row_ids[${_cbx_selected_idx}]}"
  local entry

  for entry in "${_cbx_compcap[@]}"; do
    local entry_id="${entry%%${_cbx_sep}*}"
    [[ "${entry_id}" == "${selected_id}" ]] || continue

    local rest="${entry#*${_cbx_sep}}"
    local meta="${rest#*${_cbx_sep}}"

    local -a parts
    parts=("${(@s:\x00:)meta}")
    local -i pidx
    for (( pidx=1; pidx < ${#parts}; pidx += 2 )); do
      if [[ "${parts[${pidx}]}" == "word" ]]; then
        print -r -- "${parts[$(( pidx + 1 ))]}"
        return 0
      fi
    done
  done

  print -r -- "${_cbx_row_texts[${_cbx_selected_idx}]}"
}
