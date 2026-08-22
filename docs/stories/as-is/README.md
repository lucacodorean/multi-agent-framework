# as-is — living story collection

The stories the platform is currently built against, tracked as inputs arrive
and work is orchestrated. Current intent only — history lives in git.

## Rules

- Only the docs-agent writes here; workers report story impact by appending to
  `docs/_intake.md` (`docs/conventions/documentation-governance.md`).
- Reading is always allowed — consult this collection when working on a new
  input or feature.
- One story per file, `AS-###-<slug>.md`. Ids are never reused; a rename keeps
  the id. The `AS-` space is disjoint from the retired `US-`/`UC-` spaces of
  `as-reference/`.
- Update stories in place as intent changes; delete a story whose scope is
  dropped — no tombstones, git history is the archive.
- `docs/stories/as-reference/` is historical, read-gated (`HISTORY-ACCESS:`),
  and never overrides this collection.

## Story format

    ---
    id: AS-###
    title: <one line>
    status: planned | in-progress | implemented
    sources: <inputs that introduced or last changed the story>
    code_refs: <implementing paths once they exist>
    ---

    Acceptance criteria in the input's language (Romanian to date), imperative,
    testable.
