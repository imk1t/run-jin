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

規約・ワークフローはすべて `.claude/skills/<name>/SKILL.md` に統一管理。Claude Code は `description` フィールドに基づきタスクに関連する Skill を**自動的にコンテキストへ読み込む**。明示的に呼ぶ場合は `/<skill-name>` で起動可。

### Convention Skills（コーディング規約）

| Skill | Trigger | Summary |
|-------|---------|---------|
| [swift-conventions](.claude/skills/swift-conventions/SKILL.md) | Swift/iOS コード編集時 | MVVM+Repository, @Observable, strict concurrency, String Catalogs, no force unwraps |
| [supabase-conventions](.claude/skills/supabase-conventions/SKILL.md) | `supabase/` 配下編集時 | Migration ベースのスキーマ変更, RLS 必須, PostGIS, Edge Function 規約 |
| [git-workflow](.claude/skills/git-workflow/SKILL.md) | branch / commit / PR 操作時 | ブランチ命名 (`feature/<issue>-<desc>`), commit format, `/review` 通過必須 |
| [ai-agent-workflow](.claude/skills/ai-agent-workflow/SKILL.md) | PR 前チェック / ルール更新時 | Pre-PR review エージェントフロー, レビュー チェックリスト, スキル改善プロセス |
| [secrets-and-env](.claude/skills/secrets-and-env/SKILL.md) | シークレット・env 編集時 | 1Password 連携, ハードコード禁止, `op://` 参照 |

### Workflow Skills（実行手順）

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [review](.claude/skills/review/SKILL.md) | `/review` | Review エージェントを起動して変更を評価（PR 前必須） |
| [pr](.claude/skills/pr/SKILL.md) | `/pr` | build → test → review → create PR の一連フロー |
| [improve-rules](.claude/skills/improve-rules/SKILL.md) | `/improve-rules` | ルール・設定・スキルを監査して改善 |

## Pre-PR Checklist
1. `make build` で警告無くコンパイル成功
2. `make test` でテスト通過
3. `/review` を実行し 🔴 blocker をすべて解消
4. PR 本文に `Closes #N` と test plan を記載
