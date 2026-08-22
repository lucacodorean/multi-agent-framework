# Documentation governance

Framework rule. Project values: `project-context/docs-policy.md`. Artifact shapes:
`framework/rules/doc-artifact-registry.md`.

## Roles

Two, determined by the task prompt and nothing else.

- **Doc writer** (`{{docs.sole_writer}}`) — only if the task prompt contains the exact line
  `{{docs.role_gate_line}}` (FI-03).
- **Worker** — every other agent. If unsure, you are a worker.

## Worker rules

- Never create, modify or delete a documentation file — no exception for a small update, a
  README, or a file you created earlier in the same session (FI-02).
- No summary, progress, notes, changelog, TODO or handoff file. Report in the final response.
  Creating a documentation file is a task failure even if the task succeeded.
- Work that invalidates, contradicts or should extend a doc is not fixed by the worker: append
  a doc-impact entry to `{{docs.worker_channel}}`. That is the only file a worker may touch,
  append-only — never edit or remove an existing entry.
- Reading documentation is always allowed, except paths listed in `{{docs.read_gated[]}}`,
  which need their stated grant present in the task prompt.

### Doc-impact entry format

```
## [<date>] <task-id or branch>
- AFFECTS: <path of doc, or "none — new topic">
- CHANGE: <one line: what is now true that the doc does not say, or says wrongly>
- SOURCE: <file or commit that proves it>
```

One entry per distinct fact. No prose beyond the three lines.

## Doc-writer charter

Invoked only at orchestration checkpoints, under the role gate. Sole doc writer.

### Allowed write paths

`{{docs.write_paths[]}}` — canonical there and nowhere else. Writing outside it is a task
failure. A path granted in any other file is not a grant (FI-01).

The host's index-and-law file is deliberately outside that list: it is writable only when the
human's instruction for **this** invocation explicitly says so. It is the file every agent
loads, so an unrequested edit to it changes how every future session behaves.

### Procedure per invocation

1. Read `{{docs.worker_channel}}`. Each entry is a claim: verify it against its SOURCE before
   acting (FI-04).
2. Merge verified changes into the canonical tree in place. No parallel or versioned copies.
3. Create, update or delete the living-story artifacts the registry defines for verified story
   impact. Do not skip this because the dispatch brief omitted it.
4. An entry conflicting with an existing rule: leave the doc untouched, write no marker, and
   cite both sides in the response for human decision.
5. Truncate `{{docs.worker_channel}}` to empty, keeping the file. Processed entries live in
   version history, not an archive.
6. Report: docs touched, artifacts written, entries merged, entries rejected with reason, open
   conflicts.

### Writing rules

- Terse directives. Imperative voice. One rule per line.
- Each rule lives in exactly one file; other files point at it (FI-01).
- Reference source files by path; never embed code, schemas or output — copies rot.
- At most one canonical example per convention.
- No history, narration or rationale — current state only. Rationale that must survive goes
  into a decision record.
- Do not invent rules. Record decisions made by workers' verified changes or by the human. The
  doc writer does not make policy.
- Documentation is written in `{{project.docs_language}}`; acceptance criteria stay in
  `{{project.input_language}}`.

### Budgets

Count tokens as `{{docs.metric}}`. No other metric counts. Per-file allowances:
`{{docs.write_paths[]}}`, with `{{docs.budget_grace}}` tokens of tolerance before an overrun is
a finding. On overrun beyond that, FI-18: compress first, and report rather than force.

## Removed documents

A document removed from the tree is recorded — what was removed, on what date, and that it is
recoverable from version history. The project's list lives with its policy
(`project-context/docs-policy.md`).

The record exists because code, configuration, tests and other documents keep citing a file
after it is gone, and the citation then resolves to nothing. Recording the removal turns a
dangling citation into an explanation instead of a mystery, and stops the next agent recreating
the file from inference. Recreation follows the rule below: explicit human instruction, never
agent judgement.

## New documentation topics

FI-20. A new file needs an explicit human instruction naming it, except where
`{{docs.artifact_types[]}}` records a standing authorization and names the file that grants it.
Workers never request a new file — they file an intake entry with `AFFECTS: none — new topic`.
