# Intake document template

Emit intake documents in exactly this structure. The persist path, its writer and its lifecycle come from the intake entry in `{{docs.artifact_types[]}}` via SKILL.md Step 0, not from this template; `<scope>` in that pattern is the sprint, filter or team — short, kebab-case.

```markdown
> **Directive to task-orchestrator:** This is a normalized intake backlog, **not an approved plan**.
> Process in **PLAN mode**: decompose items into tasks, assign routing, and stop at the approval gate.
> Entries below are work items preserving source granularity — they are not dispatch units.

# Intake: [scope — e.g. Sprint 14 QA + BA]

**Generated:** 2026-08-12T14:30+03:00
**Source:** [exact JQL / filter / export file name / "pasted export"]
**Source of truth:** [tracker-backed: the tracker — this file is a generated snapshot, stale the moment the tracker moves; regenerate, never hand-edit. | transit: the inbound statement captured below — no upstream tracker holds it; this file is the durable transit record, retained for traceability; supersede it with a later document, never rewrite it.]
**Filters applied:** [status filter and any other assumption made during parsing]
**Counts:** N ready · M needs clarification · K amendments

## Ready items

[Items per references/item-templates.md, ordered by source key ascending.]

## Needs clarification — not forwarded to orchestration

[Failed-gate items: common block + whatever content exists, plus:]
- **Missing:** [exact gate fields absent]
- **Kick back to:** [reporter / team]

[If none: "None."]

## Amendments

[One line per amendment pair: "KEY-2 supersedes KEY-1 — KEY-1 dropped from Ready items." or
"KEY-3 amends KEY-1 (in 2026-08-01-sprint-13-intake.md) — delta only, see item." If none: "None."]

## Intake summary

| Key | Type | Priority signal | Component(s) | Gate |
|-----|------|-----------------|--------------|------|
| KEY | bug \| feature \| change | as stated | … | ready \| needs-clarification |
```

## Rules

- **The directive block is always the first content of the file.** It is what prevents task-orchestrator's mode detection from mistaking this document for a dispatchable task list. Never omit or soften it.
- **Ordering is by source key ascending, everywhere** (Ready items, Needs clarification, summary table). Stable order + stable formatting = a git diff of two intakes shows only real backlog changes.
- **No timestamps outside the header.** Item-level dates come from the tracker (created/updated), which is fine; generation-time data appears once, in the header, so re-runs don't create diff noise.
- **The summary table lists every item once**, gate status included — it's the at-a-glance view and the completeness check (table row count = header counts).
- **The word "task" never appears below the directive block.** Items, throughout. (The directive itself addresses the orchestrator and legitimately names tasks and PLAN mode — that's its job.)
- **No routing content anywhere** — no model names, effort levels, routes, or waves. If the source ticket itself contains routing opinions ("this is a quick cheap-tier job"), they are tracker noise: strip them.
- Superseded items appear only in Amendments, not in Ready items.
- **Pick the source-of-truth line by where the content came from.** Re-derivable input (an export, a query result) → the tracker-backed / snapshot line. Input that exists nowhere else (a pasted statement, a verbal decision, a screenshot) → the transit / sole-record line. The line describes the artifact so the next reader does not treat a paste like an export. It does not authorize overwrite or deletion.
