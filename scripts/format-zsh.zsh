#!/usr/bin/env zsh
# format-zsh.zsh -- Format zsh scripts using shfmt.
#
# Files that shfmt's experimental zsh mode can't parse (e.g., those with
# glob qualifiers) are skipped. Re-runs zsh -n after formatting to verify
# no new syntax errors were introduced.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h}"

source "${PROJECT_ROOT}/scripts/lib/find-zsh-files.zsh"

function require_tools() {
  if ! command -v shfmt >/dev/null 2>&1; then
    print "Error: shfmt not found" >&2
    return 1
  fi
}

function main() {
  require_tools

  local -a zsh_files=()
  zsh_files=("${(@f)$(find_zsh_files)}")

  if ((${#zsh_files[@]} == 0)); then
    print "No zsh files found to format."
    return 0
  fi

  local file
  for file in "${zsh_files[@]}"; do
    [[ -z "${file}" ]] && continue
    local rel="${file#${PROJECT_ROOT}/}"
    print "Formatting ${rel}..."

    if shfmt -i 2 -w -ln zsh "${file}" 2>/dev/null; then
      : # shfmt formatted successfully
    else
      print "  shfmt could not parse, skipping"
    fi

    # Verify no syntax errors introduced.
    if ! zsh -n "${file}" 2>/dev/null; then
      print "  WARNING: formatting introduced syntax errors in ${rel}" >&2
    fi
  done

  print "Done."
}

main "${@}"
