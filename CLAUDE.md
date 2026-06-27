# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Home Warehouse / "PantryKeeper" — a self-hosted home pantry tracker. Monorepo with two siblings:

- `backend/` — FastAPI + SQLAlchemy 2.0 + PostgreSQL, migrated with Alembic.
- `mobile/` — Flutter app (iOS / Android / web / desktop). See `mobile/CLAUDE.md` for Flutter-specific commands and architecture.

The Flutter app talks to the FastAPI service over HTTP. **There is no shared schema codegen** — Dart models in `mobile/lib/data/models/*.dart` are hand-mirrored against Pydantic schemas in `backend/app/schemas/`. When a backend response shape changes, both sides must be updated by hand.

`docker-compose.yml` runs `db` (Postgres 16) + `api` (backend on `:8000`) for local dev and bundles its own Postgres. Production typically points a single backend container at an external Postgres (see `README.md` for deploy options).

## Backend commands (run from `backend/`)

Always work inside a virtualenv — never `pip install` globally.

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Run the API (also auto-runs migrations + admin seed via scripts/start.sh under Docker)
alembic upgrade head                 # apply migrations
python -m app.initial_data           # seed/refresh admin user (admin / admin)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Tests (in-memory SQLite, no Postgres needed)
pytest
pytest tests/test_inventory.py                       # single file
pytest tests/test_inventory.py::test_name            # single test

# Migrations
alembic revision --autogenerate -m "describe change"
alembic upgrade head
alembic downgrade -1
```

`JWT_SECRET_KEY` is **required at import time** — `app/core/config.py` constructs `Settings()` at module load with no default, so the app (and any test that imports it) fails fast if it is unset. `tests/conftest.py` sets a fixed test value before importing app modules; replicate that pattern in any new test entry point.

The full local stack: `docker compose up -d` (needs `JWT_SECRET_KEY` exported; compose has a dev-only fallback).

## Backend architecture

**Multi-tenancy is the core invariant.** Every domain row carries a `warehouse_id`. Requests resolve their tenant through `app/api/deps.py::get_current_warehouse_member`, which reads the optional `X-Warehouse-Id` header; with no header it falls back to the caller's *first* membership. (The old "self-heal" path that auto-joined callers to `warehouse_id=1` as admin was deliberately removed — do not reintroduce implicit cross-tenant joins.) New endpoints must scope every query by the resolved member's `warehouse_id`; never trust an id from the request body alone.

**Stock data model** (`app/models/`): `Category` → `Product` → `StockBatch`. A product's total stock is the sum of its batches; batches carry an `expiry_date`. Consumption is **FEFO** (first-expiry-first-out) — see `_consume_fefo` in the service. Deleting a category cascades to products and their batches, but `InventoryAction` audit rows are preserved (their fk refs are SET NULL by the endpoint), so the activity log survives deletions.

**All stock mutations go through `app/services/inventory_service.py`** (`restock` / `consume` / `adjust` / `undo`). Endpoints stay thin. Each mutation writes an `InventoryAction` (the audit/activity log and the basis for `undo`) and fires two best-effort, never-raising hooks into the Microsoft To Do integration: auto-resolve open pending-restocks and push a task when a category drops to/below `min_stock`. A connector hiccup must never block an inventory action — keep these wrapped in try/except.

**Microsoft To Do connector** (`app/integrations/microsoft_todo/`, `app/core/scheduler.py`): OAuth (MSAL) connector that syncs low-stock categories to a To Do list as `PendingRestock` rows. OAuth tokens are encrypted at rest with Fernet (`app/core/crypto.py`, key from `CONNECTOR_ENCRYPTION_KEY`). The APScheduler background job and the connector endpoints only activate when `settings.microsoft_connector_enabled` is true (client id + secret + encryption key all set) — otherwise endpoints 503 and the scheduler never starts, which is why tests don't touch it.

**Auth**: JWT bearer (`python-jose`), passwords hashed with bcrypt (`passlib`). Rate limiting via `slowapi` (e.g. login is 10/min/IP); `RATE_LIMIT_STORAGE_URI` (Redis) is only needed for multi-worker prod. Tests swap the hasher to `md5_crypt` for speed.

**Routing note** (`app/api/api.py`): `inventory.router` is mounted twice — once at `/inventory` and once at `` — so dashboard endpoints live at `/dashboard` while the rest live under `/inventory`.

**Tests**: `tests/conftest.py` uses in-memory SQLite via `StaticPool` with per-function transaction rollback. Because tests run against SQLite, avoid Postgres-only SQL in model/query code paths that tests exercise.

## Mobile

See `mobile/CLAUDE.md`. Key cross-cutting facts: the app stores its backend base URL and JWT in `SharedPreferences` (set during onboarding); the Dio interceptor in `lib/domain/providers/core_providers.dart` attaches `Authorization: Bearer <token>`. State management is Riverpod (codegen) + go_router; `*.g.dart` and `*.freezed`-style files are generated via `build_runner` and must be regenerated after editing annotated sources or models.
