#!/usr/bin/env bash
# The ADR-citation gate — every `ADR-NNNN` named by tracked source must resolve to a record
# in docs/adr/.
#
#   Usage:  infra/ci/adr-citations.sh
#
# No container and no lock: the host rule is about TOOLS (docs/architecture.md → CI — gates)
# and this gate invokes none — git, grep, awk and sort over tracked text — and owns no Docker
# resource for infra/ci/lock.sh to serialise.
#
# This script is itself in scope, so it carries no literal ADR id anywhere, in comment or in
# message; the examples below name ranges and placeholders instead.
#
# Red on arrival, deliberately, and unlike the contract gate: no baseline, because the
# dangling citations are a defect already ruled on, not accepted debt to ratchet down.
#
# This script never pushes, tags, or deploys.
set -euo pipefail

# Declared and assigned separately: `readonly VAR="$(cmd)"` masks the substitution's exit
# status, so a failing `cd` would leave REPO_ROOT empty (SC2155; reasoning in env-contract.sh).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

readonly ADR_DIR=docs/adr

# Deliberately unanchored: a consumed ERE boundary makes `grep -o` drop overlapping matches,
# measured to lose the second id of an `<id>/<id>` pair. Four-digit-ness is asserted in awk.
readonly CITATION_RE='ADR-[0-9]+'

log() {
  echo "==> $*"
}

cd "${REPO_ROOT}"

# Without this the run dies three commands later on git's own `fatal: not a git repository` —
# red, but diagnosed by git rather than by the gate.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: ${REPO_ROOT} is not a git checkout — this gate reads TRACKED files only and" >&2
  echo "would have nothing to scan. Run it from a real clone, not from a copied directory." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
cleanup() { rm -rf "${WORK_DIR}"; }
trap cleanup EXIT

readonly RECORDS="${WORK_DIR}/records"
readonly RAW="${WORK_DIR}/raw"
readonly SCANNED="${WORK_DIR}/scanned"
readonly MALFORMED="${WORK_DIR}/malformed"
readonly OFFENDERS="${WORK_DIR}/offenders"

# Tracked only, as on the citation side: an ADR written but not added satisfies nothing on a
# runner.
git ls-files -- "${ADR_DIR}" \
  | sed -n "s|^${ADR_DIR}/\([0-9]\{4\}\)-[^/]*\.md\$|\1|p" \
  | sort > "${RECORDS}"

RECORD_COUNT="$(wc -l < "${RECORDS}" | tr -d ' ')"
readonly RECORD_COUNT

if ((RECORD_COUNT == 0)); then
  echo "error: ${ADR_DIR}/ holds no tracked <NNNN>-*.md record." >&2
  echo "Every citation in the tree would dangle for that one reason, so the gate reports the" >&2
  echo "reason instead of the consequence. Restore the directory, or — if the ADR practice was" >&2
  echo "genuinely abandoned — delete this gate rather than leaving it green over nothing." >&2
  exit 1
fi

DUPLICATES="$(uniq -d < "${RECORDS}" || true)"
readonly DUPLICATES
if [[ -n "${DUPLICATES}" ]]; then
  echo "error: two records claim the same ADR number — a citation cannot be resolved:" >&2
  while read -r dup; do
    git ls-files -- "${ADR_DIR}/${dup}-*" | sed 's/^/  /' >&2
  done <<< "${DUPLICATES}"
  echo "One decision per file, numbered sequentially (${ADR_DIR}/README.md)." >&2
  exit 1
fi

log "records: ${RECORD_COUNT} tracked ADR file(s) in ${ADR_DIR}/"

# `-I` skips binary blobs; `--no-color` keeps the output parseable under color.ui=always. git
# grep exits 1 on no match, which the SCANNED_COUNT guard below, not this line, decides about.
git grep --no-color -n -I -o -E "${CITATION_RE}" -- . > "${RAW}" || true

