> **UNFILLED STUB.** Every `<…>` below must be supplied before this context is usable. Keys,
> shapes and consumers: `framework/contracts/project-context.schema.md` § roster.md. Blank form:
> `framework/templates/project-context/roster.md`.

# Roster

Every path in the repository maps to exactly one member (FI-05). Harness directories are outside
the roster (FI-21); `framework/**` is owned by no member and is read-only (FI-25).

## Topology

- `roster.tiers`: <ordered member names, highest tier first>
- `roster.side_contexts`: <member — reached_through: interface path, or none>
- `roster.outside_order`: <members standing outside the tier order>

## Member — <name>

| field | value |
|---|---|
| `member.role` | <a charter id from `framework/roles/`> |
| `member.tier` | <position, or `side` / `outside`> |
| `member.stack` | <technologies this member works in> |
| `member.owns` | <writable path globs> |
| `member.carve_outs` | <path → owning member> |
| `member.verify` | <command keys from commands.md> |
| `member.conventions` | <convention files binding this member> |
| `member.destructive` | <operations needing an approved task> |

Duties:

1. <duty>

One block per member. Until this file is filled there is no roster, and work is not routed.
