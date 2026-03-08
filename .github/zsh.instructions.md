---
applyTo: "**/*.zsh"
---

- **Leading hyphen in function/file names** (e.g., `-cbx-compadd`): This is an intentional zsh plugin convention for internal/private functions. The underscore prefix (`_`) is reserved by zsh for completion functions and must not be used for non-completion internal functions. Do not suggest renaming hyphen-prefixed names to underscore-prefixed names.
- **`${0:A:h}` for plugin root directory**: In zsh, `$0` at the top level of a sourced file is set to the path of that file (not the shell name, as in bash). `${0:A:h}` is the standard idiom used by virtually all zsh plugin frameworks (oh-my-zsh, zinit, etc.) to resolve the plugin root directory. Do not suggest replacing `$0` with `${(%):-%x}` or `%N` expansions.
