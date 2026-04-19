---
name: pr
description: feature ブランチで Pull Request を作成するときに使用。`/pr` 起動時、または「PR 作って」「PR 出して」と依頼されたときに発動。事前チェック（make build, make test）→ review skill 実行 → ブランチ push → `gh pr create --base main` の順で `Closes #N` 付き PR を作成する。
---

Create a pull request for the current branch.

## Instructions

### Step 0: Branch Check
- Verify you are NOT on `main`. If on main, abort — all work must be on a feature branch.
- Verify branch name follows `feature/<issue-number>-<short-desc>` pattern.
- Identify the issue number from the branch name.

### Step 1: Pre-flight Checks
1. Run `make build` — must succeed
2. Run `make test` — must succeed
3. If either fails, fix issues before proceeding

### Step 2: Review Agent
Launch the `code-reviewer` agent to evaluate all changes on this branch vs main.
- If there are 🔴 blockers: fix them and re-review
- If only 🟡 warnings or 🟢: proceed

### Step 3: Push & Create PR
1. Push the branch: `git push -u origin <branch-name>`
2. Create the PR with `gh pr create --base main`:
   - Title: concise, imperative mood, under 70 chars
   - Body MUST include `Closes #N` (where N is the issue number) to auto-close the issue on merge
   - Body includes: Summary bullets, test plan
   - Format:
     ```
     ## Summary
     - bullet points

     ## Test Plan
     - [ ] test items

     Closes #N
     ```

### Step 4: Self-Improvement Check
After creating the PR, check if any patterns from this work should be added to:
- `.claude/skills/<name>/SKILL.md` — new conventions, patterns discovered
- `.claude/agents/code-reviewer.md` — new review checklist items
- `.claude/settings.json` — new hooks or permissions

If updates are needed, include them in the PR or note them for a follow-up.
