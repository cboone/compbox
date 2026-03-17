.PHONY: lint lint-md spell test test-scrut test-scrut-update test-zunit check-zsh format-zsh verify bench bench-baseline help

lint: lint-md spell ## Run all linters

lint-md: ## Lint Markdown files
	npx markdownlint-cli2@0.21.0 "**/*.md"

test: test-scrut test-zunit ## Run all tests

test-scrut: ## Run scrut tests
	scrut test --shell zsh tests/scrut/*.md

test-scrut-update: ## Update scrut test snapshots
	scrut update --shell zsh tests/scrut/*.md

test-zunit: ## Run zunit tests
	zunit tests/zunit/*.zunit

check-zsh: ## Check zsh scripts for syntax and lint issues
	zsh scripts/check-zsh.zsh

format-zsh: ## Format zsh scripts with shfmt
	zsh scripts/format-zsh.zsh

verify: check-zsh test ## Run checks and tests

bench: ## Run benchmarks
	zsh scripts/bench/run.zsh

bench-baseline: ## Capture benchmark baseline
	zsh scripts/bench/run.zsh --baseline

spell: ## Run spell check
	npx cspell@9.7.0 --dot .

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'
