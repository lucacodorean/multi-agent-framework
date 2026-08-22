# 0026 — `docs/tracker/` is a whitelisted generated-artifact path

- Status: accepted
- Date: 2026-08-12

## Context

The `tracker-intake` skill (`.claude/skills/tracker-intake/`) normalizes issue-tracker output
— Jira exports, QA bug lists, BA change requests, pasted tickets — into a quality-gated
intake backlog at `docs/tracker/YYYY-MM-DD-<scope>-intake.md`, which is then handed to
`task-orchestrator` in PLAN mode.

- Workers never write `.md`; the docs-agent is the sole doc writer.
- `docs/tracker/` sat outside the docs-agent whitelist, and a new file in the doc tree
  requires an explicit human instruction naming that file.
- Every run of the pipeline therefore needed its own human grant. An intake document
  produced 2026-08-12 could not be landed for exactly that reason.
- A pipeline meant to run routinely cannot depend on a per-run human grant.
- The path and name are deterministic, so the grant it would carry adds no information.

## Decision

- `docs/tracker/` is an allowed docs-agent write path.
- Intake documents there are exempt from the naming-instruction rule for new doc files; the
  skill's deterministic path is the standing authorization.
- Treat them as build artifacts: the tracker holds truth — regenerate, never hand-edit.
- They carry no token budget; their length follows the backlog.
- This ruling covers `docs/tracker/` and nothing else. `docs/stories/**`, `docs/backlog.md`
  and `docs/miscellaneous/**` remain outside the whitelist and still require a one-off human
  instruction per file. Their treatment stays open as BL-007 in `docs/backlog.md`.

## Consequences

- The `tracker-intake` → `task-orchestrator` pipeline runs without a human grant per run.
- Generated artifacts now share the doc tree with authored docs. The exemption's boundary is
  the path, so any further generated tree needs its own ruling.
- Unbudgeted files can grow unbounded; `docs/tracker/` is not documentation the roster loads
  by default, and no rule elsewhere may cite it as canonical.
- The operative rules live in `docs/conventions/documentation-governance.md`; this record
  holds only the rationale. Supersede this ADR rather than editing it.
