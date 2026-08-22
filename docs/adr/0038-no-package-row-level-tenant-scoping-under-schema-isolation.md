# 0038 — No package row-level tenant scoping under schema isolation

- Status: accepted
- Date: 2026-08-20

## Context

- Institutions are separated by PostgreSQL schema: `roles`, `permissions` and the three
  pivots are created in `tenant_<slug>` by
  `database/migrations/tenant/2026_07_28_100100_create_permission_tables.php`. There is no
  central spatie installation.
- spatie/laravel-permission ships a `teams` feature that scopes those rows by a `team_id`
  column and a resolver; Filament ships row-level multi-tenancy on the same shape.
- That migration reads `permission.teams`, `permission.table_names` and
  `permission.column_names` from `config/permission.php`.
- Provenance: recorded as ADR-0005, removed from the tree on 2026-08-11; re-derived here from
  code.

## Decision

- No package's row-level tenant-scoping feature is enabled while isolation is by schema.
  `permission.teams` stays `false`.
- State the package default explicitly rather than delete the key, with the reason at the key,
  so it cannot drift back silently on an upgrade.
- `config/permission.php` stays a verbatim `vendor:publish` of the package config, package
  comments included, with exactly the pinned deviations marked in place — an upgrade is a
  re-publish plus those edits, not a merge.
- The Filament half of the same rule is decided at
  `app/Providers/Filament/AppPanelProvider.php`.

Rejected: enable `teams` with the tenant as the team — the package's own supported
multi-tenancy, and the route to one central role table serving every institution. Refused: it
scopes rows inside tables that are already physically isolated, and correctness then depends
on a resolver being set on every path instead of on the connection.

## Consequences

- Authorization rows are per tenant schema; a query is scoped by the connection, and nothing
  can forget to scope it.
- Enabling `teams` later is a schema change across every tenant, not a configuration edit.
- Filament's `->tenant(...)` API is unavailable; tenant context arrives from path middleware.
