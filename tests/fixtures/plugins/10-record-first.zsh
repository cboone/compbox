#!/usr/bin/env zsh

# Test plugin fixture: first source in deterministic order.

typeset -ga CBX_TEST_LOADED_SOURCES
CBX_TEST_LOADED_SOURCES+=("10-record-first")

typeset -g CBX_TEST_TMP_GLOBAL="set-by-first-fixture"
