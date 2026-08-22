# Extensions — index

The single index of everything added to the framework without editing it (FI-26). One row per
extension, added in the same change that adds the extension. An extension absent from this
table is untraceable and therefore a defect, not an extension.

## What an extension may do

| may | may not |
|---|---|
| **add** a rule, a role charter, a host adapter, an artifact kind, a placeholder | restate, shadow or override anything the core states |
| **narrow** an existing rule by pointing at it and adding a condition | edit any file under `framework/` (FI-25) |
| declare its own placeholders, documented in its own contract file | put a second copy of a core rule anywhere (FI-01) |

An extension that needs the core to change is not an extension: it is a task for whoever
maintains the core.

## Index

| extension | adds | path | narrows | declares | owner | added | status |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

Columns: **adds** — rule / role / host / artifact-kind / placeholder. **narrows** — the core
rule it points at, or `—` for a pure addition. **declares** — placeholders it introduces, or
`—`. **added** — date. **status** — `active` / `superseded by <extension>` / `retired`.

A retired extension keeps its row; the row is the traceability record. Never delete a row —
change its status.

## Layout of an extension

```
extensions/<name>/
  README.md      what it adds and why, and the core rule it points at
  <files>        the added rules, roles, adapters or templates
```

Nothing here is loaded automatically. An extension is in force because a project's context or
the host's instruction file names it — the same way every other rule reaches an agent.
