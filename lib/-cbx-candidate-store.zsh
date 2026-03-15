#!/usr/bin/env zsh

# Candidate store: reset, pack, and unpack helpers for captured completion data.

function -cbx-candidate-reset() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  typeset -gi _CBX_CAND_NEXT_ID=0
  typeset -ga _CBX_CANDIDATES=()
  typeset -ga _CBX_CAND_RAW_ARGS=()
}

function -cbx-candidate-pack() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  local id="${1}"
  local word="${2}"
  local display="${3}"
  local group="${4}"
  local prefix="${5}"
  local suffix="${6}"
  local iprefix="${7}"
  local isuffix="${8}"

  # Packed format: tab-separated fields in fixed order.
  # id<TAB>word<TAB>display<TAB>group<TAB>prefix<TAB>suffix<TAB>iprefix<TAB>isuffix
  printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
    "${id}" \
    "${word}" \
    "${display}" \
    "${group}" \
    "${prefix}" \
    "${suffix}" \
    "${iprefix}" \
    "${isuffix}"
}

function -cbx-candidate-unpack() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  local packed="${1}"
  local -a fields=()

  # Split on tab characters, preserving empty fields.
  local rest="${packed}"
  while [[ "${rest}" == *$'\t'* ]]; do
    fields+=("${rest%%$'\t'*}")
    rest="${rest#*$'\t'}"
  done
  fields+=("${rest}")

  print "id=${fields[1]}"
  print "word=${fields[2]}"
  print "display=${fields[3]}"
  print "group=${fields[4]}"
  print "prefix=${fields[5]}"
  print "suffix=${fields[6]}"
  print "iprefix=${fields[7]}"
  print "isuffix=${fields[8]}"
}
