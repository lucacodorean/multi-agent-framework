#!/usr/bin/env bash
#
# DDEV web_extra_daemon — the DEVELOPMENT queue worker (T19, decided 2026-07-29).
#
# Wired by infra/ddev/config.daemons.yaml (copied to .ddev/config.daemons.yaml by
# infra/ddev/bootstrap.sh) and supervised inside the web container for as long as the
# project runs. Like infra/ddev/hooks/dev-install.sh this file is NOT copied into .ddev/:
# the repository root is bind-mounted at /var/www/html, so the daemon executes this very
# file and there is no generated copy that can drift from the source of truth.
#
# WHY A WORKER EXISTS AT ALL. Two decided behaviours depend on queued work — the tenant
# first-login setup link is mailed from a queued job, and `convertPdf` is queued-only — and
# with no worker both produce nothing and report no error. Measured: a mail dispatched to the
# queue left Mailpit's inbox unchanged until one `queue:work --once` pass delivered it.
#
# WHY `queue:listen` AND NOT `queue:work`: infra/README.md § The restart cycle —
# `queue:work` holds the application in memory and keeps running old code after an edit.
# `queue:listen` boots a fresh framework per job, which is invisible at development
# volumes. Production is the opposite trade; this daemon is development-only, with exactly
# the standing of `bind_all_interfaces` (infra/README.md § The bind-all-interfaces
# decision).
#
# NOT GATED on APP_ENV, deliberately, unlike dev-install.sh: that script CREATES fixture
# data and must prove where it is before acting. This one only performs work the
# application itself already enqueued, so there is nothing here to keep out of any
# environment — and the daemon only exists inside the DDEV topology to begin with.
set -euo pipefail

# The bind-mount point of the repository root inside the web container.
readonly PROJECT_ROOT=/var/www/html
# Per-job wall clock. MUST stay above the engine's PDF budget: config/engine.php pins
# `convertPdf` to a 300s HTTP budget with `params.timeout` at 240s, and Laravel's own
# default of 60s would kill that conversion mid-flight and report it as a timeout of the
# job rather than of the call. Jobs declaring their own $timeout still override this.
readonly JOB_TIMEOUT_SECONDS=360
# One attempt, matching the preview queue command (docs/topology/preview.md § Services)
# and the engine's queued-only conversion. Stated explicitly so a change to the
# framework default cannot quietly turn a single attempt into several.
readonly JOB_ATTEMPTS=1
# A fresh clone has no vendor/ until the post-start hook's composer install finishes, and
# this daemon may start first. Wait rather than crash-loop: supervisord gives up on a
# process that keeps dying, which would leave the project with no worker even after the
# install completed.
readonly INSTALL_WAIT_TIMEOUT_SECONDS=600
readonly INSTALL_WAIT_INTERVAL_SECONDS=5
readonly LOG_PREFIX='queue-worker:'

log() {
  echo "${LOG_PREFIX} $*"
}

cd "${PROJECT_ROOT}"

waited=0
while [[ ! -f vendor/autoload.php ]]; do
  if ((waited >= INSTALL_WAIT_TIMEOUT_SECONDS)); then
    log "vendor/ still absent after ${INSTALL_WAIT_TIMEOUT_SECONDS}s — nothing to run" >&2
    log "install dependencies, then 'ddev poweroff && ddev start' to bring the worker up" >&2
    exit 1
  fi
  if ((waited == 0)); then
    log "waiting for composer install to finish (fresh clone)"
  fi
  sleep "${INSTALL_WAIT_INTERVAL_SECONDS}"
  waited=$((waited + INSTALL_WAIT_INTERVAL_SECONDS))
done

log "starting (queue:listen, timeout=${JOB_TIMEOUT_SECONDS}s, tries=${JOB_ATTEMPTS})"
# exec: the worker replaces this shell, so supervisord's signals reach PHP directly
# instead of stopping a wrapper and orphaning the process it started.
exec php artisan queue:listen \
  --tries="${JOB_ATTEMPTS}" \
  --timeout="${JOB_TIMEOUT_SECONDS}" \
  --no-ansi
