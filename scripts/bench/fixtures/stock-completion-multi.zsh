#!/usr/bin/env zsh

# Benchmark fixture: stock Tab completion with multi-match.
# Runs one deterministic multi-match path completion in stock zsh (no plugin).
# Baseline for popup delta comparison.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

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

# Trigger completion on multi-match prefix. Stock zsh inserts common prefix
# "alpha-" and may list matches. Enter executes the resulting command.
send -- "echo \$tmpdir/alph\t\r"
expect "bench> "

send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT
