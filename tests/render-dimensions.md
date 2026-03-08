# render-dimensions

## Content width is max text width plus padding and popup width adds borders

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "hello" "hello"
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "content: ${_cbx_content_width}"
> echo "popup: ${_cbx_popup_width}"
content: 7
popup: 9
```

## Width accounts for descriptions

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "hello" "hello" "a description"
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "content: ${_cbx_content_width}"
> echo "popup: ${_cbx_popup_width}"
content: 22
popup: 24
```

## Width clamped to COLUMNS

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "a-very-long-candidate-name" "a-very-long-candidate-name"
> -cbx-generate-complist
> COLUMNS=20
> -cbx-render-compute-dimensions
> echo "content: ${_cbx_content_width}"
> echo "popup: ${_cbx_popup_width}"
content: 18
popup: 20
```

## Visible count capped at CBX MAX VISIBLE

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 20; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "visible: ${_cbx_visible_count}"
visible: 16
```

## Visible count equals row count when under limit

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 5; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "visible: ${_cbx_visible_count}"
visible: 5
```

## Total candidates excludes dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "A"
> cbx_add_candidate 2 "beta" "beta" "" "B"
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "rows: ${#_cbx_row_kinds}"
> echo "candidates: ${_cbx_total_candidates}"
rows: 3
candidates: 2
```

## Status line needed when rows exceed visible count

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 20; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "needs_status: ${_cbx_needs_status}"
needs_status: 1
```

## Status line needed when filter string is active

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 5; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> _cbx_filter_string="a"
> -cbx-render-compute-dimensions
> echo "needs_status: ${_cbx_needs_status}"
needs_status: 1
```

## No status line when all fit and no filter

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 5; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "needs_status: ${_cbx_needs_status}"
needs_status: 0
```

## Popup height is visible count plus 2

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 5; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "height: ${_cbx_popup_height}"
height: 7
```

## render-selected-number counts candidates up to selected index

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "divider" "candidate" "candidate")
> _cbx_selected_idx=4
> -cbx-render-selected-number
> echo "selected: ${_cbx_selected_num}"
selected: 3
```

## render-selected-number at first candidate is 1

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate")
> _cbx_selected_idx=1
> -cbx-render-selected-number
> echo "selected: ${_cbx_selected_num}"
selected: 1
```

## render-selected-number with selected index 0 is 0

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate")
> _cbx_selected_idx=0
> -cbx-render-selected-number
> echo "selected: ${_cbx_selected_num}"
selected: 0
```

## Divider rows do not contribute to width

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "divider" "candidate")
> typeset -ga _cbx_row_ids=("1" "0" "2")
> typeset -ga _cbx_row_texts=("hello" "this is a very long divider text" "world")
> typeset -ga _cbx_row_descriptions=("" "" "")
> COLUMNS=80
> -cbx-render-compute-dimensions
> echo "content: ${_cbx_content_width}"
content: 7
```
