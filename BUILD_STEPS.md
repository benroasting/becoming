# Becoming — Build Steps

Ordered phases. Each one should be working end-to-end before moving to the next. See `PLANNING.md` for the domain model and API surface these implement.

## 1. Scaffold — in progress

- [x] `go mod init github.com/benroasting/becoming`
- [ ] `cmd/server/main.go` — config load, DB pool, router, graceful shutdown
- [ ] `internal/config/config.go` — `PORT`, `ENVIRONMENT`, `LOG_LEVEL`, `DATABASE_URL`
- [ ] `internal/database/database.go` — `pgxpool.Pool` from `DATABASE_URL`
- [ ] `internal/handlers/health.go` + `router.go` — Chi router, `/health` only
- [ ] `docker-compose.yml` — Postgres service for local dev
- [ ] `migrations/` folder ready, migrate tooling decided (CLI vs programmatic)
- [ ] **Done when:** `docker-compose up -d && go run ./cmd/server` then `curl localhost:8080/health` returns 200

## 2. Value — end to end

- [ ] Migration: `values` table (id, name, description, status, created_at, updated_at)
- [ ] Model, repository (CRUD + archive/unarchive)
- [ ] Handlers + router wiring
- [ ] **Done when:** can create, list, update, and archive a Value via curl

## 3. Habit + join tables

- [ ] Migration: `habits` table (reuse `is_active` as archive flag) + `habit_values` and `habit_goals` join tables
- [ ] Model, repository (CRUD + archive + association writes, ≥1 value enforced)
- [ ] Handlers + router wiring
- [ ] **Done when:** can create a habit tagged to multiple values, and archiving hides it without deleting its future check-in history

## 4. Goal + join table

- [ ] Migration: `goals` table (status enum) + `goal_values` join table (reuses `habit_goals` from step 3)
- [ ] Model, repository (CRUD; requires ≥1 existing `habit_id` and `value_id` at creation)
- [ ] Handlers + router wiring
- [ ] **Done when:** creating a goal with no habits is rejected; creating one with existing habits works

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
