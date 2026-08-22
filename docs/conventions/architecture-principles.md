# Architecture principles

Structural discipline: how modules, boundaries and dependencies relate. Code-level:
`engineering-principles.md`. Adds to, never restates, `CLAUDE.md` ch. 2,
`docs/architecture.md`, `rules-of-engagement.md`.

## Contexts and dependency direction

- Organize `app/` by bounded context, never by technical layer: no `Services/`, `UseCases/`,
  `Actions/`, `Repositories/`, `Domain/`, `Application/` or `Infrastructure/` directory
  anywhere. Subdirectories inside a context are business phases
  (`app/Dosar/{Determination,Sampling,Signature}`), not technical roles; `Exceptions/` and
  `Storage/` are the only role-named ones. `tests/**` mirrors it.
- Context dependencies run one way: `app/Dosar/**` imports published `App\RiskRegister`
  symbols; `app/RiskRegister/**` must not know `App\Dosar` exists.
- Import only a context's published surface — ports, value objects, enums, exceptions.
  Divergence: `Dosar` injects concrete `App\RiskRegister\RiskClassIntervals`.
- Delivery (`app/Filament/**`, `app/Http/**`, `app/Console/**`, `app/Listeners/**`) depends
  on contexts, never the reverse. Divergence: `app/Auth/PasswordSetupLink.php` imports the
  Filament page its link targets.
- There are no domain events; a listener runs only if wired in
  `app/Providers/AppServiceProvider.php` (discovery is off, `bootstrap/app.php`).

## Ports and composition root

- Declare the port in the domain namespace that consumes it, name the implementation
  `Tenant<Port>`, and bind it only in a per-capability provider
  (`app/Providers/{Dosar,RiskRegister,Engine}ServiceProvider.php`), never in
  `AppServiceProvider`. Engine bindings stay lazy, so a misconfigured engine cannot break
  migrate, provision or seed.
- Never name a concrete adapter outside `app/Providers/`: not in a domain class, a panel, or
  a comment (`app/RiskRegister/RiskIndexSourceRepository.php` states it in tree).
- Behind an owned interface: persistence (13 `*Repository` ports),
  `app/Engine/Audit/BusinessAuditTrail.php`. Not behind one, known gaps rather than
  licence: tenant settings (`DB::table('settings')` in eight domain classes), mail (`Mail::`
  in the three notifiers vs an injected `Mailer` in `app/Auth/PasswordSetupLink.php`), the
  clock.
- Ambient tenant context is read through stancl's `tenant()` helper inside the tenancy
  carve-out, never injected: the standing exception to dependency inversion
  (`app/Tenancy/TenantKeyspace.php`, `app/Auth/SecurityEventLog.php`).

## Persistence posture

- Append-only follows ROLE, not the presence of a `version` column: evidence of an act is
  append-only by trigger; working state and current-pointers are mutable (ADR-0030,
  ADR-0058).

## Entry points

- Entry points are Filament resources, pages and actions (`app/Filament/**`), artisan
  commands (`app/Console/Commands/**`), queued jobs and listeners; `app/Http/Controllers/`
  holds one abstract base. Each reads input, delegates to exactly one use case, maps the
  result to a notification or exit code, and decides nothing.
- An entry point resolves collaborators with `app(UseCase::class)`, the only seam Livewire
  admits; use cases, adapters and listeners take constructor injection.
- Every write reachable from a panel goes through a named use-case class: no
  `Model::create/save/update`, query or transaction in a resource, page, action, controller
  or listener. Reads may resolve a port directly
  (`app/Filament/Resources/Dosare/DosarResource.php`); writes may not. Divergence:
  `EditProject::handleRecordUpdate()` writes `name` directly before delegating the rest.
- Ask the domain whether an act is permitted, never re-derive it from state in the page:
  `ViewDosar::canAttestPlatform()` delegates to `SignatureCircuit::canAttest()`. Divergence:
  nine sibling `can*()` predicates re-derive workflow rules for visibility.
