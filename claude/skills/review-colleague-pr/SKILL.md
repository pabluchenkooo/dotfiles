---
name: review-colleague-pr
description: Review a colleague's branch as a senior architect against the code constitution, hunt for memory and correctness problems, write structured findings and draft a PR comment. Use when the user runs /review-colleague-pr <branch> [base] [context], or asks to review someone else's PR or branch.
---

# Review a colleague's PR

Arguments: `<branch> [base] [free-text context]`. Base defaults to the repo's default branch. The context often says what the ticket is, what the colleague tends to get wrong, or their experience level: use it to decide where to look hardest and how to word the comment. A pasted ticket is the source of truth for scope.

You are a senior architect. Be critical, but every claim must point at code.

## 1. Context

- Load the ticket's notes if there are any (follow the load-vault skill when `$NOTES_VAULT` is set). Read earlier reviews of the same colleague or ticket if they exist: repeat patterns matter.
- Read the project's conventions (CLAUDE.md, CONTRIBUTING, architecture docs) and the code-constitution skill.
- `git fetch`, then `git log --oneline <base>..<branch>` and `git diff <base>...<branch> --stat`. If the branch isn't pushed yet (the user's own, uncommitted), review the working tree instead.

## 2. Review

Read every changed file in full where it matters, plus callers and tests. Check, in this order:

1. **Does it solve the ticket?** Reproduce the bug path or feature flow in your head against the code. A big diff that doesn't fix the reported problem is the most important finding.
2. **Correctness**: edge cases, error paths, races, transactions, idempotency of jobs, migrations that lock or break on existing data.
3. **Memory and performance**: unbounded loads, big binaries in memory or process state, atoms from input, N+1, external calls inside transactions. For Elixir, apply the elixir-antipatterns catalogue.
4. **Code constitution**: every changed file, violations by rule number. State explicitly when a file passes.
5. **Scope**: unrelated changes that belong in their own PR.
6. **Tests**: do they test the behavior that changed, and through factories only (Rule 13)?

If the change is mostly docs or content, don't apply the constitution strictly; judge clarity, accuracy and consistency instead.

## 3. Output

Directory: the ticket folder in `$NOTES_VAULT` (under a `reviews/` or `colleagues/` subfolder if the vault has one), otherwise `.reviews/<branch>/` at the repo root (add `.reviews/` to `.git/info/exclude`).

### `review.md` (always)

```markdown
# Review: <branch>

## Problem
<What the ticket is about. What broke and why.>

## Approach
<What the PR does: files and modules changed, key decisions, dependencies added.>

## Does it solve the ticket?
<yes / partly / no, with the reasoning>

## Code constitution
<Per file: passes, or violations by rule number with file:line.>

## Issues
### Critical
### Major
### Minor
<Each: file:line, snippet, why it hurts, suggested fix.>

## Where to start
<For the user: the 2-3 files to read first and in what order.>
```

### `recommended-alternative.md` (only for an architectural concern)

TL;DR · why not the current approach (concrete risks, with evidence) · what stays the same · what changes · maintenance cost · decision matrix (risk, complexity, maintenance) · implementation steps.

### `pr-comment.md` (always)

The text to post on the PR:
- Lead with what's genuinely good.
- One bold label per concern, specific risk, concrete suggestion, phrased as a question or proposal, not a demand.
- Group nits at the end.
- Adjust to the colleague: more explanation and links to docs for someone new to the language or framework; brief for a senior.
- Offer to pair. Keep it short: the detailed analysis lives in `review.md`.

## 4. Stop

Give the user the paths, the verdict in two lines and the top issues. Never post on GitHub or push unless the user explicitly says so.
