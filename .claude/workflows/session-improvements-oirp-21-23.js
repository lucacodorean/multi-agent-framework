export const meta = {
  name: 'session-improvements-oirp-21-23',
  description: 'OIRP-21/OIRP-23 tenant-panel session lifecycle: seam design, two implementations, adversarial review + disclosure sweep, docs checkpoint',
  phases: [
    { title: 'T1 seam design', detail: 'domain-engineer decides both refusal seams, inventories every 403 to preserve', model: 'opus' },
    { title: 'T2 OIRP-21', detail: 'deactivated session ends with notification + login redirect' },
    { title: 'T3 OIRP-23', detail: 'role-based refusal answers with the Dashboard' },
    { title: 'T4 review', detail: 'adversarial review + guest-surface disclosure sweep', model: 'opus' },
    { title: 'T5 docs', detail: 'docs-agent drains intake, updates living stories, writes no ADR' },
  ],
}

const COMMON = `
PROJECT: OIR Flow — multi-tenant Laravel 13 / PHP 8.5 / Filament 5 platform, Pest suite. Read CLAUDE.md first, then docs/conventions/engineering-principles.md (code-level discipline: strict types, comment discipline, class/method/transaction rules).

TWO DOCUMENTS CARRY YOUR BRIEF — read both before touching anything:
- docs/tracker/2026-08-21-session-improvements-intake.md — the normalized items OIRP-21 and OIRP-23, each with an "Observed as-built" block whose file:line citations are verified. Trust them but re-read the cited code.
- .claude/plans/2026-08-21-session-improvements-plan.md — the approved plan. Read § Invariants and your own row in § Tasks.

STANDING HUMAN RULING (plan § Invariants) — binds you regardless of what any ticket text says:
- No route discloses account state to an unauthenticated caller. Body, status code, headers, redirect target and TIMING all count as disclosure.
- The deactivation notice is reachable ONLY from an authenticated session. The login page and app/Filament/Auth/Pages/Login.php are NOT to be modified, and tests/Feature/Auth/DeactivatedUserCannotLoginTest.php must stay green WITHOUT edits.
- A violation you find in code this plan does not modify is REPORTED, never fixed. Out-of-scope work goes back to planning.

HARD CONSTRAINTS:
- NEVER commit. NEVER push. Leave your work in the working tree (branch session-improvements).
- You are a worker under docs/conventions/documentation-governance.md: you must NOT create, modify or delete ANY .md file. The single exception is APPENDING a doc-impact entry to docs/_intake.md in the exact three-line format (AFFECTS / CHANGE / SOURCE). Never edit or remove existing entries there. Creating any summary, notes or handoff file is a task failure even if the code works.
- Stay inside your ownership area (CLAUDE.md ch. 2). app/**, tests/**, bootstrap/app.php, config/** except tenancy.php are yours. Do not touch contract/**, database/**, infra/**, .ddev/**, .github/**, app/Tenancy/**, or the tenancy carve-outs.
- Verification runs in the container per docs/runbook.md. tests/Pest.php holds a machine-wide PostgreSQL advisory lock, so a concurrent suite run queues rather than collides — a slow start is not a hang.
`

const LANDED = `
REPORT DISCIPLINE: your final answer is data for the orchestrator, not prose for a human. Fill the structured schema exactly. Every file you wrote goes in landedFiles as a repo-relative path — a stage claiming success with an empty landedFiles list is treated as a failed gate.
`

phase('T1 seam design')

