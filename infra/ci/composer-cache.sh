#!/usr/bin/env bash
# A composer download cache that survives between gate runs. SOURCED, never executed.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/composer-cache.sh"
#   ci_ensure_composer_cache
#   docker run ... $(ci_composer_cache_docker_args) ...
#
# Owned by platform-engineer. Used by the two gates that install the platform's ~150 composer
# packages inside a throwaway runner:
#   infra/ci/platform-suite.sh
#   infra/ci/seam-suite.sh
#
# ---------------------------------------------------------------------------------------
# WHY: availability, not speed — without a cache a rate-limited mirror is fatal rather than
# slow. The shared volume, the parallelism cap and the cold-run recovery are recorded in
# docs/runbook.md § CI gates.
#
# A NAMED DOCKER VOLUME, not a host directory: the runner installs as root, so a bind mount
# would fill the developer's checkout with root-owned files that need sudo to clear.
#
# SHARED BY BOTH GATES, which take separate locks and so may hit it concurrently. That is safe
# because composer writes cache entries by renaming a temporary file into place — a reader sees
# the old entry, the new one, or a miss it re-downloads.
#
# ---------------------------------------------------------------------------------------
# WHAT THIS CACHE CANNOT DO, stated because it is the failure mode that would matter.
#
# It cannot mask a dependency change. `composer install` resolves nothing: it reads
# composer.lock and installs exactly the name+version+dist-reference set written there. The
# cache is keyed by that same triple, so a changed lock file simply misses the cache and
# downloads the new package. Removing a package from the lock removes it from vendor/ whether
# or not its zip still sits in the cache. The cache holds DOWNLOADS, never the decision about
# what to install.
# ---------------------------------------------------------------------------------------

# The volume name is a constant, like the gates' container names, so it can be inspected and
# cleared by name:
#
#   docker volume inspect oir-flow-ci-composer-cache      # location + creation time
#   docker run --rm -v oir-flow-ci-composer-cache:/c alpine du -sh /c   # size
#   docker volume rm oir-flow-ci-composer-cache           # clear it (cold-cache run)
#
# Clearing it is never destructive to anything but download time: nothing in it is a source of
# truth, and the next run repopulates it from composer.lock.
readonly CI_COMPOSER_CACHE_VOLUME=oir-flow-ci-composer-cache

# Where the volume is mounted INSIDE the runner. Not composer's default (~/.cache/composer):
# an explicit path makes the mount and the env variable obviously the same thing, and keeps the
# cache independent of whatever HOME the runner image happens to give root.
readonly CI_COMPOSER_CACHE_DIR=/composer-cache

# Composer's default of 12 simultaneous connections to codeload.github.com is what tripped the
# 429 above; 6 keeps a cold install parallel while asking a rate-limited mirror for half as
# much at once. A reliability floor, not a tuning knob: raising it recreates the failure this
# file exists to prevent, and lowering it buys nothing once the cache is warm.
readonly CI_COMPOSER_MAX_PARALLEL_HTTP=6

# Create the volume if it does not exist. `docker volume create` is idempotent — it returns the
# existing volume's name — so this is safe to call on every run, and a first run on a fresh
# machine needs no separate bootstrap step.
ci_ensure_composer_cache() {
  docker volume create "${CI_COMPOSER_CACHE_VOLUME}" >/dev/null
}

# The `docker run` arguments that put the cache in front of composer. Emitted as a string for
# unquoted expansion at the call site — every token here is a fixed literal built from the
# readonly constants above, so word splitting is exactly the intended behaviour and no value
# can contain whitespace.
ci_composer_cache_docker_args() {
  echo "--volume ${CI_COMPOSER_CACHE_VOLUME}:${CI_COMPOSER_CACHE_DIR}"
  echo "--env COMPOSER_CACHE_DIR=${CI_COMPOSER_CACHE_DIR}"
  echo "--env COMPOSER_MAX_PARALLEL_HTTP=${CI_COMPOSER_MAX_PARALLEL_HTTP}"
}
