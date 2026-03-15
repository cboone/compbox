#!/usr/bin/env zsh
# manual-test.zsh -- Launch a clean interactive zsh with the plugin loaded.
#
# Usage: zsh scripts/manual-test.zsh
#
# Starts an interactive shell with no user rc files, initializes stock
# completion, sources compbox.plugin.zsh, then drops you at a prompt.
# Run from any worktree root.

readonly SCRIPT_DIR="${0:A:h}"

function main() {
  emulate -L zsh
  setopt ERR_EXIT NO_UNSET PIPE_FAIL

  local project_root="${SCRIPT_DIR:h}"
  local plugin="${project_root}/compbox.plugin.zsh"

  if [[ ! -f "${plugin}" ]]; then
    print -u2 "error: plugin not found at ${plugin}"
    return 1
  fi

  # Use a temporary ZDOTDIR so only our .zshrc runs.
  local tmpdir
  tmpdir="$(mktemp -d)"

  cat >"${tmpdir}/.zshrc" <<ZSHRC
autoload -Uz compinit && compinit -C
source ${(q)plugin}

print ""
print "compbox manual test shell"
print "  enabled:       \${_CBX_ENABLED}"
print "  emacs ^I:      \$(bindkey -M emacs '^I')"
print "  orig widget:   \${_CBX_ORIG_TAB_EMACS}"
print "  compadd shim:  \${+functions[compadd]}"
print ""
print "Try: ls ~/D<Tab>  git ch<Tab>  cd <Tab>"
print "     cbx-disable  cbx-enable"
print "     cbx-dump     (show captured candidates after <Tab>)"
print ""

# Debug helper: dump captured candidates after a <Tab> completion.
function cbx-dump() {
  emulate -L zsh
  setopt NO_UNSET PIPE_FAIL

  print "candidates: \${#_CBX_CANDIDATES[@]}"
  print "next id:    \${_CBX_CAND_NEXT_ID:-0}"
  print "raw args:   \${#_CBX_CAND_RAW_ARGS[@]}"
  print ""

  if ((\${#_CBX_CANDIDATES[@]} == 0)); then
    print "(no candidates captured, try pressing <Tab> first)"
    return 0
  fi

  local packed
  for packed in "\${_CBX_CANDIDATES[@]}"; do
    -cbx-candidate-unpack "\${packed}"
    echo "---"
  done
}

PROMPT="compbox %~ %# "

# Clean up the temp directory on exit.
TRAPEXIT() { rm -rf ${(q)tmpdir} }
ZSHRC

  ZDOTDIR="${tmpdir}" exec zsh -i
}

main "${@}"