const t1 = await agent(`${COMMON}
TASK T1 — DECIDE THE TWO REFUSAL SEAMS. YOU WRITE NO CODE IN THIS TASK.

Two QA items ask the tenant panel to stop answering a live user with a bare 403:
- OIRP-21: an account deactivated mid-session must be sent to the login page with an informative notification, instead of the 403 raised by Filament's own Authenticate middleware (vendor/filament/filament/src/Http/Middleware/Authenticate.php:33-39) once User::canAccessPanel() sees is_active=false.
- OIRP-23: a user whose ROLE changed mid-session must land on the Dashboard ("Panoul de control"), instead of the 403 raised by abort_unless(static::canAccess(), 403) inside Filament's page/resource concerns (vendor/filament/filament/src/Pages/Concerns/CanAuthorizeAccess.php:9,14; Resources/Pages/Concerns/CanAuthorizeResourceAccess.php:19,22; Resources/Pages/Concerns/InteractsWithRecord.php:21,26).

These two causes are DIFFERENT (authentication state vs authorization state) and could easily be built as two overlapping mechanisms, or as one blanket rule that silently swallows refusals this product decided on purpose. Your job is to fix which seam answers which cause, before either is implemented.

DELIVERABLES (all in the structured report, no files written except one docs/_intake.md entry if you have a verified doc-impact fact):
1. seamAuthentication — where the inactive-session rule lives, exactly: file to create/modify, how it is registered in app/Providers/Filament/AppPanelProvider.php, and whether it needs the isPersistent registration that RequirePasswordChoice uses (AppPanelProvider.php:169-171) so Livewire's update endpoint is covered too. State the ordering constraint against Filament\\Http\\Middleware\\Authenticate: your rule must win before that abort_if fires.
2. seamAuthorization — where the canAccess() refusal is answered. Choose between (a) the ten in-page canAccess() call sites (ProjectResource.php:213, UserResource.php:323, ImportContracts.php:101, ContractImportExceptions.php:81, ContractImportItems.php:88, ConfigureRiskClassIntervals.php:76, ConsultRiskRegister.php:89, IngestRiskIndex.php:95, ImportAssociations.php:71, RiskIndexSourceHistory.php:90) and (b) an exception-rendering rule in bootstrap/app.php, whose withExceptions() today registers only shouldRenderJsonWhen. Give the reason, and give the mechanism that keeps the rule from widening: how does the chosen seam distinguish "an authorization gate refused an authenticated tenant-panel caller" from every other 403 in the application?
3. preserved403 — a row per existing 403 answer with a keep/change verdict AND the test that pins it: app/Http/Middleware/BindSessionToTenant.php:57 (ADR-0045, tests/Feature/Tenancy/BindSessionToTenantTest.php:95-107), app/Http/Middleware/EnsureTenantIsAccessible.php:53 (tests/Feature/Tenancy/TenantIsolationTest.php:171, tests/Feature/Console/TenantManagementTest.php:355-382 and :927), app/Filament/Pages/ImportContracts.php:484, ImportAssociations.php:217, IngestRiskIndex.php:357, ContractImportExceptions.php:503, the two signed-link 403 views (ValidatePasswordSetupSignature.php:36, ValidatePasswordResetSignature.php:34), the stock tampered-signature 403 (tests/Feature/Auth/PasswordSetupRefusalTest.php:300), tests/Feature/Auth/TenantLivewireContextTest.php:83, tests/Feature/Persons/PersonAdministrationSurfaceTest.php:73,76. Add any 403 site you find that this list misses — grep for abort(, abort_if, abort_unless, HttpException across app/.
4. redirectLoopArgument — why the Dashboard target cannot loop. The app panel registers Filament's stock Dashboard (AppPanelProvider.php:105); its label "Panoul de control" comes from vendor/filament/filament/resources/lang/ro/pages/dashboard.php:5 with APP_LOCALE=ro. Say what happens if a caller is already on the Dashboard, and whether any role can be refused BY the Dashboard itself.
5. filesToTouch — the file list T2 and T3 will each modify, disjoint where possible, with the collision points named (both stages reach the panel's auth stack, so they are serialized).
6. notificationMechanism — confirm the delivery path the ruling fixed: guard logout, session()->regenerate() (NOT invalidate(), which drops the flash), Filament\\Notifications\\Notification::make()->...->send(), redirect to the panel login route. The working precedent is app/Filament/Auth/Pages/ChoosePassword.php:113-127 and app/Filament/Auth/Pages/ResetPassword.php:88-102. State how a test can assert the notification actually RENDERS on the login page after the redirect, not merely that send() was called.

ACCEPTANCE: every item above answered concretely with file:line evidence; no code written; no .md written except at most one appended docs/_intake.md entry.

EFFORT — high: consider both seam options for OIRP-23 adversarially before choosing. For your chosen seam, actively try to break it: name a request that SHOULD still get 403 and walk it through your rule to prove it still does. Verify every file:line you cite by opening it. A design that reads well and widens the rule is the failure mode here.
${LANDED}`, {
  label: 'T1 seam design',
  phase: 'T1 seam design',
  agentType: 'domain-engineer',
  model: 'opus',
  effort: 'high',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['seamAuthentication', 'seamAuthorization', 'preserved403', 'redirectLoopArgument', 'filesToTouch', 'notificationMechanism', 'landedFiles', 'outOfScope'],
    properties: {
      seamAuthentication: { type: 'string' },
      seamAuthorization: { type: 'string' },
      preserved403: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['site', 'verdict', 'pinnedBy'],
          properties: { site: { type: 'string' }, verdict: { type: 'string', enum: ['keep', 'change'] }, pinnedBy: { type: 'string' } },
        },
      },
      redirectLoopArgument: { type: 'string' },
      filesToTouch: { type: 'array', items: { type: 'string' } },
      notificationMechanism: { type: 'string' },
      landedFiles: { type: 'array', items: { type: 'string' } },
      outOfScope: { type: 'array', items: { type: 'string' } },
    },
  },
})

