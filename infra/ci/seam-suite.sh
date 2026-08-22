#!/usr/bin/env bash
# The seam gate — the platform's engine client against a REAL engine, over a real network hop.
#
#   Usage:  infra/ci/seam-suite.sh
#
# Requires Docker and NOTHING else on the host: no PHP, no composer, no Python. Same rule as
# every other gate here (infra/README.md → Host-agnostic tooling).
#
# ---------------------------------------------------------------------------------------
# WHY THIS EXISTS. `contract/engine.openapi.yaml` is the only coupling point between the two
# contexts, and the tier model rests on the claim that conformance verified on each side
# separately is sufficient for them to interoperate. This gate is what tests that claim:
# docs/architecture.md § CI — gates. Ruled a CONTRACT-TIER requirement, so the coverage is
# not platform's to trade for build time — docs/conventions/orchestration.md § Tiers and
# direction.
#
# WHY TWO ENGINE CONTAINERS. 401 and 503 cannot come from one deployment: 401 means a secret
# was presented and refused, 503 shared-secret-absent means the engine was started without
# one (docs/architecture.md § Contract boundary). So a second, deliberately unconfigured
# engine runs alongside the first, addressed by ENGINE_UNCONFIGURED_URL.
#
# ---------------------------------------------------------------------------------------
# WHAT MAKES THIS RED (docs/conventions/orchestration.md → "green by absence"):
#   1. Any seam case failing — including the client failing to parse what the engine really
#      sends, which no amount of hermetic testing on either side can catch.
#   2. ANY seam case SKIPPING. This is the one that matters most: the cases skip unless
#      ENGINE_LIVE_SMOKE=1, so without the assertion in infra/ci/seam/assert-seam-executed.php
#      this gate would report success having exercised the seam ZERO times. Asserted twice —
#      the variable is checked before the run, and the executed count after it.
#   3. The `live-engine` group matching no tests at all (renamed, moved, deleted).
#   4. Fewer seam cases executing than the recorded floor — coverage shrinking silently. Note
#      that a case which DISAPPEARS leaves no skip to report, so (2) cannot see it and only
#      the floor can; the two checks look similar and cover different failures.
#   5. Either engine image failing to build, or either engine never answering /health.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

# Pinned exactly, and to the SAME versions the other gates and the topology use. If the Redis
# tag here and the one in .ddev/.env.redis ever diverge, CI and development stop testing the
# same thing.
readonly RUNNER_IMAGE=ddev/ddev-webserver:v1.25.3
readonly POSTGRES_IMAGE=postgres:16
readonly REDIS_IMAGE=redis:7.4.10-bookworm

# Built, never pulled, from the same Dockerfile the DDEV topology uses — so the gate exercises
# the developer's engine rather than a CI-only lookalike. Tagged distinctly from both the DDEV
# project's image and the engine gate's, so running this on a developer's machine cannot
# overwrite either.
readonly ENGINE_IMAGE=oir-flow-seam-ci-engine:latest

readonly NETWORK=oir-flow-ci-seam-net
readonly DB_CONTAINER=oir-flow-ci-seam-db
readonly REDIS_CONTAINER=oir-flow-ci-seam-redis
readonly ENGINE_CONTAINER=oir-flow-ci-seam-engine
readonly UNCONFIGURED_CONTAINER=oir-flow-ci-seam-engine-unconfigured

# Aliases are NOT cosmetic: phpunit.xml hard-codes DB_HOST=db, the application reads
# REDIS_HOST, and the two engine URLs below address their containers by name.
readonly DB_ALIAS=db
readonly REDIS_ALIAS=redis
readonly ENGINE_ALIAS=engine
readonly ENGINE_URL="http://${ENGINE_ALIAS}:8000"

# THE SECOND ENGINE. A deployment that HAS a shared secret answers 401 to a wrong key; one that
# has NONE answers 503 to every key alike. The distinction cannot be produced by varying what
# the CLIENT sends, only by how the ENGINE was started — so the pair needs two containers.
readonly UNCONFIGURED_ALIAS=unconfigured-engine
readonly UNCONFIGURED_URL="http://${UNCONFIGURED_ALIAS}:8000"

