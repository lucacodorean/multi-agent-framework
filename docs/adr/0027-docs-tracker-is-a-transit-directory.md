# 0027 — `docs/tracker/` is a transit directory

- Status: accepted
- Date: 2026-08-12
- Supersedes: 0026, decision clause "regenerate, never hand-edit" only

## Context

- `docs/tracker/` takes unstructured data in (pasted statements, QA lists, tracker exports)
  and puts structured data out: an intake backlog consumable by `task-orchestrator` in PLAN
  mode. Files are retained for traceability; no cleanup is wanted.
- ADR-0026 called every file there a build artifact of the tracker — "regenerate, never
  hand-edit".
- That holds only where the input is re-derivable. A Jira export or a JQL result can be
  re-run, so its intake document is a snapshot.
- A pasted BA statement, a verbal decision or a screenshot exists nowhere else. Its intake
  document is the only durable copy of the inbound content, so regenerating over it destroys
  the sole record.

## Decision

- `docs/tracker/` is a transit directory, not a build output. Retain every file; do not prune.
- Re-derivable input (export, query, API pull): the intake document is a snapshot —
  regenerate to replace, never hand-edit.
- Non-re-derivable input (pasted text, verbal decision, screenshot): the intake document is
  the sole record — write once, supersede with a later document, never rewrite or regenerate
  over it.
- The rest of ADR-0026 stands: `docs/tracker/` is a docs-agent write path; the
  `tracker-intake` skill's deterministic path is the standing authorization, exempting these
  files from the naming-instruction rule for new doc files; they carry no token budget; and
  the ruling's boundary is `docs/tracker/` and nothing else — `docs/stories/**`,
  `docs/backlog.md` and `docs/miscellaneous/**` remain outside the whitelist (BL-007).

## Consequences

- Classify the input before running intake again. The wrong class costs the only copy of an
  unrecoverable statement.
- The directory grows monotonically: superseded documents stay beside their successors.
- The operative rules live in `docs/conventions/documentation-governance.md`; this record
  holds only the rationale. Supersede this ADR rather than editing it.
