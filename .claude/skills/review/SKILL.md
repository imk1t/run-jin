---
name: review
description: 実装変更を main にマージする前のコードレビューを実行するときに使用。`/review` 起動時、PR 作成前、または品質・セキュリティ・規約遵守を確認したいときに発動。アーキテクチャ (MVVM)、ローカライズ、RLS、プライバシー、バッテリー最適化、テスト等のチェックリストに基づき、🔴 blocker / 🟡 warning / 🟢 ok で評価する。
---

Review the current changes before creating a PR.

## Instructions

You are a **code review agent** for the Run-Jin (ラン陣) project. Review all staged and unstaged changes thoroughly.

### Step 1: Gather Changes
Run `git diff main...HEAD` to see all changes on the current branch. Also run `git diff` for any unstaged changes.

### Step 2: Build & Test Verification
Run `make build` and `make test` to verify the code compiles and tests pass. Report any failures.

### Step 3: Review Checklist

Evaluate each item. For each finding, report severity (🔴 blocker / 🟡 warning / 🟢 ok) and specific file:line.

**Architecture & Patterns**
- [ ] Follows MVVM + Repository + Service pattern (see AGENTS.md / swift-conventions skill)
- [ ] ViewModels use `@Observable` (not `ObservableObject`)
- [ ] New services are protocol-based and injectable
- [ ] No business logic in Views

**Security & Privacy**
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No location data leaks (privacy zones respected)
- [ ] RLS policies set on any new Supabase tables
- [ ] No user PII in logs or analytics events

**iOS Quality**
- [ ] No compiler warnings
- [ ] SwiftData models have proper `@Model` annotation
- [ ] UI strings use String Catalogs (not hardcoded Japanese/English)
- [ ] Async code is properly `@MainActor` or `nonisolated`
- [ ] No force unwraps (`!`) unless justified
- [ ] Error handling present (no silent failures)

**Performance & Battery**
- [ ] GPS: uses `distanceFilter`, no unnecessary continuous tracking
- [ ] Map overlays: viewport-based loading, not loading all cells
- [ ] H3 computation: runs on background actor
- [ ] No blocking main thread operations

**Testing**
- [ ] New logic has unit tests
- [ ] Edge cases considered (offline, empty data, concurrent access)

**Documentation**
- [ ] Complex logic has inline comments
- [ ] AGENTS.md or related skill updated if conventions changed
- [ ] PR description will reference the GitHub issue

### Step 4: Summary
Provide a summary:
- Total findings by severity
- List of blockers that MUST be fixed
- List of warnings to consider
- Overall assessment: APPROVE / REQUEST CHANGES

### Step 5: Rule Improvement
If this review revealed a pattern that should be caught earlier:
- Suggest an update to AGENTS.md, the relevant `.claude/skills/<name>/SKILL.md`, or `.claude/settings.json`
- Explain why this rule would prevent similar issues
