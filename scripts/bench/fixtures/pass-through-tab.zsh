#!/usr/bin/env zsh

# Benchmark fixture: pass-through Tab completion overhead.
# Measures plugin startup + enable + disable lifecycle compared to
# stock completion baseline.

autoload -Uz compinit
compinit -C

readonly _PROJECT_ROOT="${0:A:h:h:h:h}"

source "${_PROJECT_ROOT}/lib/cbx-complete.zsh"
source "${_PROJECT_ROOT}/lib/cbx-enable.zsh"
source "${_PROJECT_ROOT}/lib/cbx-disable.zsh"

cbx-enable
cbx-disable
