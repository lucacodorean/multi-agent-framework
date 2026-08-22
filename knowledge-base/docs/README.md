# Knowledge-base documentation

The project's knowledge lives here: the documents agents read to do the work, and write to
record it. Decision records, tracker intake documents, review reports, stories, and the
business and domain material the work is based on.

This is a working directory, not an archive. Agents read it for information and write to it as
work lands. Creating a new file is normal — within the limits below.

## What governs a file here

| question | answer lives in |
|---|---|
| which kinds of document may exist, and where each one is filed | the project's docs policy — `docs.artifact_types` and `docs.write_paths` |
| what each kind's lifecycle is — immutable, living, snapshot, sole record, dated snapshot, transit, append-only | `framework/rules/doc-artifact-registry.md` |
| who may write, and how a worker reports a doc-impact instead of writing | `framework/rules/documentation-governance.md` |
| whether a new file needs a human naming it | FI-20 — unless its kind carries a standing authorization in the registry, in which case deterministic paths need no instruction |

That is what keeps "creating files as needed" from becoming clutter: a file belongs to a
declared kind with a declared path and lifecycle, or it needs a human to name it. Summary,
notes, progress and handoff files are not a kind — they never were, and FI-02 still holds.

## Typical contents

| kind | what it holds |
|---|---|
| decision records | one decision per file, immutable once accepted; supersede rather than edit |
| tracker intake | normalized work items, orchestrator-ready; transit, kept for traceability |
| review reports | dated snapshots of what a review found; retire a finding in place |
| stories | current intent, living; acceptance criteria in the input's language |
| business and domain material | what the work is based on; sole record — write once, supersede, never regenerate over |
| the intake channel | the append-only file every worker reports doc-impact to |

Documentation *about the framework itself* — how to instantiate it, why a rule is shaped the
way it is — belongs here too, under the same registry. The framework's own rules do not: they
are core, and core is read-only (FI-25).

## Layout

The directories exist so an agent has somewhere to write without inventing a path. Each is
empty apart from a `.gitkeep` until the work arrives.

| path | holds |
|---|---|
| `conventions/` | the two convention slots the framework mandates (`engineering-principles.md`, `architecture-principles.md` — both stubs until filled), and pointer stubs for rules that moved into the core |
| `adr/` | decision records — immutable once accepted; template in `framework/templates/artifacts/` |
| `stories/` | living stories — current intent only |
| `tracker/` | normalized intake documents — transit, never pruned |
| `debt/` | review reports — dated snapshots, retired in place |
| `topology/` | one file per runtime |
| `ci/` | the CI host wiring |
| `archive/` | what compaction removes; nothing is hard-deleted |

Not yet declared: which of these paths a project actually uses, their budgets, and the sole
writer. That comes from a project context (`docs.write_paths`, `docs.artifact_types`), which
this repository does not yet have — so treat the table above as the intended shape, not an
authorized whitelist.
