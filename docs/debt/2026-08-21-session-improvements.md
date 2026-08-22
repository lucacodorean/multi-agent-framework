# OIRP-21/OIRP-23 session-improvements — adversarial review findings

Target reviewed: the OIRP-21/OIRP-23 diff on branch `session-improvements`, plus every
guest-reachable route for account/tenant-state disclosure. Reviewer: `code-reviewer` agent,
opus, effort high (run T4, workflow `wf_dfd18f2d-0e6`). Source of every claim below: that
workflow run's findings table and verbatim-scenario appendix, recorded here in full.

**Overall verdict: holds-with-findings.** Kept refusals intact: true. Redirect loop possible:
false.

Findings by severity: **blocker ×1 · major ×2 · minor ×6** — 9 total.

---

## Findings

### REVIEW-001 — blocker — pre-existing, out of scope for this run
- **File:line:** `app/Http/Middleware/BindSessionToTenant.php:42`
- **Claim:** a session authenticated in tenant B can be adopted as a tenant-A account
  during the window before BindSessionToTenant stamps `_tenant_id`, because the binding is
  inferred from the request PATH rather than from where authentication happened.
- **Failure scenario:** POST the tenant-B login through Livewire's update endpoint and do NOT
  follow the returned redirect effect; with the same cookie jar, GET `/{tenant-a}/proiecte` as
  the session's first authenticated request. `BindSessionToTenant.php:42-54` resolves
  `$request->user()` by looking the session's numeric id up in tenant A's users table
  (per-schema serials collide; `app/Auth/TenantEloquentUserProvider.php` adds no tenant
  scoping), finds `$bound === null`, stamps `_tenant_id = tenant-a` and passes.
  `EndDeactivatedSession` (position 8) and Filament's `Authenticate` (9) both pass because that
  alpha row is active and `User::canAccessPanel()` only checks `id==='app' && is_active`
  (`app/Models/User.php:47-50`). `AuthenticateSession` (10) finds no `password_hash_web` — that
  key is written only by that middleware, which is absent from the `web` group on
  `livewire.update` and returns early on the login GET where the user is null — so
  `vendor/laravel/framework/src/Illuminate/Session/Middleware/AuthenticateSession.php:60-62`
  STORES the alpha hash instead of logging out, and the takeover persists for the session's
  whole life. Order verified with `ddev artisan route:list -v`. Traced statically, not
  executed (read-only mandate forbids DB mutation); the one assumption is a user-id collision
  across two tenant schemas. Owner: data-engineer (CLAUDE.md ch. 2 carve-out). REPORT ONLY —
  new work, back through PLAN.

### REVIEW-002 — major — pre-existing, out of scope for this run
- **File:line:** `app/Filament/Auth/Pages/RequestPasswordReset.php:57`
- **Claim:** the tenant forgot-password submission has no rate limit at all, and its silent
  path is timing-distinguishable, so unlimited samples can be taken against the enumeration
  channel.
- **Failure scenario:** the replacement page extends `SimplePage` and drops Filament's
  `WithRateLimiting` trait entirely; stock
  `vendor/filament/filament/src/Auth/Pages/PasswordReset/RequestPasswordReset.php:40,59` calls
  `$this->rateLimit(2)`, and `route:list -v` shows no throttle middleware on
  `filament.app.auth.request-password-reset`. An unauthenticated caller can therefore POST the
  form without limit. Body, status, headers and redirect are identical for every submission
  (`RequestPasswordReset.php:41,64-68`), but the exists+active+activated branch additionally
  mints a signed URL, writes a `SecurityEventLog` entry and pushes a queue job
  (`app/Auth/TenantPasswordReset.php:104-115`) while the other three branches return at
  `:100-102`. Mail is queued (`app/Mail/TenantPasswordResetLink.php:19` implements
  `ShouldQueue`), so the delta is a job insert plus a log write rather than an SMTP round trip —
  modest per sample, but with no attempt cap it is statistically samplable, and it doubles as
  unbounded mail/queue amplification toward a known address. REPORT ONLY — not modified by
  this run.

