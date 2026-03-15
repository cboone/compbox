#!/usr/bin/env zsh

# Benchmark fixture: stock compinit baseline.
# Measures bare compinit without an interactive shell. Compare against
# lifecycle-only to isolate compbox's startup cost.

autoload -Uz compinit
compinit -C
