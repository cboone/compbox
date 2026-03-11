## Branch Review: docs/make-new-plan

Base: main (merge base: f8df54a)
Commits: 3
Files changed: 33 (10 added, 1 modified, 22 deleted, 0 renamed)
Reviewed through: 66816ee

### Summary

This branch performs a clean-slate reset of the compbox project: it removes all prior implementation code and tests from the first attempt, then adds a comprehensive phased rebuild plan (one high-level roadmap plus nine detailed phase execution plans) that will guide the project's test-first reimplementation. The cspell dictionary was also expanded to cover terminology introduced by the new plans.

### Changes by Area

#### Documentation / Plans

All new plan files were added under `docs/plans/`:

- `2026-03-11-rebuild-compbox-test-first-phases.md`: High-level roadmap covering goals, non-goals, interaction decisions, quality strategy (Scrut, zunit, manual), zsh check/lint/format pipeline, performance/benchmarking strategy, phase roadmap overview, and cross-phase definition of done.
- `2026-03-11-phase-00-test-benchmark-foundation.md`: Test harnesses, benchmark scaffolding, CI wiring.
- `2026-03-11-phase-01-hook-lifecycle-pass-through.md`: Plugin enable/disable, Tab pass-through widget.
- `2026-03-11-phase-02-candidate-capture-data-model.md`: compadd interception, candidate packing.
- `2026-03-11-phase-03-apply-by-id-and-parity.md`: Replay insertion, parity edge cases.
- `2026-03-11-phase-04-popup-mvp-interaction.md`: Minimal popup rendering, recursive-edit keymap loop.
- `2026-03-11-phase-05-positioning-and-screen-restore.md`: DSR-based placement, tmux capture-pane restore.
- `2026-03-11-phase-06-prefix-filter-and-preview-composition.md`: Prefix filtering, ghost text preview.
- `2026-03-11-phase-07-grouping-scroll-and-status.md`: Divider rows, viewport scrolling, status display.
- `2026-03-11-phase-08-hardening-compatibility-performance.md`: Signal hardening, plugin compatibility, final budgets.

#### Removed Code (prior implementation)

All prior plugin implementation and tests were deleted:

- `compbox.plugin.zsh` (plugin entrypoint)
- `lib/cbx-enable.zsh`, `lib/cbx-disable.zsh`, `lib/cbx-complete.zsh` (lifecycle)
- `lib/-cbx-compadd.zsh`, `lib/-cbx-complete.zsh`, `lib/-cbx-apply.zsh` (completion internals)
- `lib/-cbx-generate-complist.zsh` (candidate list generation)
- `lib/position.zsh`, `lib/render.zsh`, `lib/navigate.zsh` (popup rendering)
- `lib/keymap.zsh`, `lib/filter.zsh`, `lib/screen.zsh`, `lib/ghost.zsh` (interaction)

#### Removed Tests (prior test suite)

- `tests/filter.md`, `tests/generate-complist.md`, `tests/ghost.md`
- `tests/navigate.md`, `tests/position.md`, `tests/render-dimensions.md`
- `tests/helpers/setup.zsh`

#### Configuration

- `cspell.json`: Expanded dictionary `words` list; added 11 new terms (`beautysh`, `checkbashisms`, `EPOCHREALTIME`, `reentrancy`, `reimplementation`, `setopt`, `shellcheck`, `shellharden`, `shfmt`, `zcompile`, `zunit`).

### File Inventory

**New files (10):**

1. `docs/plans/2026-03-11-rebuild-compbox-test-first-phases.md`
2. `docs/plans/2026-03-11-phase-00-test-benchmark-foundation.md`
3. `docs/plans/2026-03-11-phase-01-hook-lifecycle-pass-through.md`
4. `docs/plans/2026-03-11-phase-02-candidate-capture-data-model.md`
5. `docs/plans/2026-03-11-phase-03-apply-by-id-and-parity.md`
6. `docs/plans/2026-03-11-phase-04-popup-mvp-interaction.md`
7. `docs/plans/2026-03-11-phase-05-positioning-and-screen-restore.md`
8. `docs/plans/2026-03-11-phase-06-prefix-filter-and-preview-composition.md`
9. `docs/plans/2026-03-11-phase-07-grouping-scroll-and-status.md`
10. `docs/plans/2026-03-11-phase-08-hardening-compatibility-performance.md`

