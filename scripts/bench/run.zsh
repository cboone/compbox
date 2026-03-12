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

typeset -ga BENCH_SCENARIO_NAMES=()
typeset -ga BENCH_SCENARIO_COMMANDS=()

function check_deps() {
  if ! command -v hyperfine >/dev/null 2>&1; then
    print "hyperfine not found. Install it with: brew install hyperfine" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    print "jq not found. Install it with: brew install jq" >&2
    return 1
  fi
}

function require_fixtures() {
  local -a required_fixtures=(
    "${FIXTURES_DIR}/noop-plugin.zsh"
    "${FIXTURES_DIR}/noop-plugin-startup.zsh"
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
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("noop-plugin-startup")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/noop-plugin-startup.zsh")
    ;;
  smoke)
    # Small fixture set for CI smoke validation.
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("noop-plugin-startup")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/noop-plugin-startup.zsh")
    ;;
  full)
    BENCH_SCENARIO_NAMES+=("stock-zsh")
    BENCH_SCENARIO_COMMANDS+=("zsh -c 'exit'")
    BENCH_SCENARIO_NAMES+=("stock-completion")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/stock-completion.zsh")
    BENCH_SCENARIO_NAMES+=("noop-plugin-startup")
    BENCH_SCENARIO_COMMANDS+=("zsh ${FIXTURES_DIR:q}/noop-plugin-startup.zsh")
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
  local median p95

  median="$(jq -r --arg scenario "${scenario}" '.results[] | select(.command == $scenario) | .median' "${json_file}")"
  # hyperfine exports times array, compute p95 from sorted times.
  p95="$(jq -r --arg scenario "${scenario}" '
  .results[] | select(.command == $scenario) |
  .times | sort | .[((length * 0.95) | floor)]
  ' "${json_file}")"

  printf "scenario=%-20s p50=%.4f p95=%.4f iterations=%d\n" "${scenario}" "${median}" "${p95}" "${runs}"
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
    print "Fixture set: small (stock completion and no-op plugin startup)."
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
  print -- "--- Results (seconds) ---"

  local scenario
  for scenario in "${BENCH_SCENARIO_NAMES[@]}"; do
    extract_stats "${json_out}" "${scenario}" "${runs}"
  done
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
    json_out="$(mktemp -t compbox-bench.XXXXXX).json"
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
