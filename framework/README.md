# Framework core

A project-agnostic multi-agent operating system. Nothing here names a project, a language, a
framework, a service or a command.

```
Framework Core   (framework/**, .claude/skills/**)
      ↓ consumes
Project Context  (project-context/**)
      ↓ describes
Project Artifacts (CLAUDE.md, docs/**, infra/**, the codebase)
```

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
| `.claude/skills/` | generic skills; host-mounted because the harness discovers them there | by framework maintainers only |
| `project-context/` | every value that changes between projects; created at instantiation — absent in the framework repository itself | **by the project** |
| `.claude/agents/`, `.opencode/agents/` | thin per-member bindings rendered from `framework/templates/agent-binding.md.template` | **by the project** |
| `examples/<project>/` | one worked instantiation, read-only reference | nobody — it binds nothing |
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

A worked instantiation to compare against: the example under `examples/` (see the repository README).

## Reading order for an agent

`framework/rules/invariants.md` first — it is the acceptance criteria for everything else.
Then your own role charter, then `project-context/`.
