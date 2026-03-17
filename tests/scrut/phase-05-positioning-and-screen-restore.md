# Phase 05: Positioning and Screen Restore Tests

Verify DSR parsing, pane geometry, popup dimensions, placement
calculations, anchor computation, and screen restore composition.

## DSR response parsing for normal row and column

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[5;10R' &&
>   echo "row=${_CBX_CURSOR_ROW} col=${_CBX_CURSOR_COL}"
row=5 col=10
```

## DSR response parsing for row 1 column 1

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[1;1R' &&
>   echo "row=${_CBX_CURSOR_ROW} col=${_CBX_CURSOR_COL}"
row=1 col=1
```

## DSR response parsing for large values

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[200;300R' &&
>   echo "row=${_CBX_CURSOR_ROW} col=${_CBX_CURSOR_COL}"
row=200 col=300
```

## DSR parsing rejects missing semicolon

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[510R' &&
>   echo "parsed" ||
>   echo "rejected"
rejected
```

## DSR parsing rejects missing escape

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse '[5;10R' &&
>   echo "parsed" ||
>   echo "rejected"
rejected
```

## DSR parsing rejects non-numeric row

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[abc;10R' &&
>   echo "parsed" ||
>   echo "rejected"
rejected
```

## DSR parsing rejects non-numeric column

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse $'\e[5;xyzR' &&
>   echo "parsed" ||
>   echo "rejected"
rejected
```

## DSR parsing rejects empty string

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-dsr-parse '' &&
>   echo "parsed" ||
>   echo "rejected"
rejected
```

## Pane geometry from LINES and COLUMNS

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   LINES=24 COLUMNS=80 &&
>   -cbx-pane-geometry &&
>   echo "h=${_CBX_PANE_HEIGHT} w=${_CBX_PANE_WIDTH}"
h=24 w=80
```

## Pane geometry fails when LINES and COLUMNS are zero

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   LINES=0 COLUMNS=0 &&
>   unset TMUX &&
>   -cbx-pane-geometry &&
>   echo "ok" ||
>   echo "failed"
failed
```

## Popup dimensions from two candidate rows

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo &&
>   -cbx-popup-rows-from-candidates &&
>   -cbx-popup-dimensions &&
>   echo "h=${_CBX_POPUP_HEIGHT} w=${_CBX_POPUP_WIDTH}"
h=4 w=9
```

## Popup dimensions from three candidates with varying lengths

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- ab checkout xyz &&
>   -cbx-popup-rows-from-candidates &&
>   -cbx-popup-dimensions &&
>   echo "h=${_CBX_POPUP_HEIGHT} w=${_CBX_POPUP_WIDTH}"
h=5 w=12
```

## Popup dimensions returns error for empty rows

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -ga _CBX_POPUP_ROWS=() &&
>   -cbx-popup-dimensions &&
>   echo "ok" ||
>   echo "failed"
failed
```

## Below placement when enough room

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_CURSOR_ROW=5 _CBX_CURSOR_COL=1 &&
>   typeset -gi _CBX_PANE_HEIGHT=24 _CBX_PANE_WIDTH=80 &&
>   typeset -gi _CBX_POPUP_HEIGHT=4 _CBX_POPUP_WIDTH=10 &&
>   typeset -ga _CBX_CANDIDATES=() &&
>   -cbx-popup-placement &&
>   echo "row=${_CBX_POPUP_ROW} col=${_CBX_POPUP_COL} dir=${_CBX_POPUP_DIRECTION}"
row=6 col=1 dir=below
```

## Above placement when not enough room below

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_CURSOR_ROW=22 _CBX_CURSOR_COL=1 &&
>   typeset -gi _CBX_PANE_HEIGHT=24 _CBX_PANE_WIDTH=80 &&
>   typeset -gi _CBX_POPUP_HEIGHT=4 _CBX_POPUP_WIDTH=10 &&
>   typeset -ga _CBX_CANDIDATES=() &&
>   -cbx-popup-placement &&
>   echo "row=${_CBX_POPUP_ROW} col=${_CBX_POPUP_COL} dir=${_CBX_POPUP_DIRECTION}"
row=18 col=1 dir=above
```

## Placement fails when no room in either direction

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_CURSOR_ROW=3 _CBX_CURSOR_COL=1 &&
>   typeset -gi _CBX_PANE_HEIGHT=5 _CBX_PANE_WIDTH=80 &&
>   typeset -gi _CBX_POPUP_HEIGHT=4 _CBX_POPUP_WIDTH=10 &&
>   typeset -ga _CBX_CANDIDATES=() &&
>   -cbx-popup-placement &&
>   echo "ok" ||
>   echo "failed"
failed
```

## Right-edge clamping keeps popup within pane

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_CURSOR_ROW=5 _CBX_CURSOR_COL=75 &&
>   typeset -gi _CBX_PANE_HEIGHT=24 _CBX_PANE_WIDTH=80 &&
>   typeset -gi _CBX_POPUP_HEIGHT=4 _CBX_POPUP_WIDTH=10 &&
>   typeset -ga _CBX_CANDIDATES=() &&
>   -cbx-popup-placement &&
>   echo "col=${_CBX_POPUP_COL}"
col=71
```

## Horizontal clamp floors at column 1

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_CURSOR_ROW=5 _CBX_CURSOR_COL=1 &&
>   typeset -gi _CBX_PANE_HEIGHT=24 _CBX_PANE_WIDTH=5 &&
>   typeset -gi _CBX_POPUP_HEIGHT=4 _CBX_POPUP_WIDTH=10 &&
>   typeset -ga _CBX_CANDIDATES=() &&
>   -cbx-popup-placement &&
>   echo "col=${_CBX_POPUP_COL}"
col=1
```

## Anchor column with prefix offsets popup left

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   PREFIX="alpha" &&
>   -cbx-capture-from-compadd -- alpha another &&
>   typeset -gi _CBX_CURSOR_COL=20 &&
>   -cbx-popup-anchor-col &&
>   echo "anchor=${REPLY}"
anchor=15
```

## Anchor column floors at 1

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   PREFIX="alpha" &&
>   -cbx-capture-from-compadd -- alpha another &&
>   typeset -gi _CBX_CURSOR_COL=3 &&
>   -cbx-popup-anchor-col &&
>   echo "anchor=${REPLY}"
anchor=1
```

## Anchor column with no candidates returns cursor column

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   typeset -gi _CBX_CURSOR_COL=15 &&
>   -cbx-popup-anchor-col &&
>   echo "anchor=${REPLY}"
anchor=15
```

## Render buffer uses CUP when placement globals set

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   typeset -gi _CBX_POPUP_ROW=10 _CBX_POPUP_COL=5 &&
>   -cbx-popup-render-buffer &&
>   [[ "${REPLY}" == *$'\e[10;5H'* ]] && echo "has-cup=yes"
has-cup=yes
```

## Render buffer falls back to relative without placement globals

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   unset _CBX_POPUP_ROW _CBX_POPUP_COL &&
>   -cbx-popup-render-buffer &&
>   [[ "${REPLY}" != *$'\e['*";"*"H"* ]] && echo "no-cup=yes"
no-cup=yes
```

## Erase buffer uses CUP when placement globals set

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_POPUP_RENDERED_LINES=3 &&
>   typeset -gi _CBX_POPUP_ROW=10 &&
>   -cbx-popup-erase-buffer &&
>   [[ "${REPLY}" == *$'\e[10;1H'* ]] && echo "has-cup=yes" &&
>   [[ "${REPLY}" == *$'\e[11;1H'* ]] && echo "has-row-2=yes" &&
>   [[ "${REPLY}" == *$'\e[12;1H'* ]] && echo "has-row-3=yes"
has-cup=yes
has-row-2=yes
has-row-3=yes
```

## Screen restore compose builds CUP sequences for saved rows

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -ga _CBX_SCREEN_SAVED=("line-one" "line-two") &&
>   typeset -gi _CBX_SCREEN_SAVE_START=10 _CBX_SCREEN_SAVE_END=11 &&
>   -cbx-screen-restore-compose &&
>   [[ "${REPLY}" == *$'\e[10;1H'* ]] && echo "has-row-10=yes" &&
>   [[ "${REPLY}" == *$'\e[11;1H'* ]] && echo "has-row-11=yes" &&
>   [[ "${REPLY}" == *"line-one"* ]] && echo "has-content-1=yes" &&
>   [[ "${REPLY}" == *"line-two"* ]] && echo "has-content-2=yes"
has-row-10=yes
has-row-11=yes
has-content-1=yes
has-content-2=yes
```

## Screen restore compose returns error for empty saved state

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -ga _CBX_SCREEN_SAVED=() &&
>   -cbx-screen-restore-compose &&
>   echo "ok" ||
>   echo "failed"
failed
```
