#!/usr/bin/env zsh
# Benchmark driver for compbox.
#
# Usage:
#   scripts/bench/run.zsh              Run full benchmark suite.
#   scripts/bench/run.zsh --baseline   Capture baseline and save to benchmarks/.
#   scripts/bench/run.zsh --smoke      Quick smoke run (fewer iterations, for CI).

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly PROJECT_ROOT="${0:A:h:h:h}"
readonly BENCHMARKS_DIR="${PROJECT_ROOT}/benchmarks"
readonly DEFAULT_RUNS=100
readonly SMOKE_RUNS=10
readonly WARMUP=5

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

function extract_stats() {
  local json_file="${1}"
  local scenario="${2}"
  local median p95

  median="$(jq -r ".results[] | select(.command | contains(\"${scenario}\")) | .median" "${json_file}")"
  # hyperfine exports times array; compute p95 from sorted times.
  p95="$(jq -r "
  .results[] | select(.command | contains(\"${scenario}\")) |
  .times | sort | .[((length * 0.95) | floor)]
  " "${json_file}")"

  printf "scenario=%-20s p50=%.4f p95=%.4f\n" "${scenario}" "${median}" "${p95}"
}

function run_benchmarks() {
  local runs="${1}"
  local json_out="${2}"

  print "Running benchmarks (${runs} iterations, ${WARMUP} warmup)..."
  print ""

  hyperfine \
    --warmup "${WARMUP}" \
    --runs "${runs}" \
    --export-json "${json_out}" \
    --command-name "stock-zsh" \
    "zsh -c 'exit'" \
    --command-name "compinit-only" \
    "zsh -c 'autoload -Uz compinit; compinit -C; exit'"

  print ""
  print -- "--- Results (seconds) ---"
  extract_stats "${json_out}" "stock-zsh"
  extract_stats "${json_out}" "compinit-only"
}

function main() {
  check_deps

  local mode="full"
  local runs="${DEFAULT_RUNS}"

  if ((${#} > 0)); then
    case "${1}" in
    --baseline)
      mode="baseline"
      ;;
    --smoke)
      mode="smoke"
      runs="${SMOKE_RUNS}"
      ;;
    --help | -h)
      print "Usage: ${0:t} [--baseline|--smoke|--help]"
      return 0
      ;;
    *)
      print "Unknown option: ${1}" >&2
      return 1
      ;;
    esac
  fi

  local json_out
  if [[ "${mode}" == "baseline" ]]; then
    mkdir -p "${BENCHMARKS_DIR}"
    json_out="${BENCHMARKS_DIR}/baseline.json"
  else
    json_out="$(mktemp -t compbox-bench.XXXXXX).json"
  fi

  run_benchmarks "${runs}" "${json_out}"

  if [[ "${mode}" == "baseline" ]]; then
    print ""
    print "Baseline saved to ${json_out#${PROJECT_ROOT}/}"
  elif [[ "${mode}" != "baseline" ]]; then
    rm -f "${json_out}"
  fi
}

main "${@}"
