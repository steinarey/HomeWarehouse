# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Monorepo with two sibling projects under `HomeWarehouse/`:

- `mobile/` — Flutter app "PantryKeeper" (this directory). iOS, Android, macOS, web, Windows, Linux targets configured.
- `backend/` — FastAPI + SQLAlchemy + PostgreSQL service. Migrations via Alembic.
- `docker-compose.yml` — runs `db` (Postgres 16) + `api` (backend on `:8000`) for local dev.
- `Dockerfile.allinone` + `combined-entrypoint.sh` — single-container Postgres+API image for test/demo deploys.

The Flutter app talks to the FastAPI service. There is no shared schema codegen — Dart models in `lib/data/models/*.dart` are hand-mirrored against Pydantic schemas in `backend/app/schemas/`. When backend response shape changes, both sides must be updated.

## Commands

### Mobile (run from `mobile/`)

```bash
flutter pub get
flutter run                                      # default device
flutter run -d chrome                            # web
flutter test                                     # all tests
flutter test test/path/to_test.dart              # single file
flutter test --plain-name "test name"            # single test by name
flutter analyze                                  # lint (uses analysis_options.yaml -> flutter_lints)
dart run build_runner build --delete-conflicting-outputs   # regen *.g.dart (riverpod_generator, json_serializable)
dart run build_runner watch --delete-conflicting-outputs   # continuous codegen
```

After editing any `@riverpod`-annotated provider or any `@JsonSerializable` model, re-run `build_runner` or the corresponding `.g.dart` will go stale and the app won't compile.

### Backend (run from `backend/`)

```bash
docker compose up                                # from repo root, brings up db + api with autoreload
pip install -r requirements.txt                  # local venv
uvicorn app.main:app --reload                    # local without docker (needs DATABASE_URL)
alembic upgrade head                             # apply migrations
alembic revision --autogenerate -m "msg"         # new migration from model diff
python -m app.initial_data                       # seed initial data
pytest                                           # all tests (uses in-memory SQLite, see tests/conftest.py)
pytest tests/test_inventory.py                   # single file
pytest -k "test_name_substring"                  # filter by name
```

`backend/scripts/start.sh` is the container entrypoint: it sleeps 5s, runs `alembic upgrade head`, runs `python -m app.initial_data`, then starts uvicorn with `--reload`.

## Backend architecture

Layered FastAPI app under `backend/app/`:

- `main.py` — minimal: creates `FastAPI`, mounts `api_router`, exposes `/health`.
- `api/api.py` — composes the router from `api/endpoints/{login,users,locations,categories,products,inventory,invites,notifications}.py`. The inventory router is mounted **twice** — once at `/inventory` and once at `""` so `/dashboard` resolves via the same module. Keep that double-mount in mind when adding routes to `inventory.py`: a path under `inventory.py` is reachable at both `/inventory/<path>` and `/<path>`.
- `api/deps.py` — FastAPI dependencies (DB session, current user).
- `models/` — SQLAlchemy 2.x typed `Mapped[...]` ORM models. Entities: `User`, `Warehouse`, `WarehouseMember`, `Invite`, `Category`, `Location`, `Product`, `StockBatch`, `InventoryAction`.
- `schemas/` — Pydantic request/response models.
- `services/inventory_service.py` — business logic for restock/consume/adjust. Stock is tracked in `StockBatch` rows keyed by `(product_id, location_id, expiry_date)`; matching batches are merged on restock. Every mutation emits an `InventoryAction` row.
- `db/base.py` — declarative `Base`; `db/session.py` — engine/session.
- `core/config.py` — `Settings` from env (`DATABASE_URL`); `core/security.py` — password hashing + JWT.
- `alembic/versions/` — migrations. Add one whenever a model changes.

Multi-tenant model: data is scoped by `warehouse_id`. `WarehouseMember` joins users to warehouses with a role. `Invite` is the join flow.

Tests (`backend/tests/`) use **in-memory SQLite** with a `StaticPool`, override `get_db` per test, and swap bcrypt for `md5_crypt` for speed — see `conftest.py`. Don't rely on Postgres-specific SQL in tested code paths.

## Mobile architecture

Riverpod + go_router + Dio. Standard 3-layer split under `lib/`:

- `data/` — `api/api_client.dart` (single Dio wrapper, one method per endpoint), `models/*.dart` (+ generated `*.g.dart`), `repositories/*.dart` (thin pass-through over `ApiClient`).
- `domain/providers/` — Riverpod providers. `auth_provider`, `core_providers` (Dio, SharedPreferences, ApiClient, repositories), `dashboard_provider`, `user_provider`, `member_provider`, `theme_provider`, `locale_provider`. The `@riverpod` annotation generates `.g.dart`.
- `domain/services/notification_service.dart` — `flutter_local_notifications` wrapper, also invoked from the `workmanager` background task.
- `presentation/screens/` — one file per route, plus `scaffold_with_navbar.dart` for the bottom-nav shell. `low_stock/` and `use_restock/` subdirs hold tabs/components for those screens.
- `config/router.dart` — `GoRouter` with a top-level redirect that gates on `authProvider`: unauth → `/login`; auth-on-login → `/`. `StatefulShellRoute.indexedStack` powers the bottom navbar.
- `config/app_constants.dart` — base URL + constants.
- `l10n/app_localizations.dart` — generated localizations. Supported locales: `en`, `is` (Icelandic).
- `main.dart` — initializes `NotificationService`, registers a 24h `Workmanager` periodic task `check_notifications`, then runs `ProviderScope` with a `SharedPreferences` override.

Background task entry point is `callbackDispatcher` in `main.dart`, marked `@pragma('vm:entry-point')` — must stay top-level for Workmanager.

## Conventions

- Generated files (`*.g.dart`, `*.freezed.dart` if added) are committed. After model/provider edits, run `build_runner` and commit both.
- Backend uses SQLAlchemy 2.x `Mapped[...]` typed columns — match that style when adding models.
- Backend datetimes use naive `datetime.utcnow` defaults (see `Product`, etc.); preserve that pattern rather than mixing tz-aware values.
- Don't bypass `inventory_service` for stock mutations — `StockBatch` merging and `InventoryAction` emission must stay together.
- When backend response shape changes, update the corresponding Dart model **and** rerun `build_runner` in `mobile/`.
