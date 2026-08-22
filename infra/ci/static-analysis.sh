#!/usr/bin/env bash
# The repository's static-analysis gate — Laravel Pint (style) and PHPStan/Larastan (types)
# over the PHP sources of every tier.
#
#   Usage:  infra/ci/static-analysis.sh
#
# Requires Docker and NOTHING else on the host: no PHP, no composer. Same rule as every other
# gate here (infra/README.md → Host-agnostic tooling).
#
# ---------------------------------------------------------------------------------------
# WHY THIS EXISTS. Pint and PHPStan are recorded conventions of this project
# (docs/conventions/engineering-principles.md § Enforced by a gate) and, until this gate,
# neither ran anywhere — a convention nothing enforces is red in someone's terminal and
# green in every build. Dropping either instead was not the platform tier's call to make:
# docs/conventions/orchestration.md § Tiers and direction.
#
# ---------------------------------------------------------------------------------------
# WHY ITS OWN GATE rather than a step inside the platform gate — ATTRIBUTION. It reads the
# sources of four tiers, so a domain or data finding must not turn the PLATFORM tier's gate
# red. The gate set: docs/architecture.md § CI — gates.
#
# ---------------------------------------------------------------------------------------
# WHAT MAKES THIS RED (ask this of every gate — if the answer is "nothing", the gate is
# decorative; docs/conventions/orchestration.md rule 4):
#   1. Any Pint finding, anywhere in the analysed tree — `--test` reports, never rewrites.
#   2. Any PHPStan error at the level phpstan.neon pins (5 today).
#   3. Either tool missing from the working copy — asserted in run-analysis.sh, because a
#      linter that is not installed reports no findings and would otherwise read as clean.
#   4. The working copy producing no composer.json — a source directory that is not a git
#      checkout copies nothing, and an empty tree lints clean.
#
# This script never pushes, tags, or deploys.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

# The same runner image the platform and seam gates use, pinned identically. If these tags
# ever diverge, the tools analysing the code and the suite running it stop agreeing about
# which PHP they are on.
readonly RUNNER_IMAGE=ddev/ddev-webserver:v1.25.3

log() {
  echo "==> $*"
}

cd "${REPO_ROOT}"

# NO LOCK: only the three container-owning gates serialize on a machine (docs/runbook.md
# § CI gates). This one is a single synchronous `docker run --rm` with the repository
# mounted READ-ONLY, which is also what keeps it safe to run while another member works.
log "running Pint and PHPStan in ${RUNNER_IMAGE}"
# --entrypoint bash: this image's entrypoint expects to be orchestrated by DDEV.
docker run --rm \
  --volume "${REPO_ROOT}:/src:ro" \
  --env "COMPOSER_ALLOW_SUPERUSER=1" \
  --entrypoint bash \
  "${RUNNER_IMAGE}" \
  /src/infra/ci/static-analysis/run-analysis.sh

log "static-analysis gate: green"
