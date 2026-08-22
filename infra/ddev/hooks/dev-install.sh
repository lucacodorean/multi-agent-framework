#!/usr/bin/env bash
#
# DDEV post-start hook — leave a DEVELOPMENT install ready to log into.
#
# Wired by infra/ddev/config.hooks.yaml, run INSIDE the web container on every `ddev start`,
# and NOT copied into .ddev/: the repository is bind-mounted at /var/www/html, so the hook
# executes this very file with no generated copy to drift. In order, every step idempotent:
# composer install (if vendor/ absent) → migrate central → `tenants:migrate` → `tenants:seed`
# → `db:seed --class=DevTenantsSeeder` → `console:administrator` → `tenants:drift-check`.
#
# WHY THE ORDER IS THE FIX AND NOT AN ARRANGEMENT. Steps 2–3 act on tenants that ALREADY
# exist; step 4 provisions the ones that do not. The provisioner skips every tenant already in
# the registry, so before steps 2 and 3 existed a tenant provisioned in July never received an
# August migration — measured, with a green `ddev start` behind it: both local tenants at 17 of
# 20 migrations and `tenants:drift-check` exiting 1. Brand-new tenants need neither step, which
# is why step 4 comes after these two and not before.
#
# WHAT MAKES IT HONEST: the last step asserts something. `tenants:drift-check` closes the
# sequence and a divergence fails the start (docs/runbook.md § Environment up — DDEV
# (local)) — the check is an ACTION, not a gate.
#
# WHAT IT REFUSES TO DO. Everything below the "act" section is development fixture data
# whose secrets are published in plain sight, and it is gated to APP_ENV=local twice over —
# the seeder never runs on preview/staging and never fails the boot
# (docs/runbook.md § Environment up — DDEV (local)). Every gate fails OPEN TO DOING NOTHING.
# `console:administrator` carries no environment guard of its own — it is the recovery path
# for a locked-out console
# (docs/adr/0044-no-environment-guard-on-the-console-bootstrap-command.md) — so here it is
# the hook's two gates that keep it development-only.
#
# A failure of an *action* (composer, migrate, seed, the operator, the drift check) is a
# different thing from a closed gate and is NOT swallowed: it exits non-zero, `ddev start`
# reports the failed hook, and the containers stay up so the failure can be investigated.
set -euo pipefail

# The bind-mount point of the repository root inside the web container.
readonly PROJECT_ROOT=/var/www/html
# The ONLY application environment this hook acts in (mirrors DevTenantsSeeder::ENVIRONMENTS).
readonly DEV_ENVIRONMENT=local
# DDEV's database service is always reachable under this hostname on the project network.
readonly DB_SERVICE_HOST=db
readonly DB_READY_TIMEOUT_SECONDS=15
# Owned by data-engineer; invoked, never modified, from here.
readonly DEV_SEEDER=DevTenantsSeeder
# Exactly one development console operator, asserted on every start. The password is published
# on purpose and is the same string as DevTenantsSeeder::PASSWORD — one credential, not two.
readonly DEV_CONSOLE_EMAIL=admin@oir-flow.dev
readonly DEV_CONSOLE_NAME='Administrator OIR Flow'
readonly DEV_CONSOLE_PASSWORD=oirflow-dev
# Attribution in the lifecycle journal — who did this. Mirrors DevTenantsSeeder::ACTOR,
# which is why the default `cli:<current user>` is not good enough: "www-data" names nobody.
readonly DEV_CONSOLE_ACTOR=hook:dev-install
readonly LOG_PREFIX='dev-install:'

log() {
  echo "${LOG_PREFIX} $*"
}

# Close a gate: report the reason and end the hook successfully — a skipped dev fixture
# is a normal outcome, not a broken start.
skip() {
  log "skipped — $*"
  exit 0
}

cd "${PROJECT_ROOT}"

# --- gates -----------------------------------------------------------------------------

if [[ ! -f .env ]]; then
  skip "no .env yet — re-run 'ddev start' once DDEV has written one"
fi

