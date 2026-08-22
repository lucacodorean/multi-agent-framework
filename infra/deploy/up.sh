#!/usr/bin/env bash
# Operator deploy for Compose project oir-flow-preview.
#
#   Usage:  infra/deploy/up.sh [--build|--no-build] [--recreate] [--reset-data]
#
# Requires Docker Compose and infra/deploy/.env (gitignored). No host PHP/Node/
# Composer — the platform image already ran `composer install --no-dev`,
# `filament:upgrade`, and `npm run build`. This script starts the stack and
# bootstraps the database inside `web`.
#
# Never called from GitLab. Do not run while a pipeline that uses host Docker
# is in flight (same box, project name oir-flow-preview).
#
# Seeders (after migrate): DatabaseSeeder (`db:seed`), TenantDatabaseSeeder
# (`tenants:seed` on existing schemas), then StagingTenantsSeeder
# (`db:seed --class=StagingTenantsSeeder`) under stack APP_ENV=staging.
# Console admin is always asserted from CONSOLE_ADMIN_*.
# Stack APP_ENV must stay staging; this script refuses APP_ENV=local in .env.
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly COMPOSE_FILE="${REPO_ROOT}/infra/deploy/compose.yaml"
readonly ENV_FILE="${REPO_ROOT}/infra/deploy/.env"
readonly ENGINE_IMAGE=oir-flow-preview-engine
readonly PLATFORM_IMAGE=oir-flow-preview-web
readonly FORBIDDEN_ENGINE_KEYS='dev-only-insecure-engine-key
ci-only-insecure-engine-key'
readonly FORBIDDEN_STAGING_SEED_PASSWORD='oirflow-dev'
readonly TENANTS_TABLE_EXISTS_QUERY="SELECT to_regclass('public.tenants') IS NOT NULL;"
readonly CONSOLA_PREFLIGHT_QUERY="SELECT id, name, status FROM public.tenants WHERE id = 'consola';"

BUILD_MODE=auto
RECREATE=0
RESET_DATA=0

usage() {
  cat <<'EOF'
Usage: infra/deploy/up.sh [--build|--no-build] [--recreate] [--reset-data]

  --build       Rebuild engine + web images (composer --no-dev, Filament, Vite).
  --no-build    Use existing oir-flow-preview-web / oir-flow-preview-engine.
  --recreate    Recreate web, queue, and engine after images are in place.
  --reset-data  After images are in place, compose down --volumes (db-data,
                redis-data), then the existing login-ready bootstrap. Images
                stay. The flag is the confirmation (no prompt). Does not imply
                --build.

Default: --build if either image is missing, otherwise --no-build.
Without --reset-data the path is additive (named volumes persist).

Requires infra/deploy/.env with APP_KEY, DB_PASSWORD, ENGINE_KEY,
CONSOLE_ADMIN_EMAIL, CONSOLE_ADMIN_NAME, CONSOLE_ADMIN_PASSWORD,
and STAGING_SEED_PASSWORD (never oirflow-dev). APP_ENV must be staging.
EOF
}

log() {
  echo "==> $*"
}

die() {
  echo "error: $*" >&2
  exit 1
}

compose() {
  docker compose \
    -f "${COMPOSE_FILE}" \
    --env-file "${ENV_FILE}" \
    "$@"
}

in_web() {
  compose exec -T web "$@"
}

