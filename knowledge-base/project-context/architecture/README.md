# Architecture

Contract: `framework/contracts/project-context.schema.md` § project.md, `project.architecture_dir`.

The system, independent of where it runs. **A directory, not a document:** on a real codebase the
architecture is never one file, so each area gets its own and this index says which.

Every claim cites its source path — never a copy of the source (FI-01). Ownership:
`project-context/ownership.md`. Budgets, where the project sets any, come from `docs.write_paths`
in `project-context/docs-policy.md`.

## What this directory must cover

Answer each row here in a paragraph, or delegate it to a file beside this one. Delegate when the
answer stops fitting in a paragraph — that is the whole rule for when to split.

| must cover | answered in | note |
|---|---|---|
| the deployable contexts, and what couples them | <file, or `here`> | one paragraph each, citing the manifest that pins its stack (`project-context/stack.md`) |
| what each boundary publishes | <file, or `here`> | the paths, formats, error model and versioning declared in `project-context/conventions.md` |
| the runtime map | <file, or `here`> | one row per entry in `project-context/runtimes.md`, each pointing at its topology document. Nothing here depends on which runtime is up (`framework/rules/runtime-topology.md`) |
| the layout | <file, or `here`> | one row per area, contents only — the owner is in `project-context/ownership.md`, not here |
| runtime behaviour | <file, or `here`> | the paths a request actually takes, each step citing the code that performs it. State what is NOT served as explicitly as what is |
| what the gates prove | <file, or `here`> | one row per entry in `project-context/ci.md` (`framework/rules/ci-gates.md`) |

## Files

One row per file in this directory. A file with no row here is undiscoverable, which is the same
as absent. `_area.md` is the form to copy for a new one; it is the form itself, so it gets no row.

| file | area |
|---|---|
| <file> | <area> |

## What does not belong here

- Class, method and module discipline — those are the two convention slots named in
  `project-context/conventions.md`.
- Ownership of a path. It is declared once, in `project-context/ownership.md` (FI-05).
- Boot and command detail — `project-context/commands.md` and `project-context/runtimes.md`.
- Anything the framework already states: a rule holding for every project is a framework rule,
  and restating it here puts one rule in two files (FI-01).
