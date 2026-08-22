#!/usr/bin/env bash
# Enforce FI-25 — framework core is read-only.
#
#   status  (default)  report which layers are in force
#   lock               make the core unwritable and install the commit hook
#   unlock             make the core writable again (deliberate core work)
#
# Layers, and what each one actually stops:
#   filesystem  chmod a-w on the core: stops every write, tool calls and shell alike.
#               Not tracked by git, so a fresh clone starts unlocked -- run `lock` after
#               cloning. While locked, git operations that would rewrite a core file
#               (checkout, pull, stash) fail; that is the intended friction, and `unlock`
#               is the way through it.
#   git         core.hooksPath -> framework/bin/githooks. pre-commit stops the change landing
#               in history (FRAMEWORK_UNLOCK=1 is the deliberate path); pre-push stops it
#               reaching other engineers (FRAMEWORK_PUBLISH=1). --no-verify defeats both.
#   instruction the host's index-and-law file states the prohibition, so every agent that
#               loads instructions has read it before touching anything.
#   harness     path-scoped deny rules, per host (framework/hosts/*.md).
#   review      FI-25 itself, plus the validator's enforcement report.
#
# None of these is absolute against an agent with a shell. Together they make an edit to the
# core deliberate and visible instead of accidental, which is the achievable goal (FI-22).
set -uo pipefail

# The unit locates itself (FI-27): CORE is knowledge-base-relative, HOOKS is repository-relative
# because git wants core.hooksPath that way.
KB=$(cd "$(dirname "$0")/../.." && pwd)
REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "$KB")
readonly KB REPO
cd "$KB" || exit 2
CORE=${FRAMEWORK_CORE_PATH:-framework}
HOOKS="${KB#"$REPO"/}/$CORE/bin/githooks"

writable() { [ -w "$CORE/rules/invariants.md" ] && echo yes || echo no; }
hooked()   { [ "$(git config --get core.hooksPath || true)" = "$HOOKS" ] && echo yes || echo no; }
hooks_present() {
  for h in pre-commit pre-push; do
    [ -x "$CORE/bin/githooks/$h" ] || { echo "MISSING $h"; return; }
  done
  echo "pre-commit pre-push"
}

case "${1:-status}" in
  lock)
    git config core.hooksPath "$HOOKS"
    chmod -R a-w "$CORE"
    echo "core locked: $CORE"
    echo "  writable: $(writable)   hooks installed: $(hooked)   hooks present: $(hooks_present)"
    echo "  deliberate core work: $0 unlock"
    ;;
  unlock)
    chmod -R u+w "$CORE"
    echo "core UNLOCKED: $CORE — re-lock with '$0 lock' when done."
    echo "  a commit still needs FRAMEWORK_UNLOCK=1, a push FRAMEWORK_PUBLISH=1 (hooks: $(hooked))"
    ;;
  status)
    echo "core: $CORE"
    echo "  filesystem writable: $(writable)   (locked = no)"
    echo "  hooks path installed: $(hooked)   hooks present: $(hooks_present)"
    if [ -n "$(git status --porcelain -- "$CORE" 2>/dev/null)" ]; then
      echo "  UNCOMMITTED CORE CHANGES:"
      git status --porcelain -- "$CORE" | sed 's/^/    /'
    else
      echo "  no uncommitted core changes"
    fi
    ;;
  *) echo "usage: $0 [status|lock|unlock]" >&2; exit 2;;
esac
