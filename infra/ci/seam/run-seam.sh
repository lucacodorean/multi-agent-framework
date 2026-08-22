#!/usr/bin/env bash
# The in-container half of the seam gate. Runs INSIDE ddev/ddev-webserver, started by
# infra/ci/seam-suite.sh — not meant to be run on a host.
#
# Owned by platform-engineer. Everything up to "a booted application with services answering"
# is shared with the platform gate (infra/ci/platform/prepare-app.sh); this file is only what
# is specific to running the platform→engine seam group against a LIVE engine container.
set -euo pipefail

# Environment checks FIRST, before the composer install in prepare-app.sh: none of them need
# vendor/, and a run that cannot be valid should say so in a second. ENGINE_LIVE_SMOKE is the
# one input whose absence produces a GREEN wrong answer — without it every seam case skips and
# the suite still reports OK — so it is checked twice, here and after the run from the JUnit
# report: this layer catches it never being passed, the other catches it never arriving.
if [[ "${ENGINE_LIVE_SMOKE:-}" != "1" ]]; then
  echo "error: ENGINE_LIVE_SMOKE is '${ENGINE_LIVE_SMOKE:-<unset>}', expected '1'." >&2
  echo "Every case in tests/Feature/Engine/LiveEngineSmokeTest.php skips without it, so this" >&2
  echo "gate would pass having exercised the seam zero times. Set by infra/ci/seam-suite.sh." >&2
  exit 1
fi

# ENGINE_URL and ENGINE_KEY are read by the seam cases from the environment directly
# (docs/adr/0048-engine-connection-comes-from-the-environment.md), so their absence is a
# configuration error, not a test failure. Checked for the same reason: a missing base URL
# would surface as a connection error attributed to the engine rather than to this script.
#
# ENGINE_UNCONFIGURED_URL belongs in the same list even though its absence is ALREADY caught
# after the run — the 503 case skips without it, and any skip fails the JUnit assertion. It is
# checked here anyway because the two failures cost differently: this one reports immediately,
# the other only after the working-copy build and a full test run. Same defect, same verdict,
# later feedback.
for variable in ENGINE_URL ENGINE_KEY ENGINE_UNCONFIGURED_URL; do
  if [[ -z "${!variable:-}" ]]; then
    echo "error: ${variable} is empty or unset — the seam cases read it from the environment." >&2
    exit 1
  fi
done

source "$(dirname "${BASH_SOURCE[0]}")/../platform/prepare-app.sh"

# `:-` rather than a bare expansion: with the pre-check deleted, `set -u` killed the script on
# this log line, three lines before the assertion that would have diagnosed the run.
log "seam targets: ${ENGINE_URL} (configured) and ${ENGINE_UNCONFIGURED_URL:-<not provided>} (no shared secret)"

# --group=live-engine SELECTS the seam cases; it does not stop them skipping, which is exactly
# why the assertion below exists rather than a reading of the summary line.
#
# No --fail-on-all-issues here: the JUnit assertion that follows covers failures and errors,
# and this group is a handful of cases rather than the whole suite. The report is what the
# gate actually judges.
readonly JUNIT_REPORT=/tmp/seam-junit.xml
log "running the seam group against the live engine"
set +e
php artisan test --group=live-engine --log-junit "${JUNIT_REPORT}"
readonly SEAM_STATUS=$?
set -e

# Reported explicitly, because it is the number the whole gate distrusts: `artisan test`
# exits 0 when every selected case SKIPS (a skip is not a failure), so this line and the
# assertion below routinely disagree — and when they do, the assertion is right.
log "seam group exit status: ${SEAM_STATUS} (0 here does NOT mean the seam ran — see next check)"

# Runs even when the suite reported failure: the execution count is diagnostic in both
# directions, and "0 executed" explains a green far better than a red explains itself.
log "verifying the seam cases actually executed"
php infra/ci/seam/assert-seam-executed.php "${JUNIT_REPORT}"

if ((SEAM_STATUS != 0)); then
  echo "" >&2
  echo "error: the seam group failed (exit ${SEAM_STATUS})." >&2
  exit "${SEAM_STATUS}"
fi

log "seam gate: the platform's engine client and a real engine interoperate"
