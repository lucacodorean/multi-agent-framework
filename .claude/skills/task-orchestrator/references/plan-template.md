# Plan template

Emit plans in exactly this structure. Keep prose tight — the table is the product.

```markdown
# Orchestration Plan: [short title]

## Source
[One or two lines: what § was — document name, pasted spec, verbal goal — and any project docs read in Step 0, including any doc rules that overrode skill defaults.]

## Assumptions & open questions
[Assumptions made instead of asking; open questions that don't block approval. If none: "None."]

## Tasks

| ID | Task | Source | Route | Model | Effort | Depends on | Wave | Acceptance criteria | Routing rationale |
|----|------|--------|-------|-------|--------|-----------|------|--------------------|-------------------|
| T1 | ...  | KEY \| — | workflow \| agent | haiku \| sonnet \| opus | low \| med \| high \| xhigh | — | 1 | [mechanically checkable] | [one line] |

## Waves

- **Wave 1** (parallel: n): T1, T2, T3
- **Wave 2** (parallel: n): T4, T5 — blocked on T1, T2
[Note the critical path: which chain of tasks determines total duration.]

## Risks & escalation
[Tasks most likely to fail or get re-routed, and what happens then. Reference the escalation rule; call out anything whose failure invalidates downstream waves.]

## Approval
Approving this plan authorizes dispatch of the tasks above, on the listed models and effort levels, wave by wave, [auto-continuing between waves / gating on you at each wave — per docs]. Reply with edits, or approve to dispatch.
```

Rules:

- Task descriptions in the table stay to one line; if a task needs a paragraph to describe, it is probably two tasks.
- Acceptance criteria must be checkable by someone (or some agent) who didn't do the work.
- Every routing cell gets a rationale — "sonnet/medium because standard implementation against a clear spec" is enough. The user is approving the economics, not just the work.
- IDs are stable: once a plan is presented, edits change rows but never renumber, so approval discussion can reference IDs safely.
- **Source** carries the tracker key(s) of the item(s) a task came from, verbatim — comma-separated when a task merges several items; the same key repeats across rows when one item decomposes into several tasks. Tasks with no tracker origin (goals stated in chat, work the decomposition itself created) get `—`. Every key present in § must appear in at least one row: that chain is what lets a run manifest be mapped back later to the item it came from. Minted keys (`ITEM-001`) are unique only inside their intake document, so cite them qualified — `2026-08-12-ba-scope#ITEM-001` — pointing at one intake document and one item in it.
