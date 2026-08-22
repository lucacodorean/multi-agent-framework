---
name: tracker-intake
description: Normalize raw work-item input — Jira exports (CSV/JSON/XML), QA bug lists, BA feature requests, pasted tickets, screenshots, or informal lists — into a quality-gated intake document ready for task-orchestrator in PLAN mode. Use when the user shares tracker or similar raw work items and wants them normalized, cleaned, prepped, planned, or dispatched — "normalize these tickets", "run intake on this sprint", "prep these bugs for the orchestrator", "turn this export into a backlog", "feed these to task-orchestrator". If input looks like work items headed for orchestration, this skill runs first, before task-orchestrator.
---

# Tracker Intake

Turn raw § into a **normalized intake backlog**: one markdown document of *work items*, quality-gated, ready to hand to `task-orchestrator` in PLAN mode. This skill only transforms and validates. It never plans, routes, or dispatches. Where the document is stored, who may write it, and whether a later run replaces it are not this skill's job.

```
raw § → tracker-intake → orchestrator-ready document → task-orchestrator (PLAN)
```

## Items, never tasks

Everything this skill produces is an **item**, never a "task". The distinction is load-bearing:

- An *item* is a work statement with source truth attached — a bug report, a feature request, a change request. It preserves source granularity.
- A *task* is an orchestrator dispatch unit. One item may decompose into several tasks; several items may merge into one. That decomposition happens downstream, behind task-orchestrator's approval gate — never here.

Consequences, all non-negotiable:

- The word "task" does not appear in the intake document.
- No item is ever assigned route, model, effort, or wave. Severity and priority pass through as **priority signal** — input to the orchestrator's routing, not a routing decision made here. If tempted to note "this one's probably cheap/low", don't — the user approves routing economics at the orchestrator's gate, not by reading intake margins.
- The intake document must not be mistakable for an approved plan. Task-orchestrator's mode detection routes "already-structured task lists" to DISPATCH; a normalized backlog looks exactly like one. The doc therefore opens with an explicit PLAN-mode directive (baked into the doc template), which closes that hole deterministically.

## Step 0 — read project conventions

Project rules override skill defaults. Read `knowledge-base/framework/rules/documentation-governance.md`, `knowledge-base/framework/rules/doc-artifact-registry.md` and `project-context/docs-policy.md`, then check:

- **Path** — the intake entry in `{{docs.artifact_types[]}}`. The user may name another path, or none (emit inline only).
- **Who writes** — the `writer` on that entry. If it is not this session, do not write: emit the document in the reply and name the authorized writer.
- **Overwrite / retention** — not decided here. If docs or the user state a rule, follow it. If silent, persist only to a new path; do not overwrite an existing file.
- **Source conventions** — custom severity scales, component naming, issue-type mappings; `{{project.tracker.host}}` and `{{project.tracker.key_prefix}}`, and `project-context/glossary.md` for domain terms.

If no project rules are reachable (pure chat context), say so in one line and proceed with the defaults.

## Step 1 — parse the source

§ may be a Jira CSV/JSON/XML export, pasted ticket text, a screenshot, an informal markdown list, or a mix. Read `references/source-adapters.md` before parsing — it maps export formats to the item schema and defines status filtering, deduplication, epic/sub-task handling, and key-minting for keyless input.

Defaults (overridable by docs or the user): include only backlog-ready statuses; dedupe by source key; epics without children are gated, not normalized. Every filtering assumption goes in the doc header — don't ask, note.

## Step 2 — normalize each item

Classify each item as **bug**, **feature**, or **change**, then normalize it with the matching template from `references/item-templates.md` (read it before normalizing). Normalizing means: clean the content, mine buried facts (repro steps living in comment threads, acceptance criteria hidden in description prose), and strip tracker noise (status churn, watcher lists, sprint history) — while never inventing content. A field the source genuinely doesn't provide gets `—`, not a plausible guess: an invented repro step poisons everything downstream of it.

## Step 3 — quality gate

Each type has gate fields (marked ● in the templates). An item missing any of them goes to the **Needs clarification** section with its source key and exactly what's missing — and does not flow to orchestration.

Why gate here: task-orchestrator allows at most one clarification round before pushing assumptions into the plan. Incomplete tickets caught at intake go back to QA/BA as a concrete kick-back artifact; incomplete tickets that slip through become silent planning assumptions. The gate is mechanical — field present or absent — so it's checkable by anyone. Thin-but-present content passes with an inline `⚠ thin:` note; judging prose quality is not the gate's job.

## Step 4 — amendments and increments

BA work routinely arrives as increments over something previously stated. When an item amends or supersedes another:

- Link it: `amends: KEY` or `supersedes: KEY` in Relations.
- State the delta — never duplicate the predecessor's content.
- If the predecessor lives in an earlier intake document at the same location, list the pair under **Amendments** so the change is explicit even before anyone diffs.
- A superseded item still present in § is dropped from Ready items and noted under Amendments — one statement of intent per concern.

## Step 5 — emit the intake document

Fill `references/intake-doc-template.md` (read it before emitting). Non-negotiable — the orchestrator contract:

- The PLAN-mode directive is the first content.
- Items, never tasks; no routing.
- Items ordered by source key ascending; no timestamps outside the header.
- The header states where § came from and whether it can be re-fetched. Pick the matching source-of-truth line in the template so the artifact does not lie. That line is header honesty, not a storage policy.

Persist only if Step 0 produced an allowed path and this session may write it. Otherwise emit the same document in the reply. Do not invent a path, overwrite, or retention rule here.

## Step 6 — handoff gate

End every intake by presenting the counts (ready / needs clarification / amendments) and offering the handoff: run `task-orchestrator` with the intake document as §, in PLAN mode. Chaining in the same session is safe — PLAN ends at its own approval gate — but it is the user's call: never continue into orchestration unprompted, and never suggest or invoke DISPATCH directly from an intake document.

Traceability requirement at handoff: every source key must survive into the orchestration plan (in task descriptions or a dedicated Source column) so the run manifest can later be mapped back to the source. If the orchestrator's plan template carries no per-task source field, recommend adding a `Source` column once — the future write-back edge (dispatch results → source comments/transitions) depends on that ID chain existing end to end.

## Reference files

- `references/source-adapters.md` — parsing Jira CSV/JSON/XML, pasted text, keyless lists; status filters; dedup; epics and sub-tasks. Read before parsing.
- `references/item-templates.md` — bug / feature / change item templates, gate fields, normalization and content-mining rules. Read before normalizing.
- `references/intake-doc-template.md` — the exact output document format, including the PLAN-mode directive header and the summary table. Read before emitting.
