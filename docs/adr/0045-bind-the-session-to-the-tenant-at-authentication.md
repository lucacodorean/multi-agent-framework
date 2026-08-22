# 0045 — Bind the session to the tenant at authentication

- Status: accepted
- Date: 2026-08-20

## Context

- The app panel is mounted on `/{tenant}/…`, and one browser legitimately reaches several
  tenants: a person may serve two OIRs, and a mistyped slug is a normal event.
- `Stancl\Tenancy\Middleware\ScopeSessions` stamps the session with a tenant key on the FIRST
  tenant request of any kind — a guest hitting a login page included — then refuses every later
  visit to a different tenant with a bare `abort(403)`. Recovery is clearing cookies.
- Session replay across tenants requires an AUTHENTICATED session to replay, so binding a guest
  session protects nothing.

## Decision

- `App\Http\Middleware\BindSessionToTenant` replaces the vendor middleware's semantics. Binding
  happens at authentication:
  - guest — no binding, never refused;
  - authenticated and unbound — bind to the path tenant;
  - authenticated and bound elsewhere — 403 carrying its own notice.
- The session key stays `_tenant_id`, the vendor middleware's own string, so an
  already-authenticated session keeps its binding.
- It runs AFTER `InitializeTenancyByPath` and AFTER `StartSession`. An uninitialized tenancy is
  an exception, never a pass-through.
- Registered in both the panel middleware and the persistent list (ADR-0053).
- Its 403 text is distinct from `EnsureTenantIsAccessible`'s suspended-tenant notice: each 403
  cause keeps a single meaning, and a new refusal needs its own message.

## Alternatives rejected

- `ScopeSessions` AS SHIPPED. Binding on first sight locks a multi-OIR user out of the correct
  tenant while protecting nothing a guest session could carry.
- KEEPING VENDOR SEMANTICS AND DOCUMENTING THE COOKIE CLEAR. It makes a legitimate access
  pattern a support procedure.

## Consequences

- A browser may hold open the login pages of any number of tenants; only an authenticated
  session is confined.
- One session serves one institution: reaching a second requires signing out.
- Any surface that authenticates a tenant user inherits the binding from this middleware — do
  not stamp `_tenant_id` at a call site.
- Guard: `tests/Feature/Auth/SessionTenantBindingTest.php`.
