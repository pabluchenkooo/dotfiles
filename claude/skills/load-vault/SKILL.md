---
name: load-vault
description: Load project and ticket context from the user's notes vault (Obsidian/markdown, path in $NOTES_VAULT) into the session before working: conventions, architecture, the ticket's plan and earlier reviews. Use when the user runs /load-vault [branch or ticket], or says to load the vault, notes or ticket context.
---

# Load vault context

Arguments: `[branch or ticket id]`. Defaults to the current git branch.

## Find the vault

Use `$NOTES_VAULT`. If it's unset, ask the user for the path once and suggest they add `export NOTES_VAULT=...` to `~/.zshrc.local`. Read the vault's root `CLAUDE.md` first if it has one: its writing and structure conventions apply to anything you write there.

## Find the project

Match the current repo to a project folder in the vault: try the repo directory name, its parent directory name and the remote's repo name against folder names (commonly under `1-Projects/` or `projects/`). If nothing or several match, list the candidates and ask.

Read, if present: the project overview/README, architecture notes, the code constitution or conventions doc, and any glossary. Skim; don't dump them back to the user.

## Find the ticket

Extract the ticket id from the argument or branch name (patterns like `ABC-123`, case-insensitive; otherwise use the slug). Search the project folder: `grep -rli "<id>" <project folder>` and folder names containing it. Read the ticket file, its `plan.md` / `_index.md`, decisions and logs, and earlier review docs in that folder.

## Report

Reply with a short brief, not a dump:
- project and ticket found (paths),
- what the ticket asks for and what's explicitly out of scope,
- decisions already made, open questions,
- state of the work (from logs / plan checkboxes and `git log <base>..HEAD`).

Then wait for the user's next instruction. Don't write to the vault unless asked; if you do, follow the vault's `CLAUDE.md` and leave changes uncommitted for the user to review.
