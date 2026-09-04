---
name: git
description: Use when committing, staging, amending, writing commit messages, or anything involving git history, push, or pull requests.
---

# Git Workflow

- Commit only when asked.
- Consider ALL changes (`git status`) and review diffs before committing.
- Group commits by work done: one commit per unit of completed work; stage
  precisely (`git add <paths>` / `-p`), never blind `git add -A`.
- Message: `type(domain): description`. `type` = `feat`/`fix`/`refactor`/
  `chore`/`docs`/`test`/`perf`/`revert`; `(domain)` = affected area;
  description imperative, lowercase, ≤72 chars, no trailing period. Body only
  when it adds real value.
- No authorship or tool trailers (no `Co-authored-by`, no "Generated with ...").
- Never push, open a PR/MR, merge, or force-push unless explicitly asked.
