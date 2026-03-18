# APISIX Gateway Stack

This folder contains a local development gateway stack for the workspace. It is intentionally isolated from the existing app compose files in [`quran-api/docker-compose.yml`](/Users/HP/Desktop/quran-app/quran-api/docker-compose.yml).

## What It Runs

- `laravel`: the Laravel API app
- `mongo`: MongoDB for the Laravel app
- `etcd`: APISIX configuration store
- `apisix`: public gateway for local development
- `apisix-dashboard`: dashboard UI for managing APISIX
- `apisix-bootstrap`: one-shot helper that creates the initial Laravel route automatically

## Current Scope

- This compose stack runs Laravel and MongoDB only.
- The AI transcription service is intentionally not included here.
- APISIX fronts the Laravel API inside the same Docker network.
- Public gateway entrypoint:
  - `http://localhost:9080/api/...` -> `http://laravel:8001/api/...` internally
- Laravel is still exposed directly on `http://localhost:8001` for smoke testing.
- The separate AI-heavy compose remains in [`quran-api/docker-compose.yml`](/Users/HP/Desktop/quran-app/quran-api/docker-compose.yml).

## Ports

- `8001`: Laravel API direct access
- `27017`: MongoDB
- `9080`: APISIX public gateway
- `9180`: APISIX Admin API, bound to `127.0.0.1` only
- `9000`: APISIX Dashboard, bound to `127.0.0.1` only

## Start Up

Run from this folder:

```powershell
docker compose up -d
```

The bootstrap container will wait for APISIX and then create the initial `/api/*` route automatically.

## Expected Development Flow

1. Start this stack from `infrastructure/docker`.
2. Wait for Laravel, MongoDB, APISIX, and the bootstrap container to finish starting.
3. Access Laravel through APISIX on `http://localhost:9080/api/...`.
4. Optionally smoke-test Laravel directly on `http://localhost:8001/api/...`.

## Dashboard Access

- URL: `http://127.0.0.1:9000`
- Username: `admin`
- Password: `admin`

## Notes

- This stack is for local development, not production hardening.
- Laravel and MongoDB have been moved here so you can work without pulling the AI service.
- To add more upstream routes later, either:
  - add more bootstrap calls in [`infrastructure/docker/scripts/bootstrap-routes.sh`](/Users/HP/Desktop/quran-app/infrastructure/docker/scripts/bootstrap-routes.sh), or
  - create them through the dashboard or the Admin API.