### REVIEW-003 — major — in-diff
- **File:line:** `app/Http/Middleware/EndDeactivatedSession.php:51`
- **Claim:** the new session-end path uses `session()->regenerate()` and never clears
  `BindSessionToTenant::TENANT_ID_KEY`, unlike the panel's own logout which calls
  `session()->invalidate()`; the ended session stays bound to the old tenant.
- **Failure scenario:** log into tenant A, get deactivated mid-session, make one more request:
  `EndDeactivatedSession` logs out, regenerates and lands on A's login page with the notice —
  but `regenerate()` migrates all session data, so `_tenant_id = 'a'` survives (that data
  survival is exactly what carries the notification, so regenerate is mandated by the plan).
  Now log into tenant B from the same browser (a second membership). The login succeeds, then
  the first authenticated tenant-B request hits `BindSessionToTenant.php:56-57`
  `abort(403, 'Această sesiune este autentificată într-o altă organizație. Deconectați-vă din
  organizația curentă înainte de a accesa o alta.')` — advice the user cannot follow, because
  `{tenant}/logout` carries the same middleware and 403s too. Only clearing cookies recovers.
  `vendor/filament/filament/src/Auth/Http/Controllers/LogoutController.php:12-15` shows the
  convention this diverges from; `grep -rn TENANT_ID_KEY app/` shows no `forget()` anywhere.
  The same omission pre-exists at `app/Filament/Auth/Pages/ChoosePassword.php:116-117` and
  `ResetPassword.php:91-92`, so this is a convention collision the new path inherits rather
  than a fresh regression — reported, not resolved.

### REVIEW-004 — minor — in-diff
- **File:line:** `app/Filament/Concerns/RedirectsRefusedAccessToDashboard.php:29`
- **Claim:** the Dashboard redirect has no self-target guard; a project-owned dashboard would
  302-loop against itself, and the genericity test would positively require it to carry the
  looping trait.
- **Failure scenario:** `redirectRefusedAccessToDashboard()` unconditionally builds
  `Dashboard::getUrl(panel: 'app')` and throws it, with no comparison against the current route
  or page. It terminates today only because `Filament\Pages\Dashboard::canAccess()` resolves
  to `CanAuthorizeAccess::canAccess()` → `true` (reflection-verified) — an accident of the
  vendor class, not a property of the rule; `it('never redirects a request already on the
  dashboard')` at `tests/Feature/Auth/RoleChangeRedirectsToDashboardTest.php:148-161` passes
  for that reason, not because a guard exists. Add a project dashboard under
  `app/Filament/Pages/` (auto-discovered by `AppPanelProvider.php:104`) with any `canAccess()`
  gate: the genericity test at `:214-224` demands `RedirectsRefusedAccess` on every page except
  the literal `Filament\Pages\Dashboard::class`, so the new dashboard must carry it, and a
  refused role then gets an infinite 302 chain. Contrast
  `app/Http/Middleware/RequirePasswordChoice.php:42-44,52-59`, which exempts its own
  destination by route name.

### REVIEW-005 — minor — in-diff
- **File:line:** `app/Filament/Concerns/RedirectsRefusedResourceAccess.php:21`
- **Claim:** every resource page still carries a live vendor
  `abort_unless(canAccess(), 403)`, so the rule silently reverts to 403 for any resource page
  that later overrides `canAccess()`; the genericity test checks trait presence only and would
  not catch it.