if (!t1) {
  log('T1 returned nothing — stopping before any implementation stage.')
  return { gate: 'T1 failed', t1: null }
}

const kept = (t1.preserved403 || []).filter(r => r.verdict === 'keep').map(r => r.site)
log(`T1 done: ${kept.length} of ${(t1.preserved403 || []).length} inventoried 403 answers marked keep.`)

const SEAM = `
T1 (already completed by another agent) fixed the seams. Build to this, do not re-decide it:

SEAM FOR AN INACTIVE SESSION: ${t1.seamAuthentication}

SEAM FOR AN AUTHORIZATION REFUSAL: ${t1.seamAuthorization}

NOTIFICATION MECHANISM: ${t1.notificationMechanism}

REDIRECT-LOOP ARGUMENT: ${t1.redirectLoopArgument}

403 ANSWERS THAT MUST SURVIVE UNCHANGED (site — pinned by):
${(t1.preserved403 || []).filter(r => r.verdict === 'keep').map(r => `- ${r.site} — ${r.pinnedBy}`).join('\n')}

FILES T1 EXPECTS TO BE TOUCHED: ${(t1.filesToTouch || []).join(', ')}

If implementing reveals that T1's seam is wrong, STOP, do not improvise a different seam, and report the contradiction with evidence.
`

phase('T2 OIRP-21')

const t2 = await agent(`${COMMON}
${SEAM}
TASK T2 — OIRP-21: END A DEACTIVATED SESSION WITH A NOTIFICATION AND A LOGIN REDIRECT.

Today: an admin deactivates User X (app/Auth/TenantUsers.php:164-206 flips users.is_active) while X has a live session. X's next request authenticates fine, then User::canAccessPanel() (app/Models/User.php:47-50) returns false and Filament's Authenticate middleware answers abort_if(..., 403) — a white stock 403 page, because resources/views/errors/ does not exist. Nothing ends X's session.

Required behaviour: on the next request of a session whose account is no longer active — guard logout, session()->regenerate(), a Filament notification, redirect to the panel login route, where the notification RENDERS as a pop-up.

Notification body, exactly: „Accesul la contul dumneavoastră este dezactivat. Contactați administratorul pentru mai multe detalii"

ACCEPTANCE CRITERIA — answer each one explicitly in criteriaResults:
1. No reachable abort(403)/abort_if remains for this cause; the redirect replaces it.
2. The notification renders on the login page AFTER the redirect. Assert the rendered page, not the send() call — the flash surviving session()->regenerate() is the whole point, and invalidate() would drop it.
3. A Livewire update request (the endpoint Filament drives components through) redirects rather than 403s, asserted by a test. See AppPanelProvider.php:129-136 and :169-171 for why persistent registration exists.
4. Nothing is hard-coded to a route name or slug: a Pest test proves the rule on TWO unrelated protected surfaces, one of which is NOT /proiecte/create (§ @note3 demands a general answer).
5. The login form is untouched: app/Filament/Auth/Pages/Login.php unmodified, Filament's generic credentials error unchanged, and tests/Feature/Auth/DeactivatedUserCannotLoginTest.php green WITHOUT edits. A diff touching either file fails this task.
6. No guest-reachable response changes in body, status or timing.
7. These stay green: tests/Feature/Tenancy/BindSessionToTenantTest.php, tests/Feature/Tenancy/TenantIsolationTest.php:171, tests/Feature/Console/TenantManagementTest.php:355-382 and :927.
8. Pint clean, PHPStan clean, FULL Pest suite green (docs/runbook.md for the commands).
9. Two docs/_intake.md entries appended: one for the new behaviour, one recording the § @note2 decision — that a login attempt into a deactivated account keeps the generic credentials error ON DISCLOSURE GROUNDS, so ADR-0055's stance stands.

EFFORT — high: after it works, adversarially re-check the three silent-green traps — (a) the notification is flashed but never rendered, (b) the page path redirects but the Livewire path still 403s, (c) the rule is scoped to one route by accident. Write the test that would catch each before declaring done.
${LANDED}`, {
  label: 'T2 OIRP-21',
  phase: 'T2 OIRP-21',
  agentType: 'domain-engineer',
  model: 'sonnet',
  effort: 'high',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['status', 'landedFiles', 'criteriaResults', 'suiteGreen', 'phpstanClean', 'pintClean', 'intakeEntries', 'outOfScope'],
    properties: {
      status: { type: 'string', enum: ['pass', 'partial', 'fail'] },
      landedFiles: { type: 'array', items: { type: 'string' } },
      criteriaResults: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['criterion', 'pass', 'evidence'],
          properties: { criterion: { type: 'string' }, pass: { type: 'boolean' }, evidence: { type: 'string' } },
        },
      },
      suiteGreen: { type: 'boolean' },
      phpstanClean: { type: 'boolean' },
      pintClean: { type: 'boolean' },
      intakeEntries: { type: 'number' },
      outOfScope: { type: 'array', items: { type: 'string' } },
    },
  },
})

