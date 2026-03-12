#!/usr/bin/env zsh

# Optional benchmark timing hooks for compbox.
#
# Contract:
# - When CBX_BENCH=1 at source time, timing hooks are enabled.
# - Otherwise, hooks are no-ops and do not create timing globals.

if [[ "${CBX_BENCH:-0}" == "1" ]]; then
  function cbx_bench_enabled() {
    return 0
  }

  function cbx_bench_reset() {
    emulate -L zsh
    setopt NO_UNSET PIPE_FAIL

    unset CBX_BENCH_MARKS CBX_BENCH_TIMINGS
  }

  function cbx_bench_mark() {
    emulate -L zsh
    setopt ERR_EXIT NO_UNSET PIPE_FAIL

    local label="${1}"
    if [[ -z "${label}" ]]; then
      print "cbx_bench_mark requires a label" >&2
      return 1
    fi

    zmodload zsh/datetime

    typeset -gA CBX_BENCH_MARKS
    CBX_BENCH_MARKS[${label}]="${EPOCHREALTIME}"
  }

  function cbx_bench_record_elapsed() {
    emulate -L zsh
    setopt ERR_EXIT NO_UNSET PIPE_FAIL

    local start_label="${1}"
    local end_label="${2}"
    local phase="${3}"

    if [[ -z "${start_label}" || -z "${end_label}" || -z "${phase}" ]]; then
      print "cbx_bench_record_elapsed requires start label, end label, and phase" >&2
      return 1
    fi

    if [[ -z "${CBX_BENCH_MARKS[${start_label}]:-}" || -z "${CBX_BENCH_MARKS[${end_label}]:-}" ]]; then
      print "cbx_bench_record_elapsed missing benchmark marks" >&2
      return 1
    fi

    local -F 8 start_ts="${CBX_BENCH_MARKS[${start_label}]}"
    local -F 8 end_ts="${CBX_BENCH_MARKS[${end_label}]}"
    local -F 8 elapsed=$((end_ts - start_ts))

    typeset -ga CBX_BENCH_TIMINGS
    CBX_BENCH_TIMINGS+=("phase=${phase} seconds=${elapsed}")
  }

  function cbx_bench_report() {
    emulate -L zsh
    setopt NO_UNSET PIPE_FAIL

    if ((${+CBX_BENCH_TIMINGS} == 0 || ${#CBX_BENCH_TIMINGS[@]} == 0)); then
      return 0
    fi

    print -l "${CBX_BENCH_TIMINGS[@]}"
  }
else
  function cbx_bench_enabled() {
    return 1
  }

  function cbx_bench_reset() {
    :
  }

  function cbx_bench_mark() {
    :
  }

  function cbx_bench_record_elapsed() {
    :
  }

  function cbx_bench_report() {
    :
  }
fi