env_get() {
  local key="$1"
  local line
  line="$(grep -E "^[[:space:]]*${key}=" "${ENV_FILE}" | tail -n1 || true)"
  [[ -n "${line}" ]] || return 0
  line="${line#*=}"
  if [[ "${line}" == \"*\" ]]; then
    line="${line#\"}"
    line="${line%\"}"
  elif [[ "${line}" == \'*\' ]]; then
    line="${line#\'}"
    line="${line%\'}"
  fi
  printf '%s' "${line}"
}

require_secret() {
  local key="$1"
  local value
  value="$(env_get "${key}")"
  [[ -n "${value}" ]] || die "${key} is empty in ${ENV_FILE}"
}

start_preview_stack() {
  local recreate="$1"
  local ok=0
  local preflight_status
  local tenants_table_exists
  local -a up_args=(up -d --wait --no-build)

  if [[ "${recreate}" -eq 1 ]]; then
    up_args+=(--force-recreate)
  fi

  # Keep the serving containers untouched until both the collision check and the
  # new image's migration have succeeded. --no-deps makes this a db-only start.
  log "starting PostgreSQL only (web and queue remain untouched)"
  if ! compose up -d --wait --no-build --no-deps db; then
    die "PostgreSQL could not be started; web and queue were not replaced"
  fi

  log "waiting for Postgres inside the compose network"
  for _ in $(seq 1 30); do
    if compose exec -T db pg_isready \
      -U "$(env_get DB_USERNAME)" -d "$(env_get DB_DATABASE)" >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 2
  done
  [[ "${ok}" -eq 1 ]] || die "Postgres did not become ready; web and queue were not replaced"

  log "preflight: checking whether public.tenants exists"
  if ! tenants_table_exists="$(
    compose exec -T db psql \
      -v ON_ERROR_STOP=1 \
      -U "$(env_get DB_USERNAME)" -d "$(env_get DB_DATABASE)" \
      -tAc "${TENANTS_TABLE_EXISTS_QUERY}"
  )"; then
    die "could not determine whether public.tenants exists; web and queue were not replaced"
  fi
  tenants_table_exists="${tenants_table_exists//[[:space:]]/}"

  if [[ "${tenants_table_exists}" == "f" ]]; then
    log "preflight: public.tenants is absent; no existing tenant collision is possible"
  elif [[ "${tenants_table_exists}" == "t" ]]; then
    log "preflight: reserved central-panel slug 'consola' must not identify a tenant"
    if compose exec -T db psql \
      -v ON_ERROR_STOP=1 -P pager=off \
      -U "$(env_get DB_USERNAME)" -d "$(env_get DB_DATABASE)" <<SQL
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
${CONSOLA_PREFLIGHT_QUERY}
SELECT EXISTS (
  SELECT 1 FROM public.tenants WHERE id = 'consola'
) AS consola_collision \gset
\if :consola_collision
\quit 42
\endif
COMMIT;
SQL
    then
      preflight_status=0
    else
      preflight_status=$?
    fi

    if [[ "${preflight_status}" -eq 42 ]]; then
      die "tenant id 'consola' is reserved for the central panel. Rename that tenant through an approved data remediation, then retry; web and queue were not replaced"
    elif [[ "${preflight_status}" -ne 0 ]]; then
      die "could not query public.tenants for reserved id 'consola'; web and queue were not replaced"
    fi
  else
    die "unexpected public.tenants existence result '${tenants_table_exists:-empty}'; web and queue were not replaced"
  fi

  # The one-off uses the selected oir-flow-preview-web image without starting or
  # replacing the web service. Installing tenants_id_not_consola here closes the
  # interval in which an old serving container could create a post-query collision.
  log "running central migrations in a one-off container before cutover"
  if ! compose run --rm --no-deps web \
    php artisan migrate --force --no-interaction; then
    die "central migrations failed in the selected web image; web and queue were not replaced"
  fi

  log "starting oir-flow-preview after successful preflight migration"
  if ! compose "${up_args[@]}"; then
    die "full preview compose up failed after the preflight migration"
  fi
}

reset_preview_data() {
  log "RESET-DATA: compose down --volumes — deleting preview named volumes (db-data, redis-data); images stay"
  if ! compose down --volumes; then
    die "compose down --volumes failed; preview stack was not started"
  fi
}

boot_preview_after_images() {
  if [[ "${RESET_DATA:-0}" -eq 1 ]]; then
    reset_preview_data
  fi
  start_preview_stack "${RECREATE:-0}"
}

parse_preview_up_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build) BUILD_MODE=build ;;
      --no-build) BUILD_MODE=nobuild ;;
      --recreate) RECREATE=1 ;;
      --reset-data) RESET_DATA=1 ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "error: unknown argument: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

