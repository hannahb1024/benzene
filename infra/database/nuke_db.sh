#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="$HOME/Documents/Projects/benzene/infra/database/docker-compose.yml"

echo "⚠️  NUKING benzene Postgres database"
echo "This will DELETE ALL DATA in the benzene-pgdata volume."
echo

echo "Stopping compose stack..."
docker compose -f "$COMPOSE_FILE" down -v || true

echo "Removing old Postgres container if it exists..."
docker rm -f benzene-postgres 2>/dev/null || true

echo "Starting fresh Postgres..."
docker compose -f "$COMPOSE_FILE" up -d benzene-postgres

echo "Waiting for Postgres to become healthy..."
until docker inspect --format='{{.State.Health.Status}}' benzene-postgres 2>/dev/null | grep -q healthy; do
  sleep 1
done

echo "✅ benzene Postgres is fresh and ready"
