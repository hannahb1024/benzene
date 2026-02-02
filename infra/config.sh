#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${CONFIG_DIR}/.." && pwd)"
ENV_FILE="${CONFIG_DIR}/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/home/hannah/Documents/Projects/benzene/infra/.env
  . "$ENV_FILE"
  set +a
fi

if [[ -z "${BENZENE_DB_NAME:-}" && -n "${POSTGRES_DB:-}" ]]; then
  BENZENE_DB_NAME="$POSTGRES_DB"
fi
if [[ -z "${BENZENE_DB_USER:-}" && -n "${POSTGRES_USER:-}" ]]; then
  BENZENE_DB_USER="$POSTGRES_USER"
fi
if [[ -z "${BENZENE_DB_PASSWORD:-}" && -n "${POSTGRES_PASSWORD:-}" ]]; then
  BENZENE_DB_PASSWORD="$POSTGRES_PASSWORD"
fi

export BENZENE_DB_HOST="${BENZENE_DB_HOST:-localhost}"
export BENZENE_DB_PORT="${BENZENE_DB_PORT:-5432}"
export BENZENE_DB_NAME="${BENZENE_DB_NAME:-benzene}"
export BENZENE_DB_USER="${BENZENE_DB_USER:-benzene}"
export BENZENE_DB_PASSWORD="${BENZENE_DB_PASSWORD:-benzene}"
export BENZENE_DB_URL="${BENZENE_DB_URL:-postgresql://${BENZENE_DB_USER}:${BENZENE_DB_PASSWORD}@${BENZENE_DB_HOST}:${BENZENE_DB_PORT}/${BENZENE_DB_NAME}}"

export BENZENE_CONTAINER_NAME="${BENZENE_CONTAINER_NAME:-benzene-postgres}"
export BENZENE_COMPOSE_FILE="${BENZENE_COMPOSE_FILE:-${CONFIG_DIR}/database/docker-compose.yml}"

export BENZENE_CSV_DIR="${BENZENE_CSV_DIR:-${ROOT_DIR}/csvs}"
export BENZENE_CSV_PATTERN="${BENZENE_CSV_PATTERN:-UpdatedFuelPrice-*.csv}"
