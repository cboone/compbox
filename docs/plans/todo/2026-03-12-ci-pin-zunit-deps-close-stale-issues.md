# Pin zunit CI dependencies and close stale issues

## Context

Four open issues (#12, #15, #16, #18) relate to CI improvements. Issue #12 requests `zsh -n` syntax checking, which is already fully implemented via `scripts/check-zsh.zsh` and the `make check-zsh` target in CI. Issues #15, #16, and #18 are duplicates, all requesting that the zunit CI dependencies (revolver, color.zsh, zunit) be pinned to specific versions with checksum verification, matching the pattern already used for shfmt, shellharden, and hyperfine.

## Plan

### 1. Close issue #12 as already done

Comment on #12 explaining that all acceptance criteria are met:

- CI runs `zsh -n` on all `.zsh` files via `make check-zsh` (in `scripts/check-zsh.zsh`, tool 1 of 7)
- Workflow fails on syntax errors (non-zero exit code propagates)
- Local developer check: `make check-zsh` (project uses `scripts/` + Makefile, not `bin/`)

Then close the issue.

### 2. Pin zunit dependencies in CI (addresses #15, closes #16 and #18 as dupes)

**File to modify:** `.github/workflows/ci.yml` (lines 90-99)

Replace the single "Install zunit and dependencies" step with three individual steps, each following the existing pinned-tool pattern (env vars for version/hash, download, verify, install).

#### Step 1: Install revolver

- Source: `molovo/revolver` at commit `6424e6cb14da38dc5d7760573eb6ecb2438e9661`
- Download from pinned raw.githubusercontent.com URL
- Verify SHA256 checksum (to be computed during implementation)
- Install to `/usr/local/bin/revolver`

#### Step 2: Install color

- Source: `molovo/color` at commit `57c9cd51c0495a3faffb203c8db74e0f60f3db73`
- Download from pinned raw.githubusercontent.com URL
- Verify SHA256 checksum (to be computed during implementation)
- Install to `/usr/local/bin/color` (no extension, preserving current behavior)

#### Step 3: Install zunit

- Source: `zunit-zsh/zunit` tag `v0.8.2` at commit `bce183c39a3b51a3dd838835516a37222aad921f`
- Clone with `--branch v0.8.2 --depth 1`
- Verify HEAD commit SHA matches expected value (equivalent to checksum for git content)
- Build with `./build.zsh` and install to `/usr/local/bin/zunit`

### 3. Close duplicate issues

- Close #16 as duplicate of #15
- Close #18 as duplicate of #15

### 4. Commits

- `fix: pin zunit CI dependencies to commit SHAs with verification (#15)`: the CI workflow change
- Issue management (close #12, #16, #18) via `gh` commands, no code commits needed

## Verification

1. Run `actionlint` on the modified workflow file to catch YAML syntax errors
2. Push the branch and verify the `test-zunit` CI job passes with all three pinned dependencies
3. Confirm checksum verification steps show "OK" in the CI logs
