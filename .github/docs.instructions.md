---
applyTo: "docs/**/*.md"
---

- **Leading hyphen in zsh function/file names** (e.g., `-cbx-compadd.zsh`): This is an intentional zsh plugin convention for internal/private functions. The underscore prefix (`_`) is reserved by zsh for completion functions. Do not suggest renaming these to underscore prefixes.
- **External workflow references in plan documents**: Plan documents may reference workflows or tools from other projects (e.g., `check-zsh`) as design inspiration or mechanism sources. These are intentional cross-project references, not files expected to exist in this repository. Do not flag them as missing.
