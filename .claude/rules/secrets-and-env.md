---
description: Secret management and environment variable rules
globs: [".env*", "*.xcconfig*", "supabase/config.toml"]
---

# Secrets & Environment Variables

## 1Password Integration
- Secrets are managed via 1Password CLI (`op`)
- Template: `.env.tpl` (committed, contains `op://` references)
- Generated: `.env` (gitignored, never commit)
- iOS config: `Config.xcconfig` (gitignored, generated from `.env`)

## Commands
```bash
make env       # Generate .env from 1Password vault
make xcconfig  # Generate Config.xcconfig from .env
make setup     # Full setup including secrets
```

## Rules
- **NEVER hardcode secrets** in source code, config files, or commit history
- Always use `op://` references in `.env.tpl` for new secrets
- Access secrets in iOS via `Bundle.main.infoDictionary` (from xcconfig)
- Supabase Edge Functions access secrets via `Deno.env.get()`
- `GoogleService-Info.plist` is gitignored — generate locally
- If a new secret is needed, add it to `.env.tpl` first, then document in README
