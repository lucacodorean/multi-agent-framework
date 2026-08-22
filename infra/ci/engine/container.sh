#!/usr/bin/env bash
# Starting an engine container, and knowing when it is really up. SOURCED, never executed.
#
#   source "<repo>/infra/ci/engine/container.sh"
#
# Shared by infra/ci/engine-suite.sh and infra/ci/seam-suite.sh. The health wait encodes two
# facts and so must not exist twice: GET /health is unauthenticated precisely so a probe can
# call it before any credential exists, and it is asked from INSIDE the container, so it works
# before any port is published. A drifted copy tests a container that was never ready.

# Start an engine container on a network.
#
#   ci_start_engine <container-name> <network> <network-alias> <image> <repo-root> [docker args…]
#
# Trailing arguments go to `docker run` — how the unconfigured variant omits ENGINE_KEY. engine/
# is bind-mounted read-only exactly as the DDEV topology mounts it: the image carries the
# runtime, the application source comes from the tree under test.
ci_start_engine() {
  local name="$1" network="$2" alias="$3" image="$4" repo_root="$5"
  shift 5

  docker run --detach \
    --name "${name}" \
    --network "${network}" \
    --network-alias "${alias}" \
    --volume "${repo_root}/engine:/app/engine:ro" \
    "$@" \
    "${image}" >/dev/null
}

# Block until an engine container answers its own liveness route.
#
#   ci_wait_for_engine_health <container-name> [timeout-seconds] [interval-seconds]
#
# Asked from inside the container over 127.0.0.1: no published port is required, the caller
# need not be on the engine's network, and no credential is involved. On timeout the
# container's logs go to stderr — a health timeout with no logs is a support ticket, not a
# diagnosis.
ci_wait_for_engine_health() {
  local name="$1" timeout="${2:-90}" interval="${3:-3}" waited=0

  while ! docker exec "${name}" python -c \
    "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3).read()" \
    >/dev/null 2>&1; do
    if ((waited >= timeout)); then
      echo "error: ${name} did not answer /health within ${timeout}s" >&2
      docker logs "${name}" >&2 || true
      return 1
    fi
    sleep "${interval}"
    waited=$((waited + interval))
  done

  echo "==> ${name} is answering /health after ${waited}s"
}
