#!/usr/bin/env bash
set -euo pipefail

echo "⚠️  NUKING benzene Postgres database"
echo "This will DELETE ALL DATA in the benzene-pgdata volume."
echo

#read -p "Type 'nuke' to continue: " CONFIRM
#if [[ "$CONFIRM" != "nuke" ]]; then
#  echo "Aborted."
#  exit 1
#fi

echo "Stopping compose stack..."
docker compose down || true

echo "Removing old Postgres container if it exists..."
docker rm -f benzene-postgres 2>/dev/null || true

echo "Removing Postgres volume..."
docker volume rm docker_benzene-pgdata 2>/dev/null || true

echo "Starting fresh Postgres..."
docker compose up -d benzene-postgres

echo "Waiting for Postgres to become healthy..."
until docker inspect --format='{{.State.Health.Status}}' benzene-postgres 2>/dev/null | grep -q healthy; do
  sleep 1
done

echo "✅ benzene Postgres is fresh and ready"
