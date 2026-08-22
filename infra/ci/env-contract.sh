#!/usr/bin/env bash
# The env contract's CI gate — root `.env.example` → infra/deploy/.env.example → the
# `x-platform-environment` anchor in infra/deploy/compose.yaml.
#
#   Usage:  infra/ci/env-contract.sh
#
# Needs only bash, git and coreutils on the host — see "WHY NO CONTAINER" below.
#
# WHY THIS EXISTS. The env contract's other enforcer, infra/hooks/sync-preview-env.sh, runs as
# a CaptainHook pre-commit action and enforces LOCALLY ONLY: `--no-verify` bypasses it and a
# clone where nobody ran `captainhook install` has no hook at all. CI could not run the same
# check because the hook's input is root `.env`, which is gitignored. Root `.env.example` IS
# TRACKED and carries the same key set, so the gate asserts it is tracked and compares that.
#
# ---------------------------------------------------------------------------------------
# NO SECOND COPY OF THE RULES — the one design constraint. The key diff, the exclusion
# lists and the secret classification live once, in infra/hooks/sync-preview-env.sh, which
# this gate calls in `--check` mode: infra/README.md § infra/hooks/ — the env contract.
#
# WHAT MAKES THIS RED:
#   1. A2 — an upstream key, minus EXCLUDED_KEYS, that the preview file or the anchor lacks.
#   2. A3 — the same read backwards, and NOT redundant: the forward direction is satisfied
#      trivially by an upstream file that LOST a key, and a forward-only version of this gate
#      was measured green against the very drift that motivated it.
#   3. B — a key the anchor does not declare; the anchor is what reaches web and queue.
#   4. Root `.env.example` untracked, absent or empty — a vacuous comparison, not a pass.
#   5. infra/hooks/sync-preview-env.sh missing — the gate must not degrade into a no-op.
#
# ---------------------------------------------------------------------------------------
# WHY NO CONTAINER: the host rule binds TOOLS, and this gate invokes none — its whole
# vocabulary is grep, awk and git over tracked text (docs/architecture.md § CI — gates).
#
# NO LOCK, and no `resource_group` in the GitLab wrapper: only the three container-owning
# gates serialize on a machine (docs/runbook.md § CI gates, docs/ci/gitlab.md § Wiring).
# This gate owns no Docker resource at all.
#
# READ-ONLY IS ENFORCED, not asserted: the engine is invoked in `--check` mode, which
# modifies nothing and stages nothing. That is what makes this safe to run on a laptop while
# another member is editing the tree.
#
# This script never pushes, tags, or deploys.
set -euo pipefail

# Declared and assigned SEPARATELY — the idiom every gate entrypoint here uses. `readonly
# VAR="$(cmd)"` masks the substitution's exit status with readonly's own, so a failing `cd`
# would go unnoticed under `set -e` and leave REPO_ROOT empty. (shellcheck SC2155.)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

# The tracked stand-in for the volatile root `.env`. Changing this means changing what the
# gate believes upstream is — do it in the engine's header too.
readonly SOURCE_FILE=.env.example

# The single enforcement engine. The hook calls it in sync mode; this gate calls the same
# file in check mode. There is deliberately no second implementation.
readonly ENGINE=infra/hooks/sync-preview-env.sh

log() {
  echo "==> $*"
}

cd "${REPO_ROOT}"

if [[ ! -f "${ENGINE}" ]]; then
  echo "error: ${ENGINE} is missing — the gate has no engine to call and would check nothing" >&2
  exit 1
fi

# The premise of the whole gate: the input must be COMMITTED. An untracked (or deleted)
# template would still be readable in a developer's working tree and absent on the runner,
# which is precisely the green-by-absence this gate was built to remove.
if ! git ls-files --error-unmatch -- "${SOURCE_FILE}" >/dev/null 2>&1; then
  echo "error: ${SOURCE_FILE} is not tracked by git — CI would have nothing to compare" >&2
  echo "The gate reads the TRACKED template because root .env is gitignored." >&2
  exit 1
fi

log "checking the env contract from ${SOURCE_FILE} (read-only)"
log "engine: ${ENGINE} --check --source ${SOURCE_FILE}"

set +e
bash "${ENGINE}" --check --source "${SOURCE_FILE}"
readonly CHECK_STATUS=$?
set -e

if ((CHECK_STATUS != 0)); then
  echo "" >&2
  echo "env-contract gate FAILED (exit ${CHECK_STATUS}) — see the labelled section(s) above." >&2
  echo "Reproduce locally, identically and without side effects:" >&2
  echo "  infra/ci/env-contract.sh" >&2
  echo "Then propagate with the same engine the pre-commit hook uses:" >&2
  echo "  ${ENGINE}" >&2
  exit "${CHECK_STATUS}"
fi

log "env-contract gate: green"