**Modified files (1):**

1. `cspell.json`

**Deleted files (22):**

1. `compbox.plugin.zsh`
2. `lib/-cbx-apply.zsh`
3. `lib/-cbx-compadd.zsh`
4. `lib/-cbx-complete.zsh`
5. `lib/-cbx-generate-complist.zsh`
6. `lib/cbx-complete.zsh`
7. `lib/cbx-disable.zsh`
8. `lib/cbx-enable.zsh`
9. `lib/filter.zsh`
10. `lib/ghost.zsh`
11. `lib/keymap.zsh`
12. `lib/navigate.zsh`
13. `lib/position.zsh`
14. `lib/render.zsh`
15. `lib/screen.zsh`
16. `tests/filter.md`
17. `tests/generate-complist.md`
18. `tests/ghost.md`
19. `tests/helpers/setup.zsh`
20. `tests/navigate.md`
21. `tests/position.md`
22. `tests/render-dimensions.md`

### Notable Changes

- **Complete code removal**: All prior implementation code (13 zsh files, ~1,467 lines) and all prior tests (7 files, ~992 lines) were deleted. The repository is now a clean slate for reimplementation.
- **Configuration update**: The cspell dictionary was expanded with terminology from the new plans (linter tool names, zsh built-ins, benchmark terms).
- **No existing plan was referenced for this branch's work**: The branch name is `docs/make-new-plan`, and the work is itself the creation of a new plan. There is no pre-existing plan that governs this branch.

### Plan Compliance

No plan governs the work on this branch. The branch's purpose is to produce the plan itself, so plan compliance evaluation is not applicable.

### Code Quality Assessment

#### Quality

This branch contains no code changes in the traditional sense: it deletes prior implementation and adds documentation. The quality evaluation therefore focuses on the plan documents themselves.

**Plan document quality is high.** The documents are well-structured and consistent across all nine phase plans. Each phase follows the same template: Objective, Depends On, In Scope, Out of Scope, Planned Changes, File-Level Plan, Scrut Tests To Add, zunit Tests To Add, Manual Checks, Benchmark Plan, Acceptance Checklist, and Rollback Triggers. This consistent structure makes the plans easy to follow and compare.

**The high-level roadmap is thorough.** It covers goals, non-goals, interaction decisions, quality strategy (with clear role definitions for Scrut, zunit, and manual testing), a detailed zsh check/lint/format pipeline with blocking vs. advisory policy, performance and benchmarking strategy with regression policy, and a cross-phase definition of done.

**Phase dependencies form a clean linear chain.** Each phase explicitly declares its dependency on the previous phase, and the scope boundaries between phases are well-defined. In-scope and out-of-scope lists prevent ambiguity about what belongs where.

#### Potential Issues

- **cspell.json formatting**: The reformatting from a single-line array to multi-line is a welcome readability improvement. No issues here.
- **Deleted code**: The prior implementation is gone. This is intentional per the plan's context section ("The first implementation attempt did not land in a stable way"). The git history preserves it if needed.
- **Old plans in done/**: Two prior plans remain in `docs/plans/done/` (the original design document and the scrut test plan). The roadmap explicitly references the original design as "the feature source of truth for intent," which is correct. No cleanup issue.

#### Completeness

The plans are self-consistent and comprehensive. Every phase specifies what files to create, what files to modify, what tests to add, what benchmarks to run, and what the acceptance criteria are. The "Deliverables After This High-Level Plan" section at the end of the roadmap calls for phase-specific plans, and all nine are present.

One minor observation: the phase plans reference creating files that the deletion commit just removed (e.g., `lib/cbx-enable.zsh`, `lib/render.zsh`). This is expected and intentional: the rebuild plan calls for recreating these files from scratch with test-first development.

#### Assessment Verdict

1. **Overall quality**: This branch is ready to merge. It cleanly removes the failed first implementation and replaces it with a well-structured, detailed rebuild plan. The documentation quality is high.
2. **Strengths**: Consistent plan template across all phases. Clear scope boundaries. Explicit dependency chain. Thoughtful quality strategy covering three testing approaches (Scrut, zunit, manual). Performance treated as a first-order concern from the start. Rollback triggers defined for every phase.
3. **Issues to address**: None blocking.
4. **Suggestions**: None. The plans are thorough and well-organized as written.
