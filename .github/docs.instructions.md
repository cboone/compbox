---
applyTo: "docs/**/*.md"
---

- **Leading hyphen in zsh function/file names** (e.g., `-cbx-compadd.zsh`): This is an intentional zsh plugin convention for internal/private functions. The underscore prefix (`_`) is reserved by zsh for completion functions. Do not suggest renaming these to underscore prefixes.
