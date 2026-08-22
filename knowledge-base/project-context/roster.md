# Roster — per-member ownership

Who exists, each member's charter and the tier order are framework facts:
`framework/roster.md`. This file supplies only what those members own **here**.

Every path maps to exactly one owner (FI-05). Ownership follows what code does, not where it
lives. A member this project does not need is left empty and is not dispatched; a member it adds
comes from an extension (FI-26).

## What this project is, and what follows from it

The product **is** the framework core, and the core is read-only to every agent (FI-25). So four
of the seven members have no writable area here and are not dispatched — not because the roster
is wrong, but because this project has no domain code, no stored state, no runtime and no
provider context. The clause in `framework/roster.md` that permits an empty member is exercised,
not assumed.

| member | owns | carve-outs | stack | verify | destructive |
|---|---|---|---|---|---|
| `contract-owner` | `project-context/**`, `extensions/**` | — | Markdown; the contract in `framework/contracts/` | `commands.test` | — |
| `domain-engineer` | — not dispatched: the product is the core, and the core is read-only | — | — | — | — |
| `data-engineer` | — not dispatched: nothing is stored | — | — | — | — |
| `platform-engineer` | — not dispatched: there is no runtime, and the harness directories are outside the roster (FI-21) | — | — | — | — |
| `engine-engineer` | — not dispatched: there is no provider context | — | — | — | — |
| `code-reviewer` | nothing — every path is read-only, `docs/_intake.md` included | — | reads Bash and Markdown | read-only inspection only | none |
| `docs-agent` | `docs.write_paths` in `docs-policy.md` | — | — | budgets under `docs.metric` | — |

`conventions` for every dispatched member: `docs/conventions/engineering-principles.md` and
`docs/conventions/architecture-principles.md` — both stubs; a member reads them and finds the
slot described rather than filled.

`roster.side_contexts`: none — `engine-engineer` exists in the standing roster and has no
instance here.

## Outside the roster

Owned by the human maintainer, by no agent:

| path | why |
|---|---|
| `framework/**` | the core, read-only to every agent (FI-25); changed only as a deliberate human act |
| `../prompts/**` | the inputs work arrives as, and the deliverables they produced |
| `../.claude/**`, `../.opencode/**` | harness directories, one per orchestrating agent (FI-21). The bindings inside them are generated (`runtimes.generated_dirs`); the settings and statusline are operator configuration |

## Duties beyond the charter

### contract-owner

1. The contract you own is `framework/contracts/project-context.schema.md`, and it is core: you
   cannot edit it. A placeholder that needs adding, renaming or removing is a task for whoever
   maintains the core — raise it, do not work around it.
2. Keep `project-context/**` and the contract in step. A key filled here that the contract does
   not name, or a key the contract names and nothing fills, is a defect the validator reports as
   a finding.
3. Own the extension index (`extensions/README.md`): every extension has a row before it has
   users, and a retired extension keeps its row (FI-26).

### docs-agent

1. This project's documentation is about the framework itself — how to instantiate it, why a
   rule is shaped the way it is, what a review found. Its rules are core and are never edited
   from here (FI-25); a rule that needs changing goes back as a task.
2. The two convention slots are stubs. Filling them is project work and needs a human naming
   what goes in them (FI-20); do not invent a code-level convention for a project whose only
   code is shell.
