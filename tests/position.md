# position

## Popup placed below when space is sufficient

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=5
> _cbx_cursor_col=10
> LINES=30
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 10 20
> echo "row: ${_cbx_popup_row}"
> echo "dir: ${_cbx_popup_direction}"
row: 6
dir: below
```

## Popup placed above when below is insufficient

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=25
> _cbx_cursor_col=10
> LINES=30
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 10 20
> echo "row: ${_cbx_popup_row}"
> echo "dir: ${_cbx_popup_direction}"
row: 15
dir: above
```

## Below preferred when both sides have equal space

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=15
> _cbx_cursor_col=10
> LINES=29
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 5 20
> echo "row: ${_cbx_popup_row}"
> echo "dir: ${_cbx_popup_direction}"
row: 16
dir: below
```

## Clamped below when neither side has full room but below is larger

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=5
> _cbx_cursor_col=10
> LINES=15
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 12 20
> echo "row: ${_cbx_popup_row}"
> echo "dir: ${_cbx_popup_direction}"
row: 6
dir: below
```

## Column aligned with insertion point

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=10
> _cbx_cursor_col=15
> LINES=30
> COLUMNS=80
> PREFIX="abc"
> -cbx-compute-position 5 20
> echo "col: ${_cbx_popup_col}"
> echo "border: ${_cbx_border_col}"
col: 12
border: 11
```

## Column clamped to minimum 2

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=10
> _cbx_cursor_col=3
> LINES=30
> COLUMNS=80
> PREFIX="abc"
> -cbx-compute-position 5 10
> echo "col: ${_cbx_popup_col}"
> echo "border: ${_cbx_border_col}"
col: 2
border: 1
```

## Horizontal overflow shifts popup left

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=5
> _cbx_cursor_col=75
> LINES=30
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 5 20
> echo "border: ${_cbx_border_col}"
> echo "col: ${_cbx_popup_col}"
border: 61
col: 62
```

## Horizontal overflow clamped to border col at least 1

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=5
> _cbx_cursor_col=5
> LINES=30
> COLUMNS=10
> PREFIX=""
> -cbx-compute-position 5 20
> echo "border: ${_cbx_border_col}"
> echo "col: ${_cbx_popup_col}"
border: 1
col: 2
```

## Above placement with popup row clamped to 1

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=4
> _cbx_cursor_col=10
> LINES=6
> COLUMNS=80
> PREFIX=""
> -cbx-compute-position 10 20
> echo "row: ${_cbx_popup_row}"
> echo "dir: ${_cbx_popup_direction}"
row: 1
dir: above
```

## available-height returns below when equal

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=15
> LINES=29
> -cbx-available-height
> echo "height: ${_cbx_avail_height}"
height: 14
```

## available-height returns above when above is larger

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> _cbx_cursor_row=20
> LINES=25
> -cbx-available-height
> echo "height: ${_cbx_avail_height}"
height: 19
```

## PREFIX with multibyte characters

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> export LC_ALL=en_US.UTF-8
> _cbx_cursor_row=5
> _cbx_cursor_col=10
> LINES=30
> COLUMNS=80
> PREFIX=$'\xe6\x97\xa5\xe6\x9c\xac'
> -cbx-compute-position 5 20
> echo "col: ${_cbx_popup_col}"
col: 6
```
