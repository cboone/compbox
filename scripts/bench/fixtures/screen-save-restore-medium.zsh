#!/usr/bin/env zsh

# Benchmark fixture: medium-region screen save/restore compose path.
# Uses the same tmux stub as the small fixture with a taller popup
# region to quantify scaling cost from additional captured rows.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly _PROJECT_ROOT="${0:A:h:h:h:h}"

source "${_PROJECT_ROOT}/lib/screen.zsh"

function tmux() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local subcommand="${1:-}"
  shift

  if [[ "${subcommand}" != "capture-pane" ]]; then
    return 1
  fi

  local -i start=0
  local -i end=0
  local arg
  while (($# > 0)); do
    arg="${1}"
    shift
    case "${arg}" in
    -S)
      start="${1}"
      shift
      ;;
    -E)
      end="${1}"
      shift
      ;;
    esac
  done

  local -i row
  for ((row = start; row <= end; row++)); do
    print -r -- "line-${row}"
  done
}

typeset -gx TMUX="stub"
typeset -gi _CBX_POPUP_ROW=20
typeset -gi _CBX_POPUP_HEIGHT=18

local -i i=0
while ((i < 400)); do
  -cbx-screen-save
  -cbx-screen-restore-compose
  ((++i))
done

unset TMUX
