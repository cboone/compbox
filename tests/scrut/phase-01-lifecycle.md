# Phase 01: Lifecycle Tests

Verify enable/disable lifecycle, idempotency, and pass-through widget
registration.

## Lifecycle state before enable shows plugin inactive

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   echo "enabled: ${_CBX_ENABLED:-0}" &&
>   echo "plugin sourced: ${_CBX_PLUGIN_SOURCED:-0}"
enabled: 0
plugin sourced: 0
```

## Enable installs widget and bindings in both keymaps

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   cbx-enable &&
>   echo "enabled: ${_CBX_ENABLED}" &&
>   bindkey -M emacs '^I' &&
>   bindkey -M viins '^I'
enabled: 1
"^I" cbx-complete
"^I" cbx-complete
```

## Disable restores original emacs binding

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   local orig_emacs &&
>   orig_emacs="$(bindkey -M emacs '^I')" &&
>   cbx-enable &&
>   cbx-disable &&
>   echo "enabled: ${_CBX_ENABLED:-0}" &&
>   local restored_emacs &&
>   restored_emacs="$(bindkey -M emacs '^I')" &&
>   [[ "${restored_emacs}" == "${orig_emacs}" ]] &&
>   echo "emacs binding: restored"
enabled: 0
emacs binding: restored
```

## Disable restores original viins binding

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   local orig_viins &&
>   orig_viins="$(bindkey -M viins '^I')" &&
>   cbx-enable &&
>   cbx-disable &&
>   local restored_viins &&
>   restored_viins="$(bindkey -M viins '^I')" &&
>   [[ "${restored_viins}" == "${orig_viins}" ]] &&
>   echo "viins binding: restored"
viins binding: restored
```

## Repeated enable calls are idempotent

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   cbx-enable &&
>   cbx-enable &&
>   cbx-enable &&
>   echo "enabled: ${_CBX_ENABLED}" &&
>   bindkey -M emacs '^I'
enabled: 1
"^I" cbx-complete
```

## Repeated disable calls are safe no-ops

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   cbx-enable &&
>   cbx-disable &&
>   cbx-disable &&
>   cbx-disable &&
>   echo "enabled: ${_CBX_ENABLED:-0}"
enabled: 0
```

## Pass-through preserves original widget name in saved state

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   cbx-enable &&
>   echo "orig emacs: ${_CBX_ORIG_TAB_EMACS}" &&
>   echo "orig viins: ${_CBX_ORIG_TAB_VIINS}"
orig emacs: expand-or-complete
orig viins: expand-or-complete
```

## Pass-through dispatches to viins widget in viins keymap

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   function zle() { print "called: $1"; } &&
>   _CBX_ORIG_TAB_EMACS="expand-or-complete" &&
>   _CBX_ORIG_TAB_VIINS="vi-expand-or-complete" &&
>   KEYMAP="viins" &&
>   cbx-complete
called: vi-expand-or-complete
```

## Pass-through dispatches to emacs widget outside viins keymap

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   function zle() { print "called: $1"; } &&
>   _CBX_ORIG_TAB_EMACS="expand-or-complete" &&
>   _CBX_ORIG_TAB_VIINS="vi-expand-or-complete" &&
>   KEYMAP="main" &&
>   cbx-complete
called: expand-or-complete
```

## Sourcing compbox.plugin.zsh auto-enables once

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   source "${CBX_PROJECT_ROOT}/compbox.plugin.zsh" &&
>   echo "enabled: ${_CBX_ENABLED}" &&
>   echo "sourced: ${_CBX_PLUGIN_SOURCED}" &&
>   bindkey -M emacs '^I'
enabled: 1
sourced: 1
"^I" cbx-complete
```

## Repeated sourcing of compbox.plugin.zsh is a no-op

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   source "${CBX_PROJECT_ROOT}/compbox.plugin.zsh" &&
>   source "${CBX_PROJECT_ROOT}/compbox.plugin.zsh" &&
>   source "${CBX_PROJECT_ROOT}/compbox.plugin.zsh" &&
>   echo "enabled: ${_CBX_ENABLED}" &&
>   bindkey -M emacs '^I'
enabled: 1
"^I" cbx-complete
```
