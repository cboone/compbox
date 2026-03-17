#!/usr/bin/env zsh

# Candidate store: reset, pack, and unpack helpers for captured completion data.

function -cbx-candidate-escape-field() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Escape backslash, tab, and newline for safe tab-delimited packing.
  # Order matters: backslash first to avoid double-escaping.
  # Returns result via REPLY (no subshell).
  REPLY="${1//\\/\\\\}"
  REPLY="${REPLY//$'\t'/\\t}"
  REPLY="${REPLY//$'\n'/\\n}"
}

function -cbx-candidate-unescape-field() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  # Unescape using SOH placeholder to avoid ordering ambiguity.
  # Without the placeholder, \\t (escaped backslash + literal t) would be
  # mis-parsed as backslash + tab.
  local soh=$'\x01'
  local tab=$'\t'
  local lf=$'\n'
  REPLY="${1//\\\\/${soh}}"
  REPLY="${REPLY//\\t/${tab}}"
  REPLY="${REPLY//\\n/${lf}}"
  REPLY="${REPLY//${soh}/\\}"
}

function -cbx-candidate-reset() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  typeset -gi _CBX_CAND_NEXT_ID=0
  typeset -ga _CBX_CANDIDATES=()
  typeset -ga _CBX_CAND_RAW_ARGS=()
  typeset -gi _CBX_NMATCHES=0
}

function -cbx-candidate-pack() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  local id="${1}"
  local call_idx="${9}"

  # Escape the 7 string fields. Integer fields (id, call_idx) are safe.
  local word display group prefix suffix iprefix isuffix
  -cbx-candidate-escape-field "${2}"
  word="${REPLY}"
  -cbx-candidate-escape-field "${3}"
  display="${REPLY}"
  -cbx-candidate-escape-field "${4}"
  group="${REPLY}"
  -cbx-candidate-escape-field "${5}"
  prefix="${REPLY}"
  -cbx-candidate-escape-field "${6}"
  suffix="${REPLY}"
  -cbx-candidate-escape-field "${7}"
  iprefix="${REPLY}"
  -cbx-candidate-escape-field "${8}"
  isuffix="${REPLY}"

  # Packed format: tab-separated fields in fixed order.
  # id<TAB>word<TAB>display<TAB>group<TAB>prefix<TAB>suffix<TAB>iprefix<TAB>isuffix<TAB>call_idx
  # NOTE: Production packing is inlined in -cbx-capture-from-compadd to avoid
  # subshell forks. This function is used in tests for round-trip verification.
  printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d' \
    "${id}" \
    "${word}" \
    "${display}" \
    "${group}" \
    "${prefix}" \
    "${suffix}" \
    "${iprefix}" \
    "${isuffix}" \
    "${call_idx}"
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

  # Validate field count: packed records must have exactly 9 fields.
  if ((${#fields[@]} != 9)); then
    print -r -- "error: expected 9 fields, got ${#fields[@]}" >&2
    return 1
  fi

  # Unescape string fields. Integer fields (1=id, 9=call_idx) are safe.
  -cbx-candidate-unescape-field "${fields[2]}"
  fields[2]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[3]}"
  fields[3]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[4]}"
  fields[4]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[5]}"
  fields[5]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[6]}"
  fields[6]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[7]}"
  fields[7]="${REPLY}"
  -cbx-candidate-unescape-field "${fields[8]}"
  fields[8]="${REPLY}"

  print -r -- "id=${fields[1]}"
  print -r -- "word=${fields[2]}"
  print -r -- "display=${fields[3]}"
  print -r -- "group=${fields[4]}"
  print -r -- "prefix=${fields[5]}"
  print -r -- "suffix=${fields[6]}"
  print -r -- "iprefix=${fields[7]}"
  print -r -- "isuffix=${fields[8]}"
  print -r -- "call_idx=${fields[9]}"
}
