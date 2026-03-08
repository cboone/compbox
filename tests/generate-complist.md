# generate-complist

## Empty input returns 1 and produces empty arrays

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> -cbx-generate-complist
> echo "exit: $?"
> echo "ids: ${#_cbx_row_ids}"
> echo "kinds: ${#_cbx_row_kinds}"
> echo "texts: ${#_cbx_row_texts}"
> echo "descs: ${#_cbx_row_descriptions}"
exit: 1
ids: 0
kinds: 0
texts: 0
descs: 0
```

## Single candidate produces one row

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "foo" "foo"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=foo desc=
```

## Multiple candidates in same group produce no dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "grp1"
> cbx_add_candidate 2 "beta" "beta" "" "grp1"
> cbx_add_candidate 3 "gamma" "gamma" "" "grp1"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=alpha desc=
row 2: kind=candidate id=2 text=beta desc=
row 3: kind=candidate id=3 text=gamma desc=
```

## Two groups produce one divider

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "grp1"
> cbx_add_candidate 2 "beta" "beta" "" "grp2"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=alpha desc=
row 2: kind=divider id=0 text= desc=
row 3: kind=candidate id=2 text=beta desc=
```

## Three groups produce two dividers

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" "grp1"
> cbx_add_candidate 2 "beta" "beta" "" "grp2"
> cbx_add_candidate 3 "gamma" "gamma" "" "grp3"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=alpha desc=
row 2: kind=divider id=0 text= desc=
row 3: kind=candidate id=2 text=beta desc=
row 4: kind=divider id=0 text= desc=
row 5: kind=candidate id=3 text=gamma desc=
```

## Empty display falls back to word

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "" "myword"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=myword desc=
```

## Descriptions are preserved

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "foo" "foo" "a description"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=foo desc=a description
```

## Row IDs match candidate IDs and divider IDs are 0

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 5 "alpha" "alpha" "" "A"
> cbx_add_candidate 9 "beta" "beta" "" "B"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=5 text=alpha desc=
row 2: kind=divider id=0 text= desc=
row 3: kind=candidate id=9 text=beta desc=
```

## Large candidate set all become rows

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> for (( i=1; i <= 20; i++ )); do
>   cbx_add_candidate ${i} "item${i}" "item${i}"
> done
> -cbx-generate-complist
> echo "${#_cbx_row_kinds}"
20
```

## Group transition from empty to non-empty inserts divider

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> cbx_add_candidate 1 "alpha" "alpha" "" ""
> cbx_add_candidate 2 "beta" "beta" "" "grp1"
> -cbx-generate-complist
> dump_rows
row 1: kind=candidate id=1 text=alpha desc=
row 2: kind=divider id=0 text= desc=
row 3: kind=candidate id=2 text=beta desc=
```
