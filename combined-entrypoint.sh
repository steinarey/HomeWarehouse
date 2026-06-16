#!/usr/bin/env bash
set -e

# Arguments passed as CMD (default "postgres")
POSTGRES_CMD="$@"

# 1) Start Postgres with original entrypoint, in the background
/usr/local/bin/docker-entrypoint-postgres.sh "$POSTGRES_CMD" &
PG_PID=$!

# 2) Wait for Postgres to be ready
echo "Waiting for Postgres to be ready..."
until pg_isready -h localhost -p 5432 -U "$POSTGRES_USER" >/dev/null 2>&1; do
  sleep 1
done
echo "Postgres is ready"

# 3) Start the API using your existing start script
echo "Starting API..."
/start.sh &
API_PID=$!

# 4) Wait for either process to exit
wait -n "$PG_PID" "$API_PID"
EXIT_CODE=$?

echo "One of the processes exited with code $EXIT_CODE, shutting down..."
exit "$EXIT_CODE"
