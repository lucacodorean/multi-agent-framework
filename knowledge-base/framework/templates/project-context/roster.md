# Roster — per-member ownership

Contract: `framework/contracts/project-context.schema.md` § roster.md.

Who exists, each member's charter and the tier order are **framework** facts:
`framework/roster.md`. This file supplies only what those members own **here**.

Every path in the repository maps to exactly one member (FI-05). Ownership follows what code
does, not where it lives. Harness directories are outside the roster (FI-21), and
`framework/**` is owned by no member and is read-only (FI-25). A member this project does not
need is left empty and is not dispatched; a member it adds comes from an extension (FI-26).

| `member.name` | `member.owns` | `member.carve_outs` | `member.stack` | `member.verify` | `member.destructive` |
|---|---|---|---|---|---|
| <member> | <writable path globs> | <path → owning member> | <technologies> | <command keys from commands.md> | <operations needing an approved task> |

`member.conventions` for every dispatched member: the two slots in `conventions.md`.

`roster.side_contexts`: <member — reached_through: interface path, or none>

## Outside the roster

Paths owned by the human maintainer and by no agent — the core, the harness directories, and
whatever else this project keeps out of the roster:

| path | why |
|---|---|
| `framework/**` | the core, read-only to every agent (FI-25) |
| <path> | <why> |

## `member.duties` — beyond the charter

One numbered list per member, for what this project requires that the charter does not already
say. Empty is valid: the charter is enough for most members on most projects.

### <member>
1. <duty>
