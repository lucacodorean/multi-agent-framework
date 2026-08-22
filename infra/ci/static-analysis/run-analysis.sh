#!/usr/bin/env bash
# The in-container half of the static-analysis gate. Runs INSIDE ddev/ddev-webserver,
# started by infra/ci/static-analysis.sh — not meant to be run on a host.
#
# Owned by platform-engineer.
set -euo pipefail

# PHP 8.5 and a git-clean writable working copy at /app. NOT prepare-app.sh: neither tool
# here needs a database, Redis, a .env, a queue premise or published Filament assets, and
# depending on them would let this gate go red for reasons that are not style or types.
source "$(dirname "${BASH_SOURCE[0]}")/../working-copy.sh"

# --no-scripts is CORRECT here, unlike in prepare-app.sh where the same flag is a named defect:
# what it skips is the post-autoload-dump hook that publishes Filament's assets, and neither
# Pint nor PHPStan opens public/. The hook also boots the application, which would surface a
# boot failure as a style failure. Autoloading is unaffected — --no-autoloader does that.
log "installing composer dependencies (--no-scripts: no assets or app boot are needed here)"
composer install --no-interaction --prefer-dist --no-progress --no-scripts

# The tools are the project's own pinned dev dependencies (composer.json), never a global or
# host binary. THIS GUARD BUYS DIAGNOSIS, NOT REDNESS: measured, removing laravel/pint leaves
# `composer install` succeeding and the invocation below failing with exit 127 either way. What
# changes is what it reports — `bash: ./vendor/bin/pint: No such file or directory`, a raw tool
# error standing in for an explanation, which must never be what reports a defect.
for tool in vendor/bin/pint vendor/bin/phpstan; do
  if [[ ! -x "${tool}" ]]; then
    echo "error: ${tool} is missing from the working copy." >&2
    echo "It is a composer dev dependency; a gate that cannot find its tool must fail, not pass." >&2
    exit 1
  fi
done

# Both tools run even when the first fails, then the statuses are judged together. A style
# violation and a type error are independent defects, and reporting only the first costs an
# extra full CI round-trip to discover the second.
STATUS=0

# --test: report, never rewrite. The repository goes in read-only and this is a copy, so a
# rewrite could not reach the caller's tree anyway — but a gate that silently "fixes" its own
# input reports green on a tree nobody has seen.
log "running Pint (--test, laravel preset: no pint.json, the preset default is the standard)"
./vendor/bin/pint --test || STATUS=1

# Level and analysed paths come from phpstan.neon (platform-owned, per CLAUDE.md ch. 2). No
# --level override here: a flag that outranks the committed configuration would let CI and a
# developer's local run disagree about what passes.
log "running PHPStan (level and paths from phpstan.neon)"
./vendor/bin/phpstan analyse --no-progress --no-interaction || STATUS=1

if ((STATUS != 0)); then
  echo "" >&2
  echo "error: static analysis failed — see the Pint and/or PHPStan output above." >&2
  echo "Reproduce locally with the identical toolchain: ./infra/ci/static-analysis.sh" >&2
  echo "Or, in the running project: ddev exec ./vendor/bin/pint --test" >&2
  echo "                            ddev exec ./vendor/bin/phpstan analyse" >&2
  echo "Pint can fix most style findings in place: ddev exec ./vendor/bin/pint" >&2
  exit 1
fi

log "static analysis: Pint clean and PHPStan clean"
