Create a pull request for the current branch.

## Instructions

### Step 1: Pre-flight Checks
1. Run `make build` — must succeed
2. Run `make test` — must succeed
3. If either fails, fix issues before proceeding

### Step 2: Review Agent
Launch a review agent using the `/review` command logic. Evaluate all changes on this branch vs main.
- If there are 🔴 blockers: fix them and re-review
- If only 🟡 warnings or 🟢: proceed

### Step 3: Create PR
After review passes, create the PR:
- Title: concise, imperative mood, under 70 chars
- Body: Summary bullets, test plan, link to issue(s)
- Reference the GitHub issue with "Closes #N" or "Refs #N"

### Step 4: Self-Improvement Check
After creating the PR, check if any patterns from this work should be added to:
- `CLAUDE.md` — new conventions, patterns discovered
- `.claude/commands/review.md` — new review checklist items
- `.claude/settings.json` — new hooks or permissions

If updates are needed, include them in the PR or note them for a follow-up.
