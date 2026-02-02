#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -f "${ROOT_DIR}/infra/config.sh" ]]; then
  # shellcheck source=/home/hannah/Documents/Projects/benzene/infra/config.sh
  . "${ROOT_DIR}/infra/config.sh"
fi

COMPOSE_FILE="${BENZENE_COMPOSE_FILE:-${SCRIPT_DIR}/docker-compose.yml}"
CONTAINER_NAME="${BENZENE_CONTAINER_NAME:-benzene-postgres}"

echo "⚠️  NUKING benzene Postgres database"
echo "This will DELETE ALL DATA in the benzene-pgdata volume."
echo

echo "Stopping compose stack..."
docker compose -f "$COMPOSE_FILE" down -v || true

echo "Removing old Postgres container if it exists..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "Starting fresh Postgres..."
docker compose -f "$COMPOSE_FILE" up -d "$CONTAINER_NAME"

echo "Waiting for Postgres to become healthy..."
until docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null | grep -q healthy; do
  sleep 1
done

echo "✅ benzene Postgres is fresh and ready"
