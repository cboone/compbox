#!/usr/bin/env zsh

# Benchmark fixture: stock Tab completion with medium multi-match (15).
# Runs one deterministic 15-match path completion in stock zsh (no plugin).
# Baseline for medium popup delta comparison.

emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

expect <<'EXPECT'
set timeout 10
log_user 0

spawn zsh -f -i

send -- "export PS1='bench> '\r"
send -- "autoload -Uz compinit; compinit -C\r"
send -- "tmpdir=\$(mktemp -d)\r"
send -- "touch \"\$tmpdir/alpha-01\" \"\$tmpdir/alpha-02\" \"\$tmpdir/alpha-03\" \"\$tmpdir/alpha-04\" \"\$tmpdir/alpha-05\"\r"
send -- "touch \"\$tmpdir/alpha-06\" \"\$tmpdir/alpha-07\" \"\$tmpdir/alpha-08\" \"\$tmpdir/alpha-09\" \"\$tmpdir/alpha-10\"\r"
send -- "touch \"\$tmpdir/alpha-11\" \"\$tmpdir/alpha-12\" \"\$tmpdir/alpha-13\" \"\$tmpdir/alpha-14\" \"\$tmpdir/alpha-15\"\r"
send -- "print __CBX_READY__\r"
expect "__CBX_READY__"

# Trigger completion on 15-match prefix. Stock zsh inserts common prefix
# "alpha-" and may list matches. Enter executes the resulting command.
send -- "echo \$tmpdir/alph\t\r"
expect "bench> "

send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT
