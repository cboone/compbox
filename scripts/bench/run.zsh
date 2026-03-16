#!/usr/bin/env zsh
# Benchmark driver for compbox.
#
# Usage:
#   scripts/bench/run.zsh                               Run full benchmark suite.
#   scripts/bench/run.zsh --baseline                    Capture baseline and save to benchmarks/.
#   scripts/bench/run.zsh --smoke                       Quick smoke run with a small fixture set.
#   scripts/bench/run.zsh --smoke --json-out <path>     Save benchmark JSON to a specific path.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BENCHMARKS_DIR="${PROJECT_ROOT}/benchmarks"
readonly FIXTURES_DIR="${PROJECT_ROOT}/scripts/bench/fixtures"
readonly DEFAULT_RUNS=100
readonly SMOKE_RUNS=10
readonly WARMUP=5

# Budget thresholds (milliseconds). If a delta exceeds these, it is flagged.
readonly BUDGET_LIFECYCLE_P50=3  # lifecycle-only vs stock-compinit p50
readonly BUDGET_LIFECYCLE_P95=5  # lifecycle-only vs stock-compinit p95
readonly BUDGET_COMPLETION_P50=5 # pass-through-tab vs stock-completion p50
readonly BUDGET_COMPLETION_P95=8 # pass-through-tab vs stock-completion p95

typeset -ga BENCH_SCENARIO_NAMES=()
typeset -ga BENCH_SCENARIO_COMMANDS=()

# ANSI color codes (matching hyperfine's style).
readonly C_BOLD=$'\e[1m'
readonly C_GREEN=$'\e[1;32m'
readonly C_CYAN=$'\e[1;36m'
readonly C_YELLOW=$'\e[1;33m'
readonly C_RED=$'\e[1;31m'
readonly C_RESET=$'\e[0m'

function check_deps() {
  if ! command -v hyperfine >/dev/null 2>&1; then
    print "hyperfine not found. Install it with: brew install hyperfine" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    print "jq not found. Install it with: brew install jq" >&2
    return 1
  fi
  if ! command -v expect >/dev/null 2>&1; then
    print "expect not found. Install it with: brew install expect" >&2
    return 1
  fi
  if ! command -v bc >/dev/null 2>&1; then
    print "bc not found. Install it with: brew install bc" >&2
    return 1
  fi
}

function require_fixtures() {
  local -a required_fixtures=(
    "${FIXTURES_DIR}/lifecycle-only.zsh"
    "${FIXTURES_DIR}/noop-plugin.zsh"
    "${FIXTURES_DIR}/noop-plugin-startup.zsh"
    "${FIXTURES_DIR}/pass-through-tab.zsh"
    "${FIXTURES_DIR}/stock-compinit.zsh"
    "${FIXTURES_DIR}/stock-completion.zsh"
  )

  local fixture
  for fixture in "${required_fixtures[@]}"; do
    if [[ ! -f "${fixture}" ]]; then
      print "Missing benchmark fixture: ${fixture}" >&2
      return 1
    fi
  done
}

function configure_scenarios() {
  local mode="${1}"

  BENCH_SCENARIO_NAMES=()
  BENCH_SCENARIO_COMMANDS=()

  case "${mode}" in
  baseline)
    BENCH_SCENARIO_NAMES+=("stock-compinit")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-compinit.zsh")
    BENCH_SCENARIO_NAMES+=("lifecycle-only")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/lifecycle-only.zsh")
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("pass-through-tab")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/pass-through-tab.zsh")
    ;;
  smoke)
    BENCH_SCENARIO_NAMES+=("stock-compinit")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-compinit.zsh")
    BENCH_SCENARIO_NAMES+=("lifecycle-only")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/lifecycle-only.zsh")
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("pass-through-tab")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/pass-through-tab.zsh")
    ;;
  full)
    BENCH_SCENARIO_NAMES+=("stock-zsh")
    BENCH_SCENARIO_COMMANDS+=("zsh -f -c 'exit'")
    BENCH_SCENARIO_NAMES+=("stock-compinit")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-compinit.zsh")
    BENCH_SCENARIO_NAMES+=("noop-plugin-startup")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/noop-plugin-startup.zsh")
    BENCH_SCENARIO_NAMES+=("lifecycle-only")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/lifecycle-only.zsh")
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("pass-through-tab")
    BENCH_SCENARIO_COMMANDS+=("zsh -f ${FIXTURES_DIR:q}/pass-through-tab.zsh")
    ;;
  *)
    print "Unknown benchmark mode: ${mode}" >&2
    return 1
    ;;
  esac
}

