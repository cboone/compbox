# Phase 02: Candidate Capture Tests

Verify compadd interception, candidate packing, and capture gating.

## Packed candidate entries for simple input

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}"
>     echo "---"
>   done
id=1
word=alpha
display=alpha
group=
prefix=
suffix=
iprefix=
isuffix=
---
id=2
word=bravo
display=bravo
group=
prefix=
suffix=
iprefix=
isuffix=
---
id=3
word=charlie
display=charlie
group=
prefix=
suffix=
iprefix=
isuffix=
---
```

## Packed candidate entries for grouped input

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -J mygroup -- delta echo &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}"
>     echo "---"
>   done
id=1
word=delta
display=delta
group=mygroup
prefix=
suffix=
iprefix=
isuffix=
---
id=2
word=echo
display=echo
group=mygroup
prefix=
suffix=
iprefix=
isuffix=
---
```

## IDs are stable and monotonic within an invocation

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- first second &&
>   -cbx-capture-from-compadd -- third &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep '^id='
>   done
id=1
id=2
id=3
```

## Outside-gate compadd calls are not captured

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-compadd -- alpha bravo 2>/dev/null;
>   echo "count: ${#_CBX_CANDIDATES[@]}"
count: 0
```

## Query-mode compadd calls are not captured

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   _CBX_IN_COMPLETE=1 &&
>   -cbx-compadd -O somevar -- alpha bravo 2>/dev/null;
>   echo "count: ${#_CBX_CANDIDATES[@]}"
count: 0
```

## Inside-gate compadd calls are captured

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   _CBX_IN_COMPLETE=1 &&
>   -cbx-compadd -- alpha bravo 2>/dev/null;
>   echo "count: ${#_CBX_CANDIDATES[@]}"
count: 2
```

## Duplicate display strings remain distinct by id

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- samename samename &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep -E '^(id|word)='
>   done
id=1
word=samename
id=2
word=samename
```

## Capture state resets between independent completion invocations

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- first-run &&
>   echo "after first: ${#_CBX_CANDIDATES[@]} candidates" &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- second-run-a second-run-b &&
>   echo "after second: ${#_CBX_CANDIDATES[@]} candidates" &&
>   -cbx-candidate-unpack "${_CBX_CANDIDATES[1]}" | grep '^id='
after first: 1 candidates
after second: 2 candidates
id=1
```

## Display strings from -d array override word values

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -a descs=("Alpha Label" "Bravo Label") &&
>   -cbx-capture-from-compadd -d descs -- alpha bravo &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep -E '^(word|display)='
>   done
word=alpha
display=Alpha Label
word=bravo
display=Bravo Label
```

## Unsorted group flag (-V) is captured like sorted group (-J)

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -V unsorted-group -- item &&
>   -cbx-candidate-unpack "${_CBX_CANDIDATES[1]}" | grep '^group='
group=unsorted-group
```

## Raw compadd args are stored for replay

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -J grp -- alpha bravo &&
>   echo "raw entries: ${#_CBX_CAND_RAW_ARGS[@]}"
raw entries: 1
```
