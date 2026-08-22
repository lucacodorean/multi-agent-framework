# 0036 — Tenant migrations mirror enum values instead of importing the class

- Status: accepted
- Date: 2026-08-20

## Context

- A tenant migration runs once per tenant on every `tenants:migrate`, provisioning of a new
  institution included. A fatal there stops onboarding, not a test.
- A migration is permanent; the class it would import is not. An import turns a rename or a
  move by that class's owner into a fatal in a file nobody edited.
- No migration in `database/migrations/tenant/` imports anything outside `Illuminate\`. The
  central `database/migrations/2026_07_29_000500_create_tenant_metric_snapshots_table.php`
  imports `App\Tenancy\TenantMetric` — a class owned by the same member as the migration
  (`CLAUDE.md` ch. 2).

## Decision

- A tenant migration imports no application class. A value set backed by a domain enum is
  written as a literal `private const` array in the migration and rendered into the CHECK.
- A migration may import only a class its own member owns; for a tenant migration that is
  none.
- Hold the migration-to-enum coupling in a test, never in the code. Canonical example:
  `self::ORIGINS` in
  `database/migrations/tenant/2026_07_29_100400_create_risk_index_store_tables.php`, with
  `tests/Feature/Tenancy/TenantRiskIndexStoreTest.php` asserting the CHECK accepts every case
  `App\RiskRegister\SourceOrigin` defines and refuses anything else.

Rejected: import the enum and render `Enum::cases()`, as the central metric-snapshot
migration does. It keeps the two lists equal by construction, and pays for that with a
cross-tier load-time dependency charged on every future provisioning run. A red test is
cheaper than a broken `tenants:migrate`.

## Consequences

- Widening a domain enum costs a forward-only tenant migration; the coupling test stays red
  until it lands.
- The value list exists twice and only the test keeps the copies equal — a new value-set
  CHECK is incomplete without one.
- Renaming or moving a domain enum cannot break provisioning.
