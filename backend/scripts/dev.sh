#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created backend/.env — edit PEYA_APP_ADMIN_* before production use."
fi
docker compose up -d oracle
echo "Waiting for Oracle..."
sleep 5
mvn -pl modules/server spring-boot:run
