# Documentation artifact registry

Framework rule. The artifact kinds a project may declare, and the lifecycle each obeys.
Project values: `{{docs.artifact_types[]}}` in `project-context/docs-policy.md`.

A project declares, per kind: `path_pattern`, `writer`, `authorization`, `lifecycle`, `budget`.
The framework fixes what each lifecycle means.

## Lifecycles

| lifecycle | rule | derived from |
|---|---|---|
| `immutable` | accepted once, never edited. A change supersedes it with a new record; the old id is never reused and never re-minted. | FI-19 |
| `living` | current state only. Updated in place as intent changes, deleted when its scope is dropped. No tombstones — version history is the archive. | FI-19 |
| `snapshot` | re-derivable from a source that still exists. Regenerate to replace; never hand-edit. | FI-19 |
| `sole-record` | not re-derivable — a paste, a verbal decision, a screenshot. Write once; supersede with a later document; never regenerate over it. | FI-19 |
| `dated-snapshot` | a judgement about a moment. Retire a finding in place: add a status line and bump its date. Never rewrite a finding body, the closing block, or the header counts — they state what was found on that date. A retired finding may hold claims that are no longer true, **and that is intended**: correcting it destroys the record of what was believed when the judgement was made. | FI-19 |
| `transit` | data in, orchestrator-ready output out. Keep every file for traceability; never prune. Regeneration follows the input class above. | FI-19 |
| `append-only` | appended to by many, drained and truncated by the doc writer alone. Never edit or remove an existing entry. | FI-02 |

## Standard kinds

The kinds a project is likely to declare, with a **suggested** path and the lifecycle that fits
it. A project's `{{docs.artifact_types[]}}` is canonical: take these, rename them, drop the ones
it has no use for, add its own. Nothing here authorizes anything — a kind is in force when the
project declares it.

The column exists so a project, or a tool standing one up, has somewhere to start other than
invention, and so two projects that do not think about it end up alike.

| kind | suggested path | lifecycle | typical authorization | budgeted |
|---|---|---|---|---|
| decision record | `docs/adr/NNNN-slug.md` | `immutable` | human-per-file | yes |
| living story | `docs/stories/<ID>-slug.md` | `living` | standing: a README in that directory | no |
| tracker intake | `docs/tracker/YYYY-MM-DD-<scope>-intake.md` | `transit` | standing: the intake skill | no |
| review report | `docs/debt/YYYY-MM-DD-<scope>.md` | `dated-snapshot` | standing: the reviewer charter | no |
| intake channel | `docs/_intake.md` | `append-only` | standing: the project's policy | no |
| compaction archive | `docs/archive/**` | `sole-record` | standing: the project's policy | no |
| convention | `docs/conventions/<name>.md` | `living` | human-per-file | yes |
| system description | `docs/architecture.md` | `living` | human-per-file | yes |
| operating commands | `docs/runbook.md` | `living` | human-per-file | yes |
| runtime topology | `docs/topology/<runtime>.md` | `living` | human-per-file | yes |
| CI host wiring | `docs/ci/<host>.md` | `living` | human-per-file | yes |
| supplied material | `docs/reference/<name>` | `sole-record` | none — arrives by human instruction | no |

`budgeted` says whether length is the author's choice (`yes`, so the project sets a number) or
follows the input (`no`, so a number would be meaningless). It is not a number: the framework
cannot know one.

Templates for the kinds that have a fixed shape: `framework/templates/artifacts/`.

## Authorization

Each kind names how a new file in it is authorized (FI-20):

- `human-per-file` — an explicit instruction naming the file. The default.
- `standing:<path>` — the named file is the standing authorization; deterministic paths need
  no per-file instruction. A kind claiming a standing authorization must name the file that
  grants it, and that file must exist.
- `none` — nobody writes here; material arrives only by explicit human instruction naming it.

## Identifiers

- One id space per kind, disjoint from every other kind's.
- An id is never reused. A rename keeps the id.
- A retired or reserved id is never re-minted; the reason is recorded once, in the kind's index.
- An index of a kind lists every record of that kind. An unindexed record invites re-minting
  and is a defect in the index, not in the record.

## Budgets

`budget` is in tokens under `{{docs.metric}}`, or `none` where length follows the input rather
than the author (generated intake, review reports). FI-18 governs overrun.
