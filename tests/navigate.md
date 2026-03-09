# navigate

## navigate-init sets defaults

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> -cbx-navigate-init
> echo "idx: ${_cbx_selected_idx}"
> echo "viewport: ${_cbx_viewport_start}"
> echo "action: [${_cbx_action}]"
idx: 0
viewport: 1
action: []
```

## first-selectable finds first candidate row

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-navigate-first-selectable
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## first-selectable skips leading dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("divider" "candidate" "candidate")
> typeset -ga _cbx_row_ids=("0" "1" "2")
> typeset -ga _cbx_row_texts=("" "alpha" "beta")
> typeset -ga _cbx_row_descriptions=("" "" "")
> -cbx-navigate-first-selectable
> echo "idx: ${_cbx_selected_idx}"
idx: 2
```

## first-selectable returns 1 with no candidates

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("divider" "divider")
> -cbx-navigate-first-selectable
> echo "exit: $?"
> echo "idx: ${_cbx_selected_idx}"
exit: 1
idx: 0
```

## first-selectable returns 1 on empty array

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=()
> -cbx-navigate-first-selectable
> echo "exit: $?"
> echo "idx: ${_cbx_selected_idx}"
exit: 1
idx: 0
```

## navigate-down moves to next candidate

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> cbx_add_candidate 3 "gamma" "gamma"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-down
> echo "idx: ${_cbx_selected_idx}"
idx: 2
```

## navigate-down skips dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "A"
> cbx_add_candidate 2 "beta" "beta" "" "B"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-down
> echo "idx: ${_cbx_selected_idx}"
idx: 3
```

## navigate-down at last candidate stays put

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> _cbx_selected_idx=2
> -cbx-navigate-down
> echo "idx: ${_cbx_selected_idx}"
idx: 2
```

## navigate-up moves to previous candidate

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> cbx_add_candidate 3 "gamma" "gamma"
> -cbx-generate-complist
> _cbx_selected_idx=3
> -cbx-navigate-up
> echo "idx: ${_cbx_selected_idx}"
idx: 2
```

## navigate-up skips dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "A"
> cbx_add_candidate 2 "beta" "beta" "" "B"
> -cbx-generate-complist
> _cbx_selected_idx=3
> -cbx-navigate-up
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## navigate-up at first candidate stays put

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-up
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## navigate-next wraps from last to first candidate

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> cbx_add_candidate 3 "gamma" "gamma"
> -cbx-generate-complist
> _cbx_selected_idx=3
> -cbx-navigate-next
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## navigate-next wraps correctly across dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "A"
> cbx_add_candidate 2 "beta" "beta" "" "B"
> -cbx-generate-complist
> _cbx_selected_idx=3
> -cbx-navigate-next
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## navigate-prev wraps from first to last candidate

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> cbx_add_candidate 3 "gamma" "gamma"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-prev
> echo "idx: ${_cbx_selected_idx}"
idx: 3
```

## navigate-prev wraps correctly across dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "A"
> cbx_add_candidate 2 "beta" "beta" "" "B"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-prev
> echo "idx: ${_cbx_selected_idx}"
idx: 3
```

## navigate-down on empty rows is a no-op

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=()
> _cbx_selected_idx=0
> -cbx-navigate-down
> echo "idx: ${_cbx_selected_idx}"
idx: 0
```

## navigate-next with single candidate stays put

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> -cbx-generate-complist
> _cbx_selected_idx=1
> -cbx-navigate-next
> echo "idx: ${_cbx_selected_idx}"
idx: 1
```

## ensure-visible scrolls viewport up to selected row

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate" "candidate" "candidate")
> _cbx_visible_count=2
> _cbx_viewport_start=3
> _cbx_selected_idx=2
> _cbx_needs_status=0
> -cbx-navigate-ensure-visible
> echo "viewport: ${_cbx_viewport_start}"
> echo "status: ${_cbx_needs_status}"
viewport: 2
status: 1
```

## ensure-visible scrolls viewport down when selection moves below window

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate" "candidate" "candidate")
> _cbx_visible_count=2
> _cbx_viewport_start=1
> _cbx_selected_idx=4
> _cbx_needs_status=0
> -cbx-navigate-ensure-visible
> echo "viewport: ${_cbx_viewport_start}"
> echo "status: ${_cbx_needs_status}"
viewport: 3
status: 1
```

## ensure-visible leaves viewport unchanged when selection is visible

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate" "candidate" "candidate")
> _cbx_visible_count=3
> _cbx_viewport_start=2
> _cbx_selected_idx=3
> _cbx_needs_status=0
> -cbx-navigate-ensure-visible
> echo "viewport: ${_cbx_viewport_start}"
> echo "status: ${_cbx_needs_status}"
viewport: 2
status: 0
```
