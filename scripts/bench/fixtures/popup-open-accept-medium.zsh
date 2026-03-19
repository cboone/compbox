#!/usr/bin/env zsh

# Benchmark fixture: popup open and accept with medium candidate count.
# Measures open-popup latency with 15 candidates, exercising taller popup
# rendering and larger screen save/restore area. Delta against
# popup-open-accept isolates the cost of additional candidates.

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
send -- "touch \"\$tmpdir/alpha-01\" \"\$tmpdir/alpha-02\" \"\$tmpdir/alpha-03\" \"\$tmpdir/alpha-04\" \"\$tmpdir/alpha-05\"\r"
send -- "touch \"\$tmpdir/alpha-06\" \"\$tmpdir/alpha-07\" \"\$tmpdir/alpha-08\" \"\$tmpdir/alpha-09\" \"\$tmpdir/alpha-10\"\r"
send -- "touch \"\$tmpdir/alpha-11\" \"\$tmpdir/alpha-12\" \"\$tmpdir/alpha-13\" \"\$tmpdir/alpha-14\" \"\$tmpdir/alpha-15\"\r"
send -- "print __CBX_READY__\r"
expect "__CBX_READY__"

# Trigger popup with 15-match prefix, wait for render, accept first item.
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
