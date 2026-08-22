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

Documentation *about the framework itself* belongs here too, under the same registry. The
framework's own rules do not: they are core, and read-only (FI-25).

## Layout

The directories exist so an agent has somewhere to write without inventing a path. What each
kind's lifecycle is: `framework/rules/doc-artifact-registry.md`.

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

Which of these paths are authorized, their budgets, and the sole writer come from
`project-context/docs-policy.md` — not from this table. A path here that the policy does not
declare is not writable (FI-20).
