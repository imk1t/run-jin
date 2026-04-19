---
name: supabase-backend
description: Supabase バックエンド（supabase/ 配下のマイグレーション、Edge Functions、RLS ポリシー、PostGIS クエリ、seed.sql、config.toml）を扱うとき、または `make supabase-*` コマンドを使うときに使用。マイグレーション必須、RLS 必須、PostGIS GEOGRAPHY パターン、H3 インデックス TEXT 保存、Edge Function の認証・CORS・エラー形式・idempotency key 規約を提供。
---

# Supabase / Backend Conventions

## Schema Changes
- スキーマ変更はすべて migration 経由（`make supabase-diff` で自動生成）
- 本番 DB を直接変更しない — migration ファイルが Source of Truth
- 配置: `supabase/migrations/<timestamp>_<desc>.sql`

## Data Patterns
- 走行ルートは PostGIS `GEOGRAPHY(LINESTRING, 4326)`
- H3 インデックスは `TEXT`（例: `8a2a1072b59ffff`）
- Timestamps は常に `TIMESTAMPTZ DEFAULT now()`
- 領地競合解決は `SELECT ... FOR UPDATE` または楽観ロック

## Security / RLS
- **新規テーブルには必ず RLS ポリシーを設定**
- ユーザーは自分のデータのみ read/write 可（明示的に共有設定したものを除く）
- `territory_cells` は誰でも read 可、write は **Edge Function 経由のみ**
- Privacy zone セルは API response から除外（`domain-rules` skill 参照）

## Edge Functions
- TypeScript（Deno runtime）、`supabase/functions/<name>/index.ts` に配置
- 1 関数 = 1 責務

### 必須パターン

**1. CORS handling (OPTIONS)**
```ts
if (req.method === "OPTIONS") {
  return new Response("ok", {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    },
  });
}
```

**2. JWT 認証 → service role 使い分け**
- Auth header から `supabaseUser.auth.getUser()` でユーザー特定
- データ操作は service role client (`SUPABASE_SERVICE_ROLE_KEY`) で実行

**3. エラーレスポンス形式**
- 形式: `{ error: string }`（必要なら `code` フィールドを追加）
- 401: 認証なし / 失敗、500: 内部エラー
- `console.error` でログ記録

**4. Idempotency key（書き込み系で必須）**
- リクエスト body に `idempotency_key: string` (UUID) を要求
- 開始時に対応行が存在するかチェック → あれば既存 ID を 200 で返却
- DB 列も `idempotency_key TEXT UNIQUE` を持たせる
- 例: `submit-run` の重複投稿防止

**5. シークレット**
- `Deno.env.get("KEY_NAME")!` で読み込み
- ハードコード禁止

## Implemented Edge Functions（参考）
| Function | 役割 |
|----------|------|
| `submit-run` | ラン完了時の session 記録 + territory cell 確定 + landmark bonus 適用 |
| `get-territory-around` | 指定座標周辺の territory cell 取得 |
| `refresh-rankings` | ランキングテーブルの再計算 |
| `check-achievements` | アチーブメント判定 |