function extract_stats() {
  local json_file="${1}"
  local scenario="${2}"
  local runs="${3}"
  local median_s p95_s

  median_s="$(jq -r --arg scenario "${scenario}" '.results[] | select(.command == $scenario) | .median' "${json_file}")"
  # hyperfine exports times array, compute p95 from sorted times.
  # Use ceil-1 index clamped to the last element for correctness on small arrays.
  p95_s="$(jq -r --arg scenario "${scenario}" '
  .results[] | select(.command == $scenario) |
  .times | sort | .[([((length * 0.95) | ceil) - 1, length - 1] | min)]
  ' "${json_file}")"

  local median_ms p95_ms
  median_ms="$(printf '%.2f' "$(echo "${median_s} * 1000" | bc -l)")"
  p95_ms="$(printf '%.2f' "$(echo "${p95_s} * 1000" | bc -l)")"

  printf "  %-24s p50=${C_CYAN}%7s ms${C_RESET}   p95=${C_CYAN}%7s ms${C_RESET}   (%d runs)\n" "${scenario}" "${median_ms}" "${p95_ms}" "${runs}"
}

function print_delta() {
  local json_file="${1}"
  local baseline="${2}"
  local target="${3}"
  local budget_p50="${4:-0}"
  local budget_p95="${5:-0}"

  local base_p50 target_p50 base_p95 target_p95
  base_p50="$(jq -r --arg s "${baseline}" '.results[] | select(.command == $s) | .median' "${json_file}")"
  target_p50="$(jq -r --arg s "${target}" '.results[] | select(.command == $s) | .median' "${json_file}")"
  base_p95="$(jq -r --arg s "${baseline}" '
    .results[] | select(.command == $s) |
    .times | sort | .[([((length * 0.95) | ceil) - 1, length - 1] | min)]
  ' "${json_file}")"
  target_p95="$(jq -r --arg s "${target}" '
    .results[] | select(.command == $s) |
    .times | sort | .[([((length * 0.95) | ceil) - 1, length - 1] | min)]
  ' "${json_file}")"

  local delta_p50 delta_p95
  delta_p50="$(printf '%.2f' "$(echo "(${target_p50} - ${base_p50}) * 1000" | bc -l)")"
  delta_p95="$(printf '%.2f' "$(echo "(${target_p95} - ${base_p95}) * 1000" | bc -l)")"

  # Green if under 1ms, yellow otherwise.
  local color_p50="${C_GREEN}"
  local abs_p50="${delta_p50#+}"
  abs_p50="${abs_p50#-}"
  if (($(echo "${abs_p50} >= 1" | bc -l))); then
    color_p50="${C_YELLOW}"
  fi

  local color_p95="${C_GREEN}"
  local abs_p95="${delta_p95#+}"
  abs_p95="${abs_p95#-}"
  if (($(echo "${abs_p95} >= 1" | bc -l))); then
    color_p95="${C_YELLOW}"
  fi

  printf "p50=${color_p50}%+7s ms${C_RESET}   p95=${color_p95}%+7s ms${C_RESET}" "${delta_p50}" "${delta_p95}"

  # Print budget verdict when thresholds are provided.
  if ((budget_p50 > 0 || budget_p95 > 0)); then
    local over_budget=0
    if (($(echo "${abs_p50} > ${budget_p50}" | bc -l))); then
      over_budget=1
    fi
    if (($(echo "${abs_p95} > ${budget_p95}" | bc -l))); then
      over_budget=1
    fi
    if ((over_budget)); then
      printf "   ${C_RED}OVER BUDGET${C_RESET} (p50<%dms, p95<%dms)" "${budget_p50}" "${budget_p95}"
    else
      printf "   ${C_GREEN}within budget${C_RESET} (p50<%dms, p95<%dms)" "${budget_p50}" "${budget_p95}"
    fi
  fi

  print ""
}

