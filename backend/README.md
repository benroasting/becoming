# becoming

## Migrations

Schema is managed with [golang-migrate](https://github.com/golang-migrate/migrate) — SQL-first: migration files are the source of truth, the Go models mirror whatever they create (see `docs/adr/`).

Install the CLI once:
```
brew install golang-migrate
```

Set `DATABASE_URL` once per shell session so you don't retype it every command:
```
export DATABASE_URL="postgres://becoming:becoming@localhost:5434/becoming?sslmode=disable"
```
(Port `5434`, not the Postgres default `5432` — this machine already has another project's Postgres bound to `5432`. Matches `docker-compose.yml` and the fallback in `internal/config/config.go`.)

**Create a new migration** (generates a numbered `.up.sql`/`.down.sql` pair in `migrations/`):
```
migrate create -ext sql -dir migrations -seq <name>
```

**Apply all pending migrations:**
```
migrate -path migrations -database "$DATABASE_URL" up
```

**Roll back the most recent migration:**
```
migrate -path migrations -database "$DATABASE_URL" down 1
```

**Roll back everything:**
```
migrate -path migrations -database "$DATABASE_URL" down
```

**Check applied schema for a table:**
```
docker compose exec db psql -U becoming -d becoming -c '\d <table_name>'
```

Editing an already-applied migration file does **not** retroactively change the database — `migrate` tracks applied versions and just no-ops on `up` if you're already there. Rolling back and reapplying (`down 1` then `up`) is only safe pre-data, during local dev before anything real is stored. Once this app has data you care about, fix a mistake with a *new* migration (`ALTER TABLE ...`), never by editing or re-running an old one.

### Troubleshooting

**Filenames must match `{version}_{name}.up.sql` / `.down.sql` exactly** — no extra text, no spaces (e.g. a stray `... copy.sql` from a Finder/editor duplicate). `migrate` silently ignores anything that doesn't match the pattern; there's no error, it just never runs. If `up` reports fewer changes than expected, check `ls migrations/` for a file that looks *almost* right.

**If `migrate up` says "no change" but the table isn't actually there:** check the recorded version:
```
docker compose exec db psql -U becoming -d becoming -c 'SELECT * FROM schema_migrations;'
```
If it shows the version as applied (and not dirty) but the schema doesn't match, that version got marked done against a migration file that didn't do what you think — e.g. running with a `DROP TABLE IF EXISTS` where a `CREATE TABLE` should've been is a harmless no-op that still "succeeds" and gets recorded. Fix by resetting the bookkeeping to the last version you trust, then reapplying:
```
migrate -path migrations -database "$DATABASE_URL" force <last_good_version>
migrate -path migrations -database "$DATABASE_URL" up
```
