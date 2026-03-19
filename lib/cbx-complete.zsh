#!/usr/bin/env zsh

# Completion widget with popup interaction loop.
# Delegates to the stock completion widget, then opens a popup for
# multi-match results with cyclical navigation and accept/cancel.
#
# Phase 05 additions: DSR cursor probing, above/below placement,
# right-edge clamping, and tmux screen save/restore.

function cbx-complete() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Reset capture state for this completion invocation.
  -cbx-candidate-reset

  # Set capture gate so compadd wrapper records candidates.
  typeset -gi _CBX_IN_COMPLETE=1

  # Save buffer state so cancel leaves the line unchanged.
  # Stock completion may insert a common prefix for multi-match;
  # we restore the original state when the popup path activates.
  local saved_buffer="${BUFFER}"
  local saved_cursor="${CURSOR}"

  if [[ "${KEYMAP}" == "viins" ]]; then
    zle "${_CBX_ORIG_TAB_VIINS}"
  else
    zle "${_CBX_ORIG_TAB_EMACS}"
  fi

  # Clear capture gate.
  unset _CBX_IN_COMPLETE

  if -cbx-complete-should-popup; then
    # Restore buffer to pre-completion state. The compadd wrapper
    # suppresses stock insertion for multi-match, but restoring
    # here provides a safety net.
    BUFFER="${saved_buffer}"
    CURSOR="${saved_cursor}"

    typeset -gi _CBX_POPUP_ACTIVE=1

    # Project candidates to visible rows and initialize selection.
    -cbx-popup-rows-from-candidates
    typeset -gi _CBX_POPUP_SELECTED=1
    typeset -g _CBX_POPUP_ACTION=""

    # Probe cursor position and compute placement.
    # If any positioning precondition fails, skip popup for this
    # invocation and route back to stock completion behavior.
    if ! -cbx-dsr-probe ||
      ! -cbx-pane-geometry ||
      ! -cbx-popup-dimensions ||
      ! -cbx-popup-placement; then
      typeset -gi _CBX_POPUP_ACTIVE=0

      # Restore pre-completion state and rerun stock completion
      # without capture so this invocation preserves stock semantics.
      BUFFER="${saved_buffer}"
      CURSOR="${saved_cursor}"
      if [[ "${KEYMAP}" == "viins" ]]; then
        zle "${_CBX_ORIG_TAB_VIINS}"
      else
        zle "${_CBX_ORIG_TAB_EMACS}"
      fi

      return
    fi

    # When placement clamps popup height, keep only rows that
    # can be displayed so selection and accept stay in sync.
    local -i max_visible=$((_CBX_POPUP_HEIGHT - 2))
    if ((${#_CBX_POPUP_ROWS[@]} > max_visible)); then
      _CBX_POPUP_ROWS=("${(@)_CBX_POPUP_ROWS[1,$max_visible]}")
      if ((_CBX_POPUP_SELECTED > max_visible)); then
        typeset -gi _CBX_POPUP_SELECTED="${max_visible}"
      fi
    fi

    # Save screen behind popup (tmux only, non-fatal).
    -cbx-screen-save 2>/dev/null || true

    -cbx-popup-render

    local saved_keymap="${KEYMAP}"
    local saved_keytimeout="${KEYTIMEOUT}"
    -cbx-popup-keymap-create
    zle -K _cbx_menu
    # The popup keymap is self-contained (no user multi-key sequences),
    # so a short timeout is safe and makes Escape feel instant.
    KEYTIMEOUT=1

    # TRAPWINCH sets a flag that popup widgets check on the next
    # keypress. This is the only reliable mechanism: zle builtins
    # cannot be called from signal handlers, zle-line-pre-redraw
    # does not fire after SIGWINCH during recursive-edit, and
    # reading from /dev/tty inside a zle widget corrupts input
    # state. The popup dismisses on the next keypress after resize.
    typeset -gi _CBX_RESIZED=0
    local saved_trapwinch=""
    if ((${+functions[TRAPWINCH]})); then
      saved_trapwinch="${functions[TRAPWINCH]}"
    fi
    functions[TRAPWINCH]='typeset -gi _CBX_RESIZED=1'

    {
      zle recursive-edit
    } always {
      # Suppress the send-break exception so execution continues to
      # the accept/cancel check below.
      TRY_BLOCK_ERROR=0
      KEYTIMEOUT="${saved_keytimeout}"
      zle -K "${saved_keymap}"

      # Restore TRAPWINCH and clear resize flag.
      if [[ -n "${saved_trapwinch}" ]]; then
        functions[TRAPWINCH]="${saved_trapwinch}"
      else
        unfunction TRAPWINCH 2>/dev/null
      fi
      unset _CBX_RESIZED 2>/dev/null

      # Detect resize: if geometry changed since placement, the saved
      # CUP positions and screen content are stale. Skip position-
      # dependent cleanup and let reset-prompt redraw everything.
      if ((LINES != _CBX_PANE_HEIGHT || COLUMNS != _CBX_PANE_WIDTH)); then
        typeset -ga _CBX_SCREEN_SAVED=()
        zle reset-prompt 2>/dev/null || true
      else
        -cbx-popup-erase
        if ! -cbx-screen-restore 2>/dev/null; then
          zle reset-prompt 2>/dev/null || true
        fi
      fi

      -cbx-popup-keymap-destroy
      if [[ -w /dev/tty ]]; then
        print -n $'\e[?25h' >/dev/tty
      fi
      typeset -gi _CBX_POPUP_ACTIVE=0
    }

    if [[ "${_CBX_POPUP_ACTION}" == "accept" ]]; then
      zle _cbx-apply
    fi
  else
    typeset -gi _CBX_POPUP_ACTIVE=0
  fi
}
