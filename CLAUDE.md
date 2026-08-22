# CLAUDE.md — multi-agent framework

This repository develops the **knowledge base**: a project-agnostic multi-agent framework, its
worked example, and its documentation. It is not a project built with the framework.

```
knowledge-base/          the vendorable unit — copy this into a host repository
  framework/             the core: rules, roles, contracts, templates, host adapters  READ-ONLY
  examples/              worked instantiations, reference only, binding nothing
  docs/                  documentation about the knowledge base
.claude/skills/          framework-owned skills, mounted where the harness finds them
prompts/                 the prompts and analyses that produced the current shape
```

Read `knowledge-base/README.md` first, then
`knowledge-base/framework/rules/invariants.md` — those invariants are the acceptance criteria
for every change made here.

## 1. The three rules that shape the repository

- **The core is read-only (FI-25).** No agent edits `knowledge-base/framework/**`. A need that
  does not fit is answered in a project's context, or by an extension beside the core (FI-26),
  or by a task to whoever maintains the core. Enforcement is layered and reported by
  `knowledge-base/framework/bin/lock-core.sh`; deliberate core work is
  `lock-core.sh unlock` plus `FRAMEWORK_UNLOCK=1` on the commit. Editing the core *silently*
  is the violation.
- **Paths inside the unit are knowledge-base-relative (FI-27).** A file under
  `knowledge-base/` cites `framework/rules/…`, never `knowledge-base/framework/rules/…`. Files
  outside the unit — this file, `README.md`, the mounted skills — use the full vendor path.
- **Examples bind nothing (FI-24).** `knowledge-base/examples/**` is read when a task names it
  and never becomes precedent. The validator does not read it unless told to.

## 2. Layout and ownership

| path | contents | writable by an agent |
|---|---|---|
| `knowledge-base/framework/` | the core | **no** (FI-25) |
| `knowledge-base/examples/` | worked instantiations | no |
| `knowledge-base/docs/` | documentation about the knowledge base | yes |
| `.claude/skills/` | the four generic skills | yes — framework-owned content at a host mount point |
| `.claude/settings.json`, `.claude/statusline.sh` | operator configuration, not core | yes |
| `prompts/` | working material | yes |

Harness directories belong to the orchestrating agent of that name (FI-21). A harness discovers
agents and skills only at the repository root, so the unit cannot own those mount points —
`knowledge-base/framework/hosts/` records where each host looks.

## 3. Changing the framework

- Add a rule in exactly one file and point at it from everywhere it binds (FI-01).
- A new placeholder is added to the contract in the same change that first consumes it.
- A role charter gains a duty only if that duty holds for every project. Otherwise it belongs
  in a member record — `knowledge-base/framework/templates/project-context/roster.md`.
- A harness name appears only under `knowledge-base/framework/hosts/`.
- Run `knowledge-base/framework/bin/validate-context.sh` before reporting done. Validate an
  example only by naming its context directory.

## 4. Working agreement

`knowledge-base/framework/rules/working-agreement.md` binds work here too:

- Never push. Commit only on explicit request.
- Destructive operations require an explicit user-approved task.
- Report outcomes faithfully — failures as failures, with output; skipped steps named as
  skipped.

## 5. Instantiating a project

`knowledge-base/README.md` § Vendoring into a host repository, then
`knowledge-base/framework/README.md` § Initializing a project. Instantiation writes the
project's context, its bindings, its index-and-law file and its convention files — never
anything under `knowledge-base/framework/`.
