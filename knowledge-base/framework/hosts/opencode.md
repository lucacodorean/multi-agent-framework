# Host adapter — opencode

Contract: `framework/contracts/host-adapter.schema.md`.

## Mount points

| concept | path |
|---|---|
| agent bindings | `.opencode/agents/<member>.md` |
| skills | not mounted — skills are not discovered by this harness |
| host dependencies | `.opencode/package.json` |

## Binding frontmatter

```yaml
---
description: <one line>      # required; carries routing text
mode: subagent               # required for a dispatched member
permission:                  # optional; the read-only expression
  edit: deny
---
```

No `tools:` field. Read-only enforcement is a `permission` map, not an allowlist. A `name:` key
is accepted and ignored — the filename is the identity.

## Dispatch primitives

| framework concept | primitive |
|---|---|
| single member | spawn a subagent of that binding |
| deterministic pipeline | none — sequence explicitly and record the sequence |
| a reviewer's delivery channel | the final response |

## Model map

Project-configured; state the mapping here when the project configures one.

## Effort map

Not exposed. Expand the assigned effort in the dispatch prompt as behaviour, and mark the
forfeit in the run manifest (FI-09).

## Instruction file

`AGENTS.md` at the repository root. State the core prohibition there for this host (FI-25); the
validator looks for it.

## Core protection

`permission: edit: deny` is per-binding, not per-path: it makes one agent read-only
everywhere, which is how the reviewer role is expressed here. A path-scoped equivalent is
unrecorded, so this host contributes no FI-25 layer of its own — the filesystem lock and the
commit hook carry it.

## Capability gaps

- No inter-agent messaging: a background member's outcome must be its final response.
- No pipeline primitive: FI-08's evidence gate must be enforced by the lead, explicitly.
- No skill discovery: work a skill would do must be inlined into the dispatch prompt.

## Import syntax

None. A binding that depends on an auto-import is broken here.

## File I/O

Local filesystem only.
