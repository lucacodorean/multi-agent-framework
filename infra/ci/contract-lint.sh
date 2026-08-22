#!/usr/bin/env bash
# The contract boundary's CI gate — Spectral over every document in contract/.
#
#   Usage:  infra/ci/contract-lint.sh
#
# Requires Docker and NOTHING else on the host: a HOST npx is forbidden by name
# (infra/README.md → Host-agnostic tooling) — it lints with whatever the developer's machine
# resolved. contract/ is the only coupling point between the tiers, so a loosened contract
# reaches every member at once, and this is the cheapest gate that catches it.
#
# ---------------------------------------------------------------------------------------
# WHAT MAKES THIS RED (ask this of every gate — if the answer is "nothing", the gate is
# decorative; docs/conventions/orchestration.md → "green by absence"):
#
#   1. ANY error-severity finding. That includes the ruleset's own house rules
#      (operation-operationId, error-responses-use-problem-json, info-version-semver,
#      channel-address-lowercase-dotted, …) — contract/.spectral.yaml deliberately bumps
#      the rules that matter on a team boundary to `error`.
#   2. A MALFORMED document. Spectral exits non-zero when a spec cannot be parsed.
#   3. AN EMPTY GLOB. If contract/*.yaml ever matches nothing, this fails loudly instead
#      of reporting a cheerful zero problems over zero files — a lint that linted nothing
#      is the purest form of green by absence.
#   4. MORE WARNINGS THAN THE RECORDED BASELINE (see WARNING_BASELINE below).
#
# Deliberately NOT red: the four warnings and one info that exist today. Fixing them means
# editing contract/**, which belongs to contract-owner, not to the platform tier — a gate
# that is red on arrival gets disabled, not fixed. The ratchet below is the compromise.
# ---------------------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT

# The official Spectral image, pinned BY DIGEST rather than by tag.
#
# The tag alone would not be a pin: `stoplight/spectral:6` is a moving target, and the
# findings this gate reports depend on the bundled @stoplight/spectral-rulesets, not only
# on the CLI. Measured on this project (2026-07-29) — the image and the web container's
# `npx @stoplight/spectral-cli@6` BOTH report CLI 6.16.2 and both report the same four
# warnings, but the image does NOT emit the `asyncapi-latest-version` info that npx does,
# because npx resolves the transitive ruleset package freshly at install time and the
# image froze an earlier one. Two toolchains, same CLI version, different output.
#
# That divergence is why the ratchet below counts WARNINGS ONLY: the warning count is 4
# in both toolchains, while the info count is 1 under npx and 0 here. Counting infos would
# make the threshold depend on which toolchain observed it.
readonly SPECTRAL_IMAGE=stoplight/spectral@sha256:032d0da0de0dfae1b5136da4172c29d4654308b9199725fdaf0d9ead2305c0ce

# Warnings accepted today, frozen 2026-07-29. Warnings only, never infos — the two
# toolchains agree on warnings and differ on infos: infra/README.md § Host-agnostic tooling.
#
# The rule this number carries is contract-owner's; the mechanism is platform's. Changing it
# is a decision there and a task here, deliberately lightweight and not an ADR
# (docs/conventions/orchestration.md § Tiers and direction). Never edit it to turn a red
# build green.
readonly WARNING_BASELINE=4

log() {
  echo "==> $*"
}

cd "${REPO_ROOT}"

# The set of documents is a GLOB, not a hard-coded list, and it is deliberately the same
# glob infra/ddev/commands/web/contract-lint uses: a new boundary document must be covered
# the moment it lands, in CI and locally, without anyone remembering to add it in two
# places. The glob does not match dotfiles, so the ruleset itself is excluded.
shopt -s nullglob
SPECS=(contract/*.yaml)
if [[ ${#SPECS[@]} -eq 0 ]]; then
  echo "error: no contract specs found in contract/*.yaml — the gate linted nothing" >&2
  exit 1
fi

REPORT_DIR="$(mktemp -d)"
# The report directory is the ONLY writable mount; the repository goes in read-only, so a
# ruleset cannot rewrite the tree it is judging.
#
# IT TAKES NO LOCK: only the three container-owning gates serialize on a machine
# (docs/runbook.md § CI gates). Both `docker run`s here are synchronous and `--rm`, and
# this directory is per-run.
trap 'rm -rf "${REPORT_DIR}"' EXIT

log "linting ${#SPECS[@]} document(s): ${SPECS[*]}"
log "spectral image: ${SPECTRAL_IMAGE}"

# --fail-severity=error draws the hard line: errors fail the process, warnings and infos
# are reported and let through to the ratchet below. Both formatters run off the SAME
# analysis — `stylish` for a human reading the log, `json` for the count — so the summary
# and the threshold can never disagree about what was found.
set +e
docker run --rm \
  --volume "${REPO_ROOT}:/work:ro" \
  --volume "${REPORT_DIR}:/report" \
  --workdir /work \
  "${SPECTRAL_IMAGE}" \
  lint "${SPECS[@]}" \
  --ruleset contract/.spectral.yaml \
  --format stylish \
  --format json --output.json /report/findings.json \
  --fail-severity=error
readonly SPECTRAL_STATUS=$?
set -e

if ((SPECTRAL_STATUS != 0)); then
  echo "" >&2
  echo "contract gate FAILED: Spectral exited ${SPECTRAL_STATUS} — error-severity findings, or a document that could not be parsed." >&2
  echo "Reproduce locally with the identical image: infra/ci/contract-lint.sh" >&2
  echo "Or inside the running project: ddev contract-lint" >&2
  exit "${SPECTRAL_STATUS}"
fi

if [[ ! -s "${REPORT_DIR}/findings.json" ]]; then
  echo "error: spectral exited 0 but wrote no JSON report — the count below would be a guess" >&2
  exit 1
fi

# Counted with the image's own Node rather than by grepping the JSON: severity is a
# numeric field (0=error 1=warn 2=info 3=hint) and a substring match would also hit any
# finding whose *message* happened to contain the same text.
WARNINGS="$(docker run --rm \
  --volume "${REPORT_DIR}:/report:ro" \
  --entrypoint node \
  "${SPECTRAL_IMAGE}" \
  -e 'const f=require("/report/findings.json");console.log(f.filter(x=>x.severity===1).length)')"

log "warnings: ${WARNINGS} (baseline ${WARNING_BASELINE}) · errors: 0"

if ((WARNINGS > WARNING_BASELINE)); then
  echo "" >&2
  echo "contract gate FAILED: ${WARNINGS} warnings, baseline is ${WARNING_BASELINE}." >&2
  echo "A change added $((WARNINGS - WARNING_BASELINE)) warning(s) to the boundary. Fix them, or — if the new" >&2
  echo "warnings are genuinely accepted — raise WARNING_BASELINE in $(basename "${BASH_SOURCE[0]}") in the same" >&2
  echo "commit, so the increase is reviewed rather than absorbed." >&2
  exit 1
fi

if ((WARNINGS < WARNING_BASELINE)); then
  log "NOTE: warnings dropped to ${WARNINGS}, below the baseline of ${WARNING_BASELINE}."
  log "Lower WARNING_BASELINE to ${WARNINGS} to lock the improvement in — a ratchet that is"
  log "not tightened lets the same warnings come back green."
fi

log "contract gate: green (0 errors, ${WARNINGS} warnings within baseline)"
