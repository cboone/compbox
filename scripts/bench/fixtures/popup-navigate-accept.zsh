#!/usr/bin/env zsh

# Benchmark fixture: popup navigation and accept.
# Measures navigation redraw overhead: two Down-arrow presses plus accept.
# Delta against popup-open-accept isolates navigation cost.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly _PROJECT_ROOT="${0:A:h:h:h:h}"

export CBX_BENCH_PROJECT_ROOT="${_PROJECT_ROOT}"

expect <<'EXPECT'
set timeout 10
log_user 0

set project_root $env(CBX_BENCH_PROJECT_ROOT)

spawn zsh -f -i

send -- "export PS1='bench> '\r"
send -- "autoload -Uz compinit; compinit -C\r"
send -- "source \"$project_root/compbox.plugin.zsh\"\r"
send -- "tmpdir=\$(mktemp -d)\r"
send -- "touch \"\$tmpdir/alpha-one\" \"\$tmpdir/alpha-two\" \"\$tmpdir/beta\"\r"

# Stub DSR probe: expect PTYs have no terminal emulator to respond to
# DSR queries, so the read loop would consume keystrokes intended for
# zle. Hardcode a plausible cursor position instead.
send -- "function -cbx-dsr-probe() { typeset -gi _CBX_CURSOR_ROW=1 _CBX_CURSOR_COL=7; }\r"

send -- "print __CBX_READY__\r"
expect "__CBX_READY__"

# Trigger popup, wait for render, navigate down twice, then accept.
# Down arrow (\x1b[B) maps to -cbx-popup-next-widget. With 2 candidates,
# two Downs wrap around: 1 -> 2 -> 1. No delay between arrows; zle
# processes keystrokes sequentially within recursive-edit.
send -- "echo \$tmpdir/alph\t"
after 200
send -- "\x1b\[B"
send -- "\x1b\[B"
send -- "\r"
send -- "\r"
expect "bench> "

send -- "cbx-disable\r"
send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT

unset CBX_BENCH_PROJECT_ROOT
