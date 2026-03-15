#!/usr/bin/env zsh

# Guard against repeated sourcing.
if ((${_CBX_PLUGIN_SOURCED:-0})); then
  return 0
fi

typeset -gi _CBX_PLUGIN_SOURCED=1

# Resolve plugin root from this file's location.
typeset -g _CBX_PLUGIN_ROOT="${0:A:h}"

# Eager library loading.
source "${_CBX_PLUGIN_ROOT}/lib/bench/timing.zsh"
source "${_CBX_PLUGIN_ROOT}/lib/cbx-complete.zsh"
source "${_CBX_PLUGIN_ROOT}/lib/cbx-enable.zsh"
source "${_CBX_PLUGIN_ROOT}/lib/cbx-disable.zsh"

# Auto-enable on first source.
cbx-enable
