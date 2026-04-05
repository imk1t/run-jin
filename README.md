# Run-Jin (ラン陣)

> 毎日のランニングが、天下取りに変わる

GPS ランニング × 陣取りゲームアプリ。走った場所がヘックスグリッドで自分の領地になり、他のランナーと陣地を奪い合う。

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS | Swift / SwiftUI / MapKit / CoreLocation / SwiftData |
| Backend | Supabase (PostgreSQL + PostGIS + Edge Functions + Realtime) |
| Hex Grid | Uber H3 (resolution 10, ~50m) |
| Auth | Supabase Auth (Phone SMS) |
| Analytics | Firebase Analytics + Crashlytics |
| Payments | StoreKit 2 |

## Repository Structure

```
run-jin/
├── run-jin/              # iOS app (SwiftUI)
├── run-jin.xcodeproj/
├── run-jinTests/
├── run-jinUITests/
├── supabase/             # Supabase backend
│   ├── config.toml
│   ├── migrations/
│   ├��─ functions/
│   └── seed.sql
├── .github/workflows/    # CI/CD
├── .env.tpl              # 1Password secret template
├── Makefile              # Dev commands
└── CLAUDE.md             # AI dev guidelines
```

## Prerequisites

- Xcode 16+
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`)
- Docker (for local Supabase)

## Setup

```bash
# 1. Clone
git clone https://github.com/imk1t/run-jin.git
cd run-jin

# 2. Generate secrets from 1Password
make env        # .env from 1Password vault
make xcconfig   # Config.xcconfig for Xcode

# 3. Start local Supabase
make supabase-start

# 4. Open in Xcode
open run-jin.xcodeproj
```

## Development Commands

```bash
make help           # Show all commands
make setup          # Full dev environment setup
make build          # Build iOS app
make test           # Run tests
make supabase-reset # Reset local DB
make supabase-diff  # Generate migration from changes
make supabase-types # Generate Swift types from schema
```

## Environment Variables

Secrets are managed via 1Password. Template: `.env.tpl`

```bash
# Generate .env from 1Password vault "run-jin"
op inject -i .env.tpl -o .env
```

Required 1Password items in vault `run-jin`:
- `supabase` — url, anon-key, service-role-key, db-password
- `firebase` — api-key, project-id

## License

Private — All rights reserved.
