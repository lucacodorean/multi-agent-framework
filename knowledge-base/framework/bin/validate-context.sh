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
#   6. core protection — the layers keeping the core read-only are in force (FI-25): the host's
#      instruction file states the prohibition and the example gate (FI-24), the filesystem lock
#      and both hooks are installed, and any uncommitted core change is reported so it cannot be
#      silent;
#   7. anchors — the extension index exists (FI-26) and {{kb.root}} resolves (FI-27);
#   8. documentation policy wiring — every standing authorization and every declared write path
#      resolves. No path is known to this script: it checks whatever the context declares;
#   9. budgets — every declared write path is inside the budget the policy declares for it,
#      counted by the metric the policy declares (FI-18).
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
# No implicit fallback to example material: an example is a demonstration, not a context (FI-24).
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

# The standing roster's members, parsed from the core. Names only — no file is special-cased.
roster_members() {
  awk '/^## Members/{f=1;next} /^## /{f=0} f' framework/roster.md 2>/dev/null \
    | grep -oE '^\| `[a-z][a-z0-9-]*`' | tr -d '|` '
}

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
# The other direction: a key the contract documents and no context file supplies is invisible
# today. Rows the contract itself marks as sourced from the core roster are not the project's to
# supply, and are skipped.
if [ -n "$CTX" ]; then
  unsupplied=0
  while IFS= read -r row; do
    case "$row" in *'framework/roster.md'*) continue;; esac
    for ph in $(printf '%s' "$row" | grep -oE '\{\{[a-z_]+\.[A-Za-z0-9_.]*(\[\])?\}\}' | tr -d '{}' | sed 's/\[\]$//'); do
      grep -rqF "\`$ph\`" "$CTX"/ 2>/dev/null || { note "  contract documents '$ph' and no context file supplies it"; unsupplied=$((unsupplied+1)); }
    done
  done < <(grep '^| ' "$SCHEMA")
  [ "$unsupplied" -eq 0 ] && echo "  every documented key is supplied by the context"
fi

echo "== 2. core purity (FI-23)"
purity=0
if [ -n "$CTX" ] && [ -f "$CTX/project.md" ]; then
  SLUG=$(grep -oE '^\| `project\.slug` \| `[^`]+`' "$CTX/project.md" | grep -oE '`[^`]+`$' | tr -d '`')
  NAME=$(grep -oE '^\| `project\.name` \| [^|]+' "$CTX/project.md" | sed 's/.*| //; s/ *$//')
  for pat in "$SLUG" "$NAME"; do
    [ -z "$pat" ] && continue
    # an unfilled stub value contributes nothing to purity
    case "$pat" in "<"*) continue;; esac
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

echo "== 3. bindings and roster wiring"
# Bindings live at the host mount points, which are outside this unit — a harness discovers
# agents only at the repository root (hosts/). Search there and beside the resolved context;
# an example's bindings are checked when, and only when, its context was named (FI-24).
BINDING_BASE=".."
[ -n "$CTX" ] && [ "$(dirname "$CTX")" != "." ] && BINDING_BASE="$(dirname "$CTX")"
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
# Every member of the standing roster must be dispatchable on every host that has a binding
# directory, and must own something — or be explicitly empty — in the context.
members=$(roster_members)
if [ -z "$members" ]; then
  note "  the standing roster lists no members — framework/roster.md § Members is unparseable"
else
  for dir in $(printf '%s\n' $bindings | xargs -r -n1 dirname | sort -u); do
    for m in $members; do
      [ -f "$dir/$m.md" ] || note "  $dir has no binding for roster member '$m' — it cannot be dispatched there"
    done
  done
  for b in $bindings; do
    bm=$(basename "$b" .md)
    printf '%s\n' $members | grep -qx "$bm" || note "  $b binds '$bm', which is not a member of the standing roster"
  done
  if [ -n "$CTX" ] && [ -f "$CTX/roster.md" ]; then
    for m in $members; do
      grep -qF "\`$m\`" "$CTX/roster.md" || note "  the context does not mention roster member '$m' — its ownership is undeclared, not empty"
    done
  fi
  echo "  $(printf '%s\n' $members | wc -l) roster members accounted for"
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
hooks_present=""
for h in pre-commit pre-push; do
  [ -x "$CORE/bin/githooks/$h" ] && hooks_present="$hooks_present $h" || note "  hook missing or not executable: $h"
done
# The instruction layer: the host's index-and-law file must carry the prohibition, so every
# agent that loads instructions has read it. FI-25 is the marker.
instr="none found"
for f in ../CLAUDE.md ../AGENTS.md; do
  [ -f "$f" ] || continue
  instr="${f#../}"
  grep -q 'FI-25' "$f" || note "  $instr does not state the core prohibition (FI-25) — the instruction layer is the only one every agent reads"
  grep -q 'FI-24' "$f" || note "  $instr does not state the example read-gate (FI-24) — nothing else can enforce a gate on reading"
  grep -q 'EXAMPLE-ACCESS' "$f" || note "  $instr does not name the EXAMPLE-ACCESS grant — an unnamed grant cannot be carried in a task prompt"
done
echo "  filesystem lock: $fs_locked · hooks path: $hook_on ·$hooks_present · instruction: $instr"
if [ "$fs_locked" = no ] && [ "$hook_on" = no ]; then
  note "  no mechanical layer is protecting the core — run $CORE/bin/lock-core.sh lock"
