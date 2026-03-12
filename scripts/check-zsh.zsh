#!/usr/bin/env zsh
# check-zsh.zsh -- Check zsh scripts for syntax, lint, scope, and formatting issues.
#
# Runs each tool in order per the check-zsh workflow:
#   1. zsh -n          (syntax)
#   2. zcompile        (compile)
#   3. shellcheck      (static analysis)
#   4. checkbashisms   (bashism detection)
#   5. shellharden     (safety suggestions)
#   6. setopt warnings (variable scope)
#   7. shfmt           (formatting)
#   8. beautysh        (formatting)

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h}"

# SC codes excluded as false positives when running shellcheck --shell=bash
# on zsh scripts:
#   SC1036  "(" unexpected: zsh glob qualifiers like (N) and (.)
#   SC1072  Expected test expression: triggered by zsh glob qualifier syntax
#   SC1073  Could not parse: triggered by zsh glob qualifier syntax
#   SC1090  Non-constant source: dynamic source paths
#   SC1091  Not following sourced file: unresolvable source paths
#   SC2034  Variable appears unused: framework/plugin variables
#   SC2039  Non-POSIX features: zsh builtins flagged when using --shell=bash
#   SC2154  Variable referenced but not assigned: framework variables
#   SC2168  local outside function: zsh allows local in broader contexts
#   SC2206  Quote to prevent splitting: zsh does not split unquoted expansions
#   SC2296  Parameter expansion in ${...}: zsh expansion flags
#   SC2299  Nested ${...}: zsh nested parameter expansions
#   SC3003-SC3057  Bashism warnings: zsh features flagged as non-POSIX
readonly SHELLCHECK_EXCLUDE="SC1036,SC1072,SC1073,SC1090,SC1091,SC2034,SC2039,SC2154,SC2168,SC2206,SC2296,SC2299,SC3003,SC3010,SC3030,SC3037,SC3043,SC3044,SC3046,SC3054,SC3057"

# Print multi-line output with indentation.
function print_indented() {
  local label="${1}"
  local output="${2}"
  print "  ${label}:"
  while IFS= read -r line; do
    print "    ${line}"
  done <<< "${output}"
}

function find_zsh_files() {
  local -a files=()
  local pattern
  for pattern in "lib/**/*.zsh" "scripts/**/*.zsh" "tests/helpers/**/*.zsh" "tests/zunit/helpers/**/*.zsh" "*.plugin.zsh"; do
    files+=("${PROJECT_ROOT}"/${~pattern}(N))
  done
  print -l "${files[@]}"
}

function require_tools() {
  local -a missing=()
  local tool
  for tool in shellcheck checkbashisms shellharden shfmt beautysh; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      missing+=("${tool}")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    print "Error: required tools not found: ${(j:, :)missing}" >&2
    return 1
  fi
}

function run_syntax_check() {
  local file="${1}"
  zsh -n "${file}" 2>&1
}

function run_zcompile() {
  local file="${1}"
  local output
  output="$(zsh -c 'zcompile "$1"' _ "${file}" 2>&1)" || {
    print -r -- "${output}"
    rm -f "${file}.zwc"
    return 1
  }
  rm -f "${file}.zwc"
  return 0
}

function run_shellcheck() {
  local file="${1}"
  # shellcheck does not support --shell=zsh; use --shell=bash with
  # zsh-specific SC codes excluded via SHELLCHECK_EXCLUDE.
  # Returns non-zero when warnings are found; || true prevents ERR_EXIT
  # from terminating the script since warnings are advisory, not fatal.
  shellcheck --shell=bash --severity=warning --exclude="${SHELLCHECK_EXCLUDE}" "${file}" 2>&1 || true
}

function run_checkbashisms() {
  local file="${1}"
  # Filter "does not appear to be a /bin/sh script; skipping" since all our
  # scripts use #!/usr/bin/env zsh and this message is expected noise.
  # || true handles both checkbashisms' non-zero exit when findings exist
  # and grep returning 1 when filtering removes all output.
  checkbashisms "${file}" 2>&1 | grep -v "does not appear to be a /bin/sh script" || true
}