readonly DB_USER=db
readonly DB_PASSWORD=db

# CI-only, not secrets, and never defaults anywhere else.
readonly CI_ENGINE_KEY=ci-only-insecure-engine-key
# MUST decode to exactly 32 bytes — AES-256-CBC. A shorter key does not fail at boot; it fails
# inside every test that touches a session, as "Unsupported cipher or incorrect key length".
# The plaintext is 32 ASCII characters so the length is verifiable by reading:
#   ci-only-insecure-app-key-1234567
readonly CI_APP_KEY=base64:Y2ktb25seS1pbnNlY3VyZS1hcHAta2V5LTEyMzQ1Njc=

log() {
  echo "==> $*"
}

# ci_start_engine / ci_wait_for_engine_health — shared with infra/ci/engine-suite.sh rather
# than reimplemented. The health wait encodes both a contract fact (GET /health is
# unauthenticated so a probe can call it before any credential exists) and a container fact
# (asked from inside, so no published port is needed); a second copy would drift.
source "$(dirname "${BASH_SOURCE[0]}")/engine/container.sh"

# One seam run at a time on this machine — four containers on shared, constant names, so two
# concurrent runs destroy each other rather than merely racing. Rationale, the measured
# collision that prompted it, and the rejected alternative: infra/ci/lock.sh.
source "$(dirname "${BASH_SOURCE[0]}")/lock.sh"
ci_take_gate_lock seam

# The persistent composer download cache, shared with the platform gate — both install the
# same composer.lock, so either gate warms the other. Why a named volume, why download
# parallelism is capped, and why a cache cannot mask a dependency change:
# infra/ci/composer-cache.sh.
source "$(dirname "${BASH_SOURCE[0]}")/composer-cache.sh"
ci_ensure_composer_cache

cleanup() {
  # Best-effort and silent: a failed run must still leave the machine clean, and a cleanup
  # error must never mask the failure being reported.
  docker rm -f "${DB_CONTAINER}" "${REDIS_CONTAINER}" "${ENGINE_CONTAINER}" \
    "${UNCONFIGURED_CONTAINER}" >/dev/null 2>&1 || true
  docker network rm "${NETWORK}" >/dev/null 2>&1 || true
}
# REGISTERED AFTER THE LOCK IS HELD, and the order is load-bearing rather than stylistic. A
# process still waiting on `flock` owns no containers; if it carried this trap and were
# interrupted — Ctrl-C, a killed agent — its cleanup would delete the containers of the run it
# is politely waiting for. The trap must not exist until the resources it destroys are ours.
trap cleanup EXIT

# Also up front, so a previous crashed run cannot poison this one. Safe only because the lock
# above guarantees any run whose containers these might be is already finished.
cleanup

cd "${REPO_ROOT}"

