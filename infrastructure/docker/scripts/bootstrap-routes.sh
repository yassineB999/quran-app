#!/bin/sh
set -eu

ADMIN_URL="http://apisix:9180/apisix/admin/routes/laravel-api"
ADMIN_KEY="quran-apisix-4dm1n-k3y-2026"

echo "Waiting for APISIX Admin API..."
until curl -sS -o /dev/null -H "X-API-KEY: ${ADMIN_KEY}" "${ADMIN_URL}"; do
  sleep 2
done

echo "Creating or updating Laravel API route..."
curl -sS -X PUT "${ADMIN_URL}" \
  -H "X-API-KEY: ${ADMIN_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "laravel-api",
    "uri": "/api/*",
    "methods": ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"],
    "upstream": {
      "type": "roundrobin",
      "scheme": "http",
      "nodes": {
        "laravel:8001": 1
      }
    }
  }'

echo
echo "APISIX bootstrap complete."