function run_shellharden() {
  local file="${1}"
  # --check returns non-zero if suggestions exist; || true prevents ERR_EXIT
  # from terminating the script since suggestions are advisory.
  # Only report the check result; --suggest dumps the entire file with ANSI
  # color codes, which is too verbose for automated output.
  shellharden --check "${file}" 2>&1 || true
}

function has_main_call() {
  # Detect executable scripts that call main at the end.
  # Sourcing these would execute their full logic.
  local file="${1}"
  grep -qE '^main "\$\{@\}"' "${file}" 2>/dev/null
}

function run_setopt_warnings() {
  local file="${1}"
  # Skip executable scripts: sourcing them would run main().
  if has_main_call "${file}"; then
    return 0
  fi
  # Returns non-zero if source fails; || true prevents ERR_EXIT from
  # terminating the script since scope warnings are advisory.
  zsh -c 'emulate -L zsh; setopt warn_create_global warn_nested_var; source "'"${file}"'"' 2>&1 || true
}

function run_shfmt() {
  local file="${1}"
  # Returns non-zero when formatting differs; || true prevents ERR_EXIT
  # from terminating the script since formatting diffs are advisory.
  shfmt -i 2 -ln zsh -d "${file}" 2>&1 || true
}

function run_beautysh() {
  local file="${1}"
  # Returns non-zero when formatting differs; || true prevents ERR_EXIT
  # from terminating the script since formatting diffs are advisory.
  beautysh --check "${file}" 2>&1 || true
}

function main() {
  local -a zsh_files=()
  zsh_files=("${(@f)$(find_zsh_files)}")

  if (( ${#zsh_files[@]} == 0 )); then
    print "No zsh files found to check."
    return 0
  fi

  require_tools

  local exit_code=0
  local file rel
  local syntax_output compile_output sc_output cb_output sh_output setopt_output fmt_output bs_output

  for file in "${zsh_files[@]}"; do
    [[ -z "${file}" ]] && continue
    rel="${file#${PROJECT_ROOT}/}"
    print "Checking ${rel}..."

    # 1. Syntax check.
    syntax_output="$(run_syntax_check "${file}" 2>&1)" || {
      print "  FAIL (zsh -n): syntax error"
      print -r -- "  ${syntax_output}"
      exit_code=1
    }

    # 2. Compile check.
    compile_output="$(run_zcompile "${file}" 2>&1)" || {
      print "  FAIL (zcompile): compilation error"
      print -r -- "  ${compile_output}"
      exit_code=1
    }

    # 3. Shellcheck.
    sc_output="$(run_shellcheck "${file}" 2>&1)"
    if [[ -n "${sc_output}" ]]; then
      print_indented "shellcheck" "${sc_output}"
    fi

    # 4. checkbashisms.
    cb_output="$(run_checkbashisms "${file}" 2>&1)"
    if [[ -n "${cb_output}" ]]; then
      print_indented "checkbashisms" "${cb_output}"
    fi

    # 5. shellharden.
    sh_output="$(run_shellharden "${file}" 2>&1)"
    if [[ -n "${sh_output}" ]]; then
      print_indented "shellharden" "${sh_output}"
    fi

    # 6. setopt warnings (variable scope).
    setopt_output="$(run_setopt_warnings "${file}" 2>&1)"
    if [[ -n "${setopt_output}" ]]; then
      print_indented "setopt warnings" "${setopt_output}"
    fi

    # 7. shfmt.
    fmt_output="$(run_shfmt "${file}" 2>&1)"
    if [[ -n "${fmt_output}" ]]; then
      print_indented "shfmt" "${fmt_output}"
    fi

    # 8. beautysh.
    bs_output="$(run_beautysh "${file}" 2>&1)"
    if [[ -n "${bs_output}" ]]; then
      print_indented "beautysh" "${bs_output}"
    fi
  done

  if (( exit_code == 0 )); then
    print "All zsh checks passed."
  fi

  return "${exit_code}"
}

main "${@}"
