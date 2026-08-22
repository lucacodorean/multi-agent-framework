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

## 0. `knowledge-base/framework/**` is READ-ONLY (FI-25)

**Do not create, edit, move or delete any file under `knowledge-base/framework/`.** This binds
every agent, in every task, including the lead. It is not a preference and it is not waived by
a task that would be easier if you edited a rule.

A need that does not fit the core is answered in one of three places, in this order:

1. **A value that varies per project** → that project's context. That is what the contract is
   for (`knowledge-base/framework/contracts/project-context.schema.md`).
2. **Something the core does not do** → an extension beside the core, never inside it (FI-26):
   add or narrow, never restate, shadow or override.
3. **A defect in a rule** → report it and stop. It is a task for whoever maintains the core,
   not a local fix.

**Do not push a core change.** Every engineer and every vendored copy downstream inherits it,
so publishing one is a release, not an edit: it is announced to whoever consumes the core.

Deliberate core maintenance, when that is genuinely the task the human gave you:

```
knowledge-base/framework/bin/lock-core.sh unlock     # then edit
FRAMEWORK_UNLOCK=1 git commit ...                    # the hook logs what changed
FRAMEWORK_PUBLISH=1 git push ...                     # only when releasing it
knowledge-base/framework/bin/lock-core.sh lock       # always leave it locked
```

The rest of the knowledge base is writable: `knowledge-base/docs/` is where documentation about
the framework goes, and `knowledge-base/examples/` may gain or lose an example. Writable is not
the same as binding — an example never becomes a rule (FI-24).

This file is one of the enforcement layers, and the only one every agent reads. The others are
the filesystem lock, the `pre-commit` and `pre-push` hooks, per-host deny rules, and the
validator's report. None is absolute against an agent with a shell; editing the core *silently*
is the violation.

## 1. The other two rules that shape the repository

- **Paths inside the unit are knowledge-base-relative (FI-27).** A file under
  `knowledge-base/` cites `framework/rules/…`, never `knowledge-base/framework/rules/…`. Files
  outside the unit — this file, `README.md`, the mounted skills — use the full vendor path.
- **Examples bind nothing (FI-24).** `knowledge-base/examples/**` is read when a task names it
  and never becomes precedent. The validator does not read it unless told to.

## 2. Layout and ownership

| path | contents | writable by an agent |
|---|---|---|
| `knowledge-base/framework/` | the core | **no** (FI-25) |
| `knowledge-base/examples/` | worked instantiations | yes — but they bind nothing (FI-24) |
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

- Never push. Commit only on explicit request. A core change is never pushed as part of
  other work (§ 0).
- Destructive operations require an explicit user-approved task.
- Report outcomes faithfully — failures as failures, with output; skipped steps named as
  skipped.

## 5. Instantiating a project

`knowledge-base/README.md` § Vendoring into a host repository, then
`knowledge-base/framework/README.md` § Initializing a project. Instantiation writes the
project's context, its bindings, its index-and-law file and its convention files — never
anything under `knowledge-base/framework/`.
