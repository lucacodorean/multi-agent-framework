# 0041 — The tenant search_path is the tenant schema and `extensions`

- Status: accepted
- Date: 2026-08-20

## Context

- stancl 3.10.0's `PostgreSQLSchemaManager::makeConnectionConfig()` sets the tenant
  connection's `search_path` to the tenant schema alone.
- `unaccent()` and `pg_trgm` are database-global objects. They live in one `extensions` schema
  created centrally by `database/migrations/0001_01_01_000000_create_extensions_schema.php`; a
  tenant migration never creates or owns an extension.
- With `public` on the tenant path, a query for a table missing from the tenant schema resolves
  against the central schema and returns rows instead of failing.

## Decision

- Tenant connections run `search_path = tenant_<slug>, extensions`, and nothing else. `public`
  is never on a tenant path.
- `tenancy.database.managers.pgsql` is `App\Tenancy\PostgreSQLSchemaManager`, the project
  subclass of stancl's manager, which overrides `makeConnectionConfig()` to append the
  extensions schema. The two names are passed as array elements so Laravel's connector quotes
  each.
- The same subclass binds the schema name as a parameter in its existence probe instead of
  interpolating it, and exposes `schemaExists()` for callers holding a name but no tenant.

Rejected: add `public` to the tenant path so central and shared tables resolve unqualified.
Refused: it converts a missing tenant table from a loud error into central rows served inside a
tenant request — the one failure schema isolation exists to prevent. Also rejected: create the
extensions per tenant schema, which duplicates database-global objects per institution and puts
a privileged statement in a migration that runs at every provisioning.

## Consequences

- A query against a table absent from the tenant schema raises; the isolation tripwires in
  `tests/Feature/Tenancy/TenantIsolationTest.php` rest on that.
- Unqualified `unaccent()` and `pg_trgm` calls resolve in tenant context with no tenant-owned
  extension.
- Upgrading stancl requires re-reading `makeConnectionConfig()`: the subclass replaces it whole,
  so an upstream change to the base is silently discarded.
