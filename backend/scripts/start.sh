#!/bin/bash
set -e

# Wait for DB to be ready (simple sleep for now, could use wait-for-it)
echo "Waiting for database..."
sleep 5

# Run migrations
echo "Running migrations..."
alembic upgrade head

# Create initial data
echo "Creating initial data..."
python -m app.initial_data

# Start application
echo "Starting application..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
