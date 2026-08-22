# Source adapters

How to get from raw § to parseable items. Whatever the format, the output of parsing is the same: a set of candidate items with source key, type, and raw content, ready for normalization.

## Status filter (all sources)

Default: include only backlog-ready statuses; exclude everything already moving or finished.

- **Include:** Open, To Do, Backlog, Reopened, Ready, Selected for Development (and local equivalents)
- **Exclude:** In Progress, In Review, Done, Closed, Resolved, Won't Fix, Duplicate, Cannot Reproduce

Rationale: items already in flight shouldn't be re-planned by the orchestrator, and finished items aren't work. Project docs or an explicit user instruction override this. Whatever filter ends up applied is recorded in the doc header under **Filters applied** — the reader must be able to see why an item they expected is absent.

If § carries no status information (informal lists, pasted fragments), everything is included and the header notes `no status data in source`.

## Jira CSV export

Column mapping (Jira repeats multi-value columns — collect all of them):

| CSV column | Item field |
|---|---|
| Issue key | Source key |
| Issue Type | Type (see mapping below) |
| Summary | Title (verbatim) |
| Description | Type-block content (flatten wiki markup) |
| Priority / Severity (custom) | Priority signal |
| Component/s (repeated) | Component(s) |
| Status | Status filter input |
| Reporter, Created, Updated | Source line |
| Inward/Outward issue link (repeated) | Relations |
| Comment (repeated) | Content mining input |

## Jira REST JSON

Per issue: `key`; `fields.issuetype.name`; `fields.summary`; `fields.description` (ADF or wiki markup — flatten to markdown); `fields.priority.name` and any severity custom field; `fields.components[].name`; `fields.status.name`; `fields.reporter.displayName`; `fields.created` / `fields.updated`; `fields.issuelinks[]` (use `type.inward`/`type.outward` wording + linked key); `fields.parent.key` for sub-tasks; `fields.comment.comments[]` for mining.

## Jira XML (RSS export)

Per `<item>`: `key`, `type`, `summary`, `description` (HTML — strip tags), `priority`, `status`, `component`, `link`. Comments under `<comments>`.

## Pasted / free text and screenshots

- Recognize source keys by pattern `[A-Z][A-Z0-9]+-\d+` anywhere in the text.
- Ticket boundaries: keys, horizontal rules, numbered/bulleted top-level entries, or obvious heading changes.
- Screenshots of boards or tickets: transcribe what is visible; anything cut off is simply absent (`—`), never inferred.

## Keyless input

Informal lists ("QA found these five things: …") get minted keys: `ITEM-001`, `ITEM-002`, … in first-seen order. Minted keys are unique **within their document only** — a later run may mint `ITEM-001` again for something unrelated.

- Inside the document, cite the bare key.
- Outside it — plan rows, manifests, chat, commit messages — cite it qualified with the document stem: `2026-08-12-ba-scope#ITEM-001`. That form resolves to exactly one item in exactly one intake document, with no counter state to maintain.
- The doc header carries the note: `minted keys — unique within this document; cite as <document-stem>#KEY outside it`.
- A minted key is never reassigned. If a later run covers an item already emitted, it reuses that item's existing key rather than renumbering.

Where the project does keep an upstream tracker, minted keys stay a stopgap: replace them with real keys before any write-back.

## Type mapping

| Source type | Intake type |
|---|---|
| Bug, Defect | bug |
| Story, New Feature | feature |
| Improvement, Change Request | change if it references prior work (link or explicit mention), else feature |
| Task (Jira's) | by content: defect-shaped → bug; references prior work → change; else feature |
| Epic | not an item — see below |
| Sub-task | own item with `parent: KEY` relation |

## Epics and sub-tasks

- **Epic with child issues present in §:** intake the children; the epic key appears only as grouping context in the children's Relations (`parent: EPIC-KEY`). An epic is a container, not a work statement.
- **Epic without children in §:** goes to Needs clarification — `missing: child issues (epic is a container; intake its children, or provide a scoped brief)`. Normalizing an epic as one mega-item smuggles decomposition into intake, which belongs to the orchestrator.
- **Sub-tasks** keep tracker granularity: each is its own item with a `parent` relation. Whether they merge back into one dispatch unit is the orchestrator's call, made behind its approval gate.

## Deduplication

- Dedupe by source key across the whole of § (mixed formats included); keep the version with the latest `updated`.
- Tracker-flagged duplicates (`Duplicate` link or status) keep only the canonical issue; the duplicate key is noted in the canonical item's Relations (`duplicates: KEY`).
- Near-duplicates without tracker linkage (two tickets, same defect, different words) are **not** merged silently — both stay, each with `⚠ possible duplicate of KEY`. Merging intent is a tracker-owner decision, not an intake decision.
