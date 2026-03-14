#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

# Benchmark fixture: stock Tab completion workload.
# Runs one deterministic path completion in an interactive shell.

expect <<'EXPECT'
set timeout 10
log_user 0

spawn zsh -f -i

send -- "export PS1='bench> '\r"
send -- "autoload -Uz compinit; compinit -C\r"
send -- "tmpdir=\$(mktemp -d)\r"
send -- "touch \"\$tmpdir/alpha-one\" \"\$tmpdir/alpha-two\" \"\$tmpdir/beta\"\r"
send -- "print __CBX_READY__\r"
expect "__CBX_READY__"

# Trigger completion once with Tab on a deterministic path prefix.
send -- "echo \$tmpdir/al\t\r"
expect "bench> "

send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT
