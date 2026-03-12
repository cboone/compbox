#!/usr/bin/env zsh

# Test plugin fixture: second source in deterministic order.

typeset -ga CBX_TEST_LOADED_SOURCES
CBX_TEST_LOADED_SOURCES+=("20-record-second")
