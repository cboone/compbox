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
#
# Exits non-zero if any tool produces findings.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h}"

source "${PROJECT_ROOT}/scripts/lib/find-zsh-files.zsh"

# Canonical SC codes excluded per the check-zsh-scripts skill (cboone/cc-plugins).
# These are stable false positives when running shellcheck --shell=bash on zsh
# scripts. Reference: check-zsh-scripts SKILL.md section 3c and
# references/tools/shellcheck.md.
#   SC1090  Non-constant source: dynamic source paths
#   SC2039  Non-POSIX features: zsh builtins flagged when using --shell=bash
#   SC2154  Variable referenced but not assigned: framework variables
#   SC2168  local outside function: zsh allows local in broader contexts
#   SC2296  Parameter expansion in ${...}: zsh expansion flags
#   SC2299  Nested ${...}: zsh nested parameter expansions
readonly -a _SHELLCHECK_SKILL_CODES=(SC1090 SC2039 SC2154 SC2168 SC2296 SC2299)

# Project-specific SC codes excluded for compbox. These fire on legitimate zsh
# patterns that the skill's canonical list does not cover.
#   SC1036  "(" unexpected: zsh glob qualifiers like (N) and (.)
#   SC1072  Expected test expression: triggered by zsh glob qualifier syntax
#   SC1073  Could not parse: triggered by zsh glob qualifier syntax
#   SC2034  Variable appears unused: zsh completion system variables (PREFIX,
#           SUFFIX, IPREFIX, ISUFFIX), test fixture globals, indirect expansion
#   SC2206  Quote to prevent splitting: zsh does not split unquoted expansions
#   SC2215  Flag used as command name: zsh internal functions with - prefix
readonly -a _SHELLCHECK_PROJECT_CODES=(SC1036 SC1072 SC1073 SC2034 SC2206 SC2215)

readonly SHELLCHECK_EXCLUDE="${(j:,:)_SHELLCHECK_SKILL_CODES},${(j:,:)_SHELLCHECK_PROJECT_CODES}"

# Print multi-line output with indentation.
function print_indented() {
  local label="${1}"
  local output="${2}"
  print "  ${label}:"
  while IFS= read -r line; do
    print "    ${line}"
  done <<<"${output}"
}

function require_tools() {
  local -a missing=()
  local tool
  for tool in shellcheck checkbashisms shellharden shfmt; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      missing+=("${tool}")
    fi
  done
  if ((${#missing[@]} > 0)); then
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
  # || true: returns non-zero when warnings exist; ERR_EXIT would
  # terminate the script before we can capture and report findings.
  shellcheck --shell=bash --severity=warning --exclude="${SHELLCHECK_EXCLUDE}" "${file}" 2>&1 || true
}

function run_checkbashisms() {
  local file="${1}"
  # Filter "does not appear to be a /bin/sh script; skipping" since all our
  # scripts use #!/usr/bin/env zsh and this message is expected noise.
  # || true: handles both checkbashisms' non-zero exit when findings exist
  # and grep returning 1 when filtering removes all output.
  checkbashisms "${file}" 2>&1 | grep -v "does not appear to be a /bin/sh script" || true
}

function run_shellharden() {
  local file="${1}"
  # Only report the check result; --suggest dumps the entire file with ANSI
  # color codes, which is too verbose for automated output.
  # || true: returns non-zero when suggestions exist; ERR_EXIT would
  # terminate the script before we can capture and report findings.
  shellharden --check "${file}" 2>&1 || true
}

function has_main_call() {
  # Detect executable scripts that call main at the end.
  # Sourcing these would execute their full logic.
  local file="${1}"
  grep -qE '^main "\$\{@\}"' "${file}" 2>/dev/null
}

function is_bench_fixture() {
  local file="${1}"
  [[ "${file}" = */scripts/bench/fixtures/* ]]
}

function run_setopt_warnings() {
  local file="${1}"
  # Skip when SKIP_SETOPT_CHECK is set (e.g., in CI) to keep the pipeline
  # purely static analysis, since this step sources (executes) files.
  if [[ -n "${SKIP_SETOPT_CHECK:-}" ]]; then
    return 0
  fi
  # Skip executable scripts: sourcing them would run main().
  if has_main_call "${file}"; then
    return 0
  fi
  # Skip bench fixtures: sourcing them runs compinit and other side effects.
  if is_bench_fixture "${file}"; then
    return 0
  fi
  # || true: returns non-zero if source encounters warnings; ERR_EXIT would
  # terminate the script before we can capture and report findings.
  zsh -c 'emulate -L zsh; setopt warn_create_global warn_nested_var; source '"${(q)file}" 2>&1 || true
}

function main() {
  local -a zsh_files=()
  zsh_files=("${(@f)$(find_zsh_files)}")

  if ((${#zsh_files[@]} == 0)); then
    print "No zsh files found to check."
    return 0
  fi

  require_tools

  local exit_code=0
  local file rel
  local syntax_output compile_output sc_output cb_output sh_output setopt_output fmt_output

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
      exit_code=1
    fi

    # 4. checkbashisms.
    cb_output="$(run_checkbashisms "${file}" 2>&1)"
    if [[ -n "${cb_output}" ]]; then
      print_indented "checkbashisms" "${cb_output}"
      exit_code=1
    fi

    # 5. shellharden.
    sh_output="$(run_shellharden "${file}" 2>&1)"
    if [[ -n "${sh_output}" ]]; then
      print_indented "shellharden" "${sh_output}"
      exit_code=1
    fi

    # 6. setopt warnings (variable scope).
    setopt_output="$(run_setopt_warnings "${file}" 2>&1)"
    if [[ -n "${setopt_output}" ]]; then
      print_indented "setopt warnings" "${setopt_output}"
      exit_code=1
    fi

    # 7. shfmt (formatting diffs only; parse errors on stderr are discarded
    # since shfmt's experimental zsh mode can't handle some valid zsh syntax
    # like glob qualifiers).
    # || true: returns non-zero when formatting differs; ERR_EXIT would
    # terminate the script before we can capture and report findings.
    fmt_output="$(shfmt -i 2 -ln zsh -d "${file}" 2>/dev/null)" || true
    if [[ -n "${fmt_output}" ]]; then
      print_indented "shfmt" "${fmt_output}"
      exit_code=1
    fi
  done

  if ((exit_code == 0)); then
    print "All zsh checks passed."
  fi

  return "${exit_code}"
}

main "${@}"