log(t2 ? `T2 ${t2.status}: ${(t2.landedFiles || []).length} files, suite ${t2.suiteGreen ? 'green' : 'NOT green'}.` : 'T2 returned nothing.')

phase('T3 OIRP-23')

const t3 = await agent(`${COMMON}
${SEAM}

T2 (already completed) implemented the OIRP-21 inactive-session redirect. Files it landed: ${t2 ? (t2.landedFiles || []).join(', ') : 'none — T2 failed, treat the auth stack as unmodified'}. Read that diff before you start; you are writing into the same auth surface.

TASK T3 — OIRP-23: ANSWER A ROLE-BASED REFUSAL WITH THE DASHBOARD.

Today: an admin changes User X's role from „Responsabil IER" to „Ofițer de verificare" (app/Auth/TenantUsers.php:128 syncRoles). ADR-0039 pins the permission cache to the in-process array store, so the change bites on X's very next request. X refreshes /{tenant}/proiecte, the resource's canAccess() ($user->can('risk-register.access'), ProjectResource.php:37,213 — a permission held only by Administrator and Responsabil IER per database/seeders/TenantDatabaseSeeder.php:48) returns false, and Filament answers abort_unless(..., 403). The account is still active and the session still valid; only the rights changed.

Required behaviour: that caller lands on the panel Dashboard („Panoul de control", AppPanelProvider.php:105) and continues with the new role. § asks for NO message on this path — do not add one; that would be new scope.

ACCEPTANCE CRITERIA — answer each one explicitly in criteriaResults:
1. An authenticated tenant-panel request refused by a page/resource canAccess() gate redirects to the Dashboard instead of 403.
2. The rule is GENERIC across the ten canAccess() sites, not per-page. A test proves it on two of them, one being /{tenant}/proiecte after a „Responsabil IER" → „Ofițer de verificare" edit performed through TenantUsers::update().
3. A request already on the Dashboard never redirects to itself.
4. Livewire update requests are covered too.
5. Every 403 T1 marked keep still answers 403. These tests stay green AND UNMODIFIED: tests/Feature/Tenancy/BindSessionToTenantTest.php:95-107, tests/Feature/Tenancy/TenantIsolationTest.php:171, tests/Feature/Console/TenantManagementTest.php:355-382 and :927, tests/Feature/Auth/TenantLivewireContextTest.php:83, tests/Feature/Persons/PersonAdministrationSurfaceTest.php:73,76. If any of them needs an edit to pass, your rule is too wide — narrow the rule, do not touch the test.
6. The redirect is reachable only by an authenticated caller: an unauthenticated request to the same URL still lands on the login page exactly as today, disclosing neither the route's permission nor the account.
7. Pint clean, PHPStan clean, FULL Pest suite green.
8. A docs/_intake.md entry appended for the new behaviour.

EFFORT — high: the criterion that matters is the negative one. Before declaring done, take each 403 marked keep and walk an actual request through your rule proving it still gets 403 — a diff that satisfies the happy path while widening the rule passes the suite and is still wrong.
${LANDED}`, {
  label: 'T3 OIRP-23',
  phase: 'T3 OIRP-23',
  agentType: 'domain-engineer',
  model: 'sonnet',
  effort: 'high',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['status', 'landedFiles', 'criteriaResults', 'preserved403Verified', 'suiteGreen', 'phpstanClean', 'pintClean', 'intakeEntries', 'outOfScope'],
    properties: {
      status: { type: 'string', enum: ['pass', 'partial', 'fail'] },
      landedFiles: { type: 'array', items: { type: 'string' } },
      criteriaResults: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['criterion', 'pass', 'evidence'],
          properties: { criterion: { type: 'string' }, pass: { type: 'boolean' }, evidence: { type: 'string' } },
        },
      },
      preserved403Verified: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['site', 'stillRefuses', 'evidence'],
          properties: { site: { type: 'string' }, stillRefuses: { type: 'boolean' }, evidence: { type: 'string' } },
        },
      },
      suiteGreen: { type: 'boolean' },
      phpstanClean: { type: 'boolean' },
      pintClean: { type: 'boolean' },
      intakeEntries: { type: 'number' },
      outOfScope: { type: 'array', items: { type: 'string' } },
    },
  },
})

