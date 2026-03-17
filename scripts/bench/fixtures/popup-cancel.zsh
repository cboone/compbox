#!/usr/bin/env zsh

# Benchmark fixture: popup cancel exit.
# Measures cancel exit latency. Delta against popup-open-accept isolates
# the cancel-vs-accept path difference.

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

# Trigger popup, wait for render, cancel with Ctrl-G.
# Uses Ctrl-G (\x07) instead of Escape to avoid KEYTIMEOUT delay (~400ms).
# After cancel, BUFFER is restored to pre-completion state.
# Ctrl-U clears the line, Enter gets a clean prompt.
send -- "echo \$tmpdir/alph\t"
after 200
send -- "\x07"
after 50
send -- "\x15\r"
expect "bench> "

send -- "cbx-disable\r"
send -- "rm -rf \"\$tmpdir\"\r"
send -- "exit\r"
expect eof
EXPECT

unset CBX_BENCH_PROJECT_ROOT
