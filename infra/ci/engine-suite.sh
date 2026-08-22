#!/usr/bin/env bash
# The engine's CI gate — container, in-process, and unconfigured-deployment passes.
#
#   Usage:  infra/ci/engine-suite.sh
#
# Requires Docker and NOTHING else on the host: no Python, no pytest, no pip. Three passes,
# none redundant: the suite over HTTP against a running container (the real hop, the real
# LibreOffice); the same suite in-process, because every `in_process_only` case SKIPS in mode 1
# and would otherwise never execute; and a second container started with NO ENGINE_KEY, which
# mode 1 skips and mode 2 only simulates but an operator meets for real. The image is BUILT
# from the same Dockerfile the DDEV topology uses, so CI exercises the developer's image.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

# Distinct from the DDEV image (`ddev-<project>-engine:latest`, auto-named by Compose since
# the topology's engine service declares no `image:` key) so a CI run on a developer's
# machine can never overwrite the image their project is running.
readonly ENGINE_IMAGE=oir-flow-engine-ci:latest
readonly TEST_IMAGE=oir-flow-engine-ci-test:latest
readonly NETWORK=oir-flow-ci-engine-net
readonly ENGINE_CONTAINER=oir-flow-ci-engine
readonly UNCONFIGURED_CONTAINER=oir-flow-ci-engine-unconfigured
# The engine is addressed by this alias on the CI network, so the URL is stable
# regardless of container naming.
readonly ENGINE_HOST=engine
readonly ENGINE_URL="http://${ENGINE_HOST}:8000"

# CI-only, not a secret, and never a default anywhere else: this value exists so the
# guarded operations have something to match against during the run.
readonly CI_ENGINE_KEY=ci-only-insecure-engine-key

# The health timeout and interval now live with the wait itself, in infra/ci/engine/container.sh
# (defaults 90s / 3s, overridable per call). Kept in one place so the two gates that start an
# engine cannot disagree about how long "not up yet" is allowed to last.

log() {
  echo "==> $*"
}

# One engine-gate run at a time on this machine. Two containers and a network on constant
# names: a second concurrent run's cleanup would delete this run's engine mid-suite, and the
# victim reports connection failures against a tree that is fine. Measured collision, and the
# rejected alternative (per-run unique names): infra/ci/lock.sh.
source "$(dirname "${BASH_SOURCE[0]}")/lock.sh"
ci_take_gate_lock engine

cleanup() {
  # Best-effort and silent: a failed run must still leave the machine clean, and a
  # cleanup error must never mask the failure that is being reported.
  docker rm -f "${ENGINE_CONTAINER}" "${UNCONFIGURED_CONTAINER}" >/dev/null 2>&1 || true
  docker network rm "${NETWORK}" >/dev/null 2>&1 || true
}
# REGISTERED AFTER THE LOCK IS HELD, and the order is load-bearing: a process still waiting on
# the lock owns no containers, so a trap installed before acquisition would — if that waiter
# were interrupted — delete the containers of the run it is waiting for. See lock.sh.
trap cleanup EXIT

# ci_start_engine / ci_wait_for_engine_health — shared with infra/ci/seam-suite.sh rather than
# defined twice. Both encode facts that must not drift between the two gates that start an
# engine: the liveness route is unauthenticated by contract, and it is asked from inside the
# container so no published port is needed.
source "$(dirname "${BASH_SOURCE[0]}")/engine/container.sh"

# Run pytest in the test image. The suite is bind-mounted read-only exactly as the dev
# topology mounts it, so `-p no:cacheprovider` is required: pytest would otherwise try to
# write .pytest_cache into a read-only mount.
run_suite() {
  docker run --rm \
    --network "${NETWORK}" \
    --volume "${REPO_ROOT}/engine:/app/engine:ro" \
    --volume "${REPO_ROOT}/contract:/app/contract:ro" \
    "$@" \
    "${TEST_IMAGE}" \
    python -m pytest -q -p no:cacheprovider
}

cd "${REPO_ROOT}"

log "building the engine image (the shared engine Dockerfile; LibreOffice, ~47s cold)"
docker build --tag "${ENGINE_IMAGE}" --file infra/shared/engine/Dockerfile infra/shared/engine

log "building the CI test image (engine image + pytest)"
docker build \
  --tag "${TEST_IMAGE}" \
  --build-arg "BASE_IMAGE=${ENGINE_IMAGE}" \
  --file infra/ci/engine/Dockerfile.test \
  infra/ci/engine

log "creating the CI network"
docker network create "${NETWORK}" >/dev/null

log "starting the engine (configured: ENGINE_KEY set)"
ci_start_engine "${ENGINE_CONTAINER}" "${NETWORK}" "${ENGINE_HOST}" "${ENGINE_IMAGE}" "${REPO_ROOT}" --env "ENGINE_KEY=${CI_ENGINE_KEY}"
ci_wait_for_engine_health "${ENGINE_CONTAINER}"

log "PASS 1/3 — black-box suite over HTTP against the running container"
run_suite --env "ENGINE_BASE_URL=${ENGINE_URL}" --env "ENGINE_KEY=${CI_ENGINE_KEY}"

log "PASS 2/3 — the same suite in-process (executes the cases pass 1 skips)"
run_suite

log "PASS 3/3 — an engine started with NO ENGINE_KEY: unservable, but alive"
# No --env ENGINE_KEY at all — modelling an operator who never set it. Measured: `--env
# ENGINE_KEY=` behaves identically, so this is precision, not a dependency.
ci_start_engine "${UNCONFIGURED_CONTAINER}" "${NETWORK}" unconfigured-engine "${ENGINE_IMAGE}" "${REPO_ROOT}"
ci_wait_for_engine_health "${UNCONFIGURED_CONTAINER}"
docker run --rm \
  --network "${NETWORK}" \
  --volume "${REPO_ROOT}/infra/ci/engine:/probe:ro" \
  "${TEST_IMAGE}" \
  python /probe/unconfigured_probe.py http://unconfigured-engine:8000

log "engine gate: all three passes green"
