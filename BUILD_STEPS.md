# Becoming — Build Steps

Ordered phases. Each one should be working end-to-end before moving to the next. See `PLANNING.md` for the domain model and API surface these implement.

## 1. Scaffold — done

- [x] `go mod init github.com/benroasting/becoming`
- [x] `cmd/server/main.go` — config load, DB pool, router, graceful shutdown
- [x] `internal/config/config.go` — `PORT`, `ENVIRONMENT`, `LOG_LEVEL`, `DATABASE_URL`
- [x] `internal/database/database.go` — `pgxpool.Pool` from `DATABASE_URL`
- [x] `internal/handlers/health.go` + `router.go` — Chi router, `/health` only
- [x] `docker-compose.yml` — Postgres service for local dev (host port 5433, not 5432 — already claimed by another project on this machine)
- [ ] `migrations/` folder ready, migrate tooling decided (CLI vs programmatic) — carried into step 2, first real migration needed there anyway
- [x] **Done when:** `docker compose up -d && go run ./cmd/server` then `curl localhost:8081/health` returns 200 (port 8081, not 8080 — also already claimed locally)

## 2. Value — done

- [x] Migration: `core_values` table (id, title, description, status, created_at, updated_at) — status is `active`/`abandoned` only, see [ADR 0001](docs/adr/0001-value-status-lifecycle.md)
- [x] Model, repository (CRUD + `abandon`, no reactivate; "pursuing" computed from habit/goal links, not stored — the computed-field wiring itself is deferred to when Habit/Goal exist to compute it from)
- [x] Handlers + router wiring (`POST /values/{id}/abandon`, not a generic archive/unarchive pair)
- [x] **Done when:** can create, list, update, and abandon a Value via curl — confirmed 2026-07-22, including abandon-twice correctly returning 404

## 3. Habit + Value join table

- [x] Migration: `habits` table (reuse `is_active` as archive flag) + `habit_values` join table only — `habit_goals` moves to step 4 (see below)
- [x] `habit_values`: composite `PRIMARY KEY (habit_id, value_id)`, no surrogate id column; `ON DELETE CASCADE` on both FKs (hygiene only — never fires in normal use, since Habit/Value both archive rather than hard-delete); plus a secondary index on `value_id` alone (the PK's leading column covers "values for this habit," but "habits for this value" needs its own index)
- [x] Model, repository (CRUD + archive + association writes, ≥1 value enforced)
- [x] Handlers + router wiring
- [x] **Done when:** can create a habit tagged to multiple values, and archiving hides it without deleting its future check-in history — confirmed 2026-07-28 via curl, including ≥1-value enforcement on create/update (400) and archive-twice correctly returning 404

## 4. Goal + Value/Habit join tables

- [x] Migration: `goals` table (status enum) + `goal_values` **and `habit_goals`** join tables — `habit_goals` had to wait until now since it references `goals(id)`, which didn't exist in step 3
- [x] Same join-table shape as step 3: composite PKs, `ON DELETE CASCADE`, secondary index on `goal_id` in `habit_goals` (this is the more important direction here — "habits under this goal" is a core query)
- [x] Model, repository (CRUD; requires ≥1 existing `habit_id` and `value_id` at creation)
- [x] Handlers + router wiring
- [x] **Done when:** creating a goal with no habits is rejected; creating one with existing habits works — confirmed 2026-07-29 via curl, including ≥1-value/≥1-habit enforcement (400), nonexistent-habit FK mapping (400), and status transitions via `PUT` with associations surviving the round-trip

## 5. CheckIn

- [ ] Migration: `check_ins` table (habit_id, completed_at, notes)
- [ ] Model, repository
- [ ] Handlers: `POST/GET /habits/{id}/check-ins`
- [ ] **Done when:** logging a check-in against a weekly habit and a daily habit both work, and history is queryable per habit

## 6. Journal

- [ ] Migration: `journal_entries` table + `journal_values` join table
- [ ] Model, repository (full CRUD, hard delete OK)
- [ ] Handlers + router wiring
- [ ] **Done when:** can create, tag to a value, edit, and delete a journal entry

## Deferred (post-v1)

- `GET /values/{id}/progress` rollup/dashboard endpoint
- Auth / multi-user
- Swift client (starts once the API is stable enough to build against)
