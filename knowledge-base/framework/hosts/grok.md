# Host adapter — Grok

Contract: `framework/contracts/host-adapter.schema.md`.

**Optional, and not built out.** This adapter is a placeholder: no `.grok/` bindings exist, and
every field below marked unrecorded must be filled before anything is rendered for this host.
Nothing in the framework depends on it.

## Mount points

| concept | path |
|---|---|
| agent bindings | `.grok/agents/<member>.md` |
| pipeline scripts | `.grok/workflows/` |

## Binding frontmatter

Project-configured; record it here before rendering bindings.

## Dispatch primitives

| framework concept | primitive |
|---|---|
| single member | `spawn_subagent` |
| deterministic pipeline | `agent()` / `parallel()` |

## Model map

| framework tier | host model |
|---|---|
| `cheap` | `grok-4.5` |
| `standard` | `grok-4.5` |
| `top` | `grok-4.6` |

## Effort map

| framework effort | field |
|---|---|
| `low` / `medium` / `high` | `reasoning_effort` |
| `xhigh` | `reasoning_effort: "xhigh"` on 4.6 only; clamp to `high` on 4.5 and note it |

Always pass `reasoning_effort`. Omitting it on 4.6 is a silent upgrade to Extra High.

## Capability gaps

- 4.5 has no `xhigh`.
- If a call rejects the effort field, drop the field, keep the prompt's effort guidance, and
  mark the forfeit in the manifest.

## Import syntax

None recorded.

## File I/O

Not recorded.
