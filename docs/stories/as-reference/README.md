# As-reference — reference pool

`docs/stories/as-reference/` is a **reference pool of lower-priority data**, merged
2026-08-14 from three sources that are now archived.

It is **not** the working specification. It specifies nothing and governs nothing.
Consult it only when needed, or when the user asks for it.
Build nothing from it without a separate decision to do so.
The collection is frozen: items are not maintained, and their recorded conflicts and
open questions stay as recorded rather than being resolved.

## Provenance

156 items (134 US, 22 UC) merged from 226 source items in three layers:

| layer | source | nature |
|---|---|---|
| A | Prototype A | migrated legacy corpus, code-verified 2026-08-11 |
| B | Stub extract of the interactive prototype | frozen 2026-08-13 |
| C | Wiki requirements-review stories | 2026-08-13 |

The three source trees were removed with `docs/legacy/` (2026-08-14). Recover them
from git history if needed. This collection is the surviving resolution of those IDs.

Merge precedence was C over B over A: an item body states the newest variant; superseded
variants and undecided disagreements sit under `## Puncte deschise`. Bodies are Romanian;
acceptance criteria are source text, never paraphrased.

## ID scheme

IDs are `US-###` / `UC-###`, permanent — never renumbered, never reused.
Lineage is in frontmatter `sources`.
The retired source ID spaces (`US-A-###`, `US-B-###`, `US-C-###`) resolve through the
crosswalk at `.claude/plans/2026-08-14-as-is/crosswalk.json`; `Q-*` and `CF-##` refs
resolve in `.claude/plans/2026-08-14-as-is/conflicts.json`. There is no `index.md`.

## Frontmatter schema

Every item file carries exactly these fields, in this order:

```yaml
---
id: US-001                    # or UC-###; permanent, never renumbered
title: <Romanian title>
sources: [US-A-025, US-B-033, US-C-049]   # lineage; any non-empty subset of the three ID spaces
overlay: new | unchanged | modified | superseded | deprecated | deferred
coverage: team-reviewed | draft | pre-wiki | stub-only | a-only
decision: pending | null
priority: Must | Should | Could | Won't | TBD
implementation: implemented | partial | not-implemented | unknown
module: <canonical module> | null
code_refs: []                 # carried from A only; never re-derived
open_questions: []            # e.g. Q-C-003
conflicts: []                 # e.g. CF-06
superseded_by: null           # as-reference id, when overlay is superseded
---
```

## Field semantics

- `overlay` — relation to its sources. `unchanged`: single-source, or sources agree.
  `modified`: sources agree in intent and the newest narrows or extends. `new`: no A
  lineage. `superseded` / `deprecated`: retained for traceability only. `deferred`: out
  of the scope current at merge time.
- `coverage` — evidentiary weight by lineage. `team-reviewed`: C lineage, Wiki Epic 2 or
  3, walked through with the team. `draft`: C lineage, other epics — BA-drafted, not
  client-reviewed. `pre-wiki`: A and B, no C. `stub-only`: B alone. `a-only`: A alone.
- `decision` — `pending` where lineage is Prototype A alone: no higher-precedence source
  corroborates the item. Not a deprecation; says nothing about implementation.
- `implementation` — carried forward from A's `verified_status`, static code evidence of
  2026-08-11, and never re-derived. `unknown` without A lineage. It is a dated fact about
  code, doubly stale now; do not read it as current, do not guess it, do not infer it from
  an item's wording.
- `module` — from the canonical module list of the archived Prototype A verification
  report. `null`, never guessed.

## Inherited dangling references

A's bodies cite `RB-01..RB-13`, `C-01..C-38` and `§` anchors from the removed legacy
index (BL-004).
They are provenance: keep them verbatim, do not rewrite them, do not invent replacements.
They resolve only when BL-004 closes.
