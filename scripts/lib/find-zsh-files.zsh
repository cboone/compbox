#!/usr/bin/env zsh
# find-zsh-files.zsh -- Shared utility to locate project zsh files.
#
# Expects PROJECT_ROOT to be set by the sourcing script.

function find_zsh_files() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  local -a files=()
  local pattern
  for pattern in "lib/**/*.zsh" "scripts/**/*.zsh" "tests/helpers/**/*.zsh" "tests/fixtures/**/*.zsh" "tests/zunit/helpers/**/*.zsh" "*.plugin.zsh"; do
    files+=("${PROJECT_ROOT}"/${~pattern}(N))
  done
  print -l "${files[@]}"
}
