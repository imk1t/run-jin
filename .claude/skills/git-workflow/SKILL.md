---
name: git-workflow
description: ブランチ作成、コミット、Pull Request の作成・更新、または main へのマージを行うときに使用。ブランチ命名規則 (`feature/<issue>-<desc>`)、コミットフォーマット、`Closes #N` を含む PR 本文、main ブランチ直接 push 禁止、AI コミットの Co-Authored-By などの規約を提供。
---

# Git Workflow

## Golden Rule
- **mainブランチに直接コミット・pushしない。** 全ての変更はfeatureブランチからmainへのPRを通す。

## Branching
- Branch naming: `feature/<issue-number>-<short-desc>` (e.g., `feature/8-location-service`)
- Always branch from latest `main` (`git switch main && git pull && git switch -c feature/...`)
- **1 Issue = 1 Branch = 1 PR** — Issueごとにブランチを作り、PRで`Closes #N`してIssueを自動クローズする
- Keep branches focused — one issue per branch, no scope creep

## Commits
- Commit messages: imperative mood, reference issue number
- Format: `feat: description (#N)` or `fix: description (#N)`
- Include `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>` when AI-generated

## Pull Requests
- Always created against `main` with issue reference
- PR title: concise, imperative mood, under 70 chars
- PR body must include:
  - `Closes #N` to auto-close the corresponding Issue on merge
  - Summary of changes (bullet points)
  - Test plan
- **PR must pass review agent before merge** — run `/review` first
- After PR is merged, delete the feature branch

## Workflow Summary
```
1. git switch main && git pull origin main
2. git switch -c feature/<issue-number>-<short-desc>
3. ... develop & commit ...
4. make build && make test
5. /review (review agent)
6. fix any findings
7. git push -u origin feature/<issue-number>-<short-desc>
8. gh pr create --base main --title "..." --body "Closes #N ..."
9. merge PR → Issue auto-closed → delete branch
```
