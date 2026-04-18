Review and improve the AI development rules and guidelines.

## Instructions

You are a **rules improvement agent**. Your job is to audit and improve the AI development configuration for the Run-Jin project.

### Step 1: Audit Current Rules
Read and analyze:
- `AGENTS.md` — project guidelines (CLAUDE.md is a thin pointer to AGENTS.md)
- `.claude/skills/*/SKILL.md` — convention skills (Swift, Supabase, Git, secrets, AI workflow)
- `.claude/settings.json` — hooks and permissions
- `.claude/commands/review.md` — review checklist
- `.claude/commands/pr.md` — PR workflow
- `.claude/agents/code-reviewer.md` — review agent definition

### Step 2: Check Against Reality
- Read recent git log (`git log --oneline -20`) to see what's been done
- Check if any patterns in the code don't match the documented conventions
- Look for repeated issues or patterns that should be codified
- Verify that the project structure in AGENTS.md matches the actual file structure

### Step 3: Propose Improvements
For each finding:
1. **What**: The specific rule/guideline to add, update, or remove
2. **Why**: What problem it solves or what pattern it codifies
3. **Where**: Which file to update (AGENTS.md, `.claude/skills/<name>/SKILL.md`, settings.json, review.md, etc.)

Categories to check:
- Missing conventions that are followed in practice but not documented
- Outdated rules that no longer apply
- Review checklist gaps (things that were caught manually but should be automated)
- Hook improvements (new pre-commit checks, permission updates)
- New slash commands that would improve workflow

### Step 4: Apply Changes
After presenting findings, apply the approved changes to the relevant files.
Include a clear commit message explaining the rule improvements.
