#!/usr/bin/env bash
# Bootstrap the DDEV topology for a project spun from this template.
#
#   Usage:  infra/ddev/bootstrap.sh <project-name> [ddev-project-type] [docroot]
#   e.g.:   infra/ddev/bootstrap.sh acme-shop laravel public
#           infra/ddev/bootstrap.sh acme-ingest generic .
#
# Run from the repository root. Requires ddev >= 1.23.5 and Docker — and NOTHING
# else on the host (no Node.js, no PHP, no Go): every tool runs inside DDEV.
# Idempotent: safe to re-run after changing the stack decision.
set -euo pipefail

PROJECT_NAME="${1:?usage: bootstrap.sh <project-name> [ddev-project-type] [docroot]}"
PROJECT_TYPE="${2:-generic}" # laravel | symfony | php | generic (Go, Python, …) — see `ddev config --help`
DOCROOT="${3:-public}"

if [[ ! -d contract || ! -d infra ]]; then
  echo "error: run from the repository root (contract/ and infra/ not found)" >&2
  exit 1
fi

echo "==> ddev config: ${PROJECT_NAME} (type=${PROJECT_TYPE}, php=8.5, database=postgres:16, node=22)"
# --nodejs-version pins the in-container Node.js so contract linting is byte-identical
# across machines; it is the ONLY reason Node is present, and it lives in the container.
# --php-version MUST be explicit: the topology is PHP 8.5, DDEV's own default is 8.4
# (docs/topology/local.md § Services).
# (Harmless for non-PHP `generic` projects — the web container simply ships an unused PHP.)
ddev config \
  --project-name="${PROJECT_NAME}" \
  --project-type="${PROJECT_TYPE}" \
  --docroot="${DOCROOT}" \
  --php-version=8.5 \
  --database=postgres:16 \
  --nodejs-version=22 \
  --bind-all-interfaces \
  --host-db-port=5432

# Remote-development VM: the project's host ports must be reachable from outside the VM,
# not just on 127.0.0.1. The project-level flag above binds the project's own ports; the
# shared router (ports 80/443) is a HOST-GLOBAL setting and cannot be set from .ddev/:
echo "==> binding router on all interfaces (host-global setting)"
ddev config global --router-bind-all-interfaces=true

echo "==> installing Redis add-on"
# 'ddev add-on get' requires ddev >= 1.23.5; on older versions use: ddev get ddev/ddev-redis
ddev add-on get ddev/ddev-redis

# The add-on's compose file floats at `redis:7`; this pins it. Why the pin is set through
# `ddev dotenv set` and never by editing that file, and why it MUST run after the add-on:
# infra/README.md § Known DDEV behaviours. The tag: docs/topology/local.md § Services.
# To move the pin: `docker pull redis:<new>`, update the tag below, re-run bootstrap, then
# `ddev poweroff && ddev start` and re-check `maxmemory-policy`.
echo "==> pinning Redis image (add-on default floats at redis:7)"
ddev dotenv set .ddev/.env.redis --redis-docker-image=redis:7.4.10-bookworm

# The add-on ships `maxmemory-policy allkeys-lfu`, wrong here: queues and sessions share the
# instance with the cache and Redis eviction is server-wide, so a cache-driven eviction can
# drop a queued job. Overwritten with the platform conf — MUST run after the add-on, which owns
# the same path. `#ddev-generated` is prepended onto the GENERATED copy only: a later
# `ddev add-on get` greps for that literal and refuses to touch the file without it, while the
# shared source infra/shared/redis/redis.conf must carry no runtime-specific convention.
echo "==> applying platform Redis config (eviction policy)"
mkdir -p .ddev/redis
{
  echo '#ddev-generated'
  cat infra/shared/redis/redis.conf
} >.ddev/redis/redis.conf

