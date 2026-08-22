# Commands — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § commands.md. Full per-runtime
detail, with verification status per command: `docs/runbook.md`. Verified by execution
2026-08-11 unless marked UNVERIFIED.

| key | command |
|---|---|
| `commands.runner_prefix` | `ddev exec` — every tool runs in a container, never on the host |
| `commands.dependency_install` | `ddev exec composer install` · assets: `ddev exec npm install --ignore-scripts && ddev exec npm run build` |
| `commands.env_up` | `ddev start` (post-start hook leaves a login-ready install) |
| `commands.env_full_boot` | `ddev poweroff && ddev start` — never `ddev restart` |
| `commands.test` | `ddev exec php artisan test` (from the repo root) |
| `commands.test_narrow` | `ddev exec php artisan test --filter=<name>` |
| `commands.style_check` | `ddev exec vendor/bin/pint --test` (apply: drop `--test`) |
| `commands.static_analysis` | `ddev exec vendor/bin/phpstan analyse` |
| `commands.contract_lint` | `ddev contract-lint` |
| `commands.db_shell` | `ddev psql` (UNVERIFIED) |
| `commands.cache_shell` | `ddev redis-cli` |
| `commands.engine_test` | `cd engine && .venv/bin/python -m pytest` |
| `commands.regenerate_runtime` | `infra/ddev/bootstrap.sh oir-flow laravel` (idempotent, UNVERIFIED) |
| `commands.tenant_drift_check` | `ddev exec php artisan tenants:drift-check` |
| `commands.commit_hook` | `ddev exec vendor/bin/captainhook hook:pre-commit` |

## Destructive — explicit user-approved task required

`commands.destructive`:

- `ddev delete`; Docker volume or database drops.
- `tenants:migrate-fresh`; `tenants:rollback` against shared data.
- `ddev redis-flush`.
- Any operation against a schema or store other than the dedicated test resources
  (`oirflow_test`, Redis DBs 8/9 — `phpunit.xml`).

## Test-suite discipline

One platform-suite run per machine: `tests/Pest.php` takes a PostgreSQL session advisory lock
inside the suite, whatever invoked it. A concurrent run waits — a slow start is not a hang.
Detail, including the eight two-process concurrency tests: `docs/runbook.md` § Test-suite
discipline.
