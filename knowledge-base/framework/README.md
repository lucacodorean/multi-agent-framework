# Framework core

A project-agnostic multi-agent operating system. Nothing here names a project, a language, a
framework, a service or a command.

```
Framework Core   framework/**  +  the host's mounted skills
      ↓ consumes
Project Context  project-context/**
      ↓ describes
Project Artifacts  the host repository's index, docs and code
```

Paths in this unit are knowledge-base-relative (FI-27): `framework/rules/…`, never
`knowledge-base/framework/rules/…`. Files outside the unit reach in by the vendor path.

## The core is read-only (FI-25)

No agent edits `framework/**`. A need that does not fit is answered in one of three places,
in this order:

1. **A value that varies per project** → the project context. That is what the contract is for.
2. **Something the core does not do** → an extension beside the core, never inside it (FI-26).
3. **A defect in a rule** → a task to whoever maintains the core. Not a local fix.

Enforcement is layered — filesystem lock, commit hook, per-host deny rules, and the
validator's report. `framework/bin/lock-core.sh` installs and reports it. None of the layers
is absolute against an agent with a shell; together they make a core edit deliberate and
visible rather than accidental, which is the achievable goal (FI-22). Editing the core
*silently* is the violation.

## Extending without touching the core (FI-26)

An extension is a wrapper directory beside the core, listed in one index so that a rule lookup
stays a single lookup. It may **add** — a rule, a role, a host adapter, an artifact kind, a
placeholder — and may **narrow** an existing rule by pointing at it. It may not restate,
shadow or override anything the core states: that would put one rule in two files and break
FI-01.

No extension mechanism is built yet, and none should be until a second real case exists —
speculative machinery is exactly what the discipline in this framework rejects. The constraint
above is fixed now so the shape is not decided under pressure later.

## The rule that makes this work

Core files carry `{{placeholders}}`. Every placeholder resolves to exactly one entry in
`project-context/**`. A core file that states a project fact directly is a defect —
`framework/bin/validate-context.sh` fails on it.

## Layout

| path | holds | edited |
|---|---|---|
| `framework/contracts/` | the placeholder contract, the host-adapter contract, the agent-binding contract | by framework maintainers only |
| `framework/rules/` | framework rules: invariants, orchestration, engagement, working agreement, doc governance, artifact registry, CI gates, runtime topology | by framework maintainers only |
| `framework/roles/` | role charters — one per role kind, plus the shared standing orders | by framework maintainers only |
| `framework/hosts/` | one adapter per agent harness (Claude Code, opencode, Grok) | by framework maintainers only |
| `framework/templates/` | project-context templates, agent-binding template, `CLAUDE.md` template, workflow-script template | by framework maintainers only |
| `framework/bin/` | `validate-context.sh` — contract completeness + core purity | by framework maintainers only |
| the host's mounted skills | generic skills; they live at the **host repository root**, not in this unit, because a harness discovers them only there (`framework/hosts/`) | by framework maintainers only |
| `project-context/` | every value that changes between projects; created at instantiation — absent in the framework repository itself | **by the project** |
| `.claude/agents/`, `.opencode/agents/` | thin per-member bindings rendered from `framework/templates/agent-binding.md.template` | **by the project** |
| `examples/<project>/` | one worked instantiation, read-only reference | nobody — it binds nothing (FI-24) |
| `CLAUDE.md`, `docs/**`, `infra/**` | project artifacts | **by the project** |

## Ownership

**Framework-owned** — roles, generic skills, orchestration, framework rules, contracts,
context templates, host adapters, the validator.

**Project-owned** — architecture, technology stack, repository structure, development
commands, testing strategy, infrastructure, deployment, coding conventions, the roster
membership, the agent bindings, `CLAUDE.md`.

Initializing a new project modifies project-owned artifacts only.

## Initializing a project

1. Copy `framework/templates/project-context/*.md` to `project-context/`.
2. Fill every `{{placeholder}}`. `framework/contracts/project-context.schema.md` lists each
   one, its shape, and which core file consumes it.
3. Render `CLAUDE.md` from `framework/templates/CLAUDE.md.template`.
4. Render one binding per roster member into each host directory the project uses, from
   `framework/templates/agent-binding.md.template` and the host's adapter.
5. Write the project-owned convention files the context names
   (`conventions.code_level`, `conventions.structural`) — the framework mandates the slot,
   never the content.
6. Run `framework/bin/validate-context.sh`.

An example instantiation, where one is present, can be validated the same way by naming its
context directory. It is a demonstration, never a source of rules (FI-24).

## Reading order for an agent

`framework/rules/invariants.md` first — it is the acceptance criteria for everything else.
Then your own role charter, then `project-context/`.
