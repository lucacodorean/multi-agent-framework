# CLAUDE.md — OIR Flow

Multi-tenant CR/CP sampling platform: a Laravel platform and a stateless Python document
engine, coupled only through `contract/`. Code is the source of truth. This file is the index
and the law; canonical documents hold the depth.

The multi-agent system is split in two. **Framework core** (`framework/`, `.claude/skills/`)
is project-agnostic and carries `{{placeholders}}`. **Project context**
(`project-context/`) resolves every placeholder. Read `framework/README.md` once, then
`framework/rules/invariants.md` — those 23 invariants govern everything below.

## 1. Repository layout

Canonical: `docs/architecture.md`. Ownership: `project-context/roster.md`. Platform ↔ engine
seam: `docs/document-engine-bridge.md`.

| path | contents | owner |
|---|---|---|
| `framework/` | framework core — roles, rules, contracts, templates, host adapters, validator | framework maintainers; no member writes it |
| `project-context/` | every value the core consumes: identity, roster, stack, commands, runtimes, CI, docs policy, conventions, glossary | the roster collectively, by human ruling |
| `contract/` | OpenAPI 3.1 ×2, AsyncAPI 3.0, `.spectral.yaml` — the only coupling point | contract-owner |
| `app/` `routes/` `resources/` `public/` `bootstrap/` `tests/` | Laravel platform: domain, two Filament panels, Pest suite — minus data carve-outs | domain-engineer |
| `database/` · `app/Tenancy/` + carve-outs · `config/tenancy.php` | migrations, factories, seeders, the schema-per-tenant mechanism | data-engineer |
| `engine/` | stateless FastAPI document engine, black-box tests, vendored prototype modules | engine-engineer |
| `infra/` `.ddev/` `.github/` | runtime sources of truth, CI gate scripts, generated DDEV config — minus `infra/README.md` | platform-engineer |
| `.claude/` `.opencode/` | harness directories — one per orchestrating agent; skills and bindings live here because the harness discovers them there | the named agent |
| `CLAUDE.md` `docs/` `infra/README.md` | active documentation | docs-agent |
| root tooling | `phpunit.xml` `phpstan.neon` `captainhook.json` dotfiles → platform; `composer.json` `package.json` `vite.config.js` `artisan` → domain | per file |

## 2. Roster

Canonical: `project-context/roster.md` — members, tier order, ownership paths, carve-outs,
duties, proof commands. Stated there and nowhere else (FI-01, FI-05).

Tier order: contract-owner → domain-engineer → data-engineer → platform-engineer.
engine-engineer is a provider bounded context beside the tiers, reached only through
`contract/engine.openapi.yaml`. code-reviewer and docs-agent stand outside the order.

## 3. Rules of engagement (non-negotiable)

Canonical: `framework/rules/rules-of-engagement.md`. Project boundary facts:
`project-context/conventions.md`. Code-level discipline:
`docs/conventions/engineering-principles.md`. Structural discipline:
`docs/conventions/architecture-principles.md`.

- Contract-first across members: no cross-member dependency without an agreed contract
  before implementation.
- Tier direction holds between members.
- Cross-tier work coordinates via tasks/messages through the contract-owner — never by
  directly editing another member's files.

## 4. Working agreement

Canonical: `framework/rules/working-agreement.md`. Commands and the destructive list:
`project-context/commands.md`.

- Members are fully autonomous within their task.
- Never push to git. Commit only on explicit request.
- Destructive operations require an explicit user-approved task.

## 5. Orchestration model

Canonical: `framework/rules/orchestration.md`. Harness spellings — dispatch primitives, model
and effort maps, capability gaps: `framework/hosts/`.

- Route most build work through the roster.
- Deterministic multi-member work runs as a pipeline, not hand-sequenced dispatches.
- Track cross-member work as tasks/messages; isolate working copies when same-tier members
  write in parallel.
- Model and effort are assigned at dispatch, never pinned in a binding.
- The lead integrates results, verifies against the published contract version, and reports.

## 6. Environment & commands

Canonical: `docs/runbook.md` — every command, per runtime, with its verification status. The
key set is `project-context/commands.md`; runtimes are `project-context/runtimes.md`; gates are
`project-context/ci.md`. This file names no command.

- Runtime contents and ports: `docs/topology/local.md`, `docs/topology/preview.md`. CI host:
  `docs/ci/gitlab.md`.
- Host needs Docker plus the CLI of the runtime being used; every tool runs in a container.
- Verify a topology change by a full boot of that runtime, never a restart.

## 7. Documentation governance

Canonical: `framework/rules/documentation-governance.md`; project values (whitelist, budgets,
artifact types, read gates): `project-context/docs-policy.md`; lifecycles:
`framework/rules/doc-artifact-registry.md`.

@framework/rules/documentation-governance.md

- Every agent is a worker by default; workers never write `.md` — their only channel is
  appending to `docs/_intake.md`.
- The docs-agent is the sole doc writer, inside the whitelist that
  `project-context/docs-policy.md` holds (§ Allowed write paths — the only copy); `CLAUDE.md`
  only on explicit human instruction.
- `docs/stories/as-reference/` is read-forbidden without a `HISTORY-ACCESS:` grant in the task
  prompt, and writable by no one (`docs/stories/README.md`).
