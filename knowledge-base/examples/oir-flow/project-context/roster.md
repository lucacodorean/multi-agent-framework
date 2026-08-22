# Roster — OIR Flow (ratified 2026-08-11)

Contract: `framework/contracts/project-context.schema.md` § roster.md. Rules:
`framework/rules/orchestration.md`, `framework/rules/rules-of-engagement.md`.

Every path maps to exactly one member (FI-05). Git-ignored artifacts (`vendor/`,
`node_modules/`, `storage/` runtime, `.env`, `engine/.venv`) follow the owner of their source
manifest. Harness directories (`.claude/**`, `.opencode/**`, any future `.<agent>/`) belong to
the orchestrating agent of that name — outside the roster, written by no member (FI-21).
`framework/**` is framework-owned; no member writes it.

## Topology

- `roster.tiers`: contract-owner → domain-engineer → data-engineer → platform-engineer
- `roster.side_contexts`: engine-engineer — reached_through: `contract/engine.openapi.yaml`
- `roster.outside_order`: code-reviewer, docs-agent

## Member — contract-owner

| field | value |
|---|---|
| `member.role` | boundary-owner |
| `member.tier` | 1 |
| `member.stack` | OpenAPI 3.1, AsyncAPI 3.0, Spectral |
| `member.owns` | `contract/**` |
| `member.carve_outs` | none |
| `member.verify` | `commands.contract_lint` |
| `member.conventions` | `conventions.code_level`, `conventions.structural` |
| `member.destructive` | none |

Duties:

1. `engine.openapi.yaml` is the platform ↔ engine seam: engine-engineer implements it,
   domain-engineer consumes it through the bridge client — neither edits it.
2. Rulings worth recording go to `docs/_intake.md` as ADR proposals for docs-agent.
3. Allocate advisory-lock ordinals before implementation from `app/Enums/AdvisoryLock.php`
   (`conventions.md` § Project-specific boundary facts).
4. The `ddev contract-lint` command belongs to platform-engineer; the ruleset content
   (`contract/.spectral.yaml`) is yours.

## Member — domain-engineer

| field | value |
|---|---|
| `member.role` | tier-member |
| `member.tier` | 2 |
| `member.stack` | Laravel ^13.5 on PHP ^8.5, Filament ^5 (two panels: `/console`, `/{tenant}`), Pest (`composer.json`) |
| `member.owns` | `app/**`, `routes/**`, `resources/**`, `public/**`, `bootstrap/**`, `tests/**` minus the carve-outs · the engine bridge client `app/Engine/**`, `app/Providers/EngineServiceProvider.php`, `config/engine.php` · `config/**` except `config/tenancy.php` · `composer.json`, `composer.lock`, `package.json`, `vite.config.js`, `artisan` |
| `member.carve_outs` | `app/Tenancy/**` → data-engineer · `app/Models/{Tenant,TenantLifecycleEvent,TenantMetricSnapshot}.php` → data-engineer · `app/Enums/TenantStatus.php` → data-engineer · `app/Providers/TenancyServiceProvider.php` → data-engineer · `app/Console/Commands/Tenants*.php` → data-engineer · `app/Http/Middleware/EnsureTenantIsAccessible.php` → data-engineer · `app/RiskRegister/Storage/**` → data-engineer · `tests/Feature/Tenancy/**` → data-engineer · `tests/Fixtures/tenant-migrations-broken/**` → data-engineer · `phpunit.xml`, `phpstan.neon` → platform-engineer |
| `member.verify` | `commands.test`, `commands.test_narrow`, `commands.style_check`, `commands.static_analysis` |
| `member.conventions` | `conventions.code_level`, `conventions.structural` |
| `member.destructive` | none |

Duties:

1. Own the two Filament panels: `/console` (central operators, guard `console`, `ConsoleUser`)
   and `/{tenant}` (tenant app, guard `web`). Panel styling and entry-point discipline:
   `conventions.structural`.
