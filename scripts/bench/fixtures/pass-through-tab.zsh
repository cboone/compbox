#!/usr/bin/env zsh

# Benchmark fixture: pass-through Tab completion overhead.
# Measures one deterministic completion keypath routed through cbx-complete.

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

# Trigger completion once with Tab on the same deterministic path prefix.
send -- "echo \$tmpdir/al\t\r"
expect "bench> "

send -- "cbx-disable\r"
send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT

unset CBX_BENCH_PROJECT_ROOT
