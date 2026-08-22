# Knowledge base

The vendorable unit: a project-agnostic multi-agent framework, one worked example of it, and
its own documentation. Copy this directory into a host repository, keep it at
`knowledge-base/`, and update it as a whole.

| path | holds | writable |
|---|---|---|
| `framework/` | the core — rules, roles, contracts, templates, host adapters, scripts | **no** (FI-25) |
| `examples/` | worked instantiations, reference only | no — binds nothing (FI-24) |
| `docs/` | documentation about this knowledge base | yes |

## Two rules that govern the unit

**Paths are knowledge-base-relative (FI-27).** Every citation in every file here resolves from
this directory, never from the repository root and never absolutely. That is what makes the
unit relocatable: vendor it anywhere and no citation changes. The scripts under
`framework/bin/` locate the unit from their own path for the same reason.

**The core is read-only (FI-25).** A need that does not fit the core is answered in the
project's context, or by an extension beside the core (FI-26), or by a task to whoever
maintains the core — never by editing `framework/`. Install and inspect the enforcement with
`framework/bin/lock-core.sh`.

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
