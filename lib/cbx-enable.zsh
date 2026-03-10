# cbx-enable.zsh — Plugin activation
#
# Saves current Tab binding, installs the compadd wrapper and completion hooks,
# and binds Tab to cbx-complete in both emacs and viins keymaps.

function cbx-enable() {
  # Guard against double-activation
  (( ${+CBX_ENABLED} )) && return 0

  # Determine the current Tab widget
  local orig_widget
  orig_widget="${$(bindkey '^I')##\"*\" }"
  # Default to expand-or-complete if not bound
  [[ -z "${orig_widget}" ]] && orig_widget="expand-or-complete"

  # Save the original widget name for later restoration
  typeset -g CBX_ORIG_WIDGET="${orig_widget}"

  # Create a frozen copy of the original widget so other plugins cannot alter it
  zle -A "${orig_widget}" ".cbx-orig-${orig_widget}"

  # Register our widgets
  zle -N cbx-complete
  zle -C _cbx-apply complete-word _cbx-apply

  # Bind Tab in emacs and viins keymaps
  bindkey -M emacs '^I' cbx-complete
  bindkey -M viins '^I' cbx-complete

  # Install the compadd wrapper function (shadows the builtin)
  function compadd() {
    -cbx-compadd "$@"
  }

  # Wrap _main_complete so candidate capture mode is enabled during completion.
  if (( ${+functions[_main_complete]} )); then
    functions[_cbx-orig-main-complete]="${functions[_main_complete]}"
    function _main_complete() {
      -cbx-complete "$@"
    }
  else
    print -r -- "compbox: _main_complete not defined; run compinit before cbx-enable" >&2
  fi

  # Save the current list-grouped zstyle value, then disable it
  local current_grouped
  if zstyle -g current_grouped ':completion:*' list-grouped; then
    typeset -g CBX_ORIG_LIST_GROUPED="${current_grouped}"
  else
    typeset -g CBX_ORIG_LIST_GROUPED="__unset__"
  fi
  zstyle ':completion:*' list-grouped false

  typeset -g CBX_ENABLED=1
}
