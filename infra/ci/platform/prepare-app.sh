#!/usr/bin/env bash
# Bring a runnable Laravel application up inside the CI runner. SOURCED, never executed.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/prepare-app.sh"
#
# Shared by infra/ci/platform/run-suite.sh and infra/ci/seam/run-seam.sh. Sourced rather than
# executed because it leaves the shell in ${WORK_DIR}, from which the caller runs its own test
# command. On exit: PHP 8.5 selected, a git-clean working copy at ${WORK_DIR} with vendor/ and
# published Filament assets, and postgres + redis answering. The half that only builds the
# working copy lives in infra/ci/working-copy.sh, for the gate that needs source without boot.
set -euo pipefail

# PHP 8.5, the git-clean working copy at /app, and `log`. Shared with the static-analysis
# gate, which needs the tree but none of the booting below. Defines SOURCE_DIR and WORK_DIR
# and leaves the shell in WORK_DIR — see the file for why it is split out rather than copied.
source "$(dirname "${BASH_SOURCE[0]}")/../working-copy.sh"

# A .env file must EXIST, even though nothing in it is authoritative: configuration comes from
# phpunit.xml and the real environment, and dotenv never overwrites either. Bootstrap reads
# .env on every Feature test, and with the file absent each emitted `Failed to open stream` —
# PHPUnit does not fail on warnings, so the run reported "288 warnings, 134 passed" and EXITED
# 0, the whole Feature suite degraded to warnings while the gate said green.
log "creating .env (path must exist; values come from phpunit.xml and the environment)"
cp .env.example .env

# Checked BEFORE composer install, deliberately: it needs only PHP and phpunit.xml, and a
# premise that is going to fail should fail in a second rather than after a three-minute
# dependency resolution. See the file's own header for what it guards and why. It applies to
# BOTH gates: neither runs a queue worker, because CI has no supervisord.
log "checking the queue premise"
php infra/ci/platform/queue-guard.php

# ---------------------------------------------------------------------------------------
# Dependencies — WITH composer scripts.
#
# `--no-scripts` skips post-autoload-dump, which is where composer.json runs
# `artisan filament:upgrade`. Filament's assets are GENERATED, not source, and the root
# .gitignore excludes public/{css,js,fonts}/filament precisely because that hook republishes
# them. Skip the hook and the tree looks complete while every Filament script 404s — a
# 200-but-broken UI ("filamentSchema is not defined").
# ---------------------------------------------------------------------------------------
# THE DOWNLOAD CACHE MUST ACTUALLY BE IN FRONT OF COMPOSER — asserted here, where the variable
# is used, rather than trusted at the call site: without it composer falls back to a cache
# inside the throwaway container and the gate dies on HTTP 429 again, a regression invisible in
# a green run. Deliberately NOT a check that the cache is POPULATED — a cold cache is a
# legitimate state, and a gate that needs prior state to pass cannot be reproduced.
if [[ -z "${COMPOSER_CACHE_DIR:-}" ]]; then
  echo "error: COMPOSER_CACHE_DIR is unset — the persistent composer cache is not mounted." >&2
  echo "Without it every run re-downloads every dist archive, and a rate-limited mirror turns" >&2
  echo "this gate red for a reason that has nothing to do with the tree (429, 2026-08-17)." >&2
  echo "The outer gate script must source infra/ci/composer-cache.sh and pass its docker args." >&2
  exit 1
fi
mkdir -p "${COMPOSER_CACHE_DIR}"
if [[ ! -w "${COMPOSER_CACHE_DIR}" ]]; then
  echo "error: COMPOSER_CACHE_DIR=${COMPOSER_CACHE_DIR} is not writable in this runner." >&2
  echo "Composer would download normally and then discard every archive, so the cache would" >&2
  echo "look configured while never warming. Check the volume mount in the outer gate script." >&2
  exit 1
fi
log "composer cache: ${COMPOSER_CACHE_DIR} ($(du -sh "${COMPOSER_CACHE_DIR}" 2>/dev/null | cut -f1) before install, max ${COMPOSER_MAX_PARALLEL_HTTP:-composer default} parallel downloads)"

log "installing composer dependencies (scripts ENABLED — filament:upgrade must run)"
# SECONDS is bash's own counter; the elapsed line is what makes a cold run and a warm run
# distinguishable in a CI log without anyone instrumenting the gate afterwards.
composer_started_at=${SECONDS}
composer install --no-interaction --prefer-dist --no-progress
log "composer install finished in $((SECONDS - composer_started_at))s (cache now $(du -sh "${COMPOSER_CACHE_DIR}" 2>/dev/null | cut -f1))"

# The assertion that makes the line above load-bearing rather than aspirational: if the
# hook is ever dropped, or someone adds --no-scripts, this fails HERE with the reason —
# instead of thirty tests later, or not at all.
log "verifying Filament published its assets"
missing=()
for directory in public/css/filament public/js/filament public/fonts/filament; do
  if [[ ! -d "${directory}" ]] || [[ -z "$(ls -A "${directory}" 2>/dev/null)" ]]; then
    missing+=("${directory}")
  fi
done
if ((${#missing[@]} > 0)); then
  echo "error: Filament assets were not published: ${missing[*]}" >&2
  echo "composer's post-autoload-dump hook (artisan filament:upgrade) did not run." >&2
  echo "Do not pass --no-scripts to composer install here; if it is unavoidable, run" >&2
  echo "\`php artisan filament:upgrade\` explicitly afterwards. A tree without these" >&2
  echo "directories serves a 200-but-broken UI." >&2
  exit 1
fi
log "Filament assets present"

# ---------------------------------------------------------------------------------------
# Services. Waited for by SPEAKING THEIR PROTOCOLS, not by sleeping: a fixed sleep is either
# too short (flaky) or too long (wasted on every run), and it proves nothing either way.
# ---------------------------------------------------------------------------------------
log "waiting for postgres and redis"
php infra/ci/platform/wait-for-services.php

# config:clear mirrors composer.json's own `test` script: a cached configuration built during
# composer install would otherwise outrank phpunit.xml's <env> block, and the tests would run
# against the development database instead of oirflow_test.
log "clearing cached configuration"
php artisan config:clear
