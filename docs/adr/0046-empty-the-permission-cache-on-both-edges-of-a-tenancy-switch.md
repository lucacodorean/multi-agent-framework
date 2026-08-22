# 0046 — Empty the permission cache on both edges of a tenancy switch

- Status: accepted
- Date: 2026-08-20

## Context

- spatie's `PermissionRegistrar` memoizes the permission collection twice: in a property on the
  singleton, and in a cache entry it resolves straight off the `CacheManager` — past stancl's
  tagged wrapper, so that entry is not tenant-scoped.
- What it holds is permission and role NAMES mapped to PER-SCHEMA integer ids, and every tenant
  legitimately has a role named `Administrator` with a different id.
- A process that touches two tenants — provisioning, the dev seeder, a queue worker, the test
  suite — would therefore answer tenant B's authorization question against tenant A's rows.
  That is a wrong answer, not an error.
- `permission.cache.store` is pinned to the in-process `array` store (`config/permission.php`,
  ADR-0039), which bounds how long a stale mapping lives but not where it is read.

## Decision

- Crossing a tenancy boundary empties spatie's permission cache, in BOTH directions.
  `App\Listeners\ForgetPermissionCacheOnTenancySwitch` handles `TenancyInitialized` and
  `TenancyEnded` and calls `forgetCachedPermissions()`.
- It is registered explicitly in `App\Providers\AppServiceProvider`; listener discovery is off
  in `bootstrap/app.php`, so an added discovery pass would double every registration there.
- The invariant is symmetric and is stated as ONE rule — crossing a context boundary empties the
  cache, whichever way you cross — because that is what makes it checkable.
- Do not clear the cache by hand at a call site: a new tenancy-crossing path inherits the rule
  from the events.

## Alternatives rejected

- CLEAR ON INITIALIZATION ONLY. Central code running after a tenant context ends — the console,
  a command — would still read that tenant's rows.
- TENANT-TAG THE PERMISSION CACHE. The registrar resolves its store past the tagged wrapper, so
  the tag never applies; the store pin exists for the same reason.

## Consequences

- Permission and role rows are re-read from the database after each boundary crossing.
- The store pin and this listener are two halves of one control; removing either reopens the
  wrong answer.
- Guard: `tests/Feature/Auth/AuthorizationTest.php` drives two tenants whose permission-to-role
  mappings differ and asserts each gets its own answer.
