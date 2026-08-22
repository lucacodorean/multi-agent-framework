# 0053 — No Filament tenancy; the tenancy middleware are persistent

- Status: accepted
- Date: 2026-08-20

## Context

- The app panel is mounted on the `{tenant}` path prefix, which makes `{tenant}` the first route
  parameter of every panel route — what `InitializeTenancyByPath` requires, since it refuses to
  initialize rather than guess which parameter is the tenant.
- Filament ships row-level multi-tenancy (`->tenant()`, `->tenantRoutePrefix()`, the tenant
  menu) for teams inside ONE database.
- Livewire does not use the panel's routes for component updates: every `wire:click`, form
  submit and table filter posts to ONE central route registered by the package, outside the
  panel prefix and therefore outside the panel's middleware group. Livewire re-applies, on that
  endpoint, only the middleware of the originating route that is on its PERSISTENT list.

## Decision

- Filament's built-in multi-tenancy is NEVER enabled. Institutions are separated by schema;
  stancl resolves the tenant, Filament does not.
- `InitializeTenancyByPath`, `EnsureTenantIsAccessible` and `BindSessionToTenant` (ADR-0045) are
  registered as PERSISTENT as well as in the panel middleware, together with
  `UseFilamentPanelAuthGuard`. Anything added to `->middleware()` later that must hold for
  component updates goes on the persistent list too.
- Middleware order in the panel stack is load-bearing: tenancy first, accessibility next,
  session binding after `StartSession`.
- `RequirePasswordChoice` is declared in its OWN `->authMiddleware()` call, because
  `isPersistent` marks everything in the array it is passed.
- Tenant routes are registered through the panel's `->routes()` seam, not `routes/web.php`.

## Alternatives rejected

- ENABLE FILAMENT TENANCY BESIDE SCHEMA ISOLATION. Two competing tenant resolvers, two notions
  of "current tenant", and a `tenant_id` column on tables that are already physically isolated.
- THE PANEL MIDDLEWARE ALONE. Without the persistent registration the default connection stays
  `central` on Livewire's endpoint, so the login POST resolves `App\Models\User` against `public`
  where the table does not exist — a tenant user cannot log in AT ALL over real HTTP — and a
  tenant suspended mid-session keeps serving every component already on screen.

## Consequences

- Suspension needs no session-invalidation mechanism: an in-flight component call is refused
  with the same 403 as any other request.
- A tenant route defined outside the panel is a second place to forget the tenancy middleware.
- `Livewire::test()` disables middleware, so none of this is visible to it. The guards are
  HTTP-level: `tests/Feature/Auth/TenantLivewireContextTest.php`,
  `tests/Feature/Auth/SessionTenantBindingTest.php`, plus a wiring assertion on the persistent
  list.
