#!/usr/bin/env bash
# Validate the framework core and, when one exists, a project instantiation of it.
#
#   1. contract completeness — every {{placeholder}} a core file consumes is documented in the
#      contract, and the context supplies every file the contract names;
#   2. core purity — no core file states a project fact (FI-23);
#   3. binding thinness — every binding names a charter, a member record and the standing
#      orders, and pins no model or effort (FI-09);
#   4. reference integrity — every framework/ and project-context/ path cited resolves;
#   5. example isolation — no core file depends on the content of a concrete example (FI-24);
#   6. core protection — at least one layer is keeping the core read-only (FI-25), and any
#      uncommitted core change is reported so it cannot be silent.
#
# Usage: framework/bin/validate-context.sh [context-dir]
#   With no argument: ./project-context if it exists, else the core is checked alone. An example
#   instantiation is NEVER read unless its context directory is named explicitly (FI-24).
#
# Read-only. Exit 0 clean, 1 with findings.
set -uo pipefail

# The unit locates itself: every path below is relative to the knowledge-base root (FI-27),
# so the unit can be vendored anywhere without editing a citation.
KB=$(cd "$(dirname "$0")/../.." && pwd)
readonly KB
cd "$KB" || exit 2

SCHEMA=framework/contracts/project-context.schema.md
CONTEXT_FILES=(project roster stack commands runtimes ci docs-policy conventions glossary)
fail=0
note() { printf '%s\n' "$*"; fail=1; }

CTX=${1:-}
# No implicit fallback to examples/: an example is a demonstration, not a context (FI-24).
[ -z "$CTX" ] && [ -d project-context ] && CTX=project-context

# Core content is the unit plus the framework-owned skills, which are mounted outside the unit
# because a harness discovers them only at the repository root (framework/hosts/).
MOUNTS=""
for d in ../.claude/skills ../.opencode/skills ../.grok/skills; do
  [ -d "$d" ] && MOUNTS="$MOUNTS $d"
done
core_files() {
  # shellcheck disable=SC2086
  find framework $MOUNTS -type f \( -name '*.md' -o -name '*.template' \) 2>/dev/null \
    | grep -v '^framework/templates/' | sort
  find framework/templates -type f 2>/dev/null | sort
}
# Core files that must not carry a project fact: everything except the host adapters (which
# exist to name harnesses) and the example-bearing templates.
pure_files() { core_files | grep -v '^framework/hosts/'; }

echo "== 1. contract completeness"
if [ -z "$CTX" ]; then
  echo "  no instantiation present — core checked alone (copy framework/templates/project-context/ to instantiate)"
  ex=$(find examples -maxdepth 2 -type d -name project-context 2>/dev/null | head -1)
  [ -n "$ex" ] && echo "  an example exists at $ex and was NOT read (FI-24) — name it to validate it"
else
  echo "  context: $CTX"
  for f in "${CONTEXT_FILES[@]}"; do
    [ -f "$CTX/$f.md" ] || note "  MISSING $CTX/$f.md"
  done
fi
undocumented=0
while read -r ph; do
  [ -z "$ph" ] && continue
  grep -qF "$ph" "$SCHEMA" || { note "  placeholder not in the contract: $ph"; undocumented=$((undocumented+1)); }
done < <(core_files | xargs grep -ho '{{[a-z_]*\.[A-Za-z0-9_.\[\]]*}}' 2>/dev/null | sort -u)
[ "$undocumented" -eq 0 ] && echo "  every placeholder used by a core file is documented"

echo "== 2. core purity (FI-23)"
purity=0
if [ -n "$CTX" ] && [ -f "$CTX/project.md" ]; then
  SLUG=$(grep -oE '^\| `project\.slug` \| `[^`]+`' "$CTX/project.md" | grep -oE '`[^`]+`$' | tr -d '`')
  NAME=$(grep -oE '^\| `project\.name` \| [^|]+' "$CTX/project.md" | sed 's/.*| //; s/ *$//')
  for pat in "$SLUG" "$NAME"; do
    [ -z "$pat" ] && continue
    hits=$(pure_files | xargs grep -nIF "$pat" 2>/dev/null || true)
    [ -n "$hits" ] && { note "  project identity '$pat' appears in core:"; printf '%s\n' "$hits" | sed 's/^/    /'; purity=1; }
  done
