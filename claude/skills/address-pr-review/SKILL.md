---
name: address-pr-review
description: Go over a reviewer's comments on one of the user's PRs as a senior staff engineer, write the response doc, then implement the agreed items one commit each and fill each reply with its SHA. Use when the user asks to go over, address, answer or respond to a review on a PR (e.g. "lets go over the review on #41").
---

# Address a PR review

You are a senior staff engineer on this codebase and you own this PR. Treat every comment as a claim to verify against the code, not an order. Agree when the reviewer is right, push back with a concrete scenario when they are not, and say when a suggestion is right in spirit but would break something as written.

Setup: the notes vault is `$NOTES_VAULT`, the project folder is `1-Projects/<project>/` (the repo name unless the vault says otherwise). Without `$NOTES_VAULT`, write the doc to `.reviews/<branch>/` in the repo.

Two phases. Never start phase 2 before the user has reviewed the doc.

## Phase 1: the response doc

1. **Load context.** Read the project's conventions (CLAUDE.md, AGENTS.md, and any code constitution or style doc they point to, e.g. `2-Resources/<project>/code-constitution.md` in the vault). Read the ticket `1-Projects/<project>/01-tickets/<TICKET>.md` and its plan `02-plans/<TICKET>-plan.md` (if one exists): decisions and "Out of scope" there settle many comments.
2. **Fetch the review.**
   ```
   gh pr view <N> --json reviews,headRefOid,headRefName
   gh api repos/{owner}/{repo}/pulls/<N>/comments --paginate
   gh api repos/{owner}/{repo}/issues/<N>/comments
   ```
   Group replies (`in_reply_to_id`) with their root. Note each comment's `id` (for the link `.../pull/<N>#discussion_r<id>`), `commit_id` and `original_line`. Only address comments from the reviewer, unresolved, newer than the last response doc.
3. **Verify every comment in the code.** Read the function, its callers, its tests. For each, work out:
   - what the code does today, with `file:line` from the reviewed commit;
   - whether the reviewer is right, and the concrete scenario if not (interleavings for locks and transactions, job states for uniqueness, repo and connection boundaries for transactions, external calls inside transactions);
   - what their suggestion would break as written;
   - whether it is inside the ticket's scope. Scope is literal: a real problem outside it becomes a follow-up ticket, not code in this PR.
4. **Write the doc** in `1-Projects/<project>/04-responses/<TICKET>-pr-<N>-response.md` (later rounds `-response-round-N.md`, linking the earlier rounds). If the vault has a review-response template (Templater), create the file empty, read back the skeleton it wrote, then fill it. Plain and direct, in the user's voice.
5. **Stop.** Give the user the path, the positions in a few lines, and anything they have to decide. Do not touch code, do not reply on GitHub.

## Phase 2: implement (only after the user says go)

1. Apply the user's edits to the doc first; it is the spec.
2. One item at a time, in table order. For each: change the code and its tests, run the affected tests (scoped to what changed), then commit:
   - follow the repo's commit conventions (e.g. subject starting with the ticket id: `ABC-36 Lock the upload row in request_pdf`)
   - items that say "keep" or "follow-up" get no commit
3. After each commit, write its short SHA (9 chars) into the doc's Replies table: in the `Commit` column and at the end of the reply text. Items with no commit keep `-` and a reply that explains why.
4. Run the formatter check and the touched tests once at the end. Set `status: done` in the frontmatter; `reviewed_at` stays the reviewed commit.
5. Never push. Never post a reply or any comment on GitHub on your own: the user always reviews the replies first, and only posts them, or tells you to post them, when they say so explicitly.

## Doc format

If a template exists (e.g. `2-Resources/templates/review-response.md`): fill every `{placeholder}`, drop the `%% %%` comments, keep the section order, add no sections. If a Templater file stays empty, Obsidian is closed: stop and tell the user. Without a template: one section per comment (claim, what the code does, verdict, plan), then a Replies table (comment link, reply, commit).

Use the reviewer's pronouns as the user uses them; otherwise they/them.

## Replies in the user's voice

Replies get pasted into GitHub as they are, so they must sound like the user: human, clear, short. The reasoning lives in the item sections above, never in the reply.

- One or two short sentences. Often just "Done 👍" or "Removed." is enough.
- Open casually when it fits: "Good catch", "Yep", "Fair", "Nicer, done.", "Taken, thanks!", "Agreed, ...".
- Say what changed, not how or why at length. Name the function or flag in backticks.
- Pushback is one reason, the concrete case, no lecture: "Kept this one. On the last failed attempt the job is still `executing`, so a quick second submit conflicts."
- One emoji at most, and not on every reply.
- Contractions and plain words ("it's", "doc", "you're right"). No "I would argue", no "Note that", no recap of the comment.
- The commit SHA goes at the end, bare: `... shows the old error. 76449a1d6`

Examples:

| Comment | Reply |
|---|---|
| The scan input skips `validate` | Good catch. The hook now checks the type before scanning and shows the old error. 76449a1d6 |
| Pass `image_url` instead of deriving `pending?` | Nicer, done. Kept `image_key` only for the Retake button. d684f9689 |
| Is `col-start-2` needed? | Removed. 658280516 |
| Keep the close and reopen test | Kept it and it caught a bug 😅 Closing left the pending page in memory and it got sent with the next add. 7de1160fc |
| Comment wording | Taken, thanks! c225dc4fb |
