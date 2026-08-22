#!/usr/bin/env bash
# Validate the framework core and, when one exists, a project instantiation of it.
#
#   1. contract completeness — every {{placeholder}} a core file consumes is documented in the
#      contract, and the context supplies every file the contract names;
#   2. core purity — no core file states a project fact (FI-23);
#   3. binding thinness — every binding names a charter, a member record and the standing
#      orders, and pins no model or effort (FI-09);
#   4. reference integrity — every framework/ and project-context/ path cited resolves.
#
# Usage: framework/bin/validate-context.sh [context-dir]
#   With no argument: ./project-context if it exists, else the first examples/*/project-context,
#   else the core is checked alone (a distribution repo with no instantiation).
#
# Read-only. Exit 0 clean, 1 with findings.
set -uo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
readonly ROOT
cd "$ROOT" || exit 2

SCHEMA=framework/contracts/project-context.schema.md
CONTEXT_FILES=(project roster stack commands runtimes ci docs-policy conventions glossary)
fail=0
note() { printf '%s\n' "$*"; fail=1; }

CTX=${1:-}
if [ -z "$CTX" ]; then
  if [ -d project-context ]; then CTX=project-context
  else CTX=$(find examples -maxdepth 2 -type d -name project-context 2>/dev/null | head -1); fi
fi

core_files() {
  find framework .claude/skills -type f \( -name '*.md' -o -name '*.template' \) 2>/dev/null \
    | grep -v '^framework/templates/' | sort
  find framework/templates -type f 2>/dev/null | sort
}
# Core files that must not carry a project fact: everything except the host adapters (which
# exist to name harnesses) and the example-bearing templates.
pure_files() { core_files | grep -v '^framework/hosts/'; }

echo "== 1. contract completeness"
if [ -z "$CTX" ]; then
  echo "  no instantiation present — core checked alone (copy framework/templates/project-context/ to instantiate)"
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
bindings=$(find . -path ./.git -prune -o -path '*/node_modules' -prune -o -path '*/agents/*.md' -print 2>/dev/null | sort)
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

echo
[ "$fail" -eq 0 ] && echo "PASS" || echo "FINDINGS — see above"
exit "$fail"
