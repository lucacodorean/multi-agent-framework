# 0032 — Localize human-facing Filament routes

- Status: accepted
- Date: 2026-08-19

## Context

Human-facing paths are assembled by `app/Providers/Filament/AppPanelProvider.php`, `app/Providers/Filament/ConsolePanelProvider.php`, `app/Filament/Resources/`, `app/Filament/Console/Resources/`, and `app/Filament/Pages/ContractImportItems.php`. Reserved prefixes live in `app/Tenancy/TenantSlug.php`. Signed-link and HTTP helpers live in `app/Auth/PasswordSetupLink.php`, `app/Auth/TenantUserActivation.php`, `app/Auth/TenantPasswordReset.php`, `tests/Pest.php`, and `tests/Support/InteractsWithTenantPanel.php`. The contract-owner ruling for this decision requires no OpenAPI, AsyncAPI, or engine-contract change.

## Decision

- Use ASCII Romanian noun forms on every human-facing tenant and console panel URI.
- Replace `/console` with `/consola`. Return immediate 404 for every old path; provide no redirect or alias. Invalidate outstanding signed URLs that contain old paths.
- Use `autentificare`, `creare`, `editare`, `vizualizare`, `setare-parola`, `resetare-parola`, `elemente`, `tenanti`, `administratori-centrali`, and `jurnal-ciclu-viata`. Keep `am-uitat-parola`.
- Keep internal Filament page keys and route names stable where possible. Configure URI paths independently of internal slugs and names.
- Keep POST-only `logout` as a technical Filament endpoint.
- Exclude `up`, Livewire, Filament package, storage, API, engine, and Horizon endpoints.
- Reserve both `consola` and `console` in `App\Tenancy\TenantSlug`. Land the data-tier reservation before domain-tier route changes.
- Change no OpenAPI, AsyncAPI, or document-engine contract.

## Consequences

- Treat localized paths as a deliberate breaking change for bookmarks and signed links.
- Update route assertions and URL helpers with the route sources.
- Preserve the platform-engine seam unchanged.
