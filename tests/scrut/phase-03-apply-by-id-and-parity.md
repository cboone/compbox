# Phase 03: Apply by Id and Parity Tests

Verify apply argument reconstruction, source-call linkage, and flow
control for completion edge cases.

## Apply resolves candidate by id and extracts selected word

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   _CBX_APPLY_ID=2 &&
>   -cbx-apply-resolve 2 &&
>   echo "word=${REPLY}"
word=bravo
```

## Apply resolve sets completion state from candidate record

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   PREFIX="pre" SUFFIX="suf" IPREFIX="ipre" ISUFFIX="isuf" &&
>   -cbx-capture-from-compadd -- alpha &&
>   -cbx-apply-resolve 1 &&
>   echo "prefix=${_CBX_RESOLVE_PREFIX}" &&
>   echo "suffix=${_CBX_RESOLVE_SUFFIX}" &&
>   echo "iprefix=${_CBX_RESOLVE_IPREFIX}" &&
>   echo "isuffix=${_CBX_RESOLVE_ISUFFIX}"
prefix=pre
suffix=suf
iprefix=ipre
isuffix=isuf
```

## Apply resolve extracts replay options from raw args

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -J mygroup -S '/' -- alpha bravo &&
>   -cbx-apply-resolve 1 &&
>   printf '%s\n' "${reply[@]}"
-J
mygroup
-S
/
```

## Apply resolve drops -d display array from replay

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -a descs=("Alpha Label" "Bravo Label") &&
>   -cbx-capture-from-compadd -d descs -J grp -- alpha bravo &&
>   -cbx-apply-resolve 1 &&
>   printf '%s\n' "${reply[@]}"
-J
grp
```

## Apply resolve drops -a array flag from replay

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -a files=(f1 f2) &&
>   -cbx-capture-from-compadd -a -J grp files &&
>   -cbx-apply-resolve 1 &&
>   echo "word=${REPLY}" &&
>   printf '%s\n' "${reply[@]}"
word=f1
-J
grp
```

## Apply resolve drops -k key flag from replay

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   local -A opts=(onlykey "val") &&
>   -cbx-capture-from-compadd -k -J grp opts &&
>   -cbx-apply-resolve 1 &&
>   echo "word=${REPLY}" &&
>   printf '%s\n' "${reply[@]}"
word=onlykey
-J
grp
```

## Duplicate words from separate compadd calls map to correct source call

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -J first-group -- samename &&
>   -cbx-capture-from-compadd -J second-group -- samename &&
>   -cbx-apply-resolve 1 &&
>   echo "id1-group: ${reply[2]}" &&
>   -cbx-apply-resolve 2 &&
>   echo "id2-group: ${reply[2]}"
id1-group: first-group
id2-group: second-group
```

## Packed candidate records include call_idx field

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo &&
>   -cbx-capture-from-compadd -- charlie &&
>   for packed in "${_CBX_CANDIDATES[@]}"; do
>     -cbx-candidate-unpack "${packed}" | grep '^call_idx='
>   done
call_idx=1
call_idx=1
call_idx=2
```

## Resolve fails for nonexistent id

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha &&
>   -cbx-apply-resolve 999 &&
>   echo "resolved" ||
>   echo "not found"
not found
```

## No-match path skips custom popup

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-complete-should-popup &&
>   echo "popup: yes" ||
>   echo "popup: no"
popup: no
```

## Single-match path skips custom popup

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- only-one &&
>   -cbx-complete-should-popup &&
>   echo "popup: yes" ||
>   echo "popup: no"
popup: no
```

## Multiple-match path activates custom popup

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   -cbx-candidate-reset &&
>   -cbx-capture-from-compadd -- alpha bravo charlie &&
>   -cbx-complete-should-popup &&
>   echo "popup: yes" ||
>   echo "popup: no"
popup: yes
```

## Pack and unpack round-trip preserves call_idx

```scrut
$ source "${TESTDIR}/../helpers/setup.zsh" &&
>   cbx_test_setup &&
>   local packed &&
>   packed="$(-cbx-candidate-pack 5 myword "My Label" grp pre suf ipre isuf 3)" &&
>   -cbx-candidate-unpack "${packed}" | grep -E '^(id|call_idx)='
id=5
call_idx=3
```
