---
description: Supabase backend conventions for run-jin
globs: ["supabase/**"]
---

# Supabase / Backend Conventions

## Schema Changes
- All schema changes via migrations (`make supabase-diff` to auto-generate)
- Never modify production DB directly — always through migration files
- Migration files in `supabase/migrations/` are the source of truth

## Edge Functions
- Written in TypeScript (Deno runtime)
- Located in `supabase/functions/<name>/index.ts`
- Each function has a single responsibility

## Security
- Always set RLS (Row Level Security) policies on new tables
- Users can only read/write their own data unless explicitly shared
- Territory cells are publicly readable, write via Edge Functions only
- Privacy zones must filter user data from API responses

## Data Patterns
- Use `SELECT ... FOR UPDATE` for territory conflict resolution
- Store routes as PostGIS `GEOGRAPHY(LINESTRING, 4326)`
- H3 indices stored as `TEXT` (e.g., `8a2a1072b59ffff`)
- Timestamps always `TIMESTAMPTZ` with `DEFAULT now()`
