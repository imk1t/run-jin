# Run-Jin (ラン陣) — AI Development Guidelines

## Project Overview
GPS running app with hex-grid territory conquest for the Japan market.
Monorepo: iOS (SwiftUI) + Supabase backend.

## Architecture
- **Pattern**: MVVM + Repository + Service Layer
- **Flow**: `View (SwiftUI) → ViewModel (@Observable) → Repository (protocol) → Service / SwiftData / Supabase`
- **Concurrency**: Strict concurrency enabled. ViewModels are `@MainActor` by default. Use `nonisolated` or custom actors for background work.
- **Offline-first**: SwiftData local → Supabase sync when online.

## Project Structure
```
run-jin/           # iOS app
  App/             # Entry point, Router, DI
  Core/            # Extensions, Utilities, Protocols
  Models/          # Domain/ (SwiftData @Model), DTO/ (Supabase)
  Services/        # Location, Running, Territory, Auth, Network, Privacy, StoreKit, Analytics
  Repositories/    # Protocol-based data access
  ViewModels/      # @Observable classes
  Views/           # SwiftUI views
  Resources/       # Assets, Localizable.xcstrings
supabase/          # Supabase backend
  migrations/      # SQL migrations (git tracked)
  functions/       # Edge Functions (TypeScript/Deno)
  seed.sql         # Initial data
```

## Tech Stack
- iOS: Swift 6 / SwiftUI / MapKit / CoreLocation / SwiftData
- Backend: Supabase (PostgreSQL + PostGIS + Edge Functions + Realtime)
- Hex Grid: Uber H3 (h3-swift, resolution 10)
- Auth: Supabase Auth (Phone SMS)
- SPM packages: h3-swift, supabase-swift, firebase-ios-sdk

## Development Commands
```bash
make help           # Show all commands
make setup          # Full dev setup (1Password → .env → xcconfig → supabase)
make env            # Generate .env from 1Password
make build          # Build iOS app
make test           # Run tests
make supabase-start # Start local Supabase
make supabase-diff  # Generate DB migration
make supabase-types # Generate Swift types from schema
```

## Environment Variables
Secrets are managed via 1Password CLI (`op`).
- Template: `.env.tpl` (committed)
- Generated: `.env` (gitignored)
- iOS config: `Config.xcconfig` (gitignored, generated from `.env`)
- **NEVER hardcode secrets.** Always use `op://` references in `.env.tpl`.

## Coding Conventions

### Swift / iOS
- Use `@Observable` (not `ObservableObject`) for ViewModels
- Use `@Query` for SwiftData reads in Views
- Use `AsyncStream` for reactive data (not Combine unless necessary)
- Prefer `NavigationStack` with typed `NavigationPath`
- All UI strings must go through String Catalogs (`Localizable.xcstrings`)
- Japanese is the primary language; English is secondary
- Minimum deployment target: iOS 17

### Supabase / Backend
- All schema changes via migrations (`make supabase-diff`)
- Edge Functions in TypeScript (Deno runtime)
- Always set RLS policies on new tables
- Use `SELECT ... FOR UPDATE` for territory conflict resolution
- Store routes as PostGIS `GEOGRAPHY(LINESTRING, 4326)`

### Git Workflow
- Branch naming: `feature/<issue-number>-<short-desc>` (e.g., `feature/8-location-service`)
- Commit messages: imperative mood, reference issue number
- PRs: Always created against `main` with issue reference
- **PR must pass review agent before merge** (see below)

## AI Agent Workflow

### Before Creating a PR
1. Run `make build` to verify compilation
2. Run `make test` to verify tests pass
3. Launch a **Review Agent** (see `.claude/settings.json` hooks) to review changes
4. Address all review findings before creating the PR
5. Include test plan in PR description

### Review Agent Checklist
The review agent evaluates:
- [ ] Code compiles without warnings
- [ ] No hardcoded secrets or API keys
- [ ] New code follows MVVM + Repository pattern
- [ ] SwiftData models have proper relationships
- [ ] RLS policies set on new Supabase tables
- [ ] Japanese UI strings use String Catalogs
- [ ] Privacy: no location data leaks in API responses
- [ ] Battery: GPS usage is optimized (distanceFilter, background modes)
- [ ] Performance: Map overlays use viewport-based loading
- [ ] Tests cover core logic (services, repositories)

## Self-Improvement Rules

### When to Update This File
This CLAUDE.md should be updated when:
- A new architectural pattern or convention is established
- A new SPM package or dependency is added
- A coding convention is discovered to be wrong or incomplete
- A review agent finding reveals a missing guideline
- The project structure changes (new folders, renamed files)

### When to Update `.claude/settings.json`
Update hooks/settings when:
- A new pre-commit check is needed
- The review agent checklist needs expansion
- New file patterns need special handling
- Build or test commands change

### Process
When updating rules:
1. Make the change in CLAUDE.md or settings
2. Include the rule change in the same PR as the code that motivated it
3. Add a comment explaining why the rule was added/changed
