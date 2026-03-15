#!/usr/bin/env zsh

# Benchmark fixture: plugin lifecycle overhead in isolation.
# Measures compinit + source libs + enable + disable without an
# interactive shell or expect. Compare against stock-compinit to
# isolate the cost of the compbox lifecycle layer.

autoload -Uz compinit
compinit -C

readonly _PROJECT_ROOT="${0:A:h:h:h:h}"

source "${_PROJECT_ROOT}/lib/-cbx-candidate-store.zsh"
source "${_PROJECT_ROOT}/lib/-cbx-compadd.zsh"
source "${_PROJECT_ROOT}/lib/cbx-complete.zsh"
source "${_PROJECT_ROOT}/lib/cbx-enable.zsh"
source "${_PROJECT_ROOT}/lib/cbx-disable.zsh"

cbx-enable
cbx-disable
