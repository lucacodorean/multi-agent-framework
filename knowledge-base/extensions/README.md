# Extensions — index

The single index of everything added to the framework without editing it (FI-26). One row per
extension, added in the same change that adds the extension. An extension absent from this
table is untraceable and therefore a defect, not an extension.

## Is it an extension at all?

The three-way routing — context, extension, or a task for the core maintainer — is stated once,
in the host's index-and-law file at the repository root. Read it there. This section only says
which symptom lands in which branch, because the wrong branch is the common failure.

| what you have | where it goes |
|---|---|
| a value that differs per project — a path, a command, a member's ownership, a budget | **context**. `framework/contracts/project-context.schema.md` names the file and the key |
| a documentation kind the registry does not list | **context**. `docs.artifact_types` in `project-context/docs-policy.md` is canonical for the project; the registry only suggests. Not an extension |
| a rule the core does not state, that this project needs | **extension** — add it |
| a core rule that is too permissive here | **extension** — narrow it |
| a core rule that is wrong, or blocks the project as written | **neither.** Report it and stop. A rule you cannot satisfy is not a rule you route around |
| a core rule you want to restate "for visibility" | **neither.** One rule, one home (FI-01). Point at it |

An extension that needs the core to change is not an extension: it is a task for whoever
maintains the core.

## What an extension may do

| may | may not |
|---|---|
| **add** a rule, a role charter, a host adapter, an artifact kind, a placeholder | restate, shadow or override anything the core states |
| **narrow** an existing rule by pointing at it and adding a condition | edit any file under `framework/` (FI-25) |
| declare its own placeholders, documented in its own contract file | put a second copy of a core rule anywhere (FI-01) |

## The shapes, worked

Each shape below says what the extension file contains and what else must change. Nothing here
is a template to paste — the point is which files are involved.

### Add a rule

The core is silent on the subject and this project needs a ruling on it.

- The extension file states the rule and nothing else. Open by naming the core rule it sits
  **beside**, so a reader arriving from either direction sees both.
- Do not restate the neighbouring rule to give context. Cite its path and section.
- If the subject turns out to be one the core already rules on, this is not an addition — it is
  a narrowing, or it is a duplicate.

### Narrow a rule

The core rule holds, and this project needs it to hold more tightly.

- Name the core rule by path **and section**, then state the added condition. Only the
  condition is new text.
- A narrowing may only remove permission, never grant it. If the extension lets an agent do
  something the core forbids, it is an override, and overrides are prohibited.
- The core rule stays the rule. An agent reads the core first and the narrowing second, in that
  order, and a narrowing that only makes sense read first is written wrong.

### Add a roster member

`framework/roster.md` is core, so a new member is added here, never by editing it (FI-26).

The extension supplies the member's role charter, unless an existing one in `framework/roles/`
fits — reuse beats copying. Then, outside the extension:

- the member's ownership row goes in `project-context/ownership.md`, like every other member's;
- a binding is rendered per host mount point, from
  `framework/templates/agent-binding.md.template`.

**Known friction.** `framework/bin/validate-context.sh` check 3 parses members out of
`framework/roster.md`, so a binding for an extension member is reported as *"binds '<name>',
which is not a member of the standing roster"*. The binding is correct and the finding is
spurious. Note it in the extension's README so the next reader does not try to fix the binding.

### Add a host adapter

A harness the core does not carry an adapter for.

- The adapter satisfies `framework/contracts/host-adapter.schema.md` and lives in the
  extension, not in `framework/hosts/`.
- It records the mount points, binding frontmatter, and model and effort maps for that harness —
  and grants no permission posture, exactly as the contract says.
- Harness names appear only in adapters. An extension that spells a harness name in a rule has
  put a host fact in the wrong layer.

### Add a placeholder

Only when the extension's own rules consume it.

- Declare it in the extension's own contract file, in the shape
  `framework/contracts/project-context.schema.md` uses, and add it in the same change that
  first consumes it.
- Namespace it so it cannot collide with a core key.
- Supply it from a project context file, and say in the extension which file.

**Known friction.** The validator's placeholder checks (1 and 10) read core files only, so an
extension's placeholders are neither verified against its contract nor caught if one is left
unfilled. Nothing checks these but the reader.

## Layout of an extension

```
extensions/<name>/
  README.md      what it adds and why, the core rule it points at, and any known friction
  <files>        the added rules, roles, adapters or templates
```

The README is not optional. The index row says an extension exists; the README says what a
reader must know before obeying it.

## Putting one in force

Nothing here is loaded automatically. An extension is in force because a project's context or
the host's index-and-law file names it — the same way every other rule reaches an agent.

**Known gap.** There is no contract key for this today. `project-context.schema.md` declares no
`extensions` slot, so an extension's in-force declaration has no home the core consumes, and
nothing validates that a listed extension is actually reachable by an agent. Until a key exists,
name the extension in the host's index-and-law file — the one file every agent loads — and treat
this index as a record, not as an activation. Closing the gap is a core change: a contract key
plus the file that consumes it, in one change.

## Index

| extension | adds | path | narrows | declares | owner | added | status |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

Columns: **adds** — rule / role / host / artifact-kind / placeholder. **narrows** — the core
rule it points at, or `—` for a pure addition. **declares** — placeholders it introduces, or
`—`. **added** — date. **status** — `active` / `superseded by <extension>` / `retired`.

A retired extension keeps its row; the row is the traceability record. Never delete a row —
change its status.
