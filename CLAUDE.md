# Run-Jin (ラン陣) — AI Development Guidelines

## Project Overview
GPS running app with hex-grid territory conquest for the Japan market.
Monorepo: iOS (SwiftUI) + Supabase backend.

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

## Rules (`.claude/rules/`)

Detailed conventions and rules are managed as individual rule files with glob-based activation:

| File | Scope | Summary |
|------|-------|---------|
| `swift-conventions.md` | `run-jin/**/*.swift` | MVVM+Repository pattern, @Observable, strict concurrency, String Catalogs, no force unwraps |
| `supabase-conventions.md` | `supabase/**` | Migration-based schema changes, RLS必須, PostGIS patterns, Edge Function conventions |
| `git-workflow.md` | `**` | Branch naming (`feature/<issue>-<desc>`), commit format, PR must pass `/review` |
| `ai-agent-workflow.md` | `**` | Pre-PR review agent flow, review checklist, self-improvement rules for updating rules |
| `secrets-and-env.md` | `.env*`, `*.xcconfig*` | 1Password integration, never hardcode secrets, `op://` references |

## Slash Commands (`.claude/commands/`)

| Command | Purpose |
|---------|---------|
| `/review` | Launch review agent to evaluate changes before PR |
| `/pr` | Build → test → review → create PR (full flow) |
| `/improve-rules` | Audit and improve rules, settings, and commands |
