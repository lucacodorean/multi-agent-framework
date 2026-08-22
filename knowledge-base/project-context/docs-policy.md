# Documentation policy

Rules: `framework/rules/documentation-governance.md`; lifecycles:
`framework/rules/doc-artifact-registry.md`.

| key | value |
|---|---|
| `docs.sole_writer` | `docs-agent` |
| `docs.role_gate_line` | `ROLE: docs-agent` |
| `docs.worker_channel` | `docs/_intake.md` |
| `docs.metric` | `wc -w <file>` × 4/3, rounded down. No other metric counts — `wc -c` ÷ 4 overstates on this corpus, where em dashes and glyphs like `≤` are multi-byte in UTF-8 but cost no extra tokens |
| `docs.archive_dir` | `docs/archive/` |
| `docs.budget_grace` | 50 — an overrun smaller than this is reported and tolerated; beyond it, FI-18 applies |

## Allowed write paths — canonical, one copy

`docs.write_paths`. Paths are knowledge-base-relative (FI-27).

| path | budget |
|---|---|
| `docs/_intake.md` | none — drain and truncate only |
| `docs/README.md` | 700 |
| `docs/conventions/` (each file) | 1,300 |
| `docs/adr/` (each record) | 650 |
| `docs/stories/` (each story) | none |
| `docs/tracker/` (each document) | none |
| `docs/debt/` (each report) | none |
| `docs/topology/` (each file) | 1,300 |
| `docs/ci/` (each file) | 1,300 |
| `docs/archive/` | none |
| `README.md` — the unit's front page; a docs-agent carve-out outside `docs/` | 1,300 |

Writing outside this list is a task failure. `framework/**` is not on it and never will be
(FI-25); `extensions/**` and `project-context/**` belong to `contract-owner`, not the doc writer;
the host's index-and-law file is writable only when the human's instruction for that invocation
says so.

## Artifact types

`docs.artifact_types`:

| type | path pattern | writer | authorization | lifecycle | budget |
|---|---|---|---|---|---|
| decision record | `docs/adr/NNNN-slug.md` | docs-agent | human-per-file | immutable | 650 |
| living story | `docs/stories/AS-###-slug.md` | docs-agent | human-per-file — no standing authorization exists until a `docs/stories/README.md` states one | living | none |
| tracker intake | `docs/tracker/YYYY-MM-DD-<scope>-intake.md` | docs-agent | standing: `../.claude/skills/tracker-intake/` | transit | none |
| review report | `docs/debt/YYYY-MM-DD-<branch>.md` | docs-agent | standing: `framework/roles/code-reviewer.md` | dated-snapshot | none |
| intake channel | `docs/_intake.md` | every agent appends; docs-agent drains | standing: this file | append-only | none |
| compaction archive | `docs/archive/**` | docs-agent | standing: this file | sole-record | none |

Decision records start at `0001`; ids are never reused, and a retired or reserved number is
never re-minted. There is no index yet — the first record creates one, and an unindexed record
invites re-minting.

## Read-gated paths

`docs.read_gated`: none. No example material is kept in this repository; should any be added it
is gated by `EXAMPLE-ACCESS:` (FI-24).

## Removed documents

`docs.removed` — recorded so a citation that no longer resolves has an explanation
(`framework/rules/documentation-governance.md` § Removed documents).

| document | removed | recover from |
|---|---|---|
| `docs/architecture.md`, `docs/runbook.md`, `docs/document-engine-bridge.md`, `docs/backlog.md` | 2026-08-22 | commit `099b10b` |
| `docs/adr/` (34 records and their index), `docs/topology/`, `docs/ci/`, `docs/debt/`, `docs/stories/`, `docs/e2e-samples/`, `docs/miscellaneous/` | 2026-08-22 | commit `099b10b` |
| `examples/oir-flow/**` — the worked instantiation, its bindings, plan, pipeline script and context | 2026-08-22 | commit `1758e26` |

All belonged to the project this framework was extracted from. `prompts/` still cites some of
them: those citations are a record of the extraction, not live references.
