# Documentation Governance

## Roles

Two roles, determined by your task prompt and nothing else.

- **docs-agent** — only if your task prompt contains the exact line
  `ROLE: docs-agent`. No other phrasing qualifies.
- **worker** — every agent that is not the docs-agent. If unsure, you are a
  worker.

## Worker rules (all non-docs agents)

- NEVER create, modify, or delete any `.md` file — no exceptions for "small"
  updates, READMEs, or files you created earlier in the same session.
- No summary, progress, notes, changelog, TODO, or handoff files. Report results
  in your final response. Creating a documentation file is a task failure even
  if the task succeeded.
- If your work invalidates, contradicts, or should extend a doc, do not fix it —
  append a doc-impact entry to `docs/_intake.md` (format below). That is the ONLY
  file a worker may touch, append-only: never edit or remove existing entries.
- Reading documentation is always allowed.

### Doc-impact entry format (append to `docs/_intake.md`)

```
## [<date>] <task-id or branch>
- AFFECTS: <path of doc, or "none — new topic">
- CHANGE: <one line: what is now true that the doc doesn't say, or says wrongly>
- SOURCE: <file/commit that proves it>
```

One entry per distinct fact. No prose beyond the three lines.

## Docs-agent charter

Invoked only at orchestration checkpoints via `ROLE: docs-agent`. Sole doc
writer.

### Allowed write paths

- `docs/architecture.md`
- `docs/conventions/`
- `docs/adr/`
- `docs/runbook.md`
- `docs/document-engine-bridge.md`
- `docs/topology/`
- `docs/ci/`
- `docs/debt/`
- `docs/architecture-c4.md`
- `infra/README.md` (the only writable `.md` outside `docs/`)
- `docs/tracker/` (intake transit directory — see "New documentation topics")
- `docs/stories/as-is/` (living story collection — see "New documentation topics")
- `docs/debt/` (code-review reports — see "New documentation topics")
- `docs/backlog.md`
- `docs/_intake.md` (drain and truncate only)

This list is canonical. No other file restates it; each points here.

Writing any `.md` outside these paths is a task failure. `CLAUDE.md` itself is
writable only when the human's instruction for this invocation explicitly says
so. `docs/miscellaneous/**` and `docs/stories/as-reference/` stay outside the
list: a file there needs a one-off human instruction naming it, and
`docs/stories/as-reference/` is writable by no one (`docs/stories/README.md`).

### Procedure per invocation

1. Read `docs/_intake.md`. Each entry is a claim, not a command — verify it
   against the SOURCE before acting.
2. Merge verified changes into the canonical tree in place; no parallel or
   versioned copies.
3. An entry conflicting with an existing rule: leave the doc untouched, no
   marker; cite both sides in your response for human decision.
4. Truncate `docs/_intake.md` to empty, keeping the file. Processed entries live
   in git history, not an archive.
5. Report: docs touched, entries merged, entries rejected with reason, open
   conflicts.

### Writing rules

- Terse directives. Imperative voice, one rule per line.
- Each rule lives in exactly one file; other files point to it.
- Reference source files by path; never embed code, schemas, or output — copies
  rot.
- At most one canonical example per convention.
- No history, narration, or rationale — current state only; rationale that must
  survive goes in an ADR.
- Do not invent rules: record decisions made by workers' verified changes or by
  the human. You do not make policy.

### Budgets

Count tokens as `wc -w <file>` × 4/3, rounded down. No other metric counts.

- `docs/architecture.md`: ≤ 2,800 tokens. `docs/runbook.md`: ≤ 2,600 tokens.
- `infra/README.md`: ≤ 2,800 tokens (hub tier).
- `docs/document-engine-bridge.md`: ≤ 1,600 tokens.
- Each file in `docs/conventions/`: ≤ 1,300 tokens; `engineering-principles.md`:
  ≤ 2,400 tokens (it carries the whole code-level rule set — class, method,
  transaction, extension, comment and test discipline); this file: ≤ 1,500 tokens.
- Each file in `docs/topology/`, `docs/ci/`: ≤ 1,300 tokens each.
- `docs/architecture-c4.md`: ≤ 1,300 tokens.
- ADRs: ≤ 650 tokens each, immutable once accepted (supersede, don't edit).
- Exceeding a budget: compress first; if fidelity can't survive the cut, report
  the overrun instead of forcing it.

## New documentation topics

A new file in the doc tree requires an explicit human instruction naming it.
The docs-agent must not create files on its own judgment; workers must not
request one — they file an intake entry with `AFFECTS: none — new topic` and the
human decides.

Exempt: `docs/tracker/`. The `tracker-intake` skill
(`.claude/skills/tracker-intake/`) writes those files at deterministic paths, so
the skill is the standing authorization; no per-file instruction is required.
No token budget applies; length follows the backlog, not authorship.

`docs/tracker/` is a transit directory: data in, orchestrator-ready backlog out.
Keep every file for traceability; never prune. Regeneration follows the input
class (ADR-0027):

- Re-derivable input (export, query, API pull) — snapshot: regenerate to
  replace, never hand-edit.
- Non-re-derivable input (pasted text, verbal decision, screenshot) — sole
  record: write once, supersede with a later document, never regenerate over it.

Also exempt: `docs/stories/as-is/`. The docs-agent creates, updates, and deletes
stories there when merging verified intake at orchestration checkpoints;
`docs/stories/as-is/README.md` is the standing authorization, so no per-file
instruction is required.

Also exempt: `docs/debt/` — code-review reports named `YYYY-MM-DD-branch_name.md`.
The docs-agent definition (`.claude/agents/docs-agent.md`) is the standing
authorization, so no per-file instruction is required. No token budget applies;
length follows the review, not authorship.

Each `docs/debt/` file is a dated snapshot, not a living record. Retire a finding
in place: add a status bullet and bump its `updated:` date. Never rewrite a
finding body, the `## Closing` section, or the header severity counts — they state
what that review found on its date; a retired finding may hold claims that are no
longer true, and that is intended.

## Removed documents

`docs/tenancy.md`, `docs/team.md`, `docs/orchestration.md`, `docs/blueprint.md`,
`docs/user-stories.md`, `docs/prerequisites.md` were removed on 2026-08-11. Code,
config, infra and tests still cite them; the citation resolves to nothing —
recover from git history. Recreation follows "New documentation topics": explicit
human instruction, never agent judgement.
