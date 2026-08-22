# 0042 — Flush the tenant cache tag set at the lifecycle transition

- Status: accepted
- Date: 2026-08-20

## Context

- Tenant cache entries are stored under a hash derived from the tag, so their Redis names carry
  no tenant segment. No key glob can enumerate a tenant's cache; the tag set
  `{prefix}tag:tenant<key>:entries` is the only tenant-addressable structure, and
  `Cache::tags(...)->flush()` the only thing that walks it.
- That tag set is also the one cache structure with no TTL (measured `TTL -1`) while the service
  runs `maxmemory-policy noeviction`. It grows with every tagged write, nothing reclaims it, and
  a full instance stops accepting writes — queue pushes included.
- Nothing in Redis is a system of record (recorded as ADR-0003, removed 2026-08-11), so a flush
  costs the next request a rebuild and can lose nothing. It is not a destructive operation.

## Decision

- `App\Tenancy\TenantCache` owns the tag — `tenancy.cache.tag_base` plus the tenant key — and the
  flush. It takes the tenant key as an argument and never reads `tenant()`: its callers run in
  central context, and initializing a tenant only to drop its cache would connect to that
  schema for nothing.
- `App\Tenancy\TenantLifecycle` flushes at the transition, not through a runbook step: after a
  slug rename, whose old tag set nothing else will ever name again, and after landing in a state
  that serves no request — keyed on `App\Enums\TenantStatus::isIdentifiable()` of the state
  landed in, never on the operation, so a later state or path inherits the rule.
- The flush runs after the registry write and the journal row, and is best-effort: a failure is
  logged as a warning naming tenant and tag, and never propagated.

Rejected: leave the flush to an operator runbook step. Refused: the structure it trims is
unbounded and invisible to key scans, so a forgotten step leaves something nothing else
reclaims. Also rejected: abort the transition when the flush fails — access is gated on the
registry row (`app/Http/Middleware/EnsureTenantIsAccessible.php`), so a Redis outage would
otherwise make an institution unsuspendable.

## Consequences

- Suspension and archival are authoritative in PostgreSQL; the cache is a consequence of them.
- This logged, non-propagated failure is a named exception to fail-fast
  (`docs/conventions/engineering-principles.md`); it is neither silent nor load-bearing.
- A new lifecycle path that renames a slug must flush the vacated tag itself.
