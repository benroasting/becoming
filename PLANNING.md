# Becoming — Planning

## Vision

A personal values/accountability app. Unlike generic goal-tracking apps, it's values-first: record the long-term character values you're working toward (better man, husband, friend, future father), then map goals, habits, and check-ins directly back to those values so day-to-day actions stay visibly connected to who you're trying to become.

## Why Go + Swift

- **Go backend, native Swift iOS client.** No React Native/Flutter.
- Flutter (Dart) doesn't advance any target language. React Native (TS) reinforces the language that's already strongest and gets exercised at work anyway.
- Swift is a working-language gap (used regularly at Hope Media, wanted at greater depth); Go concurrency is a personal-growth gap the earlier interpreter project doesn't exercise.
- Considered `golang.org/x/mobile` (gomobile) to embed Go directly as an iOS library instead of running it as a networked service. Rejected: gomobile's FFI boundary only exposes basic types (no channels/goroutines), which would undercut the concurrency practice that's a main point of this project. Go runs as a real networked backend (HTTP/websocket) the Swift app calls. Gomobile stays an option later for offline-first sync.
- Kotlin/Android native client is planned as a deliberate second-pass port later, once the Swift client and domain logic are proven out.

## Reference project

An earlier attempt lives at [github.com/benroasting/becoming](https://github.com/benroasting/becoming) (Flutter + Go, goal/habit tracker, no values concept). This repo is a fresh implementation — same proven backend stack (Chi router, pgx/Postgres, golang-migrate) and layout, but the domain model is new and the Go code is being typed from scratch for the reps, not copied.

## Domain model

- **Value** — long-term identity/character statement. Mostly-fixed but editable set (add/remove/change over time). Removal is a soft **archive** (status flag), not hard delete, so historical goals/habits/check-ins still make sense after a value is no longer being pursued.
- **Habit** — the recurring practical action. Many-to-many with Value (**≥1 required**), many-to-many with Goal (**optional**, 0+). Archived via its existing `is_active` flag rather than hard-deleted — CheckIns point at `habit_id`, so hard-deleting would orphan history.
- **Goal** — a time-bound checkpoint. Many-to-many with Value (**≥1 required**), many-to-many with Habit (**≥1 required** — a goal can't exist with zero habits). Keeps a status enum (active/completed/abandoned/inactive) rather than a separate archive mechanism.
- **CheckIn** (renames the reference repo's `HabitLog`) — belongs to a Habit. Cadence is derived from the habit's own `Frequency` rather than tracked separately; logged as raw timestamps, with "did I hit this period" computed at read time rather than enforced at write time.
- **JournalEntry** — freeform text + timestamp, optionally tagged to one or more Values. Nothing else references it, so it's fine to hard-delete.

Two decisions worth remembering the reasoning for:
1. `POST /goals` requires **existing** `habit_ids` (and `value_ids`) — a goal can't create habits inline. Keeps each resource's endpoint focused on its own entity; you create habits first, then goals that reference them.
2. Value and Habit archive instead of delete; Goal and JournalEntry don't need that treatment (Goal already has a terminal status; nothing references a JournalEntry).

Single-user for v1 — no auth, no `users` table, deliberately deferred (matches the reference repo's original approach).

## API surface (v1)

- **Values** — `GET/POST /values`, `GET/PUT /values/{id}`, `PATCH /values/{id}/archive` (+ unarchive). No DELETE.
- **Habits** — `GET/POST /habits` (`value_ids[]` ≥1, `goal_ids[]` optional), `GET/PUT /habits/{id}`, `PATCH /habits/{id}/archive`.
- **Goals** — `GET/POST /goals` (`value_ids[]` ≥1, `habit_ids[]` ≥1, both existing), `GET/PUT /goals/{id}`.
- **CheckIns** — `POST/GET /habits/{id}/check-ins`.
- **Journal** — full CRUD on `/journal-entries` (`value_ids[]` optional tag).
- Deferred (not MVP): `GET /values/{id}/progress` rollup/dashboard endpoint.

## Working agreement

Ben writes and runs all the code. Claude acts as a design/thinking partner beforehand (questions, tradeoffs, architecture discussion) and reviewer afterward — not an implementer. For this project's API-surface design phase, Claude also actively co-proposes resource/endpoint shapes rather than pure Socratic questioning, but implementation stays Ben's.
