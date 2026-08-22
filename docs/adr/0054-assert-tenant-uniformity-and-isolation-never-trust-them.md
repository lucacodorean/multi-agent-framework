# 0054 — Assert tenant uniformity and isolation; never trust them

- Status: accepted
- Date: 2026-08-20

## Context

- Institutions are separated by PostgreSQL schema, so one migration run acts on N schemas and
  reports one result. A migration that fails is loud; one institution left on an older schema
  while the run reports success is not.
- Every tenant schema is expected to carry the same applied-migration set as
  `database/migrations/tenant/` and as every other tenant. Nothing in the run compares them.
- A tenant table's isolation is a placement fact — present in `tenant_<slug>`, absent from
  `public` — and a placement fact is assertable.
- Provenance: recorded as ADR-0005, removed from the tree on 2026-08-11; re-derived here from
  code. Other parts of that record are at 0038, 0042 and 0043.

## Decision

- `app/Console/Commands/TenantsDriftCheck.php` runs as the last step of the local post-start
  hook (`infra/ddev/hooks/dev-install.sh`) and of the preview bring-up (`infra/deploy/up.sh`).
  The exit code is the product: a divergence fails the bring-up. Never soften it to a warning.
- `App\Tenancy\TenantDriftInspector` answers three questions per tenant — schema present for a
  status that implies one (`App\Enums\TenantStatus::expectsSchema()`), applied ledger against
  the migration files, and each tenant's ledger against every other's. It is read-only:
  repairing drift is a separate, deliberate act (`tenants:migrate`).
- No reference set throws (`App\Tenancy\Exceptions\TenantDriftReferenceMissing`) instead of
  passing trivially. Orphan `tenant_%` schemas with no registry row are printed and do not fail
  the run. Verdicts stay distinct per remedy (`App\Tenancy\TenantDriftVerdict`).
- Isolation is asserted the same way: `tests/Feature/Tenancy/TenantIsolationTest.php` pins the
  `public` table inventory as an exact list, and a tenant table's absence from `public` is
  asserted where that table is created (`tests/Feature/Tenancy/ExpenseLedgerVersionsTest.php`).

Rejected: trust a green deploy to mean every schema is current, and review to keep business
tables out of `public`. Refused: both failure modes are silent — the deploy reports success,
and a central table looks like every other migration — and both surface only once data sits in
the wrong place. Also rejected: let the check repair what it finds, which turns a diagnosis
into an unreviewed migration; and fail the gate on orphan schemas, which lets one rolled-back
provisioning attempt block every deploy.

## Consequences

- A tenant migration is immutable once applied anywhere: renaming or deleting the file makes
  every schema carrying it report a migration with no file.
- Adding a central table means editing the pinned inventory in the same change; that edit is
  the review.
- The tripwire rests on a missing tenant table raising instead of resolving centrally (0041).
- Restoring a drifted tenant is a deliberate migration run, never a side effect of the check.