# Gate 1, pre-PHP: the DECLARED environment. Readable with no vendor/ and no working
# database, so a fresh clone is judged before anything is installed. `tail -n1` because
# the last assignment is the one PHP dotenv keeps.
declared_environment=$(
  sed -n 's/^[[:space:]]*APP_ENV[[:space:]]*=[[:space:]]*"\?\([^"[:space:]]*\)"\?.*/\1/p' .env | tail -n1
)
if [[ "${declared_environment}" != "${DEV_ENVIRONMENT}" ]]; then
  skip "APP_ENV is '${declared_environment:-unset}', not '${DEV_ENVIRONMENT}'"
fi

# --- install ---------------------------------------------------------------------------

# DDEV's laravel project type writes .env and generates APP_KEY, but never installs
# dependencies; without this a fresh clone cannot run artisan at all and CLAUDE.md's
# "a fresh clone needs nothing more" would be false. Guarded on the artefact itself, so
# it costs nothing on every later start.
if [[ ! -f vendor/autoload.php ]]; then
  log "vendor/ absent — installing composer dependencies (first start after a fresh clone)"
  composer install --no-interaction --prefer-dist
fi

# Gate 2, authoritative: the environment the framework actually resolved, which may differ
# from .env (web_environment, container env, config caching). Parses the one bracketed
# value `artisan env` prints. An empty or unexpected answer closes the gate.
runtime_environment=$(php artisan env --no-ansi 2>/dev/null | sed -n 's/.*\[\(.*\)\]\..*/\1/p' | tail -n1)
if [[ "${runtime_environment}" != "${DEV_ENVIRONMENT}" ]]; then
  skip "the framework reports environment '${runtime_environment:-unknown}', not '${DEV_ENVIRONMENT}'"
fi

# Gate 3: the central database answers. DDEV starts the db service before this hook, so a
# closed gate here means a genuinely broken or still-provisioning database — worth one
# line, not a failed start.
if ! pg_isready -h "${DB_SERVICE_HOST}" -q -t "${DB_READY_TIMEOUT_SECONDS}"; then
  skip "database service '${DB_SERVICE_HOST}' did not answer within ${DB_READY_TIMEOUT_SECONDS}s"
fi

# --- act -------------------------------------------------------------------------------

# An unmigrated central database has no tenant registry to iterate, so nothing below it can
# run; a migrated one reports "Nothing to migrate".
log "migrating the central database"
php artisan migrate --force --no-interaction

# The drift fix (see the header). On an empty registry — a fresh clone, before step 4 has
# provisioned anything — stancl's runForMultiple falls back to a cursor over the tenants
# table, the loop body never executes and this prints nothing and exits 0. `--path` and
# `--realpath` come from config/tenancy.php (`migration_parameters`), which is why the
# tenant migration directory is not named here.
log "migrating existing tenant schemas"
php artisan tenants:migrate --force --no-interaction

# Same argument one level up: TenantDatabaseSeeder grants roles, permissions and settings
# and never revokes, so re-running it carries everything added since a tenant was
# provisioned into that tenant. The seeder class comes from config/tenancy.php
# (`seeder_parameters`) — naming it here would fork that decision into two files.
log "re-seeding the tenant role/permission/setting vocabulary"
php artisan tenants:seed --force --no-interaction

# Provisions any dev tenant that is missing, through the audited provisioner — which
# migrates and seeds what it creates, so a tenant born here is already current. Idempotent:
# a tenant already in the registry is reported as a skip and never touched.
log "provisioning any missing development tenant (${DEV_SEEDER})"
php artisan db:seed --class="${DEV_SEEDER}" --force --no-interaction

# The console table has exactly one writing surface — the console panel, which authenticates
# against that same table — so an empty roster locks everybody out of the page that fills
# it. This is the way in. Idempotent by address: a run that finds the account re-asserts its
# name and access, re-sets the secret because we pass one, and exits 0.
log "asserting the development console operator (${DEV_CONSOLE_EMAIL})"
php artisan console:administrator "${DEV_CONSOLE_EMAIL}" \
  --name="${DEV_CONSOLE_NAME}" \
  --password="${DEV_CONSOLE_PASSWORD}" \
  --actor="${DEV_CONSOLE_ACTOR}" \
  --no-interaction

# The closing assertion, and the only step here that can call the install wrong: it compares
# every tenant schema's applied-migration set against the codebase and against the other
# tenants. Its exit code is the product — `set -e` carries a divergence out of this script
# and into a failed `ddev start`. Do not soften this into a warning.
log "asserting no tenant is behind the codebase"
php artisan tenants:drift-check

log "development install is provisioned and current"
