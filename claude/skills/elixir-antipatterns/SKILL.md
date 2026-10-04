---
name: elixir-antipatterns
description: Scan an Elixir/Phoenix branch diff for anti-patterns, with extra weight on memory and process problems (binary leaks, unbounded loads, atom creation, external calls inside transactions, bloated process state). Use when the user runs /elixir-antipatterns <branch> [base], or asks to check Elixir code for anti-patterns, memory issues or OOM risks.
---

# Elixir anti-patterns review

Arguments: `<branch> [base]`. Base defaults to the repo's default branch (`git symbolic-ref refs/remotes/origin/HEAD`). With no arguments, use the current branch.

## Steps

1. `git fetch` quietly, then get the diff: `git diff <base>...<branch> --stat` and the full diff for `*.ex`, `*.exs`, `*.heex`. Read whole changed functions, not just hunks, plus their callers when data size or process boundaries matter.
2. Check every changed function against the catalogue below. Only report what you can point to in the code; each finding needs `file:line`, the snippet, **why it hurts here** (with rough data sizes or call frequency when you can estimate them), and the fix.
3. Rank findings: **Critical** (OOM, crash, data loss, security), **Major** (leaks under load, wrong process design, silent failures), **Minor** (idiom, readability).
4. Write the result where the user keeps reviews (see "Output") and summarize the top items in chat.

## Catalogue

### Memory and the BEAM (look hardest here)

- **Unbounded loads**: `Repo.all` without `limit` on tables that grow; preloading has-many associations of unbounded size; `Enum` over a whole result set that should be `Repo.stream` (inside a transaction) or paginated.
- **Large binaries kept alive**: holding a whole file/upload/HTTP body in memory (`File.read!`, `Req` bodies) when it could be streamed; base64-encoding big files; keeping large binaries in assigns, GenServer state or ETS. Sub-binaries (`binary_part`, pattern-matched slices) of a large binary keep the whole parent alive: `:binary.copy/1` the small piece when storing it long-term.
- **LiveView assigns bloat**: large lists or blobs in socket assigns instead of `stream/3`; re-sending big assigns on every update; temporary assigns not used where they should be.
- **Process state bloat and mailboxes**: GenServer state that only grows (caches with no eviction); a single GenServer as a bottleneck for work that could be concurrent; unbounded mailboxes from `send`/`cast` floods without back-pressure; `Task.async` without `await`/timeout, or unsupervised tasks.
- **Atom creation from input**: `String.to_atom/1`, `Jason.decode(keys: :atoms)`, "atomize keys" helpers on external data. Atoms are never garbage-collected; use `String.to_existing_atom/1` or keep string keys.
- **Copying across processes**: sending large terms between processes or into `Task`s (they get copied); prefer passing ids or using ETS / persistent references.
- **Accidental quadratic work**: `++` in loops, `length/1` in guards on long lists, repeated `Enum.at/2`, `Map.merge` in reduce over big maps, `Enum` pipelines that walk a large list several times where one `reduce` or a `Stream` would do.
- **Long transactions with external calls**: HTTP, KMS/crypto services, S3 or email inside `Repo.transaction`/`Ecto.Multi`: holds a DB connection and locks while waiting on the network. Do the external call before or after, or use an outbox/job.

### Code anti-patterns

- Comments restating the code; long parameter lists; boolean flag parameters that switch behavior.
- Complex `else` clauses in `with` that match errors from unrelated steps; normalize errors in private functions.
- Dynamic map access (`map[:key]`) for keys that are required; use `map.key` or pattern matching so a missing key fails loudly.
- Non-assertive pattern matching and truthiness (`if value`) where the shape is known.
- Namespace trespassing; structs with 32+ fields.

### Design anti-patterns

- Alternative return types switched by options; boolean obsession (several booleans that are really one state atom).
- Exceptions for control flow; `{:ok, _}`/`{:error, _}` ignored with `_ =`.
- Primitive obsession (passing raw maps/strings where a struct or atom describes the domain).
- Unrelated multi-clause functions grouped under one name.
- Library code reading application config at runtime instead of taking options.

### Process anti-patterns

- Code organized by processes: a GenServer used only to group functions with no state, concurrency or isolation need.
- Scattered process interfaces: `GenServer.call(pid, ...)` sprinkled across modules instead of one client API.
- Sending unnecessary data to processes (whole structs where an id would do).
- Unsupervised processes (`spawn`, `Task.start` outside a supervisor) for work that must not be lost.

### Ecto and Phoenix

- N+1 queries in loops or in components; preload or join instead.
- Missing DB constraints or indexes behind validations that assume uniqueness; race-prone check-then-insert instead of `on_conflict` / unique constraint.
- Business logic, Repo calls or HTTP in components or templates; components should receive assigns and render.
- User-facing strings not going through gettext (when the project uses gettext).
- Oban jobs that aren't idempotent, lack `unique` options where duplicates hurt, or carry big payloads in args instead of ids.

### Macros

- Macros where a function would do; large `quote` blocks; `use` that injects lots of code silently (prefer `import`/`alias` plus plain functions).

## Output

Write `antipatterns.md` with: a one-paragraph verdict, a findings table (`# | Severity | Where | Pattern | Fix`), then one section per finding. If `$NOTES_VAULT` is set, put it in the ticket's folder there (see the load-vault skill); otherwise in `.reviews/<branch>/` at the repo root, and make sure `.reviews/` is listed in `.git/info/exclude`.
