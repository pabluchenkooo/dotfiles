---
name: review-branch
description: Self-review the user's own branch before opening a PR, against the code constitution, the project's architecture and conventions, and memory/correctness risks, with an optional focus. Use when the user runs /review-branch [branch] [base] [focus], or asks to review their own branch or changes before a PR.
---

# Review my branch

Arguments: `[branch] [base] [focus]`. Branch defaults to the current one, base to the repo's default branch. Free text after them is the focus (e.g. "memory handling", "does it follow the architecture"): weigh it first, but still do the full pass.

This is the user's own code, so be blunt: the goal is that a reviewer finds nothing.

## Steps

1. **Context.** Read the project's conventions and architecture docs, the code-constitution skill, and the ticket notes if any (load-vault skill when `$NOTES_VAULT` is set).
2. **Diff.** `git diff <base>...<branch>` plus uncommitted changes (`git status`, `git diff`). Read changed functions in full, and their callers.
3. **Check:**
   - the ticket is fully solved, and nothing outside its scope slipped in;
   - correctness: edge cases, error paths, races, transactions, migrations on existing data;
   - memory and performance (for Elixir, the elixir-antipatterns catalogue);
   - code constitution, rule by rule, per file;
   - fits the architecture: right layer, no business logic in UI components, no new abstraction layers without a reason;
   - generated-looking code: dead code, redundant comments, over-defensive checks, needless helpers, leftover debug output;
   - tests cover the change, set up through factories, and pass: run the affected tests (scoped) and the formatter/linter check.
4. **Report** in chat, ranked: Critical, Major, Minor, each with `file:line` and the fix. End with a short "ready / not ready" verdict.

Don't change code unless the user asks. When they say "fix them", do one finding per commit, subject only, no Co-Authored-By trailer, and never push.
