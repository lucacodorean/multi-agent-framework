# Documentation policy — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § docs-policy.md. Rules:
`framework/rules/documentation-governance.md`; lifecycles:
`framework/rules/doc-artifact-registry.md`.

| key | value |
|---|---|
| `docs.sole_writer` | docs-agent |
| `docs.role_gate_line` | `ROLE: docs-agent` |
| `docs.worker_channel` | `docs/_intake.md` |
| `docs.metric` | `wc -w <file>` × 4/3, rounded down (ratified 2026-08-19). No other metric counts. `wc -c` ÷ 4 overstates badly on this corpus — Romanian diacritics, em dashes and glyphs like `≤` are multi-byte in UTF-8 but cost no extra tokens. |
| `docs.archive_dir` | `docs/archive/` — created on first compaction; nothing is hard-deleted |

## Allowed write paths — canonical, one copy

`docs.write_paths`:

| path | budget |
|---|---|
| `docs/architecture.md` | 2,800 |
| `docs/runbook.md` | 2,600 |
| `docs/document-engine-bridge.md` | 1,600 |
| `docs/conventions/` (each file) | 1,300 |
| `docs/conventions/engineering-principles.md` | 2,400 |
| `docs/topology/` (each file) | 1,300 |
| `docs/ci/` (each file) | 1,300 |
| `docs/architecture-c4.md` | 1,300 — not yet created |
| `docs/adr/` (each record) | 650 |
| `infra/README.md` | 2,800 (hub tier) — the only writable `.md` outside `docs/`; a docs-agent carve-out inside platform-engineer's tree |
| `docs/debt/` | none |
| `docs/tracker/` | none |
| `docs/stories/as-is/` | none |
| `docs/backlog.md` | none |
| `docs/_intake.md` | drain and truncate only |

Outside the list and needing a one-off human instruction naming the file:
`docs/miscellaneous/**`, `docs/e2e-samples/**`. `docs/stories/as-reference/` is writable by no
one. `CLAUDE.md` is writable only when the human's instruction for that invocation says so.

## Artifact types

`docs.artifact_types`:

| type | path pattern | writer | authorization | lifecycle | budget |
|---|---|---|---|---|---|
| decision record | `docs/adr/NNNN-slug.md` | docs-agent | human-per-file | immutable | 650 |
| living story | `docs/stories/as-is/AS-###-slug.md` | docs-agent | standing:`docs/stories/as-is/README.md` | living | none |
| tracker intake | `docs/tracker/YYYY-MM-DD-<scope>-intake.md` | tracker-intake skill via docs-agent | standing:`.claude/skills/tracker-intake/` | transit | none |
| review report | `docs/debt/YYYY-MM-DD-<branch>.md` | docs-agent | standing:`framework/roles/code-reviewer.md` | dated-snapshot | none |
| review intake | `docs/tracker/YYYY-MM-DD-<scope>-review-intake.md` | docs-agent | standing:`.claude/skills/tracker-intake/` | transit, sole-record | none |
| backlog | `docs/backlog.md` | docs-agent | standing:this file | living | none |
| intake channel | `docs/_intake.md` | every worker appends; docs-agent drains | standing:this file | append-only | none |
| supplied material | `docs/stories/support/*` | nobody | none | sole-record | none |
| historical stories | `docs/stories/as-reference/*` | nobody | none | immutable | none |

Decision-record numbering: starts at 0024 (0001–0023 removed with the 2026-08-11
re-initialization); 0034 retired; ids never reused. Index: `docs/adr/README.md`.

## Read-gated paths

`docs.read_gated`:

| path | grant |
|---|---|
| `docs/stories/as-reference/` | `HISTORY-ACCESS:` present in the task prompt |

## Removed documents

`docs/tenancy.md`, `docs/team.md`, `docs/orchestration.md`, `docs/blueprint.md`,
`docs/user-stories.md`, `docs/prerequisites.md` were removed 2026-08-11. Code, config, infra and
tests still cite them; the citation resolves to nothing — recover from git history. Recreation
needs an explicit human instruction (FI-20).