- **Failure scenario:** the traits replace only the `...CanAuthorizeResourceAccess` hook pair.
  Reflection on `ListProjects`, `CreateProject`, `EditProject`, `ViewUser` and `ViewDosar` shows
  `mountCanAuthorizeAccess`/`hydrateCanAuthorizeAccess` still resolving to vendor —
  `CanAuthorizeAccess.php:7-15` on List/Create pages and `InteractsWithRecord.php:19-27` on
  Edit/View pages — both of which `abort_unless(static::canAccess(...), 403)`. That is dormant
  purely because `Filament\Resources\Pages\Page::canAccess()` returns the inherited default
  `true` (`vendor/filament/filament/src/Resources/Pages/Page.php:259-262`) and no app resource
  page overrides it. Override `public static function canAccess(array $parameters = []): bool`
  on any resource page to refuse a role, request it with that role, and the answer is 403
  instead of the Dashboard redirect the plan calls generic across the panel — with a green
  suite, because `tests/Feature/Auth/RoleChangeRedirectsToDashboardTest.php:226-254` asserts
  only that traits are attached.

### REVIEW-006 — minor — in-diff
- **File:line:** `app/Filament/Concerns/RedirectsRefusedEditAccess.php:19`
- **Claim:** the `authorizeAccess()` overrides throw `HttpResponseException`, which does not
  implement `HttpExceptionInterface`, so `EditRecord::getRedirectUrl()`'s deliberate catch of
  the vendor refusal no longer catches it.
- **Failure scenario:** `vendor/filament/filament/src/Resources/Pages/EditRecord.php:401-415`
  calls `$this->authorizeAccess()` inside
  `try { ... } catch (AuthorizationException | HttpExceptionInterface)` to decide the
  post-save destination — vendor's `abort_unless(..., 403)` throws `HttpException`, which is
  caught. The override throws
  `Illuminate\Http\Exceptions\HttpResponseException extends RuntimeException`
  (`vendor/laravel/framework/src/Illuminate/Http/Exceptions/HttpResponseException.php:9`),
  implementing neither arm. Make `ProjectResource::canEdit(Model $record)` record-dependent
  (e.g. refuse an archived project) and save an edit that flips the record into that state: the
  exception escapes after the transaction committed and the 'saved' notification fired,
  dumping the user on the Dashboard instead of the record's view or index page. Unreachable
  today because every `canEdit()`/`canView()`/`canCreate()` here is record-independent
  (`app/Filament/Resources/Users/UserResource.php:289-292`,
  `app/Filament/Resources/Projects/ProjectResource.php:179-182`) — the override mirrors the
  vendor gate's condition faithfully but not its exception contract.

### REVIEW-007 — minor — in-diff
- **File:line:** `docs/_intake.md:11`
- **Claim:** the T1 doc-impact entry states a false premise: that Filament's `Authenticate` is
  non-persistent and therefore never ran on Livewire's update endpoint. It is registered
  persistent by Filament itself.
- **Failure scenario:** the entry's CHANGE line claims '`Filament\Http\Middleware\Authenticate`
  is registered non-persistent, so its `canAccessPanel()` check never runs on Livewire's update
  endpoint and a person deactivated mid-session keeps driving components already on screen',
  citing `AppPanelProvider.php:131-136` — which shows only that the PANEL did not add it.
  `vendor/filament/filament/src/FilamentServiceProvider.php:20,105-112` calls
  `Livewire::addPersistentMiddleware([Authenticate::class, ...])` into the GLOBAL list, and
  `PersistentMiddleware.php:173-215` filters the original route's gathered middleware against
  that global list, so `Authenticate` WAS applied on the update endpoint and DID answer 403
  before this change. The implementation is unaffected; the record is not. T5's docs-agent is
  one stage from merging this into `docs/stories/as-is/AS-002` — governance requires it to
  verify against SOURCE and reject this entry rather than merge it.

### REVIEW-008 — minor — in-diff
- **File:line:** `app/Http/Middleware/EndDeactivatedSession.php:54`
- **Claim:** one notification is queued per intercepted request with no de-duplication and no
  exempt-route list, so concurrent tabs stack duplicate deactivation toasts on the login page.