main() {
  parse_preview_up_args "$@"

  cd "${REPO_ROOT}"

  command -v docker >/dev/null 2>&1 || die "docker is required and was not found on PATH"
  docker compose version >/dev/null 2>&1 || die "docker compose plugin is required"

  [[ -f "${COMPOSE_FILE}" ]] || die "missing ${COMPOSE_FILE}"
  [[ -f "${ENV_FILE}" ]] || die "missing ${ENV_FILE} — copy infra/deploy/.env.example and fill secrets"

  APP_ENV_VALUE="$(env_get APP_ENV)"
  APP_URL_VALUE="$(env_get APP_URL)"
  ENGINE_KEY_VALUE="$(env_get ENGINE_KEY)"
  CONSOLE_EMAIL="$(env_get CONSOLE_ADMIN_EMAIL)"
  CONSOLE_NAME="$(env_get CONSOLE_ADMIN_NAME)"
  CONSOLE_PASSWORD="$(env_get CONSOLE_ADMIN_PASSWORD)"
  STAGING_SEED_PASSWORD_VALUE="$(env_get STAGING_SEED_PASSWORD)"

  [[ "${APP_ENV_VALUE}" != "local" ]] || die "APP_ENV=local is DDEV-only; preview .env must stay staging"
  [[ "${APP_URL_VALUE}" == https://* ]] || die "APP_URL must be https://… (preview web publishes :443 only)"

  require_secret APP_KEY
  require_secret DB_PASSWORD
  require_secret ENGINE_KEY
  require_secret CONSOLE_ADMIN_EMAIL
  require_secret CONSOLE_ADMIN_NAME
  require_secret CONSOLE_ADMIN_PASSWORD
  require_secret STAGING_SEED_PASSWORD

  if printf '%s\n' "${FORBIDDEN_ENGINE_KEYS}" | grep -Fxq "${ENGINE_KEY_VALUE}"; then
    die "ENGINE_KEY must not be the DDEV or CI stand-in (${ENGINE_KEY_VALUE})"
  fi

  [[ "${STAGING_SEED_PASSWORD_VALUE}" != "${FORBIDDEN_STAGING_SEED_PASSWORD}" ]] || \
    die "STAGING_SEED_PASSWORD must not be ${FORBIDDEN_STAGING_SEED_PASSWORD} (published DevTenantsSeeder secret)"

  log "compose config (validate against ${ENV_FILE})"
  compose config --quiet

  images_present=1
  docker image inspect "${PLATFORM_IMAGE}" >/dev/null 2>&1 || images_present=0
  docker image inspect "${ENGINE_IMAGE}" >/dev/null 2>&1 || images_present=0

  if [[ "${BUILD_MODE}" == "nobuild" && "${images_present}" -eq 0 ]]; then
    die "images missing (${PLATFORM_IMAGE} / ${ENGINE_IMAGE}); run with --build or wait for the GitLab images job"
  fi

  if [[ "${BUILD_MODE}" == "build" || "${images_present}" -eq 0 ]]; then
    log "building images (composer install --no-dev, filament:upgrade, npm run build, engine)"
    compose build engine web
    docker image inspect "${PLATFORM_IMAGE}" >/dev/null
    docker image inspect "${ENGINE_IMAGE}" >/dev/null
  else
    log "reusing images ${PLATFORM_IMAGE} · ${ENGINE_IMAGE} (--no-build)"
  fi

  boot_preview_after_images

  log "checking central migration status after full compose up"
  in_web php artisan migrate:status --no-interaction

  log "asserting public.console_users exists"
  console_users="$(
    compose exec -T db \
      psql -U "$(env_get DB_USERNAME)" -d "$(env_get DB_DATABASE)" -tAc \
      "SELECT to_regclass('public.console_users')"
  )"
  [[ "${console_users}" == "console_users" ]] || die "central migrate did not create public.console_users (got '${console_users:-empty}')"

  log "seeding the central database (DatabaseSeeder)"
  in_web php artisan db:seed --force --no-interaction

  log "migrating existing tenant schemas"
  in_web php artisan tenants:migrate --force --no-interaction

  log "seeding tenant role/permission/setting vocabulary (TenantDatabaseSeeder)"
  in_web php artisan tenants:seed --force --no-interaction

  log "provisioning staging tenants (StagingTenantsSeeder; oir-north-west / oir-south-west)"
  in_web php artisan db:seed --class=StagingTenantsSeeder --force --no-interaction

  log "asserting console operator ${CONSOLE_EMAIL}"
  in_web php artisan console:administrator "${CONSOLE_EMAIL}" \
    --name="${CONSOLE_NAME}" \
    --password="${CONSOLE_PASSWORD}" \
    --actor='cli:preview-up' \
    --no-interaction

  log "asserting no tenant is behind the codebase"
  in_web php artisan tenants:drift-check

  log "preview is up: ${APP_URL_VALUE}/consola  · Mailpit :8025  · Postgres :$(env_get DB_HOST_PORT)"
  log "engine stays unpublished (http://engine:8000 on the compose network only)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
