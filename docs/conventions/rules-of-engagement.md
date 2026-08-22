# Rules of engagement

Canonical depth behind `CLAUDE.md` ch. 3. The three core rules live there; this file holds
the boundary mechanics the codebase encodes.

## Boundary mechanics

- Publish before building: every cross-member interface (REST path, payload, event, error
  shape) exists in `contract/` before implementation. Semver in `info.version`.
- `info.version` versions the interface, not the file: a prose-only correction to a
  published contract leaves it unchanged (its code pins would otherwise move for no
  consumer-visible change — ADR-0025).
- Error model on every boundary: RFC 9457 problem details (`contract/.spectral.yaml`
  enforces at error severity; platform half: `app/Engine/Problem.php`, `ProblemMapper.php`).
- Tier membership follows what code does, not where it lives: the tenancy mechanism inside
  `app/` and `tests/` is data-tier (carve-out list: `CLAUDE.md` ch. 2).
- `config/` is owned per file, never as a directory (`config/tenancy.php` data,
  `config/engine.php` domain).
- Ports and adapters: a `Storage/` subdirectory inside a domain module is the data tier's
  adapter behind a domain-declared port. Domain code calls the port, never the adapter
  class. The port's failure vocabulary is domain-owned: adapters raise only exception types
  declared on the interface, living in the domain namespace. Canonical example:
  `app/RiskRegister/Storage/**` implements `App\RiskRegister\RiskIndexSourceRepository`;
  its refusals are `App\RiskRegister\Exceptions`, not adapter-namespace types.

## The engine seam

- The engine is a bounded context, not a platform layer: stateless, tenancy-unaware,
  reached only through `contract/engine.openapi.yaml`.
- The platform never opens an Office file; `app/Engine/**` (bridge client) is the only
  path in. Absence does not prove it — `openspout/openspout` is a hard requirement of
  `filament/actions` and ships in `vendor/` regardless. What holds and is tested: this
  platform declares no spreadsheet package in `composer.json` and names no spreadsheet,
  zip or XML reader in any import source
  (`tests/Feature/RiskRegister/ContractImportSeamBoundaryTest.php`).
- `X-Correlation-Id` is opaque to the engine — stamp logs and audit events, never parse or
  branch on it.
- The engine computes, the platform decides: recomputations return as `diffs_reproducere`
  cross-checks; a non-empty diff is the platform's error to raise.
- The engine returns `auditEvents[]`; the platform persists them tenant-side.
- FastAPI's generated `/openapi.json` is not the contract; drift from the published spec is
  an engine defect.
- Vendored prototype modules (`engine/vendor/modul_a_populatie`, `modul_b_nj`) are
  re-exposed via `engine/app/vendored.py` — wrap, never rewrite: their validation against
  real data is the reason they exist.

## Enforcement copies

Each orchestrating agent enacts the roster in its own harness directory (Claude:
`.claude/agents/*.md`). Definition content follows the ratified roster in `CLAUDE.md`
ch. 2; the harness owner keeps its copies in sync with it.