- **Failure scenario:** `Notification::send()` uses `session()->push`
  (`vendor/filament/notifications/src/Notification.php:160-168`) — permanent session data
  appended to an array that the login page pulls whole
  (`vendor/filament/notifications/src/Livewire/Notifications.php:38`). The middleware pushes
  unconditionally on every request it intercepts. Open two tabs on the tenant panel under one
  session, deactivate the account, let both tabs issue their next request (reload or any
  Livewire update), then open the login page: two identical toasts render. Contrast
  `RequirePasswordChoice::exemptRouteNames()`, which the new middleware has no analogue of — so
  even a deliberate POST `{tenant}/logout` by a deactivated user queues the deactivation notice.

### REVIEW-009 — minor — in-diff, pre-existing gap
- **File:line:** `app/Http/Middleware/EndDeactivatedSession.php:35`
- **Claim:** a forced session termination writes no security-journal entry, and the 302 that
  replaces the 403 is no longer distinguishable from ordinary navigation in the access log.
- **Failure scenario:** deactivate an account with a live session and make one more request:
  nothing is recorded. `canAccessPanel()` does not pass through the Gate, so
  `app/Listeners/LogAuthorizationDenial.php` (bound to `GateEvaluated` at
  `app/Providers/AppServiceProvider.php:113`) does not fire, and `app/Auth/SecurityEventLog.php`
  has no method for this event — unlike every other auth-state transition in the codebase
  (`authenticationFailed:21`, `authorizationDenied:32`, `passwordChosen:41`, `userChanged:138`).
  Note this refutes the wider version of the concern for OIRP-23: role-gate refusals stay
  observable through `GateEvaluated` regardless of status code, so only the deactivation path
  is dark. Pre-existing in kind (Filament's `abort_if(403)` logged nothing either), but this
  change is the natural place for it, and it removes the 403 that was at least a signal in the
  access log.

---

## Disclosure sweep — five guest-reachable surfaces

| surface | account/tenant state distinguishable by a guest? | evidence |
|---|---|---|
| Login page `/{tenant}/autentificare` | **No** | One generic error for every failure: `vendor/filament/filament/src/Auth/Pages/Login.php:98-103,151-160,217-222` throws the same `login.messages.failed` on both the credential branch and the `canAccessPanel` branch. Timing is normalised: `retrieveByCredentials` + `validateCredentials` run inside `app(Timebox::class)->call(..., auth.timebox_duration = 200_000 us)` at `:93-108`, so an unknown address is padded to the same floor as an existing one, and `$timebox->returnEarly()` fires only when the password is correct. The active/deactivated split happens only at `attemptWhen` (`:151-157`), which requires the correct password — a caller who already holds it, not an anonymous prober. Throttle keys are the submitted string, not the resolved account (`app/Filament/Auth/Pages/Login.php:40-43,108-111,117-122`). Not modified by this run; `app/Filament/Auth/Pages/Login.php` and `tests/Feature/Auth/DeactivatedUserCannotLoginTest.php` are absent from git status. |
| Forgot password `/{tenant}/am-uitat-parola` | **YES** — see REVIEW-002 (timing only, pre-existing) | Body, status, headers and redirect are identical for every submission: one `CONFIRMATION` constant shared with its tests (`app/Filament/Auth/Pages/RequestPasswordReset.php:41,64-68`), and unknown, deactivated and not-yet-activated all take the silent return at `app/Auth/TenantPasswordReset.php:100-102`. TIMING differs: the exists+active+activated branch mints a signed URL, writes `SecurityEventLog::passwordResetLinkIssued` and pushes a queue job (`:104-115`) where the silent branch returns immediately. Mail is queued, not sent inline (`app/Mail/TenantPasswordResetLink.php:19` implements `ShouldQueue`), so the delta is a job insert plus a log write — small per sample, but the page dropped Filament's stock `$this->rateLimit(2)` (`vendor/.../PasswordReset/RequestPasswordReset.php:40,59`) and the route carries no throttle, so samples are unlimited. Not modified by this run. |
| Setup link `/{tenant}/setare-parola/{user}` | **No** | Without a valid signature the answer is identical for an existing and a non-existent `{user}`: `app/Http/Middleware/ValidatePasswordSetupSignature.php:29-31` throws `InvalidSignatureException` before the expiry is looked at, and `:33-35` answers expiry from link properties only. Route model binding cannot leak a 404-vs-403 differential even though `route:list -v` shows `SubstituteBindings` running before the signature middleware: `Route::signatureParameters(['subClass' => Model::class])` returns 0 for `filament.app.auth.set-password` (action `App\Filament\Auth\Pages\ChoosePassword@__invoke`, `mount(?string $user = null)` at `ChoosePassword.php:83`), so no implicit binding is attempted. With a valid signature, absent, inactive, already-activated and wrong-session collapse into one 404 body through a single construction site (`ChoosePassword.php:140-162,195-198`). Not modified by this run. |
| Reset link `/{tenant}/resetare-parola/{user}` | **No** (to an unauthenticated caller) | Reaching the page at all requires a `temporarySignedRoute` signature over tenant+user+marker (`app/Auth/TenantPasswordReset.php:63-74`) that only the mailed holder has; without it, `ValidatePasswordResetSignature.php:29-31` answers `InvalidSignatureException` identically for any `{user}`, and `Route::signatureParameters(['subClass' => Model::class])` returns 0 for `filament.app.auth.reset-password` so no binding 404 precedes it. To a link holder the states do differ — bare 404 for absent/deactivated/not-activated (`ResetPassword.php:122-130`) versus the SPENT_VIEW 404 (`:142-145`) versus a 200 form — which is ADR-0057's recorded decision and is addressed to a caller who already proved possession of a link minted for that account. Not modified by this run. |
| Tenant path `/{tenant}` and every protected panel route | **No** (no account state added) | TENANT state is disclosed by design — 403 for Suspended, 404 for never-activated or retired (`app/Http/Middleware/EnsureTenantIsAccessible.php:37-39,49-59`) — and no ACCOUNT state is. This diff adds nothing for a guest: `ddev artisan route:list -v` confirms `EndDeactivatedSession` is absent from all four guest routes (autentificare, am-uitat-parola, setare-parola/{user}, resetare-parola/{user}) because `vendor/filament/filament/routes/web.php:60` applies `getAuthMiddleware()` only inside the authenticated group; on a protected route it returns `$next($request)` untouched for a null or non-`User` principal (`EndDeactivatedSession.php:47-49`), adding no measurable work since `Authenticate` resolves the same guard-cached user immediately after. A guest on a protected path still gets Filament's own login redirect, asserted at `tests/Feature/Auth/RoleChangeRedirectsToDashboardTest.php:194-201`. The T3 traits are never reached by a guest (`Authenticate` at position 9 short-circuits before `mount()`), and their `abort(403)` guard at `RedirectsRefusedAccessToDashboard.php:31-36` is a fail-closed backstop, not a new disclosure. |

---

## Closing

Overall verdict: **holds-with-findings**. Kept refusals intact: true — the six deliberately
preserved 403 sites from T1's inventory were walked by T3 and none regressed. Redirect loop
possible: false, contingent on today's vendor `Dashboard::canAccess()` returning `true` (see
REVIEW-004 for the condition under which that stops holding). Two findings (REVIEW-001,
REVIEW-002) are pre-existing and out of scope for the OIRP-21/OIRP-23 diff; the remaining seven
are in-diff or in-diff-adjacent. Scope: `git diff` for the session-improvements branch against
its base, plus a static sweep of the five guest-reachable surfaces named above. Not executed:
no database mutation, no booted stack — every finding is traced statically from route
definitions, vendor source, and existing tests.

