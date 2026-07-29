#!/usr/bin/env bash
# Smoke test — endpoints Mon Peya backend (port 8082)
set -euo pipefail

BASE="${BASE_URL:-http://localhost:8082}"

echo "== Platform ping =="
curl -sf -X POST "$BASE/api/platform/v1/ping" \
  -H 'Content-Type: application/json' \
  -d '{"data":{"pingId":1}}' | head -c 200
echo

echo "== Billetterie ping =="
curl -sf -X POST "$BASE/api/billetterie/v1/ping" \
  -H 'Content-Type: application/json' \
  -d '{"data":{"pingId":1}}' | head -c 200
echo

echo "== Immo health =="
curl -sf "$BASE/api/immo/health"
echo

echo "== Immo login (bridge — nécessite Peya API) =="
curl -s -X POST "$BASE/api/immo/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"login":"0700000000","password":"1234"}' | head -c 300
echo

echo "OK — smoke test terminé"
