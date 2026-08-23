# Knowledge base

The vendorable unit: a project-agnostic multi-agent framework, the stub context that
instantiates it, and its own documentation. Copy this directory into a host repository, keep it
at `knowledge-base/`, and update it as a whole.

| path | holds | writable |
|---|---|---|
| `framework/` | the core — rules, roles, contracts, templates, host adapters, scripts | **no** (FI-25) |
| `docs/` | the project's knowledge: decision records, tracker intake, review reports, stories, business and domain material | yes — this is where agents read and record |
| `extensions/` | additions to the framework made without editing it, and their index | yes (FI-26) |
| `project-context/` | the instantiation: every value the core consumes | yes — stubs until filled |
| `docs/_intake.md` | the doc-impact channel every agent but the doc writer reports through | append only |

## Standing up a derived project

This unit is the starting point for any project. It is adapted from outside itself, never by
editing it:

| surface | what it decides |
|---|---|
| `project-context/` | ownership, stack, commands, runtimes, gates, doc policy, conventions, glossary |
| `extensions/` | anything the core does not do — added rules, roles, adapters, artifact kinds, members (FI-26) |
| `docs/` | the project's own knowledge, read and written as work proceeds |

The team itself is not per-project: `framework/roster.md` holds the standing roster, and the
bindings that make its members dispatchable are rendered per host at the repository root.

## Where the anchor points

`{{kb.root}}` resolves to this directory, written `./knowledge-base/`. It is stated once in the project's context
(`kb.root`) and restated in the host's instruction file, so an agent that meets
`{{kb.root}}/framework/rules/...` in a mounted skill can resolve it without opening the
context. Files *inside* the unit never use the anchor — they are knowledge-base-relative
(FI-27).

## Three rules that govern the unit

**Example material is read-gated (FI-24).** There is none here. Should any be added, it is
opened only when the task prompt carries the grant `EXAMPLE-ACCESS:` naming what is needed from
it — never to check a convention or copy a shape. Writable, readable and binding are three
separate properties.

**Paths are knowledge-base-relative (FI-27).** Every citation in every file here resolves from
this directory, never from the repository root and never absolutely. That is what makes the
unit relocatable: vendor it anywhere and no citation changes. The scripts under
`framework/bin/` locate the unit from their own path for the same reason.

**The core is read-only (FI-25).** A need that does not fit the core is answered in the
project's context, or by an extension beside the core (FI-26), or by a task to whoever
maintains the core — never by editing `framework/`. Install and inspect the enforcement with
`framework/bin/lock-core.sh`; the host's instruction file carries the prohibition for every
agent that loads instructions.

Publishing a core change is a separate deliberate act from committing one: every engineer and
every vendored copy downstream inherits it, so it is a release and is announced as one
(`FRAMEWORK_PUBLISH=1`). Everything else in this unit is writable — `docs/` is where
documentation about the framework goes.

## Vendoring into a host repository

1. Copy this directory to `knowledge-base/` at the host repository root. The path is a
   convention, not a preference: files outside the unit cite it by that name.
2. **Check `project-context/`, and replace it wholesale** from
   `framework/templates/project-context/` if it holds anything but stubs. The reference copy
   ships as stubs, so there is nothing to undo; a copy taken from a derived project carries that
   project's filled context — filled values look authoritative, and inheriting someone else's are
   worse than starting from stubs. Note the core version you vendored (`framework/VERSION`) while
   you are here.
3. Run `knowledge-base/framework/bin/lock-core.sh lock` — a fresh copy starts unlocked, and
   the filesystem lock is not carried by version control.
4. Instantiate: `framework/README.md` § Initializing a project.
5. Copy the framework-owned skills to the host's mount points at the **host repository root**,
   not inside this unit — a harness discovers agents and skills only there (`framework/hosts/`),
   which is why they are not part of the unit. Take them from the maintenance repository
   (`.claude/skills/`, and the equivalent per host); instantiation renders the bindings itself.
   **The unit alone is not the whole delivery:** without this step the framework has no skills.
6. Verify: `knowledge-base/framework/bin/validate-context.sh <context-dir>`.

## Updating a vendored copy

Unlock, replace `framework/` wholesale, re-copy the skills to their mount points, re-lock, and
record the new `framework/VERSION`. The skills are core content held outside the unit, so an
update that skips them leaves half a core. Local divergence in `framework/` is not an
update path — it is the thing FI-25 exists to prevent. Anything the host needs that the core
does not do belongs in an extension beside the core (FI-26).
