# CLAUDE.md — multi-agent framework

This repository is the **framework itself**, not a project built with it. It ships a
project-agnostic multi-agent operating system and the templates that instantiate it.

```
Framework Core   framework/**, .claude/skills/**   placeholders only, no project facts
      ↓ consumes
Project Context  project-context/**                created at instantiation, not present here
      ↓ describes
Project          the adopting repository
```

Read `framework/README.md` first, then `framework/rules/invariants.md` — those invariants
are the acceptance criteria for every change made here.

## 1. Layout

| path | contents | rule |
|---|---|---|
| `framework/rules/` | invariants, orchestration, engagement, working agreement, doc governance, artifact registry, CI gates, runtime topology | each rule lives in exactly one file; others point at it (FI-01) |
| `framework/roles/` | role charters + the one shared standing-orders block | a charter states duties, never a project's paths or stack |
| `framework/contracts/` | the project-context contract, the host-adapter contract, the agent-binding contract | the contract is the only list of placeholders |
| `framework/templates/` | project-context templates, `CLAUDE.md`, agent binding, pipeline script, artifact templates | what an adopting project copies and fills |
| `framework/hosts/` | one adapter per harness — the only files allowed to name a harness | capability claims carry the date they were verified |
| `framework/bin/` | `validate-context.sh` | run it before reporting any change here as done |
| `.claude/skills/` | generic skills: `task-orchestrator`, `tracker-intake`, `docs-compaction`, `user-stories-use-cases` | host-mounted because the harness discovers them there; framework-owned |
| `examples/*/` | worked instantiations, read-only reference | binds nothing, is never precedent, and is read only when the task names it (FI-24) |
| `prompts/` | the prompts and analyses that produced this split | working material |

`.claude/settings.json` and `.claude/statusline.sh` are operator configuration, not core.

## 2. The rule that makes this work

A core file carries `{{placeholders}}`; every placeholder resolves to exactly one entry in
`framework/contracts/project-context.schema.md`. A project name, path, version, command or
domain term stated directly in a core file is a defect (FI-23) — `validate-context.sh` fails
on it.

## 3. Changing the framework

- Add a rule in exactly one file and point at it from everywhere it binds.
- A new placeholder is added to the contract in the same change that first consumes it.
- A role charter gains a duty only if that duty holds for every project. Otherwise it belongs
  in a member record — `framework/templates/project-context/roster.md`.
- A harness name appears only under `framework/hosts/`.
- Run `framework/bin/validate-context.sh` before reporting done. Where an example
  instantiation is present, validate it too by naming its context directory — the validator
  never reads an example unless told to (FI-24).

## 4. Working agreement

`framework/rules/working-agreement.md` binds work here too:

- Never push. Commit only on explicit request.
- Destructive operations require an explicit user-approved task.
- Report outcomes faithfully — failures as failures, with output; skipped steps named as
  skipped.

## 5. Instantiating a project

The six steps in `framework/README.md` § Initializing a project. Instantiation writes
`project-context/**`, one binding per member per host, the index-and-law file, and the two
project-owned convention files — and nothing under `framework/`.
