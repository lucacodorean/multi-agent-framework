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
`knowledge-base/framework/rules/…`. Files outside the unit cite `kb.root`, the anchor the
project declares once and the host's instruction file restates.

## The unit has a version

`framework/VERSION` — the version of the core, and the only thing a consumer can point at to say
which core it vendored. Publishing a core change bumps it; the `pre-push` hook refuses a core
change whose range leaves it untouched, so a release cannot go out unnamed.

Dated form, `YYYY-MM-DD`, because the release boundary is a publish and not a feature set. A
project that needs semantics beyond "newer than what I have" replaces the scheme — the mechanism
does not care what the string is, only that it changed.

## The core is read-only (FI-25)

No agent edits `framework/**`. A need that does not fit is answered in one of three places,
in this order:

1. **A value that varies per project** → the project context. That is what the contract is for.
2. **Something the core does not do** → an extension beside the core, never inside it (FI-26).
3. **A defect in a rule** → a task to whoever maintains the core. Not a local fix.

Publishing a core change is a second act beyond committing one: every engineer and every
vendored copy downstream inherits it, so it is a release and is announced as one.

Enforcement is layered, and each layer states what it actually stops:

| layer | stops | defeated by |
|---|---|---|
| the host's instruction file | any agent that loads instructions — the only layer every agent reads | an agent that ignores them |
| filesystem lock (`bin/lock-core.sh`) | every write, tool calls and shell alike | `lock-core.sh unlock` |
| `pre-commit` hook | the change landing in history | `FRAMEWORK_UNLOCK=1`, `--no-verify` |
| `pre-push` hook | the change reaching other engineers | `FRAMEWORK_PUBLISH=1`, `--no-verify` |
| per-host deny rules | tool calls at the path, and shell writes the host recognizes as writes — measured 2026-08-22: a `deny` entry refuses outright and never prompts | a write form the matcher does not recognize |
| validator check 6 | nothing — it reports the state of the others | nothing |

No layer is absolute against an agent with a shell; together they make a core edit deliberate
and visible rather than accidental, which is the achievable goal (FI-22). Editing the core
*silently* is the violation.

Deliberate core maintenance is a human act, not an agent's. `lock-core.sh unlock` lifts the
filesystem bit only: a host `deny` rule still refuses the write, and by design nothing an agent
can do lifts it. Someone with access to the host settings lifts the rule, or makes the edit
themselves. Then `FRAMEWORK_UNLOCK=1` on the commit, `FRAMEWORK_PUBLISH=1` on the release, and
`lock-core.sh lock` to leave it locked. Lifting a rule and not restoring it is how the guarantee
dies quietly.

The rest of the unit is writable, and is where the work happens: `docs/` holds the project's
knowledge — decision records, tracker intake, review reports, stories, business and domain
material — read by agents for information and written by them to record it; `extensions/` holds
additions made without editing the core, each in its index (FI-26); `project-context/` holds the
instantiation the core consumes. Example material, if any is ever kept, binds nothing and is
read-gated (FI-24).

## Extending without touching the core (FI-26)

An extension is a wrapper directory beside the core, listed in one index so that a rule lookup
stays a single lookup. It may **add** — a rule, a role, a host adapter, an artifact kind, a
placeholder — and may **narrow** an existing rule by pointing at it. It may not restate,
shadow or override anything the core states: that would put one rule in two files and break
FI-01.

No extension mechanism is built yet, and none should be until a second real case exists —
speculative machinery is exactly what the discipline in this framework rejects. The constraint
above is fixed now so the shape is not decided under pressure later.

## What a derived project changes

This unit is the starting point, and it is adapted from outside itself — never by editing it:

| surface | holds |
|---|---|
| `project-context/` | the values the core consumes: ownership, stack, commands, runtimes, gates, doc policy, conventions, glossary |
| `extensions/` | anything the core does not do — added rules, roles, adapters, artifact kinds, members (FI-26) |
| `docs/` | the project's own knowledge, written and read as the work proceeds |

Nothing else needs to change to stand a new project up, and nothing under `framework/` may
change to stand one up.

## The rule that makes this work

Core files carry placeholders, written `{{a.b}}`. Every placeholder resolves to exactly one entry in
`project-context/**`. A core file that states a project fact directly is a defect —
`framework/bin/validate-context.sh` fails on it.

## Layout

| path | holds | edited |
|---|---|---|
| `framework/contracts/` | the placeholder contract, the host-adapter contract, the agent-binding contract | by framework maintainers only |
| `framework/roster.md` | the standing roster: who exists, the tier order, each member's mandate | by framework maintainers only |
| `framework/rules/` | framework rules: invariants, orchestration, agent communication, engagement, working agreement, doc governance, artifact registry, CI gates, runtime topology | by framework maintainers only |
| `framework/roles/` | role charters — one per role kind, plus the shared standing orders | by framework maintainers only |
| `framework/hosts/` | one adapter per agent harness (Claude Code, opencode, Grok) | by framework maintainers only |
| `framework/templates/` | project-context templates, agent-binding template, `CLAUDE.md` template, workflow-script template | by framework maintainers only |
| `framework/VERSION` | the core's version — bumped when a core change is published | by framework maintainers only |
| `framework/bin/` | `validate-context.sh` (ten checks) and `lock-core.sh` (the read-only layers) | by framework maintainers only |
| the host's mounted skills | generic skills; they live at the **host repository root**, not in this unit, because a harness discovers them only there (`framework/hosts/`) | by framework maintainers only |
| `project-context/` | every value that changes between projects; created at instantiation — absent in the framework repository itself | **by the project** |
| `.claude/agents/`, `.opencode/agents/` | thin per-member bindings rendered from `framework/templates/agent-binding.md.template` | **by the project** |
| `docs/` | the project's knowledge, per the artifact registry | **by the project** |
| `extensions/<name>/` | additions made without editing the core, indexed in `extensions/README.md` | **by the project** |
| the host's index-and-law file, its code and its infrastructure | project artifacts outside the unit | **by the project** |

## Ownership

**Framework-owned** — roles, generic skills, orchestration, framework rules, contracts,
context templates, host adapters, the validator.

**Project-owned** — architecture, technology stack, repository structure, development
commands, testing strategy, infrastructure, deployment, coding conventions, the roster
membership, the agent bindings, `CLAUDE.md`.

Initializing a new project modifies project-owned artifacts only.

## Initializing a project

1. Copy `framework/templates/project-context/*.md` to `project-context/`.
2. Fill every placeholder. `framework/contracts/project-context.schema.md` lists each
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
