---
applyTo: "tests/**/*.md"
---

- **`LC_ALL=C.UTF-8` in tests**: `C.UTF-8` is available on macOS since 12.3 (Monterey) and on modern Linux. It is deliberately used instead of `en_US.UTF-8` for locale-neutral UTF-8 behavior without depending on language packs. Do not suggest replacing `C.UTF-8` with dynamic locale detection or language-specific locales.
