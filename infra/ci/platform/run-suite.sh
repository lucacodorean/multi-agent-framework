#!/usr/bin/env bash
# The in-container half of the platform gate. Runs INSIDE ddev/ddev-webserver, started by
# infra/ci/platform-suite.sh — not meant to be run on a host.
#
# Owned by platform-engineer. Everything up to "a booted application with services
# answering" is shared with the seam gate and lives in prepare-app.sh; this file is only
# what is specific to running the WHOLE Pest suite.
set -euo pipefail

# Leaves the shell in /app with vendor/ installed, Filament assets published, .env present,
# and postgres + redis answering. Reads the repository from /src READ-ONLY, so a CI run never
# writes into the tree it was given — on a laptop, the tree the developer is still editing.
source "$(dirname "${BASH_SOURCE[0]}")/prepare-app.sh"

# --fail-on-all-issues, NOT the narrower --fail-on-warning: both were measured, and
# --fail-on-warning left the run exiting 0 with 288 warnings — what Pest prints as "warnings"
# is not the issue class that flag selects. `--do-not-fail-on-skipped` is then REQUIRED, not a
# softening: --fail-on-all-issues counts a skipped test as an issue and this suite skips the
# live-engine cases by design, so without it the gate is red on a good tree. NOT --parallel:
# every worker would share one oirflow_test and purgeTenancy() drops every tenant schema in it
# (tests/Pest.php refuses --parallel outright, but the reason belongs next to the command).
# The next line asserts that PHP diagnostics can reach this gate at all — see that file.
log "checking that PHP diagnostics can reach this gate"
php infra/ci/platform/assert-diagnostics-visible.php

log "running the platform suite (Pest, exclusive — no --parallel, any issue is fatal)"
readonly EVENTS_LOG=/tmp/pest-events.txt
# Captured as well as displayed. `tee` keeps the run streaming to the CI log — a suite whose
# output only appears after it finishes is unreadable while it runs — while leaving a file the
# compile-time check can scan. 2>&1 because `artisan test` forwards the test subprocess's
# stderr onto its own stdout, so the two streams are already merged by the time we see them;
# merging explicitly means the check does not depend on which side a diagnostic arrived from.
readonly SUITE_OUTPUT=/tmp/pest-output.txt
set +e
php artisan test --fail-on-all-issues --do-not-fail-on-skipped --log-events-text "${EVENTS_LOG}" 2>&1 | tee "${SUITE_OUTPUT}"
# PIPESTATUS[0], not $?. With `set -o pipefail` in force, `$?` would be the pipeline's status
# and `tee` cannot fail informatively — the suite's own exit code is the one that means
# something, and it is the left-hand element.
readonly SUITE_STATUS=${PIPESTATUS[0]}
set -e

# Neither --fail-on-warning nor --fail-on-all-issues makes a run red when tests trigger PHP
# warnings — both were measured against a tree producing 295 of them and both exited 0. So the
# condition is asserted directly from PHPUnit's event log, a documented machine-readable
# surface, rather than from the "295 warnings" line, which is human-facing formatting Pest is
# free to restyle. Tests that do not execute as written are not a lesser kind of failure.
ISSUE_COUNT=0
if [[ -f "${EVENTS_LOG}" ]]; then
  ISSUE_COUNT="$(grep -cE 'Test Triggered (PHP )?(Warning|Notice|Deprecation)' "${EVENTS_LOG}" || true)"
fi

if ((ISSUE_COUNT > 0)); then
  echo "" >&2
  echo "error: the suite triggered ${ISSUE_COUNT} PHP warning/notice/deprecation event(s)." >&2
  echo "Tests that trigger these did not execute as written, even when they report passing" >&2
  echo "assertions. PHPUnit does not fail the run for them, so this gate does. First few:" >&2
  # `|| true` on the pipeline, not decoration: `head` closes the pipe after 8 lines, grep
  # takes SIGPIPE, and under `set -o pipefail` that made the script abort with 141 before
  # reaching the `exit 1` below — a red build reporting a signal instead of a reason.
  { grep -E -A1 'Test Triggered (PHP )?(Warning|Notice|Deprecation)' "${EVENTS_LOG}" | head -8 >&2; } || true
  exit 1
fi

# THE SECOND DOORWAY — compile-time diagnostics, which the check above cannot see. PHP emits
# them while merely LOADING a file, before and outside any test, so PHPUnit never classifies
# them as `Test Triggered ...` and the grep above counts ZERO. Measured: two files carrying a
# no-op global-namespace `use` printed a warning on every run, the event log contained neither,
# and Pint and PHPStan were both green. The scan reads the MERGED capture, because the
# diagnostics arrive on stdout and a stderr-only scan would report a clean tree. Anchored at the
# start of the line: `^PHP Warning:` is the interpreter's own prefix, and the same text appears
# mid-line in Pest's summary and could appear in a test's own output.
COMPILE_DIAGNOSTICS=0
if [[ -f "${SUITE_OUTPUT}" ]]; then
  COMPILE_DIAGNOSTICS="$(grep -cE '^PHP (Warning|Notice|Deprecated|Fatal error|Parse error|Recoverable fatal error):' "${SUITE_OUTPUT}" || true)"
fi

if ((COMPILE_DIAGNOSTICS > 0)); then
  echo "" >&2
  echo "error: PHP emitted ${COMPILE_DIAGNOSTICS} diagnostic(s) while LOADING the suite's files." >&2
  echo "These fire during file inclusion rather than inside a test, so PHPUnit never records" >&2
  echo "them as test-triggered issues and the event-log check above cannot see them at all." >&2
  echo "A file that does not even load as written is not a lesser defect than a failing test." >&2
  echo "" >&2
  # Same `|| true` as above, and for the same measured reason: `head` closing the pipe sends
  # SIGPIPE to grep, which under `set -o pipefail` aborts the script with 141 before the
  # `exit 1` — a red build reporting a signal instead of a reason.
  { grep -E '^PHP (Warning|Notice|Deprecated|Fatal error|Parse error|Recoverable fatal error):' "${SUITE_OUTPUT}" | sort -u | head -10 >&2; } || true
  exit 1
fi

if ((SUITE_STATUS != 0)); then
  echo "" >&2
  echo "error: the platform suite failed (exit ${SUITE_STATUS})." >&2
  exit "${SUITE_STATUS}"
fi

log "suite green: no triggered issues, and no diagnostics while loading the files"
