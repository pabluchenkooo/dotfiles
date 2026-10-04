---
name: code-constitution
description: The user's mandatory code-readability rules (pattern matching over conditionals, boolean naming, early returns, why-comments, deep modules, no premature abstraction, factory-only test setup). Load before writing or reviewing code, and whenever another skill says "check against the code constitution".
---

# Code Constitution: mandatory rules

These are not suggestions. Every line of code you produce must comply. When a project has its own conventions doc, that doc wins on project specifics (libraries, folders, naming of modules); these rules still govern how the code reads.

You write code for **human brains, not machines**. A reader can hold roughly **4 chunks in working memory at once**. If a reader has to juggle more than four things simultaneously, the code has failed.

Examples are in Elixir where the rule is language-specific; translate the idea to the language at hand.

---

### Rule 1: Conditionals are a last resort, pattern matching first

Prefer pattern matching and multiple function clauses over branching inside one function body.

```elixir
# ✅ pattern matching, multiple clauses
def process(%{status: :active, role: :admin} = user), do: grant_full_access(user)
def process(%{status: :active} = user), do: grant_limited_access(user)
def process(%{status: :suspended} = user), do: deny_access(user)

# ❌ branching for what pattern matching can handle
def process(user) do
  if user.status == :active do
    if user.role == :admin, do: grant_full_access(user), else: grant_limited_access(user)
  else
    deny_access(user)
  end
end
```

When a conditional is truly unavoidable, prefer in this order:
1. `case` (matching on a value's shape or content)
2. `cond` (independent boolean expressions)
3. `if` (a single, simple true/false check)

Never use `unless` (or any inverted-logic construct like it). Never combine `unless` with `else`.

### Rule 2: Boolean naming

| Kind | Convention | Example |
|---|---|---|
| Statically set | `is_` prefix | `is_enabled = true` |
| Computed at runtime | `?` suffix (or `is_`/`has_` in languages without `?`) | `has_e164? = Enum.any?(rules, &(&1.type == "e164"))` |
| Function returning boolean | `?` suffix | `def expired?(token), do: ttl(token) <= 0` |

Never mix these conventions. Never omit them.

### Rule 3: Readable conditionals, extract into named variables

Never stack more than 3 conditions inline. Extract each into a named variable.

```
# ❌
if val > LIMIT && (a || b) && (c && !d) { ... }

# ✅ each variable is one chunk
is_valid = val > LIMIT
is_allowed = a || b
is_secure = c && !d
if is_valid && is_allowed && is_secure { ... }
```

### Rule 4: Early returns over nested ifs

Handle edge cases first and bail out, so the reader only follows the happy path. In Elixir, `with` or pattern-matched clauses serve the same purpose.

```python
# ❌
def process(order):
    if order.is_valid:
        if order.has_stock:
            if order.payment_ok:
                ship(order)

# ✅
def process(order):
    if not order.is_valid:   return error("invalid")
    if not order.has_stock:  return error("no stock")
    if not order.payment_ok: return error("payment failed")
    ship(order)
```

### Rule 5: Comments say WHY, not WHAT

- Banned: comments that restate the next line.
- Allowed WHAT comments: only a bird's-eye overview above a block (`# Phase 2: reconcile inventory`).
- Always write WHY comments for non-obvious motivation, tradeoffs and workarounds.

### Rule 6: Deep modules over shallow ones

Prefer a simple interface hiding real complexity. Don't split logic into many tiny functions or modules the reader has to chase; linear reading is natural, jumping between abstractions is not. A unit that doesn't hide meaningful complexity behind a simpler interface shouldn't exist.

### Rule 7: Composition over deep inheritance

Never make readers trace behavior up and down a hierarchy. Assemble behavior from parts.

### Rule 8: DRY is not sacred

A little duplication beats a wrong abstraction or an unnecessary dependency. Deduplicate only when the shared logic is genuinely the same concept, not code that happens to look alike today.

### Rule 9: Minimal language features

Use the smallest subset of the language that does the job. Clever use of obscure features is a violation, not a virtue.

### Rule 10: Self-descriptive values

No magic numbers, cryptic strings or lookup tables the reader has to memorize. `set_mode(:turbo)`, not `set_mode(3)`.

### Rule 11: No unnecessary abstraction layers

Every layer is a toll on working memory. If a layer doesn't meaningfully simplify the interface for its consumer, remove it. Flat and linear beats deep and layered.

### Rule 12: No nested conditionals

Never nest a conditional inside another (including templates with nested `:if`/`if` blocks). Extract the inner branch into a private function dispatched by pattern matching.

```elixir
# ❌
~H"""
<%= if @mode == :editing do %>
  <%= if @role == :admin do %><.admin_editor /><% else %><.basic_editor /><% end %>
<% else %>
  <.viewer />
<% end %>
"""

# ✅
~H"<.body mode={@mode} role={@role} />"

defp body(%{mode: :editing, role: :admin} = assigns), do: ~H"<.admin_editor />"
defp body(%{mode: :editing} = assigns), do: ~H"<.basic_editor />"
defp body(assigns), do: ~H"<.viewer />"
```

### Rule 13: Unit tests build setup through factories only

A unit test sets up its scenario only through test helpers/factories, never by calling other business-logic functions (including the module under test). Chained setup couples tests: a change in the helper silently breaks or masks unrelated tests, and it becomes unclear what is under test.

```elixir
# ❌ setup through other domain functions
{:ok, order} = Orders.create_order(attrs)
{:ok, _} = Orders.reserve(order)
assert {:ok, _} = Orders.ship(order.id)

# ✅ setup through factories
order = insert(:order, status: :reserved)
assert {:ok, _} = Orders.ship(order.id)
```

---

When two rules seem to conflict, resolve in favor of **reducing the reader's cognitive load**.

## Using this in a review

Check every changed file against the rules. Cite violations by rule number with `file:line`, quote the offending snippet, and show the compliant version. If a file passes, say so explicitly. Don't flag untouched code unless the change made it worse.
