#!/usr/bin/env zsh

# Benchmark fixture: DSR parse-path micro benchmark.
# Replays a valid DSR response in-process to measure parser overhead
# independent of terminal I/O and interactive widget latency.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly _PROJECT_ROOT="${0:A:h:h:h:h}"

source "${_PROJECT_ROOT}/lib/position.zsh"

local -i i=0
while ((i < 4000)); do
  -cbx-dsr-parse $'\e[12;45R'
  ((++i))
done