2. A module's `Storage/` subdirectory is the data tier's adapter — call the port, never the
   adapter class; the container binding stays in your service providers.
3. Express data needs downward as requirements routed through contract-owner; never design
   schemas, migrations or Redis structures yourself.
4. Every Office-file operation goes to the engine through the bridge client — the platform
   never opens an Office file. Act on `diffs_reproducere` cross-checks; the platform's
   determination is the authoritative one.
5. Run Pest from the repository root.

## Member — data-engineer

| field | value |
|---|---|
| `member.role` | tier-member |
| `member.tier` | 3 |
| `member.stack` | PostgreSQL 16 + Redis (`noeviction`), `stancl/tenancy` ^3.9, Eloquent, Laravel migration idiom |
| `member.owns` | `database/**` — central (`migrations/`) and tenant (`migrations/tenant/`) sets kept distinct, seeders, factories · `config/tenancy.php` · the tenancy mechanism carved out of `app/` and `tests/` (the carve-out list in domain-engineer's record) · adapters behind domain-declared ports, today `app/RiskRegister/Storage/**` · Redis key schemas, TTL policies, cache and queue usage patterns |
| `member.carve_outs` | none inbound; your carve-outs live inside domain-engineer's tree |
| `member.verify` | `commands.db_shell`, `commands.cache_shell`, `commands.tenant_drift_check`, `commands.test` |
| `member.conventions` | `conventions.code_level`, `conventions.structural` |
| `member.destructive` | `tenants:migrate-fresh`; `tenants:rollback` against shared data; `ddev redis-flush` |

Duties:

1. Serve the domain: requirements arrive as tasks through contract-owner; you translate them
   into schemas, migrations and Redis structures. The contract never leaks your table shapes.
2. PostgreSQL is the system of record; Redis is cache, ephemeral state and queue — never a
   second system of record. Redis runs `noeviction`, so every cache entry needs an explicit TTL.
3. Adapters raise only exception types declared on the domain-owned port. Before reporting,
   grep the tree for your adapter's exception namespace — any hit outside the adapter directory
   and your tests is a defect.
4. Migrations are forward-only. Destructive changes are flagged explicitly and never run
   against shared data without explicit user instruction. Keep seeders and factories in sync
   with every schema change.
5. Central/tenant migration discipline: `conventions.structural` § Central and tenant.

## Member — platform-engineer

| field | value |
|---|---|
| `member.role` | tier-member |
| `member.tier` | 4 |
| `member.stack` | DDEV type `laravel`, PHP 8.5 on nginx-fpm, docroot `public`, PostgreSQL 16, Redis (`noeviction`), Node 22, engine `python:3.12-slim` + `libreoffice-writer` |
| `member.owns` | `infra/**` minus the carve-out below — `infra/ddev/` (local source of truth), `infra/deploy/` (preview), `infra/shared/` (runtime-agnostic inputs), `infra/ci/` (gates), `infra/hooks/` · `.ddev/**` (generated; never hand-rolled) · the engine container: `infra/shared/engine/**`, `infra/deploy/engine/**`, compose services, base-image pins, `libreoffice-writer` · `.github/workflows/**` · root tooling: `phpunit.xml`, `phpstan.neon`, `captainhook.json`, `.editorconfig`, `.env.example`, `.gitattributes`, `.gitignore`, `.npmrc` |
| `member.carve_outs` | `infra/README.md` → docs-agent |
| `member.verify` | `commands.env_full_boot`, then: DB reachable, Redis PING with `maxmemory-policy noeviction`, engine healthy with a non-null `pdfBackend`; plus every gate in `ci.gates` |
| `member.conventions` | `conventions.code_level`, `conventions.structural`, plus the way DDEV expects a thing to be written |
| `member.destructive` | deleting Docker volumes or databases; `ddev delete` |

Duties:

1. Keep the baseline healthy and pinned. A floating service tag is a topology defect.
2. Keep bootstrap reproducible: fresh clone → `ddev start` → login-ready install via the
   post-start hook (`infra/ddev/hooks/dev-install.sh`, ending in `tenants:drift-check`). Any
   manual step you introduce is a bug.
3. Paved-path tooling runs in containers, never on the host. The gates need Docker and nothing
   else; the three container-heavy gates serialize on `infra/ci/lock.sh`.
4. The application inside the engine container is engine-engineer's: you provision, they
   implement.
5. Serve requests from other tiers arriving via contract-owner — fulfil, push back with
   reasons, or propose alternatives.

## Member — engine-engineer

| field | value |
|---|---|
| `member.role` | provider-context |
| `member.tier` | side |
| `member.reached_through` | `contract/engine.openapi.yaml` |
| `member.stack` | Python ≥3.12, FastAPI, Pydantic, uvicorn, pytest |
| `member.owns` | `engine/**` — the FastAPI app (`engine/app/`), routes (`engine/app/routes/`), the vendored prototype modules (`engine/vendor/` + `engine/app/vendored.py`), the dependency manifest (`engine/pyproject.toml`), templates, and the black-box test suite (`engine/tests/`) |
| `member.carve_outs` | the container and the Python lock both images build from (`infra/shared/engine/**`, `infra/deploy/engine/**`, `infra/shared/engine/requirements.txt`) → platform-engineer |
| `member.verify` | `commands.engine_test` |
| `member.conventions` | `conventions.code_level` § Comments (the one rule binding every language), FastAPI/Pydantic idiom |
| `member.destructive` | none |

Duties:

1. Perform every Office-file operation (`.xlsx`/`.docx`/`.pdf`) so the platform never opens an
   Office file: reading, extracting, transforming, generating, converting, structurally
   checking. Sampling decisions, archiving, notifications and the signature circuit are not
   yours.
2. Re-expose, never rewrite, the vendored prototype modules (`engine/vendor/modul_a_populatie`,
   `modul_b_nj`, and the `common` and `modul_pdf` trees) through `engine/app/vendored.py` —
   their validation against real data is the reason this context exists.
3. Return recomputations as `diffs_reproducere` and `auditEvents[]` in every response.
   Container-local JSONL is diagnostics only.
4. Match fields by semantic header name, never by position; ignore diacritics, case and edge
   whitespace; normalize fiscal codes before comparison.
5. Unimplemented routes answer 501 from `engine/app/routes/stubs.py` until built. The dev engine
   container has no hot reload.

## Member — code-reviewer

| field | value |
|---|---|
| `member.role` | code-reviewer |
| `member.tier` | outside |
| `member.stack` | reads the whole stack; writes none of it |
| `member.owns` | nothing — every path is read-only, `docs/_intake.md` included |
| `member.carve_outs` | none |
| `member.verify` | read-only inspection and read-only static analysis only |
| `member.conventions` | `conventions.code_level`, `conventions.structural`, `conventions.enforcement` |
| `member.destructive` | none; no mutating command at all |

Duties:

1. Report as `tracker-intake`-shaped item blocks; the lead hands them verbatim to docs-agent
   for persistence at the review paths in `docs.artifact_types`.
2. Attribute every finding to the owning member in this file so the lead can route it.

## Member — docs-agent

| field | value |
|---|---|
| `member.role` | docs-agent |
| `member.tier` | outside |
| `member.stack` | none |
| `member.owns` | `docs.write_paths` in `project-context/docs-policy.md`, and nothing else. Includes the carve-out `infra/README.md`; `CLAUDE.md` only on explicit human instruction |
| `member.carve_outs` | none |
| `member.verify` | budgets under `docs.metric`; every intake claim against its SOURCE |
| `member.conventions` | `framework/rules/documentation-governance.md`, `framework/rules/doc-artifact-registry.md` |
| `member.destructive` | truncating `docs/_intake.md` after a verified drain (routine, not destructive); deleting a living story whose scope is dropped |

Duties:

1. Writes no code. No other member writes documentation.
