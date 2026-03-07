---
applyTo: "**/*.zsh"
---

- **Leading hyphen in function/file names** (e.g., `-zcm-compadd`): This is an intentional zsh plugin convention for internal/private functions. The underscore prefix (`_`) is reserved by zsh for completion functions and must not be used for non-completion internal functions. Do not suggest renaming hyphen-prefixed names to underscore-prefixed names.
