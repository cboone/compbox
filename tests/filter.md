# filter

## filter-init saves unfiltered data and clears filter string

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> echo "filter: [${_cbx_filter_string}]"
> echo "unfiltered: ${#_cbx_unfiltered_kinds}"
> echo "rows: ${#_cbx_row_kinds}"
filter: []
unfiltered: 2
rows: 2
```

## filter-append adds character and applies filter

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "b"
> echo "filter: ${_cbx_filter_string}"
> dump_rows
filter: b
row 1: kind=candidate id=2 text=beta desc=
```

## Filter is case-insensitive

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "B"
> dump_rows
row 1: kind=candidate id=2 text=beta desc=
```

## Filter matches on descriptions

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "xyz" "xyz" "orange"
> cbx_add_candidate 2 "abc" "abc" "apple"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "o"
> dump_rows
row 1: kind=candidate id=1 text=xyz desc=orange
```

## Filter preserves group dividers only between surviving candidates

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "apple" "apple" "" "fruits"
> cbx_add_candidate 2 "avocado" "avocado" "" "fruits"
> cbx_add_candidate 3 "ant" "ant" "" "bugs"
> cbx_add_candidate 4 "bee" "bee" "" "bugs"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "a"
> dump_rows
row 1: kind=candidate id=1 text=apple desc=
row 2: kind=candidate id=2 text=avocado desc=
row 3: kind=divider id=0 text= desc=
row 4: kind=candidate id=3 text=ant desc=
```

## Filter removes dividers when only one group survives

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "apple" "apple" "" "fruits"
> cbx_add_candidate 2 "cherry" "cherry" "" "fruits"
> cbx_add_candidate 3 "dog" "dog" "" "animals"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "r"
> dump_rows
row 1: kind=candidate id=2 text=cherry desc=
```

## No matches shows no matches message row

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "z"
> dump_rows
row 1: kind=message id=0 text=no matches desc=
```

## Empty filter restores all original rows

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "b"
> -cbx-filter-backspace
> dump_rows
row 1: kind=candidate id=1 text=alpha desc=
row 2: kind=candidate id=2 text=beta desc=
```

## filter-backspace on empty filter returns 1

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-backspace
> echo "exit: $?"
exit: 1
```

## filter-backspace removes last character

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "a"
> -cbx-filter-append "l"
> echo "before: ${_cbx_filter_string}"
> -cbx-filter-backspace
> echo "after: ${_cbx_filter_string}"
before: al
after: a
```

## Filter resets viewport and selection

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha"
> cbx_add_candidate 2 "beta" "beta"
> -cbx-generate-complist
> -cbx-filter-init
> _cbx_selected_idx=2
> _cbx_viewport_start=5
> -cbx-filter-append "a"
> echo "idx: ${_cbx_selected_idx}"
> echo "viewport: ${_cbx_viewport_start}"
idx: 1
viewport: 1
```

## Filter updates total candidates accurately

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "apple" "apple" "" "A"
> cbx_add_candidate 2 "avocado" "avocado" "" "B"
> cbx_add_candidate 3 "cherry" "cherry" "" "B"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "a"
> echo "total: ${_cbx_total_candidates}"
total: 2
```

## Substring matching not prefix-only

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "hello" "hello"
> cbx_add_candidate 2 "world" "world"
> -cbx-generate-complist
> -cbx-filter-init
> -cbx-filter-append "l"
> dump_rows
row 1: kind=candidate id=1 text=hello desc=
row 2: kind=candidate id=2 text=world desc=
```
