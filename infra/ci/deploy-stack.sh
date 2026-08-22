#!/usr/bin/env bash
# The preview deploy-stack CI gate — config + image build for infra/deploy/, no `up`.
#
#   Usage:  infra/ci/deploy-stack.sh
#
# Requires Docker and the Compose plugin, nothing else on the host — and no registry token.
# GitLab's `build` job calls this with no arguments, so the default mode is the only one that
# may ship. It proves compose.yaml interpolates cleanly against infra/deploy/.env.example and
# that BOTH preview images build; building only one and calling it green would be this script's
# purest green by absence. It does NOT run `up`, push, or touch the preview project's
# lifecycle — the skipped `up` is NAMED on stdout so it cannot read as a pass.
#
# ---------------------------------------------------------------------------------------
# WHAT MAKES THIS RED (ask this of every gate — if the answer is "nothing", the gate is
# decorative; docs/conventions/orchestration.md → "green by absence"):
#
#   1. `docker compose … config` non-zero (invalid compose, unresolvable interpolation).
#   2. Either image build fails (engine or platform/web).
#   3. Either build is SKIPPED or leaves no image — post-build `docker image inspect`
#      must find both `oir-flow-preview-engine` and `oir-flow-preview-web` (Compose
#      names build products `<project>-<service>` when services declare no `image:`).
#   4. Missing contract files (compose.yaml, .env.example, either Dockerfile) — the
#      gate would otherwise report a cheerful "built nothing".
#
# Deliberately NOT red: absence of a running stack. This gate never starts containers.
# ---------------------------------------------------------------------------------------
# NO LOCK: only the three container-owning gates serialize on a machine (docs/runbook.md
# § CI gates). `compose config` and `compose build` create no named project container.
# ---------------------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

readonly COMPOSE_FILE="${REPO_ROOT}/infra/deploy/compose.yaml"
readonly ENV_FILE="${REPO_ROOT}/infra/deploy/.env.example"
readonly ENGINE_DOCKERFILE="${REPO_ROOT}/infra/deploy/engine/Dockerfile"
readonly PLATFORM_DOCKERFILE="${REPO_ROOT}/infra/deploy/platform/Dockerfile"
readonly DEPLOY_UP_TEST="${REPO_ROOT}/infra/ci/deploy-up-preflight.sh"

# Compose `name: oir-flow-preview` + explicit local `image:` keys (pull_policy: never).
# web and queue share PLATFORM_IMAGE; building `web` is enough for both.
readonly ENGINE_IMAGE=oir-flow-preview-engine
readonly PLATFORM_IMAGE=oir-flow-preview-web

# Compose services that produce the two preview images. `queue` shares
# oir-flow-preview-web with `web`; do not add `queue` here.
readonly BUILD_SERVICES=(engine web)

log() {
  echo "==> $*"
}

compose() {
  # Paths quoted; invoke from REPO_ROOT. Do NOT pass --project-directory at the repo
  # root — compose.yaml resolves build context as ../.. from its own directory
  # (infra/deploy/). Compose defaults project-directory to the compose file's dir.
  docker compose \
    -f "${COMPOSE_FILE}" \
    --env-file "${ENV_FILE}" \
    "$@"
}

cd "${REPO_ROOT}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required and was not found on PATH" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "error: docker compose plugin is required (docker compose version failed)" >&2
  exit 1
fi

for path in "${COMPOSE_FILE}" "${ENV_FILE}" "${ENGINE_DOCKERFILE}" "${PLATFORM_DOCKERFILE}" "${DEPLOY_UP_TEST}"; do
  if [[ ! -f "${path}" ]]; then
    echo "error: required deploy artifact missing: ${path}" >&2
    exit 1
  fi
done

log "testing preview cutover preflight sequencing (mocked Docker; no runtime mutation)"
bash "${DEPLOY_UP_TEST}"

log "compose config (validate infra/deploy/compose.yaml against .env.example)"
compose config --quiet

log "building preview images: ${BUILD_SERVICES[*]}"
# Explicit service list — a bare `compose build` that somehow built zero local
# Dockerfiles must not count as green. --pull is left default so base layers can
# refresh; we never push and never start the project.
compose build "${BUILD_SERVICES[@]}"

log "asserting both images exist (fail if a build was skipped)"
docker image inspect "${ENGINE_IMAGE}" >/dev/null
docker image inspect "${PLATFORM_IMAGE}" >/dev/null
log "images present: ${ENGINE_IMAGE} · ${PLATFORM_IMAGE}"

# NAMED skip — a silent skip of `up` is a task failure (green by absence).
# Do not replace this with a comment-only omission; GitLab and operators read stdout.
echo "SKIP: compose up (not this cut; T7 deferred)"

log "deploy-stack gate: green (config + build only; no up, no push, no project lifecycle)"