fi
# Stack terms are checked unconditionally: the core must be language-agnostic even with no
# instantiation present. Extend this list in a project's own context, never here.
STACK_TERMS='\b(ddev|laravel|filament|pest|phpstan|larastan|pint|stancl|eloquent|artisan|composer|fastapi|pydantic|uvicorn|spectral|postgres|libreoffice|xlsx|docx)\b'
hits=$(pure_files | xargs grep -niE "$STACK_TERMS" 2>/dev/null || true)
[ -n "$hits" ] && { note "  stack term in core:"; printf '%s\n' "$hits" | sed 's/^/    /'; purity=1; }
[ "$purity" -eq 0 ] && echo "  no project identity or stack term in core"

echo "== 3. binding thinness"
# Bindings are checked beside the resolved context only. With no context, the root harness
# directories; with a named context, that context's siblings. An example's bindings are checked
# when, and only when, its context was named (FI-24).
BINDING_BASE=$([ -n "$CTX" ] && dirname "$CTX" || echo ..)
bindings=$(find "$BINDING_BASE" -maxdepth 3 -path '*/node_modules' -prune -o -path '*/agents/*.md' -print 2>/dev/null | sort)
if [ -z "$bindings" ]; then
  echo "  no bindings present — render them from framework/templates/agent-binding.md.template"
else
  for b in $bindings; do
    grep -q 'framework/roles/' "$b" || note "  $b names no charter"
    grep -q 'project-context/roster.md' "$b" || note "  $b names no member record"
    grep -q '_standing-orders.md' "$b" || note "  $b names no standing orders"
    grep -qE '^model:|^effort' "$b" && note "  $b pins model or effort (FI-09)"
    lines=$(wc -l < "$b")
    [ "$lines" -gt 40 ] && note "  $b is $lines lines — a binding restating a charter is a defect"
  done
  echo "  $(printf '%s\n' $bindings | wc -l) bindings checked"
fi

echo "== 4. reference integrity"
missing=0
while read -r p; do
  case "$p" in *'*'*|*'{'*|*'<'*) continue;; esac
  target=$p
  # project-context/ references resolve against the instantiation, wherever it lives
  case "$p" in project-context/*) [ -n "$CTX" ] && target="$CTX/${p#project-context/}" || continue;; esac
  [ -e "$target" ] || { note "  dangling reference: $p"; missing=$((missing+1)); }
done < <({ core_files; [ -n "$CTX" ] && ls "$CTX"/*.md; } 2>/dev/null \
          | xargs grep -hoE '(framework|project-context)/[A-Za-z0-9_./-]+' 2>/dev/null \
          | sed 's/[.,)]*$//' | sort -u)
[ "$missing" -eq 0 ] && echo "  every framework/ and project-context/ reference resolves"

echo "== 5. example isolation (FI-24)"
# A core file may name the directory generically (`examples/`, `examples/<project>/`); it may
# not depend on a concrete example.
hits=$(core_files | xargs grep -nIoE 'examples/[a-z0-9][A-Za-z0-9_.-]*' 2>/dev/null | grep -v 'examples/<' || true)
if [ -n "$hits" ]; then
  note "  core file depends on a concrete example:"; printf '%s\n' "$hits" | sed 's/^/    /'
else
  echo "  no core file depends on a concrete example"
fi

echo "== 6. core protection (FI-25)"
CORE=${FRAMEWORK_CORE_PATH:-framework}
HOOKS=$(git config --get core.hooksPath 2>/dev/null || true)
REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "$KB")
WANT_HOOKS="${KB#"$REPO"/}/$CORE/bin/githooks"
fs_locked=no; [ -w "$CORE/rules/invariants.md" ] || fs_locked=yes
hook_on=no;   [ -n "$HOOKS" ] && [ "${HOOKS%/}" = "$WANT_HOOKS" ] && hook_on=yes
echo "  filesystem lock: $fs_locked · commit hook: $hook_on"
if [ "$fs_locked" = no ] && [ "$hook_on" = no ]; then
  note "  nothing is protecting the core — run $CORE/bin/lock-core.sh lock"
fi
dirty=$(git status --porcelain -- "$CORE" 2>/dev/null || true)
if [ -n "$dirty" ]; then
  echo "  uncommitted core changes (deliberate core work must be visible, FI-25):"
  printf '%s\n' "$dirty" | sed 's/^/    /'
else
  echo "  no uncommitted core changes"
fi

echo
[ "$fail" -eq 0 ] && echo "PASS" || echo "FINDINGS — see above"
exit "$fail"