---

# Round 2 — re-review of round-1 fixes (2026-08-21)

Target reviewed: the fixes applied to REVIEW-003 through REVIEW-009 above, on branch
`session-improvements`. Reviewer: `code-reviewer` agent, opus, effort high (run T9, workflow
`wf_06cfe2e7-f26`, follow-up plan `.claude/plans/2026-08-21-session-improvements-followup-plan.md`).

**Overall verdict: 4 fixed, 2 fixed-with-new-problem.** Invariants hold: true.

## Verdict per round-1 finding

| id | verdict | note |
|---|---|---|
| REVIEW-003 | fixed | `app/Http/Middleware/EndDeactivatedSession.php:83-84` replaces `session()->regenerate()` with `session()->invalidate()` + `regenerateToken()`, matching `vendor/filament/filament/src/Auth/Http/Controllers/LogoutController.php:14-15`. |
| REVIEW-004 | fixed | `app/Filament/Concerns/RedirectsRefusedAccessToDashboard.php` now compares the current route name against the Dashboard's route name and aborts 403 instead of redirecting into a self-loop. |
| REVIEW-005 | fixed-with-new-problem | The genericity test now asserts the *resolved declaring class* per gate, not trait presence, closing a second, page-level vendor gate (`Filament\Pages\Page`'s own hook pair) that had stayed live on every resource page. The stronger assertion style is what exposes REVIEW-012. |
| REVIEW-006 | fixed | The decision is recorded with the vendor call site cited at `app/Filament/Concerns/RedirectsRefusedEditAccess.php:15-24`, naming `vendor/filament/filament/src/Resources/Pages/EditRecord.php:401-415`. |
| REVIEW-008 | fixed-with-new-problem | Exactly one notice reaches the login page and it is not suppressed — `session()->invalidate()` flushes any earlier undelivered notice before the new one is pushed. The `invalidate()` fix is what introduces REVIEW-011. |
| REVIEW-009 | fixed | `app/Auth/SecurityEventLog.php:40-52` adds `deactivatedSessionEnded()`, writing `security.session.ended_by_deactivation` at level warning through the same private sink as every other event. |

## New findings from the re-review (REVIEW-010…013)

| id | severity | file:line | finding | status (verified in the working tree, 2026-08-21) |
|---|---|---|---|---|
| REVIEW-010 | minor | `app/Filament/Concerns/RedirectsRefusedAccess.php:23` | The page-level gate replacement called `static::canAccess()` with no arguments, dropping the `['record' => ...]` argument vendor's `InteractsWithRecord` passes on Edit/View pages; the architecture test pinned the record-less form. | **fixed** — the trait now detects `getRecord()` and conditionally passes `['record' => ...]`, reproducing both vendor call shapes. |
| REVIEW-011 | minor | `app/Http/Middleware/EndDeactivatedSession.php:71` | `session()->invalidate()` destroys the old session id; a staggered concurrent request on the same stale cookie can overwrite the notice-carrying cookie and drop the deactivation notice entirely — a failure mode `regenerate()` did not have. | **accepted as a trade-off, not fixed** — human ruling, tracked at `docs/backlog.md` BL-036; caveat comment recorded above the `invalidate()` call. |
| REVIEW-012 | minor | `tests/Feature/Auth/RoleChangeRedirectsToDashboardTest.php:278` | The genericity/resolution test had no non-emptiness assertion on either discovery loop, so a page- or resource-discovery regression would make the whole REVIEW-005 check vacuously green. | **fixed** — `expect($discoveredPages)->not->toBeEmpty()` and `expect($panel->getResources())->not->toBeEmpty()` now guard both loops. |
| REVIEW-013 | minor | `tests/Feature/Auth/DeactivatedSessionEndsTest.php:17`, `:117`; `tests/Support/InteractsWithTenantPanel.php:210` | Three comments still described `session()->regenerate()` as the teardown call the middleware makes, after REVIEW-003 replaced that call with `invalidate()` + `regenerateToken()`. | **partially fixed** — the two `DeactivatedSessionEndsTest.php` comments now name `invalidate()` and cite `regenerate()` only as the call it replaced. `tests/Support/InteractsWithTenantPanel.php:210` is unchanged: its `carryCookies()` docblock still names only `session()->regenerate()` as the session-rotation example — not false (`ChoosePassword.php` and `ResetPassword.php` still call `regenerate()`), but it does not mention `invalidate()` either. |

### New findings — verbatim scenarios

**REVIEW-010 — `app/Filament/Concerns/RedirectsRefusedAccess.php:23`**

`EditRecord` and `ViewRecord` compose `Concerns\InteractsWithRecord`, whose hook pair is
`abort_unless(static::canAccess(['record' => $this->getRecord()]), 403)`
(`vendor/filament/filament/src/Resources/Pages/Concerns/InteractsWithRecord.php:19-27`). The
round-1 trait pulled `RedirectsRefusedAccess` into the resource-level trait, so a leaf-class
method won over the inherited one on `EditProject`, `EditUser`, `ViewDosar` and `ViewUser`,
but called `static::canAccess()` with no arguments — a record-dependent gate would decide on
a missing record. Unreachable in practice because no app resource page overrode `canAccess()`
at the time, but test-pinned rather than caught.

**REVIEW-011 — `app/Http/Middleware/EndDeactivatedSession.php:71`**

Two tabs share session S1; deactivate the account. Tab 1's request R1 calls
`session()->invalidate()`, which destroys S1 and issues S2 carrying the notice. Tab 2's
request R2 still carries S1 and, if its response reaches the browser after R1's, gets its own
empty `Set-Cookie: S1` — overwriting S2 and losing the notice entirely (the caller ends up
logged out with no explanation). The previous `regenerate()` did not have this failure mode
because it left the old session alive for R2 to be intercepted by too. Traced statically —
reproducing it needs two genuinely concurrent HTTP requests, which the Pest client cannot
issue. Fail direction is safe: still logged out, still on login.

**REVIEW-012 — `tests/Feature/Auth/RoleChangeRedirectsToDashboardTest.php:278`**

The only unconditional assertion in the genericity test was
`expect($panel)->toBeInstanceOf(Panel::class)`; every `resolvedDeclaringClass()` check sat
inside the two discovery loops. An empty `discoverPages()`/`discoverResources()`
registration, or a discovery regression, would make both loops execute zero times while the
test still reported PASS.

**REVIEW-013 — stale `regenerate()` comments**

`grep -rn "regenerate" app/ tests/` against the working tree showed three comments
describing `session()->regenerate()` as the teardown call the middleware makes, after
REVIEW-003 replaced that call with `invalidate()` + `regenerateToken()`: the top docblock and
a body comment in `DeactivatedSessionEndsTest.php`, and the `carryCookies()` docblock in
`InteractsWithTenantPanel.php`. Per `docs/conventions/engineering-principles.md` §
Comments, a comment earns its place by stating a constraint invisible from the code; one
naming a call the code no longer makes misdirects the next reader of a security path.

## Closing (round 2)

Overall verdict: **4 fixed, 2 fixed-with-new-problem** of the six in-diff round-1 findings
(REVIEW-003, 004, 006, 009 fixed clean; REVIEW-005, 008 fixed but each introduced one new
minor finding, closed above as REVIEW-012 and REVIEW-011 respectively). Invariants hold: kept
refusals intact, no redirect loop. Verified independently against the working tree at
docs-checkpoint time (2026-08-21): REVIEW-010 and REVIEW-012 are cleanly fixed; REVIEW-011 is
accepted as a trade-off, not fixed (BL-036); REVIEW-013 is fixed at two of its three cited
sites, with the third unchanged (see table above). This section is additional to the round-1
record above; it does not alter that record's finding bodies, its Closing, or its header
severity counts.
