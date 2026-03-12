#!/usr/bin/env zsh

# Test plugin fixture: verifies strict options while sourcing plugin files.

typeset -ga CBX_TEST_LOADED_SOURCES
CBX_TEST_LOADED_SOURCES+=("30-record-options")

if [[ "${options[err_exit]}" == "on" && "${options[nounset]}" == "on" && "${options[pipe_fail]}" == "on" ]]; then
  typeset -g CBX_TEST_PLUGIN_STRICT_OPTIONS="on"
else
  typeset -g CBX_TEST_PLUGIN_STRICT_OPTIONS="off"
fi
