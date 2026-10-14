---
name: archive-done
description: Move vault notes of finished tickets to the archive. Reads the ticket ids from the file names in the project's ticket folders, asks the issue tracker for their status, and moves every file of a Done or Canceled ticket to the archive with the same subfolder. Use when the user asks to archive done tickets or clean up the vault.
---

# Archive done tickets

Setup: the vault is `$NOTES_VAULT` (PARA layout: `1-Projects/`, `3-Archive/`). The project folder is `1-Projects/<project>/`; ask which project if more than one has ticket folders. Folders to scan: `1-Projects/<project>/{01-tickets,02-plans,03-reviews,04-responses,05-tasks}/`, and the same five under every `1-Projects/<project>/cycles/cycle-N/`. Adjust these names to the vault's layout.

1. **Collect ids.** Every file name starts with a ticket id: `^[A-Z][A-Z0-9]*-\d+` (`ABC-106.md`, `ABC-2436-pr-131-review.md`). Group the files by id. Files that do not start with an id are left alone and listed in the report.
2. **Ask the tracker.** For each id, fetch the issue (Linear: `mcp__linear__get_issue`). Read its status type. Done or Canceled (Linear status type `completed` or `canceled`) means archive. Anything else stays. An id the tracker does not know stays and is listed.
3. **Show before moving.** Print a table: id, status, files to move. Wait for the user's ok.
4. **Move.** Plain `mv`, keeping the path below `1-Projects/`: `1-Projects/<project>/01-tickets/ABC-106.md` goes to `3-Archive/<project>/01-tickets/ABC-106.md`, `1-Projects/<project>/cycles/cycle-8/02-plans/ABC-3-plan.md` to `3-Archive/<project>/cycles/cycle-8/02-plans/ABC-3-plan.md`. `mkdir -p` the target folder first. Never overwrite: if the target exists, stop and report.
5. **Links.** Links are by file name (`[[ABC-106-plan]]`), so moves do not break them. If a moved file is linked by full path anywhere (`grep -rl "1-Projects/<project>/.*<ID>"`), rewrite that path to `3-Archive/...`.
6. **Report.** What moved, what stayed and why. No git commit.

Obsidian may be open: Templater sees moved files as new and resolves any `<% %>` in them, but filled notes have none.
