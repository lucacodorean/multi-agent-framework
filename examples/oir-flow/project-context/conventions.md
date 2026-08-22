# Conventions and boundary — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § conventions.md.

| key | value |
|---|---|
| `conventions.code_level` | `docs/conventions/engineering-principles.md` |
| `conventions.structural` | `docs/conventions/architecture-principles.md` |

## Boundary

| key | value |
|---|---|
| `conventions.boundary.interface_paths` | `contract/**` — `openapi.yaml` (system REST), `engine.openapi.yaml` (platform ↔ engine seam), `asyncapi.yaml` (events), `.spectral.yaml` (ruleset) |
| `conventions.boundary.formats` | OpenAPI 3.1 ×2, AsyncAPI 3.0 |
| `conventions.boundary.error_model` | RFC 9457 problem details; `.spectral.yaml` enforces at error severity; platform half is `app/Engine/Problem.php`, `ProblemMapper.php` |
| `conventions.boundary.versioning` | semver in `info.version`; the contract file is the single source of the seam version and it is never restated elsewhere (ADR-0025). A prose-only correction leaves it unchanged |

## Project-specific boundary facts

- The engine is a bounded context, not a platform layer: stateless, tenancy-unaware, reached
  only through `contract/engine.openapi.yaml`. Seam detail: `docs/document-engine-bridge.md`.
- The platform never opens an Office file; `app/Engine/**` is the only path in. Absence does not
  prove it — `openspout/openspout` ships transitively via `filament/actions`. What holds and is
  tested: no spreadsheet package is declared in `composer.json` and no spreadsheet, zip or XML
  reader is named in any import source
  (`tests/Feature/RiskRegister/ContractImportSeamBoundaryTest.php`).
- `X-Correlation-Id` is opaque to the engine.
- The engine computes, the platform decides: recomputations return as `diffs_reproducere`; a
  non-empty diff is the platform's error to raise. The engine returns `auditEvents[]`; the
  platform persists them tenant-side.
- Ports and adapters: a `Storage/` subdirectory inside a domain module is the data tier's
  adapter behind a domain-declared port. Canonical example: `app/RiskRegister/Storage/**`
  implements `App\RiskRegister\RiskIndexSourceRepository`; refusals are
  `App\RiskRegister\Exceptions`, never adapter-namespace types.
- Advisory-lock ordinals come from the contract-owner before implementation, from the registry
  `app/Enums/AdvisoryLock.php`; 5..65535 are free (ADR-0033).
- `config/` is owned per file, never as a directory.

## Enforcement

`conventions.enforcement` (FI-22):

| convention | enforced by |
|---|---|
| style | Pint, in the static-analysis gate |
| types, undefined calls, dead branches | PHPStan/Larastan level 5, same gate |
| decision-record citations in source | the adr-citations gate |
| boundary shape and error model | the contract gate (Spectral) |
| `declare(strict_types=1)` | nothing |
| whether a comment earns its place | nothing mechanical — the roles point at the convention, and code-reviewer reports an unearned comment as a finding |
| `docs/conventions/architecture-principles.md` as a whole | nothing: no arch test, no deptrac, no custom analyser rule, no CI script inspecting imports. It holds by review and roster write permissions. Adjacent checks exist and are named in that file |
| ownership boundaries | roster write permissions and review, not tooling |
