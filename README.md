# Home Warehouse

Self-hosted home pantry tracker. FastAPI backend + Flutter mobile (iOS / Android / web).

This guide covers running the backend against an **existing PostgreSQL server**
(e.g. the Postgres container on your unRAID box) and pointing the mobile app at
it.

---

## 1. Prepare the database

Connect to your Postgres server (psql, Adminer, pgAdmin, or `docker exec -it
<pg-container> psql -U postgres`) and create a dedicated role + database.

```sql
-- Pick a strong password. This is what the app will use.
CREATE ROLE inventory_user WITH LOGIN PASSWORD 'change-me-please';

-- Database, owned by the new role.
CREATE DATABASE inventory OWNER inventory_user;

-- Grant the role full rights on its own database.
GRANT ALL PRIVILEGES ON DATABASE inventory TO inventory_user;
```

Verify the role can connect from the host that will run the backend:

```bash
psql -h <unraid-host> -p 5432 -U inventory_user -d inventory
```

If the connection is rejected, check the Postgres container's `pg_hba.conf`
accepts your network and that the container port (default `5432`) is exposed on
unRAID.

**Schema setup is automatic.** The backend runs `alembic upgrade head` on boot
(see `backend/scripts/start.sh`), which creates every table on a fresh
database. No manual `CREATE TABLE` needed.

---

## 2. Configure the backend

The backend reads its configuration from environment variables. Only two are
strictly required:

| Variable                  | Required | Example                                                                    |
| ------------------------- | -------- | -------------------------------------------------------------------------- |
| `DATABASE_URL`            | yes      | `postgresql+psycopg2://inventory_user:change-me-please@unraid.lan:5432/inventory` |
| `JWT_SECRET_KEY`          | yes      | `openssl rand -hex 32` output                                              |
| `JWT_ALGORITHM`           | no       | `HS256` (default)                                                          |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | no   | `10080` (7 days, default)                                                  |
| `CORS_ALLOW_ORIGINS`      | no       | `https://pantry.example.com` (comma-separated). Unset = localhost-only.    |
| `RATE_LIMIT_STORAGE_URI`  | no       | `redis://host:6379` (needed only for multi-worker prod)                    |

Generate a secret once and keep it stable; rotating it invalidates all existing
JWTs and forces every user to log in again.

```bash
export JWT_SECRET_KEY="$(openssl rand -hex 32)"
```

---

## 3. Deploy the backend

Pick **one** of the three options below. All three target the unRAID Postgres
from outside the bundled `db` container.

### Option A — Docker, single backend container (recommended)

Build the backend image and run it pointing at unRAID:

```bash
cd backend
docker build -t home-warehouse-api .

docker run -d --name home-warehouse-api --restart=always \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql+psycopg2://inventory_user:change-me-please@<unraid-host>:5432/inventory" \
  -e JWT_SECRET_KEY="$(openssl rand -hex 32)" \
  -e CORS_ALLOW_ORIGINS="*" \
  home-warehouse-api
```

To put this container on unRAID directly, use the Community Applications
"Add Container" form with:

- **Repository**: `home-warehouse-api` (or push to a registry first)
- **Port**: host `8000` → container `8000`
- **Variables**: `DATABASE_URL`, `JWT_SECRET_KEY`, `CORS_ALLOW_ORIGINS`

On first boot the container runs migrations + seeds the initial admin user
(see `backend/app/initial_data.py`).

### Option B — `docker-compose.yml` with external DB

The repo ships a `docker-compose.yml` that bundles its own Postgres. To reuse
your existing DB, drop the `db` service and the `depends_on` block, and supply
`JWT_SECRET_KEY`:

```yaml
services:
  api:
    build: ./backend
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+psycopg2://inventory_user:change-me-please@<unraid-host>:5432/inventory
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
```

Then:

```bash
export JWT_SECRET_KEY="$(openssl rand -hex 32)"
docker compose up -d
```

### Option C — Bare metal (no Docker)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export DATABASE_URL="postgresql+psycopg2://inventory_user:change-me-please@<unraid-host>:5432/inventory"
export JWT_SECRET_KEY="$(openssl rand -hex 32)"

alembic upgrade head
python -m app.initial_data           # one-time seed
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