log(t3 ? `T3 ${t3.status}: ${(t3.landedFiles || []).length} files, suite ${t3.suiteGreen ? 'green' : 'NOT green'}.` : 'T3 returned nothing.')

phase('T4 review')

const t4 = await agent(`${COMMON}

TASK T4 — ADVERSARIAL REVIEW OF BOTH CHANGES, THEN A DISCLOSURE SWEEP OF EVERY GUEST-REACHABLE ROUTE. YOU WRITE NO CODE AND FIX NOTHING.

Review the full working-tree diff on branch session-improvements (git diff, git status — the work is uncommitted by design). It implements:
- OIRP-21 (T2): a session whose account was deactivated mid-flight is logged out, session regenerated, notified, redirected to login. Files: ${t2 ? (t2.landedFiles || []).join(', ') : 'T2 failed — say so'}.
- OIRP-23 (T3): an authorization refusal inside the tenant panel redirects to the Dashboard instead of 403. Files: ${t3 ? (t3.landedFiles || []).join(', ') : 'T3 failed — say so'}.

PART 1 — answer these four questions explicitly, each with file:line evidence:
a) Can any 403 that T1 marked keep now be reached as a redirect? The list: ${kept.join('; ')}
b) Does the deactivation notification survive session()->regenerate() and actually RENDER on the login page — or is the test asserting the send() call only?
c) Is there any authenticated surface where the inactive-account rule is bypassed? Check at minimum: the logout route, the guest routes registered in AppPanelProvider->routes(), ->authenticatedRoutes(), the Livewire update endpoint, and anything registered as persistentMiddleware.
d) Can either redirect loop — including the interaction between T2's login redirect and T3's Dashboard redirect, and between T2's rule and RequirePasswordChoice (app/Http/Middleware/RequirePasswordChoice.php), which also redirects authenticated users.

PART 2 — the disclosure sweep. The standing human ruling is that NO route discloses account state to an unauthenticated caller. For EACH guest-reachable surface below, state whether an unauthenticated caller can distinguish an existing account, a deactivated account and an unknown account, by body, status code, headers, redirect target OR timing:
- the login page /{tenant}/autentificare (App\\Filament\\Auth\\Pages\\Login + Filament's base Login::authenticate)
- forgot-password /{tenant}/am-uitat-parola (RequestPasswordReset::CONFIRMATION, TenantPasswordReset::request — note it short-circuits on unknown/inactive/must-choose)
- the setup link /{tenant}/setare-parola/{user} (ChoosePassword, ADR-0055)
- the reset link /{tenant}/resetare-parola/{user} (ValidatePasswordResetSignature, ADR-0057)
- the tenant path itself (EnsureTenantIsAccessible — tenant state is legitimately disclosed; account state is not)
A violation in code this run did NOT modify is reported as a finding, never fixed.

Report findings as tracker-intake bug items (the format your agent definition specifies), most severe first, and state a verdict: does the diff hold both invariants — every kept 403 still refuses, and no new disclosure to an unauthenticated caller.

EFFORT — high: try to break it, do not confirm it. Both changes convert a refusal into a redirect, so the failure mode is a passing suite plus a widened rule. Prefer a concrete request walked end to end over a reading of intent.`, {
  label: 'T4 review + disclosure sweep',
  phase: 'T4 review',
  agentType: 'code-reviewer',
  model: 'opus',
  effort: 'high',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['verdict', 'findings', 'disclosureSweep', 'keptRefusalsIntact', 'redirectLoopPossible'],
    properties: {
      verdict: { type: 'string', enum: ['holds', 'holds-with-findings', 'violated'] },
      findings: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['file', 'summary', 'failureScenario', 'severity'],
          properties: { file: { type: 'string' }, line: { type: 'number' }, summary: { type: 'string' }, failureScenario: { type: 'string' }, severity: { type: 'string', enum: ['blocker', 'major', 'minor'] } },
        },
      },
      disclosureSweep: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['surface', 'distinguishable', 'evidence'],
          properties: { surface: { type: 'string' }, distinguishable: { type: 'boolean' }, evidence: { type: 'string' } },
        },
      },
      keptRefusalsIntact: { type: 'boolean' },
      redirectLoopPossible: { type: 'boolean' },
    },
  },
})

