# CLAUDE.md — multi-agent framework

This repository develops the **knowledge base**: a project-agnostic multi-agent framework, its
worked example, and its documentation. It is not a project built with the framework.

```
knowledge-base/          the vendorable unit — copy this into a host repository
  framework/             the core: rules, roles, contracts, templates, host adapters  READ-ONLY
  project-context/       the instantiation: nine files resolving every placeholder  STUBS
  docs/                  the project's knowledge: conventions, decisions, intake, reviews
  extensions/            additions made without editing the core, and their index
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

The rest of the knowledge base is writable, and is where the work happens:

- `knowledge-base/docs/` — the project's knowledge: conventions, decision records, tracker
  intake, review reports, stories, business and domain material. Agents read here for
  information and write here to record it. The directories are in place and mostly empty; a
  file belongs to a declared kind with a declared path and lifecycle
  (`knowledge-base/framework/rules/doc-artifact-registry.md`), and summary, notes and handoff
  files are not a kind (FI-02).
  - `docs/conventions/engineering-principles.md` and `architecture-principles.md` are the two
    slots the framework mandates and never fills. Both are stubs today: filling them is project
    work, and every role charter points at them meanwhile.
- `knowledge-base/extensions/` — additions to the framework made without editing it, each
  listed in `knowledge-base/extensions/README.md` (FI-26).
- `knowledge-base/project-context/` — the nine files that resolve the core's placeholders.
  Stubs today; filling them is the first task of any project using this framework.

This file is one of the enforcement layers, and the only one every agent reads. The others are
the filesystem lock, the `pre-commit` and `pre-push` hooks, per-host deny rules, and the
validator's report. None is absolute against an agent with a shell; editing the core *silently*
is the violation.

## 1. The other two rules that shape the repository

- **`{{kb.root}}` is `knowledge-base/`.** That is the anchor, and this line is where an agent
  resolves it. A mounted skill or any other file outside the unit cites
  `{{kb.root}}/framework/…`; a file inside the unit cites `framework/…`, knowledge-base-relative
  (FI-27).
- **Example material is read-gated and binds nothing (FI-24).** There is none in this
  repository. Should any be added, it is opened only when the task prompt carries the grant
  `EXAMPLE-ACCESS:` naming what is needed from it — not to check a convention, not to copy a
  shape, not to settle an ambiguity in a rule. It never becomes precedent, and the validator
  does not read it unless told to.

## 2. Layout and ownership

| path | contents | writable by an agent |
|---|---|---|
| `knowledge-base/framework/` | the core | **no** (FI-25) |
| `knowledge-base/project-context/` | the instantiation the core consumes | yes |
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
