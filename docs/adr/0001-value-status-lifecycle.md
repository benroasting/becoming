# ADR 0001: Value status lifecycle

## Status
Accepted

## Context

`core_values` needs some notion of lifecycle: a Value can be actively part of someone's life, or it can stop being pursued. The first draft copied the `Goal` status enum from the reference project (`active`, `completed`, `abandoned`, `inactive`) without examining whether those four states actually mean something distinct for a Value the way they do for a time-bound Goal.

Working through it surfaced two separate concerns that had gotten collapsed into one field:

1. **Is this value still something I hold, or did I let it go?** — a real decision the person makes, worth recording.
2. **Am I currently doing anything about it right now?** — a fact derivable at any moment from whether any non-archived Habit or Goal currently links to the value.

`inactive` and `completed` were both attempts to represent (2) as a stored state, which caused two problems: they would go stale the instant a habit was added or archived (nothing would proactively rewrite the Value row when its associations changed elsewhere), and `completed` implied a reactivate path back to `active`, which reintroduced complexity for a state that mostly meant "no active habits right now."

## Decision

- `core_values.status` has exactly two values: `active` and `abandoned`.
- `abandoned` is terminal by design — there is no `reactivate` action. If abandoning a value ends up being wrong in practice, the answer is to create a new Value, not to resurrect the old one.
- "Pursuing" vs. "not pursuing" is **never stored**. It's computed at read time by checking whether any non-archived Habit or Goal currently references the value (via `habit_values` / `goal_values`). The API can surface this as a computed field on the Value response, but it is not a column.
- The only status-changing action endpoint is `POST /values/{id}/abandon`. No `/complete`, no `/reactivate`.

## Consequences

- Simpler schema and API surface than the 4-state (or 3-state) alternatives that were considered and rejected.
- No risk of the "currently pursuing" signal going stale, since it's never written — it's derived fresh from live associations every time it's read.
- The "did I feel done, or did I give up" distinction that motivated `completed`/`abandoned` as two separate archived-reasons is lost. That was a deliberate tradeoff: the distinction was real but not worth the complexity of an asymmetric reactivation rule (completed could come back, abandoned couldn't). If that signal turns out to matter later, the cheaper fix is a nullable `closed_reason` text/enum column alongside `abandoned`, added in a new migration — not resurrecting the 4-state enum.

## Alternatives considered

- **4-state enum copied from Goal** (`active`/`completed`/`abandoned`/`inactive`) — rejected: two of the four states didn't have a clear, distinct meaning for a Value.
- **3-state enum** (`active`/`completed`/`abandoned`) — rejected: required a `reactivate` action for `completed` but not `abandoned`, an asymmetry that added API surface for a distinction that a computed "pursuing" field already captures more simply.