- A refusal arrives as a named domain exception: catch, render, halt. The text lives in the
  exception; the entry point supplies a heading and never re-decides the rule.
  `$action->halt()` keeps a modal open; only the closing path re-renders the page beneath,
  so refresh a listing the act changed there (`app/Filament/Pages/RiskIndexSourceHistory.php`).
- Two entry points performing one act share a delivery collaborator under
  `app/Filament/<Context>/` — routing, form and refusal vocabulary in it, neither page
  routing the act (`app/Filament/RiskRegister/PerformRiskIndexIngest.php`).
- Entry points carry no policy. Named exception: `app/Filament/Auth/Pages/Login.php` owns
  its throttle key and window, because Filament exposes no other seam.

### Panel styling

- A panel serves exactly one stylesheet, `public/css/filament/filament/app.css`: neither
  provider calls `viteTheme()` and no `FilamentAsset` CSS is registered. It defines `fi-*`
  classes and no utilities, so a Tailwind utility written into `app/Filament/**` or
  `resources/views/filament/**` reaches the browser as a dead attribute.
- Style through Filament's own API — its size, weight and font-family enums, `Section`,
  `RepeatableEntry` — never a raw class string. Where Filament offers nothing, declare an
  inline `style`. Panel-wide chrome is the one override, a render hook:
  `AppPanelProvider::chromeStyles()`.
- A listing body is `white-space: nowrap`: the cell is one line, so `lineClamp()` clamps
  nothing and only `->wrap()` grows a row. Keep row height constant with `->limit()` plus
  `->tooltip()` (`app/Filament/Resources/Projects/ProjectResource.php`).
- `resources/views/welcome.blade.php` is the only view loading the Tailwind build, and the
  only place a utility class is live. Laravel's mail theme inlines its own CSS and defines
  no utility either.

## Engine seam

- The seam's abstraction is `contract/engine.openapi.yaml` plus the typed
  `app/Engine/Requests/**` and `Results/**` DTOs, not a PHP interface: `EngineClient` is a
  `final readonly` class and tests substitute at the HTTP layer.
- `app/Engine/**` injects Illuminate's HTTP factory, never the `Http` facade.
- Never add a client method for an operation the engine does not serve.
- Engine vocabulary reaches the UI as a published type, never a string literal.

## Central and tenant

- A table is central only if it must be readable with no tenant context or must outlive the
  tenant schema; everything a business user creates is tenant-local. Central models declare
  stancl's `CentralConnection`, tenant-local models declare none.
- Head every migration `CENTRAL —` or `TENANT —`, filed in `database/migrations/` or
  `…/tenant/` to match.
- Central code never queries a tenant schema — values are pushed into a central snapshot the
  console reads (`app/Tenancy/TenantMetricRecorder.php`); no cross-schema join or view
  exists. The audit trail is tenant-local; the central journal holds operational metadata
  only.
- A queued job carries scalars and a tenant key, re-initializes tenancy in `handle()` and
  ends it in `finally` (`app/Dosar/Documents/Jobs/ConvertNotaToPdfJob.php`, the only job so
  far). Mint names the framework does not tenant-scope — locks, rate limiters — through
  `app/Tenancy/TenantKeyspace.php`; never concatenate such a key.

## What enforces this

- Nothing mechanically enforces this file: no `arch()` test, no deptrac, no custom PHPStan
  rule, no CI script inspecting imports. It holds by review and roster write permissions.
- Adjacent checks exist: boundary shape in the contract gate, wiring in
  `tests/Feature/{FilamentPanelsTest,Console/TenantViewSurfaceTest}.php`, isolation in
  `tests/Feature/Tenancy/TenantIsolationTest.php`; some rules hold by construction
  (`TenantMetricRecorder::record()`). Name the mechanism when claiming enforcement.