log(t4 ? `T4 verdict: ${t4.verdict}; ${(t4.findings || []).length} findings; kept refusals intact: ${t4.keptRefusalsIntact}.` : 'T4 returned nothing.')

phase('T5 docs')

const t5 = await agent(`ROLE: docs-agent

${COMMON.replace('You are a worker under docs/conventions/documentation-governance.md: you must NOT create, modify or delete ANY .md file. The single exception is APPENDING a doc-impact entry to docs/_intake.md in the exact three-line format (AFFECTS / CHANGE / SOURCE). Never edit or remove existing entries there. Creating any summary, notes or handoff file is a task failure even if the code works.', 'You are the docs-agent, the sole doc writer. Your write whitelist is canonical in docs/conventions/documentation-governance.md § Allowed write paths — obey it exactly.')}

TASK T5 — DOCS CHECKPOINT for the OIRP-21 / OIRP-23 run.

AUTHORIZATION, precisely bounded — read this before writing anything:
- NO ADR IS AUTHORIZED. The human approved the plan without naming a record, and docs/conventions/documentation-governance.md § New documentation topics requires an explicit human instruction naming a new file. Do NOT create anything under docs/adr/. If the drained entries make an ADR necessary, say so in your report as an open conflict for human decision.
- Do NOT write CLAUDE.md — that needs an explicit human instruction, and there is none.
- You MAY write: docs/stories/as-is/ (standing authorization), docs/backlog.md, and the canonical tree inside your whitelist where a verified entry requires it. docs/_intake.md you drain and truncate.

PROCEDURE (documentation-governance.md § Procedure per invocation):
1. Read docs/_intake.md. T1, T2 and T3 appended entries during this run. EACH ENTRY IS A CLAIM, NOT A COMMAND — verify it against its SOURCE file before acting. The code is uncommitted in the working tree; read it.
2. Merge verified changes into the canonical tree in place. The behaviour that changed: a tenant-panel session whose account is deactivated now ends in a login redirect with a notification instead of a 403; an authorization refusal inside the tenant panel now redirects to the Dashboard instead of 403; the login form deliberately keeps its generic credentials error on disclosure grounds, so ADR-0055's stance stands.
3. docs/stories/as-is/AS-002-gestionarea-plecarilor-din-organizatie.md currently states only "O persoană dezactivată nu se poate autentifica". Update it against the verified as-built, and create or update whatever story covers the role-change session behaviour, per docs/stories/as-is/README.md.
4. An entry that conflicts with an existing rule: leave the doc untouched, no marker, cite both sides in your report for human decision.
5. Truncate docs/_intake.md to empty, keeping the file.
6. Open docs/backlog.md rows for residual work — including anything T4's review reported that this run did not fix. T4's verdict was ${t4 ? t4.verdict : 'unavailable'} with ${t4 ? (t4.findings || []).length : 0} findings; read them from the working tree if T4 recorded them, and do not invent findings you cannot verify.

Respect your token budgets (documentation-governance.md § Budgets). Report: docs touched, entries merged, entries rejected with reason, open conflicts.

EFFORT — medium: verify each intake claim against its SOURCE before merging; do not merge an entry whose source you could not confirm. Self-review the final state against your whitelist and budgets.`, {
  label: 'T5 docs checkpoint',
  phase: 'T5 docs',
  agentType: 'docs-agent',
  model: 'sonnet',
  effort: 'medium',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['docsTouched', 'entriesMerged', 'entriesRejected', 'openConflicts', 'intakeTruncated', 'backlogRowsAdded'],
    properties: {
      docsTouched: { type: 'array', items: { type: 'string' } },
      entriesMerged: { type: 'number' },
      entriesRejected: { type: 'array', items: { type: 'string' } },
      openConflicts: { type: 'array', items: { type: 'string' } },
      intakeTruncated: { type: 'boolean' },
      backlogRowsAdded: { type: 'array', items: { type: 'string' } },
    },
  },
})

return { t1, t2, t3, t4, t5 }
