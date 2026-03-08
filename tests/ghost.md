# ghost

## ghost-read-suggestion returns 1 on empty POSTDISPLAY

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> POSTDISPLAY=""
> -cbx-ghost-read-suggestion
> echo "exit: $?"
exit: 1
```

## ghost-read-suggestion extracts first word

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> POSTDISPLAY="hello world"
> -cbx-ghost-read-suggestion
> echo "${_cbx_suggestion_word}"
hello
```

## ghost-read-suggestion strips SGR style sequences

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> POSTDISPLAY=$'\e[2mhello world\e[0m'
> -cbx-ghost-read-suggestion
> echo "${_cbx_suggestion_word}"
hello
```

## ghost-read-suggestion handles single word

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> POSTDISPLAY="hello"
> -cbx-ghost-read-suggestion
> echo "${_cbx_suggestion_word}"
hello
```

## ghost-read-suggestion handles stacked SGR style sequences

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> POSTDISPLAY=$'\e[1m\e[2mhello world\e[0m'
> -cbx-ghost-read-suggestion
> echo "${_cbx_suggestion_word}"
hello
```

## ghost-find-suggestion-match with unique match returns index

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate" "candidate")
> typeset -ga _cbx_row_ids=("1" "2" "3")
> typeset -ga _cbx_row_texts=("alpha" "beta" "gamma")
> typeset -ga _cbx_row_descriptions=("" "" "")
> typeset -g _cbx_suggestion_word="beta"
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
> echo "idx: ${_cbx_suggestion_idx}"
exit: 0
idx: 2
```

## ghost-find-suggestion-match returns 1 with no match

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate")
> typeset -ga _cbx_row_ids=("1" "2")
> typeset -ga _cbx_row_texts=("alpha" "beta")
> typeset -ga _cbx_row_descriptions=("" "")
> typeset -g _cbx_suggestion_word="delta"
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
exit: 1
```

## ghost-find-suggestion-match returns 1 on ambiguous matches

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "candidate")
> typeset -ga _cbx_row_ids=("1" "2")
> typeset -ga _cbx_row_texts=("alpha" "alpha")
> typeset -ga _cbx_row_descriptions=("" "")
> typeset -g _cbx_suggestion_word="alpha"
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
exit: 1
```

## ghost-find-suggestion-match skips divider rows

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate" "divider" "candidate")
> typeset -ga _cbx_row_ids=("1" "0" "2")
> typeset -ga _cbx_row_texts=("alpha" "" "beta")
> typeset -ga _cbx_row_descriptions=("" "" "")
> typeset -g _cbx_suggestion_word="beta"
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
> echo "idx: ${_cbx_suggestion_idx}"
exit: 0
idx: 3
```

## ghost-find-suggestion-match returns 1 on empty suggestion

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate")
> typeset -ga _cbx_row_ids=("1")
> typeset -ga _cbx_row_texts=("alpha")
> typeset -ga _cbx_row_descriptions=("")
> typeset -g _cbx_suggestion_word=""
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
exit: 1
```

## ghost-find-suggestion-match is case-sensitive

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> typeset -ga _cbx_row_kinds=("candidate")
> typeset -ga _cbx_row_ids=("1")
> typeset -ga _cbx_row_texts=("Alpha")
> typeset -ga _cbx_row_descriptions=("")
> typeset -g _cbx_suggestion_word="alpha"
> -cbx-ghost-find-suggestion-match
> echo "exit: $?"
exit: 1
```

## ghost-update computes suffix by removing PREFIX from word

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> PREFIX="he"
> -cbx-ghost-update "hello"
> local clean="${POSTDISPLAY#$'\e[2m'}"
> clean="${clean%$'\e[0m'}"
> echo "${clean}"
llo
```

## ghost-update uses full word when PREFIX does not match

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> PREFIX="xyz"
> -cbx-ghost-update "hello"
> local clean="${POSTDISPLAY#$'\e[2m'}"
> clean="${clean%$'\e[0m'}"
> echo "${clean}"
hello
```

## ghost-update uses full word with empty PREFIX

```scrut
$ source "$TESTDIR/helpers/setup.zsh"
> PREFIX=""
> -cbx-ghost-update "hello"
> local clean="${POSTDISPLAY#$'\e[2m'}"
> clean="${clean%$'\e[0m'}"
> echo "${clean}"
hello
```
