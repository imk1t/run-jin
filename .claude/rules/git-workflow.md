---
description: Git workflow and branch/PR conventions
globs: ["**"]
---

# Git Workflow

## Branching
- Branch naming: `feature/<issue-number>-<short-desc>` (e.g., `feature/8-location-service`)
- Always branch from `main`
- Keep branches focused — one issue per branch

## Commits
- Commit messages: imperative mood, reference issue number
- Format: `feat: description (#N)` or `fix: description (#N)`
- Include `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>` when AI-generated

## Pull Requests
- Always created against `main` with issue reference
- **PR must pass review agent before merge** — run `/review` first
- Include test plan in PR description
- Reference issue with `Closes #N` or `Refs #N`
