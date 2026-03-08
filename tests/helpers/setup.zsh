# Test bootstrap: source libs, stubs, helpers
# Sourced at the top of every scrut test block.

source "${TESTDIR:h}/lib/-cbx-compadd.zsh"
source "${TESTDIR:h}/lib/-cbx-generate-complist.zsh"
source "${TESTDIR:h}/lib/render.zsh"
source "${TESTDIR:h}/lib/navigate.zsh"
source "${TESTDIR:h}/lib/filter.zsh"
source "${TESTDIR:h}/lib/ghost.zsh"
source "${TESTDIR:h}/lib/position.zsh"

typeset -ga _cbx_compcap=()
typeset -gi _cbx_visible_count=100
typeset -gi _cbx_needs_status=0
typeset -gi _cbx_total_candidates=0

function zle() { : }
function -cbx-render-full() { : }
function -cbx-render-update-selection() { : }

function cbx_add_candidate() {
  local id="${1}" display="${2}" word="${3}" desc="${4:-}" group="${5:-}"
  local meta="word${_cbx_nul}${word}${_cbx_nul}desc${_cbx_nul}${desc}${_cbx_nul}group${_cbx_nul}${group}"
  _cbx_compcap+=("${id}${_cbx_sep}${display}${_cbx_sep}${meta}")
}

function dump_rows() {
  local -i i
  for (( i=1; i <= ${#_cbx_row_kinds}; i++ )); do
    print -r -- "row ${i}: kind=${_cbx_row_kinds[${i}]} id=${_cbx_row_ids[${i}]} text=${_cbx_row_texts[${i}]} desc=${_cbx_row_descriptions[${i}]}"
  done
}
