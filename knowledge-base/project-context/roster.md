> **UNFILLED STUB.** Ownership below must be supplied before work is routed. Keys and shapes:
> `framework/contracts/project-context.schema.md` § roster.md.

# Roster — per-member ownership

Who exists, each member's charter and the tier order are framework facts:
`framework/roster.md`. This file supplies only what those members own **here**.

Every path in the repository maps to exactly one member (FI-05). Ownership follows what code
does, not where it lives. Harness directories are outside the roster (FI-21), and
`framework/**` is owned by no member and is read-only (FI-25). A member this project does not
need is left empty and is not dispatched; a member this project adds comes from an extension
(FI-26).

| member | owns | carve-outs | stack | verify | destructive |
|---|---|---|---|---|---|
| `contract-owner` | <interface paths> | — | <interface formats, linter> | <command keys> | — |
| `domain-engineer` | <path globs> | <path → owner> | <languages, frameworks> | <command keys> | — |
| `data-engineer` | <path globs> | <path → owner> | <stores, ORM> | <command keys> | <operations> |
| `platform-engineer` | <path globs> | <path → owner> | <runtimes, services> | <command keys> | <operations> |
| `engine-engineer` | <path globs> | <container paths → platform-engineer> | <language, framework> | <command keys> | — |
| `code-reviewer` | nothing — every path is read-only | — | reads the whole stack | read-only inspection only | none |
| `docs-agent` | `docs.write_paths` in `docs-policy.md` | — | — | budgets under `docs.metric` | — |

`conventions` for every member: `docs/conventions/engineering-principles.md` and
`docs/conventions/architecture-principles.md` — both stubs until filled.

`roster.side_contexts`: `engine-engineer` — reached_through: <interface path>

## Duties beyond the charter

One numbered list per member, for what this project requires of it that the charter does not
already say. Empty is valid: the charter is sufficient for most members on most projects.

### contract-owner
1. <duty>

### domain-engineer
1. <duty>

### data-engineer
1. <duty>

### platform-engineer
1. <duty>

### engine-engineer
1. <duty>
