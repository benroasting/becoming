# Becoming

A personal values/accountability app. Unlike generic goal trackers, it's **values-first**: you record the long-term character you're working toward (a better husband, friend, future father…), then connect habits, goals and journal entries back to those values, so day-to-day actions stay visibly tied to who you're trying to become.

- **Backend:** Go API (Chi, pgx/Postgres, golang-migrate)
- **Mobile:** native Swift iOS app (SwiftUI)
- **Single-user for now:** no auth, no users table — deliberately deferred.

## What it does

| Tab | What you can do |
| --- | --- |
| **Values** | Create, edit and abandon values (abandoning is permanent). Tap a value to see its **Journey**. |
| **Habits** | Create, edit and archive habits, each tied to one or more values. Check in by **swiping right** on a habit (or press and hold). |
| **Goals** | Time-bound checkpoints backed by existing habits and values; mark them complete. |
| **Journal** | Freeform entries, optionally tagging values as **Growth**, **Neutral** or **Setback**. |

**The Journey** is the heart of the app. For each value it shows a trail of your running Growth/Neutral/Setback total over a per-day heat strip on one scrolling timeline, with a dashed road ahead toward the next milestone. The trail comes **only from your journal tags**. Habit check-ins for that value appear as small dots under each day, but never change the score. See [PLANNING.md](PLANNING.md#design-ios) for why.

## Repository layout

```
backend/    Go API, SQL migrations, docker-compose for Postgres
mobile/     Xcode project for the iOS app
PLANNING.md Domain model, API surface, design decisions
```

<details>
<summary>More detail</summary>

```
backend/
  cmd/server/            entry point (config, DB pool, router, graceful shutdown)
  internal/config/       env-based config
  internal/handlers/     HTTP handlers + Chi router
  internal/models/       domain types
  internal/repository/   Postgres access (pgx)
  migrations/            numbered .up.sql / .down.sql pairs
  docs/adr/              architecture decision records
  BUILD_STEPS.md         build history and "done when" checks

mobile/Becoming/
  App/                   Theme (colors, typography), environment keys
  Components/            shared views (e.g. multi-select section)
  Features/              Values, Habits, Goals, Journal, Journey — each a view model + list + form
  Models/                Codable models mirroring the API
  Networking/            APIClient + one service protocol per resource
  Fonts/                 Merriweather (SIL OFL, shipped unmodified)
mobile/BecomingTests/    unit tests
```

</details>

## Running it locally

### Prerequisites

- Go (see `backend/go.mod` for the version)
- Docker (for Postgres)
- [`golang-migrate`](https://github.com/golang-migrate/migrate): `brew install golang-migrate`
- Xcode (see [Mobile](#mobile) for version notes)

### Backend

```sh
cd backend

# One-time: docker-compose.yml expects this external volume to exist.
docker volume create becoming_pgdata

# Start Postgres (host port 5434, not the default 5432).
docker compose up -d

# Apply migrations.
export DATABASE_URL="postgres://becoming:becoming@localhost:5434/becoming?sslmode=disable"
migrate -path migrations -database "$DATABASE_URL" up

# Run the API on :8081.
go run ./cmd/server
```

Check it's up: `curl localhost:8081/health`.

Try the API:

```sh
curl -X POST localhost:8081/api/v1/values \
  -H 'Content-Type: application/json' \
  -d '{"title":"A present husband","description":"Phone away, eyes up"}'

curl localhost:8081/api/v1/values
```

**Configuration** (all optional; defaults shown):

| Variable | Default |
| --- | --- |
| `PORT` | `8081` |
| `ENVIRONMENT` | `development` |
| `LOG_LEVEL` | `info` (`debug`, `info`, `warn`, `error`) |
| `DATABASE_URL` | `postgres://becoming:becoming@localhost:5434/becoming?sslmode=disable` |

More on creating and rolling back migrations, and a troubleshooting section, in [`backend/README.md`](backend/README.md).

### Mobile

1. Make sure the backend is running.
2. Open `mobile/Becoming.xcodeproj` in Xcode, pick a simulator, and run.

The app talks to `http://localhost:8081/api/v1` (set in `mobile/Becoming/AppConfiguration.swift`), which works from the iOS Simulator. To run on a physical device, change that to your machine's LAN address.

**Xcode / iOS version:** the project file currently sets an iOS **26.5** deployment target, so it opens cleanly in a matching Xcode. The code only needs iOS 18+ APIs, so on an older Xcode you can lower the deployment target under *Build Settings → iOS Deployment Target*.

**Tests:** `mobile/BecomingTests` uses Swift Testing (⌘U in Xcode). Right now the only tested code is the Journey calculation (`ValueJourney`). There are no Go tests yet; backend steps were verified by hand with curl (see [`backend/BUILD_STEPS.md`](backend/BUILD_STEPS.md)).

## API

All routes are under `/api/v1` (except `/health`). Data is single-user.

| Resource | Endpoints |
| --- | --- |
| Values | `GET/POST /values`, `GET/PUT /values/{id}`, `POST /values/{id}/abandon` |
| Habits | `GET/POST /habits`, `GET/PUT /habits/{id}`, `POST /habits/{id}/archive` |
| Check-ins | `GET/POST /habits/{id}/check-ins` |
| Goals | `GET/POST /goals`, `GET/PUT /goals/{id}` |
| Journal | `GET/POST /journal-entries`, `GET/PUT/DELETE /journal-entries/{id}` |

A few rules worth knowing: a habit needs at least one value; a goal needs at least one value **and** one habit, all of which must already exist; values can be abandoned but never deleted or reactivated; habits are archived rather than deleted so check-in history survives. The full model and the reasoning are in [PLANNING.md](PLANNING.md).

## Docs

- [PLANNING.md](PLANNING.md): vision, domain model, API surface, design decisions (palette, typography, Journey)
- [backend/README.md](backend/README.md): migrations and troubleshooting
- [backend/BUILD_STEPS.md](backend/BUILD_STEPS.md): build history with "done when" checks
- [backend/docs/adr/](backend/docs/adr/): architecture decision records

## Known gaps / next up

- Out-of-range `impact`, `frequency` or goal `status` values are rejected by the database but surface as a 500 instead of a 400 (Postgres check violation `23514` isn't mapped yet).
- No progress rollup endpoint (`GET /values/{id}/progress`); the Journey is currently computed on the device.
- No auth or multi-user support.
- Habit check-in history screen, and a "done this period" view.

## Credits

Typeset in [Merriweather](https://github.com/EbenSorkin/Merriweather4), © The Merriweather Project Authors, used under the SIL Open Font License 1.1 (see `mobile/Becoming/Fonts/Merriweather-OFL.txt`).
