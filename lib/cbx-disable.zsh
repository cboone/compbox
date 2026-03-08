# cbx-disable.zsh — Plugin deactivation
#
# Restores original Tab binding, removes the compadd wrapper, and cleans up
# all plugin state.

function cbx-disable() {
  # Guard against disabling when not active
  (( ! ${+CBX_ENABLED} )) && return 0

  # Restore original Tab binding
  if [[ -n "${CBX_ORIG_WIDGET}" ]]; then
    # Restore the frozen copy
    zle -A ".cbx-orig-${CBX_ORIG_WIDGET}" "${CBX_ORIG_WIDGET}"

    # Rebind Tab to the original widget
    bindkey -M emacs '^I' "${CBX_ORIG_WIDGET}"
    bindkey -M viins '^I' "${CBX_ORIG_WIDGET}"

    # Remove the frozen copy
    zle -D ".cbx-orig-${CBX_ORIG_WIDGET}" 2>/dev/null
  fi

  # Remove our widgets
  zle -D cbx-complete 2>/dev/null
  zle -D _cbx-apply 2>/dev/null

  # Remove the compadd wrapper
  unfunction compadd 2>/dev/null

  # Restore the original _main_complete implementation
  if (( ${+functions[_cbx-orig-main-complete]} )); then
    functions[_main_complete]="${functions[_cbx-orig-main-complete]}"
    unfunction _cbx-orig-main-complete 2>/dev/null
  fi

  # Restore the list-grouped zstyle
  if [[ "${CBX_ORIG_LIST_GROUPED}" == "__unset__" ]]; then
    zstyle -d ':completion:*' list-grouped
  else
    zstyle ':completion:*' list-grouped "${CBX_ORIG_LIST_GROUPED}"
  fi

  # Clean up global variables
  unset CBX_ENABLED CBX_ORIG_WIDGET CBX_ORIG_LIST_GROUPED
}
