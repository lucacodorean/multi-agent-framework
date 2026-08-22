#!/usr/bin/env bash
# Materialize a writable, git-clean working copy of the repository inside a CI runner.
# SOURCED, never executed.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/working-copy.sh"
#
# Sourced by infra/ci/platform/prepare-app.sh and infra/ci/static-analysis/run-analysis.sh.
# On exit: PHP 8.5 selected, the shell left in ${WORK_DIR} with the file set a fresh checkout
# would contain, and `log` defined for the caller.
#
# Split out of prepare-app.sh rather than sourced from it, so that a Pint failure never
# requires a running PostgreSQL — a gate that goes red for someone else's reason gets muted.
set -euo pipefail

readonly SOURCE_DIR=/src
readonly WORK_DIR=/app

log() {
  echo "==> $*"
}

# PHP 8.5 explicitly, because the image's default is 8.4: DDEV normally selects the version at
# container start from config.yaml, and started directly the image answers `php -v` with 8.4.
# Selected through update-alternatives — the mechanism the image registers — rather than by
# shadowing the binary, so composer, artisan, pest, pint and phpstan all resolve the same one.
log "selecting PHP 8.5 (image default is 8.4)"
update-alternatives --set php /usr/bin/php8.5 >/dev/null
php -v | head -1

# A writable working copy containing EXACTLY what a fresh checkout would contain: the file set
# comes from git (--cached from the working tree so uncommitted edits are tested, --others for
# new files, --exclude-standard for .gitignore) rather than a hand-written exclude list. The
# original `tar --exclude=vendor` version made the gate LIE — a developer's gitignored
# public/css/filament came along, so prepare-app.sh's "assets published" assertion found them
# present and passed under `--no-scripts`, the exact failure it exists to catch.
log "materializing a writable working copy at ${WORK_DIR} (git-clean file set)"
mkdir -p "${WORK_DIR}"
# The mount is owned by the host user, not by root inside the container; without this git
# refuses to operate on it ("dubious ownership") and the copy would silently produce nothing.
git config --global --add safe.directory "${SOURCE_DIR}"

# The source must BE a git checkout, asserted before the copy rather than inferred after it.
# Measured: pointed at a directory with no .git, `git ls-files` died under `set -e` with its
# own `fatal: not a git repository` and exit 128 — three lines BEFORE the message written to
# explain exactly that case. A tool's raw error must never be what reports a defect. Real, not
# hypothetical: an exported tarball, a build context, or a `cp -a` minus .git all reach here.
if ! git -C "${SOURCE_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: ${SOURCE_DIR} is not a git checkout." >&2
  echo "These gates copy the file set git reports as clean (tracked + new, minus .gitignore)," >&2
  echo "so a source directory without a repository would produce an EMPTY working copy — and" >&2
  echo "an empty tree passes a linter, installs no dependencies and runs no tests." >&2
  echo "Run the gate from a clone, not from an exported or copied tree." >&2
  exit 1
fi
git -C "${SOURCE_DIR}" ls-files -z --cached --others --exclude-standard \
  | tar -C "${SOURCE_DIR}" --null --files-from - -cf - \
  | tar -C "${WORK_DIR}" -xf -
cd "${WORK_DIR}"

# A copy that produced no composer.json is a broken copy, not an empty repository. The
# non-checkout case is caught above; this is the net for every other way it comes out partial.
if [[ ! -f composer.json ]]; then
  echo "error: the working copy has no composer.json — the git file-set copy produced nothing." >&2
  echo "Is ${SOURCE_DIR} a git checkout? This gate copies what git reports as the clean file set." >&2
  exit 1
fi
