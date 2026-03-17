# Phase 04: Popup MVP Interaction Tests

Verify visible-row projection, rendering, navigation, and accept/cancel
state transitions for the popup interaction loop.

## Row projection from captured candidates

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   local tab=$'\t' &&
>   for row in "${_CBX_POPUP_ROWS[@]}"; do
>     printf 'id=%s display=%s\n' "${row%%${tab}*}" "${row#*${tab}}"
>   done
id=1 display=alpha
id=2 display=bravo
id=3 display=charlie
```

## Row projection uses display field from -d array

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -a descs=("Alpha Label" "Bravo Label") &&
>   -cbx-capture-from-compadd -d descs -- alpha bravo &&
>   -cbx-popup-rows-from-candidates &&
>   local tab=$'\t' &&
>   for row in "${_CBX_POPUP_ROWS[@]}"; do
>     printf 'id=%s display=%s\n' "${row%%${tab}*}" "${row#*${tab}}"
>   done
id=1 display=Alpha Label
id=2 display=Bravo Label
```

## Row projection decodes escaped display fields

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local w=$'tab\there' &&
>   -cbx-capture-from-compadd -- "${w}" &&
>   -cbx-popup-rows-from-candidates &&
>   local tab=$'\t' &&
>   local row="${_CBX_POPUP_ROWS[1]}" &&
>   printf '%s\n' "${row#*${tab}}" | cat -vt
tab^Ihere
```

## Minimal popup frame contains expected structure

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   -cbx-popup-render-buffer &&
>   echo "lines=${_CBX_POPUP_RENDERED_LINES}" &&
>   [[ "${REPLY}" == *"┌"*"┐"* ]] && echo "has-top-border=yes" &&
>   [[ "${REPLY}" == *"└"*"┘"* ]] && echo "has-bottom-border=yes" &&
>   [[ "${REPLY}" == *"│"*"aa"*"│"* ]] && echo "has-row-aa=yes" &&
>   [[ "${REPLY}" == *"│"*"bb"*"│"* ]] && echo "has-row-bb=yes"
lines=4
has-top-border=yes
has-bottom-border=yes
has-row-aa=yes
has-row-bb=yes
```

## Render highlights first row when selected is 1

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   -cbx-popup-render-buffer &&
>   local hl="${REPLY#*$'\e[7m'}" &&
>   hl="${hl%%$'\e[0m'*}" &&
>   echo "highlighted=[${hl}]"
highlighted=[ aa ]
```

## Selection update after next highlights second row

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   -cbx-popup-next &&
>   -cbx-popup-render-buffer &&
>   local hl="${REPLY#*$'\e[7m'}" &&
>   hl="${hl%%$'\e[0m'*}" &&
>   echo "highlighted=[${hl}]"
highlighted=[ bb ]
```

## Selection update after prev highlights first row

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- aa bb &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=2 &&
>   -cbx-popup-prev &&
>   -cbx-popup-render-buffer &&
>   local hl="${REPLY#*$'\e[7m'}" &&
>   hl="${hl%%$'\e[0m'*}" &&
>   echo "highlighted=[${hl}]"
highlighted=[ aa ]
```

## Wrap at bottom boundary

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=3 &&
>   -cbx-popup-next &&
>   echo "${_CBX_POPUP_SELECTED}"
1
```

## Wrap at top boundary

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   -cbx-popup-prev &&
>   echo "${_CBX_POPUP_SELECTED}"
3
```

## Accept state sets apply-id from selected row

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=2 &&
>   local tab=$'\t' &&
>   local row="${_CBX_POPUP_ROWS[${_CBX_POPUP_SELECTED}]}" &&
>   typeset -g _CBX_APPLY_ID="${row%%${tab}*}" &&
>   typeset -g _CBX_POPUP_ACTION="accept" &&
>   echo "action=${_CBX_POPUP_ACTION}" &&
>   echo "apply_id=${_CBX_APPLY_ID}"
action=accept
apply_id=2
```

## Cancel state does not set apply-id

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -g _CBX_POPUP_ACTION="cancel" &&
>   echo "action=${_CBX_POPUP_ACTION}" &&
>   echo "apply_id=${_CBX_APPLY_ID:-unset}"
action=cancel
apply_id=unset
```

## No-match path skips popup

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   _CBX_NMATCHES=0 &&
>   -cbx-complete-should-popup &&
>   echo "popup: yes" ||
>   echo "popup: no"
popup: no
```

## Single-match path skips popup

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   _CBX_NMATCHES=1 &&
>   -cbx-complete-should-popup &&
>   echo "popup: yes" ||
>   echo "popup: no"
popup: no
```

## Erase buffer clears rendered lines

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   typeset -gi _CBX_POPUP_RENDERED_LINES=4 &&
>   -cbx-popup-erase-buffer &&
>   printf '%s\n' "${REPLY}" | cat -v
^[7
^M^[[2K
^M^[[2K
^M^[[2K
^M^[[2K^[8^[[?25h
```

## Rendered lines count matches row count plus borders

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-popup-rows-from-candidates &&
>   typeset -gi _CBX_POPUP_SELECTED=1 &&
>   -cbx-popup-render-buffer &&
>   echo "${_CBX_POPUP_RENDERED_LINES}"
5
```
