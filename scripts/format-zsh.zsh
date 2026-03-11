#!/usr/bin/env zsh
# format-zsh.zsh -- Format zsh scripts using shfmt and beautysh.
#
# Runs shfmt first (stricter parser), then beautysh for anything shfmt
# could not parse. Re-runs zsh -n after formatting to verify no new
# syntax errors were introduced.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h}"

function find_zsh_files() {
  local -a files=()
  local pattern
  for pattern in "lib/**/*.zsh" "scripts/**/*.zsh" "tests/helpers/**/*.zsh" "tests/zunit/helpers/**/*.zsh" "*.plugin.zsh"; do
    files+=("${PROJECT_ROOT}"/${~pattern}(N))
  done
  print -l "${files[@]}"
}

function main() {
  local has_shfmt=0
  local has_beautysh=0
  command -v shfmt >/dev/null 2>&1 && has_shfmt=1
  command -v beautysh >/dev/null 2>&1 && has_beautysh=1

  if (( ! has_shfmt && ! has_beautysh )); then
    print "Neither shfmt nor beautysh found." >&2
    print "  brew install shfmt" >&2
    print "  brew install beautysh" >&2
    return 1
  fi

  local -a zsh_files=()
  zsh_files=("${(@f)$(find_zsh_files)}")

  if (( ${#zsh_files[@]} == 0 )); then
    print "No zsh files found to format."
    return 0
  fi

  local file
  for file in "${zsh_files[@]}"; do
    [[ -z "${file}" ]] && continue
    local rel="${file#${PROJECT_ROOT}/}"
    print "Formatting ${rel}..."

    # shfmt first (stricter parser).
    if (( has_shfmt )); then
      shfmt -i 2 -w -ln zsh "${file}" 2>/dev/null || {
        print "  shfmt could not parse, falling back to beautysh"
      }
    fi

    # beautysh second.
    if (( has_beautysh )); then
      beautysh "${file}" >/dev/null 2>&1 || true
    fi

    # Verify no syntax errors introduced.
    if ! zsh -n "${file}" 2>/dev/null; then
      print "  WARNING: formatting introduced syntax errors in ${rel}" >&2
    fi
  done

  print "Done."
}

main "${@}"