fi
dirty=$(git status --porcelain -- "$CORE" 2>/dev/null || true)
if [ -n "$dirty" ]; then
  echo "  uncommitted core changes (deliberate core work must be visible, FI-25):"
  printf '%s\n' "$dirty" | sed 's/^/    /'
else
  echo "  no uncommitted core changes"
fi

echo "== 7. anchors"
# FI-26: one index, or extensions are untraceable.
if [ -f extensions/README.md ]; then
  # count data rows only: not the header, not the separator, not the em-dash placeholder
  rows=$(awk -F'|' '/^\| extension \|/{h=1;next} h&&/^\|/{c=$2;gsub(/[ \t]/,"",c);
         if(c!=""&&c!~/^-+$/&&c!="\xe2\x80\x94")n++} END{print n+0}' extensions/README.md)
  echo "  extension index: present, $rows extension(s) listed"
elif [ -d extensions ]; then
  note "  extensions/ exists with no README.md index — every extension must be traceable (FI-26)"
else
  echo "  extension index: none, and no extensions/ directory"
fi
# FI-27: the anchor must resolve to this directory, and be findable without opening the context.
[ -f framework/VERSION ] && echo "  core version: $(cat framework/VERSION)" \
  || note "  framework/VERSION is absent — a consumer cannot say which core it vendored"
anchor=$(basename "$KB")
if [ -n "$CTX" ] && [ -f "$CTX/project.md" ]; then
  declared=$(grep -oE '^\| `kb\.root` \| `[^`]+`' "$CTX/project.md" | grep -oE '`[^`]+`$' | tr -d '`/')
  if [ -z "$declared" ]; then
    note "  the context declares no kb.root — files outside the unit have no anchor to cite (FI-27)"
  elif [ "$declared" != "$anchor" ]; then
    note "  kb.root is declared '$declared' but this unit sits at '$anchor'"
  else
    echo "  kb.root: '$anchor', declared and matching"
  fi
else
  echo "  kb.root: '$anchor' (no context to check the declaration against)"
fi
for f in ../CLAUDE.md ../AGENTS.md; do
  [ -f "$f" ] || continue
  grep -q "kb.root" "$f" || note "  ${f#../} does not state where {{kb.root}} points — a mounted skill cannot resolve it (FI-27)"
done

echo "== 8. documentation policy wiring"
if [ -z "$CTX" ] || [ ! -f "$CTX/docs-policy.md" ]; then
  echo "  no documentation policy to check"
else
  POL="$CTX/docs-policy.md"
  # A standing authorization names the file that grants a whole class of documents (FI-20). If
  # that file is absent the authorization is a claim, not a grant.
  auth_missing=0
  for a in $(grep -oE 'standing: `[^`]+`' "$POL" | sed 's/standing: //' | tr -d '`'); do
    t=$a; case "$a" in /*) t="${a#/}";; esac
    [ -e "$t" ] || { note "  standing authorization names '$a', which does not exist"; auth_missing=$((auth_missing+1)); }
  done
  [ "$auth_missing" -eq 0 ] && echo "  every standing authorization resolves"
  # Declared write paths must exist, or say they do not yet. No filename is known here.
  wp_missing=0; wp_total=0
  while IFS= read -r row; do
    case "$row" in *'not yet created'*) continue;; esac
    pth=$(printf '%s' "$row" | sed -n 's/^| *`\([^`]*\)`.*/\1/p')
    [ -z "$pth" ] && continue
    case "$pth" in *'<'*|*'*'*) continue;; esac
    wp_total=$((wp_total+1))
    [ -e "$pth" ] || { note "  declared write path '$pth' does not exist — mark it 'not yet created' or create it"; wp_missing=$((wp_missing+1)); }
  done < <(awk '/^## Allowed write paths/{f=1;next} /^## /{f=0} f' "$POL")
  [ "$wp_missing" -eq 0 ] && echo "  all $wp_total declared write paths exist"
fi

echo "== 9. budgets (FI-18)"
if [ -z "$CTX" ] || [ ! -f "$CTX/docs-policy.md" ]; then
  echo "  no documentation policy to check"
else
  # The metric is the policy's, not this script's: words x 4/3, rounded down. A budget cell that
  # is not a number ("none", prose) means the length follows the input rather than the author.
  tokens() { awk '{w+=NF} END{printf "%d", w*4/3}' "$1"; }
  over=0; checked=0
  while IFS= read -r row; do
    pth=$(printf '%s' "$row" | sed -n 's/^| *`\([^`]*\)`.*/\1/p')
    [ -z "$pth" ] && continue
    case "$pth" in *'<'*|*'*'*) continue;; esac
    bud=$(printf '%s' "$row" | awk -F'|' '{print $(NF-1)}' | tr -d ' ,' | grep -oE '^[0-9]+$' || true)
    [ -z "$bud" ] && continue
    if [ -d "$pth" ]; then files=$(find "$pth" -type f -name '*.md' 2>/dev/null); else files="$pth"; fi
    for f in $files; do
      [ -f "$f" ] || continue
      t=$(tokens "$f"); checked=$((checked+1))
      [ "$t" -gt "$bud" ] && { note "  $f is $t tokens, over its $bud budget — compress, or report the overrun (FI-18)"; over=$((over+1)); }
    done
  done < <(awk '/^## Allowed write paths/{f=1;next} /^## /{f=0} f' "$CTX/docs-policy.md")
  [ "$over" -eq 0 ] && echo "  all $checked budgeted files are within budget"
fi

echo
[ "$fail" -eq 0 ] && echo "PASS" || echo "FINDINGS — see above"
exit "$fail"
