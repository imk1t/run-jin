---
name: secrets-and-env
description: シークレット・環境変数・設定ファイル（.env, .env.tpl, Config.xcconfig, supabase/config.toml, GoogleService-Info.plist, Edge Function の env）を追加・編集するときに使用。1Password CLI 連携、`op://` 参照テンプレート、ハードコード禁止、iOS では Bundle.main 経由、Edge Function では `Deno.env.get()` などの規約を提供。
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
