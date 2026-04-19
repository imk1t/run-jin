# Run-Jin (ラン陣) — AI Agent Guidelines

> このファイルは [AGENTS.md 規約](https://agents.md/) に従い、AI コーディングエージェント
> （Claude Code, Codex, Cursor 等）が本プロジェクトで作業するための共通コンテキストを提供する。

## Project Overview
GPS ランニング × ヘックスグリッド陣取りゲーム（日本市場向け）。
モノレポ構成: iOS (SwiftUI) + Supabase バックエンド。

## Repository Structure
```
run-jin/
├── run-jin/              # iOS app (SwiftUI)
│   ├── App/              # Entry point, Router, DI
│   ├── Core/             # Extensions, Utilities, Protocols
│   ├── Models/
│   │   ├── Domain/       # SwiftData @Model
│   │   └── DTO/          # Supabase DTO
│   ├── Services/         # Location, Running, Territory, Auth, HealthKit, ...
│   ├── Repositories/     # Protocol-based data access
│   ├── ViewModels/       # @Observable classes
│   ├── Views/            # SwiftUI views
│   └── Resources/        # Assets, Localizable.xcstrings
├── run-jinTests/         # 単体テスト
├── run-jinUITests/       # UI テスト
├── run-jin.xcodeproj/
├── supabase/             # Supabase バックエンド
│   ├── migrations/       # SQL migration (git tracked)
│   ├── functions/        # Edge Functions (TypeScript/Deno)
│   ├── seed.sql          # 初期データ
│   └── config.toml
├── .github/workflows/    # CI/CD
├── docs/                 # 申請ドキュメント等
├── .claude/              # Claude Code 用設定（skills / agents / settings）
└── Makefile              # 開発コマンド
```

## Tech Stack
- iOS: Swift 6 / SwiftUI / MapKit / CoreLocation / SwiftData / HealthKit
- Backend: Supabase (PostgreSQL + PostGIS + Edge Functions + Realtime)
- Hex Grid: H3 (SwiftyH3, resolution 10, ~50m)
- Auth: Supabase Auth (Phone SMS)
- Analytics: Firebase Analytics + Crashlytics
- Payments: StoreKit 2
- SPM packages: SwiftyH3, supabase-swift, firebase-ios-sdk

## Development Commands
```bash
make help            # 全コマンド一覧
make setup           # フルセットアップ (1Password → .env → xcconfig → supabase)
make env             # .env を 1Password から生成
make xcconfig        # Config.xcconfig を .env から生成
make build           # iOS アプリビルド
make test            # テスト実行
make supabase-start  # ローカル Supabase 起動
make supabase-diff   # DB マイグレーション生成
make supabase-types  # スキーマから Swift 型を生成
```

## Skills (`.claude/skills/`)

コーディング規約・アーキガイド・ワークフローは `.claude/skills/<name>/SKILL.md` に集約。Claude Code は `description` フィールドに基づきタスクに関連する Skill を**自動的にコンテキストへ読み込む**。明示的に呼ぶ場合は `/<skill-name>`。

### Convention Skills（コーディング規約 / アーキガイド）

| Skill | Trigger | Summary |
|-------|---------|---------|
| [swift-architecture](.claude/skills/swift-architecture/SKILL.md) | Swift/iOS コード編集時 | レイヤード MVVM+Repository, DependencyContainer, Domain/DTO 分離, strict concurrency (@MainActor / nonisolated init / AsyncStream), SwiftUI/SwiftData, ローカライズ, Swift Testing |
| [supabase-backend](.claude/skills/supabase-backend/SKILL.md) | `supabase/` 配下編集時 | Migration ベース, RLS 必須, PostGIS パターン, Edge Function (JWT auth, CORS, error 形式, idempotency key) |
| [domain-rules](.claude/skills/domain-rules/SKILL.md) | Territory / Run / Privacy / H3 関連編集時 | Territory 上書き (iOS 1.5× / server 0.5×), Privacy zone, H3 res10, Run submit idempotency, HealthKit+GPS 並行 |
| [secrets-and-env](.claude/skills/secrets-and-env/SKILL.md) | シークレット・env 編集時 | 1Password 連携, ハードコード禁止, `op://` 参照, `Bundle.main` / `Deno.env.get()` |
| [git-workflow](.claude/skills/git-workflow/SKILL.md) | branch / commit / PR 操作時 | ブランチ命名 (`feature/<issue>-<desc>`), commit format, `Closes #N`, Pre-PR チェックリスト |

### Workflow Skills（実行手順）

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [pr](.claude/skills/pr/SKILL.md) | `/pr` | build → test → `code-reviewer` agent → push → `gh pr create --base main` |

### Agents (`.claude/agents/`)

| Agent | Purpose |
|-------|---------|
| [code-reviewer](.claude/agents/code-reviewer.md) | `/review` 相当のコードレビュー専用エージェント。Convention 4 + git-workflow に基づく checklist で 🔴/🟡/🟢 評価。`pr` skill から自動起動 |

## Pre-PR Checklist
1. `make build` で警告無くコンパイル成功
2. `make test` でテスト通過
3. `code-reviewer` agent (`/review`) を起動し 🔴 blocker をすべて解消
4. PR 本文に `Closes #N` と test plan を記載
