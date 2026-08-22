# Host adapter — Claude Code

Contract: `framework/contracts/host-adapter.schema.md`.

## Mount points

| concept | path |
|---|---|
| agent bindings | `.claude/agents/<member>.md` |
| skills | `.claude/skills/<name>/SKILL.md` (+ `references/`) |
| pipeline scripts | `.claude/workflows/` |
| plans and run manifests | `.claude/plans/` |
| host settings | `.claude/settings.json` |

The harness discovers bindings and skills only at these paths; that is why framework-owned
skills live under `.claude/` rather than under `framework/`.

## Binding frontmatter

```yaml
---
name: <member.name>          # required; also the subagent_type
description: <one line>      # required; the lead routes on this text
tools: <comma-separated>     # optional allowlist; omit to grant the default set
model: <alias>               # omit — assigned at dispatch (FI-09)
---
```

Read-only enforcement is expressed as a `tools:` allowlist (no write tools listed), not as a
permission map.

## Dispatch primitives

| framework concept | primitive |
|---|---|
| single member, discovery work | `Agent` with `subagent_type: <member.name>`, `name:` for continuity |
| continue a running member | `SendMessage` to that name |
| named teammates, emerging shape | `Agent` + `SendMessage`, tracked with `TaskCreate` / `TaskList` |
| deterministic pipeline | `Workflow` — script with `meta`, `phase()`, `agent()`, `parallel()`, `pipeline()` |
| isolated working copy | `isolation: "worktree"` on the dispatch |
| a reviewer's delivery channel | `SendMessage` to the lead |

## Model map

| framework tier | host model |
|---|---|
| `cheap` | the host's haiku alias |
| `standard` | the host's sonnet alias |
| `top` | the host's opus alias |

## Effort map

| framework effort | field |
|---|---|
| `low` / `medium` / `high` | `effort:` on `Workflow`'s `agent()` |
| `xhigh` | clamp to `high`; note the clamp in the run manifest |

## Capability gaps

- Verified 2026-08-11: `Agent` exposes `model` only — per-stage effort is reachable through
  `Workflow` alone. A dispatch that forfeits an intended effort assignment says so at dispatch.
  Re-verify before relying on this.
- Permission mode is inherited by dispatched agents and is not overridable per dispatch:
  confirm write permission is in force before dispatching writers (FI-08).

## Import syntax

`@path/to/file.md` on its own line inside a discovered file auto-loads that file. Inert text on
every other host — never make a rule depend on it.

## File I/O

Local filesystem only. Input files arrive at paths the user names; there is no upload directory.

## Instruction file

`CLAUDE.md` at the repository root, auto-loaded for every session and every dispatched agent.
This is where the core prohibition is stated for this host (FI-25) — the only enforcement layer
every agent reads. The validator checks that it carries the rule.

## Core protection

Path-scoped deny rules in the harness settings are this host's layer of FI-25 — entries of the
form `Edit(<core>/**)` and `Write(<core>/**)` under `permissions.deny`.

- UNVERIFIED (2026-08-22): whether a deny rule still binds when `permissions.defaultMode` is
  set to a bypassing mode. Verify before relying on this layer alone.
- Known gap: deny rules match tool calls. A write performed through `Bash` — a heredoc, a
  stream editor in place — does not go through `Edit` or `Write` and is not matched. The
  filesystem lock is the layer that covers it (`framework/bin/lock-core.sh`).

## Permission posture

`.claude/settings.json` is operator configuration, not framework core. The framework grants no
posture: whether agents run unattended is a project and operator decision, recorded with the
project.
