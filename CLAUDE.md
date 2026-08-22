# CLAUDE.md — OIR Flow

Multi-tenant CR/CP sampling platform: a Laravel platform and a stateless Python document
engine, coupled only through `contract/`. Code is the source of truth. This file is the
index and the law; canonical docs hold the depth.

## 1. Repository layout

Canonical: `docs/architecture.md`. Owners: ratified roster, ch. 2. Platform ↔ engine seam:
`docs/document-engine-bridge.md`.

| path | contents | owner |
|---|---|---|
| `contract/` | OpenAPI 3.1 ×2, AsyncAPI 3.0, `.spectral.yaml` — the only coupling point | contract-owner |
| `app/` `routes/` `resources/` `public/` `bootstrap/` `tests/` | Laravel platform: domain, two Filament panels, Pest suite — minus data carve-outs (ch. 2) | domain-engineer |
| `app/Engine/` | engine bridge client (consumer half of the seam) | domain-engineer |
| `database/` | central + tenant migrations (`migrations/tenant/`), factories, seeders | data-engineer |
| `app/Tenancy/` + carve-outs | schema-per-tenant mechanism living where Laravel puts it | data-engineer |
| `config/` | owned per file: `tenancy.php` data; `engine.php` and the rest domain | per file |
| `engine/` | stateless FastAPI document engine, black-box tests, vendored prototype modules | engine-engineer |
| `infra/` | runtime-agnostic inputs (`infra/shared/`), per-runtime sources of truth (`infra/ddev/`, `infra/deploy/`), CI gate scripts (`infra/ci/`) — minus the docs carve-out (ch. 2) | platform-engineer |
| `.ddev/` `.github/` | generated DDEV config; five CI workflows | platform-engineer |
| `.claude/` `.grok/` | harness directories — one per orchestrating agent (Claude, Grok) | the named agent |
| `CLAUDE.md` `docs/` `infra/README.md` | active documentation | docs-agent |
| root tooling | `phpunit.xml` `phpstan.neon` `captainhook.json` dotfiles → platform; `composer.json` `package.json` `vite.config.js` `artisan` → domain | per file |

## 2. Team roster (ratified 2026-08-11)

Canonical: this chapter. Every path maps to exactly one owner; git-ignored artifacts
(`vendor/`, `node_modules/`, `storage/` runtime, `.env`, `engine/.venv`) follow the owner
of their source manifest. Harness directories (`.claude/**`, `.grok/**`, any future
`.<agent>/`) belong to the orchestrating agent of that name — outside the roster; no
member writes them; each agent writes only its own.

| member | owns (writes) | everything else |
|---|---|---|
| contract-owner | `contract/**` | readonly |
| domain-engineer | `app/**` `routes/**` `resources/**` `public/**` `bootstrap/**` `tests/**` minus data carve-outs · `config/**` minus `tenancy.php` · `composer.json` `composer.lock` `package.json` `vite.config.js` `artisan` | readonly |
| data-engineer | `database/**` · `config/tenancy.php` · carve-outs: `app/Tenancy/**`, `app/Models/{Tenant,TenantLifecycleEvent,TenantMetricSnapshot}.php`, `app/Enums/TenantStatus.php`, `app/Providers/TenancyServiceProvider.php`, `app/Console/Commands/Tenants*.php`, `app/Http/Middleware/EnsureTenantIsAccessible.php`, `app/RiskRegister/Storage/**`, `tests/Feature/Tenancy/**`, `tests/Fixtures/tenant-migrations-broken/**` | readonly |
| engine-engineer | `engine/**` | readonly |
| platform-engineer | `infra/**` minus the carve-out `infra/README.md` · `.ddev/**` · `.github/**` · `phpunit.xml` `phpstan.neon` `captainhook.json` `.editorconfig` `.env.example` `.gitattributes` `.gitignore` `.npmrc` | readonly |
| docs-agent | `docs/**` per governance whitelist · carve-out: `infra/README.md`; `CLAUDE.md` only on explicit human instruction | readonly |

Tier order: contract-owner → domain-engineer → data-engineer → platform-engineer.
engine-engineer is a provider bounded context beside the tiers, reached only through
`contract/engine.openapi.yaml` (`.claude/agents/engine-engineer.md`).

## 3. Rules of engagement (non-negotiable)

Canonical: `docs/conventions/rules-of-engagement.md`. Code-level discipline:
`docs/conventions/engineering-principles.md`. Structural discipline:
`docs/conventions/architecture-principles.md`.

- Contract-first across members: no cross-member dependency without an agreed contract
  (interface, schema, or API definition) before implementation.
- Tier direction holds between members.
- Cross-tier work coordinates via tasks/messages through the contract-owner — never by
  directly editing another member's files.

## 4. Working agreement

Canonical: `docs/conventions/working-agreement.md`.

- Members are fully autonomous within their task.
- Never push to git.
- Commit only on explicit request.
- Destructive operations require an explicit user-approved task.

## 5. Orchestration model

Canonical: `docs/conventions/orchestration.md`.

- Route most build work through the roster.
- Use the `Workflow` tool for deterministic multi-member orchestration.
- Track cross-member work as tasks/messages.
- Use worktree isolation when members mutate files in parallel within the same tier.
- Model & effort are assigned at dispatch time, not in agent definitions.
- The lead integrates results, verifies against contract, and reports to the user.

## 6. Environment & commands

Canonical: `docs/runbook.md` — every command, per runtime, with its verification status.
This file names no command; read them there.

- Runtime contents and ports: local `docs/topology/local.md`, preview
  `docs/topology/preview.md`. CI host: `docs/ci/gitlab.md`.
- Host needs Docker plus the CLI of the runtime being used; every tool runs in a container.
- Gate set and its rules: `docs/architecture.md` § CI — gates.
- Gate serialization on a machine: `docs/runbook.md` § CI gates.
- Verify a topology change by a full boot of that runtime, never a restart.

## 7. Documentation governance

Canonical: `docs/conventions/documentation-governance.md`.

@docs/conventions/documentation-governance.md

- Every agent is a worker by default; workers never write `.md` — their only channel is
  appending to `docs/_intake.md`.
- The docs-agent is the sole doc writer, inside the whitelist that governance holds
  (§ Allowed write paths — the only copy); `CLAUDE.md` only on explicit human
  instruction.
- `docs/stories/as-reference/` is read-forbidden without a `HISTORY-ACCESS:` grant in the
  task prompt, and writable by no one (`docs/stories/README.md`).