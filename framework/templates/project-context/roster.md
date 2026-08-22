# Roster

Contract: `framework/contracts/project-context.schema.md` § roster.md. Rules:
`framework/rules/orchestration.md`, `framework/rules/rules-of-engagement.md`.

Every path in the repository maps to exactly one member (FI-05). Harness directories are
outside the roster and belong to the agent of that name (FI-21).

## Topology

- `roster.tiers`: <ordered member names, highest tier first>
- `roster.side_contexts`: <member — reached_through: interface path>
- `roster.outside_order`: <members standing outside the tier order>

## Member — <name>

| field | value |
|---|---|
| `member.role` | <a charter id from `framework/roles/`> |
| `member.tier` | <position, or `side` / `outside`> |
| `member.stack` | <technologies this member works in> |
| `member.owns` | <writable path globs> |
| `member.carve_outs` | <path → owning member, for paths inside `owns` that are not yours> |
| `member.verify` | <command keys from commands.md> |
| `member.conventions` | <convention files binding this member> |
| `member.destructive` | <destructive operations specific to this member> |

Duties — numbered, binding as the charter:

1. <duty>

Repeat one block per member.