function run_benchmarks() {
  local mode="${1}"
  local runs="${2}"
  local json_out="${3}"

  configure_scenarios "${mode}"

  if [[ "${mode}" == "baseline" ]]; then
    print "Running baseline benchmarks (${runs} iterations, ${WARMUP} warmup)..."
  elif [[ "${mode}" == "smoke" ]]; then
    print "Running smoke benchmarks (${runs} iterations, ${WARMUP} warmup)..."
    print "Fixture set: lifecycle and end-to-end completion."
  else
    print "Running full benchmarks (${runs} iterations, ${WARMUP} warmup)..."
  fi
  print ""

  local -a hyperfine_args=(
    --warmup "${WARMUP}"
    --runs "${runs}"
    --export-json "${json_out}"
  )

  local idx=1
  while ((idx <= ${#BENCH_SCENARIO_NAMES[@]})); do
    hyperfine_args+=(
      --command-name "${BENCH_SCENARIO_NAMES[idx]}"
      "${BENCH_SCENARIO_COMMANDS[idx]}"
    )
    ((idx++))
  done

  hyperfine "${hyperfine_args[@]}"

  print ""
  print "${C_BOLD}Results${C_RESET}"

  local scenario
  for scenario in "${BENCH_SCENARIO_NAMES[@]}"; do
    extract_stats "${json_out}" "${scenario}" "${runs}"
  done

  # Show lifecycle overhead deltas when paired scenarios are present.
  local -A has_scenario
  for scenario in "${BENCH_SCENARIO_NAMES[@]}"; do
    has_scenario[${scenario}]=1
  done

  local printed_header=0

  if ((${+has_scenario[stock-compinit]} && ${+has_scenario[lifecycle-only]})); then
    print ""
    print "${C_BOLD}Lifecycle overhead${C_RESET}"
    printed_header=1
    printf "  %-38s" "lifecycle-only vs stock-compinit"
    print_delta "${json_out}" "stock-compinit" "lifecycle-only" \
      "${BUDGET_LIFECYCLE_P50}" "${BUDGET_LIFECYCLE_P95}"
  fi

  if ((${+has_scenario[stock-completion]} && ${+has_scenario[pass-through-tab]})); then
    if ((!printed_header)); then
      print ""
      print "${C_BOLD}Lifecycle overhead${C_RESET}"
    fi
    printf "  %-38s" "pass-through-tab vs stock-completion"
    print_delta "${json_out}" "stock-completion" "pass-through-tab" \
      "${BUDGET_COMPLETION_P50}" "${BUDGET_COMPLETION_P95}"
  fi
}

function main() {
  local mode="full"
  local runs="${DEFAULT_RUNS}"
  local json_out_arg=""

  while (($# > 0)); do
    case "${1}" in
    --baseline)
      mode="baseline"
      runs="${DEFAULT_RUNS}"
      ;;
    --smoke)
      mode="smoke"
      runs="${SMOKE_RUNS}"
      ;;
    --json-out)
      shift
      if [[ -z "${1:-}" ]]; then
        print "Missing value for --json-out" >&2
        return 1
      fi
      json_out_arg="${1}"
      ;;
    --help | -h)
      print "Usage: ${0:t} [--baseline|--smoke] [--json-out <path>] [--help]"
      return 0
      ;;
    *)
      print "Unknown option: ${1}" >&2
      return 1
      ;;
    esac
    shift
  done

  check_deps
  require_fixtures

  local json_out
  local cleanup_json=0

  if [[ -n "${json_out_arg}" ]]; then
    mkdir -p "${json_out_arg:h}"
    json_out="${json_out_arg}"
  elif [[ "${mode}" == "baseline" ]]; then
    mkdir -p "${BENCHMARKS_DIR}"
    json_out="${BENCHMARKS_DIR}/baseline.json"
  else
    json_out="$(mktemp -t compbox-bench-XXXXXX.json)"
    cleanup_json=1
  fi

  run_benchmarks "${mode}" "${runs}" "${json_out}"

  print ""
  if [[ "${mode}" == "baseline" ]]; then
    print "Baseline saved to ${json_out#${PROJECT_ROOT}/}"
  elif [[ -n "${json_out_arg}" ]]; then
    print "Benchmark JSON saved to ${json_out#${PROJECT_ROOT}/}"
  fi

  if ((cleanup_json == 1)); then
    rm -f "${json_out}"
  fi
}

main "${@}"
