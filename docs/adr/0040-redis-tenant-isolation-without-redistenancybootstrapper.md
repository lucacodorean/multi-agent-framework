# 0040 — Redis tenant isolation without RedisTenancyBootstrapper

- Status: accepted
- Date: 2026-08-20

## Context

- Redis backs cache, sessions and queues in every deployed runtime (`.env.example`:
  `CACHE_STORE`, `SESSION_DRIVER`, `QUEUE_CONNECTION`).
- Nothing in the application talks to Redis directly; every use goes through Laravel's cache,
  session or queue.
- stancl's `RedisTenancyBootstrapper` separates tenants by switching Redis database index or
  connection prefix, and only for direct Redis use. A default Redis build offers 16 logical
  databases and collides silently past that rather than failing.

## Decision

- `tenancy.bootstrappers` holds `DatabaseTenancyBootstrapper`, `CacheTenancyBootstrapper`,
  `FilesystemTenancyBootstrapper`, `QueueTenancyBootstrapper`. `RedisTenancyBootstrapper` stays
  absent, and the `tenancy.redis` keys with it are unused.
- Isolation is per channel, each by its own mechanism:
  - cache — tags, `tenancy.cache.tag_base` = `tenant`, applied by stancl's cache manager;
  - sessions — the session-to-tenant binding at `app/Http/Middleware/BindSessionToTenant.php`;
  - queues — central by design; the tenant key travels inside the job payload.
- Enabling the bootstrapper later is an ADR, not a configuration edit.

Rejected: enable it anyway as defence in depth. Refused: it protects only direct Redis access,
which no code performs, while imposing a ceiling of roughly sixteen institutions that is
reached by silent collision rather than by an error.

## Consequences

- Tenant count is not bounded by Redis.
- A tenant's cache is addressable only through its tag set; there is no `tenant:{id}:cache:*`
  key glob, and flushing it is ADR-0042.
- Any future component that speaks to Redis directly must carry the tenant key itself — no
  bootstrapper will do it for it.
- `config/tenancy.php` keeps the disabled bootstrapper named and reasoned at the key, so its
  absence reads as a decision rather than an omission.