readonly CI_APP_KEY_BYTES="$(printf '%s' "${CI_APP_KEY#base64:}" | base64 -d 2>/dev/null | wc -c)"
if [[ "${CI_APP_KEY_BYTES}" != "32" ]]; then
  echo "error: CI_APP_KEY decodes to ${CI_APP_KEY_BYTES} bytes, but AES-256-CBC requires exactly 32." >&2
  exit 1
fi

log "building the engine image (the shared engine Dockerfile; LibreOffice, ~47s cold)"
docker build --tag "${ENGINE_IMAGE}" --file infra/shared/engine/Dockerfile infra/shared/engine

log "creating the CI network"
docker network create "${NETWORK}" >/dev/null

log "starting postgres (${POSTGRES_IMAGE}) as '${DB_ALIAS}'"
# Needed even though no seam case touches the database: tests/Pest.php's bootstrap creates
# oirflow_test and takes the suite advisory lock before ANY test runs, seam group included.
docker run --detach \
  --name "${DB_CONTAINER}" \
  --network "${NETWORK}" \
  --network-alias "${DB_ALIAS}" \
  --env "POSTGRES_USER=${DB_USER}" \
  --env "POSTGRES_PASSWORD=${DB_PASSWORD}" \
  --env "POSTGRES_DB=${DB_USER}" \
  --tmpfs /var/lib/postgresql/data:rw \
  "${POSTGRES_IMAGE}" >/dev/null

log "starting redis (${REDIS_IMAGE}) as '${REDIS_ALIAS}', using the platform's own redis.conf"
docker run --detach \
  --name "${REDIS_CONTAINER}" \
  --network "${NETWORK}" \
  --network-alias "${REDIS_ALIAS}" \
  --volume "${REPO_ROOT}/infra/shared/redis:/etc/redis/conf:ro" \
  "${REDIS_IMAGE}" \
  /etc/redis/conf/redis.conf >/dev/null

log "starting the engine as '${ENGINE_ALIAS}' (configured: ENGINE_KEY set)"
ci_start_engine "${ENGINE_CONTAINER}" "${NETWORK}" "${ENGINE_ALIAS}" "${ENGINE_IMAGE}" "${REPO_ROOT}" \
  --env "ENGINE_KEY=${CI_ENGINE_KEY}"

log "waiting for the engine to answer /health"
ci_wait_for_engine_health "${ENGINE_CONTAINER}"

log "starting a SECOND engine as '${UNCONFIGURED_ALIAS}' (unconfigured: no ENGINE_KEY at all)"
# No --env ENGINE_KEY at all — modelling an operator who never set it. Measured: `--env
# ENGINE_KEY=` produces the identical 503 and `degraded` health, since the engine draws no
# distinction between unset and empty. Untidy, not broken.
ci_start_engine "${UNCONFIGURED_CONTAINER}" "${NETWORK}" "${UNCONFIGURED_ALIAS}" "${ENGINE_IMAGE}" "${REPO_ROOT}"

# Waiting on /health here is not a formality: an engine with no shared secret is unservable
# but ALIVE, so the one route that answers without a credential is the only way to know this
# container is ready (docs/architecture.md § Contract boundary). If /health needed a key, an
# unconfigured engine could never be waited on at all.
log "waiting for the unconfigured engine to answer /health (unauthenticated by contract)"
ci_wait_for_engine_health "${UNCONFIGURED_CONTAINER}"

log "running the seam group in ${RUNNER_IMAGE}"
# The repository goes in READ-ONLY; run-seam.sh copies it to a writable /app inside the
# container, so nothing reaches the caller's working tree.
# --entrypoint bash: this image's entrypoint expects to be orchestrated by DDEV.
log "composer cache: volume ${CI_COMPOSER_CACHE_VOLUME} at ${CI_COMPOSER_CACHE_DIR} (max ${CI_COMPOSER_MAX_PARALLEL_HTTP} parallel downloads)"

# Unquoted on purpose — see ci_composer_cache_docker_args: it emits fixed literals, so word
# splitting is what turns them into separate docker arguments.
# shellcheck disable=SC2046
docker run --rm \
  --network "${NETWORK}" \
  --volume "${REPO_ROOT}:/src:ro" \
  $(ci_composer_cache_docker_args) \
  --env "APP_KEY=${CI_APP_KEY}" \
  --env "REDIS_HOST=${REDIS_ALIAS}" \
  --env "REDIS_PORT=6379" \
  --env "COMPOSER_ALLOW_SUPERUSER=1" \
  --env "ENGINE_LIVE_SMOKE=1" \
  --env "ENGINE_URL=${ENGINE_URL}" \
  --env "ENGINE_KEY=${CI_ENGINE_KEY}" \
  --env "ENGINE_UNCONFIGURED_URL=${UNCONFIGURED_URL}" \
  --entrypoint bash \
  "${RUNNER_IMAGE}" \
  /src/infra/ci/seam/run-seam.sh

log "seam gate: green"
