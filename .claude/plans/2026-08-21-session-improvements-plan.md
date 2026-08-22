# Orchestration Plan: QA session-lifecycle improvements on branch `session-improvements`

## Source

§ = `docs/tracker/2026-08-21-session-improvements-intake.md` (2 ready items: OIRP-21, OIRP-23), produced by `tracker-intake` from `prompts/2026-08-21-session-improvements.md`.

Step 0 docs read: `CLAUDE.md` ch. 1–5, `docs/conventions/orchestration.md`, `documentation-governance.md`, `docs/adr/0039`, `0045`, `0055`, `docs/backlog.md`.

Doc rules that override skill defaults:

- **`Workflow` is mandatory here**, not `Agent` + `SendMessage`: members, order and gates are all known before dispatch (`orchestration.md` § Deterministic workflows). It is also the only route carrying per-stage `effort` — an `Agent` dispatch would forfeit every effort cell below.
- **One tier, one member.** Both items are `app/**`, `bootstrap/app.php` and `tests/**` — domain-engineer throughout. No `contract/**` change, so no contract-owner routing; no migration, so no data-engineer.
- **Same-path serialization over parallelism.** T2 and T3 both reach the app panel's middleware and refusal surfaces, so they run in sequence; worktree isolation applies only to same-tier members writing disjoint paths (`orchestration.md`).
- **Workers never write `.md`**; each stage ends by appending a doc-impact entry to `docs/_intake.md`, and one docs-agent checkpoint drains it (`documentation-governance.md`).
- **No commits, no pushes** (`CLAUDE.md` ch. 4). Every stage leaves its work in the tree.
- Plan artifacts live under `.claude/` — this file (`orchestration.md` § Deterministic workflows).

## Assumptions & open questions

Resolved by the human, and load-bearing for the breakdown:

- **The deactivation notice is reachable only from an authenticated session; the login form is not touched.** The human ruled that the message is delivered as a pop-up notification through the notification bag, and that the user learns of the deactivation at their next action — on the redirect to the login page — not by submitting credentials. So OIRP-21 is one behaviour, not two: the mid-session interruption carries the notification, and the login form keeps Filament's generic `filament-panels::auth/pages/login.messages.failed` error unchanged.
- **This discharges the enumeration exposure rather than accepting it.** The notification only ever reaches a caller who already held a valid session for that account, so it discloses nothing the caller did not already know; an anonymous prober sees exactly what it sees today. ADR-0055 and `2026-08-20-bug-fixing-qa-feedback#OIRP-24` are left standing, unamended, and `DeactivatedUserCannotLoginTest` stays green **unmodified**.
- **§ @note2 is therefore answered by a recorded decision, not by code.** Its condition — "if there is no specific behavior for the situation when the user attempts to log-in into a deactivated account" — is false here: the generic credentials error *is* the specific behaviour, chosen on disclosure grounds. T2 files that as an intake entry; T5 turns it into an ADR only if the approval names one.
- **Coverage boundary, stated so it is not discovered later:** the notice fires on the next request of a session that was open when the account was deactivated. Someone who had already closed their browser has no session to interrupt and gets the generic login error with no explanation. That is the accepted shape — the reported case is "was working when it happened".
- **Delivery mechanism is fixed by that ruling, and it constrains the code:** `session()->regenerate()`, never `invalidate()` — the codebase precedent (`ChoosePassword::save()`, `ResetPassword::save()`) regenerates precisely because an invalidated session drops the flashed notification.

Assumptions made instead of asking:

- **OIRP-23 asks for a redirect, not a message.** § names „Panoul de control" as the destination and no notification; T3 therefore adds none. A message on that path would be new scope.
- **The generality clause (§ @note3) is a test obligation, not prose.** T2 and T3 each prove it on at least two unrelated protected surfaces, one of which is not the example route from the ticket.
- **Livewire's update endpoint is in scope for both items.** § says "accesare sau reîncărcare"; the panel registers its tenancy and password-choice middleware as persistent for exactly this reason (`AppPanelProvider.php:129-136`, `:169-171`), and a rule that only covers full page loads leaves components already on screen driving.
- **T1 exists because the two items could be built as two overlapping mechanisms.** OIRP-21's cause is authentication state (`canAccessPanel`, one vendor middleware); OIRP-23's is authorization state (`canAccess()`, ten in-page call sites). One cheap decision stage fixes which seam answers which cause before either is implemented.
- **No backlog row is touched.** BL-022…BL-033 name neither cause; BL-024 (unowned 403/expired-page divergence on the signed-link routes) is adjacent and stays out of scope unless T3's seam re-homes 403 rendering platform-wide, which T1 is asked to avoid.

Open, non-blocking:

- **Two ADR candidates are named but not authorized by this plan** (`documentation-governance.md` § New documentation topics; the same hold the previous run applied): (a) *the deactivation notice is reachable only from an authenticated session* — the ruling above, which answers § @note2 with a refusal and keeps ADR-0055's stance intact; (b) *an authorization refusal inside the tenant panel answers with a redirect, not 403* — T1's seam decision and the list of 403s it deliberately preserves. Approving this plan authorizes no `.md` outside `docs/_intake.md`. Name them in the approval to release T5's ADR half.

## Invariants (bind every stage, not only the rows that mention them)

**No route discloses account state to an unauthenticated caller.** Human ruling, standing above this plan. It holds today, and no stage may weaken it:

- **Login** — one generic error for every failure, deactivated included (`filament-panels::auth/pages/login.messages.failed`, reached through `attemptWhen(… canAccessPanel …)`). Untouched by this plan.
- **Forgot password** — one confirmation for every submission, `RequestPasswordReset::CONFIRMATION` („Dacă adresa există și contul este activ, veți primi un e-mail…"), with unknown, deactivated and not-yet-activated addresses all taking the silent path (`TenantPasswordReset::request()`). The constant is shared with its tests so a wording change that reintroduces a distinct failure path is a single edit.
- **Setup link** — unknown account, inactive account, already-used link and wrong-session collapse into one 404 body (ADR-0055, `ChoosePassword::UNAVAILABLE_VIEW`).
- **Reset link** — expiry and tampering are answered on link properties, not account properties (`ValidatePasswordResetSignature`, ADR-0057).
- **Tenant path** — suspended 403 / unknown-or-retired 404 is *tenant* state, not account state (`EnsureTenantIsAccessible`), and stays as it is.

Consequences for the stages below: the deactivation notice exists only behind proof of session; timing and status codes count as disclosure, not just bodies; and any stage that finds a violation reports it rather than fixing it — that is new work, and it goes back through PLAN.

## Tasks

| ID | Task | Source | Route | Model | Effort | Depends on | Wave | Acceptance criteria | Routing rationale |
|----|------|--------|-------|-------|--------|-----------|------|--------------------|-------------------|
| T1 | Decide the two refusal seams and inventory every 403 that must survive | OIRP-21, OIRP-23 | agent (domain-engineer) | opus | high | — | 1 | Writes no code. Report names: the seam answering an authenticated-but-inactive session and where it registers (incl. Livewire coverage); the seam answering a `canAccess()` refusal, chosen between the ten in-page sites and a rule in `bootstrap/app.php`, with the reason; a table of every existing 403 answer (`BindSessionToTenant:57`, `EnsureTenantIsAccessible:53`, `ImportContracts:484`, `ImportAssociations:217`, `IngestRiskIndex:357`, `ContractImportExceptions:503`, the two signed-link views, the stock tampered-signature 403) marked keep or change, each with the test that pins it; a redirect-loop argument for the Dashboard target; the files T2 and T3 will touch. Ends with a `docs/_intake.md` entry | Cross-cutting design whose failure invalidates both implementations; the intake shows the cheap seam (a blanket 403 rule) silently swallowing four deliberate refusals |
| T2 | OIRP-21: end a deactivated session with a notification and a login redirect | OIRP-21 | agent (domain-engineer) | sonnet | high | T1 | 2 | An authenticated request whose account is no longer active answers with: guard logout, `session()->regenerate()`, a Filament notification, redirect to the panel login route — no reachable `abort(403)` left for this cause. Notification reads „Accesul la contul dumneavoastră este dezactivat. Contactați administratorul pentru mai multe detalii" and is asserted to render on the login page after the redirect, i.e. the flash survives the regenerate. Registered so a Livewire update request redirects rather than 403s, asserted by a test. No route name or slug hard-coded; a Pest test proves the rule on two unrelated protected surfaces, one of them not `/proiecte/create`. **The login form is not modified**: `App\Filament\Auth\Pages\Login` and the generic credentials error stay as they are, and `DeactivatedUserCannotLoginTest` stays green **without edits** — a diff touching either is a failed criterion. `BindSessionToTenantTest`, `TenantIsolationTest:171` and `TenantManagementTest:355-382,927` still see 403. No guest-reachable response changes in body, status or timing — the invariants section is a criterion, not context. pint + phpstan clean, full Pest suite green. Ends with `docs/_intake.md` entries for the behaviour and for the § @note2 decision | Implementation against T1's fixed seam — standard work in a known pattern, with the logout→regenerate→notify→redirect precedent already in the tree. High effort, not medium: the flash surviving a session regenerate and the Livewire update path each fail silently-green if only the page path is checked |
| T3 | OIRP-23: answer a role-based refusal with the Dashboard instead of 403, without touching the deliberate 403s | OIRP-23 | agent (domain-engineer) | sonnet | high | T2 | 3 | An authenticated tenant-panel request refused by a page or resource `canAccess()` gate lands on the panel Dashboard („Panoul de control") instead of 403; no message is added. The rule is generic across the ten `canAccess()` sites — not per-page — and a test proves it on two of them, one being `/{tenant}/proiecte` after a „Responsabil IER" → „Ofiţer de verificare" edit. A request already on the Dashboard never redirects to itself. Livewire update requests covered. Every 403 T1 marked keep still answers 403, with `BindSessionToTenantTest:95-107`, `TenantIsolationTest:171`, `TenantManagementTest:355-382,927`, `TenantLivewireContextTest:83` and `PersonAdministrationSurfaceTest:73,76` green and unmodified. The redirect is reachable only by an authenticated caller: an unauthenticated request to the same URL still lands on the login page as it does today, disclosing nothing about the route's permission or the account. pint + phpstan clean, full Pest suite green. Ends with a `docs/_intake.md` entry | Same shape as T2 against a settled seam; high effort because the criterion that matters is a negative one — six refusals that must NOT change — and a diff satisfying the happy path while widening the rule looks green |
| T4 | Adversarial review of both changes, plus a disclosure sweep of every guest-reachable route | OIRP-21, OIRP-23 | agent (code-reviewer) | opus | high | T2, T3 | 4 | Reviews the full working-tree diff and reports findings as tracker-intake bug items. Answers explicitly: can any 403 T1 marked keep now be reached as a redirect; does the notification survive the session regenerate and render on the login page; is there any authenticated surface where the inactive-account rule is bypassed (logout route, guest routes, Livewire update, `authenticatedRoutes`); can either redirect loop. **Then sweeps the invariant across every guest-reachable route — login, forgot-password, setup link, reset link, tenant path — and states for each whether an unauthenticated caller can distinguish an existing, a deactivated and an unknown account by body, status code, headers, redirect target or timing.** A violation found in existing code is reported, not fixed | Two auth-surface changes whose failure mode is a green suite, plus a whole-surface invariant sweep — `orchestration.md` § Model & effort puts verification at the highest effort the stage merits |
| T5 | Docs checkpoint: drain intake, update the living stories, write only the ADRs named in the approval | OIRP-21, OIRP-23 | agent (docs-agent) | sonnet | medium | T4 | 5 | Drains and truncates `docs/_intake.md`, verifying each entry against its SOURCE; updates `docs/stories/as-is/AS-002` and any story the verified entries touch; writes an ADR only if the approval named it; opens backlog rows for residual work; reports docs touched, entries merged, entries rejected, open conflicts | Docs writing against verified sources — routing table default; docs-agent is the sole doc writer |

## Waves

- **Wave 1** (parallel: 1): T1
- **Wave 2** (parallel: 1): T2 — blocked on T1
- **Wave 3** (parallel: 1): T3 — blocked on T2 (shares the panel's middleware and refusal surfaces)
- **Wave 4** (parallel: 1): T4 — blocked on T2, T3
- **Wave 5** (parallel: 1): T5 — blocked on T4

**Critical path: T1 → T2 → T3 → T4 → T5 — the whole plan.** Nothing here parallelizes: one member owns every path, and T2 and T3 write the same auth surface. The chain is five short stages, not five large ones.

## Risks & escalation

- **T3 is the task most likely to fail its real criterion.** Making the refusal redirect is easy; keeping the six deliberate 403s is the work. The failure looks like a passing suite plus a widened rule that silently redirects a suspended-tenant or wrong-tenant refusal to a dashboard. T1's keep/change table and T4 exist to catch exactly that. Standard escalation: one retry on sonnet/high with the failure evidence, then opus/high.
- **T2's quiet failure is a lost notification.** Logout, redirect and 403-removal are all visible; the notification surviving `regenerate()` into the *next* request is the part a happy-path test misses. Its acceptance criterion asserts the rendered login page, not the flash call, for that reason.
- **T1's failure invalidates both implementations.** If its report cannot name a seam that leaves the deliberate 403s alone, the run stops and returns to PLAN rather than letting T2 pick a seam by itself.
- **T4 may generate new work, and the disclosure sweep is the likeliest source.** It reads five existing surfaces the plan does not modify; anything it finds there is out of scope by construction and goes back through PLAN as fresh intake. The DISPATCH protocol refuses silent scope absorption.
- `tests/Pest.php` holds a machine-wide PostgreSQL advisory lock, so suite runs queue rather than collide (`docs/runbook.md` § Test-suite discipline). With parallel 1 throughout, this never binds.
- Nothing commits or pushes; a bad wave is recovered with `git checkout`.

## Approval

Approving this plan authorizes a **single `Workflow` run** dispatching **T1–T5** on the listed models and effort levels, wave by wave, auto-continuing between waves with a short report at each boundary, and stopping early on any of the three DISPATCH stop conditions.

It authorizes **no ADR**: T5 writes `docs/adr/` only for a record named in the approval reply. The two candidates are listed under Assumptions.

No commit and no push will be made. Reply with edits, or approve to dispatch.