For a persistent service, wrap the `uvicorn` line in a systemd unit or run
under `pm2 / supervisor`.

---

## 4. Verify the backend

```bash
curl http://<backend-host>:8000/health
# {"status":"ok"}

# OpenAPI docs:
open http://<backend-host>:8000/docs
```

Create the first user via the docs page (`POST /users/`) — no invite code on a
fresh install means a new warehouse is auto-created with that user as admin.

---

## 5. Build and configure the mobile app

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# iOS only, one-time:
cd ios && pod install && cd ..
```

The mobile app stores its backend URL in `SharedPreferences`. On first launch
the user is sent to **Onboarding**, where they enter the backend URL:

- Same host as backend container: `http://<unraid-host>:8000`
- Android emulator pointing at host machine: `http://10.0.2.2:8000`
- Physical device on LAN: `http://<host-lan-ip>:8000`

The default placeholder is `http://10.0.2.2:8000` (the Android emulator's
loopback to the host machine). Change it to your unRAID host in onboarding or
later in **Settings → Connection**.

After setting the URL, log in (or register) on the next screen.

### Run modes

```bash
flutter run                # default device
flutter run -d chrome      # web build (requires CORS_ALLOW_ORIGINS on backend)
flutter build apk          # release APK
flutter build ipa          # release iOS archive
```

---

## 6. Day-to-day operations

### Apply schema changes after a `git pull`

```bash
# Docker:
docker exec home-warehouse-api alembic upgrade head

# Bare metal:
cd backend && alembic upgrade head
```

`start.sh` already runs migrations on container boot, so simply restarting the
container also works.

### Back up the database

This is your responsibility — the app holds no local state outside Postgres.
Standard `pg_dump`:

```bash
pg_dump -h <unraid-host> -U inventory_user inventory > inventory-$(date +%F).sql
```

### Logs

```bash
docker logs -f home-warehouse-api
```

### Rotate the JWT secret

Set a new `JWT_SECRET_KEY` and restart. Every issued token instantly becomes
invalid; clients are bounced to the login screen. There is no token blacklist
to maintain.

---

## 7. Troubleshooting

| Symptom                                                          | Cause / fix                                                                                          |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Backend exits immediately with `field required: JWT_SECRET_KEY` | Set the env var (see step 2). Required, no default.                                                  |
| `psycopg2.OperationalError: could not connect to server`         | DB host/port unreachable, or `pg_hba.conf` rejects the source network. Test with `psql` first.       |
| `password authentication failed for user "inventory_user"`       | Password mismatch between `CREATE ROLE` and `DATABASE_URL`. Reset with `ALTER ROLE inventory_user WITH PASSWORD '...';`. |
| Mobile app stuck on splash / spinning loader                     | Wrong backend URL or backend not reachable from the device. Use Settings → Connection to verify.     |
| Flutter web shows CORS errors in browser console                 | Set `CORS_ALLOW_ORIGINS` to the web app's origin (e.g. `https://pantry.example.com`).                |
| `429 Too Many Requests` on login                                 | Rate limit is 10/min per IP. Wait a minute or whitelist your IP at a reverse proxy.                  |
| Migration error on boot after pulling new code                   | Run `alembic upgrade head` manually and read the error. Most likely a half-applied previous version. |

---

## 8. Project layout

```
.
├── backend/                 FastAPI + SQLAlchemy + Alembic
│   ├── app/
│   │   ├── api/endpoints/   HTTP routes (users, inventory, products, …)
│   │   ├── models/          SQLAlchemy ORM (warehouse-scoped)
│   │   ├── schemas/         Pydantic v2 request/response
│   │   ├── services/        Business logic (inventory_service)
│   │   └── core/            config, security, time, rate_limit
│   ├── alembic/versions/    Schema migrations
│   └── tests/               pytest (in-memory SQLite)
├── mobile/                  Flutter app (PantryKeeper)
│   └── lib/                 data / domain / presentation split
├── docker-compose.yml       Local-dev stack (bundles its own Postgres)
└── Dockerfile.allinone      Single-container Postgres + API (demo/testing)
```

Detailed architecture notes live in `mobile/CLAUDE.md`.
