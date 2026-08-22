# 0039 — Pin the permission cache to the in-process array store

- Status: accepted
- Date: 2026-08-20

## Context

- `Spatie\Permission\PermissionRegistrar::getCacheStoreFromConfig()` resolves its store off
  the CacheManager it was constructed with, which is not the tenant-tagged manager
  `Stancl\Tenancy\Bootstrappers\CacheTenancyBootstrapper` swaps into the container. The entry
  under `spatie.permission.cache` is therefore untagged and shared by every tenant and by
  central.
- Its contents are role and permission NAMES mapped to per-schema integer ids. Two schemas
  legitimately hold a role named `Administrator` with different ids, so a shared entry makes
  tenant B answer an authorization question from tenant A's ids — a wrong answer, not an
  error.

## Decision

- `permission.cache.store` is `array`, the in-process store: the cached map cannot outlive the
  request that filled it. Asserted by `tests/Feature/Tenancy/ProvisioningTest.php`.
- `permission.cache.expiration_time` stays at the package default; against an in-process store
  it bounds a per-request cache only.
- A shared store becomes admissible only if the registrar is taught to resolve the
  tenant-tagged repository — an upstream change, not a configuration edit.
- The other half of the invariant, a tenancy switch inside one request, is decided at
  `app/Listeners/ForgetPermissionCacheOnTenancySwitch.php`.

Rejected: keep the package default (`default`, i.e. Redis here) and rely on stancl's cache
tagging for isolation. Refused: the registrar never passes through the tagging wrapper, so the
tag is never applied and the isolation is imaginary. Also rejected: a per-tenant cache key or
prefix — the registrar would have to know the tenant, which is the same upstream change.

## Consequences

- The role and permission set is re-read from the tenant schema once per request — two indexed
  queries on tables of a few rows — instead of once per 24 hours.
- No cross-request permission cache exists to invalidate or to warm; a role change takes effect
  on the next request.
- Any process touching two tenants (provisioning, seeders, queue workers, the test suite) is
  bounded to one request's worth of stale mapping.
