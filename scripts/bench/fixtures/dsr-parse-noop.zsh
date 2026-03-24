#!/usr/bin/env zsh

# Benchmark fixture: DSR micro baseline loop.
# Matches the loop shape used by dsr-parse-micro without calling the
# parser. Delta against dsr-parse-micro isolates parse-path overhead.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

typeset -gi _CBX_CURSOR_ROW=0
typeset -gi _CBX_CURSOR_COL=0

local -i i=0
while ((i < 4000)); do
  _CBX_CURSOR_ROW=12
  _CBX_CURSOR_COL=45
  ((++i))
done