# Parsed from the RIGHT so a path containing a colon cannot shift the fields. A run that is
# not four digits goes to MALFORMED rather than being dropped, so the gate cannot report green
# over a citation it could not read. `length()` rather than `{4}`: mawk's interval support
# varies and this runs on whatever awk the runner has.
awk -F: -v malformed="${MALFORMED}" '
  {
    nf = NF
    cite = $nf
    lineno = $(nf - 1)
    path = $1
    for (i = 2; i <= nf - 2; i++) path = path ":" $i

    # The one exclusion: prose under docs/ may name a number that has no record.
    if (path ~ /^docs\// && path ~ /\.md$/) next

    digits = substr(cite, 5)
    if (length(digits) != 4) {
      print path "\t" lineno "\t" cite >> malformed
      next
    }

    print path "\t" lineno "\t" digits
  }
' "${RAW}" | sort -u -t$'\t' -k1,1 -k2,2n -k3,3 > "${SCANNED}"

if [[ -s "${MALFORMED}" ]]; then
  echo "error: citation(s) with a digit run that is not four digits — the gate cannot resolve them:" >&2
  awk -F'\t' '{ printf "  %s:%s: %s\n", $1, $2, $3 }' "${MALFORMED}" | sort -u >&2
  echo "Records are numbered with exactly four digits (${ADR_DIR}/README.md). Fix the citation." >&2
  exit 1
fi

SCANNED_COUNT="$(wc -l < "${SCANNED}" | tr -d ' ')"
readonly SCANNED_COUNT

if ((SCANNED_COUNT == 0)); then
  echo "error: the scan matched no ADR citation anywhere in the tracked tree." >&2
  echo "In this repository that means the scanner is broken — the citation form changed, or the" >&2
  echo "pathspec stopped matching — not that the tree is clean. If the last citation was genuinely" >&2
  echo "removed, delete this guard in the same commit rather than working around it." >&2
  exit 1
fi

log "citations in scope: ${SCANNED_COUNT} (tracked text files; .md under docs/ excluded)"

awk -F'\t' 'NR == FNR { have[$1] = 1; next } !($3 in have) { print }' \
  "${RECORDS}" "${SCANNED}" > "${OFFENDERS}"

OFFENDING_CITATIONS="$(wc -l < "${OFFENDERS}" | tr -d ' ')"
readonly OFFENDING_CITATIONS

if ((OFFENDING_CITATIONS == 0)); then
  log "adr-citations gate: green (${SCANNED_COUNT} citation(s), every number resolves to a record)"
  exit 0
fi

OFFENDING_FILES="$(cut -f1 < "${OFFENDERS}" | sort -u | wc -l | tr -d ' ')"
readonly OFFENDING_FILES

echo "" >&2
echo "adr-citations gate FAILED: ${OFFENDING_CITATIONS} citation(s) in ${OFFENDING_FILES} file(s) name an" >&2
echo "ADR number that no ${ADR_DIR}/<NNNN>-*.md record holds." >&2
echo "" >&2
echo "Missing numbers (citations · files):" >&2
# Not one awk pass with `asorti`: that is a gawk extension, and mawk would fall through after
# already printing half the report.
join -t$'\t' \
  <(cut -f3 < "${OFFENDERS}" | sort | uniq -c | awk '{ print $2 "\t" $1 }') \
  <(cut -f1,3 < "${OFFENDERS}" | sort -u | cut -f2 | sort | uniq -c | awk '{ print $2 "\t" $1 }') \
  | awk -F'\t' '{ printf "  ADR-%s  %4d citation(s) in %3d file(s)\n", $1, $2, $3 }' >&2
echo "" >&2
echo "Every offending citation, file:line:" >&2
awk -F'\t' '{ printf "  %s:%s: ADR-%s\n", $1, $2, $3 }' "${OFFENDERS}" >&2
echo "" >&2
echo "Fix each one of two ways (${ADR_DIR}/README.md → numbering):" >&2
echo "  * the decision still binds — re-derive it from the code and re-record it at a NEW," >&2
echo "    unused number, then cite that. Removed numbers are never reused." >&2
echo "  * the decision no longer binds, or the comment restates what the code already says —" >&2
echo "    delete the citation." >&2
echo "" >&2
echo "Reproduce locally, identically and without side effects:" >&2
echo "  infra/ci/adr-citations.sh" >&2
exit 1
