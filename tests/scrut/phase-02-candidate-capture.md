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
call_idx=1
---
id=2
word=bravo
display=bravo
group=
prefix=
suffix=
iprefix=
isuffix=
call_idx=1
---
id=3
word=charlie
display=charlie
group=
prefix=
suffix=
iprefix=
isuffix=
call_idx=1
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
call_idx=1
---
id=2
word=echo
display=echo
group=mygroup
prefix=
suffix=
iprefix=
isuffix=
call_idx=1
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

## Wrapper skips capture when compadd reports no matches

Outside a completion context, `builtin compadd` returns non-zero. The
wrapper only captures when compadd actually adds matches (returns 0).

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   _CBX_IN_COMPLETE=1 &&
>   -cbx-compadd -- alpha bravo 2>/dev/null;
>   echo "count: ${#_CBX_CANDIDATES[@]}"
count: 0
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

## Words from -a array flag are expanded into candidates

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -a mymatches=(file1 file2 file3) &&
>   -cbx-capture-from-compadd -a mymatches &&
>   echo "count: ${#_CBX_CANDIDATES[@]}" &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep '^word='
>   done
count: 3
word=file1
word=file2
word=file3
```

## Words from -k associative array flag use keys as candidates

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -A myassoc=(opt1 "desc1" opt2 "desc2") &&
>   -cbx-capture-from-compadd -k myassoc &&
>   echo "count: ${#_CBX_CANDIDATES[@]}" &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep '^word='
>   done | sort
count: 2
word=opt1
word=opt2
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

## Tab in word field round-trips through pack and unpack

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   local word=$'before\tafter' &&
>   local packed &&
>   packed="$(-cbx-candidate-pack 1 "${word}" "disp" "" "" "" "" "" 1)" &&
>   local unpacked &&
>   unpacked="$(-cbx-candidate-unpack "${packed}")" &&
>   local got="$(echo "${unpacked}" | grep '^word=' | cut -d= -f2-)" &&
>   if [[ "${got}" == "${word}" ]]; then echo "match"; else echo "mismatch: $(echo -n "${got}" | od -An -tx1)"; fi
match
```

## Newline in display field round-trips through pack and unpack

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   local display=$'line1\nline2' &&
>   local packed &&
>   packed="$(-cbx-candidate-pack 1 "myword" "${display}" "" "" "" "" "" 1)" &&
>   local unpacked &&
>   unpacked="$(-cbx-candidate-unpack "${packed}")" &&
>   echo "${unpacked}" | grep -A1 '^display='
display=line1
line2
```

## Field-count validation rejects corrupted records

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-unpack $'1\ttwo\tthree' 2>&1 || true
error: expected 9 fields, got 3
```
