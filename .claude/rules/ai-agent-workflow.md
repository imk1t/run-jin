---
description: AI agent workflow rules — PR creation, review, and self-improvement
globs: ["**"]
---

# AI Agent Workflow

## Before Creating a PR
1. Run `make build` to verify compilation
2. Run `make test` to verify tests pass
3. Launch a **Review Agent** (`/review`) to review all changes
4. Address all 🔴 blocker findings before creating the PR
5. Include test plan in PR description

## Review Agent Checklist
The review agent evaluates:
- Code compiles without warnings
- No hardcoded secrets or API keys
- New code follows MVVM + Repository pattern
- SwiftData models have proper `@Model` annotation
- RLS policies set on new Supabase tables
- Japanese UI strings use String Catalogs
- **Localization**: 新しいUI文字列に英語翻訳が `Localizable.xcstrings` に追加されている
- **Localization**: カスタムView/関数でユーザー向け文字列パラメータが `LocalizedStringKey` 型を使用している（`String` 型だと翻訳されない）
- Privacy: no location data leaks in API responses
- Battery: GPS usage is optimized (distanceFilter, background modes)
- Performance: Map overlays use viewport-based loading
- Tests cover core logic (services, repositories)

## Self-Improvement Rules

### When to Update Rules
Rules (`.claude/rules/*.md`) should be updated when:
- A new architectural pattern or convention is established
- A new SPM package or dependency is added
- A coding convention is discovered to be wrong or incomplete
- A review agent finding reveals a missing guideline
- The project structure changes

### When to Update Settings/Hooks
Update `.claude/settings.json` when:
- A new pre-commit check is needed
- The review agent checklist needs expansion
- New file patterns need special handling
- Build or test commands change

### Process
1. Make the rule change in the appropriate `.claude/rules/*.md` file
2. Include the rule change in the same PR as the code that motivated it
3. Add a comment in the PR explaining why the rule was added/changed
4. Run `/improve-rules` periodically to audit and refine rules