# Mail: DDEV runs Mailpit in the web container and points MAIL_MAILER/HOST/PORT at it in .env.
# Only the sender identity needs correcting, and dotenv is IMMUTABLE — a value present in .env
# is never overwritten by a config default, so it is injected as web_environment: a real
# container variable, which dotenv will not overwrite and which survives DDEV rewriting .env.
echo "==> wiring platform mail sender identity (web container)"
ddev config --web-environment-add="MAIL_FROM_ADDRESS=no-reply@${PROJECT_NAME}.ddev.site"

echo "==> installing contract-lint command (Spectral, runs in-container)"
mkdir -p .ddev/commands/web
cp infra/ddev/commands/web/contract-lint .ddev/commands/web/contract-lint

# Lifecycle hooks live in their own config file: `ddev config` above rewrites
# .ddev/config.yaml, while DDEV merges every .ddev/config.*.yaml — so hooks placed here
# survive a re-bootstrap. The post-start hook itself runs infra/ddev/hooks/dev-install.sh
# straight from the bind-mounted repository root; only this pointer is copied.
echo "==> installing post-start hook (dev install: composer, migrate, dev tenants)"
cp infra/ddev/config.hooks.yaml .ddev/config.hooks.yaml
chmod +x infra/ddev/hooks/dev-install.sh

# The development queue worker (T19). Same mechanism and same reason as the hooks file:
# `ddev config` above rewrites config.yaml and has no flag for web_extra_daemons, so the
# daemon lives in its own merged config file. The script itself is run from the
# bind-mounted repository root, not copied.
echo "==> installing queue worker daemon (queue:listen, supervised in the web container)"
cp infra/ddev/config.daemons.yaml .ddev/config.daemons.yaml
chmod +x infra/ddev/daemons/queue-worker.sh

echo "==> wiring application locale (web container)"
cp infra/ddev/config.locale.yaml .ddev/config.locale.yaml

# Document engine: internal-only compose service + its build context. The image carries the
# runtime (Python 3.12 + LibreOffice + pinned deps); the application source is bind-mounted
# read-only from engine/, so editing engine/** needs no image rebuild.
#
# Guarded on engine/ existing: the service bind-mounts ../engine, so installing it in a
# repository without an engine would produce a container that fails its healthcheck forever.
if [[ -d engine ]]; then
  echo "==> installing engine service (compose + build context)"
  mkdir -p .ddev/engine-build
  cp infra/ddev/docker-compose.engine.yaml .ddev/docker-compose.engine.yaml
  # Two runtime-agnostic sources, one build directory — why the pair is assembled rather
  # than resolved across runtimes: docs/architecture.md § Runtimes,
  # docs/topology/local.md § Generation.
  cp infra/shared/engine/Dockerfile .ddev/engine-build/Dockerfile
  cp infra/shared/engine/requirements.txt .ddev/engine-build/requirements.txt

  # The platform is the engine's only client, so it needs the seam's coordinates and
  # the same shared secret the engine container is started with — otherwise every
  # call gets 401 the moment the bridge is written. Both sides read the SAME
  # ENGINE_KEY default; override it per environment (export ENGINE_KEY=… before
  # bootstrap, or .ddev/config.local.yaml) — the default is dev-only, not a secret.
  echo "==> wiring platform → engine environment (web container)"
  ddev config --web-environment-add="ENGINE_URL=http://engine:8000,ENGINE_KEY=${ENGINE_KEY:-dev-only-insecure-engine-key}"
else
  echo "==> skipping engine service (no engine/ directory in this repository)"
fi

echo "==> starting topology (first run builds the engine image: LibreOffice, several minutes)"
ddev start
ddev describe

cat <<'EOF'

Done. Next steps:
  - Lint contracts:  ddev contract-lint          (Spectral, runs in-container)
  - Postgres shell:  ddev psql          Redis shell:  ddev redis-cli
  - Engine health:   ddev exec curl -s http://engine:8000/health   (internal only —
    there is no host port and no router entry for the engine, by design)
  - Commit .ddev/ so every machine runs the identical topology. (Commit only on
    explicit request — see CLAUDE.md working agreement.)
EOF
