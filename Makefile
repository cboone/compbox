.PHONY: lint lint-md format format-check spell help

lint: lint-md spell ## Run all linters

lint-md: ## Lint Markdown files
	npx markdownlint-cli2@0.21.0 "**/*.md"

format: ## Format files with Prettier
	npx prettier@3.8.1 --write .

format-check: ## Check formatting with Prettier
	npx prettier@3.8.1 --check .

spell: ## Run spell check
	npx cspell@9.7.0 .

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'
