# Preview runtime — Compose

Compose project `oir-flow-preview`; source of truth `infra/deploy/compose.yaml`
(ADR-0029). System description: `docs/architecture.md`. Operator procedure:
`docs/runbook.md`.

## Services

| service | what | source |
|---|---|---|
| web | image `oir-flow-preview-web`; `php:8.5.7-fpm-bookworm` + nginx, non-root user `app` uid 1000, listens `8443`, published `0.0.0.0:443:8443` | `infra/deploy/platform/Dockerfile` |
| queue | same image and environment as web, command `queue:work --tries=1 --timeout=360` | `infra/deploy/compose.yaml` |
| db | `postgres:16`, volume `db-data`, published `0.0.0.0:${DB_HOST_PORT:-5432}:5432` | `infra/deploy/compose.yaml` |
| redis | `redis:7.4.10-bookworm`, volume `redis-data`, unpublished | `infra/deploy/compose.yaml` |
| engine | image `oir-flow-preview-engine`, `expose: 8000` only, application source baked in | `infra/deploy/engine/Dockerfile` |
| mailpit | `axllent/mailpit:v1.30.7`, host `:8025` | `infra/deploy/compose.yaml` |

## Rules

- Build context of both images is the repository root. Paths inside the file are relative
  to `infra/deploy/`: invoke with `-f infra/deploy/compose.yaml`, never with
  `--project-directory` at the repository root.
- web and queue MUST share image `oir-flow-preview-web`, `pull_policy: never` — these
  tags exist in no registry, and CI builds the tag once as service `web`.
- The Redis configuration is bind-mounted from `../shared/redis/redis.conf`; the engine
  image COPYs `infra/shared/engine/requirements.txt` from the root context. Neither is
  copied, forked, nor resolved out of another runtime's directory.
- The engine image carries the application source but not the development surface:
  `infra/deploy/engine/Dockerfile.dockerignore` (Dockerfile-scoped, so no other build is
  affected) excludes `engine/.venv`, `**/__pycache__`, `**/.pytest_cache` and `engine/tests`
  from the root context. `engine/pyproject.toml` stays — it supplies `pythonpath`.
- The engine is unpublished: no `ports:`. The intended path is `http://engine:8000` from
  web and queue. Publishing it contradicts `contract/engine.openapi.yaml` `servers`.
- Postgres publishes on every interface; do not run this runtime beside another that
  publishes the same host port without changing `DB_HOST_PORT`.
- web is HTTPS only — no host `:80`. Certificates come from `TLS_CERT` / `TLS_KEY`,
  defaulting to `/var/lib/oir-flow/tls/{fullchain,privkey}.pem`; absent those,
  `infra/deploy/platform/start-web.sh` generates a self-signed pair.
- Configuration is `infra/deploy/.env` (gitignored; template `infra/deploy/.env.example`).
  `APP_ENV` stays `staging`; `ENGINE_KEY` and `STAGING_SEED_PASSWORD` have empty defaults
  and no development value is accepted (`infra/deploy/up.sh`).
- Start and stop this runtime only through `infra/deploy/up.sh`, never from CI and never
  while a pipeline using host Docker is in flight.
- Named volumes `db-data` and `redis-data` persist across additive `up.sh` boots; operator
  `infra/deploy/up.sh --reset-data` removes them via `compose down --volumes` (images and
  bind-mounts stay). See `docs/runbook.md` § Environment up — preview.
