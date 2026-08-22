# Knowledge base

The vendorable unit: a project-agnostic multi-agent framework, one worked example of it, and
its own documentation. Copy this directory into a host repository, keep it at
`knowledge-base/`, and update it as a whole.

| path | holds | writable |
|---|---|---|
| `framework/` | the core — rules, roles, contracts, templates, host adapters, scripts | **no** (FI-25) |
| `docs/` | the project's knowledge: decision records, tracker intake, review reports, stories, business and domain material | yes — this is where agents read and record |
| `extensions/` | additions to the framework made without editing it, and their index | yes (FI-26) |
| `project-context/` | the instantiation: every value the core consumes | yes — stubs until filled |

## Where the anchor points

`{{kb.root}}` resolves to this directory. It is stated once in the project's context
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
2. Run `knowledge-base/framework/bin/lock-core.sh lock` — a fresh copy starts unlocked, and
   the filesystem lock is not carried by version control.
3. Instantiate: `framework/README.md` § Initializing a project.
4. Mount the host's harness directories at the **host repository root**, not inside this unit —
   a harness discovers agents and skills only there (`framework/hosts/`). The unit holds the
   canonical skills; the mount is where the harness reads them.
5. Verify: `knowledge-base/framework/bin/validate-context.sh <context-dir>`.

## Updating a vendored copy

Unlock, replace `framework/` wholesale, re-lock. Local divergence in `framework/` is not an
update path — it is the thing FI-25 exists to prevent. Anything the host needs that the core
does not do belongs in an extension beside the core (FI-26).
