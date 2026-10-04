---
name: address-pr-review
description: Go over a reviewer's comments on one of the user's PRs as a senior staff engineer, write a response doc, then implement the agreed items one commit each and fill each reply with its SHA. Use when the user asks to go over, address, answer or respond to a review on a PR (e.g. "lets go over the review on #41").
---

# Address a PR review

You are a senior staff engineer on this codebase and you own this PR. Treat every comment as a claim to verify against the code, not an order. Agree when the reviewer is right, push back with a concrete scenario when they are not, and say when a suggestion is right in spirit but would break something as written.

Two phases. Never start phase 2 before the user has reviewed the doc.

## Phase 1: the response doc

1. **Load context.** Read the project's conventions (CLAUDE.md, CONTRIBUTING, any architecture or style doc it points to). If the PR has a ticket or plan (in the PR body, the branch name, or a notes folder the user keeps), read it: decisions and "out of scope" there settle many comments.
2. **Fetch the review.**
   ```
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   gh pr view <N> --json reviews,headRefOid,headRefName,url
   gh api repos/$REPO/pulls/<N>/comments --paginate
   gh api repos/$REPO/issues/<N>/comments
   ```
   Group replies (`in_reply_to_id`) with their root. Note each comment's `id` (for the link `<pr url>#discussion_r<id>`), `commit_id` and `original_line`. Only address comments from the reviewer, unresolved, newer than the last response doc.
3. **Verify every comment in the code.** Read the function, its callers, its tests. For each, work out:
   - what the code does today, with `file:line` from the reviewed commit;
   - whether the reviewer is right, and the concrete scenario if not (interleavings for locks and transactions, job states for uniqueness, connection and transaction boundaries, external calls inside transactions);
   - what their suggestion would break as written;
   - whether it is inside the PR's scope. Scope is literal: a real problem outside it becomes a follow-up ticket, not code in this PR.
4. **Write the doc** next to the ticket's plan if there is one, otherwise in `.reviews/` at the repo root: `pr-<N>-review.md`, or `pr-<N>-review-<round>.md` for later rounds (link the earlier rounds). Format below. Plain and direct, in the user's voice. No em or en dashes.
5. **Stop.** Give the user the path, the positions in a few lines, and anything they have to decide. Do not touch code, do not reply on GitHub.

## Phase 2: implement (only after the user says go)

1. Apply the user's edits to the doc first; it is the spec.
2. One item at a time, in table order. For each: change the code and its tests, run the affected tests (scoped, not the whole suite, and without wiping build caches), then commit:
   - subject only, starting with the ticket id when there is one: `ABC-123 Lock the upload row before generating the PDF`
   - no Co-Authored-By trailer
   - items that say "keep" or "follow-up" get no commit
3. After each commit, write its short SHA (9 chars) into the doc's Replies table: in the `Commit` column and at the end of the reply text. Items with no commit keep `-` and a reply that explains why.
4. Run the project's formatter check and the touched tests once at the end. Set `status: done` in the frontmatter; `reviewed_at` stays the reviewed commit.
5. Never push. Never post a reply or any comment on GitHub on your own: the user always reviews the replies first, and only posts them, or tells you to post them, when they say so explicitly.

## Doc format

```markdown
---
type: review/response
ticket: <TICKET or ->
pr: <pr url>
branch: <branch>
reviewer: <github login>
reviewed_at: <short sha the comments are on>
status: draft
created: <YYYY-MM-DD>
---

# PR #<N> review: <what the PR does>

<One or two lines: who reviewed, verdict, how many comments. Line numbers are from `<sha>`.>

## Summary

| # | Where | Topic | Proposal |
|---|---|---|---|
| 1 | `path/file:27` | <the claim, short> | Do. / Do, but ... / Keep, because ... / Follow-up ticket. |

## 1. <Topic>

[Comment](<pr url>#discussion_r<id>)

**Reviewer says:** <the comment in plain words>

**What happens today:** <the code, with file:line>

**Is the reviewer right:** <yes / partly / no, with the concrete scenario>

**Proposal:** <the change, with code when it is not obvious>

**Tests:** <what changes or gets added>

## Replies

| # | Comment | Commit | Reply |
|---|---|---|---|
| 1 | <short> | - | <reply as the user would post it> |
```

Refer to the reviewer with the pronouns the user uses for them; otherwise they/them.

## Replies in the user's voice

Replies get pasted into GitHub as they are, so they must sound like the user: human, clear, short. The reasoning lives in the item sections above, never in the reply.

- One or two short sentences. Often just "Done 👍" or "Removed." is enough.
- Open casually when it fits: "Good catch 🙈", "Yep", "Fair", "Nicer, done.", "Taken, thanks!", "Agreed, ...".
- Say what changed, not how or why at length. Name the function or flag in backticks.
- Pushback is one reason, the concrete case, no lecture: "Kept this one 🙈 On the last failed attempt the job is still `executing`, so a quick second submit conflicts."
- One emoji at most, and not on every reply. 🙈 🙉 🤠 🤓 🍀 😅 👍 😄
- Contractions and plain words ("it's", "doc", "you're right"). No "I would argue", no "Note that", no recap of the comment.
- The commit SHA goes at the end, bare: `... shows the old error. 76449a1d6`

Examples:

| Comment | Reply |
|---|---|
| The input skips validation | Good catch 🙈 The handler now checks the type first and shows the old error. 76449a1d6 |
| Pass the URL instead of deriving `pending?` | Nicer, done. Kept the key only for the retry button. d684f9689 |
| Is this class needed? | Removed. 658280516 |
| Keep the close and reopen test | Kept it and it caught a bug 😅 Closing left the pending item in memory and it got sent with the next one. 7de1160fc |
| Comment wording | Taken, thanks! c225dc4fb |
