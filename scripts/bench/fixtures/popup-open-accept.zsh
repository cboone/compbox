#!/usr/bin/env zsh

# Benchmark fixture: popup open and immediate accept.
# Measures open-popup latency including render and accept exit for a small
# candidate count (2 matches).

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
send -- "print __CBX_READY__\r"
expect "__CBX_READY__"

# Trigger popup with multi-match prefix, wait for render, accept first item.
# Enter (^M) maps to -cbx-popup-accept-widget in the _cbx_menu keymap.
send -- "echo \$tmpdir/alph\t"
after 200
send -- "\r"
send -- "\r"
expect "bench> "

send -- "cbx-disable\r"
send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT

unset CBX_BENCH_PROJECT_ROOT
