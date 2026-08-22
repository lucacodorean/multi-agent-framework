# Technology stack — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § stack.md. The only place a version
is stated. Source of truth for every pin is the manifest named beside it.

| key | value |
|---|---|
| `stack.languages` | PHP ^8.5 (`composer.json`) · Python ≥3.12 (`engine/pyproject.toml`) · Node 22 (runtime) |
| `stack.frameworks` | Laravel ^13.5 · Filament ^5 (two panels: `/console`, `/{tenant}`) · FastAPI (engine) · `stancl/tenancy` ^3.9 · `spatie/laravel-permission` ^8.3 |
| `stack.services` | PostgreSQL 16 (schema per tenant) · Redis 7.4.10-bookworm, `noeviction` · SMTP · `python:3.12-slim-bookworm` + `libreoffice-writer` (engine image) |
| `stack.tooling.style` | Pint, `laravel` preset (no `pint.json`; the preset is the standard) |
| `stack.tooling.static_analysis` | PHPStan/Larastan `level: 5` (`phpstan.neon`); never pass `--level`, never lower it |
| `stack.tooling.test` | Pest (platform) · pytest (engine, black-box HTTP) |
| `stack.tooling.contract_lint` | Spectral against `contract/.spectral.yaml`; in-container only, never host `npx` |

Out of every gate named here: `infra/**` PHP and the Python engine.
