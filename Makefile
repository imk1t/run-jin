.PHONY: help env xcconfig supabase-start supabase-stop supabase-reset supabase-diff supabase-migrate build test clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ──────────────────────────────────────
# Environment / Secrets (1Password)
# ──────────────────────────────────────

env: ## Generate .env from 1Password (op inject)
	op inject -i .env.tpl -o .env
	@echo "✓ .env generated from 1Password"

xcconfig: env ## Generate Config.xcconfig from .env for Xcode
	@. ./.env && sed \
		-e "s|__SUPABASE_URL__|$$SUPABASE_URL|g" \
		-e "s|__SUPABASE_ANON_KEY__|$$SUPABASE_ANON_KEY|g" \
		run-jin/Config.xcconfig.template > run-jin/Config.xcconfig
	@echo "✓ Config.xcconfig generated"

# ──────────────────────────────────────
# Supabase
# ──────────────────────────────────────

supabase-start: ## Start local Supabase
	cd supabase && supabase start

supabase-stop: ## Stop local Supabase
	cd supabase && supabase stop

supabase-reset: ## Reset local DB (apply migrations + seed)
	cd supabase && supabase db reset

supabase-diff: ## Generate migration from local DB changes
	@read -p "Migration name: " name && cd supabase && supabase db diff -f $$name

supabase-migrate: ## Push migrations to remote Supabase
	cd supabase && supabase db push

supabase-types: ## Generate Swift types from Supabase schema
	cd supabase && supabase gen types swift --local > ../run-jin/Models/DTO/SupabaseTypes.swift
	@echo "✓ Swift types generated"

# ──────────────────────────────────────
# iOS Build
# ──────────────────────────────────────

SCHEME = run-jin
DESTINATION = platform=iOS Simulator,name=iPhone 17,OS=26.4

build: ## Build iOS app
	xcodebuild build \
		-project run-jin.xcodeproj \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		2>&1 | grep -E "(BUILD|error:|warning:)" || true

test: ## Run iOS tests
	xcodebuild test \
		-project run-jin.xcodeproj \
		-scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		2>&1 | grep -E "(BUILD|Test |error:|warning:|Executed)" || true

clean: ## Clean build artifacts
	xcodebuild clean -project run-jin.xcodeproj -scheme $(SCHEME) -quiet
	rm -rf DerivedData build

# ──────────────────────────────────────
# Development
# ─────────────────────────��────────────

setup: env xcconfig supabase-start ## Full dev environment setup
	@echo "✓ Development environment ready"
